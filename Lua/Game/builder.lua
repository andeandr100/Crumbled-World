require("Game/builderUpgrader.lua")
require("Game/builderFunctions.lua")
require("Game/mapInfo.lua")
require("NPC/state.lua")
--require("Game/autoBuilder.lua")
--this = BuildNode()
local buildCounter = 0
local readyToPlay = {}
local towerChangeState = 0
local towerBuildInfo = {}
local waveTime = 0
local curentWave = -1
local canBuildInThisWorld = false

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
	if canBuildInThisWorld then 
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
	towerBuildInfo = {}
	if this:clearBuildings() then
		noMoneyIcon:setVisible(false)
		buildingBillboard:setInt( "NumBuildingBuilt", 0)
		buildingBillboard:setBool("Ready", false)
		readyToPlay[0] = false
	else
		restartListener:pushEvent("reloadeMap")
	end
end



--function addHighScore(data)
--	for i=1, #towerBuildInfo do
--		towerBuildInfo[i].restore = nil
--	end
--end

--this function can only be called once
function sendHightScoreToTheServer()
--	for i=1, #towerBuildInfo do
--		towerBuildInfo[i].restore = nil
--	end
	local statsBilboard = Core.getBillboard("stats")
	local highScore = Core.getHighScore()
	
	local highScoreBillBoard = Core.getGlobalBillboard("highScoreReplay")
	highScoreBillBoard:setBool("victory", true)
	highScoreBillBoard:setInt("score", statsBilboard:getInt("score"))
	highScoreBillBoard:setInt("life", statsBilboard:getInt("life"))
	highScoreBillBoard:setDouble("gold", statsBilboard:getInt("gold"))
	
	
	highScore:addScore( tabToStrMinimal(towerBuildInfo) )
end

function addRebuildTowerEvent(textData)
	local tab = totable(textData)
	towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=0,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=tab.upp,func=5},restore={para1=tab.down,func=rebuildSoldTower}}
	
	print("\n\n")
	print("---------------------------")
	print("---------------------------")
	print("---------------------------")
	print("\n\n")
	print(tostring(towerBuildInfo))
	print("\n\n")
end

function addDowngradeTower(textData)
	local tab = totable(textData)--{upp=upgradeData,down=downGradeData})
	towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=0,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=tab.upp,func=3},restore={para1=tab.down,func=upgradeWallTower,name="downgradeToWall"}}
end

function setBuildingTargetVec(textData)
	
	towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=0,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=totable(textData),func=6},restore=nil}
end

function changeArrowTowerRotation(tab)
	--{netName=script:getNetworkName(),para=tostring(direction.x)..","..direction.y..","..direction.z}
	local script = Core.getScriptOfNetworkName(tab.netName)
	comUnit:sendTo(script:getIndex(), "setRotateTarget", tab.para)
end

function addPrioEvent(intabData)
	towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=0,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=totable(intabData),func=7},restore=nil}	
end

function callPrioEvent(eventData)
	local script = Core.getScriptOfNetworkName(eventData.netName)
	if script then
		local comIndex = script:getIndex()
		if eventData.event == 1 then
			
			comUnit:sendTo(comIndex,"addState",tostring(state.ignore)..";0")
			comUnit:sendTo(comIndex,"addState",tostring(state.highPriority)..";1")
		else
			comUnit:sendTo(comIndex,"addState",tostring(state.highPriority)..";0")
			comUnit:sendTo(comIndex,"addState",tostring(state.ignore)..";1")
		end
	end
end

function DropLatestBuildingEvent(netName)
	print("\n\n")
	print("netName: " .. netName)
	print("---------------------------")
	print("---------------------------")
	print("---------------------------")
	print("\n\n")
	print(tostring(towerBuildInfo))
	print("\n\n")
	
