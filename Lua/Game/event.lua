require("Game/eventBase.lua")
--this = SceneNode()
local event = EventBase.new()
function create()
	local mapInfo = MapInfo.new()
	local numWaves = mapInfo.getWaveCount()						--how many waves must be beaten to win
	local goldEstimationEarnedPerWave = 500+(numWaves*5)
	local startGold = 1000										--how much gold to start with
	local goldMultiplayerOnKills = 1.0
	local interestMultiplyerOnKill = 1.0						--how much gold percentage gained on killing an npc
	local startLives = 20										--how many npc you can have slip by without losing
	local seed = mapInfo.getSead()								--what seed should be used for the mapd
	local startSpawnWindow = mapInfo.getSpawnWindow()			--how many group compositions that can spawn 2==[1,2,3]
	local level = mapInfo.getLevel()							--what difficuly is played
	local waveFinishedGold = 200								--how much gold you get to finish a wave
	local difficult = mapInfo.getDifficulty()					--(>0.70 the lower this value is the more time you have to collect on the interest
	local difficultIncreaser = mapInfo.getDifficultyIncreaser()	--how large the exponential difficulty increase should be
	--
	if mapInfo.isCartMap() then
		startLives = 1
	end
	--
	if mapInfo.getGameMode()=="default" then
		--nothing
	elseif mapInfo.getGameMode()=="rush" then
		--nothing
	elseif mapInfo.getGameMode()=="survival" then
		--lower the availabel gold to make the spawned npc's easier. (this will make it easier to get intrest in the available gold)
		startGold = startGold*0.5				--(makes the spawn easier, restored after the generating of the waves)
		interestMultiplyerOnKill = 0.5
		numWaves = 100
	elseif mapInfo.getGameMode()=="training" then
		--nothing, so the spawns will be the same as if in normal game
	elseif mapInfo.getGameMode()=="only interest" then
		--nothing, to leave wave unchanged
	elseif mapInfo.getGameMode()=="leveler" then
		startGold = 1000
		interestMultiplyerOnKill = 0
	end
	--
	if Core.isInMultiplayer() then
		numWaves = 100
	end
	--
	--
	--create event system
	if not event.init(startGold,waveFinishedGold,interestMultiplyerOnKill,startLives,level) then
		return false
	end
	--
	if not(Core.isInMultiplayer() and Core.getNetworkClient():isAdmin()==false) then
		event.getSpawnManager().generateWaves(numWaves,difficult,difficultIncreaser,startSpawnWindow,seed)--generate the actual waves
	end
	--
	if Core.isInMultiplayer() then
		--event.spawnUnitsPattern(SPAWN_PATTERN.Clone)
		event.getSpawnManager().spawnUnitsPattern(SPAWN_PATTERN.Grouped)
	else
		event.getSpawnManager().spawnUnitsPattern(SPAWN_PATTERN.Grouped)
	end
	--
	if mapInfo.getGameMode()=="survival" then
		startGold = startGold * 2.0
		interestMultiplyerOnKill = 1.0
	elseif mapInfo.getGameMode()=="training" then
		startGold = math.floor(numWaves*goldEstimationEarnedPerWave/100.00+0.5)*100.0
		waveFinishedGold = 0
		interestMultiplyerOnKill = 0
		goldMultiplayerOnKills = 0.0
	elseif mapInfo.getGameMode()=="only interest" then
		waveFinishedGold = 0
		goldMultiplayerOnKills = 0.0
		interestMultiplyerOnKill = 1.0
		startGold = 3500
	elseif mapInfo.getGameMode()=="leveler" then
		goldMultiplayerOnKills = 0
		interestMultiplyerOnKill = 0
	end
	event.setDefaultGold(startGold,waveFinishedGold,interestMultiplyerOnKill,goldMultiplayerOnKills)
	--
	update = event.update
	return true
end