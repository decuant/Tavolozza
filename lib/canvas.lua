--[[
*	canvas.lua
*
*   .
]]

local wx		= require("wx")
local trace 	= require("lib.trace")
local palette	= require("lib.RYBColours")
local hsl_con	= require("lib.hsl")

local _insert	= table.insert
local _remove	= table.remove

local _wxColour	= palette.wxColour
local _colours	= palette.tColours

-- ----------------------------------------------------------------------------
-- attach tracing to the container
--
local m_trace = trace.new("wxHSL")

-------------------------------------------------------------------------------
--
local Canvas	= { }
Canvas.__index	= Canvas

-- ----------------------------------------------------------------------------
-- list of created panels, allows to match with self in Windows' events
-- tuple { win id, lua self }
-- a list might be an overside structure since this panel is only used once
-- at run-time in this application, but the idea...
--
local m_tPanels = { }

-- ----------------------------------------------------------------------------
-- get the 'self'
--
local function RoutingTable_Get(inWinId)

	for _, aSelf in next, m_tPanels do
		
		if aSelf[1] == inWinId then return aSelf[2] end
	end

	-- this is a serious error
	--
	return nil
end

-- ----------------------------------------------------------------------------
-- get the 'self'
--
local function RoutingTable_Add(inWinId, inSelf)

	if not RoutingTable_Get(inWinId) then
		
		m_tPanels[#m_tPanels + 1] = { inWinId, inSelf }
	end
end

-- ----------------------------------------------------------------------------
-- remove link
--
local function RoutingTable_Del(inWinId)

	for i, aSelf in next, m_tPanels do
		
		if aSelf[1] == inWinId then _remove(m_tPanels, i) return end
	end
end

-- ----------------------------------------------------------------------------
-- constants
--
local m_BoxingX		= 10			-- deflate amount for window's client rect
local m_BoxingY		= 10			--	"		"		"		"		"	"

--local m_defFont		= "Lucida Console"

-- ----------------------------------------------------------------------------
--
local tDefColours =
{
	clrBackground	= _colours.Gray50,
	clrForeground	= _colours.Gray0,	
--	clrText			= _colours.Blu,
}

-- ----------------------------------------------------------------------------
-- objects factory
--
function Canvas.New()

	local t =
	{
		--	default values
		--	
		hWindow		= nil,		-- window's handle
		
		iSizeX		= 600,		-- width of the client area
		iSizeY		= 400,		-- height of the client area
								-- deflated coords of window's client rect
		rcClip		= { left   = 0,
						top    = 0,
						right  = 0,
						bottom = 0,
					  },

		iRasterOp	= wx.wxCOPY, 	-- wx.wxAND_REVERSE,
		bRasterOp	= false,		-- use a raster operation
		
		hBackDc		= nil,			-- background device context
		hForeDc		= nil,			-- device context for the foreground
		
		tColours	= tDefColours,		
		penDefault	= nil,
		brushBack	= nil,			-- brush for background		
		
		tObjects	= { },			-- list of objects
	}

	return setmetatable(t, Canvas)
end

-- ----------------------------------------------------------------------------
-- will return the wxWindow handle
--
function Canvas.GetHandle(self)
--	m_trace:line("Canvas.GetHandle")

	return self.hWindow
end

-- ----------------------------------------------------------------------------
-- add a shape to the list
--
function Canvas.AddObject(self, inObject)
--	m_trace:line("Canvas.AddObject")
	
	_insert(self.tObjects, inObject)
end

-- ----------------------------------------------------------------------------
--
function Canvas.SetForeColour(self, inColour)
--	m_trace:line("Canvas.SetForeColour")

	self.tColours.clrForeground = inColour

	self:Refresh()
end

-- ----------------------------------------------------------------------------
--
function Canvas.SetBackColour(self, inColour)
--	m_trace:line("Canvas.SetBackColour")

	self.tColours.clrBackground = inColour

	self:CreateGDIObjs()
	self:Refresh()
end

-- ----------------------------------------------------------------------------
--
function Canvas.CreateGDIObjs(self)
--	m_trace:line("Canvas.CreateGDIObjs")

	local tColours	= self.tColours
	local clrBack	= _wxColour(tColours.clrBackground)
	local clrFore	= _wxColour(tColours.clrForeground)
	
	-- when creating a pen wider than 2 wxWidgets will try to round it
	-- thus showing a little line at both ends when set at 3 pixels wide.
	-- with CAP_BUTT wxWidgets will square the end
	--
	self.penDefault	= wx.wxPen(clrFore, 1, wx.wxSOLID)
	self.penDefault:SetCap(wx.wxCAP_BUTT)

	self.brushBack	= wx.wxBrush(clrBack, wx.wxSOLID)
end

-- ----------------------------------------------------------------------------
--
function Canvas.NewMemDC(self)
--	m_trace:line("Canvas.NewMemDC")

	local iWidth  = self.iSizeX
	local iHeight = self.iSizeY

	-- create a bitmap wide as the client area
	--
	local memDC = self.hForeDc

	if not memDC then

		local bitmap = wx.wxBitmap(iWidth, iHeight)
		
		memDC  = wx.wxMemoryDC()
		memDC:SelectObject(bitmap)
	end

	-- draw the background
	--
	if not self.hBackDc then return nil end

	memDC:Blit(0, 0, iWidth, iHeight, self.hBackDc, 0, 0, wx.wxCOPY)

	-- draw the shapes
	--	
	local oldRaster	= memDC:GetLogicalFunction()

	if self.bRasterOp then memDC:SetLogicalFunction(self.iRasterOp) end
	
	for _, object in next, self.tObjects do
		
		object:Draw(memDC)
	end
	
	if self.bRasterOp then memDC:SetLogicalFunction(oldRaster) end

	return memDC
end

-- ----------------------------------------------------------------------------
-- create a legenda and a grid
--
function Canvas.NewBackground(self)
--	m_trace:line("Canvas.NewBackground")
	
	local iWidth	= self.iSizeX
	local iHeight	= self.iSizeY
	
	-- check for valid arguments when creating the bitmap
	--
	if 0 >= iWidth or 0 >= iHeight then return nil end
	
	-- create a bitmap wide as the client area
	--
	local memDC  = wx.wxMemoryDC()
 	local bitmap = wx.wxBitmap(iWidth, iHeight)
	memDC:SelectObject(bitmap)
	
	-- set the back color
	-- (note that Clear uses the background brush for clearing)
	--
	memDC:SetBackground(self.brushBack)
	memDC:Clear()

	return memDC
end

-- ----------------------------------------------------------------------------
--
function Canvas.RefreshBackground(self)
--	m_trace:line("Canvas.RefreshBackground")
	
	if self.hBackDc then
		self.hBackDc:delete()
		self.hBackDc = nil
	end

	self.hBackDc = self:NewBackground()
end

-- ----------------------------------------------------------------------------
--
function Canvas.RefreshDrawing(self)
--	m_trace:line("Canvas.RefreshDrawing")

	if self.hForeDc then
		self.hForeDc:delete()
		self.hForeDc = nil
	end	

	self.hForeDc = self:NewMemDC()
end

-- ----------------------------------------------------------------------------
--
function Canvas.CreateCanvas(self, inOwner)
--	m_trace:line("Canvas.CreateCanvas")

	-- create the panel, derived from wxWindow
	-- deriving from wxPanel raises problems on get focus
	-- if not using the wxWANTS_CHARS flag won't respond to
	-- the wxEVT_KEY_DOWN for the 4 cursor arrows, only the 
	-- wxEVT_KEY_UP instead, thus using wxWANTS_CHARS is imperative
	--
	local hWindow = wx.wxWindow(inOwner, wx.wxID_ANY,
								wx.wxDefaultPosition, 
								wx.wxDefaultSize,
								wx.wxWANTS_CHARS)

	-- responds to events
	--
	hWindow:Connect(wx.wxEVT_PAINT,		Canvas.OnPaint)
	hWindow:Connect(wx.wxEVT_SIZE,		Canvas.OnSize)
--	hWindow:Connect(wx.wxEVT_MOUSEWHEEL,Canvas.OnMouseWheel)
--	hWindow:Connect(wx.wxEVT_KEY_UP,	Canvas.OnKeyUp)
--	hWindow:Connect(wx.wxEVT_KEY_DOWN,	Canvas.OnKeyDown)
	hWindow:Connect(wx.wxEVT_LEFT_UP,	Canvas.OnLeftBtnUp)
	hWindow:Connect(wx.wxEVT_RIGHT_UP,	Canvas.OnRightBtnUp)

	-- this is necessary to avoid flickering
	-- wxBG_STYLE_CUSTOM deprecated use wxBG_STYLE_PAINT
	--
	hWindow:SetBackgroundStyle(wx.wxBG_STYLE_PAINT)
	
	-- set not using wxBufferedDC anyway
	-- (shouldn't be needed though)
	--
	hWindow:SetDoubleBuffered(false)

	-- store interesting members
	--
	self.hWindow = hWindow

	-- add object window to list of objects
	--
	RoutingTable_Add(hWindow:GetId(), self)

	-- create the permanent GDI objects with some defaults
	--
	self:CreateGDIObjs()
	
	return true
end

-- ----------------------------------------------------------------------------
--
function Canvas.Refresh(self)
--	m_trace:line("Canvas.Refresh")
	
	self:RefreshBackground()
	self:RefreshDrawing()
	
	-- call Invalidate
	--
	local hWindow = self.hWindow

	if hWindow then hWindow:Refresh(true) end	
end

-- ----------------------------------------------------------------------------
--
function Canvas.OnClose(event)
--	m_trace:line("Canvas.OnClose")

	-- simply remove from windows' list
	--
	RoutingTable_Del(event:GetId())
end

-- ----------------------------------------------------------------------------
--
function Canvas.OnPaint(event)
--	m_trace:line("Canvas.OnPaint")

	local aSelf = RoutingTable_Get(event:GetId())
	local winDc = wx.wxPaintDC(aSelf.hWindow)

	winDc:Blit(0, 0, aSelf.iSizeX, aSelf.iSizeY, aSelf.hForeDc, 0, 0, wx.wxCOPY)
	winDc:delete()
end

-- ----------------------------------------------------------------------------
--
function Canvas.OnSize(event)
--	m_trace:line("Canvas.OnSize")

	local size   = event:GetSize()
	local aSelf  = RoutingTable_Get(event:GetId())
	local rcClip = aSelf.rcClip
	
	aSelf.iSizeX = size:GetWidth()
	aSelf.iSizeY = size:GetHeight()
	
	rcClip.left  = m_BoxingX / 2
	rcClip.top   = m_BoxingY / 2
	rcClip.right = aSelf.iSizeX - m_BoxingX / 2
	rcClip.bottom= aSelf.iSizeY - m_BoxingY / 2
	
	aSelf.rcClip = rcClip
	
	aSelf:Refresh()
end

-- ----------------------------------------------------------------------------
-- handle the mouse wheel, modify the zoom factor
-- if key press CTRL then handles the X otherwise the Y
--
function Canvas.OnMouseWheel(event)
--	m_trace:line("Canvas.OnMouseWheel")

	local aSelf = RoutingTable_Get(event:GetId())

	-- Update display
	--
--	aSelf:Refresh()
end

-- ----------------------------------------------------------------------------
-- handle drawing's options from keyboard
--
function Canvas.OnKeyUp(event)
--	m_trace:line("Canvas.OnKeyUp")

	local aSelf 	= RoutingTable_Get(event:GetId())
	local key		= event:GetKeyCode() - 48
	local bRefresh 	= false

	-- Update display
	--
--	if bRefresh then aSelf:Refresh() end
end

-- ----------------------------------------------------------------------------
--
function Canvas.OnKeyDown(event)
--	m_trace:line("Canvas.OnKeyDown")

	local aSelf = RoutingTable_Get(event:GetId())
	local key	= event:GetKeyCode()
	local bAlt	= event:AltDown()

	-- Update display
	--
--	aSelf:Refresh()
end

-- ----------------------------------------------------------------------------
-- get the object that the user clicked in
--
function Canvas.ColorFromPoint(self, event)
--	m_trace:line("Canvas.ColorFromPoint")

	local iPtX, iPtY = event:GetLogicalPosition(self.hForeDc):GetXY()
	
	for _, object in next, self.tObjects do
		
		local iIndex, aColour = object:HitTest({iPtX, iPtY})
		
		if 0 < iIndex and aColour then return aColour, object.sFunction end
	end

	return nil
end

-- ----------------------------------------------------------------------------
-- change the current color if clicked object
--
function Canvas.OnLeftBtnUp(event)
--	m_trace:line("Canvas.OnLeftBtnUp")

	local aSelf	 = RoutingTable_Get(event:GetId())
	
	local aColour, sFunction = aSelf:ColorFromPoint(event)
	
	if aColour then
		
		_G.m_App.ForeColourChanged(aColour, sFunction)
	end
end

-- ----------------------------------------------------------------------------
-- change the current color if clicked object
--
function Canvas.OnRightBtnUp(event)
--	m_trace:line("Canvas.OnRightBtnUp")
	
	local aSelf	 = RoutingTable_Get(event:GetId())
	
	local aColour, sFunction = aSelf:ColorFromPoint(event)
	
	if aColour then
		
		_G.m_App.BackColourChanged(aColour, sFunction)
	end
end

-- ----------------------------------------------------------------------------
--
return Canvas

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
