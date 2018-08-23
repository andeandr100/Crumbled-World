require("Game/mapInfo.lua")
--this = SceneNode()

local timer = 0.0
local interesetMultiplyerOnKill = 1.0
local isCircleMap = false

function restartMap()
	local mapInfo = MapInfo.new()
	
	waveHistory = {}
	scoreHistory = {}
	currentWave = mapInfo.getStartWave()
	billboard:erase("scoreHistory")
	billboard:setDouble("gold", startGold or 1000)
	billboard:setDouble("goldGainedTotal", startGold or 1000)
	billboard:setDouble("goldGainedFromKills", 0.0)
	billboard:setDouble("goldGainedFromInterest", 0.0)
	billboard:setDouble("goldGainedFromWaves", billboard:getDouble("gold"))
	billboard:setDouble("goldGainedFromSupportTowers", 0.0)
	billboard:setDouble("goldInsertedToTowers", 0.0)
	billboard:setDouble("goldLostFromSelling", 0.0)
	billboard:setDouble("defaultGold", startGold or 1000)
	--
	billboard:setDouble("totalDamageDone", 0.0)
	--
	handleSetMaxLife()
	handleSetLife(billboard:getInt("maxLife"))
	billboard:setDouble("score", 0.0)
	billboard:setFloat("difficult", 1.0)
	billboard:setBool("gameEnded",false)
	--
	billboard:setInt("towersSold", 0)
	billboard:setInt("towersBuilt", 0)
	billboard:setInt("towersUpgraded", 0)
	billboard:setInt("towersSubUpgraded", 0)
	billboard:setInt("towersBoosted", 0)
	billboard:setInt("wallTowerBuilt", 0)
	billboard:setInt("minigunTowerBuilt", 0)
	billboard:setInt("arrowTowerBuilt", 0)
	billboard:setInt("ElectricTower", 0)
	billboard:setInt("swarmTowerBuilt", 0)
	billboard:setInt("bladeTowerBuilt", 0)
	billboard:setInt("missileTowerBuilt", 0)
	billboard:setInt("quakeTowerBuilt", 0)
	billboard:setInt("supportTowerBuilt", 0)
	--
	billboard:setInt("aliveEnemies", 0)			--not counting spawned enemies
	billboard:setInt("wave", 0)
	billboard:setBool("waveRestarted",false)
	billboard:setInt("killedLessThan5m",0)
	billboard:setString("timerStr","0s")
	billboard:setInt("killCount",0)
	billboard:setInt("spawnCount",0)
	billboard:setInt("hasMoreScoreThanPreviousBestGame", oldScoreTable and 0 or -2)
	billboard:setInt("scorePreviousBestGame", oldScoreTable and 0 or -1)
	statsPerKillTable = {version=1}
	--
	--	Localy calculated
	--
	billboard:setDouble("totalTowerValue",0.0)
	--all billboard string "1","2","3",... and so on are all pregiven to npc spawns
	--
	LOG("STATS.RESTARTMAP()\n")
	
