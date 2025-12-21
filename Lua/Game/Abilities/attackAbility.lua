require("Game/Abilities/attackTargetArea.lua")
require("Game/Abilities/attackEffect.lua")
require("Game/Abilities/worldCollision.lua")
require("Game/gameValues.lua")

--this = SceneNode()
AttackAbility = {}
function AttackAbility.new(inCamera, inComUnit, isUserControlled)
	local self = {}
	local camera = inCamera
	local comUnit = inComUnit
	local AttackArea = AttackArea.new()
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local attackEffect = AttackEffect.new(camera, targetSelector, inComUnit)
	local boostSelected = false
	local abilityHasBeenUsedThisWave = false
	local statsBilboard = Core.getBillboard("stats")
	local userControlled = isUserControlled
	
	local damageScale = 1.2
	local abilityDetonationRange = 6
	local abilityActivated = 0
	local abilityGlobalPosition = Vec3()
	local billboardStats = Core.getBillboard("stats")
	local mapCollision = WorldCollision.new(inCamera)
	local abilitesBeingPlacedFrameId = 0
	
	

	
	
	--Reality check will fail due to this node being built on the player node instead of the islands
	local function init()
		local campaingConfig = Core.getGlobalBillboard("MapInfo")
		if campaingConfig:getBool("isCampaign") then
			local gameValues = GameValues.new()
			local data = gameValues.getTowerAbilityValues("Passiv","comet")
			
			damageScale = data.stats.damage[data.campaingUnlockedLevel]
			abilityDetonationRange = data.stats.range[data.campaingUnlockedLevel]
		end
	end
	
	function self.getAttackHasBeenUsedThisWave()
		return abilityHasBeenUsedThisWave
	end
	
	function self.isActive()
		return boostSelected
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
	
	function self.getAbilitesBeingPlaced()
		return abilitesBeingPlacedFrameId > Core.getFrameNumber()
	end
	

	local function getDamage()
		return statsBilboard:getInt("npc_scorpion_hp") * damageScale
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
					comUnit:sendTo(targetIndex,"attack",tostring(abilityDamage * distance))
					comUnit:sendTo(targetIndex,"physicPushIfDead",abilityGlobalPosition)
				end
			end
		else
			for targetIndex,distance in pairs(targetTable) do
				comUnit:sendTo(targetIndex,"attack",tostring(abilityDamage * distance))
				comUnit:sendTo(targetIndex,"physicPushIfDead",abilityGlobalPosition)
			end
		end
	end
	
	local function mouseInGameArea()
		return billboardStats:getPanel("MainPanel") == Core.getPanelWithMouseFocus()
	end
	
	function self.isActive()
		local activeTime = Core.getGameTime() - abilityActivated
		return activeTime > 0 and activeTime < 15
	end
	
	function self.activate(globalPosition)
		abilityActivated = Core.getGameTime()
		abilityHasBeenUsedThisWave = true
		abilityGlobalPosition = globalPosition
		boostSelected = false
		attackEffect.activate(globalPosition)
		AttackArea.update(false, Vec3())
		
		targetSelector.disableRealityCheck()
	end
	
	function self.update()
		
		
		if attackEffect.update() then
			if attackEffect.impactedShieldIndex() > 0 then
				comUnit:sendTo(attackEffect.impactedShieldIndex(),"attack",tostring(getDamage() * 3))
				impact(attackEffect.impactedShieldIndex())
			else
				impact(0)
			end
		end

		if boostSelected and abilityHasBeenUsedThisWave == false then
			
			abilitesBeingPlacedFrameId = Core.getFrameNumber() + 1
				
			local collision, globalposition = mapCollision.mouseWorldCollision(false)
			
			if collision and Core.getInput():getMouseDown(MouseKey.left) and mouseInGameArea() then
				comUnit:sendNetworkSync("NetActivateAttackAbility", tostring(globalposition))
				self.activate(globalposition)
				self.setAnotherAbilityButtonPressed()
			else
				AttackArea.update(collision, globalposition)			
			end
		else
			AttackArea.update(false, Vec3())
		end
		
	end
	
	init()
	
	return self
end