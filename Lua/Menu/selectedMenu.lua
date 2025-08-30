require("Game/builderUpgrader.lua")
require("Game/targetArea.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/settings.lua")
require("Menu/selectedTowerMenu.lua")
require("Menu/selectedNpcMenu.lua")

--this = SceneNode()

function restartWave()
	if towerMenu.getVisible() then
		reloadTowerMenu = 2
	end
end

function setVisibleClass(class)
	if towerMenu == class then
		npcMenu.setVisible(false)
		towerMenu.setVisible(true)
	elseif npcMenu == class then
		npcMenu.setVisible(true)
		towerMenu.setVisible(false)
	else
		npcMenu.setVisible(false)
		towerMenu.setVisible(false)
	end
end

function destroy()
	
end

function restore(data)
	setVisibleClass(nil)
end

function create()
	
	--Protection in multiplayer environment where multiple instances of this script is loaded
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	if ( node == nil and this:getSceneName() ~= "Selected menu" ) or ( node and node:getClientId() ~= 0 ) then
		return false
	end
	
	if this:getNodeType() == NodeId.playerNode then
		local menuNode = this:getRootNode():addChild(SceneNode.new())
		--camera = Camera()
		menuNode:setSceneName("Selected menu")
		
		menuNode:createWork()
				
		--Move this script to the camera node
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		return false
	else
		
		local rootNode = this:getRootNode();
		camera = ConvertToCamera(rootNode:findNodeByName("MainCamera"));
		buildingNodeBillboard = Core.getBillboard("buildings")
		
		--camera
		selectedCamera = Camera.new(Text("Selected buildng"),true,200,200);
		selectedCamera:setShadowScale(2.0)
		selectedCamera:setDirectionLight(Core.getDirectionalLight(this))
		selectedCamera:setAmbientLight(Core.getAmbientLight(this))
		selectedCamera:setRenderScript("Camera/selectedTowerRender.lua")
		selectedCamera:setActive(false)
		
		--keybinds
		keyBinds = Core.getBillboard("keyBind");
		esqKeyBind = KeyBind("Menu", "control", "toogle menu")
		esqKeyBind:setKeyBindKeyboard(0, Key.escape)
		
		
		restartListener = Listener("Restart")
		restartListener:registerEvent("restart", restartMap)
		
		if camera then
			npcMenu = selectedNpcMenu.new(camera, selectedCamera)
			towerMenu = selectedtowerMenu.new(camera, selectedCamera)
		
			Core.setScriptNetworkId("SelectedMenu")
			comUnit = Core.getComUnit();
			comUnit:setName("SelectedMenu")
			comUnit:setCanReceiveTargeted(true);
			comUnit:setCanReceiveBroadcast(true);
			
			restartWaveListener = Listener("RestartWave")
			restartWaveListener:registerEvent("restartWave", restartWave)
			reloadTowerMenu = -1
			
			--Handle communication
			comUnitTable = {}					
		--	comUnitTable["NetSell"] = towerMenu.networkSellTower
			comUnitTable["NETUW"] = towerMenu.netUpgradeWallTower
			comUnitTable["waveChanged"] = towerMenu.waveChanged
		--	comUnitTable["sellTowerBynetId"] = towerMenu.sellTowerFromNetwork
			comUnitTable["downGradeTowerBynetId"] = towerMenu.downGradeTower
			comUnitTable["updateSelectedTower"] = towerMenu.updateSelectedTower
		end
		
		settingsListener = Listener("Settings")
		settingsListener:registerEvent("Changed", settingsChanged)
		settingsChanged()
	end
	return true
end

function restartMap()
	print("\n\nSelected menu is in hidding because map restart\n\n")
	setVisibleClass(nil)
end

function settingsChanged()
	print("\n\n\nsettingsChanged() - - - - - - - \n\n\n")
	selectedCamera:setDefferRenderShader(Settings.getDeferredShader())
	selectedCamera:setUseShadow(Settings.shadow.getIsEnabled())
	selectedCamera:setDynamicLightsEnable(Settings.dynamicLights.getEnabled())
	selectedCamera:setUseGlow(Settings.glow.getEnabled())
	selectedCamera:setUseAntiAliasing(false)
	selectedCamera:setUseSelectedRender(false)
end



function update()
	--Handle communication
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		--print("selectedMenu: msg="..msg.message)
		if comUnitTable[msg.message]~=nil then
		 	comUnitTable[msg.message](msg.parameter,msg.fromIndex)
		end
	end

	--when in game menu is shown hide selected tower menu
	if esqKeyBind:getPressed() or buildingNodeBillboard:getBool("inBuildMode") then
		setVisibleClass(nil)
	end
	
	--this ocure when a restart wave event is called
	if reloadTowerMenu > 0 then
		reloadTowerMenu = reloadTowerMenu - 1
		if reloadTowerMenu == 0 and towerMenu.getVisible() then
			--reload tower menu
			towerMenu.updateSelectedTower()
		end
	end
	
	towerMenu.update()
	npcMenu.update()
	

	if billboardStats == nil then
		billboardStats = Core.getBillboard("stats")
		
	end
	selectedCamera:render()

	return true

end