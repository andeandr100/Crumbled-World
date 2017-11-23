require("Game/mapInfo.lua")
--this = SceneNode()

local timer = 0.0
function restartMap()
	local mapInfo = MapInfo.new()
	
	waveHistory = {}
	scoreHistory = {}
	currentWave = mapInfo.getStartWave()
	
	billboard:setDouble("gold", startGold or 1000)
	billboard:setDouble("goldGainedTotal", startGold or 1000)
	billboard:setDouble("goldGainedFromKills", 0.0)
	billboard:setDouble("goldGainedFromInterest", 0.0)
	billboard:setDouble("goldGainedFromWaves", billboard:getDouble("gold"))
	billboard:setDouble("goldGainedFromSupportTowers", 0.0)
	billboard:setDouble("goldInsertedToTowers", 0.0)
	billboard:setDouble("goldLostFromSelling", 0.0)
	billboard:setDouble("defaultGold", startGold or 1000)
	billboard:setDouble("interestrate",0.0020)
	billboard:setDouble("activeInterestrate",0.0020)
	--
	billboard:setDouble("totalDamageDone", 0.0)
	--
	billboard:setInt("life", 20)
	billboard:setDouble("score", 0.0)
	billboard:setFloat("difficult", 1.0)
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
	billboard:setInt("alive enemies", 0)
	billboard:setInt("wave", 0)
	billboard:setInt("killedLessThan5m",0)
	billboard:setString("timerStr","0s")
	billboard:setInt("killCount",0)
	billboard:setInt("spawnCount",0)
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
	LOG("STATS.RESTARTWAVE("..tostring(wave)..")\n")
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
		billboard:setInt("life", item["life"])--the total of units you can let through before losing
		billboard:setDouble("score", item["score"])--your highscore
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
		updateTimerStr()
	end
end
function create()
	LOG("STATS.CREATE()\n")
	if Core.getScriptOfNetworkName("stats") then
		return false
	end
	Core.setScriptNetworkId("stats")
	comUnit = Core.getComUnit()
	comUnit:setCanReceiveTargeted(true)
	comUnit:setName("stats")
	billboard = comUnit:getBillboard()
	if Core.isInMultiplayer() then
		netSyncTimer = Core.getTime()
	end
	
	local mapInfo = MapInfo.new()
	
	waveHistory = {}
	currentWave = mapInfo.getStartWave()
	
	
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
	comUnitTable["setLife"] = handleSetLife
	comUnitTable["setMaxLife"] = handleSetMaxLife
	comUnitTable["setGold"] = handleSetGold
	comUnitTable["setStartGold"] = handleSetStartGold
	comUnitTable["addGold"] = handleAddGold
	comUnitTable["addGoldNoScore"] = handleAddGoldNoScore
	comUnitTable["addGoldWaveBonus"] = handleAddGoldWaveBonus
	comUnitTable["addTotalDmg"] = handleAddTotalDamage
	comUnitTable["goldInterest"] = handleGoldInterest
	comUnitTable["removeGold"] = handleRemoveGold
	comUnitTable["setInterestRateOnKill"] = handleSetInterestRateOnKill
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
	--
	comUnitTable["setWave"] = handleSetwave
	comUnitTable["setMaxWave"] = handleSetMaxwave
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
	comUnitTable["addSpawn"] = handleAddSpawn
	comUnitTable["killedLessThan5m"] = handleKilledLessThan5m
	--
	
	
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
	billboard:setInt("life", tonumber(numLife))
	billboard:setDouble("activeInterestrate",billboard:getDouble("interestrate")*(billboard:getInt("life")/billboard:getInt("maxLife")))
	updateScore()
end
function handleSetMaxLife(maxNumLife)
	billboard:setInt("maxLife", tonumber(maxNumLife))
	billboard:setDouble("activeInterestrate",billboard:getDouble("interestrate")*(billboard:getInt("life")/billboard:getInt("maxLife")))
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
function handleAddGoldWaveBonus(amount)
	handleAddGold(amount)
	billboard:setDouble("goldGainedFromWaves",billboard:getDouble("goldGainedFromWaves")+tonumber(amount))
