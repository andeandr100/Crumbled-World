require("Game/Abilities/slowFieldTargetArea.lua")

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
	local abilityLast = 12
	local abilityTargetArea = 4
	local abilitySlowPercentage = 0.4
	local abilityActivated = -100
	local abilityGlobalPosition = Vec3()
	
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
	
	local function worldCollision()
		--get collision line from camera and mouse pos
		local cameraLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos());
		--Do collision agains playerWorld and return collided mesh
		local playerNode = this:findNodeByType(NodeId.playerNode)
		collisionMesh = playerNode:collisionTree(cameraLine, NodeId.islandMesh);
		--Check if collision occured and check that we have an island which the mesh belongs to
		if collisionMesh and collisionMesh:findNodeByType(NodeId.island) then
			collPos = cameraLine.endPos;
			return true, collPos;
		end		
		return false, Vec3();
	end
	
	function self.update()
		
		if keyBindSlowAbility:getPressed() then
			boostSelected = true
		end
		
		if Core.getInput():getMouseDown(MouseKey.right) or Core.getInput():getKeyDown(Key.escape) or keyBindBoostBuilding:getPressed() or keyAttackAbility:getPressed() then
			boostSelected = false
		end
		
		
		if boostSelected and abilityHasBeenUsedThisWave == false then
				
			local collision, globalposition = worldCollision()
			slowFieldTargetArea.update(collision, globalposition, false)
			
			if collision and Core.getInput():getMouseDown(MouseKey.left) then
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