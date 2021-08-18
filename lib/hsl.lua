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

-------------------------------------------------------------------------------
--
local HSLColour	 = {}
HSLColour.__index = HSLColour

-- ----------------------------------------------------------------------------
--
local function new(inHue, inSat, inLum)

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

-- ----------------------------------------------------------------------------
--
function HSLColour.toString(self)

	return _frmt("H: %8.4f S: %.4f L: %.4f", self.H, self.S, self.L)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.fromHSL(h, s, l)

	return new(h, s, l)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.fromRGB(r, g, b)

	return new(RGBToHSL(r, g, b))
end

-- ----------------------------------------------------------------------------
--
function HSLColour.toRGB(self)

	return HSLToRGB(self.H, self.S, self.L)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.hue_offset(self, delta)
	
   return new((self.H + delta) % 360, self.S, self.L)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.complementary(self)
	
   return self:hue_offset(180.0)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.neighbors(self, inAngle)
	
   local angle = inAngle or 30.0
   
   return self:hue_offset(angle), self:hue_offset(360.0 - angle)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.triadic(self)
	
   return self:neighbors(120.0)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.split_complementary(self, angle)
	
   return self:neighbors(180.0 - (angle or 30.0))
end

-- ----------------------------------------------------------------------------
--
function HSLColour.desaturate_to(self, saturation)
	
   return new(self.H, saturation, self.L)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.desaturate_by(self, r)
	
   return new(self.H, self.S * r, self.L)
end	 

-- ----------------------------------------------------------------------------
--
function HSLColour.lighten_to(self, lightness)
	
   return new(self.H, self.S, lightness)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.variations(self, fx, iSides)
	
	iSides = iSides or 5
	
	local tVariations = { }

	for i=1, iSides do
		
		_insert(tVariations, fx(self, i, iSides))
	end

	return tVariations
end

-- ----------------------------------------------------------------------------
--
function HSLColour.tints(self, inSides, inOffset)
	
	local function fx(color, i, inSides)
		
		return color:lighten_to(color.L + (inOffset / i))
	end

	return self:variations(fx, inSides)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.desaturate(self, inSides, inOffset)
	
	local function fx(color, i, inSides)
		
		return color:desaturate_to(inOffset / i)
	end

	return self:variations(fx, inSides)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.offset(self, inSides, inOffset)
	
	local function fx(color, i, inSides)
		
		return color:hue_offset(inOffset * i)
	end

	return self:variations(fx, inSides)
end

-- ----------------------------------------------------------------------------
--
function HSLColour.adjoin(self, inSides, inOffset)

	local tList  = { }
	local iTimes = inSides / 2 

	for i=1, iTimes do
		
		local a, b = self:neighbors(inOffset / i)
		
		tList[i] 		= new(a.H, a.S, 0.500)
		tList[i+iTimes] = new(b.H, b.S, 0.500)
	end
	
	return tList
end

-- ----------------------------------------------------------------------------
--
return HSLColour

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
