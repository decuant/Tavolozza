--[[
*	hsl.lua
*
*   .
]]

local trace 	= require("lib.trace")

local _min		= math.min
local _max		= math.max
local _abs		= math.abs
local _floor	= math.floor
local _insert 	= table.insert
local _frmt		= string.format

-- ----------------------------------------------------------------------------
--
local m_trace = trace.new("wxHSL")
m_trace:enable(true)

-- ----------------------------------------------------------------------------
--
local function RGBToHSL(inRed, inGreen, inBlue)
	
	inRed 	= inRed   / 255.0
	inGreen = inGreen / 255.0
	inBlue	= inBlue  / 255.0

	local dMax	= _max(inRed, inGreen, inBlue)
	local dMin	= _min(inRed, inGreen, inBlue)
	local dif	= dMax - dMin
	local sum	= dMax + dMin

	local hue = 0.0
	local sat = 0.0
	local lum = sum / 2.0

	if 0.0 ~= dif then
		
		sat = dif / (1 - _abs((2.0 * lum) - 1.0))
		
		if inRed == dMax then
			
			hue = ((inGreen - inBlue) / dif) % 6
		
		elseif inGreen == dMax then
			
			hue = ((inBlue - inRed) / dif) + 2.0
		
		elseif inBlue == dMax then
			
			hue = ((inRed - inGreen) / dif) + 4.0
		end
		
		hue = hue * 60.0
	end
	
	return hue, sat, lum
end

-- ----------------------------------------------------------------------------
--
local function HSLToRGB(inHue, inSaturation, inLuma)

	local C = (1.0 - _abs(2.0 * inLuma - 1)) * inSaturation

	local X = C * (1.0 - _abs((inHue / 60.0) % 2 - 1.0))

	local m = inLuma - C / 2.0
	
	local dRed	 = 0.0
	local dGreen = 0.0
	local dBlue	 = 0.0
	
	if 0.0 <= inHue and inHue < 60.0 then
		
		dRed	= C
		dGreen	= X
		
	elseif 60.0 <= inHue and inHue < 120.0 then
		
		dRed	= X
		dGreen	= C
		
	elseif 120.0 <= inHue and inHue < 180.0 then
		
		dGreen	= C
		dBlue	= X
		
	elseif 180.0 <= inHue and inHue < 240.0 then
		
		dGreen	= X
		dBlue	= C
		
	elseif 240.0 <= inHue and inHue < 300.0 then
		
		dRed	 = X
		dBlue	 = C
		
	else
		
		dRed	 = C
		dBlue	 = X
	end
	
	dRed = _floor((dRed + m) * 255.0)
	if 0.00000 > dRed then dRed = 0 end
	
	dGreen = _floor((dGreen + m) * 255.0)
	if 0.00000 > dGreen then dGreen = 0 end
	
	dBlue = _floor((dBlue + m) * 255.0)
	if 0.00000 > dBlue then	dBlue = 0 end

	return dRed, dGreen, dBlue
end

-------------------------------------------------------------------------------
--
local HSLColour	 	= {}
HSLColour.__index	= HSLColour
HSLColour.__eq		= HSLColour.equal

-- ----------------------------------------------------------------------------
--
function HSLColour.new(inHue, inSat, inLum)

	inHue = inHue or 0.000
	inSat = inSat or 0.000
	inLum = inLum or 0.000
	
	if 0.000 > inHue then inHue = 0.000 end
	if 0.000 > inSat then inSat = 0.000 end
	if 0.000 > inLum then inLum = 0.000 end
	
	if 360.000 < inHue then	inHue = 360.000 end
	if   1.000 < inSat then inSat =   1.000 end
	if   1.000 < inLum then inLum =   1.000 end
	
	local t =
	{
		H = inHue, 
		S = inSat, 
		L = inLum,
	}

	return setmetatable(t, HSLColour)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.equal(self, b)

	return (self.H == b.H) and (self.S == b.S) and (self.L == b.L)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.toString(self)

	return _frmt("H: %8.4f S: %.4f L: %.4f", self.H, self.S, self.L)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.fromHSL(h, s, l)

	return HSLColour.new(h, s, l)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.fromRGB(r, g, b)

	return HSLColour.new(RGBToHSL(r, g, b))
end

-- ----------------------------------------------------------------------------
--
function HSLColour.toRGB(self)

	return HSLToRGB(self.H, self.S, self.L)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.hue(self, inHue)
	
   return HSLColour.new(inHue % 360, self.S, self.L)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.offset(self, inOffset)
	
   return HSLColour.new((self.H + inOffset) % 360, self.S, self.L)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.saturation(self, saturation)
	
   return HSLColour.new(self.H, saturation, self.L)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.saturate(self, infraction)
	
   return HSLColour.new(self.H, self.S * infraction, self.L)
end	 

-- ----------------------------------------------------------------------------
--
function HSLColour.luminance(self, lightness)
	
   return HSLColour.new(self.H, self.S, lightness)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.lighten(self, infraction)
	
   return HSLColour.new(self.H, self.S, self.L * infraction)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.stepping(self, inSides, inTarget)
	
	local tStepping	 = { }
	local dStep		 = (inTarget - self.H) / inSides
	local dHue		 = inTarget

	for i=1, inSides do
		
		tStepping[i]  = self:hue(dHue)
		dHue = dHue - dStep
	end

	return tStepping
end

-- ----------------------------------------------------------------------------
--
function HSLColour.vivid(self, inSides, inTarget)
	
	local tVivid = { }
	local dStep  = (inTarget - self.S) / inSides
	local dSatur = inTarget

	for i=1, inSides do
		
		tVivid[i]  = self:saturation(dSatur)
		dSatur = dSatur - dStep
		
--		if 0.0 > dSatur then dSatur = 0.00 end
--		if inTarget < dSatur then dSatur = inTarget end
	end

	return tVivid
end

-- ----------------------------------------------------------------------------
-- if inTarget is 0 then processing shades
-- if inTarget is 1 then processing tints
--
function HSLColour.tints(self, inSides, inTarget)
	
	local tTints = { }
	local dStep	 = (inTarget - self.L) / inSides
	local dLuma  = inTarget

	for i=1, inSides do
		
		tTints[i]  = self:luminance(dLuma)
		dLuma = dLuma - dStep
		
--		if 0.0 > dLuma then dLuma = 0.00 end
--		if inTarget < dLuma then dLuma = inTarget end

		if 0.0 < dStep and inTarget < dLuma then 
			
			dLuma = inTarget
		end
	end

	return tTints
end

-- ----------------------------------------------------------------------------
--
return HSLColour

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
