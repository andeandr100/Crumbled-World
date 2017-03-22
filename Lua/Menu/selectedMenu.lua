require("Game/builderUpgrader.lua")
require("Game/targetArea.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/settings.lua")
require("Menu/selectedTowerMenu.lua")
require("Menu/selectedNpcMenu.lua")

--this = SceneNode()
function instalForm()
	str = ""
	local panelSpacing = PanelSize(Vec2(0.005),Vec2(1))
	form = Form( camera, PanelSize(Vec2(0.225,-1),PanelSizeType.WindowPercentBasedOny), Alignment.BOTTOM_RIGHT);
	form:setName("SelectedMenu form")
	form:getPanelSize():setFitChildren(false,true)
	form:setBackground(Gradient(Vec4(Vec3(0),0.85), Vec4(Vec3(0),0.7)));
	form:setLayout(FallLayout(panelSpacing));
	form:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor));
	form:setPadding(BorderSize(Vec4(MainMenuStyle.borderSize * 3)));
	form:setFormOffset(PanelSize(Vec2(0.005), Vec2(1)));
	form:setRenderLevel(1)
	
	--form = Form()
	header = form:add(Label(PanelSize(Vec2(-1,0.03)), "", Alignment.MIDDLE_CENTER));
	header:setTextColor(Vec3(1))
	
	local lineBreak = form:add(Panel(PanelSize(Vec2(-1,0.002))));
	lineBreak:setBackground(Sprite(Vec4(0.4,0.4,0.4,0.7)))


--	local mainPanel = form:add(Panel(PanelSize(Vec2(-1,1),Vec2(2,1.1))))
--	local mainPanel = form:add(Panel(PanelSize(Vec2(-1,1))))
--	mainPanel:getPanelSize():setFitChildren(false,true)
--	mainPanel:setLayout(FallLayout())

	leftMainPanel = form:add(Panel(PanelSize(Vec2(-1),Vec2(1,1.1))));
	leftMainPanel:setLayout(FallLayout(PanelSize(Vec2(0.01),Vec2(1))))
	

	--tower image
	towerImagePanel = form:add(Panel(PanelSize(Vec2(-1),Vec2(1))));
	towerImagePanel:setBackground(Sprite(selectedCamera:getTexture()));
--	towerImagePanel:setBackground(Sprite(Vec3(0.3)));
	towerImagePanel:setLayout(FlowLayout());
	towerImagePanel:getLayout():setPanelSpacing(PanelSize(Vec2(0.005)));
	
	towerMenu = selectedtowerMenu.new(form, leftMainPanel, towerImagePanel)
	npcMenu = selectedNpcMenu.new(form, leftMainPanel, towerImagePanel)
	
	Core.setScriptNetworkId("SelectedMenu")
	comUnit = Core.getComUnit();
	comUnit:setName("SelectedMenu")
	comUnit:setCanReceiveTargeted(true);
	comUnit:setCanReceiveBroadcast(true);
	
	--Handle communication
	comUnitTable = {}					
--	comUnitTable["NetSell"] = towerMenu.networkSellTower
	comUnitTable["NETUW"] = towerMenu.netUpgradeWallTower
	comUnitTable["waveChanged"] = towerMenu.waveChanged
--	comUnitTable["sellTowerBynetId"] = towerMenu.sellTowerFromNetwork
	comUnitTable["downGradeTowerBynetId"] = towerMenu.downGradeTower
	comUnitTable["updateSelectedTower"] = towerMenu.updateSelectedTower

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
	if form then
		print("\n\nSelected menu is in hidding because form is being destroyed\n\n")
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

function restore(data)
	if data.form then
		print("\n\nSelected menu is in hidding because restore function caled\n\n")
		data.form:setVisible(false)
		data.form:destroy()
		data.form = nil
	end
end

function create()
	if this:getNodeType() == NodeId.playerNode then
		local menuNode = this:getRootNode():addChild(SceneNode())
		--camera = Camera()
		menuNode:setSceneName("Selected menu")
		
		menuNode:createWork()
				
		--Move this script to the camera node
		--this:removeScript(this:getCurrentScript():getName());
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		return false
	else
		
		local rootNode = this:getRootNode();
		camera = ConvertToCamera(rootNode:findNodeByName("MainCamera"));
		buildingNodeBillboard = Core.getBillboard("buildings")
		
		--camera
		selectedCamera = Camera(Text("Selected buildng"),true,200,200);
		selectedCamera:setShadowScale(2.0)
		selectedCamera:setDirectionLight(Core.getDirectionalLight(this))
		selectedCamera:setAmbientLight(Core.getAmbientLight(this))
		selectedCamera:setRenderScript("Game/render.lua")
--		selectedCamera:setClearColor(Vec4(1,0,0,1))

		
		--keybinds
		keyBinds = Core.getBillboard("keyBind");
		esqKeyBind = KeyBind("Menu", "control", "toogle menu")
		esqKeyBind:setKeyBindKeyboard(0, Key.escape)
		
		
		restartListener = Listener("Restart")
		restartListener:registerEvent("restart", restartMap)
		
		restoreData = {form = form}
		setRestoreData(restoreData)
		
		if camera then
			
			instalForm()
			
			form:update()
			form:setVisible(false)
		else
			--print("No camera was ever found\n");
		end
		
		settingsListener = Listener("Settings")
		settingsListener:registerEvent("Changed", settingsChanged)
		settingsChanged()
	end
	return true
end

function restartMap()
	print("\n\nSelected menu is in hidding because map restart\n\n")
	
	form:setVisible(false)
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
		print("selectedMenu: msg="..msg.message)
		if comUnitTable[msg.message]~=nil then
		 	comUnitTable[msg.message](msg.parameter,msg.fromIndex)
		end
	end

	--when in game menu is shown hide selected tower menu
	if esqKeyBind:getPressed() or buildingNodeBillboard:getBool("inBuildMode") then
		form:setVisible(false)
		setVisibleClass(nil)
	end
	
	towerMenu.update()
	npcMenu.update()
	
	if form:getVisible() then
		
		if billboardStats == nil then
			billboardStats = Core.getBillboard("stats")
		end
		selectedCamera:render()
		form:update()	
	end
	return true

end