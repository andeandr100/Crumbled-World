require("Game/builderUpgrader.lua")
require("Game/builderFunctions.lua")
require("Game/mapInfo.lua")
--require("Game/autoBuilder.lua")
--this = BuildNode()
local buildCounter = 0
local readyToPlay = {}
local towerChangeState = 0
local towerBuildInfo = {}
local waveTime = 0
local curentWave = -1

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
		
		towerBuildInfo = totable("{[1]={restore={func=nil,para2=true,para1=\"{T0_1,name=ops}\"}}}")
		replayIndex = 1
		towerBuildInfo = totable("{[1]={restore={func=nil,para2=true,para1=\"T0_1\"},wave=0,add={func=nil,para1=\"{rotation=360,islandId=0,tName=\"T0_1\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(-0.0900001526,1.55999947),towerLocalIslandMatrix=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,-0.0999994278,0,1.56146479,1})}\"},buildTimeFromBeginingOfWave=4.3861607869621,cost=35},[2]={restore={func=nil,para2=true,para1=\"T0_2\"},wave=0,add={func=nil,para1=\"{rotation=360,islandId=0,tName=\"T0_2\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(1.61000061,-0.159999847),towerLocalIslandMatrix=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,1.60000134,0,-0.158534527,1})}\"},buildTimeFromBeginingOfWave=5.7371609115507,cost=35},[3]={restore={func=nil,para2=true,para1=\"T0_3\"},wave=0,add={func=nil,para1=\"{rotation=360,islandId=0,tName=\"T0_3\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(-0.109999657,-1.64000034),towerLocalIslandMatrix=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,-0.119998932,0,-1.63853502,1})}\"},buildTimeFromBeginingOfWave=6.6369963418692,cost=35},[4]={restore={func=nil,para2=true,para1=\"T0_4\"},wave=0,add={func=nil,para1=\"{rotation=360,islandId=0,tName=\"T0_4\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(-1.68999958,1.53999901),towerLocalIslandMatrix=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,-1.69999886,0,1.54146433,1})}\"},buildTimeFromBeginingOfWave=11.251666832482,cost=35},[5]={restore={func=nil,para2=true,para1=\"T0_5\"},wave=0,add={func=nil,para1=\"{rotation=360,islandId=0,tName=\"T0_5\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(-1.71000004,-1.70000076),towerLocalIslandMatrix=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,-1.71999931,0,-1.69853544,1})}\"},buildTimeFromBeginingOfWave=12.230721638305,cost=35},[6]={restore={func=nil,para2=true,para1=\"T0_6\"},wave=0,add={func=nil,para1=\"{rotation=345,islandId=0,tName=\"T0_6\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(-3.56999969,-1.44000053),towerLocalIslandMatrix=createMatrixFromTable({0.965925872,0,-0.258818835,0,0,1,0,0,0.258818835,0,0.965925872,0,-3.57999897,0,-1.43853521,1})}\"},buildTimeFromBeginingOfWave=13.736848200904,cost=35},[7]={restore={func=nil,para1={tName=\"T0_1\",netName=\"T0_7\",playerId=0,buildCost=0,upgToScripName=\"Tower/WallTower.lua\"}},wave=0,add={func=nil,para1={[1]=\"T0_7\",[2]=200,[3]=\"Tower/MinigunTower.lua\",[4]=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,-0.0999994278,0,1.56146479,1}),[5]=\"T0_7\",[6]=true}},buildTimeFromBeginingOfWave=16.108752770815,cost=165},[8]={restore={func=nil,para1={tName=\"T0_2\",netName=\"T0_8\",playerId=0,buildCost=0,upgToScripName=\"Tower/WallTower.lua\"}},wave=1,add={func=nil,para1={[1]=\"T0_8\",[2]=200,[3]=\"Tower/MinigunTower.lua\",[4]=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,1.60000134,0,-0.158534527,1}),[5]=\"T0_8\",[6]=true}},buildTimeFromBeginingOfWave=0.57381335552782,cost=165},[9]={restore={func=nil,para1={msg=\"upgrade1\",netId=\"T0_7\",param=1}},wave=1,add={func=nil,para1={netId=\"T0_7\",msg=\"upgrade1\",param=2}},buildTimeFromBeginingOfWave=2.5845731673762},[10]={restore={func=nil,para1={tName=\"T0_3\",netName=\"T0_9\",playerId=0,buildCost=0,upgToScripName=\"Tower/WallTower.lua\"}},wave=2,add={func=nil,para1={[1]=\"T0_9\",[2]=200,[3]=\"Tower/missileTower.lua\",[4]=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,-0.119998932,0,-1.63853502,1}),[5]=\"T0_9\",[6]=true}},buildTimeFromBeginingOfWave=24.624568435829,cost=165},[11]={restore={func=nil,para2=true,para1=\"T0_10\"},wave=3,add={func=nil,para1=\"{rotation=352.5,islandId=0,tName=\"T0_10\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(-4.82999992,1.61999893),towerLocalIslandMatrix=createMatrixFromTable({0.990268111,0,-0.13917312,0,0,1,0,0,0.13917312,0,0.990268111,0,-4.8399992,0,1.62146425,1})}\"},buildTimeFromBeginingOfWave=8.892212790437,cost=35},[12]={restore={func=nil,para2=true,para1=\"T0_11\"},wave=3,add={func=nil,para1=\"{rotation=356.25,islandId=0,tName=\"T0_11\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(-4.56999969,3.23999977),towerLocalIslandMatrix=createMatrixFromTable({0.997564077,0,-0.0697563812,0,0,1,0,0,0.0697563812,0,0.997564077,0,-4.57999897,0,3.24146509,1})}\"},buildTimeFromBeginingOfWave=9.8854345146101,cost=35},[13]={restore={func=nil,para2=true,para1=\"T0_12\"},wave=3,add={func=nil,para1=\"{rotation=356.25,islandId=0,tName=\"T0_12\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(-3.02999973,4.57999992),towerLocalIslandMatrix=createMatrixFromTable({0.997564077,0,-0.0697563812,0,0,1,0,0,0.0697563812,0,0.997564077,0,-3.03999901,0,4.58146524,1})}\"},buildTimeFromBeginingOfWave=10.58594538155,cost=35},[14]={restore={func=nil,para2=true,para1=\"T0_13\"},wave=3,add={func=nil,para1=\"{rotation=356.25,islandId=0,tName=\"T0_13\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(-1.43000031,4.65999985),towerLocalIslandMatrix=createMatrixFromTable({0.997564077,0,-0.0697563812,0,0,1,0,0,0.0697563812,0,0.997564077,0,-1.43999958,0,4.66146517,1})}\"},buildTimeFromBeginingOfWave=11.296086510411,cost=35},[15]={restore={func=nil,para2=true,para1=\"T0_14\"},wave=3,add={func=nil,para1=\"{rotation=3.75,islandId=0,tName=\"T0_14\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(0.230000496,4.63999939),towerLocalIslandMatrix=createMatrixFromTable({0.99862951,0,0.0523359589,0,0,1,0,0,-0.0523359589,0,0.99862951,0,0.220001221,0,4.64146471,1})}\"},buildTimeFromBeginingOfWave=12.38516042917,cost=35},[16]={restore={func=nil,para2=true,para1=\"T0_15\"},wave=3,add={func=nil,para1=\"{rotation=3.75,islandId=0,tName=\"T0_15\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(1.82999992,4.63999939),towerLocalIslandMatrix=createMatrixFromTable({0.99862951,0,0.0523359589,0,0,1,0,0,-0.0523359589,0,0.99862951,0,1.82000065,0,4.64146471,1})}\"},buildTimeFromBeginingOfWave=14.856887261383,cost=35},[17]={restore={func=nil,para2=true,para1=\"T0_16\"},wave=3,add={func=nil,para1=\"{rotation=2.1468744615177e-014,islandId=0,tName=\"T0_16\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(3.45000076,4.69999886),towerLocalIslandMatrix=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,3.44000149,0,4.70146418,1})}\"},buildTimeFromBeginingOfWave=15.811680021463,cost=35},[18]={restore={func=nil,para2=true,para1=\"T0_17\"},wave=3,add={func=nil,para1=\"{rotation=11.25,islandId=0,tName=\"T0_17\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(4.70999908,1.60000038),towerLocalIslandMatrix=createMatrixFromTable({0.981627226,0,0.190809011,0,0,1,0,0,-0.190809011,0,0.981627226,0,4.69999981,0,1.6014657,1})}\"},buildTimeFromBeginingOfWave=18.330815867055,cost=35},[19]={restore={func=nil,para2=true,para1=\"T0_18\"},wave=3,add={func=nil,para1=\"{rotation=11.25,islandId=0,tName=\"T0_18\",buildingId=1,playerId=0,towerScriptName=\"Tower/WallTower.lua\",navMeshPosition=Vec2(4.93000031,3.23999977),towerLocalIslandMatrix=createMatrixFromTable({0.981627226,0,0.190809011,0,0,1,0,0,-0.190809011,0,0.981627226,0,4.92000103,0,3.24146509,1})}\"},buildTimeFromBeginingOfWave=19.049647258362,cost=35},[20]={restore={func=nil,para1={tName=\"T0_17\",netName=\"T0_19\",playerId=0,buildCost=0,upgToScripName=\"Tower/WallTower.lua\"}},wave=3,add={func=nil,para1={[1]=\"T0_19\",[2]=200,[3]=\"Tower/ArrowTower.lua\",[4]=createMatrixFromTable({0.981627226,0,0.190809011,0,0,1,0,0,-0.190809011,0,0.981627226,0,4.69999981,0,1.6014657,1}),[5]=\"T0_19\",[6]=true}},buildTimeFromBeginingOfWave=20.191116319038,cost=165},[21]={restore={func=nil,para2=true,para1=\"T0_20\"},wave=4,add={func=nil,para1=\"{rotation=63.75,islandId=0,tName=\"T0_20\",buildingId=2,playerId=0,towerScriptName=\"Tower/MinigunTower.lua\",navMeshPosition=Vec2(4.59000015,-1.54000092),towerLocalIslandMatrix=createMatrixFromTable({0.453990549,0,0.891006529,0,0,1,0,0,-0.891006529,0,0.453990549,0,4.58000088,0,-1.53853559,1})}\"},buildTimeFromBeginingOfWave=5.5782500370406,cost=200},[22]={restore={func=nil,para2=true,para1=\"T0_21\"},wave=4,add={func=nil,para1=\"{rotation=5.0888875497432e-014,islandId=0,tName=\"T0_21\",buildingId=2,playerId=0,towerScriptName=\"Tower/MinigunTower.lua\",navMeshPosition=Vec2(3.04999924,-3.14000034),towerLocalIslandMatrix=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,3.03999996,0,-3.13853502,1})}\"},buildTimeFromBeginingOfWave=19.818340265192,cost=200}}")
	
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

