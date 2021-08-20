--[[
*	Tints.lua
*
*   Octagon with tints of a colour.
]]

local wx		= require("wx")
local palette	= require("lib.RYBColours")
local hsl_con	= require("lib.hsl")

local _floor	= math.floor
local _ceil		= math.ceil

local _wxColour	= palette.wxColour
local _colours	= palette.tColours

local m_PenNull	= wx.wxPen(_wxColour(_colours.Gray0), 1, wx.wxTRANSPARENT)

-- ----------------------------------------------------------------------------
-- return whether the point is in the rect
--
local function _ptInRect(inPoint, inTopX, inTopY, inBottomX, inBottomY)
	
	if inTopX <= inPoint[1] and inBottomX >= inPoint[1] then
		
		if inTopY <= inPoint[2] and inBottomY >= inPoint[2] then
			
			return true
		end
	end

	return false
end

-------------------------------------------------------------------------------
--
local Tints	= { }
Tints.__index	= Tints

-- ----------------------------------------------------------------------------
-- objects factory
--
function Tints.New(inFunction, inSizeX, inSizeY)

	inFunction = inFunction or "Tints"
	if 0 == #inFunction then inFunction = "Tints" end
	
	local t =
	{
		sFunction	= inFunction,
		iTopX		= 0,
		iTopY		= 0,
		iSizeX		= inSizeX,
		iSizeY		= inSizeY,
		iSlices		= 16,
		tVertices	= { },
		
		clrLines	= _colours.Gray0,
		tColours	= { },
	}

	return setmetatable(t, Tints)
end

-- ----------------------------------------------------------------------------
-- set the origin
--
function Tints.SetTopLeft(self, inTopX, inTopY)
	
	self.iTopX = inTopX
	self.iTopY = inTopY
	
	self:Layout()
end

-- ----------------------------------------------------------------------------
-- set the size
--
function Tints.SetSize(self, inWidth, inHeight)
	
	self.iSizeX = inWidth
	self.iSizeY = inHeight
	
	self:Layout()
end

-- ----------------------------------------------------------------------------
-- return the slice the point is in or 0
--
function Tints.Layout(self)

	local tVertices	= { }
	local iSpace	= 5
	local iSlices	= self.iSlices
	local iTopX		= self.iTopX + iSpace
	local iTopY		= self.iTopY + iSpace
	local iSizeX	= ((self.iSizeX - (iSpace * 2)) / iSlices)
	local iSizeY	= self.iSizeY - (iSpace * 2)

	for i=1, iSlices do
		
		tVertices[i] = { iTopX + 2, iTopY + 2, iSizeX - 4, iSizeY - 4}
		
		iTopX = self.iTopX + _floor(iSizeX * i) + iSpace
	end

	self.tVertices = tVertices
end

-- ----------------------------------------------------------------------------
-- set the colours, expects hsl objects
--
function Tints.SetColours(self, inColourVertices, inColourFiller)
	
	self.clrLines = inColourVertices

	local tColours1	= inColourFiller:tints(self.iSlices / 2, -0.5)
	local tColours2	= inColourFiller:tints(self.iSlices / 2,  0.5)

	self.tColours = tColours1
	self.tColours[#self.tColours + 1] = inColourFiller
	
	for i=#tColours2, 1, -1 do
		
		self.tColours[#self.tColours + 1] = tColours2[i]
	end
end

-- ----------------------------------------------------------------------------
-- return the colour for the indexed slice or nothing
--
function Tints.ColourAt(self, inIndex)
	
	if 0 < inIndex and inIndex <= #self.tColours then
		
		return self.tColours[inIndex]
	end
	
	return nil
end

-- ----------------------------------------------------------------------------
-- return the slice the point is in or 0
--
function Tints.HitTest(self, inPoint)

	local tVertices	= self.tVertices

	for i, vector in next, tVertices do
		
		if _ptInRect(inPoint, vector[1], vector[2], vector[1] + vector[3], vector[2] + vector[4]) then
			
			return i, self:ColourAt(i)
		end
	end

	return 0
end

-- ----------------------------------------------------------------------------
-- draw the shape
--
function Tints.Draw(self, inDc)

	local tVertices	= self.tVertices
	local i 		= 0
	local iIndex  	= _floor(#self.tColours / 2) + 1
	local current	= tVertices[iIndex]
	
	if not current then return end
	
	-- draw a rectangle for highlighting the original colour
	--
	inDc:SetPen(wx.wxPen(_wxColour(self.clrLines), 3, wx.wxSOLID))
	
	inDc:DrawRectangle(current[1] - 1, current[2] - 1,
					   current[3] + 2, current[4] + 2)

	inDc:SetPen(m_PenNull)	
	
	-- draw all rectangles (without border)
	--
	for _, colour in next, self.tColours do
		
		i = i + 1
		if i > #tVertices then break end
		
		inDc:SetBrush(wx.wxBrush(_wxColour(colour), wx.wxSOLID))
		
		current = tVertices[i]
		inDc:DrawRectangle(current[1], current[2],
						   current[3], current[4])
	end
end

-- ----------------------------------------------------------------------------
--
return Tints

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
