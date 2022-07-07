require("Game/Abilities/attackTargetArea.lua")
require("Game/particleEffect.lua")

--this = SceneNode()
AttackEffect = {}
function AttackEffect.new()
	local self = {}
	
	local camera = Core.getMainCamera()
	local attackVelocity = 7.5
	local attackTime = 2
	local time = 0
	local attackVector = Vec3()
	local attackPosition = Vec3()
	local attackActive = false
	local playerNode
	local node = SceneNode.new()
	local stoneModel = Core.getModel("Data/Models/nature/stone/stone1.mym")
	local explosion = ParticleSystem.new( ParticleEffect.Explosion )
	local pointLight = PointLight.new(Vec3(0,0,0),Vec3(3,1.5,0.0),1.0)
	local smokeTrail = ParticleSystem.new( ParticleEffect.CometTrail )
	local fireball = ParticleSystem.new( ParticleEffect.CometFireBall )
	local smalRocks = {}
	--states
	--0 not started should be invisble
	--1 the ability should be on impact approatch
	--2 explosion effect are playing
	local state = 0
	

	
	
	local function init()
		playerNode = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
		
		stoneModel:setVisible(false)
		playerNode:addChild(node)
		node:addChild(stoneModel:toSceneNode())
		node:addChild(explosion:toSceneNode())
		node:addChild(smokeTrail:toSceneNode())
		
		node:addChild(fireball:toSceneNode())
		fireball:setVisible(false)
		
		node:addChild(pointLight:toSceneNode())
		pointLight:setVisible(false)
		pointLight:setLocalPosition(Vec3())
		pointLight:clear()
		pointLight:setRange(4.0)
		pointLight:setCutOff(0.15)
		smokeTrail:setVisible(false)
		smokeTrail:setSpawnRate(0.0)--restore spawnRate to default value
		
		for i=1, 10 do
			local gravelModel = Core.getModel("Data/Models/nature/stone/stone1.mym")
			gravelModel:setVisible(false)
			node:addChild(gravelModel:toSceneNode())
			local moveVec = Vec3(math.randomFloat(-1,1), math.randomFloat(0.3,1), math.randomFloat(-1,1) ):normalizeV() * 3
			smalRocks[i] = {model=gravelModel,atVec=moveVec}
		end
		
	end
	
	function self.activate(globalPosition)
		attackTime = 2
		state = 1
		attackVector = (Vec3(0,-1.0,0) + camera:getGlobalMatrix():getRightVec()):normalizeV()
		attackPosition = globalPosition - playerNode:getGlobalPosition()
		local stonePosition = attackPosition - attackVector * attackTime * attackVelocity
		stoneModel:setLocalPosition(stonePosition)
		stoneModel:setVisible(true)
		attackActive = true
		
		smokeTrail:setVisible(true)
		smokeTrail:activate(stonePosition)
		smokeTrail:setSpawnRate(1.0)
		fireball:activate(Vec3())
		
		pointLight:setVisible(true)
		pointLight:setLocalPosition(stonePosition)
	end
	
	function self.update()
		if state == 1 then
			attackTime = attackTime - Core.getDeltaTime()
			local stonePosition = (attackPosition+attackVector) - attackVector * attackTime * attackVelocity
			fireball:setLocalPosition(stonePosition)
			stoneModel:setLocalPosition(stonePosition)
			pointLight:setLocalPosition(stonePosition)
			smokeTrail:setEmitterPos(stonePosition)
			if attackTime * attackVelocity < 1 then
				explosion:activate(attackPosition)
			end
			
			if attackTime < 0 then
				attackActive = false
				fireball:setVisible(false)
				stoneModel:setVisible(false)
				smokeTrail:setSpawnRate(0.0)
				state = 2
				time = 3
				
				for i=1, #smalRocks do
					smalRocks[i].model:setLocalPosition(Vec3())
					smalRocks[i].model:setVisible(true)
				end
				self.update()
			end
		elseif state == 2 then
			local deltaTime = Core.getDeltaTime()
			time = time - deltaTime
			for i=1, 10 do
				smalRocks[i].model:setLocalPosition(smalRocks[i].atVec * deltaTime)
			end
			if time < 0 then 
				state = 0
				for i=1, #smalRocks do
					smalRocks[i].model:setVisible(false)
				end
			end
		end
		
	end
	
	init()
	
	return self
end