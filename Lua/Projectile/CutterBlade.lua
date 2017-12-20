require("NPC/deathManager.lua")
require("NPC/state.lua")
require("Menu/settings.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
--this = SceneNode()
CutterBlade = {name="CutterBlade"}
function CutterBlade.new(pTargetSelector)
	local self = {}
	local sparkCenter
	local pointLight
	local attacked = {}
	local speed = 8.0
	local range = 1.35
	local stateDamageMul = 0.0
	local damage = 0.0
	local npcHitt = 0
	local slow = 0.0
	local slowTimer = 0.0
	local statesAffected = 0
	local masterBladeLevel = 0
	local movment
	local atVec 		--atVec = Vec3()
	local length
	local thePosition 	--atVec = Vec3()
	local SlowDuration
	local shieldAreaIndex = 0
	local shieldBypass = 0.0
	local comUnit = Core.getComUnit()
	local billboard = Core.getBillboard()
	local testForceFiledOnAttack = false
	local deathManager
	local maxPos = Vec3()
	local projectileIsDead = false
	local model = Core.getModel("projectile_blade.mym")
	local blade = model:getMesh( "blade" )
	local node = SceneNode()
	local damageDone = 0.0
	this:findNodeByTypeTowardsRoot(NodeId.playerNode):addChild(node)
	node:addChild(model)
	
	blade:setShader(Core.getShader("minigunPipe"))	
	blade:setUniform(blade:getShader(), "heatUvCoordOffset", Vec2(256/blade:getTexture(blade:getShader(),0):getSize().x,0))
	blade:setUniform(blade:getShader(), "heat", 0.0)

	--targetingSystem
	local targetSelector = pTargetSelector

	local function attack(target,startPos)
		--ParticleEffectElectricFlash("Lightning_D.tga")
		if testForceFiledOnAttack and shieldAreaIndex~=targetSelector.getIndexOfShieldCovering(targetSelector.getTargetPosition(target)) then
			--the npc is inside a forcefield
		else
			attacked[target]=true
			if stateDamageMul>1.0 and targetSelector.isTargetInState(target,state.burning) then
				comUnit:sendTo(target,"attackBlade",tostring(damage*stateDamageMul).."")
				comUnit:sendTo("SteamAchievement","CriticalStrike","")
				damageDone = damageDone + damage*stateDamageMul
			else
				comUnit:sendTo(target,"attackBlade",tostring(damage).."")
				damageDone = damageDone + damage
			end
			if shieldBypass>0.5 then
				comUnit:sendTo(target,"destroyShield","")
			end
			if slow>0.0 and (targetSelector.getTargetPosition(target)-(thePosition+(atVec*movment))):length()<2.0 then
				comUnit:sendTo(target,"slow",{per=slow,time=slowTimer,type="physical"})
			end
			npcHitt = npcHitt + 1
--			if npcHitt>6 then
--				--the first 6 will take full damage
--				damage = damage*0.90
--				speed = math.max(speed*0.9, 5.0)
--			end
			model:setLocalPosition( model:getLocalPosition() + (model:getLocalPosition():normalizeV()*0.01 ) )
		end
	end
	
	local function attackAllNewTargetsInRange(line)
		targetSelector.selectAllInCapsule(line,range)
		local targets = targetSelector.getAllTargets()
		for index,score in pairs(targets) do
			if not attacked[index] then
				--if we have not attacked this unit before
				attack(index,line.startPos)
			end
		end
	end
	
	function self.init(param)
		movment = 0.0
		deathManager = param.dManager
		atVec = billboard:getVec3("pipeAt"):normalizeV()
		length = billboard:getFloat("range")
		thePosition = billboard:getVec3("BulletStartPos")
		maxPos = thePosition+(atVec*length)
		damage = billboard:getFloat("damage")
		speed = billboard:getFloat("bladeSpeed")
		slow = billboard:getFloat("slow")
		slowTimer = billboard:getFloat("slowTimer")
		stateDamageMul = billboard:getFloat("stateDamageMul")
		masterBladeHeat = billboard:getFloat("masterBladeHeat")
		shieldBypass = billboard:getFloat("shieldBypass")
		shieldAreaIndex = targetSelector.getIndexOfShieldCovering(thePosition)
		blade:setUniform(blade:getShader(), "heat", masterBladeHeat)
		testForceFiledOnAttack = false
		projectileIsDead = false
		npcHitt = 0
		damageDone = 0.0
		
		targetSelector.setPosition(thePosition+(atVec*(length*0.5)))
		targetSelector.setRange(length*0.55)
		
		if billboard:getInt("electricBlade")>0 then
			if not sparkCenter then
				sparkCenter = {}
				for i=1, 4, 1 do
					sparkCenter[i] = ParticleSystem(ParticleEffect.SparkSpirit)
					blade:addChild(sparkCenter[i])
				end
				sparkCenter[2]:setLocalPosition(Vec3(0.05,0.28,0.0)*0.66)
				sparkCenter[3]:setLocalPosition(Vec3(-0.28,-0.10,0.0)*0.66)
				sparkCenter[4]:setLocalPosition(Vec3(0.22,-0.20,0.0)*0.66)
				pointLight = PointLight(Vec3(0,0,0),Vec3(0,1.75,3.5),2.5)
				pointLight:setVisible(false)
				model:addChild(pointLight)
			end
			for i=1, 4, 1 do
				sparkCenter[i]:setScale( 0.10+(0.05*billboard:getInt("electricBlade")) )
				sparkCenter[i]:activate(Vec3())
			end
			pointLight:clear()
			pointLight:setRange(0.2)
			pointLight:pushRangeChange(2.5,0.2)
			pointLight:setVisible(true)
		else
			if sparkCenter then
				sparkCenter[1]:deactivate()
				sparkCenter[2]:deactivate()
				sparkCenter[3]:deactivate()
				sparkCenter[4]:deactivate()
			end
			if pointLight then
				pointLight:setVisible(false)
			end
		end
		--thePosition.y = 0.0
		node:setLocalPosition(thePosition)
		attacked = {}
		
		--dist = Collision.lineSegmentPointDist3D(line,Vec3(3,1,0))
		model:setLocalPosition(Vec3(0.01,0,0))
		model:setVisible(true)
	end
	local function generatePhysicalBlade(outVector)
		outVector = Vec3(outVector.x,outVector.y+0.75,outVector.z)
		--physic
		local lmodel=Core.getModel("projectile_blade.mym")
--		local lblade = model:getMesh( "blade" )
		
		local globalPos = model:getGlobalPosition()
		
		local rigidBody = RigidBody(this,Box(globalPos - Vec3(0.5,0.2,0.5), globalPos + Vec3(0.5,0.2,0.5)),outVector*3)
		rigidBody:addChild(lmodel)
		--set rotation from model blade
		lmodel:setLocalMatrix( model:getGlobalMatrix():inverseM() * lmodel:getGlobalMatrix() )
		--remove offset, this should not be needed
		lmodel:setLocalPosition(Vec3())
		deathManager.addRigidBody(rigidBody)
		
	end
	function self.destroy()
		if node:getParent() then--as the parrent can already be destroyed, if end of the map
			node:getParent():removeChild(node)
		end
	end
	function self.stop()
		if sparkCenter then
			for i=1, 4, 1 do
				sparkCenter[i]:deactivate()
			end
			pointLight:setVisible(false)
		end
		--
		model:setVisible(false)
	end
	function self.update()		
		local previousPos = thePosition+(atVec*movment)
		movment = movment + (speed * Core.getDeltaTime())
		local currentPos = thePosition+(atVec*movment)
		if shieldAreaIndex~=targetSelector.getIndexOfShieldCovering(currentPos) then
			--forcefield hitt
			shieldAreaIndex = shieldAreaIndex>0 and shieldAreaIndex or targetSelector.getIndexOfShieldCovering(currentPos)
			if stateDamageMul>1.0 then
				comUnit:sendTo(shieldAreaIndex,"attack",tostring(damage*stateDamageMul))
				damageDone = damageDone + damage*stateDamageMul
			else
				comUnit:sendTo(shieldAreaIndex,"attack",tostring(damage))
				damageDone = damageDone + damage
			end
			local oldPosition = currentPos - atVec
			local futurePosition = currentPos + atVec
			local hitTime = tostring(0.75)
			comUnit:sendTo(shieldAreaIndex,"addForceFieldEffect",tostring(oldPosition.x)..";"..oldPosition.y..";"..oldPosition.z..";"..futurePosition.x..";"..futurePosition.y..";"..futurePosition.z..";"..hitTime)
			--stop blade if shieldByPass is not upgraded
			if shieldBypass<0.5 then
				projectileIsDead = true
				testForceFiledOnAttack = true
			else
				shieldAreaIndex = targetSelector.getIndexOfShieldCovering(currentPos)
			end
		end
		--
		--	blocked
		--
		local shieldDist = (billboard:getVec3("bladeBlockedPos")-currentPos):length()
		if shieldDist<1.25 then
			--this blade was blocked on this position
			--remove the block
			--atVec = atVec * 2.0
			local bladeDir = atVec:normalizeV()
			local npcDir = billboard:getVec3("bladeBlockedDir"):normalizeV()
			local outVec = -((npcDir*bladeDir)*npcDir*2.0-bladeDir)
			billboard:setVec3("bladeBlockedPos",Vec3(0,-1000000,0))
			--
			if Settings.DeathAnimation.getSettings()=="Enabled" then
				generatePhysicalBlade(outVec)
			end
			--
			attackAllNewTargetsInRange(Line3D(previousPos,billboard:getVec3("bladeBlockedPos")) )
			projectileIsDead = true
		else
			attackAllNewTargetsInRange(Line3D(previousPos,((movment>length) and maxPos or currentPos)) )
		end
		--
		--	End of projectile?
		--
		if projectileIsDead or movment>length then
			--reached end of line/ or hit a physical shield
			self.stop()--makes it invisible
			comUnit:sendTo("SteamStats","BladeMaxHittCount",npcHitt)
			comUnit:sendTo("SteamStats","MaxDamageDealt",damageDone)
			return false
		end
		model:rotateAroundPoint(Vec3(0,1,0),Vec3(),-Core.getDeltaTime()*math.pi*3.0)
		node:setLocalPosition(currentPos)
	
		--
		--	graphic part of the code
		--
		if slow>0.0 then
			pointLight:update()
			--pointLight:render()
		end
		--model:render()
		return true
	end
	
	return self
end