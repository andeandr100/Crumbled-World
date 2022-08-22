require("Game/Abilities/attackTargetArea.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")

--this = SceneNode()
AttackEffect = {}
function AttackEffect.new(inCamera, inTargetSelector, inComUnit)
	local self = {}
	
	local camera = inCamera
	local comUnit = inComUnit
	local targetSelector = inTargetSelector
	local attackVelocity = 8.5
	local attackTime = 2
	local time = 0
	local attackVector = Vec3()
	local attackPosition = Vec3()
	local attackActive = false
	local playerNode
	local node = SceneNode.new()
	local stoneModel = Core.getModel("Data/Models/nature/stone/stone1.mym")
	local explosion = ParticleSystem.new( ParticleEffect.Explosion )
	local pointLight = PointLight.new(Vec3(1,0.8,0.8),15.0)
	local smokeTrail = ParticleSystem.new( ParticleEffect.CometTrail )
	local fireball = ParticleSystem.new( ParticleEffect.CometFireBall )
	local smalRocks = {}
	local shieldAreaIndex = 0
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
		pointLight:setRange(10.0)
		pointLight:setCutOff(0.15)
		smokeTrail:setVisible(false)
		smokeTrail:setSpawnRate(0.0)--restore spawnRate to default value
		
		for i=1, 15 do
			local gravelModel = Core.getModel("Data/Models/nature/stone/gravel3.mym")
			gravelModel:setVisible(false)
			node:addChild(gravelModel:toSceneNode())
			smalRocks[i] = {model=gravelModel,atVec=Vec3()}
		end
		
	end
	
	function self.stop()
		state = 0
		node:setVisible(false)
		attackActive = false
		fireball:setVisible(false)
		stoneModel:setVisible(false)
		smokeTrail:setSpawnRate(0.0)
		for i=1, #smalRocks do
			smalRocks[i].model:setVisible(false)
		end
	end
	
	function self.activate(globalPosition)
		
		attackTime = 2
		state = 1
		attackVector = (Vec3(0,-1.0,0) - camera:getGlobalMatrix():getRightVec()):normalizeV()
		attackPosition = globalPosition
		local stonePosition = attackPosition - attackVector * attackTime * attackVelocity
		stoneModel:setLocalPosition(stonePosition)
		stoneModel:setVisible(true)
		attackActive = true
		shieldAreaIndex = 0
		targetSelector.setPosition(globalPosition)
		targetSelector.setRange(12)
		targetSelector.selectAllInRange()
		
		smokeTrail:setVisible(true)
		smokeTrail:activate(stonePosition)
		smokeTrail:setSpawnRate(1.0)
		fireball:activate(Vec3())
		
		pointLight:setVisible(true)
		pointLight:setLocalPosition(stonePosition)
		
		for i=1, #smalRocks do
			smalRocks[i].model:setLocalPosition(attackPosition)
			smalRocks[i].model:setVisible(false)
			smalRocks[i].atVec = Vec3(math.randomFloat(-1,1), math.randomFloat(0.8,1.5), math.randomFloat(-1,1) ):normalizeV() * 18
		end
		node:setVisible(true)
	end
	
	function self.impactedShieldIndex()
		return shieldAreaIndex
	end
	
	function self.getPosition()
		return stoneModel:getLocalPosition()
	end
	
	
	function self.update()
		if state == 1 then
			
			
			attackTime = attackTime - Core.getDeltaTime()
			
			
			local stonePosition = (attackPosition+attackVector) - attackVector * attackTime * attackVelocity
			
			--check if we have hit a shield
			shieldAreaIndex = targetSelector.getIndexOfShieldCovering(stonePosition)
			if shieldAreaIndex > 0 then
				--forcefield hitt
				local shieldPosition = targetSelector.getShieldPositionFromShieldIndex(shieldAreaIndex)
				local startPosition = stoneModel:getLocalPosition()
				local collision, collisionPosition = Collision.lineSegmentSphereIntersection( Line3D(startPosition,stonePosition), Sphere(shieldPosition,SHIELD_RANGE ))
				attackTime = -1
				if collision then
					stonePosition = collisionPosition
					
					local hitTime = tostring(1.0)
					comUnit:sendTo(shieldAreaIndex,"addForceFieldEffect",tostring(startPosition.x)..";"..startPosition.y..";"..startPosition.z..";"..stonePosition.x..";"..stonePosition.y..";"..stonePosition.z..";"..hitTime)
				end
				attackPosition = stonePosition
			end
			
			
			-- put the Fireball effect on the camera side of the rock so more of the particle is not clouded by the rock
			fireball:setLocalPosition(stonePosition + (camera:getGlobalPosition()-stonePosition):normalizeV() * 0.3 + Vec3(0,-0.2,0))
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
					smalRocks[i].model:setLocalPosition(attackPosition)
					smalRocks[i].model:setVisible(true)
				end
				self.update()
				return true
			end
		elseif state == 2 then
			local deltaTime = Core.getDeltaTime()
			time = time - deltaTime
			for i=1, #smalRocks do
				smalRocks[i].atVec = smalRocks[i].atVec + Vec3(0,-9.8,0) * deltaTime
				smalRocks[i].model:setLocalPosition( smalRocks[i].model:getLocalPosition() + smalRocks[i].atVec * deltaTime)
			end
			if time < 0 then 
				state = 0
				for i=1, #smalRocks do
					smalRocks[i].model:setVisible(false)
				end
			end
		end
		return false
		
	end
	
	init()
	
	return self
end