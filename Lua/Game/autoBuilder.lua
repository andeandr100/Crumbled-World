--this = BuildNode()

AutoBuilder = {}
AutoBuilder.keyBindSave = KeyBind()
AutoBuilder.keyBindSave:setKeyBindKeyboard(0, Key.lctrl, Key.s)
AutoBuilder.keyBindLoad = KeyBind()
AutoBuilder.keyBindLoad:setKeyBindKeyboard(0, Key.lctrl, Key.l)
local eventList = {}
local loadOrder = {}
local curentEvent = 1
local currentWave = 0

local buildingList = {}

function AutoBuilder.setBuildingList(buildings)
--	AutoBuilder.buildings = buildings
end

local function getbuildingId(building)
--	for i=1, #AutoBuilder.buildings do
--		if AutoBuilder.buildings[i] == building then
--			return i
--		end
--	end
	return 0
end

local function getBuildingIndex(sceneNodeId)
--	for i=1, #buildingList do
--		if buildingList[i]:getId() == sceneNodeId then
--			return i
--		end
--	end
	return 0
end

local function getBuildingFromIndex(buildingIndex)
	return buildingList[buildingIndex]
end

function AutoBuilder.addBuilding(currentBuilding, collisionMesh, globalCollisionPos, rotation, building)
--	--building = SceneNode.new()
--	print("AutoBuilder.addBuilding()\n")
--	local buildingId = getbuildingId(currentBuilding)
--	
--	local island = collisionMesh:findNodeByTypeTowardsRoot(NodeId.island)
--	
--	eventList[#eventList+1] = {}
--	eventList[#eventList].time = Core.getGameTime()
--	eventList[#eventList].type = 1--1 building
--	eventList[#eventList].buildingId = buildingId
--	eventList[#eventList].islandId = island:getIslandId()
--	eventList[#eventList].localPosition = island:getGlobalMatrix():inverseM() * globalCollisionPos
--	eventList[#eventList].rotation = rotation
--	
--	buildingList[#buildingList+1] = building
end

function AutoBuilder.changeBuilding(currentBuilding, nextBuilding, localMatrix)
--	--building = SceneNode.new()
--	print("AutoBuilder.addBuilding()\n")
--	local buildingId = getbuildingId(nextBuilding)
--	
--	local island = collisionMesh:findNodeByTypeTowardsRoot(NodeId.island)
--	
--	eventList[#eventList+1] = {}
--	eventList[#eventList].time = Core.getGameTime()
--	eventList[#eventList].type = 3--1 building
--	eventList[#eventList].buildingIndex = getBuildingIndex(currentBuilding:getId())
--	eventList[#eventList].upgradeToBuildingId = buildingId
--	eventList[#eventList].localMatrix = localMatrix
--	
--	buildingList[#buildingList+1] = building
end

function split(str,sep)
	local array = {}
	local reg = string.format("([^%s]+)",sep)
	for mem in string.gmatch(str,reg) do
		table.insert(array, mem)
	end	
	return array
end

function soldTower(idString)
	
end

function newWave(wave)
--	eventList[#eventList+1] = {}
--	eventList[#eventList].time = 999999
--	eventList[#eventList].type = 5
--	eventList[#eventList].waveTime = Core.getGameTime()
--	eventList[#eventList].wave = tonumber(wave)
--	
--	currentWave = tonumber(wave)
--	
end

function setBuildingTargetVec(inText)
--	print("\n\n\ninText: "..inText.."\n")
--	local array = split(inText, ";")
--	print("Count: "..#array.."\n\n\n")
--	if #array == 2 then
--		eventList[#eventList+1] = {}
--		eventList[#eventList].time = Core.getGameTime()
--		eventList[#eventList].type = 4
--		eventList[#eventList].buildingId = getBuildingIndex(tonumber(array[1]))
--		eventList[#eventList].inPara = array[2]
--	end
end

function upgradeBuilding(inText)
--	print("\n\n\ninText: "..inText.."\n")
--	local array = split(inText, ";")
--	print("Count: "..#array.."\n\n\n")
--	if #array == 2 then
--		eventList[#eventList+1] = {}
--		eventList[#eventList].time = Core.getGameTime()
--		eventList[#eventList].type = 2
--		eventList[#eventList].buildingId = getBuildingIndex(tonumber(array[1]))
--		eventList[#eventList].functionName = array[2]
--	end
end

function AutoBuilder.save()
--	local config = loadConfig("TowerReBuild")
--	config:removeChildren()
--	
--	print("AutoBuilder.save()\n")
--	for i=1, #eventList do
--		local configEvent = config:getChild("Event"..i)
--		configEvent:getChild("time"):setFloat(eventList[i].time)
--		configEvent:getChild("type"):setInt(eventList[i].type)
--		if eventList[i].type == 1 then
--			configEvent:getChild("buildingId"):setInt(eventList[i].buildingId)
--			configEvent:getChild("islandId"):setInt(eventList[i].islandId)
--			configEvent:getChild("rotation"):setFloat(eventList[i].rotation)
--			
--			local pos = eventList[i].localPosition
--				
--			configEvent:getChild("posX"):setFloat(pos.x)
--			configEvent:getChild("posY"):setFloat(pos.y)
--			configEvent:getChild("posZ"):setFloat(pos.z)
--		
--		elseif eventList[i].type == 2 then
--			configEvent:getChild("buildingId"):setInt(eventList[i].buildingId)
--			configEvent:getChild("functionName"):set(eventList[i].functionName)
--		elseif eventList[i].type == 3 then
--			configEvent:getChild("buildingIndex"):setInt(eventList[i].buildingIndex)
--			configEvent:getChild("upgradeToBuildingId"):setInt(eventList[i].upgradeToBuildingId)
--			
--			local pos = eventList[i].localMatrix:getPosition()
--			local at = eventList[i].localMatrix:getAtVec()
--			local up = eventList[i].localMatrix:getUpVec()
--				
--			configEvent:getChild("posX"):setFloat(pos.x)
--			configEvent:getChild("posY"):setFloat(pos.y)
--			configEvent:getChild("posZ"):setFloat(pos.z)
--			
--			configEvent:getChild("atX"):setFloat(at.x)
--			configEvent:getChild("atY"):setFloat(at.y)
--			configEvent:getChild("atZ"):setFloat(at.z)
--			
--			configEvent:getChild("upX"):setFloat(up.x)
--			configEvent:getChild("upY"):setFloat(up.y)
--			configEvent:getChild("upZ"):setFloat(up.z)
--		elseif eventList[i].type == 4 then
--			configEvent:getChild("buildingId"):setInt(eventList[i].buildingId)
--			configEvent:getChild("inPara"):set(eventList[i].inPara)
--		elseif eventList[i].type == 5 then
--			configEvent:getChild("waveTime"):setFloat(eventList[i].waveTime)
--			configEvent:getChild("wave"):setInt(eventList[i].wave)
--		end
--	end
--	config:save()
end

function AutoBuilder.load()
--	print("AutoBuilder.load()\n")
--	local config = Config("TowerReBuild")
--	loadOrder = {}
--	curentEvent = 1
--	for i=1, config:getChildSize() do
--		local eventConfig = config:getChild(i-1)
--		loadOrder[i] = {}
--		loadOrder[i].time = eventConfig:getChild("time"):getFloat("0")
--		loadOrder[i].type = eventConfig:getChild("type"):getInt("0")
--		if loadOrder[i].type == 1 then
--			loadOrder[i].buildingId = eventConfig:getChild("buildingId"):getInt("0")
--			loadOrder[i].islandId = eventConfig:getChild("islandId"):getInt("0")
--			loadOrder[i].rotation = eventConfig:getChild("rotation"):getFloat("0")
--			
--			local pos = Vec3()
--
--			pos.x = eventConfig:getChild("posX"):getFloat("0")
--			pos.y = eventConfig:getChild("posY"):getFloat("0")
--			pos.z = eventConfig:getChild("posZ"):getFloat("0")
--						
--			loadOrder[i].localPosition = pos
--		elseif loadOrder[i].type == 2 then
--			loadOrder[i].buildingId = eventConfig:getChild("buildingId"):getInt("0")
--			loadOrder[i].functionName = eventConfig:getChild("functionName"):get("noFunction")
--		elseif loadOrder[i].type == 3 then
--			loadOrder[i].buildingIndex = eventConfig:getChild("buildingIndex"):getInt("0")
--			loadOrder[i].upgradeToBuildingId = eventConfig:getChild("upgradeToBuildingId"):getInt("0")
--			
--			local pos = Vec3()
--			local at = Vec3()
--			local up = Vec3()
--
--			pos.x = eventConfig:getChild("posX"):getFloat("0")
--			pos.y = eventConfig:getChild("posY"):getFloat("0")
--			pos.z = eventConfig:getChild("posZ"):getFloat("0")
--			
--			at.x = eventConfig:getChild("atX"):getFloat("0")
--			at.y = eventConfig:getChild("atY"):getFloat("0")
--			at.z = eventConfig:getChild("atZ"):getFloat("0")
--			
--			up.x = eventConfig:getChild("upX"):getFloat("0")
--			up.y = eventConfig:getChild("upY"):getFloat("0")
--			up.z = eventConfig:getChild("upZ"):getFloat("0")
--			
--			local matrix = Matrix()
--			matrix:createMatrix(at, up)
--			matrix:setPosition(pos)
--			
--			loadOrder[i].localMatrix = matrix
--		elseif loadOrder[i].type == 4 then
--			loadOrder[i].buildingId = eventConfig:getChild("buildingId"):getInt("0")
--			loadOrder[i].inPara = eventConfig:getChild("inPara"):get("0,0,0")
--		elseif loadOrder[i].type == 5 then
--			loadOrder[i].waveTime = eventConfig:getChild("waveTime"):getFloat("0")
--			loadOrder[i].wave = eventConfig:getChild("wave"):getInt("0")
--		end
--		
--	end
--	
--	if #loadOrder > 0 then
--		local startTime = loadOrder[1].time
--		if loadOrder[1].type == 5 then
--			startTime = loadOrder[1].waveTime
--		end
--		local timeOffset = (startTime+1) - Core.getGameTime()
--		for i=curentEvent, #loadOrder do
--			if loadOrder[i].type == 5 then
--				loadOrder[i].waveTime = loadOrder[i].waveTime - timeOffset
--			else
--				loadOrder[i].time = loadOrder[i].time - timeOffset
--			end
--		end
--	end
end

local function getIslandFromId(islandId)
--	list = this:getPlayerNode():findAllNodeByTypeTowardsLeaf(NodeId.island)
--	
--	for i=0, list:size()-1 do
--		if list:item(i):getIslandId() == islandId then
--			return list:item(i)
--		end
--	end
--	
	return nil
end

function AutoBuilder.update()
	
--	if AutoBuilder.keyBindSave:getPressed() then
--		AutoBuilder.save()
--	end
--	if AutoBuilder.keyBindLoad:getPressed() then
--		AutoBuilder.load()
--	end
--	
--	if curentEvent <= #loadOrder and loadOrder[curentEvent].time < Core.getGameTime() then
--		if loadOrder[curentEvent].type == 1 then
--			local island = getIslandFromId(loadOrder[curentEvent].islandId)
--			local building = AutoBuilder.buildings[loadOrder[curentEvent].buildingId]
--			local newBuildng = this:build(building, island, loadOrder[curentEvent].localPosition, loadOrder[curentEvent].rotation)
--			
--			AutoBuilder.buildingBillboard = AutoBuilder.buildingBillboard or Core.getBillboard("buildings")
--			AutoBuilder.buildingBillboard:setInt( "NumBuildingBuilt", AutoBuilder.buildingBillboard:getInt("NumBuildingBuilt") + 1 )
--			buildingList[#buildingList+1] = newBuildng
--		elseif loadOrder[curentEvent].type == 2 then
--			local building = getBuildingFromIndex( loadOrder[curentEvent].buildingId )
--			if building then
--				local buildingScript = building:getScriptByName("tower")	
--				comUnit:sendTo(buildingScript:getIndex(),loadOrder[curentEvent].functionName,"")
--			end
--		elseif loadOrder[curentEvent].type == 3 then
--			local buildingToUpgrade = getBuildingFromIndex( loadOrder[curentEvent].buildingIndex )
--			local upgradeToBuilding = AutoBuilder.buildings[loadOrder[curentEvent].upgradeToBuildingId]
--			
--			--get the script of the tower that will be built
--			local buildingScript = upgradeToBuilding:getScriptByName("tower")
--			--get the script file name
--			local scriptName = buildingScript:getFileName()
--			
--			local wallTowerScript = buildingToUpgrade:getScriptByName("tower")
--			--get the tower hull
--			local towerHull = wallTowerScript:getBillboard():getVectorVec2("hull2dGlobal")
--			
--	
--			--Clean up the wall tower from the map
--			
--			scriptList = buildingToUpgrade:getAllScript()			
--			for i=1, #scriptList do
--				buildingToUpgrade:removeScript(scriptList[i]:getName())
--			end
--			
--			while buildingToUpgrade:getChildSize() > 0 do
--				local child = buildingToUpgrade:getChildNode(0)
--				child:setVisible(false)
--				buildingToUpgrade:removeChild(child:toSceneNode())
--			end
--			
--			--the wall tower has been removed from the map
--			--Set the new script on the node to load it in to memmory
--			buildingScript = buildingToUpgrade:loadLuaScript(scriptName)
--			buildingToUpgrade:setLocalMatrix(loadOrder[curentEvent].localMatrix)
--
--			buildingToUpgrade:update();
--			buildingScript:getBillboard():setVectorVec2("hull2dGlobal", towerHull)
--			buildingScript:setName(Text("tower"))	
--			
--			buildingList[#buildingList+1] = buildingToUpgrade
--		elseif loadOrder[curentEvent].type == 4 then
--			local building = getBuildingFromIndex( loadOrder[curentEvent].buildingId )
--			if building then
--				local buildingScript = building:getScriptByName("tower")	
--				Core.getComUnit():sendTo(buildingScript:getIndex(), "setRotateTarget", loadOrder[curentEvent].inPara)
--			end
--			
--		end
--		
--		curentEvent = curentEvent + 1
--	elseif curentEvent <= #loadOrder then
--		if loadOrder[curentEvent].type == 5 and loadOrder[curentEvent].wave == currentWave then
--			
--			local timeOffset = loadOrder[curentEvent].waveTime - Core.getGameTime()
--			print("\n\nSync offset: "..timeOffset.."\n\n\n")
--			for i=curentEvent, #loadOrder do
--				
--				if loadOrder[i].type == 5 then
--					loadOrder[i].waveTime = loadOrder[i].waveTime - timeOffset
--				else
--					loadOrder[i].time = loadOrder[i].time - timeOffset
--				end
--			end
--			
--			timeOffset = loadOrder[curentEvent].waveTime - Core.getGameTime()
--			print("\n\nFinal Sync offset: "..timeOffset.."\n\n\n")
--			
--			curentEvent = curentEvent + 1
--		end
--	end
	
end