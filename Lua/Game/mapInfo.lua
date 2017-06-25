require("Game/campaignData.lua")
require("Menu/MainMenu/mapInformation.lua")
--this = SceneNode()
MapInfo = {}
function MapInfo.new()
	local self = {}
	local FIRSTTIMEVICTORYBONUS = 2
	local FIRSTTIMEGAMEMODEVICTORYBONUS = 1
	local billboard = false
	local increasedDifficultyMax = 0.0
	local increasedDifficultyMin = 0.0

	function self.setLevel(level,notSave)
		--1 = 0.70
		--2 = 0.75
		--3 = 0.80
		--4 = 0.85
		--5 = 0.90
		local actualLevel = level
		print("setLevel("..level..")\n")
--		if type(level)=="string" then
--			local difficult = {Easy=1,Normal=2,Hard=3,Extreme=4,Insane=5}--"Impossible #"
--			print("difficult = "..tostring(difficult).."\n")
--			if difficult[level] then
--				level = tonumber(difficult[level])
--			else
--				print("Imposible\n")
--				level = 5+tonumber(string.match(level, " (.*)"))
--			end
--		end
		actualLevel = level
		--balance difficulty to map
		--increasedDifficultyMin
		local addPerLevel = (increasedDifficultyMax-increasedDifficultyMin)/4.0
		level = (level+increasedDifficultyMin)+(addPerLevel*(level-1))
		--
		print("setLevel == "..actualLevel..") == "..level.."\n")
		billboard:setDouble("level",actualLevel)
		billboard:setDouble("difficulty",0.75+((level-1)*0.055))			--start difficulty
		billboard:setDouble("difficultIncreaser",1.0160+(level*0.00275))	--how fast the difficulty should accelerate
		billboard:setInt("SpawnWindow",math.floor(2+(actualLevel*0.55)))	--how many different npc group can be spawned
		--
		if billboard:exist("isCart")==false then
			billboard:setBool("isCart",false)
		end
	end
	function self.getReward()
		local cData = CampaignData.new()
		local reward = math.max(1,math.floor( (self.getLevel()*self.getWaveCount()+0.01)/25 ))
		if cData.hasMapBeenBeaten(self.getMapNumber())==false then
			reward = reward + FIRSTTIMEVICTORYBONUS
		end
		if cData.hasMapModeBeenBeaten( self.getMapNumber(), self.getGameMode() )==false then
			reward = reward + FIRSTTIMEGAMEMODEVICTORYBONUS
		end
		return reward
	end
	function self.setIsCartMap(isCart)
		print("setIsCartMap("..tostring(isCart)..")\n")
		billboard:setBool("isCart",isCart)
	end
	function self.setChangedDifficultyMax(amount)
		amount = amount==nil and 0 or amount
		increasedDifficultyMax = amount
		self.setLevel(billboard:getDouble("level"))
	end
	function self.setChangedDifficultyMin(amount)
		amount = amount==nil and 0 or amount
		increasedDifficultyMin = amount
		self.setLevel(billboard:getDouble("level"))
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
	function self.setPlayerCount(num)
		billboard:setInt("PlayerCount",tonumber(num))
	end
	function self.setSead(num)
		billboard:setInt("sead",tonumber(num))
	end
	--
	function self.getIncreasedDifficultyMax()
		return increasedDifficultyMax
	end
	function self.getLevel()
		return billboard:getDouble("level")
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
		return billboard:getString("GameMode")
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
						self.setChangedDifficultyMax(mapInfo.difficultyIncreaseMax)
						self.setChangedDifficultyMin(mapInfo.difficultyIncreaseMin)
						self.setWaveCount(mapInfo.waveCount)
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
			self.setLevel(2.0)
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