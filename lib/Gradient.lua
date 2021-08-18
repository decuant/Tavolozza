--[[
*	Gradient.lua
*
*   Octagon with tints of a colour.
]]

local wx		= require("wx")
local palette	= require("lib.RYBColours")
local hsl_con	= require("lib.hsl")

local _cos		= math.cos
local _sin		= math.sin
local _rad		= math.rad

local _wxColour	= palette.wxColour
local _colours	= palette.tColours

local m_PenNull	= wx.wxPen(_wxColour(_colours.Gray0), 1, wx.wxTRANSPARENT)

-- ----------------------------------------------------------------------------
-- generic to test if a point lies inside a triangle
--
local function _ptInTriangle(inPoint, inVert1, inVert2, inVert3)

	function sign(inPt1, inPt2, inPt3)
		
		return (inPt1[1] - inPt3[1]) * (inPt2[2] - inPt3[2]) - (inPt2[1] - inPt3[1]) * (inPt1[2] - inPt3[2])
	end

    local d1 = sign(inPoint, inVert1, inVert2)
    local d2 = sign(inPoint, inVert2, inVert3)
    local d3 = sign(inPoint, inVert3, inVert1)

    local has_neg = ((d1 < 0.0) or (d2 < 0.0)) or (d3 < 0.0)
    local has_pos = ((d1 > 0.0) or (d2 > 0.0)) or (d3 > 0.0)

    return not (has_neg and has_pos)
end

-------------------------------------------------------------------------------
--
local TintsOct	 = { }
TintsOct.__index = TintsOct

-- ----------------------------------------------------------------------------
-- objects factory
--
function TintsOct.New(inRadius)

	local t =
	{
		iCenterX	= 0,
		iCenterY	= 0,
		dRadius		= 1.0,
		tVertices	= { },
		
		clrLines	= _colours.Gray0,
		clrFill		= _colours.Gray100,
		tTints		= { },
	}

	local ret = setmetatable(t, TintsOct)
	
	-- here we fill in the tables
	--
	ret:SetRadius(inRadius)
	ret:SetColours(_colours.Gray0, _colours.Gray100)

	return ret
end

-- ----------------------------------------------------------------------------
-- set the radius
--
function TintsOct.SetRadius(self, inRadius)
	
	local dRadius = inRadius or self.dRadius
	if 0.1 > dRadius then dRadius = 0.1 end
	
	local iDegrees	= 0
	local iCenterX	= self.iCenterX
	local iCenterY	= self.iCenterY
	local tVertices = { }
	
	while 360 >= iDegrees do
		
		local pt = {iCenterX + _cos(_rad(iDegrees)) * dRadius, iCenterY + _sin(_rad(iDegrees)) * dRadius}
		
		tVertices[#tVertices + 1] = pt
		
		iDegrees = iDegrees + 45
	end
	
	self.dRadius	= dRadius
	self.tVertices	= tVertices
end

-- ----------------------------------------------------------------------------
-- set the origin
--
function TintsOct.SetOrigin(self, inOriginX, inOriginY)
	
	self.iCenterX = inOriginX
	self.iCenterY = inOriginY
	
	self:SetRadius()
end

-- ----------------------------------------------------------------------------
-- set the colors, expects hsl objects
--
function TintsOct.SetColours(self, inColourVertices, inColourFiller)
	
	self.clrLines = inColourVertices
	self.clrFill  = inColourFiller
	
	-- store tints for all slices
	--
	self.tTints	  = inColourFiller:tints(#self.tVertices - 2, 2.00)
	table.insert(self.tTints, 1, inColourFiller)	-- original color
end

-- ----------------------------------------------------------------------------
-- return the tint for the indexed slice or nothing
--
function TintsOct.ColorAt(self, inIndex)
	
	if 0 < inIndex and inIndex <= #self.tVertices then
		
		return self.tTints[inIndex]
	end
	
	return nil
end

-- ----------------------------------------------------------------------------
-- return the slice the point is in or 0
--
function TintsOct.HitTest(self, inPoint)
	
	local tVertices	= self.tVertices
	local tPoints 	= { }

	tPoints[1] = {self.iCenterX, self.iCenterY}		-- shared vertex
	
	for i=1, #tVertices - 1 do
		
		tPoints[2] = {tVertices[i][1], tVertices[i][2]}
		tPoints[3] = {tVertices[i+1][1], tVertices[i+1][2]}
		
		if _ptInTriangle(inPoint, tPoints[1], tPoints[2], tPoints[3]) then
			
			return i
		end
	end

	return 0
end

-- ----------------------------------------------------------------------------
-- draw the shape
--
function TintsOct.Draw(self, inDc)

	-- draw the vertices
	--
	local tVertices	= self.tVertices

	inDc:SetPen(wx.wxPen(_wxColour(self.clrLines), 1, wx.wxSOLID))
	inDc:DrawLines(tVertices, 0, 0)
	inDc:SetPen(m_PenNull)

	-- draw the contents
	--
	local tTints	= self.tTints
	local tPoints 	= { }

	tPoints[1] = {self.iCenterX, self.iCenterY}		-- shared vertex

	for i=1, #tVertices - 1 do
		
		tPoints[2] = {tVertices[i][1], tVertices[i][2]}
		tPoints[3] = {tVertices[i+1][1], tVertices[i+1][2]}
		
		inDc:SetBrush(wx.wxBrush(_wxColour(tTints[i]), wx.wxSOLID))
		inDc:DrawPolygon(tPoints, 0, 0, wx.wxWINDING_RULE)
	end
end

-- ----------------------------------------------------------------------------
--
return TintsOct

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

