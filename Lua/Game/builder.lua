require("Game/builderUpgrader.lua")
require("Game/builderFunctions.lua")
require("Game/mapInfo.lua")
--require("Game/autoBuilder.lua")
--this = BuildNode()
local buildCounter = 0
local readyToPlay = {}
local towerChangeState = 0

--TODO
--In multiplayer add transaction id when buying selling tower, to ensure that towers can only be built in a correct order,
--With this 2 towers cant be buil in the same spot, bechause the user with the higher transaction id can't buil until he got
--The build event from the other user.

local transactionQueue = {wait=0,currentState="build"}

function destroy()
	if buildingBillboard then
		buildingBillboard:setBool("Ready", false)
	end
end

function worldCollision()
	--get collision line from camera and mouse pos
	local cameraLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos());
	--Do collision agains playerWorld and return collided mesh
	collisionMesh = playerNode:collisionTree(cameraLine, NodeId.islandMesh);
	--Check if collision occured and check that we have an island which the mesh belongs to
	if collisionMesh and collisionMesh:findNodeByType(NodeId.island) then
		collPos = cameraLine.endPos;
		return true;
	end		
	return false;
end

function changeSelectedTower( newTower )
--	if enableTheCrasher then
--		abort()
--	end
	if currentTower then
		currentTower:setVisible(false);
	end
	currentTower = newTower;
	if currentTower then
		currentTower:setVisible(true);
		local model = currentTower:findNodeByType(NodeId.model);
		if model then
			model:setColor(Vec3(1));
		end
	end
	if currentTower then
		buildingBillboard:setBool("inBuildMode", true)
	else
		buildingBillboard:setBool("inBuildMode", false)
	end
end


