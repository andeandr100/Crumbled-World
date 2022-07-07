require("Game/Abilities/slowFieldTargetArea.lua")

--this = SceneNode()
SlowfieldAbility = {}
function SlowfieldAbility.new(inCamera, inComUnit)
	local self = {}
	local camera = inCamera
	local comUnit = inComUnit
	local slowFieldTargetArea = slowFieldTargetArea.new()
	local keyBindBoostBuilding = Core.getBillboard("keyBind"):getKeyBind("SlowAbility")
	local slowFieldButtonPressed = false
	local abilityHasBeenUsedThisWave = false
	
	local lastSlowEffectSent = 0
	local abilityLast = 12
	local abilityTargetArea = 4
	local abilitySlowPercentage = 0.4
	local abilityActivated = 0
	local abilityGlobalPosition = Vec3()
	
	function self.getSlowFieldHasBeenUsedThisWave()
		return abilityHasBeenUsedThisWave
	end
	
	function self.setSlowFieldButtonPressed()
		slowFieldButtonPressed = true
	end
	
	function self.waveChanged(param)
		abilityHasBeenUsedThisWave = false
	end
	
	function self.getSlowFieldKeyBind()
		return keyBindBoostBuilding;
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
		
		if Core.getInput():getMouseDown(MouseKey.right) or Core.getInput():getKeyDown(Key.escape) then
			slowFieldButtonPressed = false
		end
		
		local boostSelected = slowFieldButtonPressed or keyBindBoostBuilding:getHeld()
		
		if boostSelected and abilityHasBeenUsedThisWave == false then
				
			local collision, globalposition = worldCollision()
			slowFieldTargetArea.update(collision, globalposition)
			
			if collision and Core.getInput():getMouseDown(MouseKey.left) then
				abilityActivated = Core.getGameTime()
				abilityHasBeenUsedThisWave = true
				abilityGlobalPosition = globalposition
				slowFieldButtonPressed = false
			end

		else
			if Core.getGameTime() - abilityActivated < 12 then
				slowFieldTargetArea.update(true, abilityGlobalPosition)
				
				if Core.getGameTime() - lastSlowEffectSent > 0.1 then
					lastSlowEffectSent = Core.getGameTime()
					comUnit:broadCast(abilityGlobalPosition,abilityTargetArea,"slow",{per=abilitySlowPercentage,time=0.25,type="electric"})
				end
			else
				slowFieldTargetArea.update(false, Vec3())
			end
		end
	end
	
	return self
end