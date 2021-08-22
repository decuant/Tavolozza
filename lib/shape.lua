--[[
*	Shape.lua
*
*   Shape built within a circle having a number of edges.
]]

local wx		= require("wx")
local palette	= require("lib.RYBColours")
local hsl_con	= require("lib.hsl")

local _cos		= math.cos
local _sin		= math.sin
local _rad		= math.rad
local _ceil		= math.ceil

local _wxColour	= palette.wxColour
local _colours	= palette.tColours

local m_PenNull	= wx.wxPen(_wxColour(_colours.Gray50), 1, wx.wxTRANSPARENT)

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
local Shape	 = { }
Shape.__index = Shape

-- ----------------------------------------------------------------------------
-- objects factory
--
function Shape.new(inRadius, inSides)

	inSides = inSides or 3
	if 3 > inSides then inSides = 3 end
	if 100 < inSides then inSides = 100 end

	local t =
	{
		iCenterX	= 0,
		iCenterY	= 0,
		dRadius		= 1.0,
		iSides		= inSides,
		iStep		= inStep or 0,
		tVertices	= { },
		
		clrLines	= _colours.Gray0,
		clrFill		= _colours.Gray100,
		tColours	= { },
	}

	local ret = setmetatable(t, Shape)
	
	-- here we fill in the tables
	--
	ret:SetRadius(inRadius)
	return ret
end

-- ----------------------------------------------------------------------------
-- set the radius
--
function Shape.SetRadius(self, inRadius)
	
	local dRadius = inRadius or self.dRadius
	if 0.1 > dRadius then dRadius = 0.1 end
	
	local dDegrees	= 0.000
	local dDegStep	= 360.000 / self.iSides
	local iCenterX	= self.iCenterX
	local iCenterY	= self.iCenterY
	local tVertices = { }
	
	for i=1, (self.iSides + 1) do
		
		local pt = {iCenterX + _cos(_rad(dDegrees)) * dRadius, iCenterY + _sin(_rad(dDegrees)) * dRadius}
		
		tVertices[i] = pt
		
		dDegrees = dDegrees + dDegStep
	end
	
	self.dRadius	= dRadius
	self.tVertices	= tVertices
end

-- ----------------------------------------------------------------------------
-- set the origin
--
function Shape.SetOrigin(self, inOriginX, inOriginY)
	
	self.iCenterX = inOriginX
	self.iCenterY = inOriginY
	
	self:SetRadius()
end

-- ----------------------------------------------------------------------------
-- return the tint for the indexed slice or nothing
--
function Shape.ColourAt(self, inIndex)
	
	if 0 < inIndex and inIndex <= #self.tVertices then
		
		return self.tColours[inIndex]
	end
	
	return self.tTints[1]
end

-- ----------------------------------------------------------------------------
-- return the slice the point is in or 0
--
function Shape.HitTest(self, inPoint)
	
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
function Shape.Draw(self, inDc)
	
	if not next(self.tColours) then return end
	
	-- draw the contents
	--
	local tPoints	= {{self.iCenterX, self.iCenterY}}	-- shared vertex
	local tVertices	= self.tVertices
	local i			= 0
	
	inDc:SetPen(m_PenNull)
	
	for i, colour in next, self.tColours do
		
		if (i + 1) > #tVertices then break end
		
		tPoints[2] = {tVertices[i][1], tVertices[i][2]}
		tPoints[3] = {tVertices[i+1][1], tVertices[i+1][2]}
		
		inDc:SetBrush(wx.wxBrush(_wxColour(colour), wx.wxSOLID))
		inDc:DrawPolygon(tPoints, 0, 0, wx.wxWINDING_RULE)
	end
end

-- ----------------------------------------------------------------------------
--
return Shape

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

