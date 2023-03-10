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
	pointLight:destroy()
	collisionModel:destroy()
	effect:destroy();
	
	npcBase = nil
	pointLight = nil
	collisionModel = nil
	effect = nil
	soul = nil
end
function create()
	
	npcBase = NpcBase.new()
	soul = npcBase.getSoul()
	pointLight = nil
	collisionModel = nil
	effect = nil
	pLightRange = 1.1


	npcBase.init("fireSpirit",nil,0.2,0.6,0.75,2.0)
	npcBase.setDefaultState(state.burning)--fire crit
	--particle effect
	effect = ParticleSystem.new(ParticleEffect.NPCSpirit)
	this:addChild(effect:toSceneNode())
	effect:activate(Vec3(0,0.65,0))
	npcBase.addParticleEffect(effect,0.35)
	--pointlight
	pointLight = PointLight.new(Vec3(0,0.25,0),Vec3(3.0,1.0,0.0),pLightRange)
	pointLight:setCutOff(0.1)
	
	--collisionModel, need to be able to click on this npc
	collisionModel = Core.getModel("lightSphere.mym")
	collisionModel:setLocalPosition(Vec3(0,0.65,0))
	local meshList = collisionModel:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
	for i=1, #meshList do
		meshList[i]:setCanBeRendered(false)
	end
	
	--pointLight:setIsStatic(true)
	this:addChild(pointLight:toSceneNode())
	this:addChild(collisionModel:toSceneNode())
	npcBase.addPointLight(pointLight,0.35)
	--
	npcBase.getSoul().setResistance(1.33,true,true,0.0)
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