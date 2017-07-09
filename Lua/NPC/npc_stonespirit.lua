require("NPC/npcBase.lua")
require("Game/particleEffect.lua")
--this = SceneNode()
local npcBase
function destroy()
	npcBase.destroy()
end
function create()
	
	npcBase = NpcBase.new()
	
	npcBase.init("stoneSpirit","npc_stonespirit.mym",0.2,0.5,1.3,2.0)
	--physic animated death
	npcBase.addDeathRigidBody()
	--particle effect
	sparkCenter = ParticleSystem(ParticleEffect.SpiritStone)
	sparkCenter:activate(Vec3(0.0,0.75,0.0))
	this:addChild(sparkCenter)
	npcBase.addParticleEffect(sparkCenter,0.5)
	--pointlight
	pointLight = PointLight(Vec3(0,0.85,0),Vec3(0.0,3.0,3.0),1.5)
	pointLight:setCutOff(0.1)
	--pointLight:setIsStatic(true)
	this:addChild(pointLight)
	npcBase.addPointLight(pointLight,0.5)
	--
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