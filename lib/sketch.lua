--[[
*	Sketch.lua
*
*	A dialog window with some controls to test appereance of colours together.
]]

local wx		= require("wx")
local rybclr	= require("lib.RYBColours")
local trace 	= require("lib.trace")

local _frmt		= string.format
local _byte		= string.byte
local _char		= string.char
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
--	grid_ruler	= {75, 200, 200, 500},				-- size of each column
	use_font	= {12, "Calibri"},					-- font for grid and tab
}

-- ----------------------------------------------------------------------------
-- combobox
--
local tCbFunctions =
{
	"Background",
	"Foreground",
}

-- ----------------------------------------------------------------------------
-- combobox target
--
local tCbTarget=
{
	"Locked",
	"Window",
	"Group Box",
	"Label",
	"Text Edit",
	"Combo Box",
	"Button",
	"Check Box",
	"Radio Box",
	"List Box",
	"Tree List",
}

-- ----------------------------------------------------------------------------
--
local m_Sketch =
{
	hWindow		= nil,					-- main frame
	tWinProps	= m_tDefWinProp,		-- window layout settings
	
	-- selection
	--
	hFunCb		= nil,					-- functions (back or fore)
	hOptCb		= nil,					-- target
	
	-- targets
	--
	tTargets	= { },
}

-- ----------------------------------------------------------------------------
-- create a filename just for the machine running on
--
local function SettingsName()
	
	return "sketch@" .. wx.wxGetHostName() .. ".ini"
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

	if tSettings then m_Sketch.tWinProps = tSettings end
end

-- ----------------------------------------------------------------------------
-- save a table to the settings file
--
local function SaveSettings()
--	m_logger:line("SaveSettings")

	local fd = io.open(SettingsName(), "w")
	if not fd then return end

	fd:write("local window_ini =\n{\n")

	local tWinProps = m_Sketch.tWinProps
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
local function OnCloseSketch()
--	m_logger:line("OnCloseSketch")
  
	if not m_Sketch.hWindow then return end

	-- need to convert from size to pos
	--
	local pos  = m_Sketch.hWindow:GetPosition()
	local size = m_Sketch.hWindow:GetSize()
	
	-- update the current settings
	--
	local tWinProps = { }
	
	tWinProps.window_xy = {pos:GetX(), pos:GetY()}
	tWinProps.window_wh = {size:GetWidth(), size:GetHeight()}
	tWinProps.use_font	= m_Sketch.tWinProps.use_font				-- just copy over
	
	m_Sketch.tWinProps = tWinProps			-- switch structures

	SaveSettings()								-- write to file

	m_Sketch.hWindow.Destroy(m_Sketch.hWindow)
	m_Sketch.hWindow = nil
end

-- ----------------------------------------------------------------------------
-- a new index for background or foreground has been selected
--
local function OnSetIndex(inIndex)
--	m_trace:line("OnSetIndex")	

	local hFunCb = m_Sketch.hFunCb

	if 0 < inIndex and inIndex <= #tCbFunctions then
		
		hFunCb:SetValue(tCbFunctions[inIndex])
	end
end

-- ----------------------------------------------------------------------------
-- a new colour has been selected
--
local function OnSetColour(inColour)
--	m_trace:line("OnSetColour")	

	local hFunCb = m_Sketch.hFunCb
	local hOptCb = m_Sketch.hOptCb
	
	local iFunc	 = hFunCb:GetCurrentSelection() + 1
	local iOptn	 = hOptCb:GetCurrentSelection() + 1
	
	local hCtrl	 = m_Sketch.tTargets[iOptn]
	if not hCtrl then return false end
	
	local clrRGB = wx.wxColour(inColour:toRGB())
	
	if 1 == iFunc then
		
		hCtrl:SetBackgroundColour(clrRGB)
	else
		
		hCtrl:SetForegroundColour(clrRGB)
	end
	
	m_Sketch.hWindow:Refresh()
end

