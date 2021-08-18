--[[
*	main.lua
*
]]

local wx		= require("wx")
local canvfctr 	= require("lib.canvas")
local rybclr	= require("lib.RYBColours")
local Pyramid	= require("lib.Pyramid")
local Palette	= require("lib.Palette")
local Slider	= require("lib.Slider")
local SideFrame	= require("lib.sideframe")
local trace 	= require("lib.trace")

local _frmt		= string.format
local _colours	= rybclr.tColours
local m_Sketch	= SideFrame

-- ----------------------------------------------------------------------------
--
local m_trace = trace.new("wxHSL")

-- ----------------------------------------------------------------------------
--
local m_App = 
{
	sAppVersion	= "0.0.3",				-- application's version
	sAppName	= "Tavolozza",			-- name for the application
	sRelDate 	= "2021/08/16",
	
	tPalette	= nil,
	tControls	= { },
	tTints		= nil,
	
	tForeColour	= _colours.__Vermillion,
	tBackColour	= _colours.__Teal,
}

_G.m_App = m_App						-- make it globally visible

-- ----------------------------------------------------------------------------
-- default dialog size and position
--
local m_tDefWinProp =
{
	window_xy	= {20,	 20},						-- top, left
	window_wh	= {990,	580},						-- width, height
	use_font	= {12, "Calibri"},					-- font for grid and tab
}

-- ----------------------------------------------------------------------------
-- default controls' height
--
local m_tDefCtrlsH =
{
	iPyramid	= 300,
	iPalette	= 125,
	iTints		= 35
}

-- ----------------------------------------------------------------------------
--
local m_Mainframe =
{
	hWindow		= nil,					-- main frame
	hCanvas		= nil,					-- panel
	
	tWinProps	= m_tDefWinProp,		-- window layout settings
}

-- ----------------------------------------------------------------------------
-- create a filename just for the machine running on
--
local function SettingsName()
	
	return "palette@" .. wx.wxGetHostName() .. ".ini"
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

	if tSettings then m_Mainframe.tWinProps = tSettings end
end

-- ----------------------------------------------------------------------------
-- save a table to the settings file
--
local function SaveSettings()
--	m_logger:line("SaveSettings")

	local fd = io.open(SettingsName(), "w")
	if not fd then return end

	fd:write("local window_ini =\n{\n")

	local tWinProps = m_Mainframe.tWinProps
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
-- when a new foreground color is selected
--
local function OnForeColourChanged(inColour, inFunction)
--	m_logger:line("OnForeColourChanged")

	if not inColour then return end
	m_trace:line("Current foreground: " .. inColour:toString())

	if "Tints" ~= inFunction then
		
		m_App.tTints:SetColours(_colours.Gray0, inColour)
	end

	local tControls = m_App.tControls

	for i=1, #tControls do
		
		tControls[i]:SetColours(_colours.Gray0, inColour)
	end

	-- update the sketch dialog
	--
	m_Sketch.SetIndex(2)					-- make a choice
	m_Sketch.SetColour(inColour)			-- apply color

	-- store and apply
	--
	m_App.tForeColour = inColour
	m_Mainframe.hCanvas:SetForeColour(inColour)	
end

-- ----------------------------------------------------------------------------
-- when a new background color is selected
--
local function OnBackColourChanged(inColour, inFunction)
--	m_logger:line("OnBackColourChanged")	
	
	if not inColour then return end
	m_trace:line("Current background: " .. inColour:toString())
	
	-- update the sketch dialog
	--
	m_Sketch.SetIndex(1)					-- make a choice
	m_Sketch.SetColour(inColour)			-- apply color
	
	-- store and apply
	--
	m_App.tBackColour = inColour
	m_Mainframe.hCanvas:SetBackColour(inColour)	
end

-- ----------------------------------------------------------------------------
-- Simple interface to pop up a message
--
local function DlgMessage(message)

	wx.wxMessageBox(message, m_App.sAppName,
					wx.wxOK + wx.wxICON_INFORMATION, m_Mainframe.hWindow)
end

-- ----------------------------------------------------------------------------
--
local function OnAbout()

	DlgMessage(_frmt(	"%s [%s] Rel. date [%s]\n %s, %s, %s",
						m_App.sAppName, m_App.sAppVer, m_App.sRelDate,
						_VERSION, wxlua.wxLUA_VERSION_STRING, wx.wxVERSION_STRING))
end

-- ----------------------------------------------------------------------------
-- called when closing the window
--
local function OnCloseMainframe()
--	m_logger:line("OnCloseMainframe")
  
	if not m_Mainframe.hWindow then return end
	
	m_Sketch.CloseSideframe()

	-- need to convert from size to pos
	--
	local pos  = m_Mainframe.hWindow:GetPosition()
	local size = m_Mainframe.hWindow:GetSize()
	
	-- update the current settings
	--
	local tWinProps = { }
	
	tWinProps.window_xy = {pos:GetX(), pos:GetY()}
	tWinProps.window_wh = {size:GetWidth(), size:GetHeight()}
	tWinProps.use_font	= m_Mainframe.tWinProps.use_font				-- just copy over
	
	m_Mainframe.tWinProps = tWinProps			-- switch structures

	SaveSettings()								-- write to file

	m_Mainframe.hWindow.Destroy(m_Mainframe.hWindow)
	m_Mainframe.hWindow = nil
end