end
function restartWave(wave)
	local d1 = waveHistory
	local item = waveHistory[wave]
	currentWave = wave
	statsPerKillTable[currentWave] = {}
	LOG("STATS.RESTARTWAVE("..tostring(wave)..")\n")
	billboard:erase("scoreHistory")
	if not item then
		error("the wave must be cretated, to be able to restore it")
	else
		billboard:setDouble("gold", item["gold"] )--how much gold
		billboard:setDouble("defaultGold", item["defaultGold"])--how much gold you start the game with
		billboard:setDouble("goldGainedTotal", item["goldGainedTotal"])
		billboard:setDouble("goldGainedFromKills", item["goldGainedFromKills"])
		billboard:setDouble("goldGainedFromInterest", item["goldGainedFromInterest"])
		billboard:setDouble("goldGainedFromWaves", item["goldGainedFromWaves"])
		billboard:setDouble("goldGainedFromSupportTowers", item["goldGainedFromSupportTowers"])
		billboard:setDouble("goldInsertedToTowers", item["goldInsertedToTowers"])
		billboard:setDouble("goldLostFromSelling", item["goldLostFromSelling"])
		billboard:setDouble("totalDamageDone", item["totalDamageDone"])--the total damage done by all towers
		billboard:setDouble("DamagePreviousWave", item["DamagePreviousWave"])--the total damage done the previous wave
		billboard:setDouble("DamageTotal", item["DamageTotal"])
		billboard:setDouble("waveGold", item["waveGold"])--the amount of gold that can be erarned as xp in the "leveler" game mode
		billboard:setDouble("totalHp", item["totalHp"])--the total amount of hp that will spawn this wave, in the "leveler" game mode
		billboard:setDouble("score", item["score"])--your highscore
		billboard:setBool("waveRestarted", true)
		billboard:setInt("wave", wave)--the current wave number
		billboard:setInt("killedLessThan5m",item["killedLessThan5m"])--achivemenet
		billboard:setInt("towersSold", item["towersSold"])
		billboard:setInt("towersBuilt", item["towersBuilt"])
		billboard:setInt("towersUpgraded", item["towersUpgraded"])
		billboard:setInt("towersSubUpgraded", item["towersSubUpgraded"])
		billboard:setInt("wallTowerBuilt", item["wallTowerBuilt"])
		billboard:setInt("minigunTowerBuilt", item["minigunTowerBuilt"])
		billboard:setInt("arrowTowerBuilt", item["arrowTowerBuilt"])
		billboard:setInt("ElectricTower", item["ElectricTower"])
		billboard:setInt("swarmTowerBuilt", item["swarmTowerBuilt"])
		billboard:setInt("bladeTowerBuilt", item["bladeTowerBuilt"])
		billboard:setInt("missileTowerBuilt", item["missileTowerBuilt"])
		billboard:setInt("quakeTowerBuilt", item["quakeTowerBuilt"])
		billboard:setInt("supportTowerBuilt", item["supportTowerBuilt"])
		billboard:setInt("killCount", item["killCount"])
		billboard:setInt("spawnCount", item["spawnCount"])
		timer = wave<=1 and 0 or item.timer
		handleSetMaxLife()
		handleSetLife(math.max(1,item["life"]))
		updateTimerStr()
	end
	updateScore()
