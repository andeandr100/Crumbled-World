--this = SceneNode()
function create()
	
--	local comUnit = Core.getComUnit()
--	comUnit:setCanReceiveTargeted(true)
--	comUnit:setName("spawnIconInfo")
--	local billboard = comUnit:getBillboard()
--	
--	local routePlanner = this:findNodeByType(NodeId.RoutePlanner)
--	
--	for i=0, routePlanner:getNumSpawnArea()-1 do
--		local spawnArea = routePlanner:getSpawnArea(i)
--		local spawnName = spawnArea:getName()
--		billboard:setString("spawnAreaName", spawnName)
--		
--		local iconSpawnNode = spawnArea:getIsland():addChild(SceneNode.new())
--		local script = iconSpawnNode:loadLuaScript("Enviromental/spawnIcon.lua")
--		script:update()
--	end
	
	return false
end

function update()
	
	return false
end