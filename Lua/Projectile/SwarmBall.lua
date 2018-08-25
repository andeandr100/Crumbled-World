require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
--this = SceneNode()
SwarmBall = {name="SwarmBall"}
function SwarmBall.new(pTargetSelector)
	local self = {}
	
	local targetSelector = pTargetSelector
	local calculatedFutherPosition = Vec3()
	local timeLeft = 0.0
	local speed = 6.0
	local comUnit = Core.getComUnit()
	local billboard = Core.getBillboard()
	
	local node = SceneNode.new()
	this:findNodeByTypeTowardsRoot(NodeId.playerNode):addChild(node)

	local hittExplosion = ParticleSystem.new( ParticleEffect.ExplosionFireBallOnHitt )
	local explosion = ParticleSystem.new( ParticleEffect.ExplosionFireBall )
	local effect2 = ParticleSystem.new( ParticleEffect.FireBall )
	node:addChild(hittExplosion:toSceneNode())
	node:addChild(explosion:toSceneNode())
	node:addChild(effect2:toSceneNode())
	effect2:setVisible(false)
	
	local velocity = Vec3()
	local position = Vec3()
	local towerPosition = Vec3()
	local range = 1.0
	local targetIndex = 0
	local detonationRange = 0.0
	local burnTime = 0.0
	local fireDPS = 0.0
	local damage = 0.0
	local smartTargeting = 0.0
	local pathList = PathListMover(0.0)
	local shieldAreaIndex = 0
	
	local thisProjectileNetName = ""
	local syncTable = {}

	local estimatedTime = 0.0

	--stages of life in projectile
	local LIFE_STAGE_TARGET_MIDPOINT = 1
	local LIFE_STAGE_TARGET_ALIVE = 2
	local LIFE_STAGE_LIMBO = 3
	local LIFE_STAGE_PREPPING_TO_DIE = 4
	local lifeStage = 0
	
	local pointLight = PointLight.new(Vec3(0,0,0),Vec3(4,2,0),1.5)
	pointLight:setCutOff(0.1)
	pointLight:setVisible(false)
	node:addChild(pointLight:toSceneNode())
	
	--sound
	local soundHitt = SoundNode.new("swarmBall_hitt")
	soundHitt:setSoundPlayLimit(2)
	node:addChild(soundHitt:toSceneNode())

	--
	--	private functions
	--
	local function basicLengthEstimation(position)
		local targetPos = targetSelector.getTargetPosition(targetIndex)
		--do a ruff estimation, based on travel time to position plus 1s for good messure
		local length = (targetPos-position):length()
		local estimatedTime2 = (length/speed)+1.0
		--another ruff estimation based on position + traveling time before impact
		targetPos = targetPos + (targetSelector.getTargetVelocity(targetIndex)*estimatedTime2)--just a prediction of futer pos
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
		local detailLevel = math.max(6.0,estimatedLength*2.0)
		local moveList = math.bezierCurve3D(s1, sd, ed, e1, detailLevel)
		if billboard:getBool("isNetOwner") then
			syncTable = {s1 = s1, sd = sd, ed = ed, e1 = e1, dLevel = detailLevel }
		end
		pathList:setList( moveList )
		return pathList:getLength()/speed
	end
	local function PlotPathToMidPoint(length,position)
		calculatedFutherPosition = targetSelector.getFuturePos(targetIndex,length/speed)
		lifeStage = LIFE_STAGE_TARGET_MIDPOINT
		local midPoint = (position+calculatedFutherPosition)*0.5
		midPoint.y = position.y + 2.0
		local enemyAt = (calculatedFutherPosition-position)
		enemyAt = Vec3(enemyAt.x,0.0,enemyAt.z):normalizeV()
		return estimateTimeAndPlotPath(midPoint,velocity,enemyAt,length,2.0)
	end
	local function PlotPathToAbove(length)
		estimatedTime = length/speed
		lifeStage = LIFE_STAGE_TARGET_MIDPOINT
		calculatedFutherPosition = targetSelector.getFuturePos(targetIndex,estimatedTime)
		estimatedTime = estimateTimeAndPlotPath(calculatedFutherPosition+Vec3(0.0,3.0,0.0),velocity*2.0,-targetSelector.getTargetVelocity(targetIndex):normalizeV()*2.0,length,2.0)
	end
	local function plotPathToTarget(length)
		local tryLimit = 5
		repeat
			estimatedTime = length/speed
			lifeStage = LIFE_STAGE_TARGET_ALIVE
			--the final estimation on the position
			calculatedFutherPosition = targetSelector.getFuturePos(targetIndex,estimatedTime)
			--the final estimated time to travel
			local estimatedLength = estimatedTime*speed
			local preEstimation = estimatedTime
			--print("detailLevel="..estimatedLength.."\n")
			estimatedTime = estimateTimeAndPlotPath(calculatedFutherPosition,velocity,targetSelector.getTargetVelocity(targetIndex):normalizeV()*2.0,estimatedLength,3.0)
			--print("FirstEstimation(pre="..preEstimation..", calculated="..estimatedTime..")\n")
			length = estimatedTime*speed--just incase next line fails
			--
			tryLimit = tryLimit - 1
		until math.abs(estimatedTime-preEstimation)<0.10 or tryLimit<0
	end
	local function endLife()
		pointLight:pushRangeChange(0.1,0.8)
		lifeStage = LIFE_STAGE_PREPPING_TO_DIE
		effect2:setVisible(false)
		explosion:activate(position,velocity)
		timeLeft = 1.0
		--this:attackTargetPos(position,DRONE_DETONATION_RANGE)
	end
	local function manageIfTargetIsNotAvailable()
		if targetSelector.isTargetAlive(targetIndex)==false then
			targetIndex = 0
			--
			--store towers default settings
			--
			targetSelector.storeSettings()
			--
			--score target close to swarmball
			targetSelector.setPosition(position)
			targetSelector.setRange(range*1.5)--covers 75% in worst case scenario
			targetSelector.selectAllInRange()
			targetSelector.scoreClosest(10)--closest to the current position
			--score target close to tower
			targetSelector.setPosition(towerPosition)--calculate value of closest target in comparison to the tower
			targetSelector.scoreClosest(10)--closest to the tower
			--score target by interest
			targetSelector.scoreName("fireSpirit",-100)
			targetSelector.scoreState(state.burning,-15)--[burning==2]
			--select only targets that is in range of the tower
			targetSelector.filterSphere(Sphere(towerPosition,range),false)
			targetIndex = targetSelector.selectTargetAfterMaxScore(-50)
			--
			--restor towers default setting
			--
			targetSelector.restoreSettings()
			--
			if targetIndex==0 then
				endLife()
			end
		end
	end

	--
	--	public functions
	--	
	function self.netSync(table)
		targetIndex = tonumber(Core.getIndexOfNetworkName(table.targetName))
		--position = table.s1--we always use the position to minimaze difference between start points
		if targetIndex>0 then
			if table.lifeStage==LIFE_STAGE_TARGET_MIDPOINT then
				local length = basicLengthEstimation(position)
				PlotPathToMidPoint(length+3.0,position)
			elseif table.lifeStage==LIFE_STAGE_TARGET_ALIVE then
				local length = 3.14*3.0*0.5
				length = length + (length/speed*targetSelector.getTargetVelocity(targetIndex):length()) + 1.0
				PlotPathToAbove(length)
			else
				local length = basicLengthEstimation(position)
				plotPathToTarget(length+4.0)
			end
		else
			position = table.s1
			local moveList = math.bezierCurve3D(table.s1, table.sd, table.ed, table.e1, table.dLevel)
			pathList:setList( moveList )
			if table.lifeStage==LIFE_STAGE_TARGET_MIDPOINT then
				lifeStage = LIFE_STAGE_TARGET_MIDPOINT
			elseif table.lifeStage==LIFE_STAGE_TARGET_ALIVE then
				lifeStage = LIFE_STAGE_TARGET_MIDPOINT
			else
				lifeStage = LIFE_STAGE_TARGET_ALIVE
			end
		end
	end
	function self.getProjectileNetName()
		return thisProjectileNetName
	end
	function self.init(table)
		targetIndex =		table[1]
		speed =		 		6.0--billboard:getFloat("fireballSpeed")
		velocity =			billboard:getVec3("escapeVector"):normalizeV()
		towerPosition =		table[2]
		position =			table[2]
		range =				table[3]+1.25--to give the projectile some space to move
		detonationRange = 	billboard:getFloat("detonationRange")
		burnTime =			billboard:getFloat("burnTime")
		fireDPS =			billboard:getFloat("fireDPS")
		damage =			billboard:getFloat("damage")
		smartTargeting =	billboard:getFloat("smartTargeting")
		lifeStage = 		0
		shieldAreaIndex =	targetSelector.getIndexOfShieldCovering(position)
		timeLeft = 			billboard:getFloat("fireballLifeTime")
		thisProjectileNetName = 			table[4]
	
		pathList:setSpeed(speed)
		
		node:setVisible(true)
		
		manageIfTargetIsNotAvailable()
			
		local length = basicLengthEstimation(position)
		--print("Length="..length.."\n")
		--if length>2.0 then
		estimatedTime = PlotPathToMidPoint(length+3.0,position)
		if billboard:getBool("isNetOwner") then
			syncTable.projectileNetName = thisProjectileNetName
			syncTable.targetName = Core.getNetworkNameOf(targetIndex)
			syncTable.lifeStage = LIFE_STAGE_TARGET_MIDPOINT
			local d1 = syncTable
			comUnit:sendNetworkSyncSafe("NetBall",tabToStrMinimal(syncTable))
		end
		--else
		--	plotPathToTarget(length+8.0)
		--end
		
		pointLight:setLocalPosition(position)
		pointLight:clear()
		pointLight:setVisible(true)
		pointLight:setRange(0.4)
		pointLight:pushRangeChange(2.0,0.7)
	
		effect2:activate(Vec3())
		effect2:setVisible(true)
	
		--comUnit:sendTo(targetIndex,"getFuturePos",firstTime)
	end
	function self.destroy()
		if node:getParent() then
			node:getParent():removeChild(node:toSceneNode())
		end
	end
	function self.stop()
		hittExplosion:setVisible(false)
		explosion:setVisible(false)
		effect2:setVisible(false)
		pointLight:setVisible(false)
		node:setVisible(false)
	end
	function self.update()
		timeLeft = timeLeft - Core.getDeltaTime()
		
		if lifeStage==LIFE_STAGE_PREPPING_TO_DIE then
			--drone has exploded
			--waiting for particle effect to die
			if explosion:isActive()==false and hittExplosion:isActive()==false then
				effect2:setVisible(false)
				pointLight:setVisible(false)
				node:setVisible(false)
				return false
			end
		else
			if timeLeft<0.0 then
				--detonate drone
				endLife()
				return true
			end
			if (position-towerPosition):length()>range then
				--we are out of range from the tower, try to find a new target
				targetIndex = 0
			elseif (position-towerPosition):length()>range*1.5 then
				--failed, hide issue ;-)
				endLife()
			end
			if pathList:willReachEnd() then
				manageIfTargetIsNotAvailable()
				if targetIndex>0 then
					if lifeStage==LIFE_STAGE_TARGET_MIDPOINT then
						local length = basicLengthEstimation(position)
						plotPathToTarget(length+4.0)
						--
						if billboard:getBool("isNetOwner") then
							syncTable.projectileNetName = thisProjectileNetName
							syncTable.targetName = Core.getNetworkNameOf(targetIndex)
							syncTable.lifeStage = LIFE_STAGE_LIMBO
							comUnit:sendNetworkSyncSafe("NetBall",tabToStrMinimal(syncTable))
						end
					else
						--attack
						if targetSelector.isTargetNamed(targetIndex,"electroSpirit")==false then
							hittExplosion:activate(position,velocity)--activate hitt indication
						end
						comUnit:sendTo(targetIndex,"attackFire",tostring(damage))
						comUnit:sendTo(targetIndex,"attackFireDPS",{DPS=fireDPS,time=burnTime,type="fire"})
						--circumference of half a circle
						local length = 3.14*3.0*0.5
						--length is half circumference + the distance the soul will travel during that time approxmatly
						length = length + (length/speed*targetSelector.getTargetVelocity(targetIndex):length()) + 1.0 -- 1.0 is just for good messure
						PlotPathToAbove(length)
						--
						if billboard:getBool("isNetOwner") then
							syncTable.projectileNetName = thisProjectileNetName
							syncTable.targetName = Core.getNetworkNameOf(targetIndex)
							syncTable.lifeStage = LIFE_STAGE_TARGET_ALIVE
							comUnit:sendNetworkSyncSafe("NetBall",tabToStrMinimal(syncTable))
						end
						--
						soundHitt:setLocalPosition(position)
						soundHitt:play(1.0,false)
					end
				else
					comUnit:broadCast(position,detonationRange,"attack",tostring(damage))
					endLife()
				end
			elseif shieldAreaIndex~=targetSelector.getIndexOfShieldCovering(position) then
				--forcefield hitt
				targetIndex = shieldAreaIndex>0 and shieldAreaIndex or targetSelector.getIndexOfShieldCovering(position)
				comUnit:sendTo(targetIndex,"attack",tostring(damage+(fireDPS*0.5)))--can't do fire damage to shield
				--hitt effect
				local oldPosition = position - pathList:getVelocity():normalizeV()
				local futurePosition = position + pathList:getVelocity():normalizeV()
				local hitTime = tostring(0.5)
				comUnit:sendTo(targetIndex,"addForceFieldEffect",tostring(oldPosition.x)..";"..oldPosition.y..";"..oldPosition.z..";"..futurePosition.x..";"..futurePosition.y..";"..futurePosition.z..";"..hitTime)
				endLife()
				explosion:deactivate()
			end
			if lifeStage~=LIFE_STAGE_PREPPING_TO_DIE then
				pointLight:setLocalPosition(position)
				velocity = pathList:getVelocity():normalizeV()
				position = pathList:getNextPos()
				--moveList = pathList:getList()

				velocity = velocity:normalizeV()
				effect2:setLocalPosition(position)
			end
		end
		pointLight:update()
		return true
	end
	
	return self
end