end
function create()
	local mapInfo = MapInfo.new()
	--
	LOG("STATS.CREATE()\n")
	if Core.getScriptOfNetworkName("stats") then
		return false
	end
	Core.setScriptNetworkId("stats")
	comUnit = Core.getComUnit()
	comUnit:setCanReceiveTargeted(true)
	if not comUnit:setName("stats") then
		error("STATS.CREATE() failed because billboard name is used")
		return false
	end
	billboard = comUnit:getBillboard()
	if Core.isInMultiplayer() then
		netSyncTimer = Core.getTime()
	end
	--
	local f1 = File("Data/Dynamic/CampaignScore/"..mapInfo.getMapName().."__"..mapInfo.getLevel().."_"..mapInfo.getGameMode()..".st")	
	local writeToFile = true
	if f1:exist() then
		oldScoreTable = totable(f1:getContent())
	end
	--
	
	waveHistory = {}
	currentWave = mapInfo.getStartWave()
	isCircleMap = mapInfo.isCricleMap()
	
	
	restartListener = Listener("Restart")
	restartListener:registerEvent("restart", restartMap)
	restartWaveListener = Listener("RestartWave")
	restartWaveListener:registerEvent("restartWave", restartWave)
	
	restartMap()
	billboard:setInt("maxWave", 100)
	billboard:setInt("NPCSpawnedThisWave", 0)
	billboard:setInt("NPCSpawnsThisWave", 0)
	billboard:setInt("totalNPCSpawns", 0)

	--ComUnitCallbacks
	comUnitTable = {}
	comUnitTable["setInteresetMultiplyerOnKill"] = handleInteresetMultiplyerOnKill
	comUnitTable["setLife"] = abort
	comUnitTable["setGold"] = handleSetGold
	comUnitTable["setStartGold"] = handleSetStartGold
	comUnitTable["addGold"] = handleAddGold
	comUnitTable["addGoldLostFromSelling"] = HandleAddGoldLostFromSelling
	comUnitTable["addGoldNoScore"] = handleAddGoldNoScore
	comUnitTable["addGoldWaveBonus"] = handleAddGoldWaveBonus
	comUnitTable["addTotalDmg"] = handleAddTotalDamage
	comUnitTable["goldInterest"] = handleGoldInterest
	comUnitTable["removeGold"] = handleRemoveGold
	--
	comUnitTable["addTowersSold"] = handleAddTowerSold
	comUnitTable["addTowerBuilt"] = handleAddTowerBuilt
	comUnitTable["addTowerUpgraded"] = handleAddTowerUpgraded
	comUnitTable["addTowerSubUpgraded"] = handleAddTowerSubUpgraded
	comUnitTable["addTowerBoosted"] = handleAddTowerBoosted
	comUnitTable["addWallTowerBuilt"] = handleAddWallTowerBuilt
	comUnitTable["addMinigunTowerBuilt"] = handleAddMinigunTowerBuilt
	comUnitTable["addArrowTowerBuilt"] = handleAddArrowTowerBuilt
	comUnitTable["addElectricTowerBuilt"] = handleAddElectricTowerBuilt
	comUnitTable["addSwarmTowerBuilt"] = handleAddSwarmTowerBuilt
	comUnitTable["addBladeTowerBuilt"] = handleAddBladeTowerBuilt
	comUnitTable["addMissileTowerBuilt"] = handleAddMissileTowerBuilt
	comUnitTable["addQuakeTowerBuilt"] = handleAddQuakeTowerBuilt
	comUnitTable["addSupportTowerBuilt"] = handleAddSupportTowerBuilt
	--
	comUnitTable["updateTowerValue"] = handleUpdateTowerValue
	--
	comUnitTable["npcReachedEnd"] = handleNpcReachedEnd
	comUnitTable["setAliveEnemies"] = handleAliveEnemies
	--
	comUnitTable["setWave"] = handleSetwave
	comUnitTable["setMaxWave"] = handleSetMaxwave
	comUnitTable["setGameEnded"] = handleSetGameEnded
	--
	comUnitTable["setBillboardDouble"] = handleSetBillboardDouble
	comUnitTable["setBillboardInt"] = handleSetBillboardInt
	comUnitTable["addBillboardDouble"] = handleAddBillboardDouble
	comUnitTable["addBillboardInt"] = handleAddBillboardInt
	comUnitTable["setBillboardString"] = handleSetBillboardString
	--
	comUnitTable["addWaveGold"] = handleAddWaveGold
	comUnitTable["removeWaveGold"] = handleRemoveWaveGold
	comUnitTable["setTotalHp"] = handleSetTotalHp
	comUnitTable["removeTotalHp"] = handleRemoveTotalHp
	--
	comUnitTable["npcSpawnedWave"] = handleNpcSpawnedWave
	comUnitTable["setNPCSpawnedThisWave"] = handleSetNPCSpawnedThisWave
	comUnitTable["setNPCSpawnsThisWave"] = handleSetNPCSpawnsThisWave
	comUnitTable["setTotalNPCSpawns"] = handleSetTotalNPCSpawns
	comUnitTable["addKill"] = handleAddKill
	comUnitTable["showScore"] = handleSaveScore
	comUnitTable["addSpawn"] = handleAddSpawn
	comUnitTable["killedLessThan5m"] = handleKilledLessThan5m
	
	
	buildNode = this:findNodeByType(NodeId.buildNode)
	waveDamages = {}
	averageDamage = 0
	towerList = {skip=20}
	totalDamage = 0
	updateScoreTime = -1.0
	
	cfg = Config("test")
	local var = cfg:get("setTable")
	var:setTable(var:getTable())
	cfg:save()
	
	return true
end
function updateScore()
	billboard:setDouble("score", billboard:getDouble("totalTowerValue") + billboard:getDouble("gold") + (billboard:getInt("life")*100) + billboard:getDouble("goldGainedFromInterest") )
	updateScoreIconStatus()
