require("Game/Abilities/slowFieldTargetArea.lua")
require("Game/Abilities/worldCollision.lua")

--this = SceneNode()
SlowfieldAbility = {}
function SlowfieldAbility.new(inCamera, inComUnit)
	local self = {}
	local camera = inCamera
	local comUnit = inComUnit
	local slowFieldTargetArea = slowFieldTargetArea.new()
	local keyBindSlowAbility = Core.getBillboard("keyBind"):getKeyBind("SlowAbility")
	local keyBindBoostBuilding = Core.getBillboard("keyBind"):getKeyBind("BoostAbility")
	local keyAttackAbility = Core.getBillboard("keyBind"):getKeyBind("AttackAbility")
	local boostSelected = false
	local abilityHasBeenUsedThisWave = false
	
	local lastSlowEffectSent = 0
	local abilityLast = 8
	local abilityTargetArea = 4
	local abilitySlowPercentage = 0.4
	local abilityActivated = -100
	local abilityGlobalPosition = Vec3()
	local billboardStats = Core.getBillboard("stats")
	local oldCollisionPosition = Vec3()
	local mapCollision = WorldCollision.new(inCamera)
	
	function self.getSlowFieldHasBeenUsedThisWave()
		return abilityHasBeenUsedThisWave
	end
	
	function self.setSlowFieldButtonPressed()
		boostSelected = true
	end
	
	function self.setAnotherAbilityButtonPressed()
		boostSelected = false
	end
	
	function self.restartWave()
		abilityHasBeenUsedThisWave = false
		abilityActivated = -100
	end
	
	function self.waveChanged(param)
		abilityHasBeenUsedThisWave = false
	end
	
	function self.getSlowFieldKeyBind()
		return keyBindSlowAbility;
	end
	
	
	local function isMouseInMainPanel()
		return billboardStats:getPanel("MainPanel") == Core.getPanelWithMouseFocus()
	end
	
	function self.update()
		
		if keyBindSlowAbility:getPressed() then
			boostSelected = true
		end
		
		if Core.getInput():getMouseDown(MouseKey.right) or Core.getInput():getKeyDown(Key.escape) or keyBindBoostBuilding:getPressed() or keyAttackAbility:getPressed() then
			boostSelected = false
		end
		
		if Core.getInput():getMouseDown(MouseKey.left) and isMouseInMainPanel() == false then
			boostSelected = false
		end
		
		if boostSelected and abilityHasBeenUsedThisWave == false then
				
			local collision, globalposition = mapCollision.mouseWorldCollision(true)
			slowFieldTargetArea.update(collision, globalposition, false)
			
			if collision and Core.getInput():getMouseDown(MouseKey.left) and isMouseInMainPanel() then
				abilityActivated = Core.getGameTime()
				abilityHasBeenUsedThisWave = true
				abilityGlobalPosition = globalposition
				boostSelected = false
			end

		else
			local activeTime = Core.getGameTime() - abilityActivated
			if activeTime > 0 and activeTime < 12 then
				slowFieldTargetArea.update(true, abilityGlobalPosition, true)
				
				if Core.getGameTime() - lastSlowEffectSent > 0.1 then
					lastSlowEffectSent = Core.getGameTime()
					comUnit:broadCast(abilityGlobalPosition,abilityTargetArea,"slow",{per=abilitySlowPercentage,time=0.25,type="electric"})
				end
			else
				slowFieldTargetArea.update(false, Vec3(), false)
			end
		end
	end
	
	return self
end