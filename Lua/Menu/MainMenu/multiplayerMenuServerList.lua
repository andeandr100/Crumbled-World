require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/directConnectWindow.lua")
require("Menu/MainMenu/multiplayerMapSelectionPanel.lua")
require("Menu/MainMenu/lobbyMenu.lua")
require("Menu/MainMenu/mapInformation.lua")
require("Menu/settings.lua")
require("Menu/MainMenu/pingPanel.lua")

--this = SceneNode()
local mapInfo = MapInfo.new()
MultiplayerMenuServerList = {}
function MultiplayerMenuServerList.new(panel)
	local self={}
	local mapTable = {}
	local customeGamePanel
	local windowDirectConnect
	local menuChangeCallback
	local multiPlayerServerListPanel
	local lobbyMenu
	local mainPanel
	local serverListPanel
	local client = Core.getNetworkClient()
	local waitForConnection
	local serverTime
	local numServerRows = 0
	local serverUpdateTime = 0
	local updateServerListBool = false
	local serverList = {}
	local iconImage
	local serverInfo = {}
	local pingPanels = {}
	local mainMenuButton = {}
	local inLobby = false
	local labels = {}
	local labelsSpecial = {}
	local joinButton

	
	local serverTester = ServerTester()
	
	function self.getVisible()
		return mainPanel:getVisible()
	end
	
	function self.setSingleCampaignButtons(singlePlayerButton, campaignBuggon, mapeditorButton)
		mainMenuButton = {}
		mainMenuButton[1] = singlePlayerButton
		mainMenuButton[2] = campaignBuggon
		mainMenuButton[3] = mapeditorButton
	end
	
	function self.languageChanged()
		for i=1, #labels do
			labels[i]:setText(language:getText(labels[i]:getTag()))
		end
		
		for i=1, #labelsSpecial do
			labelsSpecial[i]:setText(language:getText(labelsSpecial[i]:getTag()) + ":")
		end
		
		if multiplayerCreateServer then
			multiplayerCreateServer.languageChanged()
		end
		if lobbyMenu then
			lobbyMenu.languageChanged()
		end
	end
	
	function self.setMenuChangeCallback(func)
		menuChangeCallback = func 
		windowDirectConnect.setMenuChangeCallback(func)
	end
	
	local function joinClicked(button)
		client:setUserName(Settings.multiplayerName.getSettings())
		client:connect(serverInfo.data.ip)--"localhost"
		waitForConnection = {time = Core.getTime()}
		print("Join server: "..serverInfo.data.ip..":"..tostring(serverInfo.data.port).."\n")
	end
	
	local function showServerInfo(button)
		local tab = totable(button:getTag():toString()) 
		joinButton:setEnabled(true)
		if serverInfo.data == nil or (serverInfo.data.ip ~= tab.ip and serverInfo.data.port ~= tab.port) then
			if tab.info then
				--set texture
				local mapInfoData = MapInformation.getMapInfoFromFileNameAndHash( tab.info.map, tab.info.mapHash )
				local imageName = mapInfoData and mapInfoData.icon or nil
				iconImage:setTexture(Core.getTexture(imageName and imageName or "noImage"))
				
				local options = {"easy", "normal", "hard", "extreme", "insane"}
				local difficultyText = (tab.info.difficulty > 0 and tab.info.difficulty < 6) and language:getText(options[tab.info.difficulty]) or ""
				
				--set information				
				serverInfo.serverNameLabel:setText(tab.name)
				serverInfo.mapLabel:setText(tab.info.map)
				serverInfo.difficulty:setText(difficultyText)
				serverInfo.playerLabel:setText(tab.info.players)
			end
			serverInfo.data = tab 
		end
	end
	
	local function updateServerList()
		--Check if it's time to do a server update check
		if serverUpdateTime < Core.getGameTime() then
			print("\n\n\n\n\n\n\n\n\n\nupdateServerList()\n\n\n\n\n")
			updateServerListBool = false
			serverUpdateTime = Core.getGameTime() + 10
			local tmpServerList = serverTime and Core.getServerList(serverTime) or Core.getServerList()
			serverTime = tmpServerList.time
			print("test serverList: "..tostring(tmpServerList).."\n")
			serverTester:parseServerTable(tmpServerList)	
		else
			while serverTester:hasNewServerInfo() do
				local tab = serverTester:popNewServerInfo()
				print("\nNew Server tested\n")
				print("tab = "..tostring(tab).."\n")
				print("name: "..tab.name.."\n")
				print("ip: "..tab.ip.."\n")
				print("port: "..tab.port.."\n")
				print("info: "..tab.info.."\n")
				print("\n")
				
				tab.info = tab.info and totable(tab.info) or {}
				
				if tab.info.name == nil then tab.info.name = "" end
				if tab.info.players == nil then tab.info.players = "x/x" end
				if tab.info.map == nil then tab.info.map = "?" end
				if tab.info.difficulty == nil then tab.info.difficulty = 2 end

				
				local button = serverListPanel:add(Button(PanelSize(Vec2(-1,0.03)), tab.name, ButtonStyle.SQUARE))
				
				button:setTextColor(Vec3(0.7))
				button:setTextHoverColor(Vec3(0.92))
				button:setTextDownColor(Vec3(1))
				button:setTextAnchor(Anchor.MIDDLE_LEFT)
				
				button:setEdgeColor((numServerRows%2 == 0) and Vec4(1,1,1,0.05) or Vec4(0))
				button:setInnerColor((numServerRows%2 == 0) and Vec4(1,1,1,0.05) or Vec4(0))
	
				button:setEdgeHoverColor(Vec4(1,1,1,0.4))
				button:setEdgeDownColor(Vec4(1,1,1,0.4))
				
				button:setInnerHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.45), Vec4(1,1,1,0.4))
				button:setInnerDownColor(Vec4(1,1,1,0.3), Vec4(1,1,1,0.4), Vec4(1,1,1,0.3))	
				button:addEventCallbackExecute(showServerInfo)
				button:addEventCallbackOnDoubleclick(joinClicked)
				button:setTag("table="..tabToStrMinimal(tab))
				
				button:setLayout(FlowLayout(Alignment.TOP_RIGHT))
				if tab.ping then
					pingPanels[#pingPanels + 1] = PingPanel.new(PanelSize(Vec2(-1),Vec2(1.5,1)), tab.ping)
					button:add(pingPanels[#pingPanels].getPanel())
				else
					button:add(Panel(PanelSize(Vec2(-1),Vec2(1.5,1))))
				end
				
				if tab.info.players then
					local label = button:add(Label(PanelSize(Vec2(-1),Vec2(2,1)), tostring(tab.info.players), Vec4(0.7)))
					label:setCanHandleInput(false)
				end
				
				numServerRows = numServerRows + 1
				
				
				serverList[#serverList + 1] = tab
			end
		end
	end
	
	function self.setVisible(set,set2)
		if type(set)=="boolean" then
			mainPanel:setVisible(set)
		else
			mainPanel:setVisible(set2)
		end
		
		
		if mainPanel:getVisible() then
			print("MainPanel Visible\n")
			serverUpdateTime = Core.getGameTime() - 1.0
			updateServerListBool = true
			serverTime = nil
			serverListPanel:clear()
			updateServerList()
		end
	end
	
	function self.clearServerList()
		serverUpdateTime = Core.getGameTime() - 1.0
		updateServerListBool = true
		serverListPanel:clear()
		serverTime = nil
		updateServerList()
	end
	
	local function addMapInfoPanel(bodyPanel)
		local infoPanel = bodyPanel:add(Panel(PanelSize(Vec2(-1, -1))))
		multiPlayerServerListPanel = infoPanel
		
	--	infoPanel:getPanelSize():setFitChildren(false, true)
		infoPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.005))))
		infoPanel:setPadding(BorderSize(Vec4(0.005),true))
		infoPanel:setBackground(Gradient(Vec4(0,0,0,0.9), Vec4(0,0,0,0.9)))
		
		iconImage = infoPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("noImage")))
		iconImage:setBorder(Border( BorderSize(Vec4(0.0015), true), Vec3(0)))
		
		local infoField = {{name="serverNameLabel",text="server name"},{name="playerLabel",text="players"},{name="mapLabel",text="map name"},{name="difficulty",text="difficulty"}}
		for i=1, #infoField do
			local row = infoPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
			labelsSpecial[#labelsSpecial + 1] = row:add(Label(PanelSize(Vec2(-1),Vec2(5,1)), language:getText(infoField[i].text)+":", Vec3(0.7)))
			labelsSpecial[#labelsSpecial]:setTag(infoField[i].text)
			
			serverInfo[infoField[i].name] = row:add(Label(PanelSize(Vec2(-1)), "", Vec3(0.7)))
		end
		
		joinButton = infoPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03),Vec2(4,1), language:getText("join server")))
		joinButton:addEventCallbackExecute(joinClicked)
		joinButton:setEnabled(false)
		
		labels[#labels+1] = joinButton
		labels[#labels]:setTag("join server")
	end
	
	local function addServersPanel(bodyPanel)
		local mapFolder = Core.getDataFolder("Map")
		local files = mapFolder:getFiles()
		
		local mapsPanel = bodyPanel:add(Panel(PanelSize(Vec2(-0.6, -1))))
		mapsPanel:setBackground(Gradient(Vec4(1,1,1,0.02), Vec4(1,1,1,0.04)))
		
		local headerPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, 0.035))))
		headerPanel:setBackground(Gradient(Vec4(1,1,1,0.05), Vec4(1,1,1,0.1)))
		labelsSpecial[#labelsSpecial+1] = headerPanel:add(Label(PanelSize(Vec2(-0.65, -1)), language:getText("servers")+":", Vec4(0.95)))
		labelsSpecial[#labelsSpecial]:setTag("servers")
			
		serverListPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, -1))))
		serverListPanel:setLayout(FallLayout())
		serverListPanel:setEnableYScroll()	
		
		
	end
	--
	--callbacks
	--
	local function eventClickedDirectConnect()
		windowDirectConnect.setVisible(true)
	end
	
	local function evenClickedCreateLobby()
