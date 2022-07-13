require("Game/Abilities/attackTargetArea.lua")
require("Game/Abilities/attackEffect.lua")

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
	local keyBindAbility = Core.getBillboard("keyBind"):getKeyBind("AttackAbility")
	local abilityButtonPressed = false
	local abilityHasBeenUsedThisWave = false
	local statsBilboard = Core.getBillboard("stats")
	
	local lastSlowEffectSent = 0
	local abilityLast = 12
	local abilityTargetArea = 4
	local abilityDetonationRange = 6
	local abilitySlowPercentage = 0.4
	local abilityActivated = 0
	local abilityGlobalPosition = Vec3()
	
	
	
	--Reality check will fail due to this node being built on the player node instead of the islands
	
	
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
	
	local function getDamage()
		return statsBilboard:getInt("npc_scorpion_hp") * 100
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
	
	function self.update()
		
		if Core.getInput():getMouseDown(MouseKey.right) or Core.getInput():getKeyDown(Key.escape) then
			abilityButtonPressed = false
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
		
		local boostSelected = abilityButtonPressed or keyBindAbility:getHeld()
		if boostSelected and abilityHasBeenUsedThisWave == false then
				
			local collision, globalposition = worldCollision()
			
			if collision and Core.getInput():getMouseDown(MouseKey.left) then
				abilityActivated = Core.getGameTime()
				abilityHasBeenUsedThisWave = true
				abilityGlobalPosition = globalposition
				abilityButtonPressed = false
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