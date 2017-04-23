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

function victory()
	victoryImage:setVisible(true)
	form:setVisible(true)
	comUnit:sendTo("InGameMenu","hide","")
end

function defeated()
	
	if not Core.isInMultiplayer() then
		continueButton:setText("Restart")
	end
	
	defeatedImage:setVisible(true)
	form:setVisible(true)
	comUnit:sendTo("InGameMenu","hide","")
end

function startNextMap()
	Worker("Menu/loadingScreen.lua", true)
	Core.startNextMap(selectedFile)
end

function create()
	
	comUnit = Core.getComUnit()
	comUnit:setCanReceiveTargeted(false)
	comUnit:setCanReceiveBroadcast(false)
	
	
	
	restartListener = Listener("Restart")
	
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
	
	
	continueButton = row:add( MainMenuStyle.createButton( Vec2(-0.5,-1), Vec2(5,1), language:getText("continue")))
	local quitToMenuButton = row:add( MainMenuStyle.createButton( Vec2(-1,-1), Vec2(5,1), language:getText("quit to menu")))


	continueButton:addEventCallbackExecute(returnToGame)
	quitToMenuButton:addEventCallbackExecute(quitToMainMenu)
	
	
	--mapInfo
--	local mapInfo = MapInfo.new()
--	if mapInfo.changeToNextMap() then
--		--next map is available (only in the campaign, and not the last map)
--		selectedFile = mapInfo.getMapFileName()
--		local sead = mapInfo.getSead()
--		
--		continueButton:setText(language:getText("next map"))
--		continueButton:addEventCallbackExecute(startNextMap)
--	else
--		--return to menu (only option)
--	end

	return true
end


function returnToGame(panel)
	
	if not Core.isInMultiplayer() and defeatedImage:getVisible() then
		restartMap()
	end

	run = false
	form:setVisible(false)

end


function quitToMainMenu(panel)
	run = false
	Worker("Menu/loadingScreen.lua", true)
	Core.quitToMainMenu()
end

function update()
		
	if form:getVisible() then
		form:update()
	end
	return run
end