--		print("eventClickedCreateLobby()\n")
--		if menuChangeCallback then
--			menuChangeCallback("Lobby",true)
--		end
		
		if not multiplayerCreateServer then
			multiplayerCreateServer = MultiplayerMapSelectionPanel.new(mainPanel, customeGamePanel, lobbyMenu)
			lobbyMenu.setMapSelectionPanel(multiplayerCreateServer)
		end
			
		customeGamePanel:setVisible(false)
		multiplayerCreateServer.setVisible(true)
		
	end
	--
	--
	--
	function self.getPanel()
		return mainPanel
	end
	
	local function goToLobby()
		customeGamePanel:setVisible(false)
		lobbyMenu.setVisible(true, false)
	end
	
	function self.update()
		if windowDirectConnect.getVisible() then
			windowDirectConnect.update()
		end
		
		if lobbyMenu.getVisible() or lobbyMenu.inLobby() then
			lobbyMenu.update()
		end
		
		if waitForConnection  then
			--print("until ("..tostring(client:isConnected()).." or "..(Core.getTime()-waitForConnection.time)..">1.0 )\n")
			if client:isConnected() then
				--client:read()
				goToLobby()
				waitForConnection = nil
			elseif Core.getTime()-waitForConnection.time>10.0 then
				print("failed to connect to server\n")
				waitForConnection = nil
			end
			
		end
		if customeGamePanel:getVisible() and mainPanel:getVisible() then
			--check if new servers has come online
			updateServerList()
		end
		
		
		if inLobby ~= lobbyMenu.inLobby() then
			inLobby = lobbyMenu.inLobby()
			for i=1, #mainMenuButton do
				if lobbyMenu.inLobby() then
					mainMenuButton[i]:setEnabled(false)
					mainMenuButton[i]:setTextColor(Vec3(0.33))
				else
					mainMenuButton[i]:setEnabled(true)
					mainMenuButton[i]:setTextColor(Vec3(0.7))
					mainMenuButton[i]:setTextHoverColor(Vec3(0.92))
					mainMenuButton[i]:setTextDownColor(Vec3(1))
				end
			end
		end
	end
	
	
	local function init()
		--
		local camera = this:getRootNode():findNodeByName("MainCamera")
		if camera then
			windowDirectConnect = DirectConnectWindow.new(camera)
			windowDirectConnect.setMenuChangeCallback(goToLobby)
		end
		--Options panel
		mainPanel = panel:add(Panel(PanelSize(Vec2(-1))))
		customeGamePanel = mainPanel:add(Panel(PanelSize(Vec2(-1))))
		customeGamePanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		--Top menu button panel
		labels[#labels+1] = customeGamePanel:add(Label(PanelSize(Vec2(-1,0.04)), language:getText("server browser"), Vec3(0.94), Alignment.MIDDLE_CENTER))
		labels[#labels]:setTag("server browser")
		
		--Add BreakLine
		local breakLinePanel = customeGamePanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		local gradient = Gradient()
		gradient:setGradientColorsHorizontal({Vec3(0.45),Vec3(0.90),Vec3(0.45)})
		breakLinePanel:setBackground(gradient)
		
		local bodyPanel = customeGamePanel:add(Panel(PanelSize(Vec2(-0.9, -0.90))))
		
		--Add map panel
		addServersPanel(bodyPanel)
		--Add info panel (about what map is playing)
		addMapInfoPanel(bodyPanel)
		
		lobbyMenu = LobbyMenu.new(mainPanel, customeGamePanel, self)
		
		--add bottom buttons
		local bottomPanel = customeGamePanel:add(Panel(PanelSize(Vec2(-1))))
		bottomPanel:setLayout(FlowLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		local button = bottomPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(6,1), language:getText("create server")))
		button:addEventCallbackExecute(evenClickedCreateLobby)
		labels[#labels+1] = button
		labels[#labels]:setTag("create server")
		
		button = bottomPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(6,1), language:getText("direct connect")))
		button:addEventCallbackExecute(eventClickedDirectConnect)
		labels[#labels+1] = button
		labels[#labels]:setTag("direct connect")
		
		
		mainPanel:setVisible(false)
	end
	init()
	
	return self
end