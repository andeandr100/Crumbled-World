require("NPC/npcBase.lua")
--this = SceneNode()
local npcBase = nil
function destroy()
	npcBase.destroy()
end
function create()
	npcBase = NpcBase.new()
	npcBase.init("rat","npc_rat.mym",0.175,0.6,0.45,3.5)
	local mat = npcBase.getModel():getLocalMatrix()
	npcBase.getSoul().enableBlood("BloodSplatterSphere",1.0,Vec3(0,0.2,0))
	mat:scale(Vec3(0.75,0.75,0.75))
	npcBase.getModel():setLocalMatrix(mat)
	--death animations
	local tableAnimationInfo = {{length = 4.10, duration = 1.42, blendTime=0.25},
								{length = 1.95, duration = 1.00, blendTime=0.50},
								{length = 1.75, duration = 0.95, blendTime=0.50}}
	local tableFrame = {startFrame = 0,
						endFrame = 21,
						framePositions = {5,12,19}}
	npcBase.addDeathAnimation(tableAnimationInfo,tableFrame)

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