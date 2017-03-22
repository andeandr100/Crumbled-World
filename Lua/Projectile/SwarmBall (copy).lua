--this = SceneNode()
--ownerIndex = Number()
SwarmBall = {name="SwarmBall"}
function SwarmBall.new()
	local self = {}
	
	local calculatedFutherPosition = Vec3()
	local timeLeft = 0.0
	local speed = 6.0
	
	local node = SceneNode()
	this:findNodeByTypeTowardsRoot(NodeId.playerNode):addChild(node)

	local explosion = ParticleSystem( "ExplosionFireBall" )
	local effect2 = ParticleSystem( "FireBall" )
	node:addChild(explosion:toSceneNode())
	node:addChild(effect2:toSceneNode())
	effect2:setVisible(false)
	
	local velocity = Vec3()
	local position = Vec3()
	local targetIndex = 0
	local detonationRange = 0.0
	local burnTime = 0.0
	local fireDPS = 0.0
	local damage = 0.0
	local smartTargeting = 0.0
	local pathList = 0
	local shieldAreaIndex = 0

	local estimatedTime = 0.0

	--stages of life in projectile
	local LIFE_STAGE_TARGET_MIDPOINT = 1
	local LIFE_STAGE_TARGET_ALIVE = 2
	local LIFE_STAGE_TARGET_DEAD = 3
	local LIFE_STAGE_PREPPING_TO_DIE = 4
	local lifeStage = 0
	
	local pointLight = PointLight(Vec3(0,0,0),Vec3(4,2,0),1.5)
	pointLight:setCutOff(0.1)
	pointLight:setVisible(false)
	node:addChild(pointLight:toSceneNode())

	--
	--	private functions
	--

	local function basicLengthEstimation(position,soul)
		local targetPos = soul.position
		--do a ruff estimation, based on travel time to position plus 1s for good messure
		local length = (targetPos-position):length()
		local estimatedTime2 = (length/speed)+1.0
		--another ruff estimation based on position + traveling time before impact
		targetPos = targetPos + (soul.velocity*estimatedTime2)--just a prediction of futer pos
		return (targetPos-position):length()--+8.0 is estimated path length in space, because there is not straight lines
	end
	local function estimateTimeAndPlotPath(futurePos,pVelocity,npcMovment,estimatedLength,defaultAmplitude)
		--local amplitude = estimatedLength*0.2
		--y=0.2+(x*0.19)^2.5
		local amplitude = (defaultAmplitude>0.1) and defaultAmplitude or 0.2+math.pow(estimatedLength*0.1,3.0)
		--print("estimateTimeAndPlotPath(estimatedLength="..estimatedLength..", amplitude="..amplitude..")\n")
		--npcMovment = Vec3(npcMovment.x,0.0,npcMovment.z)
		local s1 = position
		local sd = position+(pVelocity*amplitude)
		local e1 = futurePos+Vec3(0,0.15,0)
		local ed = futurePos+Vec3(0,0.15,0)-(npcMovment*amplitude)
		local detailLevel = (estimatedLength<2) and 6 or estimatedLength*2.0
		moveList = math.bezierCurve3D(s1, sd, ed, e1, detailLevel)
		pathList:setList( moveList )
		return pathList:getLength()/speed
	end
	local function PlotPathToMidPoint(length,position,soul)
		calculatedFutherPosition = soulManager:getFuturePos(targetIndex,length/speed)
		lifeStage = LIFE_STAGE_TARGET_MIDPOINT
		local midPoint = (position+calculatedFutherPosition)*0.5
		midPoint.y = position.y + 2.0
		local enemyAt = (calculatedFutherPosition-position)
		enemyAt = Vec3(enemyAt.x,0.0,enemyAt.z):normalizeV()
		return estimateTimeAndPlotPath(midPoint,velocity,enemyAt,length,2.0)
	end
	local function PlotPathToAbove(length,soul)
		estimatedTime = length/speed
		lifeStage = LIFE_STAGE_TARGET_MIDPOINT
		calculatedFutherPosition = soulManager:getFuturePos(targetIndex,estimatedTime)
		estimatedTime = estimateTimeAndPlotPath(calculatedFutherPosition+Vec3(0.0,3.0,0.0),velocity*2.0,-soul.velocity:normalizeV()*2.0,length,2.0)
	end
	local function plotPathToTarget(length,soul)
		repeat
			estimatedTime = length/speed
			lifeStage = LIFE_STAGE_TARGET_ALIVE
			--the final estimation on the position
			calculatedFutherPosition = soulManager:getFuturePos(targetIndex,estimatedTime)
			--the final estimated time to travel
			local estimatedLength = estimatedTime*speed
			local preEstimation = estimatedTime
			--print("detailLevel="..estimatedLength.."\n")
			estimatedTime = estimateTimeAndPlotPath(calculatedFutherPosition,velocity,soul.velocity:normalizeV()*2.0,estimatedLength,3.0)
			--print("FirstEstimation(pre="..preEstimation..", calculated="..estimatedTime..")\n")
			length = estimatedTime*speed--just incase next line fails
		until math.abs(estimatedTime-preEstimation)<0.10
	end
	local function endLife()
		pointLight:pushRangeChange(0.1,0.8)
		lifeStage = LIFE_STAGE_PREPPING_TO_DIE
		effect2:setVisible(false)
		timeLeft = 1.0
		explosion:activate(position,velocity)
		--this:attackTargetPos(position,DRONE_DETONATION_RANGE)
	end
	local function manageIfTargetIsNotAvailable()
		if lifeStage~=LIFE_STAGE_TARGET_DEAD and soulManager:isAlive(targetIndex)==false then
			targetIndex = 0
