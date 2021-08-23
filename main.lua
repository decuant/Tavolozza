--[[
*	main.lua
*
]]

local wx		= require("wx")
local hsl 		= require("lib.hsl")
local rybclr	= require("lib.RYBColours")
local Canvas 	= require("lib.canvas")
local Pyramid	= require("lib.pyramid")
local Palette	= require("lib.palette")
local Ribbon	= require("lib.ribbon")
local Sketch	= require("lib.sketch")
local Stack 	= require("lib.stack")
local trace 	= require("lib.trace")

local _frmt		= string.format
local _floor	= math.floor

local _colours	= rybclr.tColours
local m_Sketch	= Sketch
local m_Stack	= Stack

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
	
	bLocked		= false,
	tPalette	= nil,
	tControls	= { },
	tRibbon		= nil,
	
	tForeColour	= hsl .fromRGB(0, 255, 0),    -- _colours._Green,
	tBackColour	= _colours.__Magenta,
	
	tProxIndx	= 60.0,
	tProxStep	= 60.0,
}

_G.m_App = m_App						-- make it globally visible

-- ----------------------------------------------------------------------------
-- default dialog size and position
--
local m_tDefWinProp =
{
	window_xy	= {20,	 20},			-- top, left
	window_wh	= {990,	580},			-- width, height
	use_font	= {12, "Calibri"},		-- font for grid and tab
	dpi_scale	= 1.0,					-- scaling
}