function updateSelectedTowerToBuild()
--	if Core.getInput():getKeyPressed(Key.l) then
--		enableTheCrasher = true
--	end
	for i = 1, 9 do
		if keyBind[i] and keyBind[i]:getPressed() then
			currentTowerIndex = i;
			changeSelectedTower( buildings[i] );
		end
	end
	
	if (keyDeselect and keyDeselect:getPressed()) or esqKeyBind:getPressed() then
		currentTowerIndex = 0;
		changeSelectedTower( nil );
	end

	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message] ~= nil then
			if msg.message == "NetSellTower" then
				transactionQueue[#transactionQueue+1] = {type="sell",parameter=msg.parameter,func=comUnitTable[msg.message]}
			elseif msg.message == "NET" then
				transactionQueue[#transactionQueue+1] = {type="build",parameter=msg.parameter,func=comUnitTable[msg.message]}
			elseif msg.message == "NETWU" then
				transactionQueue[#transactionQueue+1] = {type="build",parameter=msg.parameter,func=comUnitTable[msg.message]}
			elseif msg.message == "NETTP" then
				transactionQueue[#transactionQueue+1] = {type="build",parameter=msg.parameter,func=comUnitTable[msg.message]}
			elseif msg.message == "buildingSubUpgrade" then
				transactionQueue[#transactionQueue+1] = {type="upgrade",parameter=msg.parameter,func=comUnitTable[msg.message]}
			elseif msg.message == "NetUpgradeWallTower" then
				--easy protection against tower who is upgraded, sold, upgraded and sold ower and ower again
				transactionQueue[#transactionQueue+1] = {type="towerChange"..towerChangeState,parameter=msg.parameter,func=comUnitTable[msg.message]}
				towerChangeState = towerChangeState + 1
			else
				comUnitTable[msg.message](msg.parameter)
			end
		else
			print("comUnit:hasMessage() == "..tostring(msg).."\n")
--			num = tonumber(msg.parameter)
--			if num and num > 0 and num <= #buildings then
--				currentTowerIndex = num
--				changeSelectedTower( buildings[num] );
--			end
		end
	end
	
	--print("Wait: "..transactionQueue.wait)
	transactionQueue.wait = transactionQueue.wait - 1
	local run = #transactionQueue > 0 and transactionQueue.wait < 0
	while run do
		if transactionQueue.currentState == transactionQueue[1].type then
			print("Transaction type: "..transactionQueue[1].type)
			transactionQueue[1].func(transactionQueue[1].parameter)
			table.remove(transactionQueue, 1)
			run = #transactionQueue > 0
		else
			print("Wait 4 frames")
			run = false
			transactionQueue.currentState = transactionQueue[1].type
			transactionQueue.wait = 4
		end
	end

--transactionQueue = {frame=0,currentState="build"}
end

function getBuildingId(building)
	for i=1, #buildings do
		if buildings[i] == building then
			return i
		end
	end
	return 0
end

function increaseBuildBuildingCount()
	buildingBillboard:setInt( "NumBuildingBuilt", buildingBillboard:getInt("NumBuildingBuilt") + 1 )
end

function changeBuilding(towerId)
	local towerId = tonumber(towerId)
	if towerId > 0 and towerId <= #buildings then
		currentTowerIndex = towerId;
		changeSelectedTower( buildings[towerId] );
	end
end

function restartMap()
	if this:clearBuildings() then
		noMoneyIcon:setVisible(false)
		buildingBillboard:setInt( "NumBuildingBuilt", 0)
		buildingBillboard:setBool("Ready", false)
		readyToPlay[0] = false
	else
		restartListener:pushEvent("reloadeMap")
	end
end

function create()
	if this:getNodeType() == NodeId.buildNode then
		Core.setScriptNetworkId("Builder")
		camera = ConvertToCamera( this:getRootNode():findNodeByName("MainCamera") );
		
		--this is the node named "player 1 node"
		print("------------------------------\n")
		comUnit = Core.getComUnit()
		comUnit:setCanReceiveTargeted(true)
		comUnit:setName("builder")
		
		--functions from autobuilder.lua
		comUnitTable = {}
--		comUnitTable["upgradeBuilding"] = upgradeBuilding
		comUnitTable["changeBuilding"] = changeBuilding
		comUnitTable["damgeTowerBuilt"] = damgeTowerBuilt
		comUnitTable["NET"] = syncBuild
		comUnitTable["NETWU"] = UpgradeWallBuilding
		comUnitTable["NETTP"] = UpgradeWallBuilding
		comUnitTable["SELLTOWER"] = sellTower
		comUnitTable["NetSellTower"] = netSellTower
		comUnitTable["UpgradeWallTower"] = upgradeWallTower
		comUnitTable["NetUpgradeWallTower"] = netUpgradeWallTower
		comUnitTable["buildingSubUpgrade"] = towerUpgrade
		
	
		restartListener = Listener("Restart")
		restartListener:registerEvent("restart", restartMap)
		
		stateBillboard = Core.getGameSessionBillboard("state")
		
		
		mapInfo = MapInfo.new()
		playerCount = Core.isInMultiplayer() and mapInfo.getPlayerCount() or 1
	
		print("test 1\n")
		keyBinds = Core.getBillboard("keyBind")
		keyBind = {}
		for i = 1, 9 do
			print("building "..tostring(i).."\n")
			keyBind[i] = keyBinds:getKeyBind("Building " .. i)
		end
		
		esqKeyBind = KeyBind("Menu", "control", "toogle menu")
		esqKeyBind:setKeyBindKeyboard(0, Key.escape)
		
		print("test 2\n")
		keyUse = keyBinds:getKeyBind("Place")
		keyDeselect = keyBinds:getKeyBind("Deselect")
		
		
		builderFunctions = BuilderFunctions.new(keyBinds, camera)
		
		rotationTime = 0
		
		print("create\n")
	
		local rootNode = this:getRootNode()
		towerWorld = rootNode:addChild(SceneNode())
		buildingBillboard = Core.getBillboard("buildings")
		buildingBillboard:setInt("NumBuildingBuilt", 0)
		buildingBillboard:setBool("inBuildMode", false)
		buildingBillboard:setBool("canBuildAndSelect", true)
		buildingBillboard:setBool("Ready", false)
		
		soundNode = SoundNode("towerBuild")
		soundNode:setLocalSoundPLayLimit(7)
		rootNode:addChild(soundNode)
		
		towerBuiltListener = Listener("builder")
		
		readyToPlay[0] = false
		
		buildings = {}
		local numBuildings = 1
		while buildingBillboard:exist(tostring(numBuildings)) do
			buildings[numBuildings] = towerWorld:addChild( SceneNode() );
			local scriptName = buildingBillboard:getString(tostring(numBuildings));
			local luaScript = buildings[numBuildings]:loadLuaScript(scriptName);
			if luaScript then
				luaScript:setName("tower");
				--buildings[numBuildings]:setIsStatic(false)
				buildings[numBuildings]:update()
				buildings[numBuildings]:setVisible(false)
				local canBePlacedHere = this:tryToSnapBuildingInToPlace(buildings[numBuildings], SceneNode(), Vec3(), 0.0 )
			else
				buildings[numBuildings] = nil;
				abort();
			end
	
			numBuildings = numBuildings + 1;
		end
		
--		AutoBuilder.setBuildingList(buildings)
		
		currentTower = nil;
	
		rotation = 0;
		playerNode = this:getParent();
	
		input = Core.getInput();
		
		noMoneyIcon = Sprite(Core.getTexture("icon_table.tga"))
		noMoneyIcon:setUvCoord(Vec2(0.875,0),Vec2(1,0.0625))
		noMoneyIcon:setSize(Vec2(0.05) * Core.getScreenResolution().y)
		noMoneyIcon:setVisible(false)
		noMoneyIcon:setAnchor(Anchor.MIDDLE_CENTER)
		
		if camera then
			camera:add2DScene(noMoneyIcon)
			local work = this:createWork();
			work:setWeight(9)
			work:setName("Builder")
			work:addDependency(camera:getWork())
			
		else
			camera = nil;
			print("No camera was found");
		end
		
		
		print("BUILDER:::RETURN == true\n")
		return true
	else
		print("------------------------------\n")
		--move this script from the current PlayerNode to a BuildNode
		local builderNode = this:addChild(BuildNode())
		--this:removeScript(this:getCurrentScript():getName());
		builderNode:loadLuaScript(this:getCurrentScript():getFileName()):setName("BuilderScript")
		print("BUILDER:::RETURN == false\n")
		return false
	end
end

function getTowerBoundingBoxFromMeshes( tower )
	local meshList = currentTower:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
	for i = 1, #meshList, 1 do
		--meshList:item(i):setColor(color)
		Core.addDebugBox(meshList[i]:getGlobalBoundingBox(),0.001,Vec3(1,0,0))
	end
end

function syncBuild(param)
	buildTowerNetworkCallback(totable(param))
end

function damgeTowerBuilt(param)
	if not readyToPlay[tonumber(param)] then
		readyToPlay[tonumber(param)] = true
		updateIsAllreadyToPlay()
	end
	
end




function netUpgradeWallTower(param)
	--print("netUpgradeWallTower()\n")
	local tab = totable(param)
	local building = Core.getScriptOfNetworkName(tab.netName):getParentNode()
	uppgradeWallTower(building, 0, tab.upgToScripName, nil, tab.tName, false, tab.playerId )
	
	comUnit:sendTo("SelectedMenu", "updateSelectedTower", "")
end

function upgradeWallTower(param)
	
	local tab = totable(param)
	local building = Core.getScriptOfNetworkName(tab.netName):getParentNode()
	uppgradeWallTower(building, tab.buildCost, tab.upgToScripName, nil, tab.tName, true, tab.playerId )
	comUnit:sendTo("SelectedMenu", "updateSelectedTower", "")
	
	if Core.isInMultiplayer() then
		comUnit:sendNetworkSyncSafe("NetUpgradeWallTower",param)
	end
end



function towerUpgrade(param)
	local tab = totable(param)
	comUnit:sendTo(Core.getScriptOfNetworkName(tab.netId):getIndex(),tab.msg,"")
end





--this function can be called localy or by ower network
function netSellTower(paramNetworkName)

	local buildingScript = Core.getScriptOfNetworkName(paramNetworkName)
	local netWorkName = (buildingLastSelected and buildingLastSelected:getScriptByName("tower")) and buildingLastSelected:getScriptByName("tower"):getNetworkName() or ""
	if buildingScript then
		local billBoard = buildingScript:getBillboard()
		local buildingToSell = buildingScript:getParentNode()
		local buildingValue = billBoard:getFloat("value")
		--print("buildingValue == "..buildingValue.."\n")
		if this:removeBuilding( buildingToSell ) then
			if billBoard:getBool("isNetOwner") then
				comUnit:sendTo("stats", "addGold", tostring(buildingValue))
			end
			--comUnit:sendTo("builder", "soldTower", tostring(buildingId))
			
			if netWorkName == paramNetworkName then
				print("\n\nSelected menu is in hidding because tower was sold\n\n")
				form:setVisible(false)
				targetArea.hiddeTargetMesh()
			end
		else
			abort()
		end
	else
		abort()
	end

end

--this function is called localy by scripts
function sellTower(param)
	netSellTower(param)
	if Core.isInMultiplayer() then
		comUnit:sendNetworkSyncSafe("NetSellTower",param)
	end
end

function UpgradeWallBuilding(param)
	local tab = totable(param)
	--changeSelectedTower( buildings[tab.buildTowerIndex] )
	local buildingToUpgradeScript = Core.getScriptOfNetworkName(tab.netName)
	local buildingToUpgrade = buildingToUpgradeScript:getParentNode()
	local buildingScript = buildings[tab.buildTowerIndex]:getScriptByName("tower")
	local towerBilboard = buildingScript:getBillboard()
	--get the cost of the new tower
	local buildCost = towerBilboard:getFloat("cost")
	--get the script file name
	local scriptName = buildingScript:getFileName()
	
	if towerBilboard:getString("Name") ~= "Wall tower" and not readyToPlay[tab.playerId] then
		readyToPlay[tab.playerId] = true
		updateIsAllreadyToPlay()
	end
	
	uppgradeWallTower(buildingToUpgrade, buildCost, scriptName, tab.matrix, tab.tName, false)
end

--"{ buildingId = 2, islandId = 0, localPos = Vec3(6.29053593,0,-6.13610077), rotation = 0}"
function buildTowerNetworkCallback(tab)
	--local tab = totable(input)
	local towerToBuild = buildings[tab.buildingId]
	
--	print("Player index: "..fromIndex.." Built a tower <---------------")
	
	building = this:buildFromBuildInfo(towerToBuild, tab)
	if building then
		local script = building:getScriptByName("tower")
		script:setScriptNetworkId(tab.tName)
		comUnit:sendTo(script:getIndex(),"NetOwner","NO")
		local towerBilboard = script:getBillboard()
		
		building:setSceneName(towerBilboard:getString("Name"))
		building:createWork()
		increaseBuildBuildingCount()
		
		if towerBilboard:getString("Name") ~= "Wall tower" then
			readyToPlay[tab.playerId] = true
		end
		
		soundNode:play(1.0, false)
		towerBuiltListener:pushEvent("built")
		
		updateIsAllreadyToPlay()
	else
		print("failed to place building")
		abort()
	end
end
function getNewTowerName()
	buildCounter = buildCounter + 1
	return "T"..Core.getNetworkClient():getClientId().."_"..buildCounter
end

function updateIsAllreadyToPlay()
	if not buildingBillboard:getBool("Ready") then
		if Core.isInMultiplayer() then
			local users = Core.getNetworkClient():getConnected()
			print("users: "..tostring(users).."\n")
			local allReady = true
			
			for i=1, #users do
				if not readyToPlay[users[i].playerId] and users[i].playerId <= playerCount then
					allReady = false
				end
			end
			
			print("Player count: "..playerCount)
			print("readyToPlay: "..tostring(readyToPlay).."\n")
			
			buildingBillboard:setBool("Ready", allReady)
			
		elseif readyToPlay[0] == true then
			buildingBillboard:setBool("Ready", true)
		end
	end
end

function update()
	
	if Core.getInput():getKeyHeld(Key.lshift) or stateBillboard:getBool("inMenu") then
		noMoneyIcon:setVisible(false)
		builderFunctions.renderTargetArea("",nil,nil)
		if currentTower then
			currentTower:setVisible(false)
		end	
		builderFunctions.updateSelectedTower(nil)
		return true		
	end

	updateSelectedTowerToBuild();
	rotation = builderFunctions.updateBuildingRotation(rotation);
	--print( "num built tower: "..buildingBillboard:getInt("NumBuildingBuilt").."\n")
	
	if currentTower then
		buildingBillboard:setBool("inBuildMode", true)
	else
		buildingBillboard:setBool("inBuildMode", false)
	end
	
	--set outline on the last seleceted tower, this is totaly seperate from selected menu selected tower
	--Byt the same tower should be selected
	builderFunctions.updateSelectedTower(currentTower)
	
	--currentTower = SceneNode()
	if currentTower and worldCollision() then
		local island = collisionMesh:findNodeByTypeTowardsRoot(NodeId.island)
		local canBePlacedHere = this:tryToSnapBuildingInToPlace(currentTower, collisionMesh, collPos, rotation );
		if  Core.getPlayerId() ~= island:getPlayerId() and island:getPlayerId() > 0 and Core.getPlayerId() > 0 then
			canBePlacedHere = false;
		end
		local script = currentTower:getScriptByName("tower")
		local towerBilboard = script:getBillboard()
		local targetAreaName = towerBilboard:getString("TargetArea")
		local buildingMatrix = this:getCurrentGlobalTowerMatrix()
		local buildCost = towerBilboard:getFloat("cost")
		local gold = Core.getBillboard("stats"):getDouble("gold")
		
		comUnit:sendTo(script:getIndex(),"checkRange","")
		
		local towerMatrix = this:getTargetIsland():getGlobalMatrix() * this:getLocalIslandMatrix()
		if canBePlacedHere and keyUse and keyUse:getPressed() and buildCost <= gold then
			building = this:TryToBuild()
			if building then
				local script = building:getScriptByName("tower")
				
				local towerName = getNewTowerName()
				script:setScriptNetworkId(towerName)
				comUnit:sendTo(script:getIndex(),"NetOwner","YES")
				
				if Core.isInMultiplayer() then
					local tab = this:getBuildInfo()--{islandId=island:getIslandId(),localPos = island:getGlobalMatrix():inverseM() * collPos, rotation=rotation, buildingId = getBuildingId(currentTower), tName=towerName}
					tab.buildingId = getBuildingId(currentTower)
					tab.tName=towerName
					tab.playerId = Core.getPlayerId()
					comUnit:sendNetworkSyncSafe("NET",tabToStrMinimal(tab))
				end
				
				building:setSceneName(towerBilboard:getString("Name"))
				building:createWork()
				increaseBuildBuildingCount()
				--successfully built tower, time to pay
				
--				AutoBuilder.addBuilding(currentTower, collisionMesh, collPos, rotation, building)
				
				
				towerBuiltSteamStats(script)
				comUnit:sendTo("stats","removeGold",tostring(buildCost))
				
				if targetAreaName == "cone" then
					--Add retarget script to building node
					building:loadLuaScript("Game/buildRotater.lua")
					changeSelectedTower(nil)
				end
				
				--make usre that the wav of enemies can start
				if towerBilboard:getString("Name") ~= "Wall tower" then
					readyToPlay[0] = true
					readyToPlay[Core.getPlayerId()] = true
					updateIsAllreadyToPlay()
				end
				soundNode:play(1.0, false)
				
				towerBuiltListener:pushEvent("built")
			end
		elseif not canBePlacedHere then
			local camLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
			local building = this:getNearestBuildingFromLine(camLine)
			
			if building and Collision.lineSegmentPointLength2(camLine, building:getGlobalPosition()) < 2.0 then
				local buildingScript = building:getScriptByName("tower")					
				local buildingBillBoard = buildingScript:getBillboard()
				
				local a=32
				if towerBilboard:getString("Name") ~= "Wall tower" and buildingBillBoard:getString("Name") == "Wall tower" and buildingBillBoard:getBool("isNetOwner")==true then
					canBePlacedHere = true
					local currentMatrix = towerMatrix
					towerMatrix = building:getGlobalMatrix()
					
					--Rotate the tower in 90 degrees interval
					local dotRightValue = towerMatrix:getRightVec():dot(currentMatrix:getAtVec())
					if dotRightValue > 0.5 then
						towerMatrix:createMatrix( towerMatrix:getRightVec(), towerMatrix:getUpVec() )
					elseif dotRightValue < -0.5 then
						towerMatrix:createMatrix( -towerMatrix:getRightVec(), towerMatrix:getUpVec() )
					elseif towerMatrix:getAtVec():dot(-currentMatrix:getAtVec()) > 0.0 then
						towerMatrix:createMatrix( -towerMatrix:getAtVec(), towerMatrix:getUpVec() )
					end
					towerMatrix:setPosition(building:getGlobalPosition())
					
					local wallTowerScript = building:getScriptByName("tower")
					--Get the cost of the wall tower
					local wallTowerCost = wallTowerScript:getBillboard():getFloat("cost")
					--update this specific tower location cost
					buildCost = buildCost - wallTowerCost
					if keyUse and keyUse:getPressed() and wallTowerCost <= gold then
						--upgrade the building
--						AutoBuilder.changeBuilding(building, currentTower, building:findNodeByTypeTowardsRoot(NodeId.island):getGlobalMatrix():inverseM() * towerMatrix )
						local newBuildingMatrix = building:getParent():getGlobalMatrix():inverseM() * towerMatrix
						local tab = {buildTowerIndex=currentTowerIndex, netName=buildingScript:getNetworkName(), matrix=newBuildingMatrix, tName=getNewTowerName()}
						local buildingScript = currentTower:getScriptByName("tower")
						--get the cost of the new tower
						local buildingCost = buildingScript:getBillboard():getFloat("cost")
						--get the script file name
						local scriptName = buildingScript:getFileName()
						uppgradeWallTower(building, buildingCost, scriptName, newBuildingMatrix, tab.tName, true)
						
						readyToPlay[0] = true
						readyToPlay[Core.getPlayerId()] = true
						updateIsAllreadyToPlay()					
						
						if Core.isInMultiplayer() then
							tab.playerId = Core.getPlayerId()
							comUnit:sendNetworkSyncSafe("NETWU",tabToStrMinimal(tab))
						end
						
						if targetAreaName == "cone" then
							changeSelectedTower(nil)
						end
					end
				end
			end
		end
		
		--set tower color
		builderFunctions.changeColor( currentTower, (canBePlacedHere and buildCost <= gold) and Vec4(1) or Vec4(1,0.7,0.7, 1.0))
		
		
			
		if this:getTargetIsland() and currentTower then
			currentTower:setLocalMatrix(towerMatrix);
			towerWorld:update();	
		end
		
		if buildCost > gold and currentTower then
			local screenPos = camera:getScreenCoordFromglobalPos(currentTower:getLocalPosition() + Vec3(0,1.0,0))
			noMoneyIcon:setVisible(true)
			noMoneyIcon:setLocalPosition(screenPos)
		else
			noMoneyIcon:setVisible(false)
		end
		
		--Render target area
		builderFunctions.renderTargetArea(targetAreaName, towerMatrix, towerBilboard)
		
		if currentTower then
			currentTower:setVisible(true)
		end
	else
		noMoneyIcon:setVisible(false)
		builderFunctions.renderTargetArea("",nil,nil)
		if currentTower then
			currentTower:setVisible(false)
		end			
	end
	if camera and Core.getInput():getMouseDown(MouseKey.left) then
		local building = this:getBuldingFromLine(camera:getWorldLineFromScreen(Core.getInput():getMousePos()))
		if building then
			print("found a building\n")
		end
	end
	
--	AutoBuilder.update()
	
	return true
end