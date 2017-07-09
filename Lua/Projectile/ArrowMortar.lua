require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
--this = SceneNode()

ArrowMortar = {name="ArrowMortar"}
function ArrowMortar.new()
	local self = {}
	local movment = 0.0
	local targetIndex = 0
	local lastLocationOnTarget = Vec3()
	local startPos = Vec3()
	local currentPos
	local state
	local speed = 15.0
	local damage
	local weaken
	local weakenTimer
	local detonationRange
	local fireDPS
	local burnTime
	local range
	local shieldAreaIndex = 0
	local hittStrength = 1
	local comUnit = Core.getComUnit()
	local billboard = Core.getBillboard()
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
		
	--scenNode
	local node = SceneNode()
	this:findNodeByTypeTowardsRoot(NodeId.playerNode):addChild(node)
	--model
	local model = Core.getModel("projectile_mortar.mym")
	node:addChild(model)
	
	--Particle effect
	local explosion = ParticleSystem( ParticleEffect.ExplosionMedium )
	node:addChild(explosion)
	
	--pointLight
	local pointLight = PointLight(Vec3(0,0,0),Vec3(4,2,0),0.2)
	pointLight:setCutOff(0.1)
	pointLight:setVisible(false)
	node:addChild(pointLight)

	--targetingSystem
	targetSelector.setPosition(this:getGlobalPosition())
	targetSelector.setRange(1.0)
	
	
	function self.init()
		--targetingSystem
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(billboard:getFloat("range")+1.0)
		targetSelector.setAngleLimits(Vec3(),math.pi*2)
	
		targetSelector.setTarget(billboard:getInt("targetIndex"))
		if targetSelector.isTargetAlive(targetSelector.getTarget())==false then
			targetSelector.deselect()
		end
		
		targetIndex = billboard:getInt("targetIndex")
		damage = billboard:getFloat("damage")
		startPos = billboard:getVec3("bulletStartPos")
		currentPos = startPos
		shieldAreaIndex = targetSelector.getIndexOfShieldCovering(currentPos)
		weaken = billboard:getFloat("weaken")
		weakenTimer = billboard:getFloat("weakenTimer")
		detonationRange = billboard:getFloat("detonationRange")
		burnTime = billboard:getFloat("burnTime")
		fireDPS = billboard:getFloat("fireDPS")
		prevAtVec = billboard:getVec3("pipeAtVector")
		range = billboard:getFloat("range")
		hittStrength = billboard:getDouble("hittStrength")
		state = 0
		lastLocationOnTarget = targetSelector.getTargetPosition(targetIndex)
		local atVec = Vec3( (lastLocationOnTarget-currentPos)+Vec3(0.0,0.75,0.0) )
		atVec = atVec:normalizeV()
		local matrix = Matrix()
		matrix:createMatrix(atVec,Vec3(0.0, 0.0, 1.0))
		matrix:scale(Vec3(1.5,1.5,1.5))
		matrix:setPosition(currentPos)
		node:setLocalMatrix(matrix)
		model:setVisible(true)
		
		pointLight:setVisible(false)
	end
	function self.destroy()
		if node:getParent() then--as the parrent can already be destroyed, if end of the map
			node:getParent():removeChild(node)
		end
	end
	function self.stop()
		explosion:setVisible(false)
		pointLight:clear()
		pointLight:clearFlickerAndSinCurve()
		pointLight:setVisible(false)
		model:setVisible(false)
	end
	function self.update()
		if state==0 then
			if targetSelector.isTargetAlive(targetIndex)==true then
				lastLocationOnTarget = targetSelector.getTargetPosition(targetIndex)
			end
			local atVec = Vec3( lastLocationOnTarget-currentPos )
			local lengthLeft = atVec:length()
			atVec:normalize()
			local frameMovment = speed * Core.getDeltaTime()
			currentPos = currentPos + (atVec * frameMovment)
			if targetSelector.isTargetAlive(targetIndex)==false then
				local per = (startPos-currentPos):length()/8.0
				per = (per>1.0) and 1.0 or per
				prevAtVec = prevAtVec or atVec --prevAtVec = Vec3()
				targetSelector.setPosition(currentPos)
				targetSelector.setAngleLimits(prevAtVec,math.pi*(0.10+(0.25*per)))
				targetSelector.setRange((range+1.0)-(startPos-currentPos):length())
				targetSelector.selectAllInRange()
				targetSelector.scoreClosestToVector(prevAtVec,10)
				targetIndex = targetSelector.selectTargetAfterMaxScore()
				if targetIndex==0 then
					self.stop()
					return false
				else
					atVec = Vec3( targetSelector.getTargetPosition(targetIndex)-currentPos )
					lengthLeft = atVec:length()
					if lengthLeft<1.0 then
						lengthLeft=frameMovment--just insta hitt instead of doing strange movments
					end
					comUnit:sendTo(LUA_INDEX,"retargeted","")
				end
			else
				prevAtVec = atVec
			end
			if lengthLeft-frameMovment<0.25 then
				local damageDone = 0.0
				--if target is alive send damage info
				if targetSelector.isTargetAlive(targetIndex)==true then
					if weaken>0.01 then
						comUnit:sendTo(targetIndex,"markOfDeath",{per=weaken,timer=weakenTimer,type="area"})
					end
					comUnit:sendTo(targetIndex,"attack",tostring(damage*0.75))
					damageDone = damageDone + damage*0.75
				end
				targetSelector.setPosition(lastLocationOnTarget)
				targetSelector.setRange(detonationRange)
				targetSelector.selectAllInRange()
				local targets = targetSelector.getAllTargets()
				comUnit:sendTo("SteamStats","ArrowMortarMaxHittCount",targetSelector.getAllTargetCount())
				for index,score in pairs(targets) do
					comUnit:sendTo(index,"markOfDeath",{per=weaken,timer=weakenTimer,type="area"})
					comUnit:sendTo(index,"attack",tostring(damage*0.25))
					comUnit:sendTo(index,"attackFireDPS",{DPS=fireDPS,time=burnTime,type="fire"})
					damageDone = damageDone + (damage*0.25) + (fireDPS*burnTime)
				end
				--
				comUnit:broadCast(lastLocationOnTarget,detonationRange,"physicPushIfDead",currentPos-(atVec * (frameMovment+0.25)))
				comUnit:sendTo("SteamStats","MaxDamageDealt",damageDone)
				state = 1
			elseif shieldAreaIndex~=targetSelector.getIndexOfShieldCovering(currentPos) then
				--shield hitt
				targetIndex = shieldAreaIndex>0 and shieldAreaIndex or targetSelector.getIndexOfShieldCovering(currentPos)
				comUnit:sendTo(targetIndex,"attack",tostring(damage+(fireDPS*0.5)))
				local oldPosition = currentPos - atVec
				local futurePosition = currentPos + atVec
				local hitTime = tostring(0.5+(hittStrength*0.15))
				comUnit:sendTo(targetIndex,"addForceFieldEffect",tostring(oldPosition.x)..";"..oldPosition.y..";"..oldPosition.z..";"..futurePosition.x..";"..futurePosition.y..";"..futurePosition.z..";"..hitTime)
				state = 1
			end
			if state==0 then
				--this projectile is not rotating
				local matrix = Matrix()
				matrix:createMatrix(atVec,Vec3(0.0, 0.0, 1.0))
				matrix:scale(Vec3(1.5,1.5,1.5))
				matrix:setPosition(currentPos)
				node:setLocalMatrix(matrix)
			else
				--hide model
				model:setVisible(false)
				--do the explostion
				explosion:activate(Vec3())
				pointLight:setRange(0.25)
				pointLight:pushRangeChange(5.0,0.1)
				pointLight:pushRangeChange(0.2,0.5)
				pointLight:setVisible(true)
			end
		elseif state==1 and explosion:isActive()==false then
			self.stop()
			return false
		end
			
		return true
	end
	
	return self
end