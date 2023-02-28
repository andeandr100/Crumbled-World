--this = SceneNode()
--comUnit = ComUnit()
function towerBuiltSteamStats(script)
	if script then
		if script:getFileName()=="Tower/WallTower.lua" then
			local bilboardStats = Core.getBillboard("stats")
			if bilboardStats:getInt("wallTowerBuilt")==49 then
				comUnit:sendTo("SteamAchievement","Waller","")
			end
			comUnit:sendTo("SteamStats","WallTowersBuilt",1)
			comUnit:sendTo("stats","addWallTowerBuilt","")
		elseif script:getFileName()=="Tower/MinigunTower.lua" then
			comUnit:sendTo("SteamStats","MinigunTowersBuilt",1)
			comUnit:sendTo("stats","addMinigunTowerBuilt","")
		elseif script:getFileName()=="Tower/ArrowTower.lua" then
			comUnit:sendTo("SteamStats","ArrowTowersBuilt",1)
			comUnit:sendTo("stats","addArrowTowerBuilt","")
		elseif script:getFileName()=="Tower/ElectricTower.lua" then
			comUnit:sendTo("SteamStats","ElectricTowersBuilt",1)
			comUnit:sendTo("stats","addElectricTowerBuilt","")
		elseif script:getFileName()=="Tower/SwarmTower.lua" then
			comUnit:sendTo("SteamStats","SwarmTowersBuilt",1)
			comUnit:sendTo("stats","addSwarmTowerBuilt","")
		elseif script:getFileName()=="Tower/BladeTower.lua" then
			comUnit:sendTo("SteamStats","BladeTowersBuilt",1)
			comUnit:sendTo("stats","addBladeTowerBuilt","")
		elseif script:getFileName()=="Tower/missileTower.lua" then
			comUnit:sendTo("SteamStats","MissileTowersBuilt",1)
			comUnit:sendTo("stats","addMissileTowerBuilt","")
		elseif script:getFileName()=="Tower/quakerTower.lua" then
			comUnit:sendTo("SteamStats","QuakeTowersBuilt",1)
			comUnit:sendTo("stats","addQuakeTowerBuilt","")
		elseif script:getFileName()=="Tower/SupportTower.lua" then
			comUnit:sendTo("SteamStats","SupportTowersBuilt",1)
			comUnit:sendTo("stats","addSupportTowerBuilt","")
		elseif script:getFileName()=="Tower/BankTower.lua" then
			comUnit:sendTo("SteamStats","BankTowersBuilt",1)
			comUnit:sendTo("stats","addBankTowerBuilt","")
		elseif DEBUG then
			error("Tower not set for SteamStats. "..script:getFileName())
		end
	end
end

function uppgradeWallTowerTab(tab)
--	print("debugData: "..tostring(tab))
	local towerScript = Core.getScriptOfNetworkName(tab[1])
	if towerScript then
		local building = towerScript:getParentNode()
		upgradeFromTowerToTower(building, tab[2], tab[3], tab[4], tab[5], tab[6], nil, true)
	end
end
function upgradeFromTowerToTower(buildingToUpgrade, buildCost, scriptName, newLocalBuildngMatrix, networkName, isOwner, playerId, disableRotatorScript)
	--buildingToUpgrade = SceneNode.new()
	--upgradeToBuilding = SCeneNode()
	
	local toTowerCost = 200
	for i=1, #buildings do
		local toTowerScript = buildings[i]:getScriptByName("tower")
		if toTowerScript:getFileName() == scriptName then
			toTowerCost = toTowerScript:getBillboard():getFloat("cost")
		end
	end

	print("\n\n\nShow Node\n")
	if scriptName and buildingToUpgrade then		
		print("scriptName"..scriptName)
		local fromTowerScript = buildingToUpgrade:getScriptByName("tower")
		--Get the cost of the wall tower
		local fromTowerCost = fromTowerScript:getBillboard():getFloat("value")
		--get the tower hull
		local towerHull = fromTowerScript:getBillboard():getVectorVec2("hull2dGlobal")
		

		--Clean up the wall tower from the map
		
		scriptList = buildingToUpgrade:getAllScript()			
		for i=1,#scriptList do
			buildingToUpgrade:removeScript(scriptList[i]:getName())
		end
		
		while buildingToUpgrade:getChildSize() > 0 do
			local child = buildingToUpgrade:getChildNode(0)
			child:setVisible(false)
			buildingToUpgrade:removeChild(child:toSceneNode())
		end
		
		--the wall tower has been removed from the map
		--Set the new script on the node to load it in to memmory
		local buildingScript = buildingToUpgrade:loadLuaScript(scriptName)
		if buildingScript then
			buildingScript:setScriptNetworkId(networkName)
			if newLocalBuildngMatrix then
				buildingToUpgrade:setLocalMatrix(newLocalBuildngMatrix)
			end
			buildingToUpgrade:update();
			buildingScript:getBillboard():setVectorVec2("hull2dGlobal", towerHull)
			buildingScript:getBillboard():setBool("IsBuildOnAWallTower", true)
			buildingScript:setName("tower")
			
			
			if isOwner then
				local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
				comUnit:sendTo("builder"..node:getClientId(), "damgeTowerBuilt", "0")
				if buildingScript:getBillboard():getString("TargetArea") == "cone" and disableRotatorScript ~= true then
					buildingToUpgrade:loadLuaScript("Game/buildRotater.lua")
				end
				--
				towerBuiltSteamStats(buildingScript)
				--remove cost of the new tower
				if toTowerCost > fromTowerCost then 
					--from wallTower to otherTower (upgrading)
					local buildCost = math.max( toTowerCost - fromTowerCost, 0)
					comUnit:sendTo("stats","removeGold",tostring( buildCost))
				else
					--from otherTower to wallTower (selling)
					comUnit:sendTo("stats","addGoldNoScore",tostring( math.max( fromTowerCost - toTowerCost, 0)))
					local buildingValueLost = fromTowerScript:getBillboard():getDouble("totalCost")-fromTowerScript:getBillboard():getDouble("value")
					comUnit:sendTo("stats","addGoldLostFromSelling",tostring(buildingValueLost))
					comUnit:sendTo("stats","addTowersSold","")
				end
				comUnit:sendTo(buildingScript:getIndex(),"NetOwner","YES")
			else
				comUnit:sendTo(buildingScript:getIndex(),"NetOwner","NO")
			end
			
			local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
			comUnit:sendTo("builder"..node:getClientId(), "damgeTowerBuilt", tostring(playerId))
		end
	end
end