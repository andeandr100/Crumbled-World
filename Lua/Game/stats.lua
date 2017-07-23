--this = SceneNode()
function restartWave(wave)
	local d1 = waveHistory
	local item = waveHistory[wave]
	if not item then
		error("the wave must be cretated, to be able to restore it")
	else
		billboard:setDouble("gold", item["gold"] )--how much gold
		billboard:setDouble("defaultGold", item["defaultGold"])--how much gold you start the game with
		billboard:setDouble("totalGoldEarned", item["totalGoldEarned"])--the total amount of gold earned during the game
		billboard:setDouble("totalGoldInterestEarned", item["totalGoldInterestEarned"])--the total interest of gold earned during the game
		billboard:setDouble("totalGoldSupportEarned", item["totalGoldSupportEarned"])--the total amount of gold the support tower has earned
		billboard:setDouble("totalDamageDone", item["totalDamageDone"])--the total damage done by all towers
		billboard:setDouble("DamagePreviousWave", item["DamagePreviousWave"])--the total damage done the previous wave
		billboard:setDouble("DamageTotal", item["DamageTotal"])
		billboard:setDouble("waveGold", item["waveGold"])--the amount of gold that can be erarned as xp in the "leveler" game mode
		billboard:setDouble("totalHp", item["totalHp"])--the total amount of hp that will spawn this wave, in the "leveler" game mode
		billboard:setInt("life", item["life"])--the total of units you can let threw before losing
		billboard:setDouble("score", item["score"])--you highscore
		billboard:setInt("wave", wave)--the current wave number
		billboard:setInt("killedLessThan5m",item["killedLessThan5m"])--achivemenet
		billboard:setInt("towersSold", item["towersSold"])--achivemenet
	end
end
function create()
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
	waveHistory = {}
	
	restartWaveListener = Listener("RestartWave")
	restartWaveListener:registerEvent("restartWave", restartWave)
	
	billboard:setDouble("gold", 650)
	billboard:setDouble("defaultGold", 650)
	billboard:setDouble("totalGoldEarned", billboard:getInt("gold"))
	billboard:setDouble("totalGoldInterestEarned", 0.0)
	billboard:setDouble("totalGoldSupportEarned", 0.0)
	billboard:setDouble("totalDamageDone", 0.0)
	billboard:setInt("life", 20)
	billboard:setDouble("score", 0)
	billboard:setFloat("difficult", 1.0)
	billboard:setInt("alive enemies", 0)
	billboard:setInt("wave", 1)
	billboard:setInt("maxWave", 1)
	billboard:setInt("killedLessThan5m",0)
	--
	billboard:setInt("NPCSpawnedThisWave", 0)
	billboard:setInt("NPCSpawnsThisWave", 0)
	billboard:setInt("totalNPCSpawned", 0)
	billboard:setInt("totalNPCSpawns", 0)

	--ComUnitCallbacks
	comUnitTable = {}
	comUnitTable["setLife"] = handleSetLife
	comUnitTable["setMaxLife"] = handleSetMaxLife
	comUnitTable["setGold"] = handleSetGold
	comUnitTable["addGold"] = handleAddGold
	comUnitTable["addGoldNoScore"] = handleAddGoldNoScore
	comUnitTable["addGoldWaveBonus"] = handleAddGoldWaveBonus
	comUnitTable["addTotalDmg"] = handleAddTotalDamage
	comUnitTable["goldInterest"] = handleGoldInterest
	comUnitTable["removeGold"] = handleRemoveGold
	comUnitTable["addTowersSold"] = handleAddTowerSold
	comUnitTable["npcReachedEnd"] = handleNpcReachedEnd
	comUnitTable["setWave"] = handleSetwave
	comUnitTable["setMaxWave"] = handleSetMaxwave
	comUnitTable["setBillboardDouble"] = handleSetBillboardDouble
	comUnitTable["setBillboardInt"] = handleSetBillboardInt
	comUnitTable["addBillboardInt"] = handleAddBillboardInt
	comUnitTable["setBillboardString"] = handleSetBillboardString
	--
	comUnitTable["addWaveGold"] = handleAddWaveGold
	comUnitTable["removeWaveGold"] = handleRemoveWaveGold
	comUnitTable["setTotalHp"] = handleSetTotalHp
	comUnitTable["removeTotalHp"] = handleRemoveTotalHp
	--
	comUnitTable["setNPCSpawnedThisWave"] = handleSetNPCSpawnedThisWave
	comUnitTable["setTotalNPCSpawned"] = handleSetTotalNPCSpawned
	comUnitTable["setNPCSpawnsThisWave"] = handleSetNPCSpawnsThisWave
	comUnitTable["setTotalNPCSpawns"] = handleSetTotalNPCSpawns
	--
	comUnitTable["killedLessThan5m"] = handleKilledLessThan5m
	--
	
	
	buildNode = this:findNodeByType(NodeId.buildNode)
	waveDamages = {}
	averageDamage = 0
	towerList = {skip=20}
	totalDamage = 0
	updateScoreTime = -1.0
	ScoreScale = 1
	
	cfg = Config("test")
	local var = cfg:get("setTable")
	var:setTable(var:getTable())
	cfg:save()
	
	return true
