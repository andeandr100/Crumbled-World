require("NPC/npcBase.lua")
--this = SceneNode()
local npcBase
function destroy()
	npcBase.destroy()
end
function create()
	
	npcBase = NpcBase.new()
	
	npcBase.init("skeleton","npc_skeleton1.mym",0.25,0.5,0.90,2.0)
	npcBase.getSoul().enableBlood("BoneSplatterSphere",0.85,Vec3(0,0.3,0))
	--death animations
	local tableAnimationInfo = {{length = 0.5, duration = 2.0, blendTime=0.2},
								{length = 0.5, duration = 2.0, blendTime=0.2},
								{length = 0.5, duration = 2.0, blendTime=0.2}}
	local tableFrame = {startFrame = 0,
						endFrame = 23,
						framePositions = {2,10,18}}
	npcBase.addDeathAnimation(tableAnimationInfo,tableFrame)
	--physic animated death
	npcBase.addDeathRigidBody()
	if npcBase.update and type(npcBase.update)=="function" then
		update = npcBase.update
	else
		error("unable to set update function")
	end
	return true
end
--function update()
--	return true
--end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end