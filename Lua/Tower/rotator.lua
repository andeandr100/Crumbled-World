Rotator = {}
function Rotator.new()
	local self = {}
	local FIRSTENEMYTIMER		= 7.0
	local STARTRANDOMTARGETING	= 3.0	--when the pipe will start to randomly rotate around
	local TIMERTARGETNEXTRANDOM	= 4.0	--when the randomness will get a new main goal to rotate around
	--
	local speedHorMax = 0.0
	local speedHorMin = 0.0
	local speedHorAcc = 0.0
	local speedHor = 0.0
	local speedVerMax = 0.0
	local speedVerMin = 0.0
	local speedVerAcc = 0.0
	local speedVer = 0.0
	--defaults
	local verMinAngle = 0.0
	local verMaxAngle = 0.0
	local horMinAngle = 0.0
	local horMaxAngle = 0.0
	local horLimits = false
	local readyToFireCount = 0
	local targetNothingTimer = 0.0
	local targetSetDuringIdelingTimer = 0.0
	local targetSetDuringIdeling = false
	--
	local defaultAt = Vec3()
	local targetAt = Vec3()
	local averageEnemyPosition = Vec3()
	local aimAt = Vec3()
	
	local function init()
		--speeds
		speedHorMax = math.pi*1.25
		speedHorMin = math.pi*0.2
		speedHorAcc = math.pi*1.0
		speedHor = math.pi*0.2
		speedVerMax = math.pi*0.4
		speedVerMin = math.pi*0.05
		speedVerAcc = math.pi*0.3
		speedVer = math.pi*0.05
		--defaults
		verMinAngle = -math.pi*0.5
		verMaxAngle = math.pi*0.5
		horMinAngle = -math.pi*2.0
		horMaxAngle = math.pi*2.0
		horLimits = false
		readyToFireCount = 0
		targetNothingTimer = FIRSTENEMYTIMER+0.01
		targetSetDuringIdelingTimer = 0.0
		targetSetDuringIdeling = false
		
		defaultAt = Vec3()
		targetAt = Vec3()
		averageEnemyPosition = Vec3()
		aimAt = Vec3()
	end
	init()
	
	local function getValueBetween(max,min,value)
		if max<value then
			return max
		elseif min>value then
			return min
		end
		return value
	end
	function self.setHorizontalLimits(pDefaultAt,horMin,horMax)
		defaultAt = pDefaultAt
		horMinAngle = horMin
		horMaxAngle = horMax
		horLimits = true
	end
	function self.setVerticalLimits(verMin,verMax)
		verMinAngle = verMin
		verMaxAngle = verMax
	end
	function self.setSpeedHorizontalMaxMinAcc(speedHorMax,speedHorMin,speedHorAcc)
		speedHorMax = speedHorMax
		speedHorMin = speedHorMin
		speedHorAcc = speedHorAcc
		speedHor = speedHorMin
	end
	function self.setSpeedVerticalMaxMinAcc(speedVerMax,speedVerMin,speedVerAcc)
		speedVerMax = speedVerMax
		speedVerMin = speedVerMin
		speedVerAcc = speedVerAcc
		speedVer = speedVerMin
	end
	--use this to get random movment of pipe when targets is not available
	function self.setFrameDataAndUpdate(pAimAt)
		targetNothingTimer = targetNothingTimer + Core.getDeltaTime()
		targetSetDuringIdelingTimer = targetSetDuringIdelingTimer + Core.getDeltaTime()
		aimAt = pAimAt
		
		--lets do some random targeting, make the tower look bussy
		if targetNothingTimer>STARTRANDOMTARGETING then
			--waited long enogh, target random target
			if targetAt:length()<0.1 or 0.025>math.abs(-math.atan2((targetAt.x*aimAt.z)-(targetAt.z*aimAt.x),(targetAt.x*aimAt.x)+(targetAt.z*aimAt.z))) then
				if targetSetDuringIdelingTimer>TIMERTARGETNEXTRANDOM then
					targetSetDuringIdeling = false
					targetSetDuringIdelingTimer = math.randomFloat(-1.25,0.25)--randomize up the movement
				else
					targetAt = Vec3()
				end
			end
			if targetSetDuringIdeling==false and averageEnemyPosition:length()>0.1 then
				targetSetDuringIdeling = true
				if targetNothingTimer>TIMERTARGETNEXTRANDOM then
					horTargetAngle = math.randomFloat(-math.pi*(1/6),math.pi*(1/6))--math.randomFloat(-30.0,30.0)
					local newTarget = Matrix()
					newTarget:createMatrix(averageEnemyPosition,Vec3(0.0, 1.0, 0.0))
					--local rot = Quat(Vec3(0.0, 1.0, 0.0), self.horTargetAngle)
					--local rotMat = rot:getMatrix()
					--newTarget = newTarget * rotMat
					--self.targetAt = newTarget:getAtVec()
					targetAt = (newTarget * Quat(Vec3(0.0, 1.0, 0.0), horTargetAngle):getMatrix()):getAtVec()
				else
					targetAt = averageEnemyPosition
				end
			end
		else
			--do nothing, not enogh time have passed yet
			targetAt = Vec3()
		end
	end
	--use this when there is targets available
	function self.setFrameDataTargetAndUpdate(pTargetAt,pAimAt)
		--target is located and done after FIRSTENEMYTIMER. now we will tune our gun to aim at this place more when inactive
		if targetNothingTimer>FIRSTENEMYTIMER then
			averageEnemyPosition = (averageEnemyPosition+targetAt)*0.5
			averageEnemyPosition.y=0.0 --angle will be set to 0 degree
			averageEnemyPosition:normalize()
		end
		targetNothingTimer = -0.0001
		
		--frame information
		aimAt = pAimAt
		targetAt = pTargetAt
		
		--update speeds
		speedHor = speedHor + (speedHorAcc*Core.getDeltaTime())
		speedVer = speedVer + (speedVerAcc*Core.getDeltaTime())
		--stick to speed limits
		speedHor = math.min(speedHor,speedHorMax)
		speedHor = math.max(speedHor,speedHorMin)
		speedVer = math.min(speedHor,speedVerMax)
		speedVer = math.max(speedHor,speedVerMin)
		
		--ready to fire
		readyToFireCount = 0
	end
	function self.isReadyToFire()
		return readyToFireCount==2--hor(+1) and ver(+1) in position then we can fire
	end
	function self.isAtHorizontalLimit()
		if horLimits then
			local rotLimitCheck = -math.atan2((targetAt.x*defaultAt.z)-(targetAt.z*defaultAt.x),(targetAt.x*defaultAt.x)+(targetAt.z*defaultAt.z))
			if rotLimitCheck<horMinAngle or rotLimitCheck>horMaxAngle then
				return true
			end
		end
		return false
	end
	function self.isAtVerticalLimit()
		error("Is not implemented")
		crash = just + crash
		return false
	end
	function self.getHorizontalRotation()
		local deltaTime = Core.getDeltaTime()
		local rotToDo = 0.0
		--set max rotation that can be done
		if targetNothingTimer>0.0 then
			rotToDo = rotToDo + math.sin( targetNothingTimer )*Core.getDeltaTime()*0.05
		end
		if targetAt:length()>0.1 then
			rotToDo = rotToDo - math.atan2((targetAt.x*aimAt.z)-(targetAt.z*aimAt.x),(targetAt.x*aimAt.x)+(targetAt.z*aimAt.z))
		end
		--limit rotations if there is an restriction
		if horLimits then
			local rotLimitCheck = -math.atan2((targetAt.x*defaultAt.z)-(targetAt.z*defaultAt.x),(targetAt.x*defaultAt.x)+(targetAt.z*defaultAt.z))
			if rotLimitCheck<horMinAngle then
				rotToDo = rotToDo + horMinAngle-rotLimitCheck
				if rotToDo>0.0 then
					rotToDo = 0.0
				end
			end
			if rotLimitCheck>horMaxAngle then
				rotToDo = rotToDo + horMaxAngle-rotLimitCheck
				if rotToDo<0.0 then
					rotToDo = 0.0
				end
			end
		end
		--set rotation max to what this frame can allow
		if targetNothingTimer>0.0 then
			if speedHorMin*deltaTime<math.abs(rotToDo) then
				return (rotToDo<0.0) and -speedHorMin*deltaTime or speedHorMin*deltaTime--we are not in a hurry
			end
			targetAt = Vec3()
			return rotToDo
		end
		local rotPer = (speedHor*deltaTime)/math.abs(rotToDo)
		local rotThisFrame = speedHor*deltaTime
		rotThisFrame = (rotToDo>0.0) and rotThisFrame or -rotThisFrame
		if rotPer>1.0 then-- rotThisFrame/rotToDo == rotation in percentage 
			rotThisFrame = rotToDo
			speedHor = math.max(speedHorMin,math.abs(rotToDo*(1.0/deltaTime)))--speed is always be greater then 0
			readyToFireCount = readyToFireCount + 1
		end
		return rotThisFrame
	end
	function self.getVerticalRotation()
		local rotToDo = 0.0
		local deltaTime = Core.getDeltaTime()
		local angleTarget = getValueBetween(verMaxAngle,verMinAngle,math.atan(targetAt.y/(0.00001+math.sqrt((targetAt.x*targetAt.x)+(targetAt.z*targetAt.z)))))--returns a value between max,min
		local angleAim = math.atan(aimAt.y/(0.00001+math.sqrt((aimAt.x*aimAt.x)+(aimAt.z*aimAt.z))))--current vertical angle
		if targetNothingTimer>0.0 then
			if targetAt ~= Vec3() then
				rotToDo = angleTarget-angleAim
				if math.abs(rotToDo)>speedVerMin*deltaTime then
					return rotToDo<0.0 and -speedVerMin*deltaTime or speedVerMin*deltaTime
				end
				return rotToDo
			end
			return math.cos( targetNothingTimer )*deltaTime*0.035
		else
			rotToDo = angleTarget-angleAim
		end
		local rotPer = (speedVer*deltaTime)/math.abs(rotToDo)
		local rotThisFrame = speedVer*deltaTime
		rotThisFrame = (rotToDo>0.0) and rotThisFrame or -rotThisFrame
		if rotPer>1.0 then-- rotThisFrame/rotToDo == rotation in percentage
			rotThisFrame = rotToDo
			speedVer = math.max(speedVerMin,math.abs(rotToDo*(1.0/deltaTime)))--speed must always be greater then 0
			readyToFireCount = readyToFireCount + 1
		end
		return rotThisFrame
	end
	--function rotator:getCurrentHorizontalAngle()
	--	return -math.atan2((self.defaultAt.x*self.aimAt.z)-(self.defaultAt.z*self.aimAt.x),(self.defaultAt.x*self.aimAt.x)+(self.defaultAt.z*self.aimAt.z))
	--end
	return self
end