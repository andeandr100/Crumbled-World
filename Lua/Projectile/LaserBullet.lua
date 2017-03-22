require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
--this = SceneNode()
--Predeclaration for the inteligence

LaserBullet = {name="LaserBullet"}
function LaserBullet.new()
	local self = {}
	
	local speed = 25.0
	local targetIndex = 0
	local startPos = Vec3()
	local currentPos = Vec3()
	local range = 0.0
	local damage = 0.0
	local damageFire = 0.0
	local damageFireTimer = 0.0
	local isAlive = false
	local shieldAreaIndex = 0
	local playerNode = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	local comUnit = Core.getComUnit()
	local billboard = Core.getBillboard()
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	
	local particleEffectBullet = ParticleSystem( ParticleEffect.LaserBullet )
	local particleEffectBullet2 = ParticleSystem( ParticleEffect.LaserBulletShine )
	local particleEffectBullet3 = ParticleSystem( ParticleEffect.LaserBulletcenter )
	local node = SceneNode()
	this:findNodeByTypeTowardsRoot(NodeId.playerNode):addChild(node)
	node:addChild(particleEffectBullet)
	node:addChild(particleEffectBullet2)
	node:addChild(particleEffectBullet3)
	particleEffectBullet:setVisible(false)
	particleEffectBullet2:setVisible(false)
	particleEffectBullet3:setVisible(false)
	
	--targetingSystem
	targetSelector.setPosition(this:getGlobalPosition())
	
	local pointLight = PointLight(Vec3(0,0,0),Vec3(0,4,4),1.5)
	pointLight:setVisible(false)
	node:addChild(pointLight)
	function self.init(table)
		targetIndex = table[1]
		damage = billboard:getFloat("damage")
		damageFire = billboard:getFloat("fireDPS")
		damageFireTimer = billboard:getFloat("burnTime")
		range = billboard:getFloat("range")
		pointLight:setLocalPosition(Vec3())
		pointLight:setVisible(true)
		pointLight:setRange(1.5)
		
		currentPos = table[2]
		shieldAreaIndex = targetSelector.getIndexOfShieldCovering(currentPos)
		
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(range+1.0)
	
		local atVec = Vec3( (targetSelector.getTargetPosition(targetIndex)-currentPos) ):normalizeV()
	
		particleEffectBullet:activate(Vec3(),atVec)
		particleEffectBullet2:activate(Vec3(),atVec)
		particleEffectBullet3:activate(Vec3())
		particleEffectBullet:setVisible(true)
		particleEffectBullet2:setVisible(true)
		particleEffectBullet3:setVisible(true)
	end
	function self.destroy()
		if node:getParent() then--as the parrent can already be destroyed, if end of the map
			node:getParent():removeChild(node)
		end
	end
	function self.update()
		local atVec = Vec3( targetSelector.getTargetPosition(targetIndex)-currentPos )
		local lengthLeft = atVec:length()
		local frameMovment = speed * Core.getDeltaTime()
		atVec:normalize()
		currentPos = currentPos + (atVec * frameMovment)
		if targetSelector.isTargetAlive(targetIndex)==false then
			--target has been lost, time to try to find new target
			targetIndex = 0
			local per = (startPos-currentPos):length()/6.0
			per = (per>1.0) and 1.0 or per
			--soulManager:updateSoul(currentPos,Vec3(),1.0)
			prevAtVec = prevAtVec or atVec
			targetSelector.setPosition(currentPos)
			targetSelector.setAngleLimits(prevAtVec,math.pi*(0.10+(0.25*per)))
			targetSelector.setRange((range+1.0)-(startPos-currentPos):length())
			targetSelector.selectAllInRange()
			targetSelector.scoreClosestToVector(prevAtVec,10)
			targetIndex = targetSelector.selectTargetAfterMaxScore()
			if targetIndex>0 then
				--new target found
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
			--direct hit on enemy target
			comUnit:sendTo(targetIndex,"attack",tostring(damage))
			comUnit:sendTo(targetIndex,"attackFireDPS",{DPS=damageFire,time=damageFireTimer,type="fire"})
			targetIndex = 0
		elseif shieldAreaIndex~=targetSelector.getIndexOfShieldCovering(currentPos) then
			--shield hitt
			targetIndex = shieldAreaIndex>0 and shieldAreaIndex or targetSelector.getIndexOfShieldCovering(currentPos)
			comUnit:sendTo(targetIndex,"attack",tostring(damage+(damageFire*0.5)))--can't do fire damage to shield
			local oldPosition = currentPos - atVec
			local futurePosition = currentPos + atVec
			local hitTime = "0.5"
			comUnit:sendTo(targetIndex,"addForceFieldEffect",tostring(oldPosition.x)..";"..oldPosition.y..";"..oldPosition.z..";"..futurePosition.x..";"..futurePosition.y..";"..futurePosition.z..";"..hitTime)
			targetIndex = 0
		end
		if targetSelector.isTargetAlive(targetIndex)==false then
			particleEffectBullet:setVisible(false)
			particleEffectBullet2:setVisible(false)
			particleEffectBullet3:setVisible(false)
			pointLight:setVisible(false)
			return false
		end
	
		--
		--  graphic part of the code
		--
		--fireball:setEmitterPos(startPos+(atVec:normalizeV()*(movment+0.5)))
		local position = currentPos + (atVec*0.5)
		particleEffectBullet:setLocalPosition(position)
		particleEffectBullet2:setLocalPosition(position)
		particleEffectBullet3:setLocalPosition(position)
		pointLight:setLocalPosition(position)
	
		--fireball:update()
		return true
	end
	
	return self
end