-- ----------------------------------------------------------------------------
-- create a window
--
local function OnCreateSketch()
--	m_trace:line("OnCreateSketch")

	ReadSettings()

	local tWinProps	= m_Sketch.tWinProps
	
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
	local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "Sketch",
							 wx.wxPoint(pos[1], pos[2]), wx.wxSize(size[1], size[2]), dwFrameFlags)
	frame:SetMinSize(wx.wxSize(300, 250))
	frame:SetBackgroundStyle(wx.wxBG_STYLE_COLOUR)
	frame:SetFont(hFont)
	
	-- ----------------------------------------------
	-- selection of target (ie: foreground + textbox)
	--
	local hFunCb  = wx.wxComboBox(frame, wx.wxID_ANY, "", wx.wxPoint(10, 10), wx.wxSize(170, 35),
								 tCbFunctions, wx.wxCB_DROPDOWN | wx.wxCB_READONLY)
	local hOptCb  = wx.wxComboBox(frame, wx.wxID_ANY, "", wx.wxPoint(200, 10), wx.wxSize(250, 35),
								 tCbTarget, wx.wxCB_DROPDOWN | wx.wxCB_READONLY)

	hFunCb:SetValue(tCbFunctions[1])
	hOptCb:SetValue(tCbTarget[1])

	-- --------------------------
	-- targets for the operations
	--
	local hGroup	= wx.wxStaticBox(frame, wx.wxID_ANY, "Group Box", wx.wxPoint(10, 60), wx.wxSize(640, 390))
	local hLabel	= wx.wxStaticText(hGroup, wx.wxID_ANY, "This is a label", wx.wxPoint(10, 40), wx.wxSize(150, 35))
	local hText		= wx.wxTextCtrl(hGroup, wx.wxID_ANY, "Some text", wx.wxPoint(170, 40), wx.wxSize(150, 35))
	local hCombo	= wx.wxComboBox(hGroup, wx.wxID_ANY, "", wx.wxPoint(10, 90), wx.wxSize(310, 35),
									{"String A", "String B", "String C"}, wx.wxCB_DROPDOWN | wx.wxCB_READONLY)
	local hButton	= wx.wxButton(hGroup, wx.wxID_ANY, "Click Me", wx.wxPoint(340, 40), wx.wxSize(150, 35))
	local hCheck	= wx.wxCheckBox(hGroup, wx.wxID_ANY, "Option", wx.wxPoint(340, 90), wx.wxSize(150, 35))
	local hRadio	= wx.wxRadioBox(hGroup, wx.wxID_ANY, "Either", wx.wxPoint(10, 130), wx.wxSize(310, 100), {"A", "B", "C", "D", "E"})
	local hList		= wx.wxListCtrl(hGroup, wx.wxID_ANY, wx.wxPoint(10, 240), wx.wxSize(310, 135), wx.wxLC_LIST)
	local hTree 	= wx.wxTreeCtrl(hGroup, wx.wxID_ANY, wx.wxPoint(340, 145), wx.wxSize(290, 230))
	
	-- select the first
	--
	hCombo:SetValue("String A")
	
	-- fill the list control with some items
	--
	for i=1, 10 do hList:InsertItem(i, "Item " .. i) end

	-- fill the tree control with some items
	--
	local root = hTree:AddRoot("Index")
	
	for i=1, 3 do
		
		local chIndx = _char((_byte('A') + i - 1))
		local rootx = hTree:InsertItem(root, root, "List " .. chIndx)
		for i=1, 4 do hTree:InsertItem(rootx, rootx, chIndx .. " " .. i) end
	end

	hTree:Expand(root)

	-- assign event handlers for this frame
	--
--	frame:Connect(wx.wxEVT_SIZE,		 OnSizeSketch)
--	frame:Connect(wx.wxEVT_CLOSE_WINDOW, OnCloseSketch)

	-- assign an icon to frame
	--
	local icon = wx.wxIcon("lib/icons/Sketch.ico", wx.wxBITMAP_TYPE_ICO)
	frame:SetIcon(icon)

	-- store interesting members
	--
	local tTargets = 
	{
		nil,
		frame,
		hGroup,
		hLabel,
		hText,
		hCombo,
		hButton,
		hCheck,
		hRadio,
		hList,
		hTree,
	}
	
	m_Sketch.hWindow  = frame
	m_Sketch.hFunCb	  = hFunCb
	m_Sketch.hOptCb	  = hOptCb
	m_Sketch.tTargets = tTargets
	
	return true
end

-- ----------------------------------------------------------------------------
--
local function SetupPublic()

	m_Sketch.CreateSketch	= OnCreateSketch
	m_Sketch.CloseSketch	= OnCloseSketch
	m_Sketch.SetColour		= OnSetColour
	m_Sketch.SetIndex		= OnSetIndex
end

-- ----------------------------------------------------------------------------
--
SetupPublic()

return m_Sketch

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
