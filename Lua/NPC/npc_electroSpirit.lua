require("NPC/npcBase.lua")
require("Game/particleEffect.lua")
--this = SceneNode()
local npcBase
local soul
local pointLight
local collisionModel
local effect
local pLightRange = 1.1
function destroy()
	npcBase.destroy()
end
function create()
	
	npcBase = NpcBase.new()
	soul = npcBase.getSoul()
	pointLight = nil
	collisionModel = nil
	effect = nil
	pLightRange = 1.1
	
	npcBase.init("electroSpirit",nil,0.2,0.6,0.75,2.0)
	npcBase.setDefaultState(state.electrecuted)
	--particle effect
	effect = ParticleSystem(ParticleEffect.SparkSpirit)
	this:addChild(effect)
	effect:activate(Vec3(0,0.65,0))
	-- DEBUG START
	effect:setEmitterLine(Line3D(Vec3(0,0.65,0),Vec3(0,0.65,0)))--this should not be needed
	-- DEBUG END
	npcBase.addParticleEffect(effect,0.35)
	--pointlight
	pointLight = PointLight(Vec3(0,0.25,0),Vec3(0.0,3.0,3.0),1.1)
	pointLight:setCutOff(0.1)
	
	--collisionModel, need to be able to click on this npc
	collisionModel = Core.getModel("lightSphere.mym")
	collisionModel:setLocalPosition(Vec3(0,0.65,0))
	local meshList = collisionModel:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
	for i=1, #meshList do
		meshList[i]:setCanBeRendered(false)
	end
	--pointLight:setIsStatic(true)
	this:addChild(pointLight)
	this:addChild(collisionModel)
	npcBase.addPointLight(pointLight,0.35)
	--resistance
	npcBase.getSoul().setResistance(0.0,true,true,1.33)
	--
	return true
end
function update()
	local hpScale = 0.50+(0.50*(soul.getHp()/soul.getMaxHp()))
	effect:setScale(hpScale)
	pointLight:setRange(pLightRange*hpScale)
	return npcBase.update()
end
--global function
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end