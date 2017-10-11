require("Menu/MainMenu/mainMenuStyle.lua")
require("Game/mapInfo.lua")
--this = SceneNode()

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

function restartMap()
	restartListener:pushEvent("restart")
end
function restartWave()
	restartWaveListener:pushEvent("EventBaseRestartWave")
	form:setVisible(false)
end

function victory()
	victoryImage:setVisible(true)
	restartWaveButton:setEnabled(false)
	form:setVisible(true)
	comUnit:sendTo("InGameMenu","hide","")
end

function defeated()
	
--	if not Core.isInMultiplayer() then
--		continueButton:setText("Restart")
--	end
	
	defeatedImage:setVisible(true)
	restartWaveButton:setEnabled(true)
	form:setVisible(true)
	comUnit:sendTo("InGameMenu","hide","")
end

function startNextMap()
	local worker = Worker("Menu/loadingScreen.lua", true)
	worker:start()
	Core.startNextMap(selectedFile)
end

function create()
	
	comUnit = Core.getComUnit()
	comUnit:setCanReceiveTargeted(false)
	comUnit:setCanReceiveBroadcast(false)
	
	
	
	restartListener = Listener("Restart")
	restartWaveListener = Listener("EventBaseRestartWave")
	
	local rootNode = this:getRootNode();
	local camera = rootNode:findNodeByName("MainCamera");

	local camera = ConvertToCamera(camera);
	form = Form( camera, PanelSize(Vec2(0.3,-1)), Alignment.MIDDLE_CENTER);
	form:setName("EndGameMenu form")
	form:getPanelSize():setFitChildren(false, true);
	form:setLayout(FallLayout( Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))));
	form:setRenderLevel(11)
	form:setVisible(false)
	form:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
	form:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
	
	
	victoryImage = form:add(Image(PanelSize(Vec2(-1,1), Vec2(3,1)), "victory"))
	victoryImage:setVisible(false)
	
	defeatedImage = form:add(Image(PanelSize(Vec2(-1,1), Vec2(3,1)), "defeated"))
	defeatedImage:setVisible(false)
	
	MainMenuStyle.createBreakLine(form)
	
	
	local row = form:add(Panel(PanelSize(Vec2(-0.9,1),Vec2(10.1,1))))
	row:setLayout(FlowLayout(PanelSize(Vec2(0.001,0))))
	
	form:add(Panel(PanelSize(Vec2(-0.9,0.002))))
	
	run = true
	
	
	--continueButton = row:add( MainMenuStyle.createButton( Vec2(-0.33,-1), Vec2(5,1), language:getText("continue")))
	restartWaveButton = row:add( MainMenuStyle.createButton( Vec2(-0.5,-1), Vec2(5,1), language:getText("revert wave")))
	local quitToMenuButton = row:add( MainMenuStyle.createButton( Vec2(-1,-1), Vec2(5,1), language:getText("quit to menu")))


	--continueButton:addEventCallbackExecute(returnToGame)
	restartWaveButton:addEventCallbackExecute(restartWave)
	quitToMenuButton:addEventCallbackExecute(quitToMainMenu)
	
	return true
end


--function returnToGame(panel)
--	
--	if not Core.isInMultiplayer() and defeatedImage:getVisible() then
--		restartMap()
--	end
--
--	run = false
--	form:setVisible(false)
--
--end


function quitToMainMenu(panel)
	run = false
	local worker = Worker("Menu/loadingScreen.lua", true)
	worker:start()
	Core.quitToMainMenu()
end

function update()
		
	if form:getVisible() then
		form:update()
	end
	return run
end