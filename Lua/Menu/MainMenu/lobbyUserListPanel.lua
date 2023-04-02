require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()

LobbyUserListPanel = {}
function LobbyUserListPanel.new(panel, client)
	local self = {}
	local mainPanel = nil
	local spectatorPanel = nil
	local spectatorLabel = nil
	local userData = nil
	local aClient = client
	local maxPlayers = 128
	local playerRowPanel = {}
	local requestPlayerid  = nil
	local dropDownPanel = nil
	local kickButton = nil
	local banButton = nil
	local playerId = -1
	local labels = {}
	local spectatorText = Text("")
	
--	userData = {{
--				name = "Client1[TCP/UDP](Admin)",
--				ping = 0,
--				playerId = 1,
--				ready = false--set by the .lua file
--			}}
	
	function self.leveLobby()
		playerId = -1
	end
	
		
	function self.setIsHost(isTheHost)
		isHost = isTheHost
		print("setIsHost = "..tostring(isTheHost).."\n")
	end
	
	function self.setReady(clientId, ready)
		if userData then
			for i=1, #userData do
				if userData[i].clientId == clientId then
					userData[i].ready = ready
					userData[i].readyCheckBox:setSelected(ready)
					print("ClinetId: "..clientId.."readyCheckBox: "..tostring(ready))
				end
			end
		end
	end
	
	local function changeReady(checkBox)
		self.setReady(aClient:getClientId(), checkBox:getSelected())
		aClient:writeSafe("Ready:table="..tabToStrMinimal({clientId=aClient:getClientId(),ready=checkBox:getSelected()}))
		print("   network send from changeReady "..(checkBox:getSelected() and "true" or "false"))
	end
	
	function self.setIsRead(ready)
		print("set is ready clientId: "..aClient:getClientId().." Ready: "..tostring(ready))
		self.setReady(aClient:getClientId(), ready)
		aClient:writeSafe("Ready:table="..tabToStrMinimal({clientId=aClient:getClientId(),ready=ready}))
		print("   network send from setIsRead "..(ready and "true" or "false"))
	end
	
	function self.getIsRead()
		if userData then
			for i=1, #userData do
				if userData[i].clientId == aClient:getClientId() then
					return userData[i].ready
				end
			end
		end
		return false
	end
	
	function self.isAllUsersReady()
		local allReady = true
		if userData then
			for i=1, #userData do
				allReady = (allReady and userData[i].ready)
			end
		end
		return allReady
	end
	
	function self.setMaxPlayers(players)
		if maxPlayers ~= players then
			maxPlayers = players
			if userData then
				self.updateUserList(userData)
			end
		end
	end
	
	local function changeAnotherUsersPlayerId(button)
		requestPlayerid = 0
		if button:getText() == spectatorText then
			--find the first unused player id in the spector range
			requestPlayerid = maxPlayers + 1
			for i=1, #userData do
				requestPlayerid = math.max(requestPlayerid, userData[i].playerId + 1)
			end
		else
			requestPlayerid = tonumber(button:getText())
		end
		
		local clientId = tonumber(button:getTag():toString())
		local clientName = ""
		local clientPlayerId = 0
		for i=1, #userData do
			if userData[i].clientId == clientId then
				clientName = userData[i].name
				clientPlayerId = userData[i].playerId
			end
		end
		
		
		aClient:writeSafe("ChangePlayerId:table="..tabToStrMinimal({clientId=clientId,newPlayerId=requestPlayerid}))
		local playerIdtext = (requestPlayerid > maxPlayers) and "Spectator" or tostring(requestPlayerid)
		aClient:writeSafe("Chat:Admin;<font color=rgb(0,155,255)>Changed "..clientName.." from player "..clientId.." to player "..playerIdtext.."</font>")
	end
	
	local function changePlayerId(button)
		requestPlayerid = 0
		if button:getText() == spectatorText then
			--find the first unused player id in the Spectator range
			requestPlayerid = maxPlayers + 1
			for i=1, #userData do
				requestPlayerid = math.max(requestPlayerid, userData[i].playerId + 1)
			end
		else
			requestPlayerid = tonumber(button:getText())
		end
		
		print("\n\n\n\n\n\n")
		client:requestPlayerId(requestPlayerid)
		print("client:requestPlayerId "..requestPlayerid)
		
		
		--set ready if player is the host
		self.setIsRead(isHost)

		
	end
	
	function self.update()