end
	
function handleInteresetMultiplyerOnKill(mul)
	interesetMultiplyerOnKill = tonumber(mul)
end
function handleAddTotalDamage(dmg)
	billboard:setDouble("totalDamageDone", billboard:getDouble("totalDamageDone")+tonumber(dmg))
end
function handleKilledLessThan5m()
	billboard:setInt("killedLessThan5m",billboard:getInt("killedLessThan5m")+1)
	if billboard:getInt("killedLessThan5m")>=5 then
		comUnit:sendTo("SteamAchievement","IKnowWhatIAmDoing","")
	end
end
function handleSetLife(numLife)
	assert(tonumber(numLife)<=billboard:getInt("maxLife"),"cant set more life than max")
	local mapInfo = MapInfo.new()
	billboard:setInt("life", tonumber(numLife))
	if mapInfo.getGameMode()=="training" then
		billboard:setDouble("activeInterestrate",0.0)	
	else
		if mapInfo.isCartMap() or mapInfo.isCricleMap() then
			billboard:setDouble("activeInterestrate",0.002)
		else
			billboard:setDouble("activeInterestrate",0.002*(billboard:getInt("life")/billboard:getInt("maxLife")))
		end
	end
	updateScore()
end
function handleSetMaxLife()
	local mapInfo = MapInfo.new()
	if mapInfo.isCartMap() then
		billboard:setInt("maxLife", 1)
		handleSetLife(1)
	elseif mapInfo.isCricleMap() then
		billboard:setInt("maxLife", 50)
		handleSetLife(50)
	else
		billboard:setInt("maxLife", tonumber(20))
		handleSetLife(tonumber(20))
	end
end
function handleSetStartGold(amount)
	startGold = tonumber(amount)
	handleSetGold(amount)
end
function handleSetGold(amount)
	billboard:setDouble("gold", tonumber(amount))
	billboard:setDouble("goldGainedTotal", tonumber(amount))
	billboard:setDouble("defaultGold", tonumber(amount))
	updateScore()
end
function handleAddGold(amount)
	billboard:setDouble("gold", billboard:getDouble("gold")+tonumber(amount))
	billboard:setDouble("goldGainedTotal", billboard:getDouble("goldGainedTotal")+tonumber(amount))
	updateScore()
end
function handleAddGoldNoScore(amount)
	billboard:setDouble("gold", billboard:getDouble("gold")+tonumber(amount))
	updateScore()
end
function HandleAddGoldLostFromSelling(amout)
	billboard:setDouble("goldLostFromSelling", billboard:getDouble("goldLostFromSelling")+tonumber(amount))
	updateScore()
end
function handleAddGoldWaveBonus(amount)
	handleAddGold(amount)
	billboard:setDouble("goldGainedFromWaves",billboard:getDouble("goldGainedFromWaves")+tonumber(amount))
end
--player earn gold on all real kills (repar spawns and hydras>1 does not grant any gold/interest)
function handleGoldInterest(multiplyer)
	if interesetMultiplyerOnKill>0.00001 then
		local interestEarned = billboard:getDouble("gold")*tonumber(multiplyer)*billboard:getDouble("activeInterestrate")*interesetMultiplyerOnKill
		handleAddGold( interestEarned )
		billboard:setDouble( "goldGainedFromInterest", billboard:getDouble("goldGainedFromInterest")+interestEarned )
	end
end
function handleRemoveGold(amount)
	billboard:setDouble("gold", billboard:getDouble("gold")-tonumber(amount))
	billboard:setDouble("goldInsertedToTowers", billboard:getDouble("goldInsertedToTowers")+tonumber(amount))
	--
	handleUpdateTowerValue()
	updateScore()
end
function handleSetMaxwave(inWave)
	billboard:setInt("maxWave", inWave)
end
function handleSetGameEnded(set)
	billboard:setBool("gameEnded",set)
end
function handleAliveEnemies(aliveCount)
	billboard:setInt("aliveEnemies", aliveCount)