function towerUpgradefunc(tab)
	comUnit:sendTo(Core.getScriptOfNetworkName(tab.netId):getIndex(),tab.msg,tab.param or "")
end

function towerUpgrade(param)
	--towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=buildCost,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=buildData,func=uppgradeWallTowerTab},restore={para1=downGradeData,func=upgradeWallTower}}
	
	local tab = totable(param)
	print("------------------------")
	print("netId: "..tab.netId)
	print("msg:   "..tab.msg)
	print("param: "..(tab.param or ""))
	print("------------------------")
	
	if tab.param then
		local downGrade = {netId = tab.netId, msg = tab.msg, param = tab.param - 1}
		towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=tab.cost,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=tab,func=towerUpgradefunc},restore={para1=downGrade,func=towerUpgradefunc}}
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
		local billBoard = buildingScript:getBillboard()
		local buildingToSell = buildingScript:getParentNode()
		local buildingValue = billBoard:getFloat("value")
		--print("buildingValue == "..buildingValue.."\n")
		if this:removeBuilding( buildingToSell ) then
			if billBoard:getBool("isNetOwner") and doNotReturnMoney ~= true then
				comUnit:sendTo("stats", "addGold", tostring(buildingValue))
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

function restartWave(wave)
	local run = true
	while run and #towerBuildInfo > 0 do
		local index = #towerBuildInfo
		if towerBuildInfo[index].wave < wave then
			run = false
		else
			local restorTab = towerBuildInfo[index].restore
			if restorTab.para1 == nil then
				restorTab.func()
			elseif restorTab.para2 == nil then
				restorTab.func(restorTab.para1)
			else
				restorTab.func(restorTab.para1, restorTab.para2)
			end
			towerBuildInfo[index] = nil
		end
	end
	
