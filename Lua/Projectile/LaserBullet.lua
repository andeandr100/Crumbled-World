require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
--this = SceneNode()
--Predeclaration for the inteligence

LaserBullet = {name="LaserBullet"}
function LaserBullet.new(targetSelector)
	local self = {}
	
	local speed = 25.0
	local targetIndex = 0
	local startPos = Vec3()
	local currentPos = Vec3()
	local range = 0.0
	local damage = 0.0
	local isAlive = false
	local shieldAreaIndex = 0
	local playerNode = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	
	local particleEffectBullet = ParticleSystem.new( ParticleEffect.LaserBullet )
	local particleEffectBullet2 = ParticleSystem.new( ParticleEffect.LaserBulletShine )
	local particleEffectBullet3 = ParticleSystem.new( ParticleEffect.LaserBulletcenter )
	local node = SceneNode.new()
	this:findNodeByTypeTowardsRoot(NodeId.playerNode):addChild(node)
	node:addChild(particleEffectBullet:toSceneNode())
	node:addChild(particleEffectBullet2:toSceneNode())
	node:addChild(particleEffectBullet3:toSceneNode())
	particleEffectBullet:setVisible(false)
	particleEffectBullet2:setVisible(false)
	particleEffectBullet3:setVisible(false)
	
	--targetingSystem
	targetSelector.setPosition(this:getGlobalPosition())
	
	local pointLight = PointLight.new(Vec3(0,0,0),Vec3(0,4,4),1.5)
	pointLight:setVisible(false)
	node:addChild(pointLight:toSceneNode())
	function self.init(table)
		targetIndex = table[1]
		damage = billboard:getFloat("damage")
		range = billboard:getFloat("range")
		damageWeak = billboard:getFloat("damageWeak")
		
		pointLight:setLocalPosition(Vec3())
		pointLight:setVisible(true)
		pointLight:setRange(1.5)
		
		currentPos = table[2]
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(range+1.0)
		shieldAreaIndex = targetSelector.getIndexOfShieldCovering(currentPos)
	
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
			node:getParent():removeChild(node:toSceneNode())
		end
	end
	function self.stop()
		targetIndex = 0
		particleEffectBullet:setVisible(false)
		particleEffectBullet2:setVisible(false)
		particleEffectBullet3:setVisible(false)
		pointLight:setVisible(false)
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
			end
		else
				prevAtVec = atVec
		end
		
		

		
		
		if lengthLeft-frameMovment<0.25 then
			
			local additionDamage = 0
			if damageWeak and damageWeak > 1.0 then
				local hp = targetSelector.getTargetHP()
				local maxHp = targetSelector.getTargetMaxHP()
				local hpAfterHalfDamage = math.max(hp-damage*0.5,0)
				local averageHPercantage =  hpAfterHalfDamage / maxHp
				additionDamage = damage * (1.0 - averageHPercantage) * (damageWeak-1.0)
			end
		
--			print("Laser damage " .. damage)
--			print("Laser range " .. range)
--			print("Laser damageWeak " .. damageWeak)
--			print("Laser additionDamage " .. additionDamage)
			local finalDamage = damage + additionDamage
--			print("Laser finalDamage " .. finalDamage)
			--direct hit on enemy target
			comUnit:sendTo(targetIndex,"attack",tostring(finalDamage))
--			print("LaserBullet target "..tostring(targetIndex).." Damage "..tostring(finalDamage))
			targetIndex = 0
		elseif shieldAreaIndex~=targetSelector.getIndexOfShieldCovering(currentPos) then
			--shield hitt
			targetIndex = shieldAreaIndex>0 and shieldAreaIndex or targetSelector.getIndexOfShieldCovering(currentPos)
			comUnit:sendTo(targetIndex,"attack",tostring(damage))
			local oldPosition = currentPos - atVec
			local futurePosition = currentPos + atVec
			local hitTime = "0.5"
			comUnit:sendTo(targetIndex,"addForceFieldEffect",tostring(oldPosition.x)..";"..oldPosition.y..";"..oldPosition.z..";"..futurePosition.x..";"..futurePosition.y..";"..futurePosition.z..";"..hitTime)
			targetIndex = 0
		end
		if targetSelector.isTargetAlive(targetIndex)==false then
			self.stop()
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