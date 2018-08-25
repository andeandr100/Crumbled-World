require("NPC/npcBase.lua")
require("NPC/state.lua")
--this = SceneNode()
local npcBase
function destroy()
	npcBase.destroy()
end
function create()
	
	npcBase = NpcBase.new()
	
	npcBase.init("skeleton","npc_skeleton1.mym",0.25,0.6,0.90,2.0)
	npcBase.getSoul().enableBlood("BoneSplatterSphere",0.85,Vec3(0,0.3,0))
	npcBase.setDefaultState(state.spawned)
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
	--override update function
	if npcBase.update and type(npcBase.update)=="function" then
		update = npcBase.update
	else
		error("unable to set update function")
	end
	--no gold is earned from this unit
	npcBase.setGainGoldOnDeath(false)
	-- 
	npcBase.getComUnitTable()["setPathPoints"] = setPathPoints
	--
	return true
end
function update()
	return true
end

function split(str,sep)
	local array = {}
	local reg = string.format("([^%s]+)",sep)
	for mem in string.gmatch(str,reg) do
		array[#array + 1] = mem
	end	
	return array
end

function setPathPoints(dataString)
	local pathPoints = {}
	--Split into pathpoints
	local points = split(dataString,";")
	for i=1, #points do
		--split data into data points
		local data = split(points[i],",")
		pathPoints[i] = {}
		pathPoints[i].localIslandPos = Vec3(tonumber(data[1]),tonumber(data[2]),tonumber(data[3]))
		pathPoints[i].islandId = tonumber(data[4])
	end
	npcBase.getMover():setPathPoints(pathPoints)

end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end