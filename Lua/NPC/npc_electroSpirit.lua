require("NPC/npcBase.lua")
require("Game/particleEffect.lua")
--this = SceneNode()
local npcBase
local soul
local spiritPointLight
local collisionModel
local effect
local pLightRange = 1.1
function destroy()
	if spiritPointLight then
		spiritPointLight:destroy()
		spiritPointLight = nil
	end
	if collisionModel then
		collisionModel:destroy()
	end
	effect:destroy();
	
	npcBase = nil
	
	collisionModel = nil
	effect = nil
	soul = nil
end
function create()
	
	npcBase = NpcBase.new()
	soul = npcBase.getSoul()
	spiritPointLight = nil
	collisionModel = nil
	effect = nil
	pLightRange = 1.1
	
	npcBase.init("electroSpirit",nil,0.2,0.6,0.75,2.0)
	npcBase.setDefaultState(state.electrecuted)
	--particle effect
	effect = ParticleSystem.new(ParticleEffect.SparkSpirit)
	this:addChild(effect:toSceneNode())
	effect:activate(Vec3(0,0.65,0))
	-- DEBUG START
	effect:setEmitterLine(Line3D(Vec3(0,0.65,0),Vec3(0,0.65,0)))--this should not be needed
	-- DEBUG END
	npcBase.addParticleEffect(effect,0.35)
	--pointlight
	spiritPointLight = PointLight.new(Vec3(0,0.25,0),Vec3(0.0,3.0,3.0),1.1)
	spiritPointLight:setCutOff(0.1)
	
	--collisionModel, need to be able to click on this npc
	collisionModel = Core.getModel("lightSphere.mym")
	collisionModel:setLocalPosition(Vec3(0,0.65,0))
	local meshList = collisionModel:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
	for i=1, #meshList do
		meshList[i]:setCanBeRendered(false)
	end
	--pointLight:setIsStatic(true)
	this:addChild(spiritPointLight:toSceneNode())
	this:addChild(collisionModel:toSceneNode())
	npcBase.addPointLight(spiritPointLight,0.35)
	--resistance
	npcBase.getSoul().setResistance(0.0,true,true,1.33)
	--
	return true
end
function update()
	local hpScale = 0.50+(0.50*(soul.getHp()/soul.getMaxHp()))
	effect:setScale(hpScale)
	spiritPointLight:setRange(pLightRange*hpScale)
	return npcBase.update()
end
--global function
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end