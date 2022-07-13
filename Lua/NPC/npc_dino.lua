require("NPC/npcBase.lua")
--this = SceneNode()
local npcBase
local soul
local healUntouched = 0.10 --10% per second
local untouchedAfter = 3.5
local healMinimum = 0.005 --0.5% per second
local timeLastDamageTaken = 0.0
local prevHpVal = 0.0
--
local AchievementLow = false
--
function destroy()
	npcBase.destroy()
end
function create()
	
	npcBase = NpcBase.new()
	soul = npcBase.getSoul()
	healUntouched = 0.10 --10% per second
	untouchedAfter = 3.5
	healMinimum = 0.005 --0.5% per second
	timeLastDamageTaken = 0.0
	prevHpVal = 0.0
	AchievementLow = false
	
	
	npcBase.init("dino","npc_dino.mym",0.42,0.6,0.8,2.0)
	npcBase.getSoul().enableBlood("BloodSplatterSphere",1.75,Vec3(0,0.35,0))
	npcBase.setDefaultState(state.none)
	--death animations
	local tableAnimationInfo = {{length = 0.92, duration = 1.45, blendTime=0.25},
								{length = 0.75, duration = 1.12, blendTime=0.25}}
	local tableFrame = {startFrame = 0,
						endFrame = 16,
						framePositions = {2,10}}
	npcBase.addDeathAnimation(tableAnimationInfo,tableFrame)
	return true
end

function update()
	local ret = npcBase.update()
	if ret and soul.getHp()>0.0 then
		timeLastDamageTaken = timeLastDamageTaken + Core.getDeltaTime()
		local hpRegen = healMinimum
		if soul.getHp()<prevHpVal then
			timeLastDamageTaken = 0.0
		elseif timeLastDamageTaken>untouchedAfter then
			hpRegen = healUntouched
		end
		prevHpVal = soul.getHp()
		soul.setHp(math.min(soul.getMaxHp(), soul.getHp() + (soul.getMaxHp()*hpRegen*Core.getDeltaTime())))
		if soul.getHp()/soul.getMaxHp()<0.05 then
			AchievementLow = true
		elseif AchievementLow and soul.getHp()+1>soul.getMaxHp() then
			npcBase.getComUnit():sendTo("SteamAchievement","Dino","")
		end
	end
	return ret
end
--global function
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end