--	 [3]={
--				restore={
--						func=nil,
--						name="WallTowerupgrade",
--						para1={
--								tName="T0_1",
--								netName="T0_2",
--								playerId=0,
--								buildCost=0,
--								upgToScripName="Tower/WallTower.lua"
--						}
--				}
	
	
	for i=#towerBuildInfo, 1, -1 do
		if towerBuildInfo[i] and towerBuildInfo[i].restore and towerBuildInfo[i].restore.para1 and towerBuildInfo[i].restore.para1.netName == netName then
			nameMaping[#nameMaping+1] = {netName.."V3",towerBuildInfo[i].restore.para1.tName}
			print("remove index: "..i)
			table.remove(towerBuildInfo, i)
			i = 0
		end
	end
	

	print("\n\n")
	print("---------------------------")
	print("---------------------------")
	print("---------------------------")
	print("\n\n")
	print(tostring(towerBuildInfo))
	print("\n\n")

end

function ChangeTowerName(tabString)
	
	local data = totable(tabString)
	
	local script = Core.getScriptOfNetworkName(data.name)
	if script then
		
	end
end

function create()
	
	--Protection in multiplayer environment where multiple instances of this script is loaded
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	if node == nil then
		return false
	end
	
	if this:getNodeType() == NodeId.buildNode then
		
		canBuildInThisWorld = ( node:getClientId() == 0 or node:getClientId() == Core.getNetworkClient():getClientId() )
		
		Core.setScriptNetworkId("Builder"..node:getClientId())
		camera = ConvertToCamera( this:getRootNode():findNodeByName("MainCamera") );
		
		--this is the node named "player 1 node"
		print("------------------------------\n")
		comUnit = Core.getComUnit()
		comUnit:setCanReceiveTargeted(true)
		comUnit:setName("builder"..node:getClientId())
		
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
		comUnitTable["addDowngradeTower"] = addDowngradeTower
		comUnitTable["DropLatestBuildingEvent"] = DropLatestBuildingEvent
		

		comUnitTable["addRebuildTower"] = addRebuildTowerEvent
		comUnitTable["sendHightScoreToTheServer"] = sendHightScoreToTheServer
		comUnitTable["setBuildingTargetVec"] = setBuildingTargetVec
		comUnitTable["addPrioEvent"] = addPrioEvent
		
		comUnitTable["ChangeTowerName"] = ChangeTowerName
		
		functionList = {}
		functionList[1] = towerUpgradefunc
		functionList[2] = buildTowerNetworkBuild
		functionList[3] = uppgradeWallTowerTab
		functionList[4] = sellTowerAddNoEvent
		functionList[5] = upgradeWallTower
		functionList[6] = changeArrowTowerRotation
		functionList[7] = callPrioEvent
		
		
		--used for arrow tower whos building is canceld
		nameMaping = {}
		
		
		replayIndex = 1
		towerBuildInfo = {}
		
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
		
		restartWaveListener = Listener("RestartWave")
		restartWaveListener:registerEvent("restartWave", restartWave)
		
	
		
		readyToPlay[0] = false
		
		buildings = {}
		local numBuildings = 1
		while buildingBillboard:exist(tostring(numBuildings)) do
			buildings[numBuildings] = towerWorld:addChild( SceneNode() );
			local scriptName = buildingBillboard:getString(tostring(numBuildings));
			local luaScript = buildings[numBuildings]:loadLuaScript(scriptName);
			if luaScript then
				luaScript:setName("tower");
				luaScript:setScriptNetworkId("builder_tower_"..numBuildings)
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
		
		waveTime = Core.getGameTime()
		highScoreReplayBillboard = Core.getGlobalBillboard("highScoreReplay")
		isAReplay = highScoreReplayBillboard:getBool("replay")
		if isAReplay then
			--This is a game is a replay
			--this only occure for nowe 2017-07-04 on the server side where top play thrue is tested to detect cheating
			towerBuildInfo = totable( highScoreReplayBillboard:getString("replayTableString") )
			
			print("towerBuildInfo: "..tostring(towerBuildInfo))
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
	upgradeFromTowerToTower(building, 0, tab.upgToScripName, nil, tab.tName, false, tab.playerId )
	
	comUnit:sendTo("SelectedMenu", "updateSelectedTower", "")
end

function upgradeWallTower(param)
	
	local tab = totable(param)
	local script = Core.getScriptOfNetworkName(tab.netName)
	if script then
		
		local tName = tab.tName
		for i=1, #nameMaping do
			if nameMaping[i][1] == tName then
				tName = nameMaping[i][2]
				table.remove(nameMaping, i)
				i = #nameMaping + 2
			end
		end
		
		local building = script:getParentNode()
		upgradeFromTowerToTower(building, 0, tab.upgToScripName, nil, tName, true, tab.playerId )
		comUnit:sendTo("SelectedMenu", "updateSelectedTower", "")
		
		
		
		
		
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("NetUpgradeWallTower",param)
		end
	else
		print("---------------------")
		print("  Crash information  ")
		print("---------------------\n")
		print(tostring(towerBuildInfo))
		print("\n---------------------\n\n")
		abort("CRASH: send the white console information bettwen Crash information to me")
	end
end

function towerUpgradefunc(tab)
	comUnit:sendTo(Core.getScriptOfNetworkName(tab.netId):getIndex(),tab.msg,tab.param or "")
end

function towerUpgrade(param)
	--towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=buildCost,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=buildData,func=uppgradeWallTowerTab},restore={para1=downGradeData,func=upgradeWallTower}}
	
	local tab = totable(param)
	local scriptName = Core.getScriptOfNetworkName(tab.netId):getFileName()
	print("----- tower Upgrade -----")
	print("netId: "..tab.netId)
	print("msg:   "..tab.msg)
	print("param: "..(tab.param or ""))
	print("name:  "..scriptName)
	print("------------------------")
	
	
	
	if tab.param and not ( scriptName == "Tower/ArrowTower.lua" and tab.msg == "upgrade6") then
		local downGrade = {netId = tab.netId, msg = tab.msg, param = tab.param - 1}
		towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=tab.cost,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=tab,func=1},restore=nil}
	else
		--TODO not supported
		print("NOT supported")
	end
	
	towerUpgradefunc(tab)
