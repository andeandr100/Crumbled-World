require("NPC/state.lua")
require("Game/timedValues.lua")
require("Game/particleEffect.lua")
--this = SceneNode()

TheSoul = {}
function TheSoul.new()
	local self = {}
	local hp = 1.0
	local maxHp = 1.0
	local mover = nil
	local slowPercentage = 0.0
	local speedBase = 2.0
	local speedCurrent = 2.0
	local fire = TimedValues.new()
	local fireDamageScoreTo = {}	--LUA_INDEX to who the damage should go
	local fireDPSImmunity = false
	local fireResistance = 0.0
	local slowImmunity = false
	local electricResistance = 0.0
	local markOfGoldImmunity = false
	local markOfGold = TimedValues.new()
	local markOfGoldOwner = TimedValues.new()
	local markOfDeath = TimedValues.new()
	local markOfDeathOwner = TimedValues.new()
	local slow = TimedValues.new()
	local slowOwner = TimedValues.new()
	local canBlockBlade = false
	local shieldAngle = 0.0
	local shieldAngleFront = true
	local bloodInfo
	local canBeKilled = true
	local comUnit					--comUnit = ComUnit()
	local bloodSpray
	local markOfDeathModel = nil
	--local soulManager
	local globalNode
	--fire
	local pointLightFlame
	local flameEffect
	--electric
	local electricEffect
	local pointLightElectric
	--sound
	local soundShieldHitt
	--local soundHitt = SoundNode("npc_hitt2")
	
	-- function:	defaultStats
	-- purpose:		set default stats for the npc
	function self.defaultStats(php,pmover,pspeedBase)
		hp = php
		maxHp = php
		mover = pmover --soul.mover = NodeMover()
		speedBase = pspeedBase
		speedCurrent = pspeedBase
	end
	-- function:	setParticleNode
	-- purpose:		sets the node where the particle effect will be added to
	function self.setParticleNode(node,localPos,markOffset)
		markOfDeathOffset = markOffset
		firePosition = localPos
		globalNode = node
		--globalNode:addChild(soundHitt)
	end
	-- function:	enableBlood
	-- purpose:		enable a blood effect for when the npc is reciving physical damage
	function self.enableBlood(particleEffectName,particleScale,offset)
		bloodInfo = {enabled=true,pName=particleEffectName,pScale=particleScale,pOffset=offset}
	end
	-- function:	setFlameVisible
	-- purpose:		enable/disable the fire effect on the npc
	local function setFlameVisible(setVisible)
		if setVisible then
			if not pointLightFlame then
				--create the particle effect
				pointLightFlame = PointLight(Vec3(0,0.4,0),Vec3(2.0,1.15,0.0),2.0)
				pointLightFlame:setCutOff(0.15)
				globalNode:addChild(pointLightFlame)
				--
				flameEffect = ParticleSystem(ParticleEffect.NPCFlame)
				globalNode:addChild(flameEffect)
				flameEffect:activate(firePosition)
			else
				--make it visible
				pointLightFlame:setVisible(true)
				flameEffect:setVisible(true)
			end
		else
			--hide the effect
			if pointLightFlame then
				pointLightFlame:setVisible(false)
				flameEffect:setVisible(false)
			end
		end
	end
	-- function:	setElectricVisible
	-- purpose:		enable/disable the electric effect on the npc
	local function setElectricVisible(setVisible)
		if setVisible then
			if not pointLightElectric then
				--create the effect, and make it visible
				electricEffect = ParticleSystem(ParticleEffect.NPCElectric)
				globalNode:addChild(electricEffect)
				electricEffect:activate(firePosition+Vec3(0,0.75,0))
				--
				pointLightElectric = PointLight(Vec3(0,0.4,0),Vec3(0.0,0.6,1.2),2.0)
				pointLightElectric:setCutOff(0.15)
				globalNode:addChild(pointLightElectric)
			else
				--make the effect visible
				pointLightElectric:setVisible(true)
				electricEffect:setVisible(true)
			end
		elseif pointLightElectric then
			--hide the particle effect
			if pointLightElectric then
				pointLightElectric:setVisible(false)
				electricEffect:setVisible(false)
			end
		end
	end
	-- function:	setShieldAngle
	-- purpose:		creates a angle where no physicle damage can be received fron
	--angle=[0,math.pi]
	--front==true if shield facing forward
	function self.setShieldAngle(angle,front)
		shieldAngle = angle
		shieldAngleFront = front
	end
	-- function:	setCanBlockBlade
	-- purpose:		if the unit will destroy blades when hitt
	function self.setCanBlockBlade(param)
		canBlockBlade = param
		if not soundShieldHitt then
			soundShieldHitt = SoundNode("shield_block")
			globalNode:addChild(soundShieldHitt)
		end
	end
	-- function:	setResistance
	-- purpose:		to set resistance/immunity to the elements fire/electric
	--fire = [0,INF]  fire>1.0 will heal npc when taking fire damage
	--fireDPSImmunity == if true npc can't burn
	--slowImmunity == if true npc can't be slowed
	--electric = [0,INF]  electric>1.0 will heal npc when taking electric damage
	function self.setResistance(fireRes,fireDPSImun,slowImun,electricRes)
		fireResistance = fireRes
		fireDPSImmunity = fireDPSImun
		electricResistance = electricRes
		slowImmunity = slowImun
	end
	-- function:	setMarkOfGoldImmunity
	-- purpose:		to set immunity agains gold gain
	function self.setMarkOfGoldImmunity(set)
		markOfGoldImmunity = set
	end
	-- function:	soulHasDied
	-- purpose:		turn off effects as the npc has died
	local function soulHasDied()
		if fire.isNotEmpty() then
			setFlameVisible(false)
		end
		if slow.isNotEmpty() then
			setElectricVisible(false)
		end
	end
	-- function:	takeDamage
	-- purpose:		remove hp from the npc and manage all amplifing effects
	-- returns:		the amount of damage the npc has actually taken
	local function takeDamage(amount)
		if hp>0.0 then
			--npc is still alive
			local multiplyer = (markOfDeath.isEmpty() and 1.0 or 1.0+markOfDeath.getMaxKey())
			amount = amount * multiplyer
			hp = hp - amount
			if hp>0.0 then
				return amount
			end
			soulHasDied()
			return hp+amount--returns the amount of health before taking damage, as the npc is now dead
		else
			--npc was already dead
			hp = -1.0
			return 0.0
		end
	end
	-- function:	handleAttacked
	-- purpose:		handeling damage taken, and send info to scripts that want's to know the resault
	local function handleAttacked(damage,fromIndex)
		local dmgTaken = takeDamage(tonumber(damage))
		local dmgLost = tonumber(damage) - dmgTaken
		if markOfDeath.isNotEmpty() then
			local per = markOfDeath.getMaxKey()
			comUnit:sendTo(markOfDeathOwner.getValue(per),"dmgDealtMarkOfDeath",tostring(dmgTaken*(per/(1.0+per))) )
			comUnit:sendTo(fromIndex,"dmgDealt",tostring(dmgTaken*(1.0/(1.0+per))) )
		else
			comUnit:sendTo(fromIndex,"dmgDealt",tostring(dmgTaken))
		end
		comUnit:sendTo(fromIndex,"dmgLost",tostring(dmgLost))
	end
	-- function:	isAttackedBlocked
	-- purpose:		check if the attack was blocked
	-- returns:		returns true if the attack was blocked
	local function isAttackedBlocked(fromIndex)
		if shieldAngle<0.1 then
			return false
		else
			local attackerPos = Core.getBillboard(fromIndex):getVec3("Position")
			local attackVec = attackerPos-this:getGlobalPosition()
			local velocity = mover:getCurrentVelocity()
			local angle = Vec2(attackVec.x,attackVec.z):angle(Vec2(velocity.x,velocity.z))
			if shieldAngleFront then
				return shieldAngle>=angle
			else
				return(math.pi-shieldAngle)<=angle 
			end
		end
	end
	-- function:	handleAttackedPhysical
	-- purpose:		manage everything when the npc is hitt by a physical attack
	local function handleAttackedPhysical(damage,fromIndex)
		if isAttackedBlocked(fromIndex) then
			--attack is blocked
			local attackerPos = Core.getBillboard(fromIndex):getVec3("Position")
			local attackVec = attackerPos-this:getGlobalPosition()
			--	sparks on shield
			if not blockSparks then
				blockSparks = ParticleSystem( ParticleEffect.SparksWhenBlocking )
				this:addChild(blockSparks)
				blockSparks:activate( Vec3(0,1,0)+(attackVec*0.3) )
			end
			attackVec = (this:getGlobalMatrix():inverseM()*attackerPos):normalizeV()
			blockSparks:activate( Vec3(0,1,0)+(attackVec*0.3) )
			--sound
			soundShieldHitt:play(0.6,false)
		else
			--npc will take damage
			handleAttacked(damage,fromIndex)
			-- blood effect on hitt
			if bloodInfo then
				if not bloodSpray then
					bloodSpray = ParticleSystem( ParticleEffect[bloodInfo.pName] )
					globalNode:addChild(bloodSpray)
					bloodSpray:setScale(bloodInfo.pScale)
					bloodSpray:activate(firePosition+Vec3(0,0.2,0),(Core.getBillboard(fromIndex):getVec3("Position")-this:getGlobalPosition()):normalizeV())
				end
				--right,height,length
				bloodSpray:setEmitterPos(firePosition+(math.randomVec3()*0.15)+bloodInfo.pOffset)--,(Core.getBillboard(fromIndex):getVec3("Position")-this:getGlobalPosition()):normalizeV())
				bloodSpray:resetSpawnTimer()
				bloodSpray:setVisible(true)
			end
			--sound
			--soundHitt:play(1,false)
		end
	end
	-- function:	handleAttackedBlade
	-- purpose:		manage if the npc was attacked by a blade
	local function handleAttackedBlade(damage,fromIndex)
		if canBlockBlade then
			local pos = this:getGlobalPosition()
			local dir = mover:getCurrentVelocity()
			comUnit:sendTo(fromIndex,"bladeBlocked",tostring(pos.x)..";"..pos.y..";"..pos.z..";"..dir.x..";"..dir.y..";"..dir.z)
			--some damage will be dealt to the shield unit (game decision)
			handleAttacked(damage,fromIndex)
		else
			--it is just a norml physical attack
			handleAttackedPhysical(damage,fromIndex)--to use effect from the physical attacks
		end
	end
	-- function:	handleDestroyShield
	-- purpose:		destroys the shield if carried
	local function handleDestroyShield(param,fromIndex)
		if canBlockBlade then
			local meshList = this:findAllNodeByTypeTowardsLeaf({NodeId.animatedMesh, NodeId.mesh})
			for i=1, #meshList do
				local subMesh = meshList[i]:splitMeshByBoneName("shield")
				if subMesh  then	
					local body = RigidBody(this:findNodeByType(NodeId.island),subMesh,mover and mover:getCurrentVelocity() or Vec3())
					body:setTimeOut(30)
				end
			end
			canBlockBlade = false
			shieldAngle = 0.0
			--Achievement
			comUnit:sendTo("SteamAchievement","ShieldSmasher","")
		end
	end
	-- function:	handleAttackedElectric
	-- purpose:		handle attacks that is electricity based
	local function handleAttackedElectric(damage,fromIndex)
		local dmg = (damage*(1.0-electricResistance))
		if dmg>0.0 then 
			handleAttacked(dmg,fromIndex)
		else
			hp = hp - dmg
			hp = math.min(hp,maxHp*2.0)--max health can be 2x the original hp value
		end
		if hp<0 then
			comUnit:sendTo("SteamStats","KilledWithElectricity",1)
		end
	end
	-- function:	handleAttackedFire
	-- purpose:		handle attack that is instant fire damage
	local function handleAttackedFire(damage,fromIndex,notDirectly)
		local dmg = (damage*(1.0-fireResistance))
		--
		if notDirectly==nil then
			comUnit:sendTo(fromIndex, "swarmBallHitt", "hitt")
		end
		--
		if dmg>0 then 
			handleAttacked(dmg,fromIndex)
		else
			hp = hp - dmg
			hp = math.min(hp,maxHp*2.0)--max health can be 2x the original hp value
		end
		if hp<0 then
			comUnit:sendTo("SteamStats","KilledWithFire",1)
		end
	end
	-- function:	handleAttackedFireDPS
	-- purpose:		handles attacks that is fire damage over time
	local function handleAttackedFireDPS(param,fromIndex)
		if fireDPSImmunity==false and (param.type=="fire" or not isAttackedBlocked(fromIndex)) then
			local DPS = param.DPS
			local timer = param.time
			
			DPS = tonumber(DPS)
			timer = tonumber(timer)
			--activate burning effect, if not imune and not active
			if fire.isEmpty() then
				setFlameVisible(true)
				flameEffect:setSpawnRate(1.0)
			end
			--set the info
			fire.set(DPS,timer)--by adding it even if imune to fire, we can get the exakt damage that would have been recived over time, like when fireballs hit repetedly on target this would have been over represented
			fireDamageScoreTo[math.floor(DPS)] = fromIndex--close enough
		end
	end
	-- function:	handleClearFire
	-- purpose:		all fire effect has been quenched
	local function handleClearFire(param)
		fire.clear()
		setFlameVisible(false)
	end
	-- function:	handleMarkOfGold
	-- purpose:		makes the npc worht more when killed
	local function handleMarkOfGold(param,fromIndex)
		if markOfGoldImmunity==false and (param.type=="area" or not isAttackedBlocked(fromIndex)) then
			--print("soul.handleMarkOfGold\n")
			local goldGain = tonumber(param.goldGain)
			local timer = tonumber(param.timer)
			markOfGold.set(goldGain,timer)
			markOfGoldOwner.set(goldGain,fromIndex)
			--markOfGoldOwner.set(percentage,fromIndex)
		end
	end
	-- function:	functionName
	-- purpose:		
	function self.getGoldGainAdd()
		if markOfGold.isNotEmpty() then
			return markOfGold.getMaxValue()
		end
		return 0
	end
	-- function:	functionName
	-- purpose:		
	function self.fixGoldEarned()
		if markOfGold.isNotEmpty() then
			if markOfGoldOwner.isNotEmpty() then
				comUnit:sendTo(markOfGoldOwner.getMaxValue(),"extraGoldEarned",markOfGold.getMaxKey())
				local p1 = this:getGlobalPosition()
				Core.addDebugLine(Line3D(p1,p1+Vec3(0,3,0)),3.0,Vec3(1,1,0))
			else
				local p1 = this:getGlobalPosition()
				Core.addDebugLine(Line3D(p1,p1+Vec3(0,3,0)),3.0,Vec3(1,0,0))
			end
		end
	end
	-- function:	functionName
	-- purpose:		
	function self.hasGoldGain()
		if markOfGold.isNotEmpty() then
			if markOfGoldOwner.isNotEmpty() then
				return true
			end
		end
		return false
	end
	-- function:	functionName
	-- purpose:		
	local function handleMarkOfDeath(param,fromIndex)
		if param.type=="area" or not isAttackedBlocked(fromIndex) then
			local percentage = param.per
			local timer = param.timer
			percentage = tonumber(percentage)
			timer = tonumber(timer)
			markOfDeath.set(percentage,timer)
			markOfDeathOwner.set(percentage,fromIndex)
			if not markOfDeathModel then
				markOfDeathModel = Core.getModel("skeleton_head.mym")
				markOfDeathModel:setLocalPosition(markOfDeathOffset)
				markOfDeathModel:setColor(Vec4(1.25,0.25,0.25,1.0))--there is no alpha, because we don't use a forwardShader
				globalNode:addChild(markOfDeathModel)
			else
				markOfDeathModel:setVisible(true)
			end
		end
	end
	-- function:	functionName
	-- purpose:		
	local function handleSlow(param,fromIndex)
		if param.type=="mineCart" or ((param.type=="electric" or not isAttackedBlocked(fromIndex)) and not slowImmunity) then
			local percentage = param.per
			local timer = param.time
			percentage = tonumber(percentage)
			timer = tonumber(timer)
			--activate burning effect, if not active
			if slow.isEmpty() and param.type~="mineCart" then
				setElectricVisible(true)
			end
			--set the info
			slow.set(percentage,timer)
			if param.type~="mineCart" then
				slowOwner.set(percentage,fromIndex)
			end
		end
	end
	-- function:	functionName
	-- purpose:		
	local function handleMaxSpeed(param,fromIndex)
		local len = (this:getGlobalPosition()-param.pos):length()
		local per = len>param.range and 1.0 or len/param.range
		local speed = (param.mSpeed*(1.0-per)) + (speedBase*per)
		mover:setMaxWalkSpeed(speed)
	end
	-- function:	functionName
	-- purpose:		
	function self.soulSetCanDie(set)
		canBeKilled = set
	end
	-- function:	functionName
	-- purpose:		can this soul die
	function self.canDie()
		return canBeKilled
	end
	-- function:	functionName
	-- purpose:		
	function self.getHp()
		return hp
	end
	-- function:	functionName
	-- purpose:		
	function self.getMaxHp()
		return maxHp
	end
	-- function:	functionName
	-- purpose:		
	function self.setHp(num)
		hp = num
	end
	--initiate callbacks
	function self.setComSystem(pcomUnit,comUnitTable)
		comUnit = pcomUnit
		comUnitTable["attack"] = handleAttacked
		comUnitTable["attackPhysical"] = handleAttackedPhysical
		comUnitTable["attackBlade"] = handleAttackedBlade
		comUnitTable["destroyShield"] = handleDestroyShield
		comUnitTable["attackElectric"] = handleAttackedElectric
		comUnitTable["attackFire"] = handleAttackedFire
		comUnitTable["attackFireDPS"] = handleAttackedFireDPS
		comUnitTable["clearFire"] = handleClearFire
		comUnitTable["markOfDeath"] = handleMarkOfDeath
		comUnitTable["markOfGold"] = handleMarkOfGold
		comUnitTable["slow"] = handleSlow
		comUnitTable["maxSpeed"] = handleMaxSpeed
		comUnitTable["shield"] = self.handleShield
	end
	function self.update()
		local deltaTime = Core.getDeltaTime()
		local retState = 0
		-- retState = retState + 1	[alive]
		-- retState = retState + 2	[burning]
		-- retState = retState + 4	[electrecuted]
		-- retState = retState + 8	[markOfDeath]
		-- retState = retState + 16	[shielded]
		--
		--	handle shield
		--
		--
		--	handle rotation spirits
		--
