require("Game/mapInfo.lua")
require("Menu/MainMenu/lobbyUserListPanel.lua")
require("Menu/MainMenu/lobbyChatPanel.lua")
require("Menu/MainMenu/mapInformation.lua")
require("Menu/MainMenu/settingsCombobox.lua")
require("Menu/settings.lua")

--this = SceneNode()
local mapInfo = MapInfo.new()
LobbyMenu = {}
function LobbyMenu.new(panel, aServerListPanel, aServerListObject)
	local self={}
	local mapTable = {}
	local customeGamePanel
	local mapNameLabel
	local playersLabel
	local comboBoxDifficutyBox
	local buttonStart
	local buttonEditLobbySettings
	local buttonQuit
	local iconImage
	local mapListPanel
	local chatPanel
	local chatHistoryPanel
	local chatTextField
	local chatLabels = {}
	local isHost = false
	local server
	local mapSelectionPanel
	local serverAddr = "0.0.0.0"
	local client = Core.getNetworkClient()
	local serverName
	local lobbyUserPanel
	local mapData
	local users = {}
	local lobbyChatPanel
	local serverListPanel = aServerListPanel
	local mapFile
	local curentMapInformation--keep information about the maps file path and hash 
	local curentMapInformationRaw = ""--used to determinate if user can be ready or not
	local serverDataChanged
	local downloadPanel
	local downloadProgressBar
	local downloadingState = 0
	local downloadingMaphash = ""
	local serverListObject = aServerListObject
	local labels = {}
	local labelsSpecial = {}
	
	function self.inLobby()
		return client:isConnected()
	end
	
	function self.languageChanged()
		for i=1, #labels do
			labels[i]:setText(language:getText(labels[i]:getTag()))
		end
		
		for i=1, #labelsSpecial do
			labelsSpecial[i]:setText(language:getText(labelsSpecial[i]:getTag()) + ":")
		end
		
		comboBoxDifficutyBox.updateLanguage()
	end
	
	function self.getVisible()
		return customeGamePanel:getVisible()
	end
	function self.getPanel()
		return customeGamePanel
	end
	function self.getServer()
		return server
	end
	local function eventClickedStartGame()
		if isHost then
			print("Map: "..mapNameLabel:getTag():toString())
			print("Difficulty: "..comboBoxDifficutyBox.getIndexText())
			--
			--
			client:writeSafe("StartGame:"..mapNameLabel:getTag():toString())
			--
			--
			local fileName = "Data/Map/"..mapInfo.getMapName()..".map"
			Core.startMap(mapNameLabel:getTag():toString())
			--start the loading screen
			Worker("Menu/loadingScreen.lua", true)
			
			--no more clients can join this server
			server:removeFromGlobalServerList()
		else
			print("set is ready")
			lobbyUserPanel.setIsRead()
		end
	end
	local function setIsReady()
		local ready = (buttonStart:getTag() == Text("ready"))
		lobbyUserPanel.setIsRead(ready)
		
		if ready then
			buttonStart:setText(language:getText("not ready"))
			labels[1]:setTag("not ready")
		else
			buttonStart:setText(language:getText("ready"))
			labels[1]:setTag("ready")
		end
	end
	
	local function quitLobby()
		print("-----------------------------")
		print("-----------------------------")
		print("		   quitLobby		 ")		
		print("-----------------------------")
		print("-----------------------------")
		if server then
			print("Stop server")
			server:removeFromGlobalServerList()
		end
		
		serverListObject.clearServerList()
		serverListPanel:setVisible(true)
		self.setVisible(false)
		lobbyUserPanel.leveLobby()
	end
	
	
	
	function self.setVisible(visible,isServer)

		print("vSet = "..tostring(visible))
		customeGamePanel:setVisible(visible)
		if visible then
			client:setUserName(Settings.multiplayerName.getSettings())
			
			if isServer then
				print("Start server")
				server = Core.getNetworkServer()
				server:start()
				server:enableNewConnections(true)
				print("serverName: "..serverName:toString())
				server:addToGlobalServerList(serverName:toString())
				print(" - Connect")
				client:disconnect()
				client:connect("0.0.0.0")
				client:connect("localhost")
				client:connect("127.0.0.1")
				print(" - Done")
				self.setIsHost(true)
			else
				print(" - is a client")
				self.setIsHost(false)
			end
			
			--Update buttons based on we are the server
			if isServer then
				buttonStart:setText(language:getText("start"))
				buttonStart:clearEvents()
				buttonStart:addEventCallbackExecute(eventClickedStartGame)
				labels[1]:setTag("start")
				buttonQuit:setText(language:getText("quit"))
				buttonEditLobbySettings:setVisible(true)
				buttonQuit:addEventCallbackExecute(quitLobby)
				labels[2]:setTag("quit")
			else
				buttonStart:setText(language:getText("ready"))
				buttonStart:clearEvents()
				buttonStart:addEventCallbackExecute(setIsReady)
				labels[1]:setTag("ready")
				buttonQuit:setText(language:getText("leave"))
				buttonEditLobbySettings:setVisible(false)		
				buttonQuit:addEventCallbackExecute(quitLobby)
				labels[2]:setTag("leave")
			end
		else
			if server then
				print("Stop server")
				server:stop()
				server:removeFromGlobalServerList()
				server = nil
			end
			client:disconnect()
		end
		--
		mapInfo.setIsCampaign(false)
		mapInfo.setGameMode("coop")		
	end
	
	
	function self.setMapSelectionPanel(panel)
		mapSelectionPanel = panel
	end
	
	--return true if difficulty has changed
	local function setDifficulty(level)
		local changed = (comboBoxDifficutyBox.getIndex() ~= level)
		
		comboBoxDifficutyBox.setIndex(level)
		
		mapInfo.setLevel(level)
		return changed
	end
	local function clickedChangeDifficulty(tag, index)
		if setDifficulty(index) then
			client:writeSafe("Difficulty:"..index)
		end
	end
	local function setMap(mapFilePath)
		if mapNameLabel:getTag():toString()~=mapFilePath then
			mapFile = File(mapFilePath)
			mapNameLabel:setText(mapFile:getName())
			mapNameLabel:setTag(mapFile:getPath())
			--
			buttonStart:setEnabled(true)
			--
			
			local mapInfoData = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
			print("\n\n\n\""..mapFile:getPath().."\"\n")

			mapData = mapInfoData and mapInfoData or {}
			
			mapInfo.setMapName(mapFile:getName())
			
			if mapFile:isFile() then
				if mapInfoData then
					mapInfo.setChangedDifficultyMax(mapInfoData.difficultyIncreaseMax)
					mapInfo.setChangedDifficultyMin(mapInfoData.difficultyIncreaseMin)
					mapInfo.setWaveCount(mapInfoData.waveCount)
				end
			end
			
			local imageName = mapData and mapData.icon or nil
			iconImage:setTexture(Core.getTexture(imageName and imageName or "noImage"))
		end
	end
	local function showMapSelctionPanel(button)
		if mapSelectionPanel then
			customeGamePanel:setVisible(false)
			mapSelectionPanel.setVisible(true)
		end
	end
	local function uppdateServerInfo()
		if isHost then
			local players = tostring(#users).."/"..(mapData.players and mapData.players or "x")
			playersLabel:setText(players)
			lobbyUserPanel.setMaxPlayers((mapData.players and mapData.players or 1))
			client:writeSafe("CMD-SetServerInfo:table="..tabToStrMinimal({map=mapFile:getName(),mapHash=mapFile:getHash(),difficulty=comboBoxDifficutyBox.getIndex(),players=players}))
			print("set CMD-SetServerInfo:table="..tabToStrMinimal({map=mapFile:getName(),mapHash=mapFile:getHash(),difficulty=comboBoxDifficutyBox.getIndex(),players=players}))
			
			serverDataChanged = true
		end
	end
	function self.setSettings(inServerName, mapFilePath, difficulty)
		serverName = inServerName
		--set the map
		setMap(mapFilePath)
		client:writeSafe("Map:table="..tabToStrMinimal({map=mapFile:getName(),mapHash=mapFile:getHash()}))
		--set difficulty
		setDifficulty(difficulty)
		
		uppdateServerInfo()
	end
	function self.startServer(inServerName, mapFilePath, difficulty)
		serverName = inServerName
		--start server and show lobby
		self.setVisible(true, true)
		--set the map
		setMap(mapFilePath)
		client:writeSafe("Map:table="..tabToStrMinimal({map=mapFile:getName(),mapHash=mapFile:getHash()}))
		--set difficulty
		setDifficulty(difficulty)
		
		uppdateServerInfo()
	end
	
	
	local function addMapInfoPanel(panel)
		local infoPanel = panel:add(Panel(PanelSize(Vec2(-1, -1))))
	--	infoPanel:getPanelSize():setFitChildren(false, true)
		infoPanel:setLayout(FallLayout(Alignment.TOP_LEFT, PanelSize(Vec2(0,0.005))))
		infoPanel:setPadding(BorderSize(Vec4(0.005),true))
		infoPanel:setBackground(Gradient(Vec4(0,0,0,0.9), Vec4(0,0,0,0.9)))
		
		--map texture
		iconImage = infoPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("White")))
		iconImage:setBorder(Border( BorderSize(Vec4(0.0015), true), Vec3(0)))
	
		--Map name		
		local rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		labelsSpecial[1] = rowPanel:add(Label(PanelSize(Vec2(-1),Vec2(3.5,1)), language:getText("map name") + ":", Vec3(0.7)))
		labelsSpecial[1]:setTag("map name")
		mapNameLabel = rowPanel:add(Label(PanelSize(Vec2(-1)),"",Vec3(0.7)))
		
		
		--Players
		rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		labelsSpecial[2] = rowPanel:add(Label(PanelSize(Vec2(-1),Vec2(3.5,1)), language:getText("players") + ":", Vec3(0.7)))
		labelsSpecial[2]:setTag("players")
		playersLabel = rowPanel:add(Label(PanelSize(Vec2(-1)),"",Vec3(0.7)))
		
		--Map difficulty
		rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		labelsSpecial[3] = rowPanel:add(Label(PanelSize(Vec2(-1),Vec2(3.5,1)), language:getText("difficulty") + ":", Vec3(0.7)))
		labelsSpecial[3]:setTag("difficulty")
		local options = {"easy", "normal", "hard", "extreme", "insane"}
		comboBoxDifficutyBox = SettingsComboBox.new(infoPanel, PanelSize(Vec2(-1, 0.03)), options, "difficulty", options[2], clickedChangeDifficulty )
		
		downloadPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		labelsSpecial[4] = downloadPanel:add(Label(PanelSize(Vec2(-1),Vec2(3.5,1)), language:getText("download") + ":", Vec3(0.7)))
		labelsSpecial[4]:setTag("download")
		downloadPanel:setVisible(false)
		downloadProgressBar = downloadPanel:add(ProgressBar(PanelSize(Vec2(-1))))
		downloadProgressBar:setColor(Vec4(0.4,0.4,0.4,1.0), Vec4(0.1,0.1,0.1,1.0))
		
		buttonEditLobbySettings = infoPanel:add(MainMenuStyle.createButton(Vec2(-1, 0.03),Vec2(4,1), language:getText("edit settings")))
		buttonEditLobbySettings:addEventCallbackExecute(showMapSelctionPanel)
		labels[3] = buttonEditLobbySettings
		labels[3]:setTag("edit settings")
		
		self.setIsHost(isHost)
	end
	local function addServersPanel(panel)
		local mapFolder = Core.getDataFolder("Map")
		local files = mapFolder:getFiles()
		
		local mapsPanel = panel:add(Panel(PanelSize(Vec2(-0.6, -1))))
		mapsPanel:setBackground(Gradient(Vec4(1,1,1,0.02), Vec4(1,1,1,0.04)))
		
		local headerPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, 0.035))))
		headerPanel:setBackground(Gradient(Vec4(1,1,1,0.05), Vec4(1,1,1,0.1)))
		labelsSpecial[5] = headerPanel:add(Label(PanelSize(Vec2(-0.65, -1)), language:getText("players")+":", Vec4(0.95)))
		labelsSpecial[5]:setTag("players")
			
		mapListPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, -0.6))))
		mapListPanel:setBackground(Gradient(Vec4(1,1,1,0.05), Vec4(1,1,1,0.1)))
		mapListPanel:setBorder(Border(BorderSize(Vec4(0.001)),Vec3(0.45)))
		
		lobbyUserPanel = LobbyUserListPanel.new(mapListPanel, client)
		
		mapsPanel:add(Panel(PanelSize(Vec2(-1,0.01))))
		
		chatPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1,-1))))
		
		lobbyChatPanel = LobbyChatPanel.new(chatPanel, client)
		

	end
	
	--
	--callbacks
	--
	--
	--
	--
	function self.getPanel()
		return customeGamePanel
	end
	
	--	userData = {{
--				clientId = 5,
--				name = "Client1[TCP/UDP](Admin)",
--				ping = 0,
--				playerId = 1
--			}}
	
	local function updateUserList()
		local inUsers = client:getConnected()	
		print("inUsers: "..tostring(inUsers))
		--remove user
		for i=#users, 1, -1 do
	
			local found = false
			for n=1, #inUsers do
				if inUsers[n].clientId == users[i].clientId  then
					found = true	
				end
			end
			if not found then
				lobbyChatPanel.updateMsg( "Chat", "Admin;<font color=rgb(0,155,255)>"..users[i].name.." left the lobby</font>")
				table.remove(users, i)
			end	
		end
		
		--add user
		for n=1, #inUsers do
			local found = false
			for i=1, #users do
				if users[i].clientId == inUsers[n].clientId then
					found = true
					--update user data
					users[i].playerId = inUsers[n].playerId
					users[i].name = inUsers[n].name
					users[i].ping = inUsers[n].ping
				end
			end
			
			if not found then
				users[#users+1] = inUsers[n]
				users[#users].ready = (isHost and users[#users].playerId == Core.getPlayerId())
				lobbyChatPanel.updateMsg( "Chat", "Admin;<font color=rgb(0,155,255)>"..users[n].name.." joined the lobby</font>")
			end
		end
	end
	
	local function serverUpdateInfo(updateUserInfo)
		serverDataChanged = false
		if client:isAdmin() then
			--map information
			client:writeSafe("Map:table="..tabToStrMinimal({map=mapFile:getName(),mapHash=mapFile:getHash()}))
			--player information
			client:writeSafe("Players:"..playersLabel:getText())
			--difficulty
			client:writeSafe("Difficulty:"..comboBoxDifficutyBox.getIndex())
			--max players
			client:writeSafe("MaxPlayers:"..(mapData.players and mapData.players or "1"))
			mapInfo.setPlayerCount((mapData.players and mapData.players or 1))
			--send witch client is ready
			if updateUserInfo then
				for i=1, #users do
					client:writeSafe("Ready:table="..tabToStrMinimal({clientId=users[i].clientId,ready=users[i].ready}))
				end
			end
		end
	end
	
	function self.update()
		if downloadingState > 0 then
			downloadPanel:setVisible(true)
			downloadProgressBar:setValue(client:isDownloadingFiles() and client:getDownloadPercentage() or 0)
			if client:isDownloadingFiles() then
				downloadingState = 2
			end
			if downloadingState == 2 and client:getDownloadPercentage() >= 1 then
				downloadingState = 0
				downloadPanel:setVisible(false)
				
				local downloadedMaps = client:getDowloadedFiles()
				for i=1, #downloadedMaps do
					--force load map information
					MapInformation.loadMapInfo(downloadedMaps[i])
				end
				--check if the map we downloaded still is the map we are gona play
				--if not the other map is on its way
				local mapTable = MapInformation.getMapInfoFromFileNameAndHash(curentMapInformation.map,curentMapInformation.mapHash)
				if mapTable then
					setMap(mapTable.path)	
				end
			end
		end
		
		
		lobbyUserPanel.update()
		
		--
		while client:hasMessage() do
			local s1 = client:popMessage()
			if string.len(s1)>0 then
				print("MSG:"..s1)
			end
			
			local tag,data = string.match(s1, "(.*):(.*)")
			if isHost==false then
				if tag=="Map" then
					if curentMapInformationRaw ~= data then
						--settings has changed, player is not ready
						curentMapInformationRaw = data
						lobbyUserPanel.settingsChanged()
					end
					curentMapInformation = totable(data)
					local mapTable = MapInformation.getMapInfoFromFileNameAndHash(curentMapInformation.map,curentMapInformation.mapHash)
					if mapTable then
						setMap(mapTable.path)	
					else
						mapFile = nil
						--Request map
						if downloadingMaphash ~= curentMapInformation.mapHash then
							print("Current download hash: "..downloadingMaphash)
							downloadingMaphash = curentMapInformation.mapHash
							print("Download map with hash: "..downloadingMaphash)
							
							client:writeSafe("RequestMap:"..tostring(client:getClientId()))
							print("Requesting map: ")
							downloadingState = 1
						end
					end
					
				elseif tag=="Difficulty" then
					if setDifficulty(tonumber(data)) then
						--settings has changed, player is not ready
						lobbyUserPanel.settingsChanged()
					end
				elseif tag == "Players" then
					playersLabel:setText(data)
				elseif tag=="StartGame" then
					if mapFile then
						Core.startMap(mapFile:getPath())
						--start the loading screen
						Worker("Menu/loadingScreen.lua", true)
					end
				elseif tag=="CMD-ServerInfo" then
					print("CMD-ServerInfo")
				elseif tag=="MaxPlayers" then
					lobbyUserPanel.setMaxPlayers(tonumber(data))
					mapInfo.setPlayerCount(tonumber(data))
				elseif tag=="ChangePlayerId" then
					local tabData = totable(data)
					if tabData.clientId == client:getClientId() then
						client:requestPlayerId(tabData.newPlayerId)
					end
				elseif tag=="Kick" then
					--Show kicked messgage
					if client:getClientId() == tonumber(data) then
						quitLobby()
					end
				elseif tag=="Ban" then
					--Show banned messgage
					if client:getClientId() == tonumber(data) then
						quitLobby()
					end	
				end
			else
				if tag=="RequestMap" and mapFile then
					client:sendFile( tonumber(data), mapFile:getPath()) 
					print("ClientId: "..data.." map: "..mapFile:getPath())
				end
			end
			
			if tag=="Ready" then
				local tabData = totable(data)
				print("ClientId: "..tabData.clientId.." ready: "..tostring(tabData.ready))
				if tabData.clientId ~= client:getClientId() then
					lobbyUserPanel.setReady(tabData.clientId, tabData.ready)
				elseif aClient then
					aClient:writeSafe("Ready:table="..tabToStrMinimal({clientId=aClient:getClientId(),ready=lobbyUserPanel.getIsRead()}))
				end
			else
				lobbyChatPanel.updateMsg(tag,data)
			end	
		end
		
		if serverDataChanged then
			--do a full server sync
			serverUpdateInfo(false)
		end
		
		if client:hasConnectedUsersChanged() then
			--update user data
			updateUserList()
			--debug information
			print("users: "..tostring(users))
			--update local user panel
			lobbyUserPanel.updateUserList(users)
			--update extern server information
			uppdateServerInfo()
			--do a full server sync for connected players 
			serverUpdateInfo(true)
		end
		
		if isHost then
			buttonStart:setEnabled(lobbyUserPanel.isAllUsersReady())
		else
			local text = lobbyUserPanel.getIsRead() and "not ready" or "ready"
			buttonStart:setText( language:getText(text) )
			labels[1]:setTag(text)
		end
		
		if not client:isConnected() then
			quitLobby()
		end
	end
	function self.setIsHost(set)
		isHost = set
		comboBoxDifficutyBox.setEnabled(isHost)
		lobbyUserPanel.setIsHost(set)
	end
	local function init()
		--
		--Options panel
		customeGamePanel = panel:add(Panel(PanelSize(Vec2(-1))))
		customeGamePanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		--Top menu button panel
		customeGamePanel:add(Label(PanelSize(Vec2(-1,0.04)), "Lobby", Vec3(0.94), Alignment.MIDDLE_CENTER))
		
		--Add BreakLine
		local breakLinePanel = customeGamePanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		breakLinePanel:setBackground(Sprite(Vec3(0.45)))
		
		local mainPanel = customeGamePanel:add(Panel(PanelSize(Vec2(-0.9, -0.90))))
		
		--Add map panel
		addServersPanel(mainPanel)
		--Add info panel (about what map is playing)
		addMapInfoPanel(mainPanel)
		
		--add bottom buttons
		local bottomPanel = customeGamePanel:add(Panel(PanelSize(Vec2(-1))))
		bottomPanel:setLayout(FlowLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		buttonStart = bottomPanel:add( MainMenuStyle.createButton( Vec2(-1,0.03), Vec2(6,1), language:getText("start")))
		
		buttonQuit = bottomPanel:add( MainMenuStyle.createButton( Vec2(-1,0.03), Vec2(6,1), language:getText("close")))
				
		customeGamePanel:setVisible(false)
		
		labels[1] = buttonStart
		labels[1]:setTag("start")
		
		labels[2] = buttonStart
		labels[2]:setTag("close")
		
		
		client:setUserName(Settings.multiplayerName.getSettings())
	end
	init()
	
	return self
end