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
			comUnit:sendTo("stats","addBillboardInt","wallTowerBuilt;1")
		elseif script:getFileName()=="Tower/MinigunTower.lua" then
			comUnit:sendTo("SteamStats","MinigunTowersBuilt",1)
			comUnit:sendTo("stats","addBillboardInt","minigunTowerBuilt;1")
			comUnit:sendTo("stats","addBillboardInt","level1;1")
		elseif script:getFileName()=="Tower/ArrowTower.lua" then
			comUnit:sendTo("SteamStats","ArrowTowersBuilt",1)
			comUnit:sendTo("stats","addBillboardInt","arrowTowerBuilt;1")
			comUnit:sendTo("stats","addBillboardInt","level1;1")
		elseif script:getFileName()=="Tower/ElectricTower.lua" then
			comUnit:sendTo("SteamStats","ElectricTowersBuilt",1)
			comUnit:sendTo("stats","addBillboardInt","electricTowerBuilt;1")
			comUnit:sendTo("stats","addBillboardInt","level1;1")
		elseif script:getFileName()=="Tower/SwarmTower.lua" then
			comUnit:sendTo("SteamStats","SwarmTowersBuilt",1)
			comUnit:sendTo("stats","addBillboardInt","swarmTowerBuilt;1")
			comUnit:sendTo("stats","addBillboardInt","level1;1")
		elseif script:getFileName()=="Tower/BladeTower.lua" then
			comUnit:sendTo("SteamStats","BladeTowersBuilt",1)
			comUnit:sendTo("stats","addBillboardInt","bladeTowerBuilt;1")
			comUnit:sendTo("stats","addBillboardInt","level1;1")
		elseif script:getFileName()=="Tower/missileTower.lua" then
			comUnit:sendTo("SteamStats","MissileTowersBuilt",1)
			comUnit:sendTo("stats","addBillboardInt","missileTowerBuilt;1")
			comUnit:sendTo("stats","addBillboardInt","level1;1")
		elseif script:getFileName()=="Tower/quakerTower.lua" then
			comUnit:sendTo("SteamStats","QuakeTowersBuilt",1)
			comUnit:sendTo("stats","addBillboardInt","quakeTowerBuilt;1")
			comUnit:sendTo("stats","addBillboardInt","level1;1")
		elseif script:getFileName()=="Tower/SupportTower.lua" then
			comUnit:sendTo("SteamStats","SupportTowersBuilt",1)
			comUnit:sendTo("stats","addBillboardInt","supportTowerBuilt;1")
			comUnit:sendTo("stats","addBillboardInt","level1;1")
		elseif DEBUG then
			error("Tower not set for SteamStats. "..script:getFileName())
		end
	end
end

function uppgradeWallTowerTab(tab)
	local building = Core.getScriptOfNetworkName(tab[1]):getParentNode()
	uppgradeWallTower(building, tab[2], tab[3], tab[4], tab[5], tab[6], nil, true)
end
function uppgradeWallTower(buildingToUpgrade, buildCost, scriptName, newLocalBuildngMatrix, networkName, isOwner, playerId, disableRotatorScript)
	--buildingToUpgrade = SceneNode()
	--upgradeToBuilding = SCeneNode()
	
	local towerCost = 200
	for i=1, #buildings do
		local towerScript = buildings[i]:getScriptByName("tower")
		if towerScript:getFileName() == scriptName then
			towerCost = towerScript:getBillboard():getFloat("cost")
		end
	end

	print("\n\n\nShow Node\n")
	if scriptName and buildingToUpgrade then		
		print("scriptName"..scriptName)
		local wallTowerScript = buildingToUpgrade:getScriptByName("tower")
		--Get the cost of the wall tower
		local wallTowerCost = wallTowerScript:getBillboard():getFloat("cost")
		--get the tower hull
		local towerHull = wallTowerScript:getBillboard():getVectorVec2("hull2dGlobal")
		

		--Clean up the wall tower from the map
		
		scriptList = buildingToUpgrade:getAllScript()			
		for i=1,#scriptList do
			buildingToUpgrade:removeScript(scriptList[i]:getName())
		end
		
		while buildingToUpgrade:getChildSize() > 0 do
			local child = buildingToUpgrade:getChildNode(0)
			child:setVisible(false)
			buildingToUpgrade:removeChild(child)
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
				comUnit:sendTo("builder", "damgeTowerBuilt", "0")
				if buildingScript:getBillboard():getString("TargetArea") == "cone" and disableRotatorScript ~= true then
					buildingToUpgrade:loadLuaScript("Game/buildRotater.lua")
				end
				--
				towerBuiltSteamStats(buildingScript)
				--remove cost of the new tower
				if towerCost > wallTowerCost then 
					comUnit:sendTo("stats","removeGold",tostring( math.max( towerCost - wallTowerCost, 0)))		
				else
					comUnit:sendTo("stats","addGoldNoScore",tostring( math.max( wallTowerCost - towerCost, 0)))	
				end
				comUnit:sendTo(buildingScript:getIndex(),"NetOwner","YES")
			else
				comUnit:sendTo(buildingScript:getIndex(),"NetOwner","NO")
			end
			
			comUnit:sendTo("builder", "damgeTowerBuilt", tostring(playerId))
		end
	end
end