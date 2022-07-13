require("NPC/npcBase.lua")
require("NPC/hydraBase.lua")
--this = SceneNode()
local npcBase
function destroy()
	npcBase.destroy()
end
function create()
	
	npcBase = NpcBase.new()
		
	createHydra(1,0.5,npcBase)
	--
	local tableAnimationInfo = {{duration = 0.75, length = 1.0, blendTime=0.25},
								{duration = 0.75, length = 1.0, blendTime=0.25},
								{duration = 0.75, length = 1.0, blendTime=0.25}}
	local tableFrame = {startFrame = 5,
						endFrame = 45,
						framePositions = {10,23,36}}
	npcBase.addDeathAnimation(tableAnimationInfo,tableFrame)

	--
	createPushFunctions()
	if updatePush and type(updatePush)=="function" then
		update = updatePush
	else
		error("unable to set update function")
	end
	return true
end

function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end