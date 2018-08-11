function create()
	this:loadLuaScript("Game/stats.lua")

	this:loadLuaScript("Menu/towerMenu.lua")
	this:loadLuaScript("Menu/statsMenu.lua")
	this:loadLuaScript("Menu/selectedMenu.lua")
	this:loadLuaScript("Menu/FPS.lua")

	local buildNode = this:addChild(BuildNode.new():toSceneNode())
	buildNode:loadLuaScript("Game/builder.lua")
	
	local camera = this:getRootNode():findNodeByName("MainCamera")
	if camera then
		camera:loadLuaScript("Game/camera.lua")
	end
	return true
end

function update()
	return false
end