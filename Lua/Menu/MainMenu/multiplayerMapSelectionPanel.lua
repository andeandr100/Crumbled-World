require("Menu/MainMenu/mapListPanel.lua")
require("Menu/MainMenu/settingsCombobox.lua")
--this = SceneNode()

MultiplayerMapSelectionPanel = {}
function MultiplayerMapSelectionPanel.new(panel, inServerListPanel, inLobbyMenu)
	local self = {}
	local mainPanel
	local selectedFile
	local iconImage
	local mapNameLabel
	local playersLabel
	local gameModeLabel
	local serverNameTextField 
	local serverListPanel = inServerListPanel
	local comboBoxDifficutyBox
	local comboBoxGameMode
	local lobbyMenu = inLobbyMenu
	local startServerButton
	local mapFile
	local labels = {}
	local serverInfoButton
	
	
	function self.getPanel()
		return mainPanel
	end
	
	function self.languageChanged()
		for i=1, #labels do
			labels[i]:setText(language:getText(labels[i]:getTag()))
		end
		
		serverInfoButton:setToolTip(language:getText("port forward"))
		
		if comboBoxDifficutyBox then
			comboBoxDifficutyBox.updateLanguage()
		end
		if comboBoxGameMode  then
			comboBoxGameMode.updateLanguage()
		end
		if mapList then
			mapList.languageChanged()
		end
	end
	
	function self.setVisible(visible)
		mainPanel:setVisible(visible)	
		if visible then
			local text = lobbyMenu.getServer() and "save settings" or "start server"
			startServerButton:setText( language:getText(text) )
			startServerButton:setTag(text)
			serverNameTextField:setKeyboardOwner()
		end
	end
	
	local function returnToServListPanel()
		print("===========================")
		print("== returnToServListPanel ==")
		print("===========================")
		
		if lobbyMenu.getServer() then
			mainPanel:setVisible(false)	
			lobbyMenu.getPanel():setVisible(true)
			serverListPanel:setVisible(false)
		else
			mainPanel:setVisible(false)	
			lobbyMenu.setVisible(false)	
			serverListPanel:setVisible(true)
		end
	end
	
	local function startServer()
		
		print("===========================")
		print("=== start server button ===")
		print("===========================")
	
		mainPanel:setVisible(false)	
		lobbyMenu.getPanel():setVisible(true)
		if lobbyMenu.getServer() then
			print("Event 1")
			lobbyMenu.setSettings(serverNameTextField:getText(), mapFile:getPath(), comboBoxDifficutyBox.getIndex())
		else
			print("Event 2")
			lobbyMenu.startServer(serverNameTextField:getText(), mapFile:getPath(), comboBoxDifficutyBox.getIndex())
		end
		serverListPanel:setVisible(false)
	end
	
	local function addTableRow(parentPanel, rowText)
		--Row panel
		local rowPanel = parentPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		--Label Panel
		labels[#labels + 1] = rowPanel:add(Label(PanelSize(Vec2(-1),Vec2(4.5,1)), language:getText(rowText) + ":", Vec3(0.7)))
		labels[#labels]:setTag(rowText)	
		--main Panel
		local rowMainPanel = rowPanel:add(Panel(PanelSize(Vec2(-1))))
		return rowMainPanel
	end
	
	local function addMapInfoPanel(panel)
		local infoPanel = panel:add(Panel(PanelSize(Vec2(-1, -1))))
	--	infoPanel:getPanelSize():setFitChildren(false, true)
		infoPanel:setLayout(FallLayout(Alignment.TOP_LEFT, PanelSize(Vec2(0,0.005))))
		infoPanel:setPadding(BorderSize(Vec4(0.005),true))
		infoPanel:setBackground(Gradient(Vec4(0,0,0,0.9), Vec4(0,0,0,0.9)))
		
		
		--Image
		iconImage = infoPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("noImage")))
		iconImage:setBorder(Border( BorderSize(Vec4(0.0015), true), Vec3(0)))
		
		mapNameLabel = infoPanel:add(Label(PanelSize(Vec2(-1, 0.03)), language:getText("map name"), Vec3(0.7)))
		labels[#labels + 1] = mapNameLabel
		labels[#labels]:setTag("map name")	
		
		--Game Mode
		local gameModePanel = addTableRow( infoPanel, "game mode" )
		local gameModeOptions = {"rush", "attack", "normal", "survival"}
		comboBoxGameMode = SettingsComboBox.new(gameModePanel, PanelSize(Vec2(-1)), gameModeOptions, "game mode", gameModeOptions[3], nil )
		gameModeLabel = gameModePanel:add(Label(PanelSize(Vec2(-1),Vec2(4.5,1)), "Co-op", Vec3(0.7)))
		
		--difficulty
		local difficultyPanel = addTableRow( infoPanel, "difficulty" )
		local difficultOptions = {"easy", "normal", "hard", "extreme", "insane"}
		comboBoxDifficutyBox = SettingsComboBox.new(difficultyPanel, PanelSize(Vec2(-1)), difficultOptions, "difficulty", difficultOptions[2], nil )
		
		--difficulty
		local playersPanel = addTableRow( infoPanel, "players" )
		playersLabel = playersPanel:add(Label(PanelSize(Vec2(-1),Vec2(4.5,1)), "", Vec3(0.7)))
		
	end
	
	
	
	local function customeGameChangedMap(button)
		selectedFile = button:getTag():toString()
		mapFile = File(selectedFile)
	
		if mapFile:isFile() then

			mapNameLabel:setText( mapFile:getName() )
			local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
			local imageName = mapInfo and mapInfo.icon or nil
			local texture = Core.getTexture(imageName and imageName or "noImage")
			
			iconImage:setTexture(texture)
			
			if mapInfo.players > 1 then
				playersLabel:setText( tostring(mapInfo.players) )
				comboBoxGameMode.getComboBox():setVisible(false)
				gameModeLabel:setVisible(true)
			else
				playersLabel:setText( "1-4" )
				comboBoxGameMode.getComboBox():setVisible(true)
				gameModeLabel:setVisible(false)
			end
		end
	end
	
	
	
	local function init()

		mapTable = {}
		selectedFile = ""
		
		--Options panel
		mainPanel = panel:add(Panel(PanelSize(Vec2(-1))))
		mainPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))

		--Top menu button panel
		local serverLabel = mainPanel:add(Label(PanelSize(Vec2(-0.9,0.04)), language:getText("create server"), Vec3(0.94), Alignment.MIDDLE_CENTER))
		serverLabel:setLayout(FlowLayout(Alignment.BOTTOM_RIGHT))
		labels[#labels + 1] = serverLabel
		labels[#labels]:setTag("create server")
		
		serverInfoButton = serverLabel:add(MainMenuStyle.createButton(Vec2(-1,-0.9), Vec2(1,1), "!"))
		serverInfoButton:setToolTip(language:getText("port forward"))
		
		--Add BreakLine
		MainMenuStyle.createBreakLine(mainPanel)
		
		local serverNameRow = mainPanel:add(Panel(PanelSize(Vec2(-0.9,0.03))))
		labels[#labels + 1] = serverNameRow:add(Label(PanelSize(Vec2(-1),Vec2(6,1)), language:getText("server name"), MainMenuStyle.textColor ))
		labels[#labels]:setTag("server name")
		serverNameTextField = serverNameRow:add(MainMenuStyle.createTextField(Vec2(-1), Vec2(),""))
		serverNameTextField:setWhiteList("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ _-<>[]()!#+%&=1234567890?;:$@\"/,.*~^|")
		
		MainMenuStyle.createBreakLine(mainPanel)
		
		local bottomAreaPane = mainPanel:add(Panel(PanelSize(Vec2(-0.9, -0.95))))
		bottomAreaPane:setLayout(FallLayout(Alignment.BOTTOM_RIGHT, PanelSize(Vec2(0,0.01))))
		
		local buttonPanel = bottomAreaPane:add(Panel(PanelSize(Vec2(-1,0.03))))
		
		local bodyPanel = bottomAreaPane:add(Panel(PanelSize(Vec2(-1, -1))))	
		--Add map panel
		local mapsPanel = bodyPanel:add(Panel(PanelSize(Vec2(-0.6, -1))))
		local mapList = MapListPanel.new(mapsPanel, customeGameChangedMap)
		--Add info panel
		addMapInfoPanel(bodyPanel)
		
		
		--Add buttons
		buttonPanel:setLayout(FlowLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		startServerButton = buttonPanel:add(MainMenuStyle.createButton(Vec2(-1), Vec2(6,1), language:getText("start server")))
		startServerButton:addEventCallbackExecute(startServer)
		labels[#labels + 1] = startServerButton
		labels[#labels]:setTag("start server")
		
		local backButton = buttonPanel:add(MainMenuStyle.createButton(Vec2(-1), Vec2(6,1), language:getText("back")))
		backButton:addEventCallbackExecute(returnToServListPanel)
		labels[#labels + 1] = backButton
		labels[#labels]:setTag("back")
		
		mainPanel:setVisible(false)			
		
		if mapList.getFirstMapButton() then
			customeGameChangedMap(mapList.getFirstMapButton())
		end
	end
	init()
	
	return self
end