require("Game/Abilities/boostTargetArea.lua") 
require("Game/Abilities/worldCollision.lua")
require("Game/gameValues.lua")
--this = SceneNode()

BoostAbility = {}
function BoostAbility.new(inCamera, inComUnit)
	local self = {}
	
	local camera = inCamera
	local comUnit = inComUnit
	local showBoostableTowers = false
	local buildingNodeBillboard = Core.getBillboard("buildings")
	local billboardStats = Core.getBillboard("stats")
	local abilityHasBeenUsedThisWave = false
	local boostSelected = false
	local billboardStats = Core.getBillboard("stats")
	local abilityActivated = -100
	local abilityGlobalPosition = Vec3()
	local abilitesBeingPlacedFrameId = 0
	
	local mapCollision = WorldCollision.new(inCamera)
	local buildNode = this:getRootNode():findNodeByType(NodeId.buildNode)
	--buildNode = BuildNode()
	local targetArea = nil
	local boostRadius = 2.0

	local function init()

		local campaingConfig = Core.getGlobalBillboard("MapInfo")
		if campaingConfig:getBool("isCampaign") then
			local gameValues = GameValues.new()
			local data = gameValues.getTowerAbilityValues("Passiv","boost")
			boostRadius = data.stats.boostRange[data.campaingUnlockedLevel]
		end
		
		targetArea = boostTargetArea.new(buildNode, boostRadius)
	end
	
	function self.getBoostHasBeenUsedThisWave()
		return abilityHasBeenUsedThisWave
	end
	
	function self.isActive()
		local activeTime = Core.getGameTime() - abilityActivated
		return activeTime > 0 and activeTime < 10
	end
	
	function self.setBoostButtonPressed()
		boostSelected = true
	end
	
	function self.setAnotherAbilityButtonPressed()
		boostSelected = false
	end
	
	function self.getAbilitesBeingPlaced()
		return abilitesBeingPlacedFrameId > Core.getFrameNumber()
	end
	
	function self.restartWave()
		abilityHasBeenUsedThisWave = false
		abilityActivated = -100
	end
	
	function self.waveChanged(param)
		abilityHasBeenUsedThisWave = false
	end

--	local function setGlowColor(node, color)
--		if node then
--			local meshList = node:findAllNodeByTypeTowardsLeaf({NodeId.mesh, NodeId.animatedMesh})
--			for aKey, mesh in pairs(meshList) do
--				local shader = mesh:getShader()
--				local definitions = shader:getDefinitions()
--				definitions[#definitions+1] = "GLOW"
--				
--				shader = Core.getShader( shader:getName(), definitions )
--				mesh:setShader( shader )
--				mesh:setUniform(shader, "glowColor", color )		
--			end
--		end
--	end
--	
--	local function setNodeNotBoostable(node)
--		if node then
--			local meshList = node:findAllNodeByTypeTowardsLeaf({NodeId.mesh, NodeId.animatedMesh})
--			for aKey, mesh in pairs(meshList) do
--				local shader = mesh:getShader()
--				local definitions = shader:getDefinitions()
--				local i = 1
--				while #definitions >= i do
--					if definitions[i] == "GLOW" then
--						table.remove(definitions, i)
--					else
--						i = i + 1
--					end
--				end
--				mesh:setShader( Core.getShader( mesh:getShader():getName(), definitions ) )
--			end
--		end
--	end
	
	
	local function handleUpgrade(building,buyMessage,paramMessage)
		if building then
			local buildingScript = building:getScriptByName("tower")
			local clientId = building:getPlayerNode():getClientId()
			comUnit:sendTo("builder"..clientId, "buildingSubUpgrade", tabToStrMinimal({netId=buildingScript:getNetworkName(),cost=0,msg=buyMessage,param=paramMessage}))
		end
	end
	
	local function boostTower(building)
		--Boost the tower
		local buildingScript = building:getScriptByName("tower")
		
		if building and buildingScript then	
			local buildingBillBoard = buildingScript:getBillboard()
			
			if buildingBillBoard and buildingBillBoard:getBool("isNetOwner") then
				handleUpgrade(building, "boost", "1")
			end
		end
	end
	
	local function isMouseInMainPanel()
		return billboardStats:getPanel("MainPanel") == Core.getPanelWithMouseFocus()
	end
	
	function self.update()

		if boostSelected and abilityHasBeenUsedThisWave == false then
			local collision, globalposition = mapCollision.mouseWorldCollision(true)
			targetArea.update(collision, globalposition, false)
			
			if buildingNodeBillboard:getBool("inBuildMode") == false then
				abilitesBeingPlacedFrameId = Core.getFrameNumber() + 1

				if Core.getInput():getMouseDown(MouseKey.left) and boostSelected and buildingNodeBillboard:getBool("canBuildAndSelect") and isMouseInMainPanel()then
					local playerNode = this:findNodeByType(NodeId.playerNode)
					local buildNode = playerNode:findNodeByType(NodeId.buildNode)
					--buildNode = buildNode()
					if buildNode then
						local buildings = buildNode:getAllBuildingFromPoint(globalposition,boostRadius)
						for i=1, #buildings do
							if buildings[i] then
								boostTower(buildings[i])
								--setGlowColor( buildings[i], Vec3(0.05,0.15,0.05) )
								abilityHasBeenUsedThisWave = true
								abilityGlobalPosition = globalposition
								abilityActivated = Core.getGameTime()
								boostSelected = false
							end
						end
					end
	
				end
			end
		
		else
			if self.isActive() then
				targetArea.update(true, abilityGlobalPosition, true)
			else
				targetArea.update(false, Vec3(), false)
			end
		end
		
	end
	
	init()
	
	return self
end