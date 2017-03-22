require("MapEditor/menuStyle.lua")
--this = SceneNode()

EditorSettings = {}
EditorSettings.buttonShowTowerGrid = nil


function EditorSettings.getConfig()
	--Load config
	local toolConfig = Config("ToolsSettings")
	--Get the ligt tool config settings
	return toolConfig:get("EditorSettings"):getTable()	
end

function EditorSettings.setDefaultValue(name, value)
	local config = EditorSettings.getConfig()
	if not config[name] then
		config[name] = value
	end
end

function EditorSettings.toogleTrueFalseButton(button)
	local dStr = button:getTag():toString()
	local name, value = string.match(button:getTag():toString(), "(.*):(.*)")
	local config = EditorSettings.getConfig()
	if value == "True" then
		button:setText("False")
		config[name] = false
	else
		button:setText("True")
		config[name] = true
	end
	
	if name == "ShowTowerGrids" then
		EditorSettings.setTowerGridVisible(config[name])
		button:setTag("ShowTowerGrids:"..(config["ShowTowerGrids"] and "True" or "False"))
	elseif name == "ShowGrid" then
		EditorSettings.setShowGridVisible(config[name])
		button:setTag("ShowGrid:"..(config["ShowGrid"] and "True" or "False"))
	end
	
	local toolConfig = Config("ToolsSettings")
	toolConfig:get("EditorSettings"):setTable(config)
	toolConfig:save()
end

function EditorSettings.createMenu(panel)
	titlePanel, bodyPanel =  MenuStyle.createTitleAndBody(panel, "Editor Settings")
		
	--body = Panel()
	titlePanel:setVisible(true)
	
	local config = EditorSettings.getConfig()
	EditorSettings.setDefaultValue("ShowTowerGrids", true)
	EditorSettings.setDefaultValue("ShowGrid", true)
	
	
	local buttonText = config["ShowTowerGrids"] and "True" or "False"
	bodyPanel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Show tower grids", Vec3(1)))
	EditorSettings.buttonShowTowerGrid = bodyPanel:add(Button(PanelSize(Vec2(-1, MenuStyle.rowHeight)), buttonText))
	EditorSettings.buttonShowTowerGrid:addEventCallbackExecute(EditorSettings.toogleTrueFalseButton)
	EditorSettings.buttonShowTowerGrid:setTag("ShowTowerGrids:"..(config["ShowTowerGrids"] and "True" or "False"))
	
	local buttonText = config["ShowGrid"] and "True" or "False"
	bodyPanel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Show grid", Vec3(1)))
	EditorSettings.buttonShowTowerGrid = bodyPanel:add(Button(PanelSize(Vec2(-1, MenuStyle.rowHeight)), buttonText))
	EditorSettings.buttonShowTowerGrid:addEventCallbackExecute(EditorSettings.toogleTrueFalseButton)
	EditorSettings.buttonShowTowerGrid:setTag("ShowGrid:"..(config["ShowGrid"] and "True" or "False"))
	
	--add extra row space
	bodyPanel:add(Panel(PanelSize(Vec2(-1, MenuStyle.rowHeight))))
end

function EditorSettings.hideAllDebugModels()
	EditorSettings.setTowerGridVisible(false)
	EditorSettings.setShowGridVisible(false)
end

function EditorSettings.restoreSettings()
	local config = EditorSettings.getConfig()
	
	if config["ShowTowerGrids"] == nil then
		EditorSettings.setTowerGridVisible(true)
	else
		EditorSettings.setTowerGridVisible(config["ShowTowerGrids"])
	end
	EditorSettings.setShowGridVisible(config["ShowGrid"])
end

function EditorSettings.setTowerGridVisible(visible)
	local fileNames = { "debug_circle_5m", "debug_circle_7_5m", "debug_crossbow_attack_area", "debug_tower_platform_1x1", "debug_tower_platform_2x2", "debug_tower_platform_3x3", "debug_tower_platform_4x4" }
	
	local playerNode = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.playerNode)
	if playerNode then
		local modelList = playerNode:findAllNodeByNameTowardsLeaf(fileNames)
		for i=1, #modelList do
			modelList[i]:setVisible( visible )
		end
	end
end

function EditorSettings.setShowGridVisible(visible)
	Core.clearDebugLines()
	if visible then
		for x = -100, 100, 10 do
			if x == 0 then
				Core.addDebugLine(Vec3(x, 0, 100), Vec3(x, 0, -100), 50000, Vec3(0, 0, 1) )
				Core.addDebugLine(Vec3(100, 0, x), Vec3(-100, 0, x), 50000, Vec3(1, 0, 0) )
			else
				Core.addDebugLine(Vec3(x, 0, 100), Vec3(x, 0, -100), 50000, Vec3(0.4) )
				Core.addDebugLine(Vec3(100, 0, x), Vec3(-100, 0, x), 50000, Vec3(0.4) )
			end		
		end
	end
end
	