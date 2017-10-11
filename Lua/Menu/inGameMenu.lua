require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/optionsMenu.lua")
require("Menu/connectionIssueForm.lua")
require("Menu/infoScreen.lua")
require("Game/mapInfo.lua")
require("Game/campaignData.lua")
require("Menu/settings.lua")
--this = SceneNode()

local textPanels = {}
local restartCounter = 0
local mapInfo = MapInfo.new()
--billboards
local statsBillboard
local stateBillboard
--panels
local mainPanel
--buttons
local continueButton
local optionsButton
local tutorialButton
local launchWavesButton
local RestartWaveButton
local RestartButton
local quitToMenuButton
local quitToEditorButton
local textList = {"continue", "options", "tutorial", "quit to desktop"}

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
		
		if Core.isInMultiplayer() then
			Core.getNetworkClient():disconnect()
		end
	end
	if optionsForm then
		optionsForm:setVisible(false)
		optionsForm:destroy()
		optionsForm = nil
	end
	if connectionIssueForm then
		connectionIssueForm.destroy()
		connectionIssueForm = nil
	end
end

function reloadeMap()
	--somthinge did go wrong during restart procedings
	--quit and load this map agin.
	
	if Core.isInEditor() then
		quitToMapeditor()
	else
		quitToMainMenu()
	end
	
end
function launchWaveCallback()
	comUnit:sendTo("EventManager","startWaves","")
	if launchWavesButton then
		launchWavesButton:setEnabled(false)
		toggleVisible()
	end
end
function restartMapCallback()
	restartCounter = restartCounter + 1
	comUnit:sendTo("SteamStats","RestartCount",1)
	comUnit:sendTo("SteamAchievement","Restart","")
	if restartCounter>=5 then
		comUnit:sendTo("SteamAchievement","JustOneMoreTry","")
	end
	--
	--show buttons if used
	if launchWavesButton then
		launchWavesButton:setEnabled(true)
	end
	if RestartWaveButton then
		RestartWaveButton:setEnabled(false)
	end
end

function languageChanged()
	for i=1, #textPanels do
		textPanels[i]:setText(language:getText(textPanels[i]:getTag()))
	end
	
	--0.17/5 magic number from before language support was added
	if mainPanel then
		local tmpLabel = Label(PanelSize(Vec2(-1)),"-")
		tmpLabel:setTextHeight(0.035)
		local maxSize = 16
		for i=1, #textList do
			tmpLabel:setText(language:getText(textList[i]))
			maxSize = math.max(maxSize, tmpLabel:getTextSizeInPixel().x)
		end
		mainPanel:setPanelSize(PanelSize(Vec2((maxSize * 1.05)/Core.getRenderResolution().x,-1)))
		mainPanel:getPanelSize():setFitChildren(false, true)
		
	end
	
	
	for i=2, #textPanels do
		textPanels[i]:setPanelSize(PanelSize(Vec2(-1,0.07)))
	end
end