end

function update()
	
	if curentWave ~= Core.getBillboard("stats"):getInt("wave") then
		curentWave = Core.getBillboard("stats"):getInt("wave")
		waveTime = Core.getGameTime()
		print("replayData: "..tabToStrMinimal(towerBuildInfo))
	end
	
	for i=replayIndex, #towerBuildInfo do
		if towerBuildInfo[i] < curentWave or (towerBuildInfo[i] == curentWave and towerBuildInfo[i].buildTimeFromBeginingOfWave < (Core.getGameTime()-waveTime)) then
			local addData = towerBuildInfo[i].add
			addData.func(addData.para1)
			towerBuildInfo[i] = nil
		end
	end
	
	if Core.getInput():getKeyDown(Key.u) then
		increaseBuildBuildingCount()
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
				
				--collect build info
				local tab = this:getBuildInfo()--{islandId=island:getIslandId(),localPos = island:getGlobalMatrix():inverseM() * collPos, rotation=rotation, buildingId = getBuildingId(currentTower), tName=towerName}
				tab.buildingId = getBuildingId(currentTower)
				tab.tName=towerName
				tab.playerId = Core.getPlayerId()
				if Core.isInMultiplayer() then
					comUnit:sendNetworkSyncSafe("NET",tabToStrMinimal(tab))
				else
					towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=buildCost,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=tabToStrMinimal(tab),func=syncBuild},restore={para1=towerName,para2=true,func=netSellTower}}
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
					if keyUse and keyUse:getPressed() and buildCost <= gold then
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
						else
							local buildData = {tab.tName, buildingCost, scriptName, newBuildingMatrix, tab.tName, true}
							local downGradeData = {netName = tab.tName, upgToScripName = "Tower/WallTower.lua", tName = tab.netName, playerId = Core.getPlayerId(), buildCost=0}
							
							towerBuildInfo[#towerBuildInfo+1] = {wave=curentWave,cost=buildCost,buildTimeFromBeginingOfWave = (Core.getGameTime()-waveTime),add={para1=buildData,func=uppgradeWallTowerTab},restore={para1=downGradeData,func=upgradeWallTower}}
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