end
function addScoreBasedOnAddedGold(addedGold)
	billboard:setDouble("score", billboard:getDouble("score") + addedGold * ScoreScale * (billboard:getInt("life") / 10.0) )
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
end
function handleSetMaxLife(maxNumLife)
	billboard:setInt("maxLife", tonumber(maxNumLife))
	ScoreScale = tonumber(maxNumLife) == 1 and 20 or 1
end
function handleSetGold(amount)
	billboard:setDouble("gold", tonumber(amount))
	billboard:setDouble("totalGoldEarned", tonumber(amount))
	billboard:setDouble("defaultGold", tonumber(amount))
end
function handleAddGold(amount)
	addScoreBasedOnAddedGold(tonumber(amount))
	billboard:setDouble("gold", billboard:getDouble("gold")+tonumber(amount))
	billboard:setDouble("totalGoldEarned", billboard:getDouble("totalGoldEarned")+tonumber(amount))
end
function handleAddGoldNoScore(amount)
	billboard:setDouble("gold", billboard:getDouble("gold")+tonumber(amount))
	billboard:setDouble("totalGoldEarned", billboard:getDouble("totalGoldEarned")+tonumber(amount))
end
function handleAddGoldWaveBonus(amount)
	handleAddGold(amount)
end
function handleGoldInterest(amount)
	local interestEarned = billboard:getDouble("gold")*tonumber(amount)
	handleAddGold( interestEarned )
	billboard:setDouble( "totalGoldInterestEarned", billboard:getDouble("totalGoldInterestEarned")+interestEarned )
end
function handleRemoveGold(amount)
	if billboard:getDouble("gold")-tonumber(amount) < 1.0 then
		print("\n##########################")
		print("Gold: "..billboard:getDouble("gold")-tonumber(amount))
		print("##########################")
	end
	billboard:setDouble("gold", billboard:getDouble("gold")-tonumber(amount))
end
function handleSetMaxwave(inWave)
	billboard:setInt("maxWave", inWave)
end
function handleSetwave(inWave)
	billboard:setInt("wave", inWave)
	waveHistory[inWave] = {
		life = billboard:getDouble("life"),
		score = billboard:getDouble("score"),
		gold = billboard:getDouble("gold"),
		defaultGold = billboard:getDouble("defaultGold"),
		totalGoldEarned = billboard:getDouble("totalGoldEarned"),
		totalGoldInterestEarned = billboard:getDouble("totalGoldInterestEarned"),
		totalGoldSupportEarned = billboard:getDouble("totalGoldSupportEarned"),
		totalDamageDone = billboard:getDouble("totalDamageDone"),
		DamagePreviousWave = billboard:getDouble("DamagePreviousWave"),
		DamageTotal = billboard:getDouble("DamageTotal"),
		waveGold = billboard:getDouble("waveGold"),
		totalHp = billboard:getDouble("totalHp"),
		--Achivements
		killedLessThan5m = billboard:getDouble("killedLessThan5m"),
		towersSold = billboard:getDouble("towersSold")
	}
	Core.getComUnit():sendTo("builder", "newWave", inWave)
	updateScoreTime = 0.5
end
function handleNpcReachedEnd(param)
	billboard:setInt("life", billboard:getInt("life")-tonumber(param))
	if billboard:getInt("life")<0 then
		billboard:setInt("life",0)
	end
end
function handleAddTowerSold()
	billboard:setInt("towersSold", billboard:getInt("towersSold")+1)
	if billboard:getInt("towersSold")==5 then
		Core.getComUnit():sendTo("SteamAchievement","Seller","")
	end
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
function handleSetNPCSpawnedThisWave(param)
	billboard:setInt("NPCSpawnedThisWave", param)
end
function handleSetTotalNPCSpawned(param)
	billboard:setInt("totalNPCSpawned", param)
end
function handleSetNPCSpawnsThisWave(param)
	billboard:setInt("NPCSpawnsThisWave", param)
end
function handleSetTotalNPCSpawns(param)
	billboard:setInt("totalNPCSpawns", param)
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
function update()
	--Handle communication
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message]~=nil then
			comUnitTable[msg.message](msg.parameter)
		end
	end
	if netSyncTimer then
		
		--update wave damage, this can only be done after the towers has updated, this can take a 0.1 seconds
		if updateScoreTime > 0.0 then
			updateScoreTime = updateScoreTime - Core.getDeltaTime()
			if updateScoreTime <= 0.0 then
				waveChanged()
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