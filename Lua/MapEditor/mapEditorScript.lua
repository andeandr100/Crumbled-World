--this = SceneNode()
function create()

	--camera
	this:loadLuaScript("Game/camera.lua")
	--menu also handle creation of new maps
	this:loadLuaScript("MapEditor/menu.lua")
	--handle map saves and load
	this:loadLuaScript("MapEditor/saveMenu.lua")
	--lua text editor
	this:loadLuaScript("MapEditor/luaEditorForm.lua")
	--map settings form
	this:loadLuaScript("MapEditor/MapSettings.lua")
	--selected menu
	this:loadLuaScript("MapEditor/Tools/SceneSelectToolMenu.lua")
	
	this:update()
	
	
	--Load tools
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		--Load grass tool
		toolManager:loadToolScript("MapEditor/Tools/grassTool.lua")
		toolManager:loadToolScript("MapEditor/Tools/pathTool.lua")
		--load and set the scene select tool as default tool
		toolManager:setToolScript("MapEditor/Tools/SceneSelectTool.lua")
		
--		toolManager:setToolScript("MapEditor/Tools/navMeshDirectionTool.lua")
		
	else
		print("\no tool manager\n\n")
		abort()
	end
	
	
	
	return true
end

function update()
	return true;
end