end
function handleSetwave(inWave)
	billboard:setInt("wave", inWave)
	currentWave = inWave
	timer = inWave==1 and 0 or timer
--	scoreHistory[inWave] = {}
	statsPerKillTable[inWave] = {}
	waveHistory[inWave] = {
		life = billboard:getDouble("life"),
		score = billboard:getDouble("score"),
		gold = billboard:getDouble("gold"),
		defaultGold = billboard:getDouble("defaultGold"),
		goldGainedTotal = billboard:getDouble("goldGainedTotal"),
		goldGainedFromKills = billboard:getDouble("goldGainedFromKills"),
		goldGainedFromInterest = billboard:getDouble("goldGainedFromInterest"),
		goldGainedFromWaves = billboard:getDouble("goldGainedFromWaves"),
		goldGainedFromSupportTowers = billboard:getDouble("goldGainedFromSupportTowers"),
		goldInsertedToTowers = billboard:getDouble("goldInsertedToTowers"),
		goldLostFromSelling = billboard:getDouble("goldLostFromSelling"),
		totalDamageDone = billboard:getDouble("totalDamageDone"),
		DamagePreviousWave = billboard:getDouble("DamagePreviousWave"),
		DamageTotal = billboard:getDouble("DamageTotal"),
		waveGold = billboard:getDouble("waveGold"),
		totalHp = billboard:getDouble("totalHp"),
		timer = timer,
		--
		killedLessThan5m = billboard:getDouble("killedLessThan5m"),
		towersSold = billboard:getInt("towersSold"),
		towersBuilt = billboard:getInt("towersBuilt"),
		towersUpgraded = billboard:getInt("towersUpgraded"),
		towersSubUpgraded = billboard:getInt("towersSubUpgraded"),
		towersBoosted = billboard:getInt("towersBoosted"),
		wallTowerBuilt = billboard:getInt("wallTowerBuilt"),
		minigunTowerBuilt = billboard:getInt("minigunTowerBuilt"),
		arrowTowerBuilt = billboard:getInt("arrowTowerBuilt"),
		ElectricTower = billboard:getInt("ElectricTower"),
		swarmTowerBuilt = billboard:getInt("swarmTowerBuilt"),
		bladeTowerBuilt = billboard:getInt("bladeTowerBuilt"),
		missileTowerBuilt = billboard:getInt("missileTowerBuilt"),
		quakeTowerBuilt = billboard:getInt("quakeTowerBuilt"),
		supportTowerBuilt = billboard:getInt("supportTowerBuilt"),

		--statistics
		killCount = billboard:getDouble("killCount"),
		spawnCount = billboard:getDouble("spawnCount")
	}
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	Core.getComUnit():sendTo("builder"..node:getClientId(), "newWave", inWave)
	updateScoreTime = 0.5
	--
	setStatsPerKillTableOn(0)
	updateScore()
end
function handleNpcReachedEnd(param)
	handleSetLife(math.max(0,billboard:getInt("life")-tonumber(param)))
end
function handleAddTowerSold()
	billboard:setInt("towersSold", billboard:getInt("towersSold")+1)
	if billboard:getInt("towersSold")==5 then
		Core.getComUnit():sendTo("SteamAchievement","Seller","")
	end
	--
	handleUpdateTowerValue()
	updateScore()
end
function handleAddTowerBuilt()
	billboard:setInt("towersBuilt", billboard:getInt("towersBuilt")+1)
end
function handleAddTowerUpgraded()
	billboard:setInt("towersUpgraded", billboard:getInt("towersUpgraded")+1)
end
function handleAddTowerSubUpgraded()
	billboard:setInt("towersSubUpgraded", billboard:getInt("towersSubUpgraded")+1)
end
function handleAddTowerBoosted()
	billboard:setInt("towersBoosted", billboard:getInt("towersBoosted")+1)
end
function handleAddWallTowerBuilt()
	billboard:setInt("wallTowerBuilt", billboard:getInt("wallTowerBuilt")+1)
end
function handleAddMinigunTowerBuilt()
	billboard:setInt("minigunTowerBuilt", billboard:getInt("minigunTowerBuilt")+1)
	handleAddTowerBuilt()
