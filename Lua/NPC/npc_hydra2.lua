require("NPC/npcBase.lua")
require("NPC/hydraBase.lua")
--this = SceneNode()
local npcBase
function destroy()
	npcBase = nil
end
function create()
	
	npcBase = NpcBase.new()
	
	createHydra(2,0.65,npcBase)
	npcBase.setLifeValue("2")--this npc will end up with 2 level 1 units
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
		spawnHydras(1)
	end
	--
	npcBase.deathCleanup()
	return true
end
function update()
	return updatePush()
end
--override gold on death, because there is no gold earned killing this unit
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end