function create()
	
	--Protection in multiplayer environment where multiple instances of this script is loaded
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	if ( node == nil and this:getSceneName() ~= "In game menu" ) or ( node and node:getClientId() ~= 0 ) then
		return false
	end
	
	
	if this:getNodeType() == NodeId.playerNode then
		local menuNode = this:getRootNode():addChild(SceneNode())
		--camera = Camera()
		menuNode:setSceneName("In game menu")
		menuNode:createWork()
				
		--Move this script to the camera node
		--this:removeScript(this:getCurrentScript():getName());
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		return false
	else
		restartListener = Listener("Restart")
		restartListener:registerEvent("reloadeMap", reloadeMap)
		restartListener:registerEvent("restart", restartMapCallback)
		
		stateBillboard = Core.getGameSessionBillboard("state")
		stateBillboard:setBool("inMenu", false)		
		
		statsBillboard = Core.getBillboard("stats")
		
		Core.setScriptNetworkId("InGameMenu")
		comUnit = Core.getComUnit()
		comUnit:setName("InGameMenu")
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(false)
		
		comUnitTable = {}
		comUnitTable["toggleMenuVisibility"] = toggleVisible
		comUnitTable["hide"] = hideWindow
		comUnitTable["NETclientInfo"] = manageClientInfo
		
		local rootNode = this:getRootNode();
		--camera = Camera()
		local camera = rootNode:findNodeByName("MainCamera");
		
		local keyBinds = Core.getBillboard("keyBind")
		keyBindInfo = keyBinds:getKeyBind("Info screen")
		keyBind = KeyBind("Menu", "control", "toogle menu")
		keyBind:setKeyBindKeyboard(0, Key.escape)
		
		settingsListener = Listener("Settings")
		settingsListener:registerEvent("LanguageChanged",languageChanged)
		
		fileName = mapInfo.getMapFileName()
		
		local showTutorial = (fileName=="Data/Map/Campaign/Beginning.map" or fileName=="Data/Map/Campaign/Intrusion.map" or fileName=="Data/Map/Campaign/Expansion.map")
		gameSpeed = 1
		gamePaused = false
	
		if camera then
			local camera = ConvertToCamera(camera);
			form = Form( camera, PanelSize(Vec2(1)), Alignment.TOP_LEFT)
			form:setName("InGameMenu form")
			form:setRenderLevel(12)
			form:setVisible(false)
			form:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
			form:addEventCallbackOnClick(toggleVisible)
			
			if Core.isInMultiplayer() then
				client = Core.getNetworkClient()
				infoScreen = InfoScreen.new(camera)
			end
			
			mainPanel = form:add(Panel(PanelSize(Vec2(0.17,1))))
			mainPanel:getPanelSize():setFitChildren(false, true);
			mainPanel:setLayout(FallLayout( Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
			mainPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
			mainPanel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
			mainPanel:setVisible(false)
			backgroundPanel = mainPanel

			textPanels[1] = mainPanel:add(Label(PanelSize(Vec2(0.17,1), Vec2(5,1)), language:getText("menu"), MainMenuStyle.textColorHighLighted, Alignment.MIDDLE_CENTER ))
			textPanels[1]:setTag("menu")
			
			MainMenuStyle.createBreakLine(mainPanel)
			
			connectionIssueForm = ConnectionIssueForm.new()
			
			
			local maxXScale = math.max( ( Core.isInEditor() and language:getText("quit to map editor"):getTextScale().x or language:getText("quit to menu"):getTextScale().x), language:getText("quit to desktop"):getTextScale().x )
			--button layou require us to take only the half x text scale
			local scale = Vec2(maxXScale / 2 + 0.5, 1)
			--0.17/5 magic number from before language support was added
					
			
			
			
			
			
			local buttonSize = Vec2(-1,0.07)	
			
			continueButton = mainPanel:add( MainMenuStyle.createMenuButton( buttonSize, nil, language:getText("continue")))
			optionsButton = mainPanel:add( MainMenuStyle.createMenuButton( buttonSize, nil, language:getText("options")))
			tutorialButton = showTutorial and mainPanel:add( MainMenuStyle.createMenuButton( buttonSize, nil, language:getText("tutorial"))) or nil
			launchWavesButton = mapInfo.getGameMode()=="training" and mainPanel:add( MainMenuStyle.createMenuButton( buttonSize, nil, language:getText("launch waves"))) or nil
			RestartWaveButton = (not Core.isInMultiplayer() and (mapInfo.getGameMode()=="default" or mapInfo.getGameMode()=="rush" or mapInfo.getGameMode()=="survival") or mapInfo.getGameMode()=="training") and mainPanel:add( MainMenuStyle.createMenuButton( buttonSize, nil, language:getText("revert wave"))) or nil
			RestartButton = (not Core.isInMultiplayer()) and mainPanel:add( MainMenuStyle.createMenuButton( buttonSize, nil, language:getText("restart"))) or nil
			quitToMenuButton = nil
			quitToEditorButton = nil
			
			if mapInfo.getGameMode()=="training" then
				textList[#textList + 1] = "launch waves"
			end
			
			if Core.isInEditor() then
				quitToEditorButton = mainPanel:add( MainMenuStyle.createMenuButton( buttonSize, nil, language:getText("quit to map editor")))
				textList[#textList + 1] = "quit to map editor"
			else
				quitToMenuButton = mainPanel:add( MainMenuStyle.createMenuButton( buttonSize, nil, language:getText("quit to menu")))
				textList[#textList + 1] = "quit to menu"
			end
			
			
			local tmpLabel = Label(PanelSize(Vec2(-1)),"-")
			tmpLabel:setTextHeight(0.035)
			local maxSize = 16
			for i=1, #textList do
				tmpLabel:setText(language:getText(textList[i]))
				maxSize = math.max(maxSize, tmpLabel:getTextSizeInPixel().x)
			end
			mainPanel:setPanelSize(PanelSize(Vec2((maxSize * 1.05)/Core.getRenderResolution().x,-1)))
			mainPanel:getPanelSize():setFitChildren(false, true)
			
			local quitToDesktopButton = mainPanel:add( MainMenuStyle.createMenuButton( buttonSize, nil, language:getText("quit to desktop")))
			
			continueButton:addEventCallbackExecute(toggleVisible)
			textPanels[2] = continueButton
			textPanels[2]:setTag("continue")
			optionsButton:addEventCallbackExecute(toggleOptionsVisible)
			textPanels[3] = optionsButton
			textPanels[3]:setTag("options")
			quitToDesktopButton:addEventCallbackExecute(quitToDesktop)
			textPanels[4] = quitToDesktopButton
			textPanels[4]:setTag("quit to desktop")
			if quitToMenuButton then
				quitToMenuButton:addEventCallbackExecute(quitToMainMenu)
				textPanels[5] = quitToMenuButton
				textPanels[5]:setTag("quit to menu")
			elseif quitToEditorButton then
				quitToEditorButton:addEventCallbackExecute(quitToMapeditor)
				textPanels[5] = quitToEditorButton
				textPanels[5]:setTag("quit to map editor")
			end
			
			if launchWavesButton then
				textPanels[#textPanels + 1] = launchWavesButton
				textPanels[#textPanels]:setTag("launch waves")
				launchWavesButton:addEventCallbackExecute(launchWaveCallback)
				launchWavesButton:setEnabled(false)
			end
			if RestartWaveButton then
				textPanels[#textPanels + 1] = RestartWaveButton
				textPanels[#textPanels]:setTag("revert wave")
				RestartWaveButton:addEventCallbackExecute(restartWave)
				RestartWaveButton:addEventCallbackExecute(toggleVisible)
				RestartWaveButton:setEnabled(false)
			end
			if RestartButton then
				textPanels[#textPanels + 1] = RestartButton
				textPanels[#textPanels]:setTag("restart")
				RestartButton:addEventCallbackExecute(restartMap)
				RestartButton:addEventCallbackExecute(toggleVisible)
			end
			if tutorialButton then
				textPanels[#textPanels + 1] = tutorialButton
				textPanels[#textPanels]:setTag("tutorial")
				tutorialButton:addEventCallbackExecute(showTutorialFunc)
			end
			
			
			
			--Options form
			optionsForm = Form( camera, PanelSize(Vec2(-1,-0.8), Vec2(4,4)), Alignment.MIDDLE_CENTER);
			optionsForm:setLayout(FallLayout( Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))));
			optionsForm:setRenderLevel(12)
			optionsForm:setVisible(false)
			optionsForm:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
			optionsForm:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
			
			local optionsPanel = OptionsMenu.create(optionsForm)
			optionsPanel:setVisible(true)
		end
	end
	return true
end

function hideWindow()
	form:setVisible(false)
	optionsForm:setVisible(false)
end

function menuButtonTobbleVisible(button)
	if form:getVisible() or optionsForm:getVisible() then
		form:setVisible(false)
		optionsForm:setVisible(false)
	else
		form:setVisible(true)
	end
	pauseGame( form:getVisible() or optionsForm:getVisible() )
end

function toggleVisible(panel)
	if optionsForm:getVisible() then
		optionsForm:setVisible(false)
		backgroundPanel:setVisible(true)
	else
		backgroundPanel:setVisible( not backgroundPanel:getVisible())
		form:setVisible( backgroundPanel:getVisible())
	end
	pauseGame( form:getVisible() or optionsForm:getVisible() )
end

function restartWave()
	restartListener:pushEvent("EventBaseRestartWave")
end

function restartMap()
	restartListener:pushEvent("restart")
end

function showTutorialFunc()
	local scripts = this:getAllScript()
	for i=1, #scripts do
		if scripts[i]:getName() == "tutorial" then
			return 
		end
	end
	Settings.setShowTutorial()
	this:loadLuaScript("Menu/tutorial.lua")
end

function quitToDesktop(panel)
	--crystal gain for survival player if they leave
	local bilboardStats = Core.getBillboard("stats")
	if bilboardStats then
		local crystalGain = bilboardStats:getInt("survivalBonus")
		if crystalGain>0 then
			comUnit:sendTo("stats","setBillboardInt","survivalBonus;"..0)
			local cData = CampaignData.new()
			cData.addCrystal( crystalGain )
		end
	end
	--
	Core.quitMainMenu()
end

function quitToMainMenu(panel)
	--crystal gain for survival player if they leave
	local bilboardStats = Core.getBillboard("stats")
	if bilboardStats then
		local crystalGain = bilboardStats:getInt("survivalBonus")
		if crystalGain>0 then
			comUnit:sendTo("stats","setBillboardInt","survivalBonus;"..0)
			local cData = CampaignData.new()
			cData.addCrystal( crystalGain )
		end
	end
	--
	Core.quitToMainMenu()
	local worker = Worker("Menu/loadingScreen.lua", true)
	worker:start()
end

function quitToMapeditor(panel)
	--local worker = Worker("Menu/loadingScreen.lua", true)
	--worker:start()
	Core.quitToMapeditor()
end

function toggleOptionsVisible(panel)
	backgroundPanel:setVisible(false)
	optionsForm:setVisible( not optionsForm:getVisible() )
	pauseGame( form:getVisible() or optionsForm:getVisible() )
end

function pauseGame(paused)
	stateBillboard:setBool("inMenu", paused)	
	if not Core.isInMultiplayer() and gamePaused ~= paused then
		gamePaused = paused
		if paused then
			gameSpeed = math.max(Core.getTimeSpeed(), 1.0)
			Core.setTimeSpeed(0.0)
		else
			Core.setTimeSpeed(gameSpeed)
		end
		
	end
end

function manageClientInfo(param)
	print("manageClientInfo("..param..")")
	if infoScreen then
		infoScreen.updateClientInfo(param)
	end
end

function update()
	
	
	
	--Handle communication
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message]~=nil then
			comUnitTable[msg.message](msg.parameter)
		end
	end
	
	if connectionIssueForm then
		if client and client:isConnected() and client:isLosingConnection() and connectionIssueForm.getVisible()==false then
			connectionIssueForm.setVisible(true)
		end
		connectionIssueForm.update()
	end
	
	if keyBind:getPressed() then
		toggleVisible()
	end
	--disable button if needed
	if RestartWaveButton then
		if statsBillboard:getInt("wave")>mapInfo.getStartWave() then
			RestartWaveButton:setEnabled(true)
		end
	end
	
	--info screen when pressing tab in multiplayer
	if infoScreen then
		if keyBindInfo:getPressed() then
			infoScreen.togleVisible()
		end
		if infoScreen.isVisible() then
			infoScreen.update()
		end
--		--if another client is losing connection, that is not us
		if infoScreen.manageConnectionIssues() then
		end
	end
	
	if optionsForm:getVisible() then
		OptionsMenu.update()
		optionsForm:update()
	end
--	print("in game menu: "..tostring(form:getVisible()))
	if form:getVisible() then
		form:update()
	end
	return true
end