--		if requestPlayerid then
--			print("have requested id "..requestPlayerid.." current player id"..Core.getPlayerId().."\n")
--		end
		if playerId ~= Core.getPlayerId() and playerIdCombobox then
			playerId = Core.getPlayerId()
			if playerId > maxPlayers then
				playerIdCombobox:setText(spectatorText)
			else
				playerIdCombobox:setText(tostring(Core.getPlayerId()))
			end
		end
	end
	
	local function kickPlayer(button)
		aClient:writeSafe("Kick:"..button:getTag():toString())
		print("kick clientId: "..button:getTag():toString())
	end
	
	local function banPlayer(button)
		aClient:writeSafe("Ban:"..button:getTag():toString())
		print("ban clientId: "..button:getTag():toString())
	end
	
	local function showPlayerOptions(button)
		--show drop down menu
		--Where the player can be kicked or banned
		
		--when kicking or banning first send a nice message if it's ignored connnection is forcefully ended.
		if not dropDownPanel then
			dropDownPanel = Panel(PanelSize(Vec2(1,0.03),Vec2(3,1)))
			
			
			kickButton = dropDownPanel:add(MainMenuStyle.createMenuButton(Vec2(-1,0.03),Vec2(), language:getText("kick")))
			kickButton:addEventCallbackExecute(kickPlayer)
--			banButton = dropDownPanel:add(MainMenuStyle.createMenuButton(Vec2(-1,0.03),Vec2(), language:getText("ban")))
--			banButton:addEventCallbackExecute(banPlayer)
			
			labels[1] = kickButton
			labels[1]:setTag("kick")
			
--			labels[2] = banButton
--			labels[2]:setTag("ban")
		end
		
		kickButton:setTag(button:getTag():toString())