end
--player earn gold on all real kills (repar spawns and hydras>1 does not grant any gold/interest)
function handleGoldInterest(multiplyer)
	local interestEarned = billboard:getDouble("gold")*tonumber(multiplyer)*billboard:getDouble("activeInterestrate")
	handleAddGold( interestEarned )
	billboard:setDouble( "goldGainedFromInterest", billboard:getDouble("goldGainedFromInterest")+interestEarned )
end
function handleSetInterestRateOnKill(interest)
	billboard:setDouble("interestrate",tonumber(interest))
	billboard:setDouble("activeInterestrate",billboard:getDouble("interestrate")*(billboard:getInt("life")/billboard:getInt("maxLife")))
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
end
function handleNpcReachedEnd(param)
	billboard:setInt("life", billboard:getInt("life")-tonumber(param))
	if billboard:getInt("life")<0 then
		billboard:setInt("life",0)
	end
	billboard:setDouble("activeInterestrate",billboard:getDouble("interestrate")*(billboard:getInt("life")/billboard:getInt("maxLife")))
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
		print("======== "..index.." spawned on wave "..wave)
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
	
	local d0 = billboard:exist(tostring(index));
	local dt = billboard;
	if billboard:getInt(tostring(index))==currentWave then
		--local count = billboard:getInt("killCount")+1
		billboard:setInt( "killCount", billboard:getInt("killCount")+1)
		local next = #statsPerKillTable[currentWave]+1
		statsPerKillTable[currentWave][next] = {
			--GOLD
			tostring(billboard:getDouble("goldGainedTotal"))..";"..
			tostring(billboard:getDouble("goldGainedFromKills"))..";"..
			tostring(billboard:getDouble("goldGainedFromInterest"))..";"..
			tostring(billboard:getDouble("goldGainedFromWaves"))..";"..
			tostring(billboard:getDouble("goldGainedFromSupportTowers"))..";"..
			tostring(billboard:getDouble("goldInsertedToTowers"))..";"..
			tostring(billboard:getDouble("goldLostFromSelling"))..";"..
			--SCORE
			tostring(billboard:getInt("score"))..";"..
			tostring(billboard:getDouble("totalTowerValue"))..";"..
			tostring(billboard:getInt("life"))..";"..
			--TOWERS
			tostring(billboard:getInt("towersBuilt"))..";"..
			tostring(billboard:getInt("wallTowerBuilt"))..";"..
			tostring(billboard:getInt("towersSold"))..";"..
			tostring(billboard:getInt("towersUpgraded"))..";"..
			tostring(billboard:getInt("towersSubUpgraded"))..";"..
			tostring(billboard:getInt("towersBoosted"))..";"..
			--ENEMIES
			tostring(billboard:getDouble("spawnCount"))..";"..
			tostring(billboard:getDouble("killCount"))..";"..
			tostring(billboard:getDouble("totalDamageDone"))
		}
	--	scoreHistory[currentWave][#scoreHistory[currentWave]+1] = billboard:getInt("score")
	--	billboard:setTable("scoreHistory",scoreHistory)		--EXPANSIVE
		
--		local c1 = Config("test")
--		local item = c1:get("root")
--		item:setTable( statsPerKillTable )
--		c1:save()
	--	addheader(panel,"Enemies")
	--	local label12 = addLine(panel,14,"Spawned:")
	--	local label13 = addLine(panel,15,"Killed:")
	--	local label14 = addLine(panel,16,"Damage:")
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
		for i=1, #waveDamages do
			averageDamage = averageDamage + waveDamages[i]
		end
		averageDamage = math.round(averageDamage / #waveDamages)
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
			
			local kills = 0
			local speed = billboard:exist("speed") and billboard:getInt("speed") or 1
			local str = Core.getNetworkClient():getUserName()..";"..Core.getNetworkClient():getClientId()..";"..billboard:getInt("gold")..";"..math.round(totalDamage)..";"..speed..";"..math.floor(Core.getNetworkClient():getPing()*1000)..";"..averageDamage..";"..kills
			
			comUnit:sendNetworkSyncSafeTo("InGameMenu","NETclientInfo",str)
			comUnit:sendTo("InGameMenu","NETclientInfo",str)
			netSyncTimer = Core.getTime()
		end
	end
	return true
end