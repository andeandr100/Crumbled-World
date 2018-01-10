--this = SceneNode()

--NPC
function createNpcNode()
	local routePlanner = this:findNodeByType(NodeId.RoutePlanner)
	--routePlanner = RoutePlanner()
	local spawnArea = routePlanner:getRandomSpawnArea()
	local island = spawnArea:getIsland()
	local npcNode = island:addChild(SceneNode.new())
	npcNode:setLocalPosition( island:getGlobalMatrix():inverseM() * spawnArea:getGlobalPosition())
	return npcNode
end

function spawnUnits()

	local node = createNpcNode()
	node:loadLuaScript("NPC/npc_rat.lua")

end

function create()
	timeBettwenSpawn = 8
	timeToNextSpawn = 1
	return true
end

function update()
	
	timeToNextSpawn = timeToNextSpawn - Core.getDeltaTime()
	if timeToNextSpawn < 0 then
		spawnUnits()
		timeToNextSpawn = timeBettwenSpawn
	end
	
	return true
end