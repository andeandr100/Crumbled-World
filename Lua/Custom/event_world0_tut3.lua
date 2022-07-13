require("Game/eventBase.lua")
--this = SceneNode()
local event = EventBase.new()
function create()
	local mapInfo = MapInfo.new()
	local numWaves = mapInfo.getWaveCount()
	local goldEstimationEarnedPerWave = 500+(numWaves*5)
	local startGold = 1000
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
	elseif mapInfo.getGameMode()=="rush" then
		--nothing
	elseif mapInfo.getGameMode()=="survival" then
		--lower the availabel gold to make the spawned npc's easier. (this will make it easier to get intrest in the available gold)
		startGold = startGold*0.5				--(makes the spawn easier, restored after the generating of the waves)
		numWaves = 100
	elseif mapInfo.getGameMode()=="training" then
		--nothing, so the spawns will be the same as if in normal game
	elseif mapInfo.getGameMode()=="leveler" then
		startGold = 1000
	end
	if not event.init(startGold,waveFinishedGold,startLives,level) then
		return false
	end
	--
	event.getSpawnManager().disableUnit("hydra1")
	event.getSpawnManager().disableUnit("hydra2")
	event.getSpawnManager().disableUnit("hydra3")
	event.getSpawnManager().disableUnit("hydra4")
	event.getSpawnManager().disableUnit("hydra5")
	--
	
	--
	event.getSpawnManager().generateWaves(numWaves,difficult,difficultIncreaser,startSpawnWindow,seed)
	
	if mapInfo.getGameMode()=="survival" then
		startGold = startGold * 2.0
	elseif mapInfo.getGameMode()=="training" then
		startGold = 9000
		waveFinishedGold = 0
		goldMultiplayerOnKills = 0
	elseif mapInfo.getGameMode()=="leveler" then
		goldMultiplayerOnKills = 0
	end
	event.setDefaultGold(startGold,waveFinishedGold,goldMultiplayerOnKills)
	
	update = event.update
	return true
end