--		if spirtiEffect then
--			spirtiEffect.time = spirtiEffect.time + (Core.getDeltaTime()*2.0)
--			spirtiEffect.mat:rotate(Vec3(0,1,0),spirtiEffect.time)
--			spirtiEffect.effect:setLocalPosition(spirtiEffect.mat*Vec3(0.4,0,0)+Vec3(0,math.sin(spirtiEffect.time*0.5),0))
--		end
		--
		--  handle fire damage
		--
		if fire.isNotEmpty() and hp>0 then
			--damge the soul
			local damageToBeDone = fire.getMaxKey()*deltaTime
			local fireDamageFromIndex = fireDamageScoreTo[math.floor(fire.getMaxKey())]
			if not fireDPSImmunity then
				handleAttacked(damageToBeDone,fireDamageFromIndex)
			else
				handleAttackedFire(damageToBeDone*0.5,fireDamageFromIndex)--if fire imune then the soul will heal over time
			end
			--update the timer
			if not fireDPSImmunity then--particle effect only available if not immune
				fire.update()
				if fire.isEmpty() then
					--if we lost the last fire damage, remove the effect
					setFlameVisible(false)
					flameEffect:setSpawnRate(0)
				else
					--we are still burning
					retState = retState + state.burning--[burning]
				end
			end
			if hp<0 then
				comUnit:sendTo("SteamStats","KilledWithFire",1)
			end
		end
		--
		--  handle markOfGold
		--
		if markOfGold.isNotEmpty() then
			markOfGold.update()
			if markOfGold.isNotEmpty() then
				retState = retState + state.markOfGold
			end
		end
		--
		--  handle markOfDeath
		--
		if markOfDeath.isNotEmpty() then
			markOfDeath.update()
			if markOfDeath.isNotEmpty() then
				retState = retState + state.markOfDeath
			else
				markOfDeathModel:setVisible(false)
			end
		end
		--
		--	handle slow
		--
		if slow.isNotEmpty() then
			slow.update()
			if slow.isEmpty() or slowOwner.isEmpty() then
				setElectricVisible(false)
			else
				retState = retState + state.electrecuted--[electrecuted]
			end
		end
		if slowPercentage~=slow.getMaxKey() then
			print("slowPercentage "..slowPercentage)
			slowPercentage = slow.getMaxKey()
			mover:setWalkSpeed(speedBase * (1.0-slowPercentage))
		end
		if hp>0 then
			retState = retState + state.alive--[alive]
		end
		return retState
	end
	function self.transferAllActiveEffectsTo(toIndex)
		if toIndex then
			--fireDPS
			if fire.isNotEmpty() then
				for key,item in pairs(fire.getTable()) do
					local fromIndex = fireDamageScoreTo[math.floor(item.key)]
					comUnit:sendToSpoof(fromIndex,toIndex,"attackFireDPS",key..";"..item.val)
				end
			end
			--markOfDeath
			if markOfDeath.isNotEmpty() then
				for key,item in pairs(markOfDeath.getTable()) do
					local fromIndex = markOfDeathOwner.getValue(item.key)
					comUnit:sendToSpoof(fromIndex,toIndex,"markOfDeath",key..";"..item.val)
				end
			end
			--slow
			if slow.isNotEmpty() then
				for key,item in pairs(slow.getTable()) do
					local fromIndex = slowOwner.getValue(item.key)
					comUnit:sendToSpoof(fromIndex,toIndex,"slow",key..";"..item.val)
				end
			end
		end
	end
	function self.manageDeath()
		if fire.isNotEmpty() then
			--damge the soul
			local dmgTimer = fire.getMaxValue()
			local dmgLost = fire.getMaxKey()*dmgTimer
			comUnit:sendTo(fireDamageScoreTo[math.floor(fire.getMaxKey())],"dmgLost",tostring(dmgLost))
		end
		if markOfDeathModel then
			markOfDeathModel:setVisible(false)
		end
		--stop effect
		setFlameVisible(false)
		setElectricVisible(false)
		--unlink effects
		if flameEffect then
			globalNode:removeChild(flameEffect)
			globalNode:removeChild(pointLightFlame)
		end
		if electricEffect then
			globalNode:removeChild(electricEffect)
			globalNode:removeChild(pointLightElectric)
		end
		if bloodSpray then
			bloodSpray:getParent():removeChild(bloodSpray)
		end
	end
	
	return self
end