end





--this function can be called localy or by ower network
function netSellTower(paramNetworkName,doNotReturnMoney)

	local buildingScript = Core.getScriptOfNetworkName(paramNetworkName)
	local netWorkName = (buildingLastSelected and buildingLastSelected:getScriptByName("tower")) and buildingLastSelected:getScriptByName("tower"):getNetworkName() or ""
	if buildingScript then
		local netName = buildingScript:getNetworkName()
		local billBoard = buildingScript:getBillboard()
		local buildingToSell = buildingScript:getParentNode()
		local buildingValue = billBoard:getFloat("value")
		local buildingValueLost = billBoard:getFloat("totalCost")-billBoard:getFloat("value")
		
		
		towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=0,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=paramNetworkName,func=4},restore={para1=netName,func=rebuildWallTower,name="rebuildWallTower"}}
		
		--print("buildingValue == "..buildingValue.."\n")
		if this:removeBuilding( buildingToSell ) then
			if billBoard:getBool("isNetOwner") and doNotReturnMoney ~= true then
				comUnit:sendTo("stats", "addGoldNoScore", tostring(buildingValue))
				comUnit:sendTo("stats","addBillboardDouble","goldLostFromSelling;"..tostring(buildingValueLost))
				comUnit:sendTo("stats","addTowersSold","")
			end
			--comUnit:sendTo("builder", "soldTower", tostring(buildingId))
			
			if netWorkName == paramNetworkName then
				print("\n\nSelected menu is in hidding because tower was sold\n\n")
				form:setVisible(false)
				targetArea.hiddeTargetMesh()
			end
		else
			if DEBUG then
				error("Removing building failed!!!")
			else
				print("Removing building failed!!!")
			end
		end
	else
		print("No script found for selected building, during remove")
	end

end