--		banButton:setTag(button:getTag():toString())
		
		
		
		
		--openDropDownPanel
		button:openDropDownPanel(Core.getInput():getMousePos(), dropDownPanel, Vec4(0.0, 0.0, 0.0, 0.8), Vec4(0.45, 0.45, 0.45, 1.0), true)
	end
	
	function self.updateUserList(users)
		if users then
			userData = users
			mainPanel:clear()
			playerRowPanel = {}
			numUsers = 0
			spectatorText = language:getText("spectator")
			
					
			--Create the row panel for all players
			for i=1, maxPlayers do
				--When there is more players the map can handle add them as spectators
				playerRowPanel[i] = mainPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
			end
			
			spectatorLabel = mainPanel:add(Label(PanelSize(Vec2(-1,0.03)),language:getText("spectators")+":", Vec4(0.85)))
			spectatorLabel:setVisible(false)
			
	
			
			spectatorPanel = mainPanel:add(Panel(PanelSize(Vec2(-1))))
			spectatorPanel:getPanelSize():setFitChildren(false, true);
			spectatorPanel:setLayout(FallLayout())
			
			
			
			print("\n\n\nCore.getPlayerId() == "..Core.getPlayerId())
			print("client:getPlayerId() == "..aClient:getPlayerId())
			print("client:getClientId() == "..aClient:getClientId())
			print("isHost == "..tostring(isHost))
			
			for i=1, #users do
				local user = users[i]
				local userName = user.name
	
				local rowPanel = (user.playerId == 0 or user.playerId > maxPlayers) and spectatorPanel:add(Panel(PanelSize(Vec2(-1,0.03)))) or playerRowPanel[user.playerId]
				
				local button = rowPanel:add(Button(PanelSize(Vec2(-1)), "", ButtonStyle.SQUARE))
				button:setTag(tostring(user.clientId))
				
				button:setEdgeColor( numUsers%2 == 0 and Vec4(1,1,1,0.05) or Vec4(0))
				button:setInnerColor(numUsers%2 == 0 and Vec4(1,1,1,0.05) or Vec4(0))
			
				button:setEdgeHoverColor(Vec4(1,1,1,0.4))
				button:setEdgeDownColor(Vec4(1,1,1,0.4))
			
				button:setInnerHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.45), Vec4(1,1,1,0.4))
				button:setInnerDownColor(Vec4(1,1,1,0.3), Vec4(1,1,1,0.4), Vec4(1,1,1,0.3))	
				
				if isHost then
					button:addEventCallbackOnRightClick(showPlayerOptions)			
				end
				button:setLayout(FlowLayout(Alignment.TOP_LEFT))
				local label = button:add(Label(PanelSize(Vec2(-0.65, -1)), userName, Vec4(0.85)))
				label:setCanHandleInput(false)
	
	
				local rightPanel = button:add(Panel(PanelSize(Vec2(-1))))	
				rightPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
				rightPanel:setCanHandleInput(false)
			
	
				local checkBox = rightPanel:add(CheckBox(PanelSize(Vec2(-1),Vec2(1)), user.ready))
						
						
				--set player id text
				local playerIdText = tostring(user.playerId)
				if user.playerId > maxPlayers then 
					spectatorLabel:setVisible(true)
					playerIdText = spectatorText
				end
				
				
				print("user.playerId == "..user.playerId)
						
				if aClient:getClientId() == user.clientId or isHost then
					
					local changIdFunc = (Core.getPlayerId() == user.playerId) and changePlayerId or changeAnotherUsersPlayerId
					
					playerIdCombobox = rightPanel:add(ComboBox(PanelSize(Vec2(-1),Vec2(3,1)), playerIdText))
					if true then
						local itemButton = MainMenuStyle.createMenuButton(Vec2(-1,0.03), Vec2(), spectatorText )
						itemButton:setTag(tostring(user.clientId))
						itemButton:addEventCallbackExecute(changIdFunc)
						playerIdCombobox:addItem(itemButton)
					end
					for n=1, maxPlayers do
						local unusedid = true
						for m=1, #users do
							if users[m].playerId == n then
								unusedid = false
							end
						end
						if unusedid then
							itemButton = MainMenuStyle.createMenuButton(Vec2(-1,0.03), Vec2(), tostring(n) )
							itemButton:setTag(tostring(tostring(user.clientId)))
							itemButton:addEventCallbackExecute(changIdFunc)
							playerIdCombobox:addItem(itemButton)
						end
					end
				else
					rightPanel:add(Label(PanelSize(Vec2(-1),Vec2(3,1)), playerIdText, Vec4(0.85)))
				end
			
			
				if isHost then
					checkBox:setEnabled(false)
				else
					if user.clientId == aClient:getClientId() then
						checkBox:addEventCallbackExecute(changeReady)
					else
						checkBox:setEnabled(false)
					end
				end
				
				checkBox:setTag(tostring(i))
				
				user.readyCheckBox = checkBox
			end
		else
			print("No user data found")
		end
	end
	
	function self.languageChanged()
		for i=1, #labels do
			labels[i]:setText(language:getText(labels[i]:getTag()))
		end
				
		updateUserList(userData)
	end
	
	function self.settingsChanged()
		if not isHost then
			self.updateUserList(userData)
			self.setIsRead(false)
		end
	end
	
	local function init()
		mainPanel = panel:add(Panel(PanelSize(Vec2(-1))))
		mainPanel:setEnableScroll()
	end
	
	init()
	return self
end