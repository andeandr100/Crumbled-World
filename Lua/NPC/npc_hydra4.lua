require("NPC/npcBase.lua")
require("NPC/hydraBase.lua")
--this = SceneNode()
local npcBase
function destroy()
	npcBase = nil
end
function create()
	
	npcBase = NpcBase.new()
	
	createHydra(4,0.9,npcBase)
	npcBase.setLifeValue("8")--this npc will end up with 8 level 1 units
	--
	createPushFunctions()
	
	npcBase.createDeadBody = createDeadBody
	return true
end
--start the death animations/physic/effect
function createDeadBody()
	setUpAlphaDeath()
	--
	if not npcBase.getMover():isAtFinalDestination() then
		spawnHydras(3)
	end
	--
	npcBase.deathCleanup()
	return true
end
function update()
	return updatePush()
end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end