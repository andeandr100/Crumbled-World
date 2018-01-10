require("NPC/state.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
--this = SceneNode()

FireBalls = {}
function FireBalls.new(pNode,pCount)
	local self = {}
	local node = pNode
	local groupNode = SceneNode.new()
	local fireballs = {}
	local rotate = 0.0
	local totalLength = 0
	local isActivate=false
	--effects
	local startExlosion = ParticleSystem.new( ParticleEffect.ExplosionMediumBlue )
	local pLight = PointLight.new(Vec3(),Vec3(0,2.0,2.0),3.0)
	--
	function self.setBallCount(count)
		for i=#fireballs+1, count do
			fireballs[#fireballs+1] = ParticleSystem.new( ParticleEffect.FireBall )
			groupNode:addChild(fireballs[#fireballs]:toSceneNode())
		end
	end
	function self.update(matrix,length)
		local per = (length/totalLength)-0.5
		local angleDiff = (math.pi*2)/#fireballs 
		local radius = 0.5
		rotate = rotate+(10*Core.getDeltaTime())
		radius = 0.6-(per*per*4*0.4)--0.4 is the range change so [0.2, 0.6] will the rangebe inside
		for i=1, #fireballs do
			local ang = (i*angleDiff)+rotate
			local pos =  Vec3(radius*math.cos(ang),0.0,radius*math.sin(ang))
			fireballs[i]:setLocalPosition(pos)
		end
		if per<-0.25 then
			pLight:setRange( math.max(0.0,(per+0.5)*12) )
		end
		groupNode:setLocalMatrix(matrix)
	end
	function self.isActivate()
		return isActivate
	end
	function self.activate(position,pLength)
		totalLength = pLength
		isActivate = true
		rotate = 0.0
		startExlosion:setScale(0.5)
		startExlosion:activate(position)
		for i=1, #fireballs do
			fireballs[i]:activate(Vec3())
			fireballs[i]:ageParticles(2.0)
		end
		pLight:setVisible(true)
		pLight:setRange(3.0)
		local mat=Matrix()
		mat:createMatrix(Vec3(1,0,0),Vec3(0,1,0))
		mat:setPosition(position)
		self.update(mat,totalLength)
	end
	function self.deactivate()
		isActivate = false
		for i=1, #fireballs do
			fireballs[i]:setVisible(false)
		end
		pLight:setVisible(false)
	end
	local function init()
		node:addChild(groupNode:toSceneNode())
		node:addChild(startExlosion:toSceneNode())
		groupNode:addChild(pLight:toSceneNode())
		self.setBallCount(pCount:toSceneNode())
	end
	init()
	return self
end
FireStorm = {}
function FireStorm.new(pNode)
	local self = {}
	local node = pNode
	local fireStorm1 = ParticleSystem.new( ParticleEffect.fireStormFlame )
	local fireStorm2 = ParticleSystem.new( ParticleEffect.fireStormSparks )
	local fireStorm3 = ParticleSystem.new( ParticleEffect.fireStormFire )
	local colorVariations = Vec3(0.35,0.35,0.05)
	local pLight = PointLight.new(Vec3(),Vec3(1.75,0.6,0.1),3.5)
	local comUnit = Core.getComUnit()
	local billboard = Core.getBillboard()
	local ATTACKUPDATETIMER = 0.25
	--
	local attackTimer = 0.0
	local fireStormTimer = 0.0
	local duration = 0.0
	local damage = 0.0
	local range = 0.0
	local slow = 0.0
	local position = Vec3()
	--
	local soundFireStorm = SoundNode.new("firestorm")
	function self.activate(pDuration,pPosition,pDamage,pSlow,pRange)
		fireStormTimer = pDuration
		duration = pDuration
		damage = pDamage
		range = pRange
		slow = pSlow
		position = pPosition
		attackTimer = 0.0
		--
		local line = Line3D(position+Vec3(0,2,0),position-Vec3(0,2,0))
		local collisionNode = this:getPlayerNode():collisionTree(line, {NodeId.islandMesh, NodeId.ropeBridge})
		if collisionNode then
			position = line.endPos+Vec3(0,0.1,0)
		end
		--
		fireStorm1:setSpawnRadius(range-0.4)
		fireStorm1:setSpawnRate(1.0)
		fireStorm1:activate(position)
		fireStorm2:setSpawnRadius(range-0.4)
		fireStorm2:setSpawnRate(1.0)
		fireStorm2:activate(position)
		fireStorm3:setSpawnRadius(range-0.4)
		fireStorm3:setSpawnRate(1.0)
		fireStorm3:activate(position)
		pLight:setLocalPosition(position)
		pLight:setRange(range+1.0)
		pLight:setAmplitude(2.5)
		pLight:setVisible(true)
		--
		soundFireStorm:setLocalPosition(position)
		soundFireStorm:playFadeIn(1,false,0.25)
		--
		comUnit:broadCast(position,range,"attackFireDPS",{DPS=damage,time=ATTACKUPDATETIMER,type="fire"})
		comUnit:broadCast(position,range,"slow",{per=slow,time=ATTACKUPDATETIMER,type="mineCart"})
	end
	function self.isActive()
		return (fireStorm1:isActive() or fireStorm2:isActive())
	end
	function self.update()
		if self.isActive() then
			local deltaTime = Core.getDeltaTime()
			fireStormTimer = fireStormTimer-deltaTime
			attackTimer = attackTimer-deltaTime
			if fireStormTimer<0.25 and fireStormTimer+Core.getDeltaTime()>=0.25 then
				fireStorm1:deactivate(0.25)
				fireStorm2:deactivate(0.25)
				fireStorm3:deactivate(0.25)
				pLight:pushRangeChange(0.0,0.25)
				soundFireStorm:stopFadeOut(0.25)
			end
			if attackTimer<0.0 then
				attackTimer = attackTimer+ATTACKUPDATETIMER
				comUnit:broadCast(position,range,"attackFireDPS",{DPS=damage,time=0.1,type="fire"})
				comUnit:broadCast(position,range,"slow",{per=slow,time=0.1,type="mineCart"})
			end
			return true
		else
			pLight:setVisible(false)
		end
		return false
	end
	local function init()
		pLight:setVisible(false)
		pLight:addFlicker(Vec3(0.2,0.15,0.05)*0.75,0.05,0.1)
		pLight:addSinCurve(Vec3(0.2,0.15,0.05),1.0)
		node:addChild(fireStorm1:toSceneNode())
		node:addChild(fireStorm2:toSceneNode())
		node:addChild(fireStorm3:toSceneNode())
		node:addChild(pLight:toSceneNode())
		node:addChild(soundFireStorm:toSceneNode())
	end
	init()
	return self
end
Missile = {name="Missile"}
function Missile.new()
	local self = {}

	local speed = 5.0
	local leavetimer = 0.0
	local currentSpeed = 0.0
	local speedAcc = 0.0
	local pSpawnRate = 1.0
	local timeLostToAcceleration = 0.0
	local color = Vec3()
	local direction = Vec3(0,1,0)
	local position = Vec3()
	local timeEnding = false
	local insideShieldIndex = 0
	local pathList = PathListMover(0.0)
	local comUnit = Core.getComUnit()
	local billboard = Core.getBillboard()
	local FirestormLevel = 0
	local fireBall
	local fireStorm
	local currentMissilePosition = Vec3()
	--
	local futurePosition = Vec3()
	local startPosition = Vec3()
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
	--
	local function estimateTimeAndPlotPath(futurePos,estimatedLength,amplitude)
		local tAtVec = (futurePos-position):normalizeV()
		local len = (futurePos-position):length()
		local mul = 4-(2*(len/5))--5m=2, 10m=0, 15m=-2
		local s1 = position
		local sd = position+(Vec3(-0.040*tAtVec.x,2.5*amplitude,-0.040*tAtVec.z))
		local e1 = futurePos+Vec3(0,0.30,0)
		local ed = futurePos+Vec3(tAtVec.x*mul,0.30,tAtVec.z*mul)-(Vec3(0.0,-2.0,0.0)*amplitude)
		local detailLevel = math.max(6,estimatedLength*10.0)
		local moveList = math.bezierCurve3D(s1, sd, ed, e1,detailLevel)
		pathList:setList( moveList )
		return (pathList:getLength()/speed) + timeLostToAcceleration
	end
	local function collisionAginstTheWorldGlobal(globalPosition)
		local globalMatrix = this:getParent():getGlobalMatrix()
		local line = Line3D(globalPosition + globalMatrix:getUpVec()*5.0, globalPosition - globalMatrix:getUpVec()*5.0 )
		local collisionNode = this:getPlayerNode():collisionTree(line, {NodeId.islandMesh, NodeId.ropeBridge})
		return collisionNode, (collisionNode and line.endPos or globalPosition)
	end
	local function getGlobalPositionY(inPos)
		local groundTestNode, groundTestYPos = collisionAginstTheWorldGlobal(inPos)
		if groundTestNode and groundTestNode:getNodeType()==NodeId.ropeBridge then
			return Vec3(inPos.x,groundTestYPos.y,inPos.z)
		end
		return inPos
	end
	local function plotPathToTargetCometStyle(length)
		local tryCount = 4
		repeat
			local estimatedTime = (length/speed) + timeLostToAcceleration
			futurePosition = targetSelector.isTargetAlive(targetIndex) and targetSelector.getFuturePos(targetIndex,estimatedTime) or futurePosition
			local calculatedFutherPosition = getGlobalPositionY(futurePosition)
			local estimatedLength = (estimatedTime-timeLostToAcceleration)*speed
			local preEstimation = estimatedTime
			estimatedTime = estimateTimeAndPlotPath(calculatedFutherPosition,estimatedLength,2.5)
			length = (estimatedTime-timeLostToAcceleration)*speed--just incase next line fails
			tryCount = tryCount - 1--if we faile to find an accaptable path we will settle with what we have
		until math.abs(estimatedTime-preEstimation)<0.10 or tryCount<=0
		--print("estimatedTime=="..estimatedTime.."\n")
--		Core.addDebugLine(calculatedFutherPosition,calculatedFutherPosition+Vec3(0,3,0),4.0,Vec3(1,1,1))
--		Core.addDebugLine(ed,ed+Vec3(0,3,0),4.0,Vec3(1,0,0))
	end
	function self.init(param)
		speed =		 		billboard:getFloat("missileSpeed")
		currentSpeed =		0.0
		pSpawnRate = 		1.0
		targetIndex =		param[1]
		speedAcc =	 		billboard:getFloat("missileSpeedAcc")
		position =			param[2]
		startPosition =		position
		insideShieldIndex =	targetSelector.getIndexOfShieldCovering(position)
		direction =			Vec3(0,1,0)
		timeLostToAcceleration = (speedAcc*(speed/speedAcc)*(speed/speedAcc))/2/speed --distance=(a*t^2)/2 -- distance/speed==timeLostToAcceleration
		FirestormLevel = billboard:getInt("FirestormLevel")
		currentMissilePosition = position
		damageDone = 		0
		
		local soulMangerBillboard = Core.getBillboard("SoulManager")
		targetSelector.disableRealityCheck()
		targetSelector.setPosition(position)
		targetSelector.setRange(billboard:getDouble("range")+5.0)--5.0 just in case the target has moved out of sight (networc sync)
		targetSelector.selectAllInRange()
		
		if targetSelector.isTargetAlive(targetIndex)==false then
			targetSelector.scoreClosest(10)
			targetSelector.scoreClosestToExit(20)
			targetIndex = targetSelector.selectTargetAfterMaxScore()
		end
	
		color = Vec3(math.randomFloat(),math.randomFloat(),math.randomFloat())
		
		if FirestormLevel>0 and not fireStorm then
			fireStorm = FireStorm.new(node)
			soundMissileSplit = SoundNode.new("missile_split")
			soundMissileSplitCount = 0
			node:addChild(soundMissileSplit:toSceneNode())
		end
		timeEnding = false
		model:setVisible(true)

		pathList:setSpeed(currentSpeed)
	
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
		--
--		soundMissileLaunchTimer = 1.5 --(playLength==1.75, will fade out sound)
		soundMissile:setLocalPosition(position)
--		soundMissileLaunch:play(2.0,false)
		soundMissile:play(0.95,false)
		--

		--
		if targetIndex>0 and targetSelector.isTargetAlive(targetIndex) then
			lastConfirmedTargetPosition = getGlobalPositionY(targetSelector.getFuturePos(targetIndex,2.5+timeLostToAcceleration))
		else
			targetIndex = 1
			if param[2] then
				lastConfirmedTargetPosition = param[2]
				futurePosition = param[2]
			else
				lastConfirmedTargetPosition = this:getGlobalPosition()+Vec3(1.5,0,0)
				futurePosition = this:getGlobalPosition()+Vec3(1.5,0,0)
			end
		end
		--
		
		plotPathToTargetCometStyle( (position-lastConfirmedTargetPosition):length()+6.0 )
		if billboard:getBool("isNetOwner") then
			local tab = { tName = Core.getNetworkNameOf(targetIndex), mToFire = param.missileIndex, tPos = futurePosition }
			comUnit:sendNetworkSyncSafe("NetLaunchMissile",tabToStrMinimal(tab))
		end
	end
	function self.destroy()
		if node:getParent() then--as the parrent can already be destroyed, if end of the map
			node:getParent():removeChild(node:toSceneNode())
		end
	end
	local function doDetonationEffect()
		explosion:activate(position)
		soundExplosion:setLocalPosition(position)
		soundExplosion:play(1.5,false)
		pointLight:pushRangeChange(5.0,0.075)
		pointLight:pushRangeChange(0.5,0.65)
		model:setVisible(false)
		if fireBall then
			fireBall.deactivate()
		end
		smokeTrail:setSpawnRate(0)
		missileTrail:setSpawnRate(0)
		missileTrail2:setSpawnRate(0)
		--
		soundMissile:stopFadeOut(0.15)
--		soundMissileLaunch:stop()		--just in case it is running
--		soundMissileLaunchTimer = -1.0	--disable timer so it will not launch missile trail
		timeEnding = true
	end
	local function attackSingleTarget(targetIndex,damageMul)
		local dmg = billboard:getDouble("dmg")*damageMul
		comUnit:sendTo(targetIndex,"attack",tostring(dmg))
		comUnit:sendTo(targetIndex,"physicPushIfDead",position)
		damageDone = damageDone + dmg
	end
	local function toVec2(pVec3)
		return Vec2(pVec3.x,pVec3.z)
	end
	function self.update()
		--Core.addDebugLine(position,position+Vec3(0,1,0),0.05,Vec3(1,0,0))
		--if target has been lost. stop missile
		if targetIndex==nil or targetIndex==0 then
			pointLight:setVisible(false)
			return false
		end
		if timeEnding then
			--waiting for effect to end
			if not(fireStorm and fireStorm.update()==true) and explosion:isActive()==false then
				--Core.addDebugLine(position,position+Vec3(0,1,0),2.0,Vec3(1))
				pointLight:setVisible(false)
				return false
			end
		else			
			if pathList:willReachEnd() then
				--we have reached the destination. do the attack
				local detonationRange = 	billboard:getFloat("dmg_range")
--				comUnit:broadCast(position,detonationRange,"attack",tostring(billboard:getDouble("dmg")))
--				comUnit:broadCast(position,detonationRange,"physicPushIfDead",position)
				targetSelector.setPosition(position)
				targetSelector.setRange(detonationRange)
				targetSelector.selectAllInRange()
				local targets = targetSelector.getAllTargets()
				comUnit:sendTo("SteamStats","MissileMaxHittCount",targetSelector.getAllTargetCount())
				for index,score in pairs(targets) do
					attackSingleTarget(index,1.0)
				end
				comUnit:sendTo("SteamStats","MaxDamageDealt",damageDone)
				--
				--
				if billboard:getDouble("fireDPS")>1.0 and fireStorm then
					fireStorm.activate(billboard:getDouble("burnTime"),position,billboard:getDouble("fireDPS"),billboard:getDouble("slow"),detonationRange)
				end
				doDetonationEffect()
			else
				local deltaTime = Core.getDeltaTime()
				currentSpeed = currentSpeed + (speedAcc*deltaTime)
				if currentSpeed>speed*0.9 then
					--close to max speed, start decresing the particle effects for the engine
					pSpawnRate = math.max(0.0,pSpawnRate - (3.0*deltaTime))
					missileTrail:setSpawnRate(pSpawnRate)
					missileTrail2:setSpawnRate(pSpawnRate)
					--
					--
					if currentSpeed>speed then
						--max speed reached. disable light
						if pSpawnRate==1.0 then
							pointLight:pushRangeChange(0.5,0.2)
						end
						currentSpeed = speed
					end
				end
				pathList:setSpeed(currentSpeed)
				--moveList = pathList:getList()
				
				if targetSelector.isTargetAlive(targetIndex) then
					lastConfirmedTargetPosition = targetSelector.getTargetPosition(targetIndex)
				elseif targetIndex>1 then
					manageIfTargetIsNotAvailable()
				end
				
				local weight = 3.5*deltaTime
				direction = ((direction*(1.0-weight)) + (pathList:getVelocity():normalizeV()*weight)):normalizeV()
				direction = pathList:getVelocity():normalizeV()
				position = pathList:getNextPos()
				--
				-- Calculate false positon
				local startPositionVec2 = toVec2(startPosition)
				local futurePositionVec2 = toVec2(futurePosition)
				local targetPositionVec2 = targetSelector.isTargetAlive(targetIndex) and toVec2(targetSelector.getTargetPosition(targetIndex)) or futurePositionVec2
				--local closeToTargetPer = pathList:getTraversedLength()/(pathList:getTraversedLength()+pathList:getLength())
				--local calculatedLength = (futurePositionVec2-startPositionVec2):length()
				--local actualLength = (targetPositionVec2-startPositionVec2):length()
				--local traveledLength = (toVec2(position)-startPositionVec2):length()
				--local atVecNorm = (targetPositionVec2-startPositionVec2):normalizeV()
				local traveledPer = (toVec2(position)-startPositionVec2):length()/(futurePositionVec2-startPositionVec2):length()--traveledLength/calculatedLength
				local calculatedXYPos = targetPositionVec2
				local d0 = {}
				if (targetPositionVec2-startPositionVec2):length()>0.1 then
					calculatedXYPos = startPositionVec2+((targetPositionVec2-startPositionVec2):normalizeV()*(targetPositionVec2-startPositionVec2):length()*traveledPer)--startPositionVec2+(atVecNorm*actualLength*traveledPer)
					position = Vec3(calculatedXYPos.x,position.y,calculatedXYPos.y)
					local line = (position-currentMissilePosition)
					local mul = math.clamp(line:length()/0.25,20,0.5)
					d0.line = line
					d0.mul = mul
					d0.oldMissilePosition = currentMissilePosition
					d0.direction = direction
					d0.currentSpeed = currentSpeed
					currentMissilePosition = currentMissilePosition + (direction*currentSpeed*Core.getDeltaTime())
					currentMissilePosition = currentMissilePosition + line*mul*Core.getDeltaTime()
				else
					currentMissilePosition = Vec3(calculatedXYPos.x,position.y,calculatedXYPos.y)
				end
				--
--				Core.addDebugSphere(Sphere(position,0.35),0.01,Vec3(1,0,0))
--				Core.addDebugSphere(Sphere(currentMissilePosition,0.35),0.01,Vec3(0,1,0))
--				Core.addDebugLine(currentMissilePosition,currentMissilePosition+direction,0.01,Vec3(1,1,0))
				--
				d0.position =  position
				d0.currentMissilePosition = currentMissilePosition
				
				smokeTrail:setEmitterPos(currentMissilePosition)
				missileTrail:setEmitterPos(currentMissilePosition)
				missileTrail2:setEmitterPos(currentMissilePosition)
				pointLight:setLocalPosition(currentMissilePosition)
				--
				--soundMissileLaunch:setLocalPosition(position)
				soundMissile:setLocalPosition(currentMissilePosition)
			
				matrix = Matrix()
				matrix:createMatrixUp(direction,Vec3(0.0, 0.0, 1.0))
				matrix:setPosition(currentMissilePosition)
				model:setLocalMatrix(matrix)
				
--				if fireBall then
--					fireBall.update(matrix,pathList:getLength())
--				end
				
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
					local oldPosition = position - pathList:getVelocity():normalizeV()
					local futurePosition = position + pathList:getVelocity():normalizeV()
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