--[[
*	Scope.lua
*
*	Display alternative backgrounds for the foreground colour selected.
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
	tLabels  =
	{	
		"F.", 			-- the actual foreground colour
		"60", 			-- triadic l.
		"120", 			-- analogous l.
		"180", 				-- original
		"240", 			-- analogous r.
		"300", 			-- triadic r.
	},
}

-- ----------------------------------------------------------------------------
--
local iMaxArray = 15

local m_Scope =
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
	
	return "scope@" .. wx.wxGetHostName() .. ".ini"
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

	if tSettings then m_Scope.tWinProps = tSettings end
end

-- ----------------------------------------------------------------------------
-- save a table to the settings file
--
local function SaveSettings()
--	m_logger:line("SaveSettings")

	local fd = io.open(SettingsName(), "w")
	if not fd then return end

	fd:write("local window_ini =\n{\n")

	local tWinProps = m_Scope.tWinProps
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
local function OnCloseScope()
--	m_logger:line("OnCloseScope")
  
	if not m_Scope.hWindow then return end

	-- need to convert from size to pos
	--
	local pos  = m_Scope.hWindow:GetPosition()
	local size = m_Scope.hWindow:GetSize()
	
	-- update the current settings
	--
	local tWinProps = { }
	
	tWinProps.window_xy = {pos:GetX(), pos:GetY()}
	tWinProps.window_wh = {size:GetWidth(), size:GetHeight()}
	tWinProps.use_font	= m_Scope.tWinProps.use_font				-- just copy over
	
	m_Scope.tWinProps = tWinProps				-- switch structures

	SaveSettings()								-- write to file

	m_Scope.hWindow.Destroy(m_Scope.hWindow)
	m_Scope.hWindow = nil
end

-- ----------------------------------------------------------------------------
-- apply the colour
--
local function OnCellSelected(event)
--	m_trace:line("OnCellSelected")

	local hGrid = m_Scope.hGrid
	
    local iRow	 = event:GetRow()
    local iCol	 = event:GetCol()
	local aValue = hGrid:GetCellBackgroundColour(iRow, iCol)
	
	-- make an hsl colour object
	--
	aValue = hsl.fromRGB(aValue:Red(), aValue:Green(), aValue:Blue())
	
	if 0 == iCol then
		
		m_Scope.tLastClr = aValue
		_G.m_App.ForeColourChanged(aValue, "Scope")
	else
		
		_G.m_App.BackColourChanged(aValue, "Scope")
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
	if not m_Scope.tLastClr then
		
		m_Scope.tLastClr = inColour
	else
		
		if inColour:equal(m_Scope.tLastClr) then return end
	end

	-- check the index
	--
	local hGrid	= m_Scope.hGrid

	if 0 == m_Scope.iCurrIdx then
		
		m_Scope.iCurrIdx = 1
		
		local iCount = hGrid:GetNumberRows() - 1
		hGrid:DeleteRows(iCount, iCount)
		hGrid:InsertRows(0, 1)
	end

	-- assign values to current row
	--
	m_Scope.iCurrIdx = m_Scope.iCurrIdx - 1
	m_Scope.tLastClr = inColour

	-- first column is the foreground colour
	--
	local iIdx = m_Scope.iCurrIdx

	hGrid:SetCellBackgroundColour(iIdx, 0, _wxColour(inColour))

	-- create all backgrounds
	--
	for i=1, #m_Columns.tLabels do
		
		local clrBack = inColour:offset(i * 60.0)
		
		-- reverse the luminance
		--
		if 0.50 < clrBack.L then
		
			clrBack = clrBack:luminance(0.25)
		else
			
			clrBack = clrBack:luminance(0.85)
		end
	
		hGrid:SetCellBackgroundColour(iIdx, i, _wxColour(clrBack))
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

	local tWinProps = m_Scope.tWinProps
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
	local tLabels 	= m_Columns.tLabels

	inGrid:CreateGrid(m_Scope.iMaxStack, #tLabels)
	inGrid:SetLabelFont(fntLbl)
	inGrid:SetGridLineColour(_wxColour(_colours.Gray25))

	for i=1, #tLabels do
		
		inGrid:SetColSize(i - 1, iSize)						-- size
		inGrid:SetColAttr(i - 1, tAttrs)					-- style
		inGrid:SetColLabelValue(i - 1, tLabels[i])			-- labels
	end

	inGrid:DisableDragRowSize()
	inGrid:DisableDragCell()
	inGrid:SetSelectionMode(0)
	inGrid:EnableEditing(false)
end

-- ----------------------------------------------------------------------------
-- create a window
--
local function OnCreateScope()
--	m_trace:line("OnCreateScope")

	ReadSettings()

	local tWinProps	= m_Scope.tWinProps
	
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
	local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Background",
							 wx.wxPoint(pos[1], pos[2]), wx.wxSize(size[1], size[2]), dwFrameFlags)
	frame:SetMinSize(wx.wxSize(300, 250))
	frame:SetBackgroundStyle(wx.wxBG_STYLE_COLOUR)
	frame:SetFont(hFont)
	
	local newGrid = wx.wxGrid(frame, wx.wxID_ANY, wx.wxDefaultPosition, frame:GetSize()) 
	SetGridStyles(newGrid)

	newGrid:Connect(wx.wxEVT_GRID_SELECT_CELL, OnCellSelected)

	-- assign event handlers for this frame
	--
--	frame:Connect(wx.wxEVT_SIZE,		 OnSizeScope)
--	frame:Connect(wx.wxEVT_CLOSE_WINDOW, OnCloseScope)

	-- assign an icon to frame
	--
	local icon = wx.wxIcon("lib/icons/Scope.ico", wx.wxBITMAP_TYPE_ICO)
	frame:SetIcon(icon)

	m_Scope.hWindow	= frame
	m_Scope.hGrid 	= newGrid
	
	return true
end

-- ----------------------------------------------------------------------------
--
local function SetupPublic()

	m_Scope.CreateScope	= OnCreateScope
	m_Scope.CloseScope	= OnCloseScope
	m_Scope.SetColour	= OnSetColour
end

-- ----------------------------------------------------------------------------
--
SetupPublic()

return m_Scope

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
