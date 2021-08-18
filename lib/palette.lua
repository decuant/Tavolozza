--[[
*	Palette.lua
*
*	Display the predefined colours in the RYB (painters) palette.
]]

local wx		= require("wx")
local palette	= require("lib.RYBColours")
local hsl_con	= require("lib.hsl")

local _floor	= math.floor

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
local Palette	 = { }
Palette.__index = Palette

-- ----------------------------------------------------------------------------
-- objects factory
--
function Palette.New(inFunction)

	local t =
	{
		sFunction	= inFunction or "Palette",
		iTopX		= 0,
		iTopY		= 0,
		dSizeX		= 100,
		dSizeY		= 100,

		tVertices	= { },
		
		clrLines	= _colours.Gray0,
		
		tColours	= 
		{
			_colours.Red,				-- primary
			_colours.Yellow,
			_colours.Blue,
	
			_colours._Orange,			-- secondary
			_colours._Green,
			_colours._Purple,

			_colours.__Vermillion,		-- tertiary
			_colours.__Amber,
			_colours.__Chartreuse,
			_colours.__Teal,
			_colours.__Violet,
			_colours.__Magenta,

			_colours.Gray0,
			_colours.Gray25,
			_colours.Gray50,
			_colours.Gray75,
			_colours.Gray100,
		},
	}

	return setmetatable(t, Palette)
end

-- ----------------------------------------------------------------------------
-- set the origin
--
function Palette.SetTopLeft(self, inTopX, inTopY)
	
	self.iTopX = inTopX
	self.iTopY = inTopY
	
	self:Layout()
end

-- ----------------------------------------------------------------------------
-- set the size
--
function Palette.SetSize(self, inWidth, inHeight)
	
	self.dSizeX = inWidth
	self.dSizeY = inHeight
	
	self:Layout()
end

-- ----------------------------------------------------------------------------
-- set the size
--
function Palette.SetWidth(self, inWidth)
	
	self.dSizeX = inWidth
	
	self:Layout()
end

-- ----------------------------------------------------------------------------
-- set the size
--
function Palette.SetHeight(self, inHeight)
	
	self.dSizeY = inHeight
	
	self:Layout()
end

-- ----------------------------------------------------------------------------
-- allocate rectangles
--
function Palette.Layout(self)

	local tVertices	= { }
	local iSpace	= 5					-- space between rects
	local iTopX		= iSpace + self.iTopX
	local iTopY		= iSpace + self.iTopY
	
	getwidth = function(iCount)
		
		return ((self.dSizeX - (iSpace * (iCount - 1)) - (iSpace * 2)) / iCount)
	end
	
	getheight = function(iCount)
		
		return ((self.dSizeY - (iSpace * (iCount - 1)) - (iSpace * 2)) / iCount)
	end	

	-- create 1 rect for each colour
	-- divided by groups
	--
	local dWidth  = getwidth(3)		-- this is the witdh of each reactangle
	local dHeight = getheight(4)	-- height of rects won't change per line
	
	-- Primary
	--
	tVertices[1] = { iTopX, iTopY, dWidth, dHeight }

	for i=2, 3 do
		
		iTopX		 = iTopX + dWidth + iSpace
		tVertices[i] = { iTopX, iTopY, dWidth, dHeight }
	end

	-- Secondary
	--
	dWidth 	= getwidth(3)
	iTopX	= iSpace + self.iTopX
	iTopY	= iSpace + dHeight + iSpace + self.iTopY

	for i=4, 6 do
		
		tVertices[i] = { iTopX, iTopY, dWidth, dHeight }
		iTopX		 = iTopX + dWidth + iSpace
	end

	-- Tertiary
	--
	dWidth 	= getwidth(6)
	iTopX	= iSpace + self.iTopX
	iTopY	= iSpace + (dHeight + iSpace) * 2 + self.iTopY

	for i=7, 12 do
		
		tVertices[i] = { iTopX, iTopY, dWidth, dHeight }
		iTopX		 = iTopX + dWidth + iSpace
	end

	-- Grey Shades
	--
	dWidth 	= getwidth(5)
	iTopX	= iSpace + self.iTopX
	iTopY	= iSpace + (dHeight + iSpace) * 3 + self.iTopY

	for i=13, 17 do
		
		tVertices[i] = { iTopX, iTopY, dWidth, dHeight }
		iTopX		 = iTopX + dWidth + iSpace
	end

	-- assign to object
	--
	self.tVertices = tVertices
end

-- ----------------------------------------------------------------------------
-- set the colours, expects hsl objects
--
function Palette.SetColours(self, inColourVertices, inColourFiller)
	
	self.clrLines = inColourVertices
	self.clrFill  = inColourFiller
end

-- ----------------------------------------------------------------------------
-- return the colour for the indexed rect or nothing
--
function Palette.ColourAt(self, inIndex)
	
	if 0 < inIndex and inIndex <= #self.tColours then
		
		return self.tColours[inIndex]
	end
	
	return nil
end

-- ----------------------------------------------------------------------------
-- return the rectangle the point is in or 0
--
function Palette.HitTest(self, inPoint)
	
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
function Palette.Draw(self, inDc)

	inDc:SetPen(wx.wxPen(_wxColour(self.clrLines), 1, wx.wxSOLID))

	local tVertices	= self.tVertices
	local current
	
	for i, colour in next, self.tColours do
		
		if i > #tVertices then break end
		
		inDc:SetBrush(wx.wxBrush(_wxColour(colour), wx.wxSOLID))
		
		current = tVertices[i]
		
		inDc:DrawRectangle(current[1], current[2], 
						   current[3], current[4])
	end

	inDc:SetPen(m_PenNull)
end

-- ----------------------------------------------------------------------------
--
return Palette

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