-- ----------------------------------------------------------------------------
-- default controls' height
--
local m_tSizes =
{
	iPyramid	= 300,
	iPalette	= 150,
	iRibbon		= 40,
	iRadius		= 150,
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
--	m_trace:line("ReadSettings")

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
--	m_trace:line("SaveSettings")

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

	sLine = _frmt("\tdpi_scale\t= %.2f,\n", tWinProps.dpi_scale)
	fd:write(sLine)	
	
	fd:write("}\n\nreturn window_ini\n")
	io.close(fd)
end

-- ----------------------------------------------------------------------------
-- when a new foreground color is selected
--
local function OnForeColourChanged(inColour, inFunction)
--	m_trace:line("OnForeColourChanged")

	if not inColour then return end
	m_trace:line("Current foreground: " .. inColour:toString())

	if not m_App.bLocked then
		
		if "Ribbon" ~= inFunction then
			
			m_App.tRibbon:SetColours(inColour:offset(180.0), inColour)
		end
		
		local tControls = m_App.tControls
		
		for i=1, #tControls do
			
			tControls[i]:SetColours(inColour:offset(180.0), inColour)
		end
	end

	-- update the sketch dialog
	--
	m_Sketch.SetIndex(2)					-- make a choice
	m_Sketch.SetColour(inColour)			-- apply color
	
	m_Stack.SetColour(inColour)

	-- store and apply
	--
	m_App.tForeColour = inColour
	m_Mainframe.hCanvas:SetForeColour(inColour)	
end

-- ----------------------------------------------------------------------------
-- when a new background color is selected
--
local function OnBackColourChanged(inColour, inFunction)
--	m_trace:line("OnBackColourChanged")
	
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
-- allows selection but dows not propagate it
--
local function OnEditLock()
--	m_trace:line("OnEditLock")

	-- toggle state
	--
	m_App.bLocked = not m_App.bLocked

	-- set a check mark in the related menu
	--
	local hMenu = m_Mainframe.hWindow:GetMenuBar()
	local iItem = hMenu:FindMenuItem("Edit", "Lock")

	if 0 < iItem then hMenu:Check(iItem, m_App.bLocked) end
end

-- ----------------------------------------------------------------------------
-- alternative background
--
local function OnEditAltBack()
--	m_trace:line("OnEditAltBack")

	local bLocked = m_App.bLocked

	m_App.bLocked = false

	-- reset to start
	--
	if 360.0 <= m_App.tProxIndx then
		
		m_App.tProxIndx = m_App.tProxStep
	end

	local clrHue = m_App.tForeColour

	clrHue = clrHue:offset(m_App.tProxIndx)
	
	-- reverse the luminance
	--
	if 0.50 < clrHue.L then
	
		clrHue = clrHue:luminance(0.25)
	else
		
		clrHue = clrHue:luminance(0.85)
	end
	
	-- apply and display
	--
	OnBackColourChanged(clrHue, "Offset")

	m_App.tProxIndx = m_App.tProxIndx + m_App.tProxStep
	m_App.bLocked	= bLocked
end

-- ----------------------------------------------------------------------------
-- Simple interface to pop up a message
--
local function DlgMessage(inMessage)

	wx.wxMessageBox(inMessage, m_App.sAppName,
					wx.wxOK + wx.wxICON_INFORMATION, m_Mainframe.hWindow)
end

-- ----------------------------------------------------------------------------
-- Generate a unique new wxWindowID
--
local ID_IDCOUNTER = wx.wxID_HIGHEST + 1
local NewMenuID = function()
	
	ID_IDCOUNTER = ID_IDCOUNTER + 1
	return ID_IDCOUNTER
end

-- ----------------------------------------------------------------------------
--
local function OnImport()
--	m_trace:line("OnImport")

end

-- ----------------------------------------------------------------------------
--
local function OnSave()
--	m_trace:line("OnSave")

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
--	m_trace:line("OnCloseMainframe")
  
	if not m_Mainframe.hWindow then return end
	
	m_Sketch.CloseSketch()
	m_Stack.CloseStack()

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
	tWinProps.dpi_scale	= m_Mainframe.tWinProps.dpi_scale				-- "	"	"	"
	
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

	local iRadius	= m_tSizes.iRadius
	local iDiameter = iRadius * 2
	local iSpace	= _floor((sizeWin:GetWidth() - (iDiameter * 3)) / 4)
	local iOffset	= iSpace + iRadius
	
	for i, pyramid in next, m_App.tControls do
		
		pyramid:SetOrigin((iSpace + iDiameter) * (i - 1) + iOffset, m_tSizes.iPalette + iRadius + 10)
	end

	m_App.tPalette:SetSize(sizeWin:GetWidth(), m_tSizes.iPalette)
	
	m_App.tRibbon:SetSize(sizeWin:GetWidth(), m_tSizes.iRibbon)
	m_App.tRibbon:SetTopLeft(0, sizeWin:GetHeight() - m_tSizes.iRibbon - 10)

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
-- scale the default height of objects
--
local function Scale()
	
	local dScale = m_Mainframe.tWinProps.dpi_scale
	
	m_tSizes.iPyramid	= _floor(m_tSizes.iPyramid * dScale)
	m_tSizes.iPalette	= _floor(m_tSizes.iPalette * dScale)
	m_tSizes.iRibbon		= _floor(m_tSizes.iRibbon   * dScale)
	m_tSizes.iRadius	= _floor(m_tSizes.iRadius  * dScale)
end

-- ----------------------------------------------------------------------------
-- create a window
--
local function CreateMainFrame(inAppTitle)
--	m_trace:line("CreateMainFrame")

	ReadSettings()
	Scale()

	local tWinProps = m_Mainframe.tWinProps

	local pos  = tWinProps.window_xy
	local size = tWinProps.window_wh
	
	-- create the frame
	--
	local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, inAppTitle,
							 wx.wxPoint(pos[1], pos[2]), wx.wxSize(size[1], size[2]))
	frame:SetMinSize(wx.wxSize(300, 250))
	
	-- ------------------------------------------------------------------------
	-- create the menus
	--
	local rcMnuImportFile	= NewMenuID()
	local rcMnuSaveFile		= NewMenuID()
	local rcMnuEdLock		= NewMenuID()
	local rcMnuEdAltBack	= NewMenuID()

	local mnuFile = wx.wxMenu("", wx.wxMENU_TEAROFF)

	mnuFile:Append(rcMnuImportFile,	"Import\tCtrl-I",	"Read the settings file")
	mnuFile:Append(rcMnuSaveFile,	"Save\tCtrl-S",		"Write the settings file")
	mnuFile:AppendSeparator()
	mnuFile:Append(wx.wxID_EXIT,    "E&xit\tAlt-X",		"Quit the program")
	
	local mnuEdit = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuEdit:Append(rcMnuEdLock, 	"Lock\tCtrl-L",		"Locks current color palette", wx.wxITEM_CHECK)
	mnuFile:AppendSeparator()
	mnuEdit:Append(rcMnuEdAltBack,	"Foreground III\tAlt-Z",	"Proximi colours")
	
	local mnuHelp = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuHelp:Append(wx.wxID_ABOUT,    "&About",			"About the application")

	-- create the menu bar and associate sub-menus
	--
	local mnuBar = wx.wxMenuBar()

	mnuBar:Append(mnuFile,	"&File")
	mnuBar:Append(mnuEdit,	"&Edit")
	mnuBar:Append(mnuHelp,	"&Help")

	frame:SetMenuBar(mnuBar)
	
	-- create the canvas
	--
	local canvas = Canvas.new()
	canvas:CreateCanvas(frame)

	-- assign event handlers for this frame
	--
	frame:Connect(wx.wxEVT_SIZE,		 OnSize)
	frame:Connect(wx.wxEVT_CLOSE_WINDOW, OnCloseMainframe)
	frame:Connect(wx.wxEVT_DPI_CHANGED,	 OnDPIChanged)
	
	-- menu event handlers
	--
	frame:Connect(rcMnuImportFile,	wx.wxEVT_COMMAND_MENU_SELECTED,	OnImport)
	frame:Connect(rcMnuSaveFile,	wx.wxEVT_COMMAND_MENU_SELECTED,	OnSave)
	
	frame:Connect(rcMnuEdLock,		wx.wxEVT_COMMAND_MENU_SELECTED,	OnEditLock)
	frame:Connect(rcMnuEdAltBack,	wx.wxEVT_COMMAND_MENU_SELECTED,	OnEditAltBack)

	frame:Connect(wx.wxID_EXIT,		wx.wxEVT_COMMAND_MENU_SELECTED, OnCloseMainframe)
	frame:Connect(wx.wxID_ABOUT,	wx.wxEVT_COMMAND_MENU_SELECTED, OnAbout)
	
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
	
	local palette = Palette.new()
	local ribbon  = Ribbon.new("Luminance")

	-- inFunction, inRadius, inOctagons, inType
	--
	local pyramid1 = Pyramid.new("Offset", 		m_tSizes.iRadius, 5, 8)
	local pyramid2 = Pyramid.new("Saturation",	m_tSizes.iRadius, 2, 6)
	local pyramid3 = Pyramid.new("Luminance", 	m_tSizes.iRadius, 3, 10)

	m_App.tPalette	= palette
	m_App.tControls	= {pyramid1, pyramid2, pyramid3}
	m_App.tRibbon	= ribbon

	m_Mainframe.hCanvas:AddObject(m_App.tPalette)
	m_Mainframe.hCanvas:AddObject(m_App.tRibbon)
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

	if CreateMainFrame(sAppTitle) 	and 
	   m_Sketch.CreateSketch()		and
	   m_Stack.CreateStack() 		then
		
		Layout()
		
		m_Mainframe.hWindow:Show(true)
		m_Sketch.hWindow:Show(true)
		m_Stack.hWindow:Show(true)
		
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
