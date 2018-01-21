require("MapEditor/Tools/Tool.lua")
require("MapEditor/menuStyle.lua")
require("Menu/colorPicker.lua")
--this = SceneNode()

function colorChanged(panel)
	
	local color = lightColor.getColor()
	
	lightModel:setColor( color * amplitudTextField:getFloat() )
	lightModel:update()
	
	lightToolConfig:get("color"):set( color )
	rootConfig:save()
end

function rangeChanged(panel)
	lightModel:setRange(rangeTextField:getFloat())
	
	lightToolConfig:get("range"):set( rangeTextField:getFloat() )
	rootConfig:save()
end

function amplitudChanged(panel)
	lightToolConfig:get("amplitud"):set( amplitudTextField:getFloat() )
	colorChanged(nil)
end

function toogleEnableDisabledButton(button)
	local name, value = string.match(button:getTag():toString(), "(.*):(.*)")
	if value == "True" then
		button:setText("Disabled")
		lightToolConfig:get(name):setBool(false)
	else
		button:setText("Enabled")
		lightToolConfig:get(name):setBool(true)
	end
	rootConfig:save()

	button:setTag(name..":"..(lightToolConfig:get(name):getBool() and "True" or "False"))
	
	useObjectCollision = lightToolConfig:get("objectCollision"):getBool()
	useObjectNormal = lightToolConfig:get("useNormal"):getBool()
end

function createMenu(panel)
	
	local panelWidthFor2 = toolAndSettingMenuSize - toolButtonSpaceing * 2 - toolButtonSpaceing
	
	useObjectCollision = lightToolConfig:get("objectCollision"):getBool()
	useObjectNormal = lightToolConfig:get("useNormal"):getBool()

	panel:add(Label(PanelSize(Vec2(panelWidthFor2 * 0.7, MenuStyle.rowHeight)),"Object collision", Vec3(1)))
	local button = panel:add(Button(PanelSize(Vec2(-1, MenuStyle.rowHeight)), "Enabled"))
	button:addEventCallbackExecute(toogleEnableDisabledButton)
	button:setTag("objectCollision:"..(lightToolConfig:get("objectCollision"):getBool() and "True" or "False"))

	panel:add(Label(PanelSize(Vec2(panelWidthFor2 * 0.7, MenuStyle.rowHeight)),"Use collision normal", Vec3(1)))
	button = panel:add(Button(PanelSize(Vec2(-1, MenuStyle.rowHeight)), "Enabled"))
	button:addEventCallbackExecute(toogleEnableDisabledButton)
	button:setTag("useNormal:"..(lightToolConfig:get("useNormal"):getBool() and "True" or "False"))
	
	
	--toolAndSettingMenuSize
	
	
	panel:add(Label(PanelSize(Vec2(panelWidthFor2 * 0.7, MenuStyle.rowHeight)),"Color", Vec3(1)))
	lightColor = ColorPickerForm.new(panel, PanelSize(Vec2(-1, MenuStyle.rowHeight)), lightToolConfig:get("color"):getVec3())
	lightColor.setChangeCallback(colorChanged)
	
	local panelWidth = (toolAndSettingMenuSize - toolButtonSpaceing * (2 + 2))/3
	
	bodyPanel:add(Label(PanelSize(Vec2(panelWidthFor2 * 0.7, MenuStyle.rowHeight)), "Color amplitud", Vec3(1)))
	amplitudTextField = bodyPanel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), tostring(lightToolConfig:get("amplitud"):getFloat())))
	amplitudTextField:setWhiteList("0123456789.")
	amplitudTextField:addEventCallbackChanged(amplitudChanged)
	
	
	bodyPanel:add(Label(PanelSize(Vec2(panelWidthFor2 * 0.7, MenuStyle.rowHeight)), "Range", Vec3(1)))
	rangeTextField = bodyPanel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), tostring(lightToolConfig:get("range"):getFloat())))
	rangeTextField:setWhiteList("0123456789.")
	rangeTextField:addEventCallbackChanged(rangeChanged)
	
	colorChanged(nil)
	rangeChanged(nil)
end

function setDefaultValue(name, value)
	if not lightToolConfig:exist(name) then
		lightToolConfig:get(name):set(value)
	end
end

function create()
	Tool.create()
	
	lightModel = PointLightModel.new(Vec3(1), 5)
	worldNode = this:getRootNode()
	lightModel:setVisible(false)
	worldNode:addChild(lightModel:toSceneNode())
	
	--Get billboard for the map editor
	local mapEditor = Core.getBillboard("MapEditor")
	--Get the setting panel
	settingsPanel = mapEditor:getPanel("SettingPanel")
	
	--Load config
	rootConfig = Config("ToolsSettings")
	--Get the ligt tool config settings
	lightToolConfig = rootConfig:get("LightTool")
	
	

	setDefaultValue("objectCollision", true)
	setDefaultValue("useNormal", true)
	setDefaultValue("range", 2)
	setDefaultValue("amplitud", 5)
	setDefaultValue("color", Vec3(1,1,0.5))
	
	if settingsPanel then
		titlePanel, bodyPanel =  MenuStyle.createTitleAndBody(settingsPanel, "Point light tool")
		
		--body = Panel()
		titlePanel:setVisible(true)
		createMenu(bodyPanel)
	end
		
	return true
end

function activated()
	titlePanel:setVisible(true)
	Tool.clearSelectedNodes(nil)
	print("activated\n")
end

function deActivated()
	lightModel:setVisible(false)
	titlePanel:setVisible(false)
	
	lightColor.setVisible(false)	
	print("Deactivated\n")
end

function update()
	local node, collisionPos, collisionNormal = Tool.getCollision(useObjectCollision)
	--node = SceneNode.new()
	if node then
		
		if useObjectNormal then
			collisionPos = collisionPos + collisionNormal * 0.3
		end
		
		lightModel:setVisible(true)
		lightModel:setLocalPosition( collisionPos )
		
		if Core.getInput():getMouseDown( MouseKey.left ) then
			local aIsland = node:findNodeByType(NodeId.island)
			if aIsland then
				aIsland:addChild(PointLightModel.new( aIsland:getGlobalMatrix():inverseM() * collisionPos, lightModel:getColor(), lightModel:getRange()):toSceneNode())
			end
		end
	else
		lightModel:setVisible(false)
	end
	
	lightColor.update()
	Tool.update()
	
	return true
end