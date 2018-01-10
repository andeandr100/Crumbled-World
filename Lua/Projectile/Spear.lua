require("NPC/deathManager.lua")
require("NPC/state.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
--this = SceneNode()

Spear = {name="Spear"}
function Spear.new(pTargetSelector)
	local self = {}
	local attacked = {}
	local sparkCenter
	local pointLight
	local speed = 8.0
	local range = 1.25
	local damage
	local stateDamageMul
	local movment
	local slow
	local slowTimer
	local atVec 		--atVec = Vec3()
	local length
	local thePosition 	--atVec = Vec3()
	local SlowDuration
	local shieldAreaIndex = 0
	local shieldBypass = 0.0
	local comUnit = Core.getComUnit()
	local billboard = Core.getBillboard()
	local maxPos = Vec3()
	local damageDone = 0.0

	local model = Core.getModel("projectile_spear.mym")
	local spear = model:getMesh( "spear" )
	local node = SceneNode.new()
	this:findNodeByTypeTowardsRoot(NodeId.playerNode):addChild(node)
	node:addChild(model:toSceneNode())
	
	spear:setShader(Core.getShader("minigunPipe"))	
	spear:setUniform(spear:getShader(), "heatUvCoordOffset", Vec2(256/spear:getTexture(spear:getShader(),0):getSize().x,0))
	spear:setUniform(spear:getShader(), "heat", 0.0)

	--targetingSystem
	local targetSelector = pTargetSelector
	targetSelector.setPosition(this:getGlobalPosition())
	targetSelector.setRange(range)

	function self.stop()
		if sparkCenter then
			sparkCenter:deactivate()
			pointLight:setVisible(false)
		end
		model:setVisible(false)
	end
	
	local function attack(target,startPos)
		--ParticleEffectElectricFlash("Lightning_D.tga")
		attacked[target]=true
		if stateDamageMul>1.0 and targetSelector.isTargetInState(target,state.burning) then
			comUnit:sendTo(target,"attackBlade",tostring(damage*stateDamageMul).."")
			damageDone = damageDone + damage*stateDamageMul
		else
			comUnit:sendTo(target,"attackBlade",tostring(damage).."")
			damageDone = damageDone + damage
		end
		if slow>0.0 then
			comUnit:sendTo(target,"slow",{per=slow,time=slowTimer,type="physical"})
		end
		if shieldBypass>0.5 then
			comUnit:sendTo(target,"destroyShield","")
		end
		model:setLocalPosition( model:getLocalPosition() + (model:getLocalPosition():normalizeV()*0.01 ) )
	end
	
	function attackAllNewTargetsInRange(line)
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
		atVec = billboard:getVec3("pipeAt"):normalizeV()
		length = billboard:getFloat("range")
		thePosition = billboard:getVec3("BulletStartPos")
		maxPos = thePosition+(atVec*length)
		damage = billboard:getFloat("damage")
		speed = billboard:getFloat("bladeSpeed")
		slow = billboard:getFloat("slow")
		slowTimer = billboard:getFloat("slowTimer")
		shieldBypass = billboard:getFloat("shieldBypass")
		stateDamageMul = billboard:getFloat("stateDamageMul")
		masterBladeLevel = billboard:getInt("masterBladeLevel")
		shieldAreaIndex = targetSelector.getIndexOfShieldCovering(thePosition)
		spear:setUniform(spear:getShader(), "heat", masterBladeLevel>0 and masterBladeLevel/3.0 or 0.0)
		damageDone = 0.0
		
		targetSelector.setPosition(thePosition+(atVec*(length*0.5)))
		targetSelector.setRange(length*0.55)
		
		if billboard:getFloat("electricBlade")>0 then
			if not parkCenter then
				sparkCenter = ParticleSystem.new(ParticleEffect.SparkSpirit)
				spear:addChild(sparkCenter:toSceneNode())
				sparkCenter:setLocalPosition(Vec3(-0.33,0.0,0.0))
				--
				pointLight = PointLight.new(Vec3(0,0,0),Vec3(0,1.75,3.5),2.5)
				pointLight:setVisible(false)
				model:addChild(pointLight:toSceneNode())
			end
			sparkCenter:setScale( 0.10+(0.05*billboard:getFloat("electricBlade")) )
			sparkCenter:activate(Vec3())
			pointLight:clear()
			pointLight:setRange(0.2)
			pointLight:pushRangeChange(2.5,0.5)
			pointLight:setVisible(true)
			
		end
		--thePosition.y = 0.0
		node:setLocalPosition(thePosition)
		attacked = {}

		local matrix = Matrix()
		matrix:createMatrix(atVec,Vec3(0.0, 1.0, 0.0))
		matrix:setPosition(thePosition)
		node:setLocalMatrix(matrix)
		
		--dist = Collision.lineSegmentPointDist3D(line,Vec3(3,1,0))
	--	model:setLocalPosition(Vec3(0.01,0.01,0.01))
		model:setVisible(true)
	end
	function self.destroy()
		if node:getParent() then--as the parrent can already be destroyed, if end of the map
			node:getParent():removeChild(node:toSceneNode())
		end
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
			shieldAreaIndex = targetSelector.getIndexOfShieldCovering(currentPos)
		end
		--
		--  attack
		--
		attackAllNewTargetsInRange(Line3D(previousPos,(movment>length and maxPos or currentPos)) )
		--
		if movment>length then
			self.stop()
			comUnit:sendTo("SteamStats","MaxDamageDealt",damageDone)
			return false
		end
		model:rotateAroundPoint(Vec3(0,0,1),Vec3(),-Core.getDeltaTime()*math.pi*3.0)
		node:setLocalPosition(currentPos)
		
		return true
	end
	
	return self
end