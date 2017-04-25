require("Game/eventBase.lua")
--this = SceneNode()
local event = EventBase.new()
function create()
	local mapInfo = MapInfo.new()
	local numWaves = mapInfo.getWaveCount()
	local goldEstimationEarnedPerWave = 500+(numWaves*5)
	local startGold = 1000
	local interestOnKill = 0.0020
	local goldMultiplayerOnKills = 1.0
	local startLives = 20
	local seed = mapInfo.getSead()
	local startSpawnWindow = mapInfo.getSpawnWindow()			--how many group compositions that can spawn 2==[1,2,3]
	local level = mapInfo.getLevel()
	local waveFinishedGold = 200								--how much gold you get to finish a wave
	local difficult = mapInfo.getDifficulty()					--(>0.70 the lower this value is the more time you have to collect on the interest
	local difficultIncreaser = mapInfo.getDifficultyIncreaser()	--how large the exponential difficulty increase should be
	--
	
	if mapInfo.getGameMode()=="default" then
		--nothing
	elseif mapInfo.getGameMode()=="survival" then
		--lower the availabel gold to make the spawned npc's easier. (this will make it easier to get intrest in the available gold)
		startGold = 800
		interestOnKill = interestOnKill*0.80
		numWaves = 999
	elseif mapInfo.getGameMode()=="training" then
		--nothing, so the spawns will be the same as if in normal game
	elseif mapInfo.getGameMode()=="only interest" then
		--nonting, to calculate the wave unchanged
	elseif mapInfo.getGameMode()=="leveler" then
		startGold = 1000
		interestOnKill = 0.0
	end
	event.init(startGold,waveFinishedGold,interestOnKill,goldMultiplayerOnKills,startLives,level)
	--
	event.disableUnit("hydra1")
	event.disableUnit("hydra2")
	event.disableUnit("hydra3")
	event.disableUnit("hydra4")
	event.disableUnit("hydra5")
	--
	
	--
	event.generateWaves(numWaves,difficult,difficultIncreaser,startSpawnWindow,seed)
	
	if mapInfo.getGameMode()=="survival" then
		startGold = 1000
		interestOnKill = interestOnKill * 1.5
	elseif mapInfo.getGameMode()=="training" then
		startGold = 9000
		waveFinishedGold = 0
		interestOnKill = 0.0
		goldMultiplayerOnKills = 0.0
	elseif mapInfo.getGameMode()=="only interest" then
		waveFinishedGold = 0
		goldMultiplayerOnKills = 0.0
		startGold = 3000
	elseif mapInfo.getGameMode()=="leveler" then
		goldMultiplayerOnKills = 0.0
	end
	event.setDefaultGold(startGold,waveFinishedGold,interestOnKill,goldMultiplayerOnKills)
	
	update = event.update
	return true
end