--			soulManager:updateSoul(position,Vec3(),1.0)
--			targetingSystem:setDefault(position)
--			targetingSystem:selectAllInRange()
--			targetingSystem:scoreClosest(10)
--			if smartTargeting>0.5 then
--				targetingSystem:scoreName("fireSpirit",-100)
--				targetingSystem:scoreState(2,-10)--[burning==2]
--			end
--			targetIndex = targetingSystem:getTargetMaxScore(-75)
			if targetIndex==0 then
				endLife()
			end
		end
	end

	--
	--	public functions
	--	

	function self.init(table)
		timer:start("init")
		targetIndex =		billboard:getInt("targetIndex")
		speed =		 		6.0--billboard:getFloat("fireballSpeed")
		velocity =			billboard:getVec3("escapeVector"):normalizeV()
		position =			billboard:getVec3("bulletStartPos")
		timeLeft =			billboard:getFloat("lifeTime") + (1.0-(math.randomFloat()*2.0))
		detonationRange = 	billboard:getFloat("detonationRange")
		burnTime =			billboard:getFloat("burnTime")
		fireDPS =			billboard:getFloat("fireDPS")
		damage =			billboard:getFloat("damage")
		smartTargeting =	billboard:getFloat("smartTargeting")
		lifeStage = 0
		shieldAreaIndex = soulManager:indexOfShieldCovering(position)
	
		pathList = pathListMover(speed)
	
		--targetingSystem:deselect()
		
		local length = basicLengthEstimation(position,soulManager:getSoul(targetIndex))
		--print("Length="..length.."\n")
		--if length>2.0 then
		estimatedTime = PlotPathToMidPoint(length+3.0,position,soulManager:getSoul(targetIndex))
		--else
		--	plotPathToTarget(length+8.0)
		--end
		
		pointLight:setLocalPosition(position)
		pointLight:clear()
		pointLight:setVisible(true)
		pointLight:setRange(0.2)
		pointLight:pushRangeChange(1.5,0.5)
	
		effect2:activate(Vec3())
		effect2:setVisible(true)
	
		--comUnit:sendTo(targetIndex,"getFuturePos",firstTime)
		timer:stop()
	end
	function self.destroy()
		node:getParent():removeChild(node)
	end
	function self.update()
		timer:start("updateSwarmBall")

		if lifeStage==LIFE_STAGE_PREPPING_TO_DIE then
			--drone has exploded
			--waiting for particle effect to die
			timeLeft = timeLeft - Core.getDeltaTime()
			if timeLeft<0.0 and explosion:isActive()==false then
				pointLight:setVisible(false)
				timer:stop()
				return false
			end
		else
			timeLeft = timeLeft - Core.getDeltaTime()
			if timeLeft<0.0 then--if the life time of the drone has been depleted
				--detonate drone
				endLife()
				timer:stop()
				return true
			end		
	
			manageIfTargetIsNotAvailable()
			if pathList:willReachEnd() then
				if targetIndex>0 then
					if lifeStage==LIFE_STAGE_TARGET_MIDPOINT then
						local length = basicLengthEstimation(position,soulManager:getSoul(targetIndex))
						plotPathToTarget(length+4.0,soulManager:getSoul(targetIndex))
					else
						--comUnit:sendTo(ownerIndex, "swarmBallHitt", "hitt")
						comUnit:sendTo(targetIndex,"attackFire",tostring(damage))
						comUnit:sendTo(targetIndex,"attackFireDPS",{DPS=fireDPS,time=burnTime,type="fire"})
						--circumference of half a circle
						local length = 3.14*3.0*0.5
						--length is half circumference + the distance the soul will travel during that time approxmatly
						length = length + (length/speed*soulManager:getVelocity(targetIndex):length()) + 1.0 -- 1.0 is just for good messure
						PlotPathToAbove(length,soulManager:getSoul(targetIndex))
					end
				else
					comUnit:broadCast(position,detonationRange,"attack",tostring(damage))
					endLife()
				end
			elseif shieldAreaIndex~=soulManager:indexOfShieldCovering(position) then
				--forcefield hitt
				targetIndex = shieldAreaIndex>0 and shieldAreaIndex or soulManager:indexOfShieldCovering(currentPos)
				comUnit:sendTo(targetIndex,"attack",tostring(damage+(fireDPS*0.5)))--can't do fire damage to shield
				endLife()
			else
				pointLight:setLocalPosition(position)
				velocity = pathList:getVelocity():normalizeV()
				position = pathList:getNextPos()
				moveList = pathList:getList()
				
				--Debug information
				--local deltaTime = Core.getDeltaTime()
				--Core.addDebugLine(s1,sd,deltaTime,Vec3(0.0,1.0,0.0))
				--Core.addDebugLine(e1,ed,deltaTime,Vec3(0.0,0.0,1.0))
				--Core.addDebugSphere(Sphere(e1,0.2),deltaTime,Vec3(0.0,0.0,1.0))
				--for i = 1, #moveList, 1 do
				--	Core.addDebugSphere(Sphere(moveList[i],0.05),deltaTime,Vec3(1.0,0.0,0.0))
				--end
				
				velocity = velocity:normalizeV()
				effect2:setLocalPosition(position)
			end
		end
		pointLight:update()
		timer:stop()
		return true
	end
	
	return self
end