require("NPC/npcBase.lua")
require("Game/particleEffect.lua")
--this = SceneNode()
local npcBase
local soul
local spiritPointLight
local collisionModel
local fireEffect
local pLightRange = 1.1
local randnum = math.randomInt(100,100000)
function destroy()
	if spiritPointLight then
		spiritPointLight:destroy()
		spiritPointLight = nil
	end
	if collisionModel then
		collisionModel:destroy()
	end

	fireEffect:destroy();
	
	npcBase = nil
	collisionModel = nil
	fireEffect = nil
	soul = nil
end
function create()
	
	npcBase = NpcBase.new()
	soul = npcBase.getSoul()
	spiritPointLight = nil
	collisionModel = nil
	fireEffect = nil
	pLightRange = 1.1
	
	


	npcBase.init("fireSpirit",nil,0.2,0.6,0.75,2.0)
	npcBase.setDefaultState(state.burning)--fire crit
	--particle effect
	fireEffect = ParticleSystem.new(ParticleEffect.NPCSpirit)
	this:addChild(fireEffect:toSceneNode())
	fireEffect:activate(Vec3(0,0.65,0))
	fireEffect:setRenderLevel(15)
	npcBase.addParticleEffect(fireEffect,0.35)
	--spiritPointLight
	spiritPointLight = PointLight.new(Vec3(0,0.25,0),Vec3(3.0,1.0,0.0),pLightRange)
	spiritPointLight:setCutOff(0.1)
	
	--collisionModel, need to be able to click on this npc
	collisionModel = Core.getModel("lightSphere.mym")
	collisionModel:setLocalPosition(Vec3(0,0.65,0))
	local meshList = collisionModel:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
	for i=1, #meshList do
		meshList[i]:setCanBeRendered(false)
	end
	
	--spiritPointLight:setIsStatic(true)
	this:addChild(spiritPointLight:toSceneNode())
	this:addChild(collisionModel:toSceneNode())
	npcBase.addPointLight(spiritPointLight,0.35)
	--
	npcBase.getSoul().setResistance(1.33,true,true,0.0)
	--
	return true
end
function update()
	local hpScale = 0.50+(0.50*(soul.getHp()/soul.getMaxHp()))
	fireEffect:setScale(hpScale)
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