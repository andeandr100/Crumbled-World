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
	local sead = mapInfo.getSead()
	local startSpawnWindow = mapInfo.getSpawnWindow()			--how many group compositions that can spawn 2==[1,2,3]
	local waveFinishedGold = 200								--how much gold you get to finish a wave
	local level = mapInfo.getLevel()
	local difficult = mapInfo.getDifficulty()					--(>0.70 the lower this value is the more time you have to collect on the interest
	local difficultIncreaser = mapInfo.getDifficultyIncreaser()	--how large the exponential difficulty increase should be
	--
	
	if mapInfo.getGameMode()=="default" then
		--nothing
	elseif mapInfo.getGameMode()=="survival" then
		--lower the availabel gold to make the spawned npc's easier. (this will make it easier to get intrest in the available gold)
		startGold = startGold*0.5				--(makes the spawn easier, restored after the generating of the waves)
		interestOnKill = interestOnKill*0.5		--(makes the spawn easier, restored after the generating of the waves)
		numWaves = 100
	elseif mapInfo.getGameMode()=="training" then
		--nothing, so the spawns will be the same as if in normal game
	elseif mapInfo.getGameMode()=="only interest" then
		--nonting, to calculate the wave unchanged
	elseif mapInfo.getGameMode()=="leveler" then
		startGold = 1000
		interestOnKill = 0.0
	end
	if not event.init(startGold,waveFinishedGold,interestOnKill,goldMultiplayerOnKills,startLives,level) then
		return false
	end
	--
	event.disableUnit("dino")
	event.disableUnit("reaper")
	event.disableUnit("hydra1")
	event.disableUnit("hydra2")
	event.disableUnit("hydra3")
	event.disableUnit("hydra4")
	event.disableUnit("hydra5")
	--
	event.addGroupToSpawn(1,1,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(1,2,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(1,3,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(1,4,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(1,5,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(1,6,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	
	event.addGroupToSpawn(2,1,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(2,2,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(2,3,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(2,4,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(2,5,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(2,6,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	
	event.addGroupToSpawn(3,1,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(3,2,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(3,3,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(3,4,{{delay=0,npc="scorpion"},{delay=0.4,npc="scorpion"},{delay=0.4,npc="fireSpirit"},{delay=0.35,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"}})
	event.addGroupToSpawn(3,5,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(3,6,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	
	event.addGroupToSpawn(4,1,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(4,2,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="fireSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(4,3,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(4,4,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(4,5,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(4,6,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	
	event.addGroupToSpawn(5,1,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(5,2,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(5,3,{{delay=0,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"}})
	event.addGroupToSpawn(5,4,{{delay=0,npc="scorpion"},{delay=0.4,npc="scorpion"},{delay=0.4,npc="fireSpirit"},{delay=0.35,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"}})
	event.addGroupToSpawn(5,5,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(5,6,{{delay=0,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"}})
	
	event.addGroupToSpawn(6,1,{{delay=0,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"}})
	event.addGroupToSpawn(6,2,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.4,npc="turtle"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(6,3,{{delay=0,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"}})
	event.addGroupToSpawn(6,4,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(6,5,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(6,6,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(6,7,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	
	event.addGroupToSpawn(7,1,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(7,2,{{delay=0,npc="electroSpirit"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(7,3,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(7,4,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(7,5,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(7,6,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	
	event.addGroupToSpawn(8,1,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="turtle"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(8,2,{{delay=0,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"}})
	event.addGroupToSpawn(8,3,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(8,4,{{delay=0,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=1.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(8,5,{{delay=0,npc="electroSpirit"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(8,6,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	
	event.addGroupToSpawn(9,1,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(9,2,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(9,3,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(9,4,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(9,5,{{delay=0,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"}})
	event.addGroupToSpawn(9,6,{{delay=0,npc="electroSpirit"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(9,7,{{delay=0,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"}})
	
	event.addGroupToSpawn(10,1,{{delay=0,npc="skeleton_cf"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="fireSpirit"},{delay=0.4,npc="electroSpirit"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton_cb"}})
	event.addGroupToSpawn(10,2,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(10,3,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(10,4,{{delay=0,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"}})
	event.addGroupToSpawn(10,5,{{delay=0,npc="electroSpirit"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(10,6,{{delay=0,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"}})
	event.addGroupToSpawn(10,7,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="turtle"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	
	event.addGroupToSpawn(11,1,{{delay=0,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"}})
	event.addGroupToSpawn(11,2,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(11,3,{{delay=0,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"}})
	event.addGroupToSpawn(11,4,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(11,5,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.4,npc="turtle"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(11,6,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(11,7,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="turtle"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	
	event.addGroupToSpawn(12,1,{{delay=0,npc="skeleton_cf"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="fireSpirit"},{delay=0.4,npc="electroSpirit"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton_cb"}})
	event.addGroupToSpawn(12,2,{{delay=0,npc="scorpion"},{delay=0.4,npc="scorpion"},{delay=0.4,npc="fireSpirit"},{delay=0.35,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"}})
	event.addGroupToSpawn(12,3,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(12,4,{{delay=0,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"}})
	event.addGroupToSpawn(12,5,{{delay=0,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"}})
	event.addGroupToSpawn(12,6,{{delay=0,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"}})
	event.addGroupToSpawn(12,7,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	
	event.addGroupToSpawn(13,1,{{delay=0,npc="stoneSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"}})
	event.addGroupToSpawn(13,2,{{delay=0,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"}})
	event.addGroupToSpawn(13,3,{{delay=0,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"}})
	event.addGroupToSpawn(13,4,{{delay=0,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"},{delay=0.2,npc="rat"}})
	event.addGroupToSpawn(13,5,{{delay=0,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"}})
	event.addGroupToSpawn(13,6,{{delay=0,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=0.4,npc="rat_tank"},{delay=1.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},waveMin=10})
	event.addGroupToSpawn(13,7,{{delay=0,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"}})
	
	event.addGroupToSpawn(14,1,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="turtle"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(14,2,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(14,3,{{delay=0,npc="electroSpirit"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(14,4,{{delay=0,npc="stoneSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"}})
	event.addGroupToSpawn(14,5,{{delay=0,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"}})
	event.addGroupToSpawn(14,6,{{delay=0,npc="scorpion"},{delay=0.4,npc="scorpion"},{delay=0.4,npc="fireSpirit"},{delay=0.35,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"}})
	event.addGroupToSpawn(14,7,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	
	event.addGroupToSpawn(15,1,{{delay=0,npc="stoneSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="fireSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"}})
	event.addGroupToSpawn(15,2,{{delay=0,npc="scorpion"},{delay=0.4,npc="scorpion"},{delay=0.4,npc="fireSpirit"},{delay=0.35,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"}})
	event.addGroupToSpawn(15,3,{{delay=0,npc="scorpion"},{delay=0.35,npc="scorpion"},{delay=0.4,npc="electroSpirit"},{delay=0.5,npc="electroSpirit"},{delay=0.35,npc="scorpion"},{delay=0.35,npc="scorpion"}})
	event.addGroupToSpawn(15,4,{{delay=0,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"},{delay=0.25,npc="rat"}})
	event.addGroupToSpawn(15,5,{{delay=0,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"},{delay=0.25,npc="skeleton"}})
	event.addGroupToSpawn(15,6,{{delay=0,npc="scorpion"},{delay=0.4,npc="scorpion"},{delay=0.4,npc="fireSpirit"},{delay=0.35,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"},{delay=0.3,npc="skeleton"}})
	event.addGroupToSpawn(15,7,{{delay=0,npc="skeleton_cf"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="turtle"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton"},{delay=0.4,npc="skeleton_cb"}})
	--
	event.generateWaves(numWaves,difficult,difficultIncreaser,startSpawnWindow,sead)
	
	if mapInfo.getGameMode()=="survival" then
		startGold = startGold * 2.0
		interestOnKill = interestOnKill * 2.0
	elseif mapInfo.getGameMode()=="training" then
		startGold = 8500
		waveFinishedGold = 0
		interestOnKill = 0.0
		goldMultiplayerOnKills = 0.0
	elseif mapInfo.getGameMode()=="only interest" then
		waveFinishedGold = 0
		goldMultiplayerOnKills = 0.0
		startGold = 3000
	elseif mapInfo.getGameMode()=="leveler" then
		waveFinishedGold = 100
		goldMultiplayerOnKills = 0.0
	end
	event.setDefaultGold(startGold,waveFinishedGold,interestOnKill,goldMultiplayerOnKills)
	
	update = event.update
	return true
end