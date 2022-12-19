--this = SceneNode()

BoostAbility = {}
function BoostAbility.new(inCamera, inComUnit)
	local self = {}
	
	local camera = inCamera
	local comUnit = inComUnit
	local keyBindSlowAbility = Core.getBillboard("keyBind"):getKeyBind("SlowAbility")
	local keyBindBoostBuilding = Core.getBillboard("keyBind"):getKeyBind("BoostAbility")
	local keyAttackAbility = Core.getBillboard("keyBind"):getKeyBind("AttackAbility")
	local showBoostableTowers = false
	local buildingNodeBillboard = Core.getBillboard("buildings")
	local billboardStats = Core.getBillboard("stats")
	local towerHasBeenBoostedThisWave = false
	local boostSelected = false
	local billboardStats = Core.getBillboard("stats")
	
	function self.getBoostKeyBind()
		return keyBindBoostBuilding;
	end
	
	function self.getBoostHasBeenUsedThisWave()
		return towerHasBeenBoostedThisWave
	end
	
	function self.setBoostButtonPressed()
		boostSelected = true
	end
	
	function self.setAnotherAbilityButtonPressed()
		boostSelected = false
	end
	
	function self.restartWave()
		towerHasBeenBoostedThisWave = false
	end
	
	function self.waveChanged(param)
		towerHasBeenBoostedThisWave = false
	end

	local function setGlowColor(node, color)
		if node then
			local meshList = node:findAllNodeByTypeTowardsLeaf({NodeId.mesh, NodeId.animatedMesh})
			for aKey, mesh in pairs(meshList) do
				local shader = mesh:getShader()
				local definitions = shader:getDefinitions()
				definitions[#definitions+1] = "GLOW"
				
				shader = Core.getShader( shader:getName(), definitions )
				mesh:setShader( shader )
				mesh:setUniform(shader, "glowColor", color )		
			end
		end
	end
	
	local function setNodeNotBoostable(node)
		if node then
			local meshList = node:findAllNodeByTypeTowardsLeaf({NodeId.mesh, NodeId.animatedMesh})
			for aKey, mesh in pairs(meshList) do
				local shader = mesh:getShader()
				local definitions = shader:getDefinitions()
				local i = 1
				while #definitions >= i do
					if definitions[i] == "GLOW" then
						table.remove(definitions, i)
					else
						i = i + 1
					end
				end
				mesh:setShader( Core.getShader( mesh:getShader():getName(), definitions ) )
			end
		end
	end
	
	local function showAllTowerThatCanBeBoosted(show)
		if showBoostableTowers == show then
			return
		end
		
		local playerNode = this:findNodeByType(NodeId.playerNode)
		local buildNode = playerNode:findNodeByType(NodeId.buildNode)
		local buildingList = buildNode and buildNode:getBuildingList() or {}
		--buildNode = buildNode()

		showBoostableTowers = show
		for key, node in pairs(buildingList) do
			if show then
				local script = node:getScriptByName("tower")
				local scriptBilboard = script and script:getBillboard() or nil
				if script and scriptBilboard and scriptBilboard:getString("Name") ~= "Wall tower" and scriptBilboard:getString("Name") ~= "Bank tower" and scriptBilboard:getBool("isNetOwner") then
					setGlowColor( node, Vec3(0.05,0.15,0.05) )
				end
			else
				setNodeNotBoostable(node)
			end
		end	
	end
	
	local function handleUpgrade(building,buyMessage,paramMessage)
		if building then
			local buildingScript = building:getScriptByName("tower")
			local clientId = building:getPlayerNode():getClientId()
			comUnit:sendTo("builder"..clientId, "buildingSubUpgrade", tabToStrMinimal({netId=buildingScript:getNetworkName(),cost=0,msg=buyMessage,param=paramMessage}))
		end
	end
	
	local function boostTower(building)
		--Boost the tower
		--Note the boost is upgrade2 in the tower upgrades
		local buildingScript = building:getScriptByName("tower")
		
		if building and buildingScript then	
			local buildingBillBoard = buildingScript:getBillboard()
			
			if buildingBillBoard and buildingBillBoard:getBool("isNetOwner") then
				handleUpgrade(building, "upgrade2", "1")
			end
		end
	end
	
	local function isMouseInMainPanel()
		return billboardStats:getPanel("MainPanel") == Core.getPanelWithMouseFocus()
	end
	
	function self.update()
		if buildingNodeBillboard:getBool("inBuildMode") == false then
			
			if keyBindBoostBuilding:getPressed() then
				boostSelected = true
			end
			
			if keyBindSlowAbility:getPressed() or keyAttackAbility:getPressed() then
				boostSelected = false
			end
			

			buildingNodeBillboard:setBool("AbilitesBeingPlaced", boostSelected)
			showAllTowerThatCanBeBoosted(boostSelected and towerHasBeenBoostedThisWave==false)
			
			if Core.getInput():getMouseDown(MouseKey.left) and isMouseInMainPanel() == false then
				boostSelected = false
			end
			
			if towerHasBeenBoostedThisWave == false and Core.getInput():getMouseDown(MouseKey.left) and boostSelected and buildingNodeBillboard:getBool("canBuildAndSelect") and isMouseInMainPanel()then

				local playerNode = this:findNodeByType(NodeId.playerNode)
				local buildNode = playerNode:findNodeByType(NodeId.buildNode)
				--buildNode = buildNode()
				if buildNode then
					
					local building = buildNode:getBuldingFromLine(camera:getWorldLineFromScreen(Core.getInput():getMousePos()))
					if building then
						boostTower(building)
						setGlowColor( building, Vec3(0.05,0.15,0.05) )
						towerHasBeenBoostedThisWave = true
						buildingNodeBillboard:setBool("AbilitesBeingPlaced", false)
					end
				end

			end
		else
			showAllTowerThatCanBeBoosted(false)
		end
		
		if Core.getInput():getMouseDown(MouseKey.left) or Core.getInput():getMouseDown(MouseKey.right) or Core.getInput():getKeyDown(Key.escape) then
			boostSelected = false
		end
	end
	
	return self
end