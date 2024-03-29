--[[
*	Pyramid.lua
*
*   Octagons with different tints of a colour.
]]

local wx		= require("wx")
local Shape		= require("lib.Shape")
local palette	= require("lib.RYBColours")
local hsl_con	= require("lib.hsl")

local _cos		= math.cos
local _sin		= math.sin
local _rad		= math.rad

local _wxColour	= palette.wxColour
local _colours	= palette.tColours

local m_PenNull	= wx.wxPen(_wxColour(_colours.Gray0), 1, wx.wxTRANSPARENT)

-------------------------------------------------------------------------------
--
local Pyramid	= { }
Pyramid.__index = Pyramid

-- ----------------------------------------------------------------------------
-- objects factory
--
function Pyramid.new(inFunction, inRadius, inOctagons, inOctaSides)

	inRadius = inRadius or 10
	if 0 > inRadius then inRadius = 10 end

	inOctagons = inOctagons or 4
	if 0 > inOctagons then inOctagons = 4 end

	inFunction = inFunction or "Offset"
	if 0 == #inFunction then inFunction = "Offset" end
	
	inOctaSides = inOctaSides or 6

	local t =
	{
		sFunction	= inFunction,
		iCenterX	= 0,
		iCenterY	= 0,
		iRadius 	= inRadius,
		
		iMaxOctgn	= inOctagons,
		iOctaSides	= inOctaSides,
		tOctagons	= { },
		iHitOctgn	= 0,
		
		clrLines	= _colours.Gray0,
		clrFill		= _colours.Gray100,
	}

	local ret = setmetatable(t, Pyramid)
	
	-- allocate octagons
	--
	local iSize  = inRadius / inOctagons
	local iSides = ret.iOctaSides
	
	for i=1, ret.iMaxOctgn do
		
		ret.tOctagons[i] = Shape.new(inRadius - ((i - 1) * iSize), iSides)
	end

	return ret
end

-- ----------------------------------------------------------------------------
-- set the origin
--
function Pyramid.SetOrigin(self, inOriginX, inOriginY)
	
	self.iCenterX = inOriginX
	self.iCenterY = inOriginY
	
	for i=1, self.iMaxOctgn do
		
		self.tOctagons[i]:SetOrigin(inOriginX, inOriginY)
	end
end

-- ----------------------------------------------------------------------------
-- set the hue
--
function Pyramid.SetHueOffset(self)

	local clrStart	= self.clrFill
	local iSides	= self.iOctaSides
	local dDegStep = 60.0 / (self.iMaxOctgn * iSides)	-- step in degrees
	
	-- make tables for each octagon
	--
	for i=1, self.iMaxOctgn do
		
		local tColours = { }
		
		for j=1, iSides do
			
			tColours[j] = clrStart
			
			clrStart = clrStart:offset(dDegStep)
		end
		
		self.tOctagons[i].tColours = tColours
	end
end

-- ----------------------------------------------------------------------------
-- set the saturation
--
function Pyramid.SetSaturation(self)

	local color  = self.clrFill
	local iSides = self.iOctaSides

	-- make tables for each octagon
	--
	for i=1, self.iMaxOctgn do
		
		local tColours = { }
		
		for j=1, iSides do
			
			tColours[j] = color
			
			color = color:saturate(0.75)
		end
		
		-- assign the table
		--
		self.tOctagons[i].tColours = tColours
	end
end

-- ----------------------------------------------------------------------------
-- set the lumincance
--
function Pyramid.SetLuminance(self)

	local color  = self.clrFill
	local iSides = self.iOctaSides

	-- make tables for each octagon
	--
	for i=1, self.iMaxOctgn do
		
		local tColours = { }
		
		for j=1, iSides do
			
			tColours[j] = color
			
			color = color:lighten(1.0125)
		end
		
		-- assign the table
		--
		self.tOctagons[i].tColours = tColours
	end
end

-- ----------------------------------------------------------------------------
-- set the colours, expects hsl objects
--
function Pyramid.SetColours(self, inColourVertices, inColourFiller)

	self.clrLines = inColourVertices
	self.clrFill  = inColourFiller
	
	if "Offset" == self.sFunction then
		
		self:SetHueOffset()
		
	elseif "Saturation" == self.sFunction then
		
		self:SetSaturation()
		
	elseif "Luminance" == self.sFunction then
		
		self:SetLuminance()
	end
end

-- ----------------------------------------------------------------------------
-- return the colour for the indexed slice or nothing
--
function Pyramid.ColourAt(self, inIndex)
	
	if 0 < self.iHitOctgn then
		
		return self.tOctagons[self.iHitOctgn]:ColourAt(inIndex)
	end
	
	return _colours.Gray0
end

-- ----------------------------------------------------------------------------
-- return the slice the point is in or 0
--
function Pyramid.HitTest(self, inPoint)

	-- backwards
	--
	for i=self.iMaxOctgn, 1, -1 do
		
		local iIndex = self.tOctagons[i]:HitTest(inPoint)
		
		if 0 < iIndex then
			
			self.iHitOctgn = i
			return iIndex, self:ColourAt(iIndex)
		end
	end
	
	self.iHitOctgn = 0
	return 0, nil
end

-- ----------------------------------------------------------------------------
-- draw the shape
--
function Pyramid.Draw(self, inDc)

	for i=1, self.iMaxOctgn do
		
		self.tOctagons[i]:Draw(inDc)
	end
	
	if 1 < self.iMaxOctgn then
		
		-- draw a trapezoid for highlighting the original colour
		--
		local tVerts1 = self.tOctagons[1].tVertices
		local tVerts2 = self.tOctagons[2].tVertices
		local tPoints = { }
		
		tPoints[#tPoints + 1] = tVerts1[1]
		tPoints[#tPoints + 1] = tVerts1[2]
		tPoints[#tPoints + 1] = tVerts2[2]
		tPoints[#tPoints + 1] = tVerts2[1]
		tPoints[#tPoints + 1] = tVerts1[1]
		
		inDc:SetPen(wx.wxPen(_wxColour(self.clrLines), 3, wx.wxSOLID))
		
		inDc:DrawLines(tPoints, 0, 0)
		
		inDc:SetPen(m_PenNull)
	end
end

-- ----------------------------------------------------------------------------
--
return Pyramid

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
