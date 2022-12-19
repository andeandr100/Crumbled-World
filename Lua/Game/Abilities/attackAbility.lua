require("Game/Abilities/attackTargetArea.lua")
require("Game/Abilities/attackEffect.lua")
require("Game/Abilities/worldCollision.lua")

--this = SceneNode()
AttackAbility = {}
function AttackAbility.new(inCamera, inComUnit)
	local self = {}
	local camera = inCamera
	local comUnit = inComUnit
	local AttackArea = AttackArea.new()
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local attackEffect = AttackEffect.new(camera, targetSelector, inComUnit)
	local keyBindSlowAbility = Core.getBillboard("keyBind"):getKeyBind("SlowAbility")
	local keyBindBoostBuilding = Core.getBillboard("keyBind"):getKeyBind("BoostAbility")
	local keyAttackAbility = Core.getBillboard("keyBind"):getKeyBind("AttackAbility")
	local boostSelected = false
	local abilityHasBeenUsedThisWave = false
	local statsBilboard = Core.getBillboard("stats")
	
	local lastSlowEffectSent = 0
	local abilityLast = 12
	local abilityTargetArea = 3.5
	local abilityDetonationRange = 6
	local abilitySlowPercentage = 0.4
	local abilityActivated = 0
	local abilityGlobalPosition = Vec3()
	local billboardStats = Core.getBillboard("stats")
	local mapCollision = WorldCollision.new(inCamera)
	
	
	--Reality check will fail due to this node being built on the player node instead of the islands
	
	
	function self.getAttackHasBeenUsedThisWave()
		return abilityHasBeenUsedThisWave
	end
	
	function self.setAttackButtonPressed()
		boostSelected = true
	end
	
	function self.setAnotherAbilityButtonPressed()
		boostSelected = false
	end
	
	function self.restartWave()
		abilityHasBeenUsedThisWave = false
		attackEffect.stop()
	end
	
	function self.waveChanged()
		abilityHasBeenUsedThisWave = false
	end
	
	function self.getAttackKeyBind()
		return keyAttackAbility;
	end
	
	
	local function getDamage()
		return statsBilboard:getInt("npc_scorpion_hp")
	end
	
	local function impact(shieldIndex)
	
		targetSelector.disableRealityCheck()
		targetSelector.setPosition(abilityGlobalPosition)
		targetSelector.setRange(abilityDetonationRange)
		targetSelector.selectAllInRangeCalculateDisatance()
		local targetTable = targetSelector.getAllTargets()
		local abilityDamage = getDamage()
		
		if shieldIndex > 0 then
			local shieldPosition = targetSelector.getShieldPositionFromShieldIndex(shieldIndex)
			
			for targetIndex,distance in pairs(targetTable) do
				local targetPosition = targetSelector.getTargetPosition(targetIndex)
				
				--if the NPC is outside the shield then do damage calculation
				if (shieldPosition-targetPosition):length() > SHIELD_RANGE then
					comUnit:sendTo(targetIndex,"attack",tostring(abilityDamage * 1.2 * distance))
					comUnit:sendTo(targetIndex,"physicPushIfDead",abilityGlobalPosition)
				end
			end
		else
			for targetIndex,distance in pairs(targetTable) do
				comUnit:sendTo(targetIndex,"attack",tostring(abilityDamage * 1.2 * distance))
				comUnit:sendTo(targetIndex,"physicPushIfDead",abilityGlobalPosition)
			end
		end
	end
	
	local function mouseInGameArea()
		return billboardStats:getPanel("MainPanel") == Core.getPanelWithMouseFocus()
	end
	
	function self.update()
		
		
		
		if keyAttackAbility:getPressed() then
			boostSelected = true
		end
		
		if Core.getInput():getMouseDown(MouseKey.right) or Core.getInput():getKeyDown(Key.escape) or keyBindSlowAbility:getPressed() or keyBindBoostBuilding:getPressed() then
			boostSelected = false
		end
		
		if attackEffect.update() then
			if attackEffect.impactedShieldIndex() > 0 then
				comUnit:sendTo(attackEffect.impactedShieldIndex(),"attack",tostring(getDamage() * 3))
				impact(attackEffect.impactedShieldIndex())
			else
				impact(0)
			end
		end
		
--		if targetSelector.getIndexOfShieldCovering(attackEffect.getPosition()) > 0 then
--			abort("shield collision")
--		end

		if Core.getInput():getMouseDown(MouseKey.left) and mouseInGameArea() == false then
			boostSelected = false
		end
		
		if boostSelected and abilityHasBeenUsedThisWave == false then
				
			local collision, globalposition = mapCollision.mouseWorldCollision(false)
			
			if collision and Core.getInput():getMouseDown(MouseKey.left) and mouseInGameArea() then
				abilityActivated = Core.getGameTime()
				abilityHasBeenUsedThisWave = true
				abilityGlobalPosition = globalposition
				boostSelected = false
				attackEffect.activate(globalposition)
				AttackArea.update(false, Vec3())
				
				targetSelector.disableRealityCheck()
			else
				AttackArea.update(collision, globalposition)			
			end
		else
			AttackArea.update(false, Vec3())
		end
	end
	
	return self
end