function sellTowerAddNoEvent(param)
	netSellTower(param)--This step adds a restore event
	towerBuildInfo[#towerBuildInfo] = nil --remove the restore event
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
	
	upgradeFromTowerToTower(buildingToUpgrade, buildCost, scriptName, tab.matrix, tab.tName, false)
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
		error("failed to place building")
	end
end

function buildTowerNetworkBuild(tab)
	
	
	local script = buildings[tab.buildingId]:getScriptByName("tower")
	local towerBilboard = script:getBillboard()
	local buildCost = towerBilboard:getFloat("cost")
	comUnit:sendTo("stats","removeGold",tostring(buildCost))
	
	buildTowerNetworkCallback(tab)
	
	local script = building:getScriptByName("tower")
	comUnit:sendTo(script:getIndex(),"NetOwner","YES")
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

function restartWave(wave)
--	print("restart Wave: "..wave)
--	print("data: "..tostring(towerBuildInfo))
	restoreToWave = wave
	local run = true
	while run and #towerBuildInfo > 0 do
		local index = #towerBuildInfo
		if towerBuildInfo[index].wave < wave then
			run = false
		else
--			print("DO: "..index)
			local restorTab = towerBuildInfo[index].restore
			if restorTab then
				if restorTab.para1 == nil then
					restorTab.func()
				elseif restorTab.para2 == nil then
					restorTab.func(restorTab.para1)
				else
					restorTab.func(restorTab.para1, restorTab.para2)
				end
			end
--			print("towerInfo: "..index.." is set to nil")
			towerBuildInfo[index] = nil
		end
	end
	
	--update wave time
	waveTime = Core.getGameTime()
end

function  isAtowerBuildEvent(index, netName)
	local addTab = towerBuildInfo[index].add
	return 	addTab and addTab.para1 and
			( addTab.func == 2 and addTab.para1.tName == netName ) or 
			( addTab.func == 3 and addTab.para1[5] == netName )
end

function rebuildWallTower(netName)
	print("Rebuild wall tower: "..netName)
	for i=1, #towerBuildInfo do
		if towerBuildInfo[i].add and towerBuildInfo[i].add.func == 2 and towerBuildInfo[i].add.para1.tName == netName then
			local addData = towerBuildInfo[i].add
			functionList[addData.func](addData.para1)
			
			local script = Core.getScriptOfNetworkName(addData.para1.tName)
			comUnit:sendTo(script:getIndex(),"NetOwner","YES")
			return
		elseif towerBuildInfo[i].restore and towerBuildInfo[i].restore.func == rebuildSoldTower and towerBuildInfo[i].restore.para1.wallTowerName == netName then
			--this case happens when a tower is directly built en sold of to a wall tower and then sold again
			local towerNetName = towerBuildInfo[i].restore.para1.towerName
			print("take build info from node: "..towerNetName)
			local n=1
			while n <= #towerBuildInfo do
				print("n: "..n)
				if towerBuildInfo[n].add and towerBuildInfo[n].add.func == 2 and towerBuildInfo[n].add.para1.tName == towerNetName then
					local addData = towerBuildInfo[n].add
					local restoreToName = addData.para1.tName
					addData.para1.buildingId = 1
					addData.para1.tName = netName
					functionList[addData.func](addData.para1)
					
					local script = Core.getScriptOfNetworkName(netName)
					comUnit:sendTo(script:getIndex(),"NetOwner","YES")
					
					addData.para1.tName = restoreToName
					return
				elseif towerBuildInfo[n].add and towerBuildInfo[n].add.func == 3 and towerBuildInfo[n].add.para1[5] == towerNetName then
					towerNetName = towerBuildInfo[n].add.para1[1]
					print("redo take build info from node: "..towerNetName)
					n = 1
				else
					n = n + 1
				end
			end
		end
	end
	error("wall tower was newer restored")
end

function rebuildSoldTower(tab)
	
	print("rebuildSoldTower: "..tostring(tab))
	
	local wallTowerNetName = tab.wallTowerName
	local towerNetName = tab.towerName
	

	--find the towers origins
	local index = 1
	local foundStartEvent = false
	while index <= #towerBuildInfo and foundStartEvent == false do
		if towerBuildInfo[index].add and isAtowerBuildEvent(index, towerNetName) then
			foundStartEvent = true
		else
			index = index + 1
		end
	end
	
	local ignoreWave = true
	if foundStartEvent then
		if towerBuildInfo[index].add.func == 2 then
			--the wall tower needs to be sold
			print("Sell Wall Tower: "..wallTowerNetName)
			sellTowerAddNoEvent(wallTowerNetName)
		elseif towerBuildInfo[index].add.func == 3 then
			--rename wallTower
			local script = Core.getScriptOfNetworkName(wallTowerNetName)
			script:setScriptNetworkId(towerBuildInfo[index].add.para1[1])
		end

		--restore building up until wave start
		while index < #towerBuildInfo and (ignoreWave or towerBuildInfo[index].wave < restoreToWave) do
			
			local addData = towerBuildInfo[index].add
			if addData and (isAtowerBuildEvent(index, towerNetName) or ( addData.func == 1 and addData.para1.netId == towerNetName ) or (addData.func == 4 and addData.para1.netName == towerNetName)) then
				ignoreWave = false
				functionList[addData.func](addData.para1)	
			end
			
			index = index + 1
		end
	end
end

function update()
	if canBuildInThisWorld == false then
		--update event from other players
		updateSelectedTowerToBuild()
		return true
	end
	
	if curentWave ~= Core.getBillboard("stats"):getInt("wave") then
		
		curentWave = Core.getBillboard("stats"):getInt("wave")
		waveTime = Core.getGameTime()
		
		if isAReplay and curentWave == 0 then
			waveTime = #towerBuildInfo > 1 and waveTime - towerBuildInfo[1].buildTimeFromBeginingOfWave + 3 or 0
		end
--		print("replayData: "..tabToStrMinimal(towerBuildInfo))
		local statsBillboard = Core.getBillboard("stats")
		local data = {gold=statsBillboard:getDouble("gold"),score=statsBillboard:getDouble("score"),life=statsBillboard:getDouble("life")}
		towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=0,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add=nil,restore=nil,data=data}
	end
	
