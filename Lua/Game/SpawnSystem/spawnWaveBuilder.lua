require("Game/SpawnSystem/spawnGroups.lua") 

--this = SceneNode()

spawnWaveBuilder = {}
function spawnWaveBuilder.new()
	local self = {}
	local spawnGroups = SpawnGroups.new()
	
	local npcValueList = 	spawnGroups.getNPCValueList()
	local groupCompOriginal = spawnGroups.getNPCGroupList()
	local bossGroup = spawnGroups.getBossGroupList()
	local endWave = spawnGroups.getEndWaveList()
	local hydraSpawnedLastOnWave = 0
	endWave.count = #endWave
	--How many of each npc type that is allowed to spawn, this is so you dont get a wave of only dinos for example
	local waveUnitLimitOriginal = spawnGroups.getWaveUnitLimit()
	local groupSpawnCount = {}
	
	
	local randome = Random()
	
	local function getNumAvailableGroups(info)
		local availableGroupsForTheWay = 0
		for i=1, #groupCompOriginal do
			if groupCompOriginal[i].waveMin == nil or groupCompOriginal[i].waveMin <= info.wave then
				availableGroupsForTheWay = i
			end
		end
	
		if availableGroupsForTheWay <= 1 then
			error("No groups to spawn")
		end
		
		return availableGroupsForTheWay
	end
	
	local function canGroupBeSpawn(info, groupIndex)
		
		local groupInfo = groupCompOriginal[groupIndex]
		if groupInfo.waveMin and groupInfo.waveMin > info.wave then
			return false
		end
		if groupInfo.waveMax and groupInfo.waveMax < info.wave then
			return false
		end
		if groupInfo.waveUseLimit and groupSpawnCount[groupIndex] and groupInfo.waveUseLimit <= groupSpawnCount[groupIndex] then
			return false
		end
		if groupInfo.groupSpawnBefore and groupInfo.groupSpawnBefore > info.spawnedGroup then
			return false
		end
		if groupInfo.groupSpawnAfter and groupInfo.groupSpawnAfter < info.groupLeftToSpawn then
			return false
		end
		
		return true
		
	end
	
	local function getFirstAvailableGroup(info, startIndex)
		
		local groupIndex = startIndex
		for i=1, #groupCompOriginal do
			
			if canGroupBeSpawn( info, groupIndex ) then
				return groupIndex
			else
				groupIndex = (groupIndex + 1) >= #groupCompOriginal and 1 or (groupIndex + 1)
			end
		end
		--If all fails the first group should be safe
		return 1
	end
	
	local function getRandomGroup(info)
		
		local groupIndex = -1
		local availableGroups = getNumAvailableGroups(info)
		for n=1, 20 do
			local randomeGroupIndex = randome:range(1, availableGroups)
			if canGroupBeSpawn(info, randomeGroupIndex) then
				--group found set group index and then quit loop be increasing the n value
				groupIndex = randomeGroupIndex
				n = n + 100 
			end
		end
		if groupIndex == -1 then
			groupIndex = getFirstAvailableGroup(info, randome:range(1, availableGroups))
		end
		
		groupSpawnCount[groupIndex] = groupSpawnCount[groupIndex] and groupSpawnCount[groupIndex] + 1 or 1
		return groupCompOriginal[groupIndex]
	end
	
	local function getRandomBossGroup(info)
		
		local bossIndex = randome:range(1, #bossGroup)
		return bossGroup[ bossIndex ]
	end
	

	-- Here we calculate if the unit should be upgraded or not
	-- We use a reqursive function where we work first on left side of the group
	-- Then we swap to right side and then go back and forth until we are done calculating
	local function isUnitUpgraded(grupCount,upgradedCount,position, cloneSkip)
		if grupCount <= upgradedCount then
			return true
		elseif upgradedCount == 0 then
			return false
		else
			if cloneSkip ~= nil then
				if position <= grupCount-cloneSkip then
					return isUnitUpgraded(grupCount-cloneSkip,upgradedCount-1,position)
				else
					return position == (grupCount-cloneSkip+1)
				end
			else
				local skip = math.max( 2, math.ceil( (grupCount-upgradedCount)/upgradedCount ))
				if upgradedCount == 1 then
					--if we only have one upgraded unit left we upgrade the midle unit
					--Note that we are not in the clone scenario
					skip = math.ceil( grupCount / 2 )
				end
				if position <= skip then
					return position == skip
				else
					return isUnitUpgraded(grupCount-skip,upgradedCount-1,position-skip,skip)
				end
			end
		end
		return false
	end
	
	local function addGroupToWave(group, currentWave, waveDetails)
	
		local index = 1
		local groupUnit = group[index]
		local upgradeDelay = nil
		while groupUnit do
			local npcName = groupUnit.npc			
			local unitCount = groupUnit.count and groupUnit.count or 1
			
			--,upgrade={count=2,npcScale=1.5,pathOffset=0.0,hpScale=2,animationSpeed=0.75}
			
			for i=1, unitCount do
				local upgradeInfo = groupUnit.upgrade
				if upgradeInfo and isUnitUpgraded(unitCount, upgradeInfo.count, i) then
					upgradeDelay = upgradeInfo.delay and upgradeInfo.delay or groupUnit.delay
					currentWave[#currentWave+1] = {npc=npcName, delay=upgradeDelay, pathOffset=upgradeInfo.pathOffset, npcScale=upgradeInfo.npcScale, hpScale=upgradeInfo.hpScale, animationSpeed=upgradeInfo.animationSpeed}
				else
					--if previous unit has a upgradeDelay we use the biggest dealy
					local dealy = math.max( upgradeDelay or 0, groupUnit.delay or 0 )
					upgradeDelay = nil
					currentWave[#currentWave+1] = {npc=npcName, delay=dealy, pathOffset=groupUnit.pathOffset, npcScale=groupUnit.npcScale, hpScale=groupUnit.hpScale, animationSpeed=groupUnit.animationSpeed}
				end
			end
			
			if waveDetails[npcName] then
				waveDetails[npcName].numEnemies = waveDetails[npcName].numEnemies + unitCount
			else
				waveDetails[npcName] = { name=npcName, scriptName=npcValueList[npcName].script, numEnemies=unitCount, npcSize=npcValueList[npcName].size}
			end
			
			index = index + 1
			groupUnit = group[index]
		end
		
	end

	
	function self.generateWaves(numWaves,baseDifficult,maxDifficult,startSpawnWindow,seed)
		
		-- linearDifficultyWeight by increasing this value less money should be available for building bank tower
		-- a lower value linearDifficultyWeight will give the user more money in the early game to build bank tower
		-- a higher value means the enemies get harder faster making it harder to build bank tower
		-- limit of value [0,1] can not go outside this range, 0 scalar ony and 1 means linear calculation only
		local linearDifficultyWeight = 0.5
		
		-- A higher value means that the early game user have more time to earn money but exponintaly scales difficutly towards the end
		-- a lower value means harder early game and closer to linear scaling, still exponential growt
		-- change this value up and down to make early or end game harder.
		-- try to keep bettwen [1.5 & 3] do testing and select a good value
		local scalarExponent = 2
		local linearDifficulty = (maxDifficult - baseDifficult) * linearDifficultyWeight
		local scalarDfficulty = (maxDifficult - baseDifficult - linearDifficulty) / (numWaves / 10)^scalarExponent
		
		
		local waves = {}
		for n=1, numWaves do
			randome = Random(seed+n)
			local difficulty = baseDifficult + linearDifficulty * n + scalarDfficulty * (n / 10)^scalarExponent
			local waveDetails = {hpMul=difficulty, info={}, waveIndex=n}
			local currentWave = {}
			local groupCount = 5 + math.floor(n/5) * 2
			local spawnedGroup = 0
			local bossSpawned = false
			currentWave[1] = waveDetails
			currentWave[2] = {npc="none", delay=10}
			
			for g=1, groupCount do
				local groupLeftToSpawn = groupCount-spawnedGroup
				local info = {wave=n,spawnedGroup=spawnedGroup,groupLeftToSpawn=groupLeftToSpawn}
				
				if (g%5)==5 and bossSpawned == false and (spawnedGroup+1)*2 > groupCount then
					bossSpawned = true
					local bossGroup = getRandomBossGroup(info)
					addGroupToWave(bossGroup, currentWave, waveDetails.info)
				else
					local group = getRandomGroup(info)
					addGroupToWave(group, currentWave, waveDetails.info)
				end
				
				
				spawnedGroup = spawnedGroup + 1
				if g < groupCount then
					--Add a delay bettwen groups
					currentWave[#currentWave+1] = {npc="none", delay=4.5}
				end
			end
			
			waves[#waves+1] = currentWave		
		end
		
		return waves
		
	end

	return self
end