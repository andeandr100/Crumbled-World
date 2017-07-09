require("NPC/npcBase.lua")
--this = SceneNode()
local npcBase
function destroy()
	npcBase.destroy()
end
function create()
	
	 npcBase = NpcBase.new()
	
	npcBase.init("skeleton_champion_back","npc_skeleton_champion_back.mym",0.45,0.5,1.3,2.0)
	npcBase.getSoul().enableBlood("BoneSplatterSphere",1.0,Vec3(0,0.35,0))
	--shield blocking
	npcBase.getSoul().setShieldAngle(math.pi*(1/3),false)--120deg block. (+-60deg), front==false
	npcBase.getSoul().setCanBlockBlade(true)
	--death animations
	local tableAnimationInfo = {{length = 0.5, duration = 2.0, blendTime=0.2},
								{length = 0.5, duration = 2.0, blendTime=0.2},
								{length = 0.5, duration = 2.0, blendTime=0.2}}
	local tableFrame = {startFrame = 1,
						endFrame = 24,
						framePositions = {3,11,19}}
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
function update()
	return true
end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end