end
function handleAddArrowTowerBuilt()
	billboard:setInt("arrowTowerBuilt", billboard:getInt("arrowTowerBuilt")+1)
	handleAddTowerBuilt()
end
function handleAddElectricTowerBuilt()
	billboard:setInt("ElectricTower", billboard:getInt("ElectricTower")+1)
	handleAddTowerBuilt()
end
function handleAddSwarmTowerBuilt()
	billboard:setInt("swarmTowerBuilt", billboard:getInt("swarmTowerBuilt")+1)
	handleAddTowerBuilt()
end
function handleAddBladeTowerBuilt()
	billboard:setInt("bladeTowerBuilt", billboard:getInt("bladeTowerBuilt")+1)
	handleAddTowerBuilt()
end
function handleAddMissileTowerBuilt()
	billboard:setInt("missileTowerBuilt", billboard:getInt("missileTowerBuilt")+1)
	handleAddTowerBuilt()
end
function handleAddQuakeTowerBuilt()
	billboard:setInt("quakeTowerBuilt", billboard:getInt("quakeTowerBuilt")+1)
	handleAddTowerBuilt()
end
function handleAddSupportTowerBuilt()
	billboard:setInt("supportTowerBuilt", billboard:getInt("supportTowerBuilt")+1)
	handleAddTowerBuilt()
end
function handleSetBillboardDouble(param)
	local bName,bValue = string.match(param, "(.*);(.*)")
	if not bName or not bValue then
		error("string was not formated correctly, should be like \"(.*);(.*)\". input=="..tostring(param))
	end
	billboard:setDouble(bName,tonumber(bValue))
end
function handleSetBillboardInt(param)
	local bName,bValue = string.match(param, "(.*);(.*)")
	if not bName or not bValue then
		error("string was not formated correctly, should be like \"(.*);(.*)\". input=="..tostring(param))
	end
	billboard:setInt(bName,tonumber(bValue))
end
function handleAddBillboardDouble(param)
	local bName,bValue = string.match(param, "(.*);(.*)")
	if not bName or not bValue then
		error("string was not formated correctly, should be like \"(.*);(.*)\". input=="..tostring(param))
	end
	if billboard:exist(bName) then
		billboard:setDouble(bName,billboard:getDouble(bName)+tonumber(bValue))
	else
		billboard:setDouble(bName,tonumber(bValue))
	end
end
function handleAddBillboardInt(param)
	local bName,bValue = string.match(param, "(.*);(.*)")
	if not bName or not bValue then
		error("string was not formated correctly, should be like \"(.*);(.*)\". input=="..tostring(param))
	end
	if billboard:exist(bName) then
		billboard:setInt(bName,billboard:getInt(bName)+tonumber(bValue))
	else
		billboard:setInt(bName,tonumber(bValue))
	end
end
function handleSetBillboardString(param)
	local bName,bValue = string.match(param, "([^;]+);([^;]+)")
	billboard:setString(bName,bValue)
end
function handleNpcSpawnedWave(param)
	local index,wave = string.match(param, "([^;]+);([^;]+)")
	if currentWave==tonumber(wave) then
		billboard:setInt(index, tonumber(wave))
	end
end
function handleSetNPCSpawnedThisWave(param)
	billboard:setInt("NPCSpawnedThisWave", param)
end
function handleSetNPCSpawnsThisWave(param)
	billboard:setInt("NPCSpawnsThisWave", param)
end
function handleSetTotalNPCSpawns(param)
	billboard:setInt("totalNPCSpawns", param)
end
function handleAddKill(param,index)
	local next = 1
	if billboard:getInt(tostring(index))==currentWave then
		if not statsPerKillTable[currentWave] then
			statsPerKillTable[currentWave] = {}
		end
		billboard:setInt( "killCount", billboard:getInt("killCount")+1)
		next = #statsPerKillTable[currentWave]+1
		setStatsPerKillTableOn(next)
	end
