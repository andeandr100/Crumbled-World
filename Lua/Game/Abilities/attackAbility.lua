require("Game/Abilities/attackTargetArea.lua")
require("Game/Abilities/attackEffect.lua")

--this = SceneNode()
AttackAbility = {}
function AttackAbility.new(inCamera, inComUnit)
	local self = {}
	local camera = inCamera
	local comUnit = inComUnit
	local AttackArea = AttackArea.new()
	local attackEffect = AttackEffect.new()
	local keyBindAbility = Core.getBillboard("keyBind"):getKeyBind("AttackAbility")
	local abilityButtonPressed = false
	local abilityHasBeenUsedThisWave = false
	
	local lastSlowEffectSent = 0
	local abilityLast = 12
	local abilityTargetArea = 4
	local abilitySlowPercentage = 0.4
	local abilityActivated = 0
	local abilityGlobalPosition = Vec3()
	
	function self.getAttackHasBeenUsedThisWave()
		return abilityHasBeenUsedThisWave
	end
	
	function self.setAttackButtonPressed()
		abilityButtonPressed = true
	end
	
	function self.waveChanged(param)
		abilityHasBeenUsedThisWave = false
	end
	
	function self.getAttackKeyBind()
		return keyBindAbility;
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
			abilityButtonPressed = false
		end
		
		if Core.getInput():getMouseDown(MouseKey.left) then
			local collision, globalposition = worldCollision()
			attackEffect.activate(globalposition)
		else
			attackEffect.update()
		end
		
		
		local boostSelected = abilityButtonPressed or keyBindAbility:getHeld()
		
		if boostSelected and abilityHasBeenUsedThisWave == false then
				
			local collision, globalposition = worldCollision()
			AttackArea.update(collision, globalposition)
			
			if collision and Core.getInput():getMouseDown(MouseKey.left) then
				abilityActivated = Core.getGameTime()
				abilityHasBeenUsedThisWave = true
				abilityGlobalPosition = globalposition
				abilityButtonPressed = false
			end

		else
			if Core.getGameTime() - abilityActivated < 12 then
				AttackArea.update(true, abilityGlobalPosition)
				
				if Core.getGameTime() - lastSlowEffectSent > 0.1 then
					lastSlowEffectSent = Core.getGameTime()
					comUnit:broadCast(abilityGlobalPosition,abilityTargetArea,"slow",{per=abilitySlowPercentage,time=0.25,type="electric"})
				end
			else
				AttackArea.update(false, Vec3())
			end
		end
	end
	
	return self
end