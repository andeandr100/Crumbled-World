require("Game/mapInfo.lua")
require("Game/campaignData.lua")
require("Game/SpawnSystem/spawnGroups.lua")
require("Game/SpawnSystem/spawnWaveBuilder.lua")
require("Game/SpawnSystem/spawnInfo.lua")


--this = SceneNode()
SPAWN_PATTERN = {
	Random = 1,	--enemies comes out of a random game
	Clone = 2,	--enemies comes out of all gates
	Grouped = 3	--eneims comes out of gate1 then gate2 then gate3 then gate1...	(default)
}
SpawnManager = {}
function SpawnManager.new()
	local self = {}
	
	local firstNpcOfWaveHasSpawned = false
	
	local totalNpcSpawned = 0
	
	local spawnInfo = SpawnInfo.new()
	local spawnGroups = SpawnGroups.new()
	local mapInfo = MapInfo.new()
	local STARTWAVE = mapInfo.getStartWave()
	local waveCount = STARTWAVE		--what wave we are currently playing
	local comUnit = Core.getComUnit()
	local bilboardStats = Core.getBillboard("stats")
	--local soulmanager
	local currentWaves = {}	--waves that are currently spawning
	local numWaves = 100	--this should not be possible to reach at all
	local waves = {}
	local goldMultiplayerOnKills = 1.0
	local waveInfo = {}
	local fixedGroupToSpawn = {}
	local disableUnits = {}
	local npc = spawnGroups.getNPCValueList()
	local npcCounter = {}
	local spawnListPopulated = false
	local spawnPattern = Core.isInMultiplayer() and SPAWN_PATTERN.Clone or SPAWN_PATTERN.Grouped
	local npcFlipOffset = 1.0

	--
	local seed
	--
	local pathBilboard
	local spawns
	local currentPortalId = 1
	local currentSpawn
	
	--
	--
	local totalSpawned = 0
	local spawnedThisWave = 0
	
	local function sendNetworkSyncSafe(msg,param)
		local tab = Core.getNetworkClient():getConnected()
		for index=1, Core.getNetworkClient():getConnectedPlayerCount() do
			comUnit:sendNetworkSyncSafeTo("Event"..tostring(tab[index].clientId),msg,param)
		end
	end

	function self.spawnUnitsPattern( pattern )
		spawnPattern = pattern
	end
	
	function self.setGoldMultiplayerOnKills(multiplyer)
		assert(multiplyer>=0,"setGoldMultiplayerOnKills(multiplyer), must be a number >=0")
		goldMultiplayerOnKills = multiplyer
	end
	function self.isAnythingSpawning()
		return #currentWaves>=1
	end
	function self.isSpawnListPopulated()
		return spawnListPopulated
	end
	function self.isFirstNpcOfWaveSpawned()
		return firstNpcOfWaveHasSpawned
	end
	
	--NPC alive
	function self.isAnyEnemiesAlive()
		local bill = Core.getBillboard("SoulManager")
		return bill and bill:getInt("npcsAlive")>0 or false
	end
	function self.getWavesSize()
		return #waves
	end
	function self.getNumWaves()
		return numWaves
	end
	function self.getWaveInfo()
		return waveInfo
	end
	local function getSpawnPosition(portalId)
		local spawnId = portalId
		return spawns[spawnId].island, spawns[spawnId].position
	end	
	--NPC
	local function createNpcNode(portalId)
		local island, localPos = getSpawnPosition(portalId)
		local npcNode = island:addChild(SceneNode.new())
		npcNode:setLocalPosition( localPos )
		npcNode:setSceneName("NPC")
		npcNode:createWork()
		return npcNode
	end
	function self.changeWave(pWaveCount)
		waveCount = pWaveCount

		spawnInfo.updateNpcInfo(waveCount,waves[waveCount])
		firstNpcOfWaveHasSpawned = false
		--this also pushes the info to the history table
		comUnit:sendTo("stats", "setWave", math.min(waveCount,numWaves))
		comUnit:sendTo("stats", "setMaxWave", numWaves)
		--
		waveCount = pWaveCount
		local count = 0
		if waveCount <=  #waves then
			local details = waves[waveCount]
			--count all real npcs
			for i=3, #details do
				if npc[details[i].npc] then
					count = count + 1
				end
			end
		end
		spawnedThisWave = 0
		comUnit:sendTo("stats", "setNPCSpawnsThisWave", count)
		comUnit:sendTo("stats", "setNPCSpawnedThisWave", 0)
	end
	local function spawnCurrentUnit(currentWave,portalId, pathOffset, npcScale, hpScale, animationSpeed)
		--make sure that it is a real npc
		if npc[currentSpawn.npc] then
			--counter for multiplayer
			npcCounter[currentSpawn.npc] = npcCounter[currentSpawn.npc] and npcCounter[currentSpawn.npc]+1 or 0
			--local netName = (Core.isInMultiplayer() and Core.getNetworkClient():getClientId() or "-")..currentSpawn.npc..npcCounter[currentSpawn.npc]
			local netName = currentSpawn.npc..npcCounter[currentSpawn.npc]
			--spawn the npc
			local node = createNpcNode(portalId)
			local script = node:loadLuaScript( npc[currentSpawn.npc].script )
			script:setScriptNetworkId(netName)
			
			local billboard = script:getBillboard()
			billboard:setDouble("pathOffset", ( pathOffset ~= nil and pathOffset or 0.2 ) * npcFlipOffset)
			billboard:setDouble("npcScale",npcScale ~= nil and npcScale or 1.0)
			billboard:setDouble("hpScale",hpScale ~= nil and hpScale or 1.0)
			billboard:setDouble("animationSpeed",animationSpeed ~= nil and animationSpeed or 1.0)
			npcFlipOffset = npcFlipOffset * -1.0


			--print("NPC->setNetName() == "..netName.."\n")
			--count down npcs to be spawned
			currentWave[1].info[currentSpawn.npc].numEnemies = currentWave[1].info[currentSpawn.npc].numEnemies - 1
			--
			totalSpawned = totalSpawned + 1
			spawnedThisWave = spawnedThisWave + 1
			comUnit:sendTo("stats", "npcSpawnedWave", tostring(script:getIndex())..";"..tostring(waveCount))
			comUnit:sendTo("stats", "setNPCSpawnedThisWave", spawnedThisWave)
			--comUnit:sendTo("stats", "setTotalNPCSpawned", totalSpawned)
			comUnit:sendTo("stats","addSpawn","")
			--
			firstNpcOfWaveHasSpawned = true
		end
	end
	local function getCopyOfTable(table)
		if type(table)~="table" then
			return table
		end
		--it is a table
		local ret = {}
		for k,v in pairs(table) do
			ret[k] = getCopyOfTable(v)
		end
		return ret
	end
	local function compareValues(t1, t2)
		--make sure they are the smae type
		if type(t1)~=type(t2) then
			abort()
			return false
		end
		
		if type(t1)=="table" then
			--compare tables
			local keysCompared = {}
			for k,v in pairs(t1) do
				keysCompared[k] = true
				--compare the 2 values 
				if compareValues(t1[k], t2[k])==false then
					abort()
					return false
				end
			end
			--make sure that t2 does not contain any other keys
			for k,v in pairs(t2) do
				if not keysCompared[k] then
					abort()
					return false
				end
			end
		else
			--compare values
			if type(t1)=="number" then
				return ((t1-t2)>-0.0001 and (t1-t2)<0.0001 )
			else
				return t1==t2
			end
		end
		return true
	end
	local function resendWaveData()
		comUnit:sendTo("stats", "setWave", mapInfo.getStartWave())
		comUnit:sendTo("stats", "setMaxWave", numWaves)
		--comUnit:sendTo("stats", "setTotalNPCSpawns", totalNpcSpawned)
		assert(waves, "waves is not initiated")
		comUnit:sendTo("statsMenu","waveInfo",waves)
	end
	function self.spawnWave(reloadIcons)
		if waves[waveCount] then
			currentWaves[#currentWaves+1] = getCopyOfTable( waves[waveCount] )--make a copy of it, then we can go back and re use it
			currentWaves[#currentWaves].waveUnitIndex = 2
			currentWaves[#currentWaves].groupCounter = 1
			currentWaves[#currentWaves].waveCount = waveCount
			comUnit:sendTo("statsMenu","startWave",tostring(waveCount)..";"..(reloadIcons and "1" or "0") )
		else
			abort()
		end
	end
	function self.clearActiveSpawn()
		currentWaves = {}
	end
	local function eraseCurrentWave(index)
		if index~=#currentWaves then
			currentWaves[index] = currentWaves[#currentWaves]
		end
		currentWaves[#currentWaves] = nil
	end
	function self.spawnUnits()
		bilboardStats = bilboardStats or Core.getBillboard("stats")
		if bilboardStats:getInt("life")>0 then
			local i=1
			while i<=#currentWaves do
				local current = currentWaves[i]
				if not spawns then
					pathBilboard = pathBilboard and pathBilboard or Core.getBillboard("Paths")
					if not pathBilboard then
						abort("No path bilboard")
					end
					spawns = pathBilboard and pathBilboard:getTable("spawns") or {}
					if #spawns==0 then
						abort("No spawn points detected\n")
					end
				end
				currentSpawn = current[current.waveUnitIndex]
				if not currentSpawn then
					eraseCurrentWave(i)
				else
					local  currentSpawningNPC = currentSpawn
					--count down untill spawn
					currentSpawn.delay =  currentSpawn.delay - Core.getDeltaTime()
					if  currentSpawn.delay<0.0 then
						
						--inform path render system that the first wave has spawned
						Core.getGlobalBillboard("Paths"):setBool("started", true)
						
						if spawnPattern==SPAWN_PATTERN.Random then
							spawnCurrentUnit(current,math.randomInt(1, #spawns))
						elseif spawnPattern==SPAWN_PATTERN.Clone then
							for i=1, #spawns do
								if Core.isInMultiplayer()==false or Core.getNetworkClient():isPlayerIdInUse(spawns[i].island:getPlayerId())==true then
									spawnCurrentUnit(current,i)
								end
							end
						elseif spawnPattern==SPAWN_PATTERN.Grouped then
							if not npc[currentSpawn.npc] then
								--currentPortalId = currentPortalId==#spawns and 1 or currentPortalId+1
								currentPortalId = ((current.waveCount+current.groupCounter)%(#spawns))+1
								current.groupCounter = current.groupCounter + 1
							end
							
							spawnCurrentUnit(current,currentPortalId, currentSpawn.pathOffset, currentSpawn.npcScale, currentSpawn.hpScale, currentSpawn.animationSpeed)
						else
							abort("Not implemented\n")
							spawnCurrentUnit(current,math.randomInt(1, #spawns))
						end
						--get next unit to spawn
						current.waveUnitIndex = current.waveUnitIndex + 1
						local nextSpawn = current[current.waveUnitIndex]
						if nextSpawn then
							--update time for the next spawn
							nextSpawn.delay = nextSpawn.delay + currentSpawn.delay
						else
							eraseCurrentWave(i)
							i = i - 1
						end
					end
					i = i + 1
				end
			end
		end
	end
	local function syncSpawnNpc(param)
		local tab = totable(param)
		local target = tonumber(Core.getIndexOfNetworkName(tab.netName))
		if target==0 then
			local islands = this:getPlayerNode():findAllNodeByTypeTowardsLeaf(NodeId.island)
			local island = nil
			for i=1, #islands do
				if islands[i]:getIslandId()==tab.islandId then
					island = islands[i]
					break
				end
			end
			local npcNode = SceneNode.new()
			island:addChild( npcNode )
			npcNode:setLocalPosition( tab.pos )
			local npcScript = npcNode:loadLuaScript(tab.scriptName)
			npcScript:setScriptNetworkId(tab.netName)
			--
			--Force update
			--
			npcNode:update()
			--path points
			comUnit:sendTo(npcScript:getIndex(), "setPathPoints", tab.pathList)
			--add new npc to waypoints, that have been passed
			for index,position in pairs(tab.wayPoints) do
				comUnit:sendTo(npcScript:getIndex(), "byPassedWaypoint", position )
			end
			return npcScript:getIndex()
		end
	end
	
	local function spawnNextGroup()
		if waveCount==0 then
			syncChangeWave(1)
			comUnit:sendTo("EventManager","spawnNextGroup","")
		else
			local i=1
			while i<=#currentWaves do
				local current = currentWaves[i]
				if currentWaves[i][1].waveIndex==waves[waveCount][1].waveIndex then
					local index = 2
					local fakeWave = {waveUnitIndex=2,[1]=current[1]}
					while current[current.waveUnitIndex] do
						--end wave if we reach a splitter, and we have added units to the current list
						if current[current.waveUnitIndex].npc=="none" then
							if index>2 then
								--add the new fake wave (end of group)
								currentWaves[#currentWaves+1] = fakeWave
								comUnit:sendTo("statsMenu","setWaveNpcIndex",current.waveUnitIndex)
								return
							end
						else
							fakeWave[index] = current[current.waveUnitIndex]
							index = index + 1
						end
						current.waveUnitIndex = current.waveUnitIndex + 1
					end
					--add the new fake wave (end of wave)
					currentWaves[#currentWaves+1] = fakeWave
					comUnit:sendTo("statsMenu","setWaveNpcIndex",current.waveUnitIndex)
					return
				end
				i = i + 1
			end
		end
	end
	local function removeNextDelay()
		local success = false
		local wCount = waveCount<=1 and 1 or waveCount
		local index = wCount==1 and 3 or 2
		--loop all added waves that will spawn
		for i=1, #currentWaves do
			if currentWaves[i][1].waveIndex==wCount then
				--we found the wave
				index = math.max(index, currentWaves[i].waveUnitIndex)
				while currentWaves[i][index] do
					local item = currentWaves[i][index]
					if item.npc == "none" and item.delay>0.01 then
						item.delay = 0.0	
						currentWaves[i][index+1].delay = 0.5
						--
						success = true
						break
					end
					index = index + 1
				end
				--there should not be any more with this wave number
				break
			end
		end
		--
		if not success then
			local d1 = currentWaves
			abort()
		end
	end
	--used by event_world0.lua, the purpose is to force a group to spawn
	function self.addGroupToSpawn(wave,position,group)
		fixedGroupToSpawn[wave] = fixedGroupToSpawn[wave] or {}
		fixedGroupToSpawn[wave][position] = group
	end
	function self.disableUnit(npcName)
		disableUnits[npcName] = true
	end
	local function syncEvent(param)
		local tab = totable(param)
		waveSpawnInformation = tab
		self.generateWaves(tab.numWaves, tab.difficultBase, tab.difficultIncreaser, tab.startSpawnWindow, tab.globalSeed)
	end
	local function syncWaveData(param)
		local waveData = totable(param)
		if waveData and waveData.index and waveData.wave then
			waves[waveData.index] = waveData.wave
		else
			abort("waveData is ill formed, should be like {index=1, wave={}}")
		end
	end
	function self.init(comUnitTable)
		comUnitTable["NetGenerateWave"] = syncEvent
		comUnitTable["NetWaveData"] = syncWaveData
		comUnitTable["NetSpawnNpc"] = syncSpawnNpc
		comUnitTable["spawnNextGroup"] = spawnNextGroup
		comUnitTable["removeNextDelay"] = removeNextDelay
		comUnitTable["startWaves"] = startButtonPressed
		comUnitTable["resendWaveData"] = resendWaveData
		--
		--	SteamStat id
		--
		local fileName = mapInfo.getMapFileName()
		local index1 = fileName:match(".*/()")
		index1 = index1 and index1 or 1
		local index2 = fileName:match(".*%.()")
		if index1 and index2 then
			fileName = fileName:sub(index1,index2-2)
			local i=1
			local len = fileName:len()
			local count=0
			repeat
				i = fileName:find("%s")
				if i then
					local str = fileName:sub(1,i-1)
					if i<=fileName:len() then
						str = str..string.upper(fileName:sub(i+1,i+1))
					end
					fileName = str..fileName:sub(i+2,fileName:len())
				end
			until not i
		end
		return true
	end
	function wavesToGenerate(pNumWaves)
		if Core.isInMultiplayer() then
			if Core.getNetworkClient():isAdmin() then
				return pNumWaves
			end
			return 2
		end
		return pNumWaves
	end
	function self.generateWaves(pNumWaves,difficultBase,difficultIncreaser,startSpawnWindow,pSeed)
		--pNumWaves = 2
		numWaves = wavesToGenerate(pNumWaves)
		comUnit:sendTo("stats", "setWave", mapInfo.getStartWave())
		comUnit:sendTo("stats", "setMaxWave", numWaves)
			
		local spawnBuilder = spawnWaveBuilder.new()
		waves = spawnBuilder.generateWaves(pNumWaves,difficultBase, difficultBase+difficultIncreaser, startSpawnWindow, pSeed )
			
		spawnListPopulated = true
		
		
		local multiplayerGenerateData = {}
		
		if Core.getNetworkClient():isAdmin() then
			multiplayerGenerateData.numWaves = pNumWaves
			multiplayerGenerateData.difficultBase = difficultBase
			multiplayerGenerateData.difficultIncreaser = difficultIncreaser
			multiplayerGenerateData.startSpawnWindow = startSpawnWindow
			multiplayerGenerateData.globalSeed = seed
			
			--comUnit:sendNetworkSyncSafe("NetGenerateWave",tabToStrMinimal(multiplayerGenerateData))
			sendNetworkSyncSafe("NetGenerateWave",tabToStrMinimal(multiplayerGenerateData))
			--the data must be sent in seperate wave as the system has a max package size of 2^16-3
			for i=1, numWaves do
				local tData = {index=i,wave=waves[i]}
				sendNetworkSyncSafe("NetWaveData",tabToStrMinimal(tData))
			end
		elseif Core.isInMultiplayer() then
			--Change back to correct amount of waves for secondary players
			numWaves = pNumWaves
			comUnit:sendTo("stats", "setWave", mapInfo.getStartWave())
			comUnit:sendTo("stats", "setMaxWave", numWaves)
		end
			
		return true
	end
	
	return self
end