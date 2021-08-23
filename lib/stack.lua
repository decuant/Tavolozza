--[[
*	sideframe.lua
*
]]

local wx		= require("wx")
local rybclr	= require("lib.RYBColours")
local hsl		= require("lib.hsl")
local trace 	= require("lib.trace")

local _frmt		= string.format
local _byte		= string.byte
local _char		= string.char

local _wxColour	= rybclr.wxColour
local _colours	= rybclr.tColours

-- ----------------------------------------------------------------------------
--
local m_trace = trace.new("wxHSL")

-- ----------------------------------------------------------------------------
-- default dialog size and position
--
local m_tDefWinProp =
{
	window_xy	= {20,	 20},						-- top, left
	window_wh	= {700,	450},						-- width, height
	use_font	= {12, "Calibri"},					-- font for grid and tab
}

-- ----------------------------------------------------------------------------
-- columns for the grid
-- at center column is the original colour
--
local m_Columns =
{
	iColSize = 75,
	tAngles  = 
	{	
		150, 			-- split-complementary l.
		120, 			-- triadic l.
		30, 			-- analogous l.
		0, 				-- original
		330, 			-- analogous r.
		240, 			-- triadic r.
		210,			-- split-complementary r.
	},
}

-- ----------------------------------------------------------------------------
--
local iMaxArray = 15

local m_Stack =
{
	hWindow		= nil,					-- main frame
	tWinProps	= m_tDefWinProp,		-- window layout settings
	
	hGrid		= nil,
	iMaxStack	= iMaxArray,			-- max grid's rows
	iCurrIdx	= iMaxArray,			-- stack's index
	
	tLastClr	= nil,					-- filter additions
}

-- ----------------------------------------------------------------------------
-- create a filename just for the machine running on
--
local function SettingsName()
	
	return "stack@" .. wx.wxGetHostName() .. ".ini"
end

-- ----------------------------------------------------------------------------
-- read dialogs' settings from settings file
--
local function ReadSettings()
--	m_logger:line("ReadSettings")

	local sFilename = SettingsName()

	local fd = io.open(sFilename, "r")
	if not fd then return end

	fd:close()

	local tSettings = dofile(sFilename)

	if tSettings then m_Stack.tWinProps = tSettings end
end

-- ----------------------------------------------------------------------------
-- save a table to the settings file
--
local function SaveSettings()
--	m_logger:line("SaveSettings")

	local fd = io.open(SettingsName(), "w")
	if not fd then return end

	fd:write("local window_ini =\n{\n")

	local tWinProps = m_Stack.tWinProps
	local sLine

	sLine = _frmt("\twindow_xy\t= {%d, %d},\n", tWinProps.window_xy[1], tWinProps.window_xy[2])
	fd:write(sLine)

	sLine = _frmt("\twindow_wh\t= {%d, %d},\n", tWinProps.window_wh[1], tWinProps.window_wh[2])
	fd:write(sLine)

	sLine = _frmt("\tuse_font\t= {%d, \"%s\"},\n", tWinProps.use_font[1], tWinProps.use_font[2])
	fd:write(sLine)	

	fd:write("}\n\nreturn window_ini\n")
	io.close(fd)
end

-- ----------------------------------------------------------------------------
-- called when closing the window
--
local function OnCloseStack()
--	m_logger:line("OnCloseStack")
  
	if not m_Stack.hWindow then return end

	-- need to convert from size to pos
	--
	local pos  = m_Stack.hWindow:GetPosition()
	local size = m_Stack.hWindow:GetSize()
	
	-- update the current settings
	--
	local tWinProps = { }
	
	tWinProps.window_xy = {pos:GetX(), pos:GetY()}
	tWinProps.window_wh = {size:GetWidth(), size:GetHeight()}
	tWinProps.use_font	= m_Stack.tWinProps.use_font				-- just copy over
	
	m_Stack.tWinProps = tWinProps				-- switch structures

	SaveSettings()								-- write to file

	m_Stack.hWindow.Destroy(m_Stack.hWindow)
	m_Stack.hWindow = nil
end

-- ----------------------------------------------------------------------------
-- apply the colour
--
local function OnCellSelected(event)
--	m_trace:line("OnCellSelected")

	local hGrid = m_Stack.hGrid
	
    local iRow	 = event:GetRow()
    local iCol	 = event:GetCol()
	local aValue = hGrid:GetCellBackgroundColour(iRow, iCol)
	
	-- make an hsl colour object
	--
	aValue = hsl.fromRGB(aValue:Red(), aValue:Green(), aValue:Blue())
	
	if 3 == iCol then
		
		m_Stack.tLastClr = aValue
		_G.m_App.ForeColourChanged(aValue, "Stack")
	else
		
		_G.m_App.BackColourChanged(aValue, "Stack")
	end
	
	-- put a mark
	--
	hGrid:SetCellTextColour(iRow, iCol, _wxColour(aValue:offset(180)))
	hGrid:SetCellValue(iRow, iCol, "*")
end

