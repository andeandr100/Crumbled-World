require("NPC/npcBase.lua")
require("NPC/hydraBase.lua")
--this = SceneNode()
local npcBase
function destroy()
	npcBase.destroy()
end
function create()
	
	npcBase = NpcBase.new()
	
	createHydra(3,0.75,npcBase)
	npcBase.setLifeValue("4")--this npc will end up with 4 level 1 units
	--
	createPushFunctions()
	if updatePush and type(updatePush)=="function" then
		update = updatePush
	else
		error("unable to set update function")
	end
	npcBase.createDeadBody = createDeadBody
	return true
end
--start the death animations/physic/effect
function createDeadBody()
	setUpAlphaDeath()
	--
	if not npcBase.getMover():isAtFinalDestination() then
		spawnHydras(2)
	end
	--
	npcBase.deathCleanup()
	return true
end
function update()
	return true
end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end