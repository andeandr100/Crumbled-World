require("Game/eventBase.lua")
--this = SceneNode()
local event = EventBase.new()
function create()
	
	--this:getPlayerNode():loadLuaScript("Custom/tutorial.lua")
	
	local mapInfo = MapInfo.new()
	local numWaves = mapInfo.getWaveCount()
	local goldEstimationEarnedPerWave = 500+(numWaves*5)
	local startGold = 1000
	local goldMultiplayerOnKills = 1.0
	local startLives = 20
	local sead = mapInfo.getSead()
	local startSpawnWindow = mapInfo.getSpawnWindow()			--how many group compositions that can spawn 2==[1,2,3]
	local waveFinishedGold = 200								--how much gold you get to finish a wave
	local level = mapInfo.getLevel()
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
	event.getSpawnManager().disableUnit("rat_tank")
	event.getSpawnManager().disableUnit("electroSpirit")
	event.getSpawnManager().disableUnit("skeleton_cf")
	event.getSpawnManager().disableUnit("skeleton_cb")
	event.getSpawnManager().disableUnit("turtle")
	event.getSpawnManager().disableUnit("dino")
	event.getSpawnManager().disableUnit("reaper")
	event.getSpawnManager().disableUnit("stoneSpirit")
	event.getSpawnManager().disableUnit("hydra1")
	event.getSpawnManager().disableUnit("hydra2")
	event.getSpawnManager().disableUnit("hydra3")
	event.getSpawnManager().disableUnit("hydra4")
	event.getSpawnManager().disableUnit("hydra5")
	--
	event.getSpawnManager().addGroupToSpawn(1,1,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(1,2,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(1,3,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(1,4,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(1,5,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(1,6,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(2,1,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(2,2,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(2,3,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(2,4,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(2,5,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(2,6,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(2,7,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(3,1,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(3,2,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(3,3,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(3,4,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(3,5,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(3,6,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(3,7,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(4,1,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(4,2,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(4,3,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(4,4,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(4,5,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(4,6,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(4,7,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(4,8,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(5,1,{{npc="rat",delay=0},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2}})
	event.getSpawnManager().addGroupToSpawn(5,2,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(5,3,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(5,4,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(5,5,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(5,6,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(5,7,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(6,1,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(6,2,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(6,3,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(6,4,{{npc="rat",delay=0},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2}})
	event.getSpawnManager().addGroupToSpawn(6,5,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="scorpion",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(6,6,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(6,7,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(6,8,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(7,1,{{npc="fireSpirit",delay=0},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5}})
	event.getSpawnManager().addGroupToSpawn(7,2,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(7,3,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(7,4,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(7,5,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(7,6,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(7,7,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(7,8,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(7,9,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(7,10,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(8,1,{{npc="rat",delay=0},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2}})
	event.getSpawnManager().addGroupToSpawn(8,2,{{npc="fireSpirit",delay=0},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5}})
	event.getSpawnManager().addGroupToSpawn(8,3,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(8,4,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(8,5,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(8,6,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(8,7,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(8,8,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(8,9,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(9,1,{{npc="rat",delay=0},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2}})
	event.getSpawnManager().addGroupToSpawn(9,2,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(9,3,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(9,4,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(9,5,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(9,6,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(9,7,{{npc="fireSpirit",delay=0},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5}})
	event.getSpawnManager().addGroupToSpawn(9,8,{{npc="fireSpirit",delay=0},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5}})
	event.getSpawnManager().addGroupToSpawn(9,9,{{npc="skeleton",delay=0},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(10,1,{{npc="fireSpirit",delay=0},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5}})
	event.getSpawnManager().addGroupToSpawn(10,2,{{npc="rat",delay=0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(10,3,{{npc="fireSpirit",delay=0},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5}})
	event.getSpawnManager().addGroupToSpawn(10,4,{{npc="rat",delay=0},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2}})
	event.getSpawnManager().addGroupToSpawn(10,5,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}})
	event.getSpawnManager().addGroupToSpawn(10,6,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.4},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.35},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3},{npc="skeleton",delay=0.3}})
	event.getSpawnManager().addGroupToSpawn(10,7,{{npc="scorpion",delay=0},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35},{npc="scorpion",delay=0.35}})
	event.getSpawnManager().addGroupToSpawn(10,8,{{npc="rat",delay=0},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2}})
	event.getSpawnManager().addGroupToSpawn(10,9,{{npc="fireSpirit",delay=0},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5},{npc="fireSpirit",delay=0.5}})
	event.getSpawnManager().addGroupToSpawn(10,10,{{npc="rat",delay=0},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2},{npc="rat",delay=0.2}})
	--
	event.getSpawnManager().generateWaves(numWaves,difficult,difficultIncreaser,startSpawnWindow,sead)
	
	if mapInfo.getGameMode()=="survival" then
		startGold = startGold * 2.0
	elseif mapInfo.getGameMode()=="training" then
		startGold = 5500
		waveFinishedGold = 0
		goldMultiplayerOnKills = 0
	elseif mapInfo.getGameMode()=="leveler" then
		goldMultiplayerOnKills = 0
	end
	event.setDefaultGold(startGold,waveFinishedGold,goldMultiplayerOnKills)
	
	update = event.update
	return true
end