-- ----------------------------------------------------------------------------
--
local function OnSize(event)
--	m_trace:line("OnSize")

	local sizeWin = m_Mainframe.hWindow:GetClientRect()

	if not next(m_App.tControls) then 
		
		event:Skip()
		return 
	end

	local iRadius	= m_App.tControls[1].iRadius
	local iDiameter = iRadius * 2
	local iSpace	= (sizeWin:GetWidth() - (iDiameter * 3)) / 4
	local iOffset	= iSpace + iRadius
	
	for i, pyramid in next, m_App.tControls do
		
		pyramid:SetOrigin((iSpace + iDiameter) * (i - 1) + iOffset, m_tDefCtrlsH.iPyramid)
	end

	m_App.tPalette:SetSize(sizeWin:GetWidth(), m_tDefCtrlsH.iPalette)
	m_App.tTints:SetSize(sizeWin:GetWidth(), m_tDefCtrlsH.iTints)

	event:Skip()	-- let the event fall through
end

-- ----------------------------------------------------------------------------
-- DPI chnaged
--
local function OnDPIChanged(event)
	m_trace:line("OnDPIChanged")
	
	event:Skip()	-- let the event fall through
end

-- ----------------------------------------------------------------------------
-- create a window
--
local function CreateMainFrame(inAppTitle)
--	m_trace:line("CreateMainFrame")

	ReadSettings()

	local tWinProps = m_Mainframe.tWinProps

	local pos  = tWinProps.window_xy
	local size = tWinProps.window_wh
	
--	local iFontSize	= tWinProps.use_font[1]
--	local sFontname	= tWinProps.use_font[2]
	
	-- create the frame
	--
	local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, inAppTitle,
							 wx.wxPoint(pos[1], pos[2]), wx.wxSize(size[1], size[2]))
	frame:SetMinSize(wx.wxSize(300, 250))
	
	-- create the canvas
	--
	local canvas = canvfctr.New()
	canvas:CreateCanvas(frame, 10, 10)

	-- assign event handlers for this frame
	--
	frame:Connect(wx.wxEVT_SIZE,		 OnSize)
	frame:Connect(wx.wxEVT_CLOSE_WINDOW, OnCloseMainframe)
	frame:Connect(wx.wxEVT_DPI_CHANGED,	 OnDPIChanged)
	
	-- assign an icon to frame
	--
	local icon = wx.wxIcon("lib/icons/Tavolozza.ico", wx.wxBITMAP_TYPE_ICO)
	frame:SetIcon(icon)

	-- store interesting members
	--
	m_Mainframe.hWindow	= frame
	m_Mainframe.hCanvas	= canvas

	return true
end

-- ----------------------------------------------------------------------------
--
local function Layout()
	
	-- ----------------------------------------------------------------------------
	--
	local function Setup()
		
		local rcRYB = Palette.New("Palette", 200, 125)
		rcRYB:SetTopLeft(0, 0)
		
		local clrStart = _colours.__Vermillion
		
		--
		-- inTitle, inRadius, inOctagons, inType
		--
		local pyramid1 = Pyramid.New("Offset", 		150, 3, 10)
		local pyramid2 = Pyramid.New("Saturation",	150, 3, 4)
		local pyramid3 = Pyramid.New("Luminance", 	150, 3, 8)

		local rcSlide1 = Slider.New("Tints", 300, m_tDefCtrlsH.iTints)
		rcSlide1:SetTopLeft(0, 475)
		
		m_App.tPalette	= rcRYB
		m_App.tControls	= {pyramid1, pyramid2, pyramid3}
		m_App.tTints	= rcSlide1
		m_App.tForeColor= clrStart
	end

	-- compile and import functions
	--
	Setup()

	m_Mainframe.hCanvas:AddObject(m_App.tPalette)
	m_Mainframe.hCanvas:AddObject(m_App.tTints)
	m_Mainframe.hCanvas:AddObject(m_App.tControls[1])
	m_Mainframe.hCanvas:AddObject(m_App.tControls[2])
	m_Mainframe.hCanvas:AddObject(m_App.tControls[3])
end

-- ----------------------------------------------------------------------------
--
local function RunApplication()

	local sAppTitle = m_App.sAppName .. " [" .. m_App.sAppVersion .. "]"
	
	m_trace:open()
	m_trace:time(sAppTitle .. " started")
	
	assert(os.setlocale('us', 'all'))
	m_trace:line("Current locale is [" .. os.setlocale() .. "]")

	wx.wxGetApp():SetAppName(sAppTitle)

	if CreateMainFrame(sAppTitle) and m_Sketch.CreateSideframe() then
		
		Layout()
		
		m_Mainframe.hWindow:Show(true)
		m_Sketch.hWindow:Show(true)
		
		OnBackColourChanged(m_App.tBackColour)
		OnForeColourChanged(m_App.tForeColour)		
		
		wx.wxGetApp():SetTopWindow(m_Mainframe.hWindow)
		wx.wxGetApp():MainLoop()
	end

	m_trace:newline(sAppTitle .. " terminated ###")
	m_trace:close()
end

-- ----------------------------------------------------------------------------
--
local function SetupPublic()

	m_App.ForeColourChanged = OnForeColourChanged
	m_App.BackColourChanged = OnBackColourChanged

end

-- ----------------------------------------------------------------------------
--
SetupPublic()
RunApplication()

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
