require("NPC/state.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
require("Projectile/fireStorm.lua")
--this = SceneNode()

Missile = {name="Missile"}
function Missile.new()
	local self = {}

	--constants
	local MAXSPEED = 7.5			--scotty, Maximum warp!
	local SPEEDACC = 5.0			--How fast the missile will accelerate
	local HITTRANGE = 0.5			--The minimum distance that we will call hitt
	local EVENTHORIZON = 4.5		--from what distance the missile will be pulled in from
	local EVENTHORIZONMINTIME = 1.0	--minimum time before the event horizon can start pulling in the missile
	--
	local currentSpeed = 0.0		--current speed
	local dirWeight = 0.0			--how fast we will turn toward the target direction
	local travelTime = 0.0			--how long the missile has been alive
	local pSpawnRate = 1.0
	local direction = Vec3(0,1,0)
	local position = Vec3()			--current position of the missile
	local timeEndingExplosion = false
	local insideShieldIndex = 0
	local comUnit = Core.getComUnit()
	local billboard = Core.getBillboard()
	local FirestormLevel = 0
	local fireStorm
	--
	local futurePosition = Vec3()
	local targetIndex = 0
	local lastConfirmedTargetPosition = Vec3()
	--
	local damageDone
	--
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	--scenNode
	local node = SceneNode.new()
	this:findNodeByTypeTowardsRoot(NodeId.playerNode):addChild(node)
	--model
	local model = Core.getModel("missile.mym")
	node:addChild(model:toSceneNode())
	--particleEffect
	local explosion = ParticleSystem.new( ParticleEffect.Explosion )
	node:addChild(explosion:toSceneNode())
	local smokeTrail = ParticleSystem.new( ParticleEffect.ShellTrail )
	local missileTrail = ParticleSystem.new( ParticleEffect.missileTale )
	local missileTrail2 = ParticleSystem.new( ParticleEffect.missileTaleBlue )
	node:addChild(smokeTrail:toSceneNode())
	node:addChild(missileTrail:toSceneNode())
	node:addChild(missileTrail2:toSceneNode())
	--pointLight
	local pointLight = PointLight.new(Vec3(0,0,0),Vec3(3,1.5,0.0),1.0)
	pointLight:setCutOff(0.15)
	node:addChild(pointLight:toSceneNode())
	--sound
	local soundMissileSplit
	local soundMissileSplitCount = 0
	local soundExplosion = SoundNode.new("missileExplosion")
	local soundMissile = SoundNode.new("missile_engine")
	node:addChild(soundExplosion:toSceneNode())
	node:addChild(soundMissile:toSceneNode())

	-- function:	Tries to find a new target, if the current has died
	local function manageIfTargetIsNotAvailable()
		if targetIndex>1 and targetSelector.isTargetAlive(targetIndex)==false then
			targetIndex = 0
			targetSelector.setPosition(lastConfirmedTargetPosition)
			targetSelector.setRange(2.0)
			targetSelector.selectAllInRange()
			targetSelector.scoreClosest(10)
			targetIndex = targetSelector.selectTargetAfterMaxScore()
			if targetSelector.isTargetAlive(targetIndex)==false then
				targetIndex = 1
			end
		end
	end
	-- function:	Makes collision test against the worlds islandMesh and ropeBridge
	--globalPosition:	(Vec3)Global position for the test
	--return1:		(NodeId)What type of node that was hitt, or nill if no hitt
	--return2:		(Vec3)Global position of the imapct
	local function collisionAginstTheWorldGlobal(globalPosition)
		local globalMatrix = this:getParent():getGlobalMatrix()
		local line = Line3D(globalPosition + globalMatrix:getUpVec()*5.0, globalPosition - globalMatrix:getUpVec()*5.0 )
		local collisionNode = this:getPlayerNode():collisionTree(line, {NodeId.islandMesh, NodeId.ropeBridge})
		return collisionNode, (collisionNode and line.endPos or globalPosition)
	end
	-- function:Get actual position for the npc, takes into acount of bridges
	-- inPos:	(Vec3)Global position on the navmesh
	-- Return1:	(Vec3)Global position for the actual position of the NPC
	local function getGlobalPositionY(inPos)
		--Do a world collision
		local groundTestNode, groundTestYPos = collisionAginstTheWorldGlobal(inPos)
		--if we colided with a bridge
		if groundTestNode and groundTestNode:getNodeType()==NodeId.ropeBridge then
			return Vec3(inPos.x,groundTestYPos.y,inPos.z)
		end
		--collision against something else
		return inPos
	end
	-- function:To calculate the estimated position for the npc when the missile meets up
	local function futurePosEstimation()
		local length = (position-lastConfirmedTargetPosition):length()
		local estimatedTime = (length/MAXSPEED)
		futurePosition = targetSelector.isTargetAlive(targetIndex) and targetSelector.getFuturePos(targetIndex,estimatedTime) or lastConfirmedTargetPosition
	end
	-- function:To initialize the missile with all info needed, to allow reuse of the same object
	-- param:	(Table){targetIndex, missileStartPosition}
	function self.init(param)
		currentSpeed =		0.0
		pSpawnRate = 		1.0
		targetIndex =		param.target
		position =			param.startPos
		lastConfirmedTargetPosition = param.targetPos
		dirWeight =			-0.40
		insideShieldIndex =	targetSelector.getIndexOfShieldCovering(position)
		direction =			Vec3(0,1,0)
		FirestormLevel = 	billboard:getInt("FirestormLevel")
		damageDone = 		0
		travelTime =		0.0
		
		--Targeting system
		local soulMangerBillboard = Core.getBillboard("SoulManager")
		targetSelector.disableRealityCheck()
		targetSelector.setPosition(position)
		targetSelector.setRange(billboard:getDouble("range")+5.0)--5.0 just in case the target has moved out of sight (networc sync)
		targetSelector.selectAllInRange()
		--If the target is dead
		if targetSelector.isTargetAlive(targetIndex)==false then
			targetSelector.scoreClosest(10)
			targetSelector.scoreClosestToExit(20)
			targetIndex = targetSelector.selectTargetAfterMaxScore()
			if targetIndex>1 then
				--new target found
				lastConfirmedTargetPosition = getGlobalPositionY(targetSelector.getFuturePos(targetIndex,2.5))
			else
				--no new target found, attack where the npc was sighted
				targetIndex=1
			end
		end
		
		--If firestorm is unlocked make sure the assets have been loaded
		if FirestormLevel>0 and not fireStorm then
			fireStorm = FireStorm.new(node)
			soundMissileSplit = SoundNode.new("missile_split")
			soundMissileSplitCount = 0
			node:addChild(soundMissileSplit:toSceneNode())
		end
		timeEndingExplosion = false
		model:setLocalPosition(position)
		model:setVisible(true)
	
		--Particle effects
		smokeTrail:setSpawnRate(1.0)--restore spawnRate to default value
		missileTrail:setSpawnRate(1.0)--restore spawnRate to default value
		missileTrail2:setSpawnRate(1.0)
		smokeTrail:activate(position)
		missileTrail:activate(position)
		missileTrail2:activate(position)
		pointLight:setVisible(true)
		pointLight:setLocalPosition(position)
		pointLight:clear()
		pointLight:setRange(1.0)
		--Sounds
		soundMissile:setLocalPosition(position)
		soundMissile:play(0.95,false)
		--
		--
		
		--estimate future poition
		futurePosEstimation()
		--
		if billboard:getBool("isNetOwner") then
			local tab = { tName = Core.getNetworkNameOf(targetIndex), mToFire = param.missileIndex, tPos = futurePosition }
			comUnit:sendNetworkSyncSafe("NetLaunchMissile",tabToStrMinimal(tab))
		end
	end
	-- function:	Cleans up all lose edges
	function self.destroy()
		if node:getParent() then--as the parrent can already be destroyed, if end of the map
			node:getParent():removeChild(node:toSceneNode())
		end
	end
	-- function:	Activates the explosion effect
	local function doDetonationEffect()
		explosion:activate(position)
		soundExplosion:setLocalPosition(position)
		soundExplosion:play(1.5,false)
		pointLight:setVisible(true)
		pointLight:pushRangeChange(5.0,0.075)
		pointLight:pushRangeChange(0.5,0.65)
		model:setVisible(false)
		smokeTrail:setSpawnRate(0)
		missileTrail:setSpawnRate(0)
		missileTrail2:setSpawnRate(0)
		--
		soundMissile:stopFadeOut(0.15)
		timeEndingExplosion = true
	end
	-- function:	Do all the damage to a single target
	-- targetIndex:	Lua index of the CNPC to receive damage
	-- damageMul:	Default 1.0 but different if some effect is active
	local function attackSingleTarget(targetIndex,damageMul)
		local dmg = billboard:getDouble("dmg")*damageMul
		comUnit:sendTo(targetIndex,"attack",tostring(dmg))
		comUnit:sendTo(targetIndex,"physicPushIfDead",position)
		damageDone = damageDone + dmg
	end
	function self.stop()
		explosion:deactivate()
		pointLight:setVisible(false)
		model:setVisible(false)
		smokeTrail:deactivate()
		missileTrail:deactivate()
		missileTrail2:deactivate()
		targetIndex = 0
		if fireStorm then
			fireStorm.stop()
		end
	end
	-- function:	Updates the missile
	-- return1:		returns true for continues execute or false to stop
	function self.update()
		--if target has been lost. stop missile
		if targetIndex==nil or targetIndex==0 then
			pointLight:setVisible(false)
			return false
		end
		if timeEndingExplosion then
			--waiting for explosion effect to end
			if not(fireStorm and fireStorm.update()==true) and explosion:isActive()==false then
				--Core.addDebugLine(position,position+Vec3(0,1,0),2.0,Vec3(1))
				pointLight:setVisible(false)
				return false
			end
		else
			futurePosEstimation()
			local dist = (futurePosition-position):length()
			if dist<=HITTRANGE then
				--we have reached the destination. do the attack
				local detonationRange = 	billboard:getFloat("dmg_range")
				targetSelector.setPosition(position)
				targetSelector.setRange(detonationRange)
				targetSelector.selectAllInRange()
				local targetTable = targetSelector.getAllTargets()
				for index,score in pairs(targetTable) do
					attackSingleTarget(index,1.0)
				end
				--Steam stats
				comUnit:sendTo("SteamStats","MissileMaxHittCount",targetSelector.getAllTargetCount())
				comUnit:sendTo("SteamStats","MaxDamageDealt",damageDone)
				--Particle effects
				if billboard:getDouble("fireDPS")>1.0 and fireStorm then
					fireStorm.activate(billboard:getDouble("burnTime"),position,billboard:getDouble("fireDPS"),billboard:getDouble("slow"),detonationRange)
				end
				doDetonationEffect()
			else
				--We are moving toward the target
				local deltaTime = Core.getDeltaTime()
				travelTime = travelTime + deltaTime
				--Update the speed of the missile
				currentSpeed = currentSpeed + (SPEEDACC*deltaTime)
				if currentSpeed>MAXSPEED*0.9 then
					--close to max speed, start decresing the particle effects for the engine
					pSpawnRate = math.max(0.0,pSpawnRate - (3.0*deltaTime))
					missileTrail:setSpawnRate(pSpawnRate)
					missileTrail2:setSpawnRate(pSpawnRate)
					--If we reached max speed
					if currentSpeed>MAXSPEED then
						--max speed reached. disable light
						if pSpawnRate==1.0 then
							pointLight:pushRangeChange(0.5,0.1)
							pointLight:pushVisible(false)
						end
						currentSpeed = MAXSPEED
					end
				end
				
				if targetSelector.isTargetAlive(targetIndex) then
					lastConfirmedTargetPosition = targetSelector.getTargetPosition(targetIndex)
				elseif targetIndex>1 then
					manageIfTargetIsNotAvailable()
				end
				
				--Update targeting direction toward the enemy
				local targetDir = (futurePosition-position):normalizeV()
				if travelTime>EVENTHORIZONMINTIME and dist<EVENTHORIZON then
					dirWeight = dirWeight + (Core.getDeltaTime()* math.pow((EVENTHORIZON+1.0)-dist, 2.5))-- (+1.0) because 0.05^2.5==0.88
				else
					dirWeight = dirWeight + Core.getDeltaTime()
				end
				--Update position
				direction = direction:interPolateV(targetDir, math.clamp(deltaTime*dirWeight,0.0,1.0))
				position = position + (direction*currentSpeed*deltaTime)
				--Update the position of the particle effects
				smokeTrail:setEmitterPos(position)
				missileTrail:setEmitterPos(position)
				missileTrail2:setEmitterPos(position)
				pointLight:setLocalPosition(position)
				--Update sound position
				soundMissile:setLocalPosition(position)
				--Uppdate the model
				matrix = Matrix()
				matrix:createMatrixUp(direction:normalizeV(),Vec3(0.0, 0.0, 1.0))
				matrix:setPosition(position)
				model:setLocalMatrix(matrix)
				
				--If the missile has hitt a forcefield
				if targetSelector.getIndexOfShieldCovering(position)~=insideShieldIndex then
					--we have passed threw a shield, detonate
					doDetonationEffect()
					
					local shieldIndex = insideShieldIndex>0 and insideShieldIndex or targetSelector.getIndexOfShieldCovering(position)
					attackSingleTarget(shieldIndex,billboard:getDouble("shieldDamageMul"))
					
					targetSelector.setPosition(position)
					targetSelector.setRange(billboard:getDouble("dmg_range"))
					--attack only targets inside or outside the shield, depending on which side the missile detonated
					targetSelector.selectAllInRange()
					local target = targetSelector.getTarget()
					local targetInsideShield = insideShieldIndex>0
					local targets = targetSelector.getAllTargets()
					comUnit:sendTo("SteamStats","MissileMaxHittCount",targetSelector.getAllTargetCount())
					for index,score in pairs(targets) do
						attackSingleTarget(index,1.0)
					end
					comUnit:sendTo("SteamStats","MaxDamageDealt",damageDone)
					--hitt effect
					local oldPosition = position - direction
					local futurePosition = position + direction
					local hitTime = "1.5"
					comUnit:sendTo(shieldIndex,"addForceFieldEffect",tostring(oldPosition.x)..";"..oldPosition.y..";"..oldPosition.z..";"..futurePosition.x..";"..futurePosition.y..";"..futurePosition.z..";"..hitTime)
				end
			end
		end
		pointLight:update()
		return true
	end
	return self
end