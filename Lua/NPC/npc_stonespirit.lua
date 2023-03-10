require("NPC/npcBase.lua")
require("Game/particleEffect.lua")
--this = SceneNode()
local npcBase
function destroy()
	npcBase = nil
end
function create()
	
	npcBase = NpcBase.new()
	
	npcBase.init("stoneSpirit","npc_stonespirit.mym",0.2,0.6,1.3,2.0)
	--physic animated death
	npcBase.addDeathRigidBody(false)
	--particle effect
	sparkCenter = ParticleSystem.new(ParticleEffect.SpiritStone)
	sparkCenter:activate(Vec3(0.0,0.75,0.0))
	this:addChild(sparkCenter:toSceneNode())
	npcBase.addParticleEffect(sparkCenter,0.5)
	--pointlight
	pointLight = PointLight.new(Vec3(0,0.85,0),Vec3(0.0,3.0,3.0),1.5)
	pointLight:setCutOff(0.1)
	--pointLight:setIsStatic(true)
	this:addChild(pointLight:toSceneNode())
	npcBase.addPointLight(pointLight,0.5)
	--
	return true
end
function update()
	return npcBase.update()
end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end