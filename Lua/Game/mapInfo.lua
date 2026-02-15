require("Game/campaignData.lua")
require("Menu/MainMenu/mapInformation.lua")
require("Game/gameValues.lua")

--this = SceneNode()
MapInfo = {}
MapInfo.gameValue = GameValues.new()

function MapInfo.new()
	local self = {}
	local FIRSTTIMEVICTORYBONUS = 2
	local FIRSTTIMEGAMEMODEVICTORYBONUS = 1
	local BASEBONUS = 1
	local billboard
	local actualLevel = 1
	local addPerLevel = 0.0
	local difficultyNormalMin = 0.0
	local difficultyNormalMax = 0.0
	local difficultyHardMin = 0.0
	local difficultyHardMax = 0.0
	
	

	function self.getGameModesSinglePlayer()
		return {"custom-game.game-mode.default", "custom-game.game-mode.survival"}
	end
	function self.getGameModesMultiPlayer()
		return {"custom-game.game-mode.default", "custom-game.game-mode.survival"}
	end
	
	function self.setDifficultyLevel(difficultyLevel)
		--1 = 0
		--2 = 1
		--3 = 1.5
		--4 = 2.0
		--5 = 2.5
		
		local minDiff = difficultyHardMin - difficultyNormalMin
		local maxDiff = difficultyHardMax - difficultyNormalMax
		local difficultyScale = difficultyLevel / 2
		--
		billboard:setInt("level",difficultyLevel)
		billboard:setDouble("difficultyMin",difficultyNormalMin + minDiff * difficultyScale)
		billboard:setDouble("difficultyMax",difficultyNormalMax + maxDiff * difficultyScale)
		billboard:setInt("SpawnWindow",math.floor(2+(difficultyLevel*0.55)))	--how many different npc group can be spawned
		--
		if billboard:exist("isCart")==false then
			billboard:setBool("isCart",false)
		elseif billboard:exist("isCircle")==false then
			billboard:setBool("isCircle",false)
		elseif billboard:exist("isCrystal")==false then
			billboard:setBool("isCrystal",false)
		end
	end
	function self.getReward()
		local reward = BASEBONUS
		local mapName = billboard:getString("mapName")
		local hasMapBeenBeaten = MapInfo.gameValue.getMapStatus(mapName)
		
		if hasMapBeenBeaten==false then
			reward = reward + FIRSTTIMEVICTORYBONUS
		end
		return reward
	end
	function self.setIsCartMap(isCart)
		billboard:setBool("isCart",isCart)
	end
	function self.setIsCircleMap(isCircle)
		billboard:setBool("isCircle",isCircle)
	end
	function self.setIsCrystalMap(isCrystal)
		billboard:setBool("isCrystal",isCrystal)
	end

	function self.setDifficultyNormalMin(value)
		if value == nil then
			abort("can not be null")
		end
		difficultyNormalMin = value
	end
	function self.setDifficultyNormalMax(value)
		if value == nil then
			abort("can not be null")
		end
		difficultyNormalMax = value
	end
	function self.setDifficultyHardMin(value)
		if value == nil then
			abort("can not be null")
		end
		difficultyHardMin = value
	end
	function self.setDifficultyHardMax(value)
		if value == nil then
			abort("can not be null")
		end
		difficultyHardMax = value
	end
	
	
	function self.setIsCampaign(mode)
		billboard:setBool("isCampaign",mode)
	end
	function self.setGameMode(mode)
		billboard:setString("GameMode",mode)
	end
	function self.setTowerSettings(tab)
		billboard:setTable("TowerSettings",tab)
	end
	function self.setMapFileName(mapFileName)
		if mapFileName then
			billboard:setString("mapFileName",mapFileName)
		end
	end
	function self.setMapName(mapName)
		if mapName then
			billboard:setString("mapName",mapName)
		end
	end
	function self.setMapNumber(num)
		billboard:setInt("mapNumber",tonumber(num))
	end
	function self.setWaveCount(num)
		billboard:setInt("waveCount",tonumber(num))
	end
	function self.setMapSize(sizeStr)
		local xStr,yStr = string.match(sizeStr, "(.*)x(.*)")
		billboard:setInt("sizeX",tonumber(xStr))
		billboard:setInt("sizeY",tonumber(yStr))
	end
	function self.setPlayerCount(num)
		billboard:setInt("PlayerCount",tonumber(num))
	end
	function self.setSead(num)
		billboard:setInt("sead",tonumber(num))
	end
	--
	function self.getAddPerLevel()
		return addPerLevel
	end
	function self.getLevel()
		return billboard:getInt("level")
	end
	function self.getDifficulty()
		return billboard:getDouble("difficulty")
	end
	function self.getDifficultyIncreaser()
		return billboard:getDouble("difficultIncreaser")
	end
	function self.getSpawnWindow()
		return billboard:getDouble("SpawnWindow")
	end
	function self.getGameMode()
		local languageStringGameMode = billboard:getString("GameMode")
		
		if languageStringGameMode == "custom-game.game-mode.default" then
			return "default"
		elseif languageStringGameMode == "custom-game.game-mode.survival" then
			return "survival"
		else
			return "undefined-game-mode"
		end
	end
	function self.getTowerSettings()
		return billboard:getTable("TowerSettings")
	end
	function self.getMapFileName()
		return billboard:getString("mapFileName")
	end
	function self.getMapName()
		return billboard:getString("mapName")
	end
	function self.getMapNumber()
		return math.max(1,billboard:getInt("mapNumber"))
	end
	function self.isCampaign()
		return billboard:getBool("isCampaign")
	end
	function self.changeToNextMap()
		local ret = false
		if self.isCampaign() then
			local cData = CampaignData.new()
			if self.getMapNumber()<cData.getMapCount() then
				local mapNum = self.getMapNumber() + 1
				local fileTab = cData.getMaps()[mapNum]
				local mapFile = fileTab.file
				self.setMapNumber(mapNum)
				self.setSead(fileTab.sead)
				self.setMapFileName(mapFile:getPath())
				self.setMapName(mapFile:getName())
				if mapFile:isFile() then
					local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
					if mapInfo then
						self.setIsCartMap(mapInfo.gameMode=="Cart")
						self.setIsCircleMap(mapInfo.gameMode=="Circle")
						self.setIsCrystalMap(mapInfo.gameMode=="Crystal")
						self.setDifficultyNormalMin(mapInfo.difficultyNormalMin)
						self.setDifficultyNormalMax(mapInfo.difficultyNormalMax)
						self.setDifficultyHardMin(mapInfo.difficultyHardMin)
						self.setDifficultyHardMax(mapInfo.difficultyHardMax)
						self.setWaveCount(mapInfo.waveCount)
						self.setMapSize(mapInfo.mapSize)
						--
						ret = true
					end
				end
			end
		end
		return ret
	end
	function self.isCartMap()
		return billboard:getBool("isCart")
	end
	function self.isCricleMap()
		return billboard:getBool("isCircle")
	end
	function self.isCrystalMap()
		return billboard:getBool("isCrystal")
	end
	function self.isRestartWaveEnabled()
		return self.isCricleMap()==false and Core.isInMultiplayer()==false
	end
	function self.getStartWave()
		return self.getGameMode()=="training" and self.getWaveCount()-5 or 0
	end
	function self.getWaveCount()
		return billboard:getInt("waveCount")
	end
	function self.getPlayerCount()
		return math.max(1, billboard:getInt("PlayerCount"))
	end
	function self.getSead()
		if billboard:exist("sead") then
			return billboard:getInt("sead")
		end
		return math.randomInt(0,2147483647)
	end
	--
	function self.changeDifficultyIncreaser(byPer)
		if byPer<0.0 then
			local val = billboard:getDouble("difficultIncreaser")-1.0
			billboard:setDouble("difficultIncreaser", 1.0 + ((-byPer)*val) )
		else
			local val = billboard:getDouble("difficultIncreaser")-1.0
			billboard:setDouble("difficultIncreaser", billboard:getDouble("difficultIncreaser") + ((byPer)*val) )
		end
	end
	--
	local function init()
		billboard = Core.getGlobalBillboard("MapInfo")
		if billboard:exist("difficulty")==false then
			self.setDifficultyLevel(2.0)
		end
		if billboard:exist("GameMode")==false then
			billboard:setString("GameMode","Normal")
		end
		if billboard:exist("TowerSettings")==false then
			billboard:setTable("TowerSettings",{})
		end
	end
	init()
	--
	return self
end