-- ----------------------------------------------------------------------------
-- a new colour has been selected, add to the stack
--
local function OnSetColour(inColour)
--	m_trace:line("OnSetColour")

	-- chcek if colour changed
	--
	if not m_Stack.tLastClr then
		
		m_Stack.tLastClr = inColour
	else
		
		if inColour == m_Stack.tLastClr then return end
	end

	-- check the index
	--
	local hGrid	= m_Stack.hGrid

	if 0 == m_Stack.iCurrIdx then
		
		m_Stack.iCurrIdx = 1
		
		local iCount = hGrid:GetNumberRows() - 1
		hGrid:DeleteRows(iCount, iCount)
		hGrid:InsertRows(0, 1)
	end

	-- assign values to current row
	--
	m_Stack.iCurrIdx = m_Stack.iCurrIdx - 1
	m_Stack.tLastClr = inColour
	
	local iIdx = m_Stack.iCurrIdx
	local tOff = m_Columns.tAngles

	for i=1, #tOff do
	
		hGrid:SetCellBackgroundColour(iIdx, i - 1, _wxColour(inColour:offset(tOff[i])))
	end
	
	-- check it visible
	--
	if not hGrid:IsVisible(iIdx, 0) then hGrid:MakeCellVisible(iIdx, 0) end

	hGrid:Refresh()
end

-- ----------------------------------------------------------------------------
-- apply styles to the grid's elements
--
local function SetGridStyles(inGrid)
--	m_logger:line("SetGridStyles")

	local tWinProps = m_Stack.tWinProps
	local iFontSize	= tWinProps.use_font[1]
	local sFontname	= tWinProps.use_font[2]
	
	local fntCell = wx.wxFont( iFontSize, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL,
							   wx.wxFONTWEIGHT_BOLD, false, sFontname, wx.wxFONTENCODING_SYSTEM)

	local fntLbl  = wx.wxFont( iFontSize - 5, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_SLANT,
							   wx.wxFONTWEIGHT_LIGHT, false, sFontname, wx.wxFONTENCODING_SYSTEM)

	local clrFore = _wxColour(_colours.Gray100)
	local clrBack = _wxColour(_colours.Gray0)

	local tAttrs = wx.wxGridCellAttr(clrFore, clrBack, fntCell, wx.wxALIGN_CENTRE, wx.wxALIGN_CENTRE)

	-- properties for columns
	--
	local iSize 	= m_Columns.iColSize
	local tAngles 	= m_Columns.tAngles

	inGrid:CreateGrid(m_Stack.iMaxStack, #tAngles)
	inGrid:SetLabelFont(fntLbl)
	inGrid:SetGridLineColour(_wxColour(_colours.Gray25))

	for i=1, #tAngles do
		
		inGrid:SetColSize(i - 1, iSize)							-- size
		inGrid:SetColAttr(i - 1, tAttrs)						-- style
		inGrid:SetColLabelValue(i - 1, tostring(tAngles[i]))	-- labels
	end

	inGrid:DisableDragRowSize()
	inGrid:DisableDragCell()
	inGrid:SetSelectionMode(0)
	inGrid:EnableEditing(false)
end

-- ----------------------------------------------------------------------------
-- create a window
--
local function OnCreateStack()
--	m_trace:line("OnCreateStack")

	ReadSettings()

	local tWinProps	= m_Stack.tWinProps
	
	-- create a font
	--
	local iFontSize	= tWinProps.use_font[1]
	local sFontname	= tWinProps.use_font[2]

	local hFont = wx.wxFont( iFontSize, wx.wxFONTFAMILY_MODERN, wx.wxFONTFLAG_ANTIALIASED,
							 wx.wxFONTWEIGHT_BOLD, false, sFontname)

	-- flags in use for the main frame
	--
	local dwFrameFlags	= wx.wxSYSTEM_MENU | wx.wxCAPTION | wx.wxRESIZE_BORDER
	
	-- starting position and dimensions
	--
	local pos  = tWinProps.window_xy
	local size = tWinProps.window_wh

	-- create the frame
	--
	local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Colours stack",
							 wx.wxPoint(pos[1], pos[2]), wx.wxSize(size[1], size[2]), dwFrameFlags)
	frame:SetMinSize(wx.wxSize(300, 250))
	frame:SetBackgroundStyle(wx.wxBG_STYLE_COLOUR)
	frame:SetFont(hFont)
	
	local newGrid = wx.wxGrid(frame, wx.wxID_ANY, wx.wxDefaultPosition, frame:GetSize()) 
	SetGridStyles(newGrid)

	newGrid:Connect(wx.wxEVT_GRID_SELECT_CELL, OnCellSelected)

	-- assign event handlers for this frame
	--
--	frame:Connect(wx.wxEVT_SIZE,		 OnSizeSideframe)
	frame:Connect(wx.wxEVT_CLOSE_WINDOW, OnCloseStack)

	-- assign an icon to frame
	--
	local icon = wx.wxIcon("lib/icons/Tavolozza.ico", wx.wxBITMAP_TYPE_ICO)
	frame:SetIcon(icon)

	m_Stack.hWindow	= frame
	m_Stack.hGrid 	= newGrid
	
	return true
end

-- ----------------------------------------------------------------------------
--
local function SetupPublic()

	m_Stack.CreateStack	= OnCreateStack
	m_Stack.CloseStack	= OnCloseStack
	m_Stack.SetColour	= OnSetColour
end

-- ----------------------------------------------------------------------------
--
SetupPublic()

return m_Stack

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
