--this=SceneNode()

function hideAllSettingsPanel()
	toolWorldSettingsPanel:setVisible(false)
end

function setToolIslandBuilder(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setIslanduilderTool()
	end
end

function setIslandRiseTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setIslandRiseTool()
	end
end

function setIslandLowerTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setIslandLowerTool()
	end
end

function setIslandSmothTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setIslandSmothTool()
	end
end

function setIslandSmothTool(panel)
	hideAllSettingsPanel()
	
	if toolManager then
		toolManager:setIslandSmothTool()
	end
end

function setIslandElevateTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setIslandElevateTool()
	end
end

function setIslandColorTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setIslandColorTool()
	end
end


---------------------------------------------
--------------------------------------------


function setLightBuilderToool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setToolScript("MapEditor/Tools/LightTool.lua")
	end
end

function setBridgeBuilderTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setToolScript("MapEditor/Tools/BridgeBuilderTool.lua")
	end
end

function setNavMeshBuilderTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setNavMeshBuilderTool()
	end
end

function setSpawnAreaBuilderTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setSpawnAreaBuilderTool()
	end
end

function setEndAreaBuilderTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setEndAreaBuilderTool()
	end
end

function setPathBuilderTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setPathBuilderTool()
	end
end

function setGrassTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setToolScript("MapEditor/Tools/grassTool.lua")
	end
end

function setPathTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setToolScript("MapEditor/Tools/pathTool.lua")
	end
end




function setRailroadTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setToolScript("MapEditor/Tools/railroadTool.lua")
	end	
end

function setIslandPaintbrushTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setToolScript("MapEditor/Tools/islandPaintTool.lua")
	end	
end

function setPointPathBuilderTool(panel)
	hideAllSettingsPanel()
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setPointPathBuilderTool()
	end
end

function createIslandEdge(panel)
	print("try to create edge\n")
	local mapEditor = Core.getBillboard("MapEditor")
	local editScene =  mapEditor:getSceneNode("editScene")
	if editScene:getNodeType() ~= NodeId.island then
		print("Not an island\n")
		editScene = editScene:findNodeByTypeTowardsLeafe(NodeId.island)
	end
	if editScene then
		print("Creat island edge\n")
		editScene:toSceneNode():loadLuaScriptAndRunOnce("MapEditor/edgeCreaterTool.lua")
	end
end
function createIslandEdgeFlora(panel)
	print("try to create edge\n")
	local mapEditor = Core.getBillboard("MapEditor")
	local editScene =  mapEditor:getSceneNode("editScene")
	if editScene:getNodeType() ~= NodeId.island then
		print("Not an island\n")
		editScene = editScene:findNodeByTypeTowardsLeafe(NodeId.island)
	end
	if editScene then
		print("generate edge flora\n")
		editScene:toSceneNode():loadLuaScriptAndRunOnce("MapEditor/edgeFloraGeneratorTool.lua")
	end
end