--	if Core.getInput():getKeyDown(Key.y) then
--		sendHightScoreToTheServer()
--	end
	
	if isAReplay then
		local timeoffset = (Core.getGameTime()-waveTime)
		print("curentWave: "..curentWave.." timeoffset: "..timeoffset)
		while towerBuildInfo[replayIndex] and (towerBuildInfo[replayIndex].wave < curentWave or (towerBuildInfo[replayIndex].wave == curentWave and towerBuildInfo[replayIndex].buildTimeFromBeginingOfWave < timeoffset)) do
			
			local addData = towerBuildInfo[replayIndex].add
			if addData ~= nil then
				functionList[addData.func](addData.para1)
				
				if towerBuildInfo[replayIndex].cost then
					comUnit:sendTo("stats","removeGold",towerBuildInfo[replayIndex].cost)
				end
			end
			
			towerBuildInfo[replayIndex] = nil
			replayIndex = replayIndex + 1
		end
	end
	
	if Core.getInput():getKeyHeld(Key.lshift) or stateBillboard:getBool("inMenu") then
		noMoneyIcon:setVisible(false)
		builderFunctions.renderTargetArea("",nil,nil)
		if currentTower then
			currentTower:setVisible(false)
		end	
		builderFunctions.updateSelectedTower(nil)
		return true		
	end

	updateSelectedTowerToBuild()
	rotation = builderFunctions.updateBuildingRotation(rotation)
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
				
				--collect build info
				local tab = this:getBuildInfo()--{islandId=island:getIslandId(),localPos = island:getGlobalMatrix():inverseM() * collPos, rotation=rotation, buildingId = getBuildingId(currentTower), tName=towerName}
				tab.buildingId = getBuildingId(currentTower)
				tab.tName=towerName
				tab.playerId = Core.getPlayerId()
				if Core.isInMultiplayer() then
					comUnit:sendNetworkSyncSafe("NET",tabToStrMinimal(tab))
				else
					towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=0,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=tab,func=2},restore={para1=towerName,para2=true,func=sellTowerAddNoEvent,name="Sell Building"}}
				end
				
				building:setSceneName(towerBilboard:getString("Name"))
				building:createWork()
				increaseBuildBuildingCount()
				--successfully built tower, time to pay

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
				local buildingScript = building and building:getScriptByName("tower") or nil			
				local buildingBillBoard = buildingScript and buildingScript:getBillboard() or nil
				
				local a=32
				if towerBilboard:getString("Name") ~= "Wall tower" and buildingBillBoard and buildingBillBoard:getString("Name") == "Wall tower" and buildingBillBoard:getBool("isNetOwner")==true then
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
					if keyUse and keyUse:getPressed() and buildCost <= gold then
						--upgrade the building
--						AutoBuilder.changeBuilding(building, currentTower, building:findNodeByTypeTowardsRoot(NodeId.island):getGlobalMatrix():inverseM() * towerMatrix )
						local newBuildingMatrix = building:getParent():getGlobalMatrix():inverseM() * towerMatrix
						local curentName = wallTowerScript:getNetworkName()
						local tab = {buildTowerIndex=currentTowerIndex, netName=buildingScript:getNetworkName(), matrix=newBuildingMatrix, tName=getNewTowerName()}
						local buildingScript = currentTower:getScriptByName("tower")
						--get the cost of the new tower
						local buildingCost = buildingScript:getBillboard():getFloat("cost")
						--get the script file name
						local scriptName = buildingScript:getFileName()
						
						
						
						upgradeFromTowerToTower(building, buildingCost, scriptName, newBuildingMatrix, tab.tName, true)
						
						readyToPlay[0] = true
						readyToPlay[Core.getPlayerId()] = true
						updateIsAllreadyToPlay()					
						
						if Core.isInMultiplayer() then
							tab.playerId = Core.getPlayerId()
							comUnit:sendNetworkSyncSafe("NETWU",tabToStrMinimal(tab))
						else
							local buildData = {curentName, buildingCost, scriptName, newBuildingMatrix, tab.tName, true}
							local downGradeData = {netName = tab.tName, upgToScripName = "Tower/WallTower.lua", tName = tab.netName, playerId = Core.getPlayerId(), buildCost=0}
							
							towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=0,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=buildData,func=3},restore={para1=downGradeData,func=upgradeWallTower,name="WallTowerupgrade"}}
						end
						
						if targetAreaName == "cone" then
							changeSelectedTower(nil)
						end
					end
				end
			end
		end
		
		--set tower color
		builderFunctions.changeColor( currentTower, (canBePlacedHere and buildCost <= gold) and Vec4(1) or Vec4(1.3,0.45,0.45, 1.0))
		
		
			
		if this:getTargetIsland() and currentTower then
			currentTower:setLocalMatrix(towerMatrix);
			towerWorld:update();	
		end
		
		if currentTower and buildCost > gold then
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