require("Game/mapInfo.lua")
require("Game/campaignData.lua")
--this = SceneNode()
SPAWN_PATTERN = {
	Random = 1,
	Clone = 2,
	Grouped = 3
}
SpawnManager = {}
function SpawnManager.new()
	local self = {}
	
	local firstNpcOfWaveHasSpawned = false
	
	local totalNpcSpawned = 0
	
	local mapInfo = MapInfo.new()
	local STARTWAVE = mapInfo.getStartWave()
	local waveCount = STARTWAVE		--what wave we are currently playing
	local comUnit = Core.getComUnit()
	local bilboardStats = Core.getBillboard("stats")
	--local soulmanager
	local waveUnitIndex = 0
	local currentWaves = {}	--waves that are currently spawning
	local wait = 15			--gives the player more time to setup the first defense
	local waitBase = wait
	local state = 0
	local numWaves = 100	--this should not be possible to reach at all
	local waves = {}
	local goldMultiplayerOnKills = 1.0
	local waveInfo = {}
	local fixedGroupToSpawn = {}
	local disableUnits = {}
	local npc = {}
	local npcCounter = {}
	local mapStatId = ""
	local steamStatMinPlayedTime = 0.0
	local cData = CampaignData.new()
	local soundWind = Sound("wind1",SoundType.STEREO)
	local spawnListPopulated = false
	local spawnPattern = SPAWN_PATTERN.Random
	local npcPathOffset
	--keybinds
	local keyBinds = Core.getBillboard("keyBind")
	local keyBindRevertWave
	--
	local pathBilboard
	local spawns
	local isCartMap = false
	local currentPortalId = 1
	local currentSpawn
	local restartListener
	local destroyInNFrames = nil
	local restartInWaves = nil
	local startTime = Core.getGameTime()
	--this:addChild(soundWind)
	--
	--
	local totalSpawned = 0
	local spawnedThisWave = 0

	function self.spawnUnitsPattern( pattern )
		spawnPattern = pattern
	end
	
	function self.setGoldMultiplayerOnKills(multiplyer)
		assert(multiplyer>=0,"setGoldMultiplayerOnKills(multiplyer), must be a number >=0")
		goldMultiplayerOnKills = multiplyer
	end
	function self.isAnythingSpawning()
		LOG("self.isAnythingSpawning() == "..tostring(#currentWaves>=1))
		return #currentWaves>=1
	end
	function self.isSpawnListPopulated()
		LOG("self.isSpawnListPopulated() == "..tostring(spawnListPopulated))
		return spawnListPopulated
	end
	function self.isFirstNpcOfWaveSpawned()
		LOG("self.isFirstNpcOfWaveSpawned() == "..tostring(firstNpcOfWaveHasSpawned))
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
		local npcNode = island:addChild(SceneNode())
		npcNode:setLocalPosition( localPos )
		npcNode:setSceneName("NPC")
		npcNode:createWork()
		return npcNode
	end
	function self.changeWave(pWaveCount)
		LOG("self.changeWave("..pWaveCount..")")
		waveCount = pWaveCount
		self.updateHpBillboard(waves[waveCount][1].hpMul)
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
	local function spawnCurrentUnit(currentWave,portalId)
		LOG("spawnCurrentUnit()")
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
			billboard:setDouble("pathOffset",npcPathOffset:randFloat()*2.0-1.0)
			print("NPC->setNetName() == "..netName.."\n")
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
	local function resendWaveData()
		comUnit:sendTo("stats", "setWave", mapInfo.getStartWave())
		comUnit:sendTo("stats", "setMaxWave", numWaves)
		--comUnit:sendTo("stats", "setTotalNPCSpawns", totalNpcSpawned)
		assert(waves, "waves is not initiated")
		comUnit:sendTo("statsMenu","waveInfo",waves)
	end
	function self.spawnWave(reloadIcons)
		LOG("spawnManager.spawnWave()")
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
		LOG("self.spawnUnits()")
		local i=1
		while i<=#currentWaves do
			local current = currentWaves[i]
			if not spawns then
				pathBilboard = pathBilboard and pathBilboard or Core.getBillboard("Paths")
				if not pathBilboard then
					error("No path bilboard")
				end
				spawns = pathBilboard and pathBilboard:getTable("spawns") or {}
				if #spawns==0 then
					error("No spawn points detected\n")
				end
			end
			currentSpawn = current[current.waveUnitIndex]
			if not currentSpawn then
				eraseCurrentWave(i)
			else
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
						spawnCurrentUnit(current,currentPortalId)
					else
						error("Not implemented\n")
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
	local function syncSpawnNpc(param)
		LOG("syncSpawnNpc()")
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
			local npcNode = SceneNode()
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
	local function calculateGoldValue(npcName,hpMul)
		local maxGoldMul = 1.50
		local relativeHp = npc[npcName].hp
		relativeHp = (relativeHp>500) and 500+((relativeHp-500)*0.20) or relativeHp	--decrease value for units with 500 or more hp
		local baseValue = relativeHp*0.0125											--500hp==6.25, 2500hp==11.25
		local ret = baseValue
		ret = (hpMul>1.0) and ret+(relativeHp*(hpMul-1.0)*0.0010) or ret			--all hpMul>1.0 has a value of 1%
		ret = (ret>baseValue*maxGoldMul) and baseValue*maxGoldMul or ret			--no value can be more than 1.5x more value than the base value
		return ret*goldMultiplayerOnKills
	end
	function self.updateHpBillboard(hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_rat_hp;"..npc.rat.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_rat_tank_hp;"..npc.rat_tank.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_skeleton_hp;"..npc.skeleton.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_scorpion_hp;"..npc.scorpion.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_fireSpirit_hp;"..npc.fireSpirit.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_electroSpirit_hp;"..npc.fireSpirit.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_skeleton_champion_front_hp;"..npc.skeleton_cf.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_skeleton_champion_back_hp;"..npc.skeleton_cb.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_turtle_hp;"..npc.turtle.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_dino_hp;"..npc.dino.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_reaper_hp;"..npc.reaper.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_stoneSpirit_hp;"..npc.stoneSpirit.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_hydra1_hp;"..npc.hydra1.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_hydra2_hp;"..npc.hydra2.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_hydra3_hp;"..npc.hydra3.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_hydra4_hp;"..npc.hydra4.hp*hpMul)
		comUnit:sendTo("stats","setBillboardInt","npc_hydra5_hp;"..npc.hydra5.hp*hpMul)
		--update all npc gold value
		comUnit:sendTo("stats","setBillboardInt","npc_rat_gold;"..calculateGoldValue("rat",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_rat_tank_gold;"..calculateGoldValue("rat_tank",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_skeleton_gold;"..calculateGoldValue("skeleton",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_scorpion_gold;"..calculateGoldValue("scorpion",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_fireSpirit_gold;"..calculateGoldValue("fireSpirit",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_electroSpirit_gold;"..calculateGoldValue("fireSpirit",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_skeleton_champion_front_gold;"..calculateGoldValue("skeleton_cf",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_skeleton_champion_back_gold;"..calculateGoldValue("skeleton_cb",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_turtle_gold;"..calculateGoldValue("turtle",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_dino_gold;"..calculateGoldValue("dino",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_reaper_gold;"..calculateGoldValue("reaper",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_stoneSpirit_gold;"..calculateGoldValue("stoneSpirit",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_hydra1_gold;"..calculateGoldValue("hydra1",hpMul))
		comUnit:sendTo("stats","setBillboardInt","npc_hydra2_gold;0")
		comUnit:sendTo("stats","setBillboardInt","npc_hydra3_gold;0")
		comUnit:sendTo("stats","setBillboardInt","npc_hydra4_gold;0")
		comUnit:sendTo("stats","setBillboardInt","npc_hydra5_gold;0")
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
	function self.init(comUnitTable)
		comUnitTable["NetGenerateWave"] = syncEvent
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
		isCartMap = mapInfo.isCartMap()
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
		mapStatId = fileName
		return true
	end
	function self.generateWaves(pNumWaves,difficultBase,difficultIncreaser,startSpawnWindow,seed)
		--pNumWaves = 2
		local multiplayerGenerateData = {}
		if Core.getNetworkClient():isAdmin() then
			multiplayerGenerateData.numWaves = pNumWaves
			multiplayerGenerateData.difficultBase = difficultBase
			multiplayerGenerateData.difficultIncreaser = difficultIncreaser
			multiplayerGenerateData.startSpawnWindow = startSpawnWindow
			multiplayerGenerateData.globalSeed = seed
			
			--comUnit:sendNetworkSyncSafe("NetGenerateWave",tabToStrMinimal(multiplayerGenerateData))
			sendNetworkSyncSafe("NetGenerateWave",tabToStrMinimal(multiplayerGenerateData))
		end
		
		if seed then
			local rand = Random(seed)
			npcPathOffset = Random(seed)
			numWaves = pNumWaves
			local isInMultiplayer = Core.isInMultiplayer()
			local addPerLevel = mapInfo.getAddPerLevel()
			local longestWave = 0.0
			totalNpcSpawned = 0
			local goldBousForWave = 200
			local startGold = 1000
			local totalGoldEarned = startGold
			local theoreticalGold = startGold-350--start cost of wall towers
			local theoreticalPaidHpPS = 0.0
			local theoreticalGoldPaid = 0.0
			local theoreticalMinimumScoreInterest = 0.0
			local timerAddBetweenWaves = 5+math.max(0.0,5*(1.0-difficultBase))
			local npcDelayAfterFirstTowerBuilt = 15.0							--delay for first wave
			local npcDelayBetweenWaves = math.clamp(8.0-((difficultBase-0.75)/0.35*5),3.0,8.0)	--delay for all other waves
			--
			comUnit:sendTo("stats", "setWave", mapInfo.getStartWave())
			comUnit:sendTo("stats", "setMaxWave", numWaves)
			--
			fixedGroupToSpawn.pos = 1
			--all spawns should be calculated with values and listed down
			--hero waves or pre selected spawns should be available
			--selection of the wave should be window based in a normaly distributed curve that moves down the spawn options of size 10 or similar
			--what script to use
			npc = 	{	rat =			{hp=275,	size=0.8,	script="NPC/npc_rat.lua"},--fast units
						skeleton =		{hp=450,	size=0.8,	script="NPC/npc_skeleton.lua"},
						scorpion =		{hp=600,	size=0.8,	script="NPC/npc_scorpion.lua"},
						rat_tank =		{hp=600,	size=0.8,	script="NPC/npc_rat_tank.lua"},--fast units
						fireSpirit =	{hp=750,	size=0.8,	script="NPC/npc_fireSpirit.lua"},--imune to fire, and restore some amount of hp by fire damage
						electroSpirit =	{hp=750,	size=0.8,	script="NPC/npc_electroSpirit.lua"},--imune to electricity, and restore some amount of hp by fire damage
						skeleton_cf =	{hp=1000,	size=0.8,	script="NPC/npc_skeleton_champion_front.lua"},--blocks physical damage
						skeleton_cb =	{hp=1000,	size=0.8,	script="NPC/npc_skeleton_champion_back.lua"},--blocks physical damage
						turtle =		{hp=2750,	size=0.8,	script="NPC/npc_turtle.lua"},--shield that abosorb all incoming damage
						dino =			{hp=1200,	size=0.8,	script="NPC/npc_dino.lua"},--heal itself if untoutched
						reaper =		{hp=1200,	size=0.8,	script="NPC/npc_reaper.lua"},--spawns npc_skeleton
						stoneSpirit =	{hp=2500,	size=0.8,	script="NPC/npc_stonespirit.lua"},
						hydra1 =		{hp=300,	size=0.8,	script="NPC/npc_hydra1.lua"},
						hydra2 =		{hp=350,	size=0.8,	script="NPC/npc_hydra2.lua"},--L2 totalHP = 350+(300*2) == 950
						hydra3 =		{hp=400,	size=0.8,	script="NPC/npc_hydra3.lua"},--L3 totalHP = 400+(350*2)+(300*4) == 2300
						hydra4 =		{hp=450,	size=0.8,	script="NPC/npc_hydra4.lua"},--L4 totalHP = 450+(400*2)+(350*4)+(300*8) == 5050
						hydra5 =		{hp=550,	size=0.8,	script="NPC/npc_hydra5.lua"},--L5 totalHP = 550+(450*2)+(400*4)+(350*8)+(300*16) == 9050
					}
			local groupCompOriginal = {
				--{{npc="rat",delay=0.0},{npc="rat_tank",delay=1},{npc="skeleton",delay=1},{npc="scorpion",delay=1},{npc="fireSpirit",delay=1},{npc="electroSpirit",delay=1},{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1},{npc="dino",delay=1},{npc="turtle",delay=1},{npc="reaper",delay=1},{npc="stoneSpirit",delay=1},{npc="hydra5",delay=1}},
		--		{{npc="rat",delay=0.0},{npc="rat_tank",delay=1},{npc="skeleton",delay=1},{npc="scorpion",delay=1},{npc="fireSpirit",delay=1},{npc="electroSpirit",delay=1},{npc="turtle",delay=1},{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1},{npc="dino",delay=1},{npc="reaper",delay=1},{npc="stoneSpirit",delay=1},{npc="hydra5",delay=1}},
		--		{{npc="rat",delay=0.0},{npc="rat_tank",delay=1},{npc="skeleton",delay=1},{npc="scorpion",delay=1},{npc="fireSpirit",delay=1},{npc="electroSpirit",delay=1},{npc="turtle",delay=1},{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1},{npc="dino",delay=1},{npc="reaper",delay=1},{npc="stoneSpirit",delay=1},{npc="hydra5",delay=1}},
		--		{{npc="rat",delay=0.0},{npc="rat_tank",delay=1},{npc="skeleton",delay=1},{npc="scorpion",delay=1},{npc="fireSpirit",delay=1},{npc="electroSpirit",delay=1},{npc="turtle",delay=1},{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1},{npc="dino",delay=1},{npc="reaper",delay=1},{npc="stoneSpirit",delay=1},{npc="hydra5",delay=1}},
--				{{npc="rat",delay=0.0},{npc="rat_tank",delay=1},{npc="skeleton",delay=1},{npc="scorpion",delay=1},{npc="fireSpirit",delay=1},{npc="electroSpirit",delay=1},{npc="turtle",delay=1},{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1},{npc="dino",delay=1},{npc="reaper",delay=1},{npc="stoneSpirit",delay=1},{npc="hydra5",delay=1}},
--				{{npc="rat",delay=0.0},{npc="rat_tank",delay=1},{npc="skeleton",delay=1},{npc="scorpion",delay=1},{npc="fireSpirit",delay=1},{npc="electroSpirit",delay=1},{npc="turtle",delay=1},{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1},{npc="dino",delay=1},{npc="reaper",delay=1},{npc="stoneSpirit",delay=1},{npc="hydra5",delay=1}},
--				{{npc="rat",delay=0.0},{npc="rat_tank",delay=1},{npc="skeleton",delay=1},{npc="scorpion",delay=1},{npc="fireSpirit",delay=1},{npc="electroSpirit",delay=1},{npc="turtle",delay=1},{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1},{npc="dino",delay=1},{npc="reaper",delay=1},{npc="stoneSpirit",delay=1},{npc="hydra5",delay=1}},
--				{{npc="rat",delay=0.0},{npc="rat_tank",delay=1},{npc="skeleton",delay=1},{npc="scorpion",delay=1},{npc="fireSpirit",delay=1},{npc="electroSpirit",delay=1},{npc="turtle",delay=1},{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1},{npc="dino",delay=1},{npc="reaper",delay=1},{npc="stoneSpirit",delay=1},{npc="hydra5",delay=1}},
--				{{npc="rat",delay=0.0},{npc="rat_tank",delay=1},{npc="skeleton",delay=1},{npc="scorpion",delay=1},{npc="fireSpirit",delay=1},{npc="electroSpirit",delay=1},{npc="turtle",delay=1},{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1},{npc="dino",delay=1},{npc="reaper",delay=1},{npc="stoneSpirit",delay=1},{npc="hydra5",delay=1}},
				--{{npc="rat",delay=0.0},{npc="rat",delay=1},{npc="rat_tank",delay=1},{npc="rat_tank",delay=1},{npc="scorpion",delay=1},{npc="scorpion",delay=1},{npc="turtle",delay=3},{npc="turtle",delay=3},{npc="dino",delay=1},{npc="dino",delay=1},{npc="hydra5",delay=1}},--blood npc
				--{{npc="rat_tank",delay=0.0},{npc="rat_tank",delay=0.15},{npc="rat_tank",delay=0.15},{npc="rat_tank",delay=0.15},{npc="rat_tank",delay=0.15},{npc="rat_tank",delay=0.15},{npc="rat_tank",delay=0.15},{npc="rat_tank",delay=0.15}},
				--{{npc="scorpion",delay=0.0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}},
				--{{npc="dino",delay=0.0},{npc="dino",delay=0.75},{npc="dino",delay=0.75},{npc="dino",delay=0.75}},
				--{{npc="skeleton_cf",delay=0.0},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton_cb",delay=0.4}},
				--{{npc="skeleton_cf",delay=1}},
				--{{npc="reaper",delay=0.0}},
				--{{npc="dino",delay=0.0}},
--				{{npc="hydra5",delay=0.0}},
--				{{npc="hydra5",delay=0.0}},
				--{{npc="electroSpirit",delay=0.0}},
				--{{npc="fireSpirit",delay=0.0}},
				--{{npc="turtle",delay=0.0}},
--				{{npc="turtle",delay=0.0}},
--				{{npc="turtle",delay=0.0}},
--				{{npc="stoneSpirit",delay=0.0}},
--				{{npc="dino",delay=0.0},{npc="dino",delay=0.75},{npc="dino",delay=0.75},{npc="dino",delay=0.75}},
--				{{npc="dino",delay=0.0},{npc="dino",delay=0.75},{npc="dino",delay=0.75},{npc="dino",delay=0.75}},
--				{{npc="reaper",delay=0.0},{npc="reaper",delay=1.5}},
--				{{npc="reaper",delay=0.0},{npc="reaper",delay=1.5}},
--				{{npc="reaper",delay=0.0},{npc="reaper",delay=1.5}},
--				{{npc="reaper",delay=0.0},{npc="reaper",delay=1.5}},	
--				{{npc="reaper",delay=0.0},{npc="reaper",delay=1.5}},
--				{{npc="turtle",delay=0.0}},
--				{{npc="turtle",delay=0.0}},
--				{{npc="turtle",delay=0.0}},
--				{{npc="turtle",delay=0.0}},
--				{{npc="turtle",delay=0.0}},
--				{{npc="turtle",delay=0.0}},
--				{{npc="turtle",delay=0.0}},
--				{{npc="turtle",delay=0.0}},
				--{{npc="reaper",delay=0.0},{npc="reaper",delay=1.5}},
		--		{{npc="reaper",delay=0.0},{npc="reaper",delay=1.5}},
		--		{{npc="reaper",delay=0.0},{npc="reaper",delay=1.5}},
				--{{npc="skeleton",delay=0.0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="turtle",delay=0.4},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}},
				--{{npc="rat",delay=0.0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}},--2000/2s <-> 1000ps
				--{{npc="rat_tank",delay=0.0},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40}},
				--{{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1}},
				--{{npc="skeleton_cf",delay=1},{npc="skeleton_cb",delay=1}},
				--{{npc="scorpion",delay=0.0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="turtle",delay=0.4},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}},
				--debug above
				--default hp/s that can be killed on straight line is == (650*0.7) == 455
				--(waveHP)/((bypasTime+spawnTime)*455) == value
				-- - --value>1.0 cant be killed on a straigth line with level 1 towers, and difficult set to 1.0
				-- - --value>2.0 cant be killed on 2 clean bypasses with level 1 towers, and difficult set to 1.0
				-- - --value difficult is offcourse lessen by that upgrades have a 10% damage incrase
				-- - --and of course that some tower can slow enemy speed that gives more time to kill them
				--(275*8)/(((12/4)+(7*0.25))*455) == 1.018
				{waveUseLimit=0},
				{waveUseLimit=1,{npc="rat",delay=0.0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}},--2000/2s <-> 1000ps
				--(450*8)/(((12/2)+(7*0.25))*455) == 1.021
				{{npc="skeleton",delay=0.0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}},
				--(600*6)/(((12/2)+(5*0.35))*455) == 1.021
				{{npc="scorpion",delay=0.0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}},
				--(800+(2*600)+(4*450))/(((12/2)+(2*0.4)+(4*0.3))*455) == 1.044
				{{npc="scorpion",delay=0.0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}},
				--((600*2)+(450*6))/(((12/2)+((2*0.35)+(6*0.25)))*455) == 1.045
				{{npc="scorpion",delay=0.0},{npc="scorpion",delay=0.35},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}},
				{{npc="scorpion",delay=0.0},{npc="scorpion",delay=0.35},{npc="electroSpirit",delay=0.4},{npc="electroSpirit",delay=0.5},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}},
				--((1200)+(450*6))/(((12/2)+((0.35)+(5*0.25)))*455) == 1.071
				{{npc="skeleton",delay=0.0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="reaper",delay=0.4}},
				--((1200)+(450*6))/(((12/2)+((0.75)+(5*0.25)))*455) == 1.031
				{{npc="dino",delay=0.0},{npc="skeleton",delay=0.75},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}},
				--?
				{{npc="skeleton",delay=0.0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="turtle",delay=0.4},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}},
				--(800*5)/(((12/2)+(4*0.5))*455) == 1.099
				{{npc="electroSpirit",delay=0.0},{npc="electroSpirit",delay=0.5},{npc="electroSpirit",delay=0.5},{npc="electroSpirit",delay=0.5},{npc="electroSpirit",delay=0.5}},
				--(800*5)/(((12/2)+(4*0.5))*455) == 1.099
				{{npc="fireSpirit",delay=0.0},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5}},
				--((3*600)+(6*275))/(((12/3.65)+(2*0.4)+(5*0.25)+1.25)*455) == 1.15
				{waveMin=10,{npc="rat_tank",delay=0.0},{npc="rat_tank",delay=0.4},{npc="rat_tank",delay=0.4},{npc="rat",delay=1.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}},
				--((800)+(8*450))/(((12/2)+(7*0.25))*455) == 1.248
				{{npc="electroSpirit",delay=0.0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}},
				--
				{{npc="skeleton_cf",delay=0.0},{npc="dino",delay=0.75},{npc="fireSpirit",delay=0.75},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5}},
				--(1200*4)/(((12/2)+(3*0.75))*455) == 1.279
				{waveUseLimit=1,{npc="dino",delay=0.0},{npc="dino",delay=0.75},{npc="dino",delay=0.75},{npc="dino",delay=0.75}},
				--((2*1000)+(8*450))/(((12/2)+(9*0.4))*455) == 1.282
				{{npc="skeleton_cf",delay=0.0},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton_cb",delay=0.4}},
				--(600*6)/(((12/3.25)+(5*0.40))*455) == 1.390
				{{npc="rat_tank",delay=0.0},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40}},
				--?
				{{npc="scorpion",delay=0.0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="turtle",delay=0.4},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}},
				--((2*1000)+(6*450)+(2*800))/(((12/2)+(9*0.4))*455) == 1.442
				{{npc="skeleton_cf",delay=0.0},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="electroSpirit",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton_cb",delay=0.4}},
				--((1200*4)+(275*6))/(((12/2)+((3*0.75)+(6*0.25)))*455) == 1.454
				{waveUseLimit=1,{npc="dino",delay=0.0},{npc="dino",delay=0.75},{npc="dino",delay=0.75},{npc="rat",delay=3.0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}},
				--(275*16)/(((12/4)+(16*0.2))*455) == 1.560
				{{npc="rat",delay=0.0},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2}},
				--A*B*C == ?
				{waveUseLimit=1,{npc="skeleton_cf",delay=0.0},{npc="reaper",delay=0.75}},
				--A*B*C == ?
				{waveUseLimit=1,{npc="reaper",delay=0.0},{npc="reaper",delay=1.5}},
				--((1*2500)+(4*800))/(((12/2)+(4*0.5))*455) == 1.56
				{waveUseLimit=1,{npc="stoneSpirit",delay=0.0},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="electroSpirit",delay=0.5},{npc="electroSpirit",delay=0.5}},
				--((2*1000)+(6*450)+(1000))*1.2/(((12/2)+(9*0.4))*455) == 1.56
				{waveUseLimit=1,{npc="skeleton_cf",delay=0.0},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="turtle",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton_cb",delay=0.4}},
				--(2*2500)/(((12/2)+1)*455) == 1.57
				{waveUseLimit=1,{npc="stoneSpirit",delay=0.0},{npc="stoneSpirit",delay=1.0}},
				--((1200*3)+(600*6))/(((12/2)+((5*0.35)+(3*0.75)))*455) == 1.58
				{waveUseLimit=1,{npc="dino",delay=0.0},{npc="scorpion",delay=0.75},{npc="scorpion",delay=0.35},{npc="dino",delay=0.65},{npc="scorpion",delay=0.75},{npc="scorpion",delay=0.35},{npc="dino",delay=0.65},{npc="scorpion",delay=0.75},{npc="scorpion",delay=0.35}},
				--(10800*0.70)/(((12/1.5)+0.75)*455) = 1.89
				{waveUseLimit=1,groupSpawnDepthMax=2,{npc="hydra5",delay=0.0}},
				{waveUseLimit=1,groupSpawnDepthMax=2,{npc="hydra5",delay=0.0}},
				{waveUseLimit=1,groupSpawnDepthMax=2,{npc="hydra5",delay=0.0}},
				--
				{waveUseLimit=1,{npc="dino",delay=0.0},{npc="dino",delay=0.75},{npc="turtle",delay=0.75},{npc="dino",delay=0.75},{npc="dino",delay=0.75}},
				--
				{waveUseLimit=1,{npc="skeleton_cf",delay=0.0},{npc="reaper",delay=0.75},{npc="reaper",delay=0.75}},
				--((1*2500)+(8*450))/(((12/2)+(7*0.25)+0.5)*455) == 1.625
				{waveUseLimit=1,{npc="stoneSpirit",delay=0.0},{npc="skeleton",delay=0.5},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}},
				--((1*2500)+(8*600))/(((12/2)+(7*0.35)+0.5)*455) == 1.793
				{waveUseLimit=1,{npc="stoneSpirit",delay=0.0},{npc="scorpion",delay=0.5},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}},
				--(600*10)/(((12/3.25)+(9*0.40))*455) == 1.808
				{waveUseLimit=1,{npc="rat_tank",delay=0.0},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40}},
				--
				{waveUseLimit=1,{npc="stoneSpirit",delay=0.0},{npc="turtle",delay=1.0},{npc="stoneSpirit",delay=1.0}},
				--(4*2500)/(((12/2)+(3*1))*455) == 2.254(unbeatable)
				--{{npc="stoneSpirit",delay=0.0},{npc="stoneSpirit",delay=1.25},{npc="stoneSpirit",delay=1.25},{npc="stoneSpirit",delay=1.25}}
			}
			--How many of each npc type that is allowed to spawn, this is so you dont get a wave of only dinos for example
			local waveUnitLimitOriginal = {
				rat = 16,
				skeleton =	math.huge,
				scorpion =	math.huge,
				rat_tank =	10,
				fireSpirit = 10,
				electroSpirit =	10,
				skeleton_cf = 2,
				skeleton_cb = 2,
				turtle = 2,
				dino =	5,
				reaper = 2,
				stoneSpirit = 2,
				hydra1 = 1,
				hydra2 = 1,
				hydra3 = 1,
				hydra4 = 1,
				hydra5 = 1,
				superHeavy = 4
			}
			--
			--
			--
			
			tCounter = 1
			
			--Time to init all waves
			local playTime = 0.0
			local nextWaveDelayTime = 0.0
			waves = {}
			for i=1, numWaves do
				local maxSpawnTime = 30.0
				local totalSpawnTime = math.min(maxSpawnTime,20+(i*0.30))--the calculated time to spawn npcs
				--launch difficulty (1.0 i max, and should never be used)[Because 1.0 is damge output limit and a of many other factors will make it unsustanable]{0.85 is probably max, increase difficultIncreaser instead}
				
				--adds time between spawned groups making powerful groups easier to handle, as you get more time to kill them
				--an exponential equation that picks up speed by how many levels that have passed. with the goal to out run the interest gain for gold 
				local difficult = (difficultIncreaser^i)+(i*(0.2/30))-math.max(0.0,(1.0-difficultBase))--((1.033+(0.0001*x))^x)
				local unitBypassMultiplyer = 0.95 + (0.5*(i/numWaves))--this value increases the amount of hp that spawns each wave
				local spawnHealthPerSecond = totalGoldEarned*0.7*difficult--0.7 magic number with no ties to reality anymore
				local hpMultiplyer = ((totalGoldEarned*difficultBase) / (startGold+50))*difficult--this directly increases the hp on the npcs (+50 is just to flatten the curve)
				--print("== "..hpMultiplyer.." = (("..totalGoldEarned.."*"..difficultBase..") / ("..startGold.."+50))*"..difficult)
				--
				local hardestGroupThatCanSpawn = startSpawnWindow + math.min( #groupCompOriginal-startSpawnWindow, math.floor(i*1.75)) + 1--hardestGroupThatCanSpawn (+1) is for bad algorithm and added dummy spawn
				--this is the total health points that can be sent out this wave
				local totalSpawnHP = spawnHealthPerSecond*totalSpawnTime*unitBypassMultiplyer*(isInMultiplayer and 1.5 or 1.0)
				local usedSpawnHP = 0.0
				--over stepping is easier, due to that it will take longer time before next spawn giving the user a time gap to kill the spawned units
				local bufferSpawnHP = 0.1
				local waveDetails = {}
				local waveDetailsInfo = {}
				local itemCount = 3--as 1 contains information and 1 is delay
				local spawnCount = {}
				local groupCountForWave = 0
				--
				--	Force npc limits, and superheavy comps, that are just out of this world
				--
				local waveUnitLimit = getCopyOfTable(waveUnitLimitOriginal)
				local function isGroupContainingLimitedUnits(group)
					for k,v in pairs(group) do
						if type(v)=="table" then
							if waveUnitLimit[v.npc] and waveUnitLimit[v.npc]<=0 then
								return true
							elseif v.npc=="hydra5" or v.npc=="hydra4" or v.npc=="stoneSpirit" or v.npc=="turtle" or v.npc=="reaper" or v.npc=="dino" then
								waveUnitLimit.superHeavy = waveUnitLimit.superHeavy - ( v.npc=="reaper" and 0.51 or (v.npc=="dino" and 0.26 or 1.0))
								return waveUnitLimit.superHeavy<=0.0
							end
						end
					end
					return false
				end
				local groupComp = getCopyOfTable(groupCompOriginal)
				local function popItem(groupComp,index)
					index = index+1
					while groupComp[index] do
						groupComp[index-1] = groupComp[index]
						index = index + 1
					end
					groupComp[index-1] = nil
				end
				local index = 1
				while groupComp[index] do
					if (groupComp[index].waveMin and i<groupComp[index].waveMin) or (groupComp[index].waveMax and i>groupComp[index].waveMax) then
						popItem(groupComp,index)
					else
						local index2 = 1
						while groupComp[index][index2] do
							if disableUnits[groupComp[index][index2].npc] then
								popItem(groupComp,index)
								index = index-1
								break
							end
							index2 = index2 + 1
						end
						index = index + 1
					end
				end
				
				--statistics
				--print("=== WAVE["..i.."]("..spawnHealthPerSecond*unitBypassMultiplyer..")\n")
				local towerExtreDamageForRouting = 1.0+(addPerLevel/2.5)
				local dpsPG = (1.0+(i*(0.30/30))*(1.0+math.min(0.30,0.30*(i/15))))*towerExtreDamageForRouting
				local toPay = ((spawnHealthPerSecond*unitBypassMultiplyer)-(theoreticalGoldPaid*dpsPG))/dpsPG
				--
--				if theoreticalGold>toPay then
--					theoreticalGoldPaid = theoreticalGoldPaid + toPay
--					theoreticalGold = theoreticalGold - toPay
--				end
				--
				theoreticalPaidHpPS = (spawnHealthPerSecond*unitBypassMultiplyer)
				
				--set wave info
				waveDetails[1] = {hpMul=hpMultiplyer, info=waveDetailsInfo, waveIndex=i}
				waveDetails[2] = {npc="none", delay=((i==1) and npcDelayAfterFirstTowerBuilt or npcDelayBetweenWaves)}
				local waveTotalTime = 0.0
				local waveGoldEarned = 0.0
				local waveNpcGold = 0.0
				waveInfo[i] = {}
				--spawn npcs untill we have passed the minimum hp goal
				--LOG("<while "..usedSpawnHP.."<"..totalSpawnHP.." and "..waveTotalTime.."<"..(totalSpawnTime*2.0).." do")
				while usedSpawnHP<totalSpawnHP and waveTotalTime<totalSpawnTime*2.0 do
					--LOG("while "..usedSpawnHP.."<"..totalSpawnHP.." and "..waveTotalTime.."<"..(totalSpawnTime*2.0).." do")
					if itemCount>3 then
						waveDetails[itemCount] = {npc="none",delay=(isInMultiplayer and 1.5 or timerAddBetweenWaves)}--add dead time after a group (groups are the peak spawn several times the average hp/s)
						itemCount = itemCount + 1
					end
					--
					local cost = 0
					local index = 1
					groupCountForWave = groupCountForWave + 1
					--
					--select a group to spawn and remove groups that cant be used any more
					--
					local group = {}
					if fixedGroupToSpawn[i] and fixedGroupToSpawn[i][groupCountForWave] then
						--the group is fixed  used function  self:addGroupToSpawn
						group = getCopyOfTable(fixedGroupToSpawn[i][groupCountForWave])
					else
						--select a random npc group and make sure it is allowed to spawn or remove it
						while true do
							local groupIndex = rand:range(1,math.min(#groupComp,hardestGroupThatCanSpawn))
							--print("groupIndex("..#groupComp..","..hardestGroupThatCanSpawn..") == "..groupIndex.."\n")
							group = getCopyOfTable(groupComp[groupIndex])
							if isGroupContainingLimitedUnits(groupComp[groupIndex]) then
								--if the group contains a unit that has reached limited spawn count, for this wave
								popItem(groupComp,groupIndex)--try again
							elseif groupComp[groupIndex].waveUseLimit and groupComp[groupIndex].waveUseLimit<=0 then
								--if the group has reach it limited spawn count, for this wave
								popItem(groupComp,groupIndex)--we broke the limit with this pass, continue
							elseif groupComp[groupIndex].groupSpawnDepthMax and groupCountForWave>groupComp[groupIndex].groupSpawnDepthMax then
								--if the npc has missed its spawn window
								popItem(groupComp,groupIndex)--try again
							else
								if groupComp[groupIndex].waveUseLimit then
									groupComp[groupIndex].waveUseLimit = groupComp[groupIndex].waveUseLimit-1
								end
								break
							end
						end
					end
					--
					--adding selected group to wave
					--
					local groupUnit = group[index]
					while groupUnit do
						--statistics
						totalNpcSpawned = totalNpcSpawned + 1
						waveTotalTime = waveTotalTime + groupUnit.delay
						--limits
						if waveUnitLimit[groupUnit.npc] then waveUnitLimit[groupUnit.npc] = waveUnitLimit[groupUnit.npc]-1 end
						--add unit to be spawned
						waveDetails[itemCount] = {npc=groupUnit.npc, delay=groupUnit.delay}--add the unit (creating new table to avoid using the same refference)
						cost = cost + (npc[groupUnit.npc].hp*hpMultiplyer)--calculate the cost
						itemCount = itemCount + 1
						--
						totalGoldEarned = totalGoldEarned + calculateGoldValue(groupUnit.npc,hpMultiplyer)
						waveGoldEarned = waveGoldEarned + calculateGoldValue(groupUnit.npc,hpMultiplyer)
						waveNpcGold = waveNpcGold + calculateGoldValue(groupUnit.npc,hpMultiplyer)
						--
						waveGoldEarned = waveGoldEarned + (theoreticalGold*tonumber(interestOnKill))
						--
						theoreticalGold = (theoreticalGold*(1.0+tonumber(interestOnKill))) + calculateGoldValue(groupUnit.npc,hpMultiplyer)--statistics
						
						--score += 400[estimated gold available]*interestOnKill*2*2[life/10==2, or on mincart map it is default 2]+goldEarnedFromKillingNPC
						theoreticalMinimumScoreInterest = theoreticalMinimumScoreInterest + (200.0*tonumber(interestOnKill)*2.0)
						--
						--add unit to wave info
						if waveDetailsInfo[groupUnit.npc] then
							waveDetailsInfo[groupUnit.npc].numEnemies = waveDetailsInfo[groupUnit.npc].numEnemies + 1
						else
							waveDetailsInfo[groupUnit.npc] = { name=groupUnit.npc, scriptName=npc[groupUnit.npc].script, numEnemies=1, npcSize=npc[groupUnit.npc].size}
						end
						-- continue
						index = index + 1
						groupUnit = group[index]
					end
					--add extra dead time for group cost
					usedSpawnHP = usedSpawnHP + cost
					nextWaveDelayTime = timerAddBetweenWaves
				end
				--LOG(">while "..usedSpawnHP.."<"..totalSpawnHP.." and "..waveTotalTime.."<"..(totalSpawnTime*2.0).." do")
--				if true then
--					local routePlanner = this:findNodeByType(NodeId.RoutePlanner)
--					local spawn = routePlanner:getRandomSpawnArea()
--					if spawn then
--						for k,v in pairs(waveDetailsInfo) do
--							spawn:addEnemyInfo(i, v)
--						end
--					end
--				end
				--
				totalGoldEarned = totalGoldEarned + goldBousForWave
				waveGoldEarned = waveGoldEarned + goldBousForWave
				--
				--add gold earned this wave
				theoreticalGold = theoreticalGold + goldBousForWave
				--remove gold for building costs
				local COSTPERWAVE = i>numWaves*0.5 and 1.3 or 0.7
				local waveCost = (waveNpcGold*COSTPERWAVE) + (i>numWaves*0.5 and (theoreticalGold*(1/(numWaves*0.175)))+100 or 0)
				waveCost = math.min(theoreticalGold , waveCost)
				theoreticalGold = theoreticalGold - waveCost
				theoreticalGoldPaid = theoreticalGoldPaid + waveCost
				--
				waveInfo[i].theoreticalGold = string.format("theoreticalGold: %.0f",theoreticalGold)
				--
				waveInfo[i].totalHp = usedSpawnHP
				waveInfo[i].waveGold = waveGoldEarned
				--print("waveInfo["..i.."].totalHp == "..waveInfo[i].totalHp.."\n")
--				print("waveInfo["..i.."].theoreticalGold == "..theoreticalGold)
				--
				waves[i] = waveDetails
				waveTotalTime = waveTotalTime + nextWaveDelayTime
				playTime = playTime + waveTotalTime + waitBase + 15.0 -- 15s time to kill last unit after it has spawned ;D
				
				longestWave = math.max(longestWave,waveTotalTime)
				--print("==== WAVE"..i..".time=="..waveTotalTime.."\n")
			end
			
			--print("\nWaves: "..tostring(waves).."\n")
			
			local hours=math.floor(playTime/3600)
			playTime = playTime - (hours*3600)
			local minutes=math.floor(playTime/60)
			--playTime = playTime - (minutes*60)
			--			print("=== minimalScore="..tostring(((totalGoldEarned+theoreticalMinimumScoreInterest)*0.75)+theoreticalMinimumScoreInterest+100))
--			abort()
--			LOG(tostring(waves))
--			LOG("=== longestWave="..longestWave.."s")
--			LOG("=== totalNpcSpawned="..totalNpcSpawned)
--			LOG("=== theoreticalGoldPaid="..theoreticalGoldPaid)
--			LOG("=== totalGoldEarned(guaranteed)="..totalGoldEarned)
--			LOG("=== theoreticalGold(Earned)="..(theoreticalGold+theoreticalGoldPaid))
--			LOG("=== interest="..(theoreticalGold+theoreticalGoldPaid-totalGoldEarned))
--			LOG("=== playTime=="..hours.."h "..minutes.."m")
--			abort()
			--
			--comUnit:sendTo("stats", "setTotalNPCSpawns", totalNpcSpawned)
			--1 Wait on tower to be built
			--2 Wait on timer
			--3 Wait on all enemies to die
			--4 money bonus for finished wave
			--5 Change Wave
			--6 Spawn Wave
			--7 Victory
			
			self.updateHpBillboard(0.1)--just fill the billboards
			
			spawnListPopulated = true
			
			comUnit:sendTo("statsMenu","waveInfo",waves)
		end
	
		return true
	end
	
	return self
end