end
function setStatsPerKillTableOn(index)
	if currentWave>=1 then
		statsPerKillTable[currentWave][index] = {
			--GOLD
			billboard:getDouble("gold"),
			billboard:getDouble("goldGainedTotal"),
			billboard:getDouble("goldGainedFromKills"),
			billboard:getDouble("goldGainedFromInterest"),
			billboard:getDouble("goldGainedFromWaves"),
			billboard:getDouble("goldGainedFromSupportTowers"),
			billboard:getDouble("goldInsertedToTowers"),
			billboard:getDouble("goldLostFromSelling"),
			--SCORE
			billboard:getInt("score"),
			billboard:getDouble("totalTowerValue"),
			billboard:getInt("life"),
			--TOWERS
			billboard:getInt("towersBuilt"),
			billboard:getInt("wallTowerBuilt"),
			billboard:getInt("towersSold"),
			billboard:getInt("towersUpgraded"),
			billboard:getInt("towersSubUpgraded"),
			billboard:getInt("towersBoosted"),
			--ENEMIES
			billboard:getDouble("spawnCount"),
			billboard:getDouble("killCount"),
			billboard:getInt("totalDamageDone")
		}
	end
end
function updateScoreIconStatus()
	if oldScoreTable then
		if currentWave>0 and oldScoreTable[currentWave] and oldScoreTable[currentWave][1] then
			local index = statsPerKillTable[currentWave] and #statsPerKillTable[currentWave] or 0
			local t1 = oldScoreTable[currentWave]	--waveTable
			local ts = t1[math.min(#t1,index)]		--killtable
			local kScore = ts[9]					--score value
			local set = kScore<billboard:getInt("score") and 1 or (kScore>billboard:getInt("score") and -1 or 0)
			print("========= "..tostring(kScore).."<"..tostring(billboard:getInt("score")).." =========")
			--  1 == we have more score now
			--  0 == equal score
			-- -1 == we are below in score then previous best round
			-- -2 == no previous score listings
			billboard:setInt("hasMoreScoreThanPreviousBestGame",  set)
			billboard:setInt("scorePreviousBestGame", kScore)
		else
			billboard:setInt("hasMoreScoreThanPreviousBestGame",  0)
		end
	end
end
function handleSaveScore()
	billboard:setTable("scoreHistory",statsPerKillTable)
	if billboard:getInt("life")>0 then
		local mapInfo = MapInfo.new()	
		local f1 = File("Data/Dynamic/CampaignScore/"..mapInfo.getMapName().."__"..mapInfo.getLevel().."_"..mapInfo.getGameMode()..".st")
		local writeToFile = true
		if f1:exist() then
			local table = totable(f1:getContent())
			local lastWaveTab = table[#table]
			local lastKillTab = lastWaveTab[#lastWaveTab]
			local lastScore = lastKillTab[9]
			writeToFile = lastScore<billboard:getInt("score")
		end
		if writeToFile then
			if f1:createNewFile() then
				local str = tabToStrMinimal(statsPerKillTable)
				f1:setContent(str, str:len())
			end
		end
	end
end
function handleAddSpawn()
	billboard:setInt("spawnCount", billboard:getInt("spawnCount")+1)
end
--
function updateXpPerGold()
	--bilboardStats:getDouble("waveGold")/bilboardStats:getDouble("totalHp")
	local tHP = math.max(1000.0,billboard:getDouble("totalHp"))
	local wGold = math.max(0.0,billboard:getDouble("waveGold"))
	--print("updateXpPerGold("..wGold.."/"..tHP..") == "..(wGold/tHP).."\n")
	billboard:setDouble("xpPerDamage",wGold/tHP)
end
function handleAddWaveGold(param)
	billboard:setDouble("waveGold",billboard:getDouble("waveGold")+tonumber(param))
	--print("WaveGold = "..billboard:getDouble("waveGold").."\n")
	updateXpPerGold()
end
function handleRemoveWaveGold(param)
	billboard:setDouble("waveGold",billboard:getDouble("waveGold")-tonumber(param))
	--print("WaveGold = "..billboard:getDouble("waveGold").."\n")
	updateXpPerGold()
end
function handleSetTotalHp(param)
	billboard:setDouble("totalHp",tonumber(param))
	updateXpPerGold()
end
function handleRemoveTotalHp(param)
	billboard:setDouble("totalHp",billboard:getDouble("totalHp")-tonumber(param))
	updateXpPerGold()
end
--
function handleUpdateTowerValue()
	local towers = buildNode:getBuildingList()
	local totalValue = 0.0
	for i=1, #towers do
		local script = towers[i]:getScriptByName("tower")
		local towerBillboard = script and script:getBillboard() or nil
		if towerBillboard and towerBillboard:getBool("isNetOwner") then
			totalValue = totalValue + towerBillboard:getDouble("value")
		end
	end
	billboard:setDouble("totalTowerValue",totalValue)
end
function waveChanged()
	local lastWaveDmg = 0
	local towers = buildNode:getBuildingList()
	totalDamage = 0
	for i=1, #towers do
		local script = towers[i]:getScriptByName("tower")
		local towerBillboard = script and script:getBillboard() or nil
		if towerBillboard and towerBillboard:getBool("isNetOwner") then
			lastWaveDmg = lastWaveDmg + towerBillboard:getDouble("DamagePreviousWave")
			totalDamage = totalDamage + towerBillboard:getDouble("DamageTotal")
		end
		
	end
	
	if lastWaveDmg > 0 then
		--Average wave damage over the last 3 wave
		waveDamages[#waveDamages+1] = lastWaveDmg
		if #waveDamages > 5 then
			table.remove(waveDamages,1)
		end
		averageDamage = 0
		local last3WaveDamage = 1
		local count = 0
		local i=#waveDamages
		while waveDamages[i] and count~=3 do
			last3WaveDamage = last3WaveDamage + waveDamages[i]
			count = count + 1
			i = i - 1
		end
		if count>=1 then
			averageDamage = last3WaveDamage/count
		else
			averageDamage = 0
		end
	end
end
function updateTimerStr()
	if currentWave>=1 then
		timer = timer + Core.getDeltaTime()
		local str = ""
		local left = timer
		if left>60.0 then
			local min = math.floor(left/60.0)
			left = left - (min*60.0)
			str = str..tostring(min).."m "
		end
		str = str..tostring(math.floor(left)).."s"
		billboard:setString("timerStr",str)
	else
		billboard:setString("timerStr","0s")
	end
end
function update()
	--Handle communication
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message]~=nil then
			comUnitTable[msg.message](msg.parameter,msg.fromIndex)
		end
	end
	updateTimerStr()
	if isCircleMap then
		handleSetLife(50-billboard:getInt("aliveEnemies"))
	end
	if netSyncTimer then
		
		--update wave damage, this can only be done after the towers has updated, this can take a 0.1 seconds
		if updateScoreTime > 0.0 then
			updateScoreTime = updateScoreTime - Core.getDeltaTime()
			if updateScoreTime <= 0.0 then
				waveChanged()
				handleUpdateTowerValue()
				updateScore()
			end
		end
		
		if Core.getTime()-netSyncTimer>0.5 then
			
			local dataTab = { name = Core.getNetworkClient():getUserName(),
							clientId = Core.getNetworkClient():getClientId(),
							gold = billboard:getInt("gold"),
							goldTotal = billboard:getInt("goldGainedTotal"),
							totalDamage = math.round(totalDamage),
							averageDamage = math.round(averageDamage),
							speed = billboard:exist("speed") and billboard:getInt("speed") or 1,		
							ping = math.floor(Core.getNetworkClient():getPing()*1000),
							kills = math.round(billboard:getDouble("killCount"))
						}
			local tabstr = tabToStrMinimal(dataTab)
			comUnit:sendNetworkSyncSafeTo("InGameMenu","NETclientInfo",tabstr)
			comUnit:sendTo("InGameMenu","NETclientInfo",tabstr)
			netSyncTimer = Core.getTime()
		end
	end
	return true
end
function destroy()
--	comUnit:setName("")
--	comUnit:setCanDisplayBillboard(false)
--	comUnit = nil
end