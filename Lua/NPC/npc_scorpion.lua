require("NPC/npcBase.lua")
--this = SceneNode()
local npcBase
function destroy()
	--print("Destroy = "..tostring(Core.getNetworkName()) )
	npcBase.destroy()
end
function create()
	
	npcBase = NpcBase.new()
	npcBase.init("scorpion","npc_scorpion1.mym",0.225,0.6,0.45,2.0)
	npcBase.getSoul().enableBlood("BloodSplatterSphere",1.75,Vec3(0,0.25,0))
	local tableAnimationInfo = {{duration = 0.65, length = 0.44, blendTime=0.25},
								{duration = 0.75, length = 0.98, blendTime=0.25},
								{duration = 0.71, length = 1.08, blendTime=0.25},
								{duration = 0.67, length = 1.00, blendTime=0.25}}
	local tableFrame = {startFrame = 0,
						endFrame = 18,
						framePositions = {5,14,10,1}}
	npcBase.addDeathAnimation(tableAnimationInfo,tableFrame)
	if npcBase.update and type(npcBase.update)=="function" then
		update = npcBase.update
	else
		error("unable to set update function")
	end
	return true
end

function update()
	error("this should not be used!!!")
	return true
end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end