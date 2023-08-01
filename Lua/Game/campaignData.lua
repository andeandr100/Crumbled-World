require("Game/campaignData.lua")
--this = SceneNode()
CampaignData = {}
function CampaignData.new()
	local self = {}
	local PERMENANTBOUGHTUPGRADECOUNT = 1
	local PERMENANTUPGCOST = 12
	local STARTCRYSTALAMOUNT = 12
	local NORMALUPGCOST = 1
	local campaingDataConfig = Config("Campaign")			--the real data, used for the shop
	local campaignDataTable = campaingDataConfig:getTable()	--used for ingame/shop for getting what can be upgraded and is free
	local maps
	local towers = { "Tower/MinigunTower.lua", "Tower/ArrowTower.lua", "Tower/SwarmTower.lua", "Tower/ElectricTower.lua", "Tower/BladeTower.lua", "Tower/missileTower.lua", "Tower/quakerTower.lua", "Tower/SupportTower.lua" }
	local towersContent = {
		["Tower/MinigunTower.lua"] = {"range", "overCharge", "overkill"},
		["Tower/ArrowTower.lua"] = {"range", "hardArrow", "markOfDeath"},
		["Tower/SwarmTower.lua"] = {"range", "burnDamage", "fuel"},
		["Tower/ElectricTower.lua"] = {"range", "ampedSlow", "energyPool", "energy"},
		["Tower/BladeTower.lua"] = {"range", "attackSpeed", "masterBlade", "electricBlade", "shieldBreaker"},
		["Tower/missileTower.lua"] = {"range", "Blaster", "fuel", "shieldSmasher"},
		["Tower/quakerTower.lua"] = {"fireCrit", "fireStrike", "electricStrike", "freeUpgrade"},
		["Tower/SupportTower.lua"] = {"range", "damage", "weaken", "gold"}
	}
	
	local highScoreReplayBillboard = Core.getGlobalBillboard("highScoreReplay")
	local isAReplay = highScoreReplayBillboard:getBool("replay")
	local isInGame = Core.getBillboard("SoulManager")
	
	local files = { 
		{file=File("Data/Map/Campaign/Beginning.map"), 		statId="Begining",		minScore=2000,	maxScore=6000,	type="Crystal",	sead=258187458,	waveCount=2},--? / 11413[5k]
		{file=File("Data/Map/Campaign/Intrusion.map"), 		statId="Intrusion",		minScore=5000,	maxScore=11000,	type="Crystal",	sead=334652485,	waveCount=10},--? / 17029
		{file=File("Data/Map/Campaign/Stockpile.map"),		statId="Stockpile",		minScore=10000,	maxScore=24000,	type="Crystal",	sead=294158370,	waveCount=20},--? / 23738[9k]
		{file=File("Data/Map/Campaign/Expansion.map"), 		statId="Expansion",		minScore=15000,	maxScore=35000,	type="Crystal",	sead=864885368,	waveCount=25},--? /	35162[13k]							--40K
		{file=File("Data/Map/Campaign/Repair station.map"),	statId="RepairStation",	minScore=15000,	maxScore=44000,	type="Cart",	sead=256546887,	waveCount=25},--? / 42900								--40k	
		{file=File("Data/Map/Campaign/Edge world.map"),		statId="EdgeWorld",		minScore=15000,	maxScore=40000,	type="Crystal",	sead=352603864,	waveCount=25},--? / 39000								--38k
		{file=File("Data/Map/Campaign/Bridges.map"),		statId="Bridges",		minScore=15000,	maxScore=34000,	type="Crystal",	sead=617196048,	waveCount=25},--? / 32474								--33k
		{file=File("Data/Map/Campaign/Spiral.map"),			statId="Spiral",		minScore=15000,	maxScore=34000,	type="Crystal",	sead=109723780,	waveCount=25},--? / 30000								--31k
		{file=File("Data/Map/Campaign/Broken mine.map"),	statId="BrokenMine",	minScore=15000,	maxScore=34000,	type="Cart",	sead=104266217,	waveCount=25},--? / 33500[13k]							--30k
		{file=File("Data/Map/Campaign/Town.map"),			statId="Town",			minScore=15000,	maxScore=34000,	type="Crystal",	sead=956148502,	waveCount=25},--? / 32000(2.65)[10K]					--30k	
		{file=File("Data/Map/Campaign/Centeral.map"),		statId="Centeral",		minScore=15000,	maxScore=28000,	type="Crystal",	sead=187549817,	waveCount=25},--? /
		{file=File("Data/Map/Campaign/Outpost.map"),		statId="Outpost",		minScore=15000,	maxScore=28000,	type="Crystal",	sead=342413641,	waveCount=25},--? / 28000(6)							--29k	
		{file=File("Data/Map/Campaign/Plaza.map"),			statId="Plaza",			minScore=15000,	maxScore=35000,	type="Crystal",	sead=169366078,	waveCount=25},--? / 35000(2.5)							--
		{file=File("Data/Map/Campaign/Long haul.map"),		statId="LongHaul",		minScore=15000,	maxScore=28000,	type="Cart",	sead=202469227,	waveCount=25},--? / 27695(2)[22k]						--
		{file=File("Data/Map/Campaign/Dock.map"),			statId="Dock",			minScore=15000,	maxScore=28000,	type="Crystal",	sead=742525885,	waveCount=25},--? / 26503								--
		{file=File("Data/Map/Campaign/Lodge.map"),			statId="Lodge",			minScore=15000,	maxScore=36000,	type="Crystal",	sead=418531867,	waveCount=25},--? / 36200[15k]							--
		{file=File("Data/Map/Campaign/Crossroad.map"),		statId="Crossroad",		minScore=15000,	maxScore=30000,	type="Crystal",	sead=365654225,	waveCount=25},--? / 27472								--27k
		{file=File("Data/Map/Campaign/Mine.map"),			statId="Mine",			minScore=15000,	maxScore=38000,	type="Cart",	sead=464004721,	waveCount=25},--? / 37000[15k]					--
		{file=File("Data/Map/Campaign/West river.map"),		statId="West river",	minScore=15000,	maxScore=20000,	type="Crystal",	sead=242072855,	waveCount=25},--? / 19545[4k]							--unchanged lower difficulty
		{file=File("Data/Map/Campaign/Blocked path.map"),	statId="BlockedPath",	minScore=15000,	maxScore=50000,	type="Crystal",	sead=32111861,	waveCount=25},--? / 50000				--
		{file=File("Data/Map/Campaign/The line.map"),		statId="TheLine",		minScore=15000,	maxScore=30000,	type="Cart",	sead=752499248,	waveCount=25},--? / 29111[4k]							--
		{file=File("Data/Map/Campaign/Dump station.map"),	statId="DumpStation",	minScore=15000,	maxScore=28000,	type="Crystal",	sead=32111861,	waveCount=25},--? / 24393[6k]							--25k
		{file=File("Data/Map/Campaign/Rifted.map"),			statId="Rifted",		minScore=15000,	maxScore=28000,	type="Crystal",	sead=27518540,	waveCount=25},--? / 22583[5k]							--
		{file=File("Data/Map/Campaign/Paths.map"), 			statId="Paths",			minScore=15000,	maxScore=38000,	type="Crystal",	sead=620382518,	waveCount=25},--? / 37000[15]				--
		{file=File("Data/Map/Campaign/Divided.map"),		statId="Divided",		minScore=15000, maxScore=35000,	type="Crystal",	sead=615837167,	waveCount=25},--? / 33000(5.5) ?(6.25)					--
		{file=File("Data/Map/Campaign/Nature.map"),			statId="Nature",		minScore=15000,	maxScore=35000,	type="Crystal",	sead=581083960,	waveCount=25},--? / 33000(3.5)[11k] ?(3.75)				--
		{file=File("Data/Map/Campaign/Train station.map"),	statId="TrainStation",	minScore=15000,	maxScore=25000,	type="Cart",	sead=680821396,	waveCount=25},--? / 24105 (4k)							--25k
		{file=File("Data/Map/Campaign/Desperado.map"),		statId="Desperado",		minScore=15000,	maxScore=32000,	type="Crystal",	sead=842172835,	waveCount=30},--? / 29063 (5k)							--30k
		{file=File("Data/Map/Campaign/The end.map"),		statId="TheEnd",		minScore=15000,	maxScore=40000,	type="Crystal",	sead=394914309,	waveCount=30} --? / 39000 (13k)
	}
	function self.shouldExist(towerName,upgradeName)
		if campaingDataConfig:exist(towerName)==false or campaingDataConfig:get(towerName):exist(upgradeName)==false then
			campaingDataConfig:get(towerName):get(upgradeName):get("permUnlocked",0)
			campaingDataConfig:get(towerName):get(upgradeName):get("buyable",0)
			campaignDataTable = campaingDataConfig:getTable()
		end
	end
	function self.garanteExistenze()
		--get the table that we will do the tests on
		campaignDataTable = campaingDataConfig:getTable()
		--make sure that every upgrade is available
		for towerName, table in pairs(towersContent) do
			for i=1, #table do
				self.shouldExist(towerName,table[i])
			end
		end
	end
	function self.hasMapBeenBeaten(number)
		local map = campaingDataConfig:get("mapsFinished")
		if number<=#files then
			map = map:get(files[number].statId)
			local item = map:getFirst()
			while not map:isEnd() do
				if item:getInt()>0 then
					return true
				end
				item = map:getNext()
			end
		end
		return false
	end
	--
	function init()
		--
		--backward compability
		--
		local tab = campaingDataConfig:get("mapsFinished")
		for i=1, #files do
			if files[i].statIdOld and tab:exist(files[i].statIdOld) then
				tab:renameChild(files[i].statIdOld,files[i].statId)
			end
		end
		--make sure that all upgrades for the towers are available
		self.garanteExistenze()
		--first map must be beaten to play any other map
		--meaning if never beaten then the game has not been played yet
		if self.hasMapBeenBeaten(1)==false and campaingDataConfig:exist("crystal") == false then
			campaingDataConfig:get("crystal"):setInt(STARTCRYSTALAMOUNT)
		end
		campaingDataConfig:save()
		campaignDataTable = campaingDataConfig:getTable()
		if isInGame then
			if isAReplay then
				--used stored data
				campaignDataTable = totable( highScoreReplayBillboard:getString("shopInfo") )
			else
				--store the shop data
				highScoreReplayBillboard:setString("shopInfo", tabToStrMinimal(campaignDataTable))
			end
		end
		--
	end
	init()
	--
	function self.fixCrystalLimits()
		print("self.fixCrystalLimits()")
		if campaingDataConfig:get("crystal",0):getInt()>self.getMaxGoldNeededToUnlockEverything() then
			campaingDataConfig:get("crystal"):setInt(self.getMaxGoldNeededToUnlockEverything())
		end
	end
	function self.getCrystal()
		return campaingDataConfig:get("crystal",0):getInt()
	end
	local function updateAvailableMaps()
		--upto 3 unbeaten maps are available
		local windowSize = {[0]=1,1,2,3,3,3,4,4,4,4,5}
		local window = windowSize[math.min(#windowSize,maps.finishedCount)]
		for index=1, #files do
			if maps.finished[index] then
				maps.available[index] = 2
			elseif window>0 then
				maps.available[index] = 1
				window = window - 1
			else
				maps.available[index] = 0
			end
		end
		
	end
	function self.isMapAvailable(num)
		--if not initiated then fix the data
		if not maps then
			maps = {finishedCount=0,finished={},available={}}
			local map = campaingDataConfig:get("mapsFinished")
			for counter=1, #files do
				maps.finished[counter] = self.hasMapBeenBeaten(counter)
				if maps.finished[counter] then
					maps.finishedCount = maps.finishedCount + 1
				end
			end
			updateAvailableMaps()
		end
		--
		return (num>#maps.available and 0 or maps.available[num])
	end
	function self.getMapModeBeatenLevel(number,mode)
		return tonumber((campaignDataTable["mapsFinished"] and campaignDataTable["mapsFinished"][files[number].statId] and campaignDataTable["mapsFinished"][files[number].statId][mode or "-"]) or 0)
	end
	function self.hasMapModeBeenBeaten(number,mode)
		return self.getMapModeBeatenLevel(number,mode)>0
	end
	function self.hasMapModeLevelBeenBeaten(number,mode,level)
		return self.getMapModeBeatenLevel(number,mode)>=level
	end
	function self.setLevelCompleted(number,level,mode)
		local befLevel = campaingDataConfig:get("mapsFinished"):get(files[number].statId):get(mode):getInt();
		campaingDataConfig:get("mapsFinished"):get(files[number].statId):get(mode):setInt(math.max(befLevel,level))
		campaignDataTable = campaingDataConfig:getTable()
		campaingDataConfig:save()
	end
	function self.getMapCount()
		return #files
	end
	function self.getMaps()
		return files
	end
	function self.getBuyablesLimitForTower(towerName,permUnlocked)
		if permUnlocked then
			return PERMENANTBOUGHTUPGRADECOUNT
		end
		local tab = campaignDataTable[towerName]
		local ret = 0
		for k,v in pairs(tab) do
			ret = ret + self.getBuyablesTotal(k,permUnlocked)
		end
		return ret
	end
	function self.getTotalBuyablesBoughtForTower(towerName,permUnlocked)
		local tab = campaignDataTable[towerName]
		if tab then
			local ret = 0
			for k,v in pairs(tab) do
				if permUnlocked then
					if v.permUnlocked then
						ret = ret + v.permUnlocked
					end
				else
					if v.buyable then
						ret = ret + v.buyable
					end
				end
			end
			return ret
		else
			return 0
		end
	end
	function self.getTotalBuyablesBought()
		local ret = 0
		for i=1, #towers do
			ret = ret + self.getTotalBuyablesBoughtForTower(towers[i],false)
			ret = ret + self.getTotalBuyablesBoughtForTower(towers[i],true)
		end
		return ret
	end
	function self.getMaxGoldNeededToUnlockEverything()
		local leftToBuyTab = {	[0]={[0]=0},
								[1]={[0]=1,[1]=0},
								[2]={[0]=3,[1]=2,[3]=0},
								[3]={[0]=6,[1]=5,[2]=3,[3]=0}}
		local ret = 0
		for i=1, #towers do
			for k,v in pairs(campaignDataTable[towers[i]]) do
				if v.buyable then
					local leftToBuy = self.getBuyablesTotal(k,false)-v.buyable
					local costLeft = leftToBuyTab[self.getBuyablesTotal(k,false)][v.buyable]*NORMALUPGCOST
					if leftToBuy==1 and self.getBuyablesTotal(k,false)==leftToBuy then
						costLeft = 3*NORMALUPGCOST
					end
					ret = ret + costLeft
				end
			end
			local leftToBuy = PERMENANTBOUGHTUPGRADECOUNT-self.getTotalBuyablesBoughtForTower(towers[i],true)
			local costLeft = leftToBuy==1 and PERMENANTUPGCOST or 0
			ret = ret + costLeft
		end
		return ret
	end
	function self.getBoughtUpg(towerName,upgradeName,permUnlocked)
		if campaignDataTable[towerName] and campaignDataTable[towerName][upgradeName] then
			return tonumber(campaignDataTable[towerName][upgradeName][permUnlocked and "permUnlocked" or "buyable"] or 0)
		else
			return 0
		end
	end
	function self.getBuyablesTotal(upgradeName,permUnlocked)
		if permUnlocked then
			return PERMENANTBOUGHTUPGRADECOUNT
		end
		if upgradeName=="freeUpgrade" then
			return 0
		end
		return (upgradeName=="shieldBreaker" or upgradeName=="smartTargeting" or upgradeName=="shieldSmasher") and 1 or 3
	end
	function self.getBuyCost(towerName,upgradeName,permUnlocked)
		local item = self.getBoughtUpg(towerName, upgradeName, permUnlocked)
		if item<self.getBuyablesTotal(upgradeName) then
			if self.getBuyablesTotal(upgradeName)==1 and permUnlocked==false then
				return 3*NORMALUPGCOST
			end
			return (item+1)*(permUnlocked and PERMENANTUPGCOST or NORMALUPGCOST)
		end
		return 0
	end
	--
	function self.addCrystal(addCount)
		print("==> self.addCrystal("..addCount..")")
		--update current crystal count
		campaingDataConfig:get("crystal"):setInt(self.getCrystal()+addCount)
		--update upgrade tables for towers
		campaignDataTable = campaingDataConfig:getTable()
		--fix crystals
		self.fixCrystalLimits()
		--save cahnges
		campaingDataConfig:save()
	end
	function self.canBuyUnlock(towerName,upgradeName,permUnlocked)
		if upgradeName=="freeUpgrade" then
			return true
		end
		if permUnlocked then
			if 	self.getBoughtUpg(towerName,upgradeName,true)<self.getBoughtUpg(towerName,upgradeName,false) and --upgrade must be bought before it can be unlocked permently
				self.getTotalBuyablesBoughtForTower(towerName,true)<PERMENANTBOUGHTUPGRADECOUNT and--we can only buy a set amout of upgrades permenant
				self.getCrystal()>=self.getBuyCost(towerName,upgradeName,permUnlocked) then--we must have wnough gold
				return true
			end
			return false
		else
			return 	self.getBoughtUpg(towerName,upgradeName,false)<self.getBuyablesTotal(upgradeName,permUnlocked) and--if there is an upgrade available
					self.getCrystal()>=self.getBuyCost(towerName,upgradeName,permUnlocked)--we must have enough gold
		end
	end
	function self.buy(towerName,upgradeName,permUnlocked)
		local item = campaingDataConfig:get(towerName):get(upgradeName):get(permUnlocked and "permUnlocked" or "buyable",0)
		local cost = self.getBuyCost(towerName,upgradeName,permUnlocked)
		if item:getInt()<self.getBuyablesTotal(upgradeName,permUnlocked) and cost<=self.getCrystal() and (permUnlocked==false or self.canBuyUnlock(towerName,upgradeName,true)) then
			item:setInt(item:getInt()+1)
			self.addCrystal(-cost)
		end
	end
	function self.clear(towerName,upgradeName,permUnlocked)
		if permUnlocked then
			print("========================================")
			print("==> self.clear("..towerName..","..upgradeName..","..tostring(permUnlocked)..")")
			local upgCount = self.getBoughtUpg(towerName,upgradeName,permUnlocked)
			campaingDataConfig:get(towerName):get(upgradeName):get(permUnlocked and "permUnlocked" or "buyable",0):setInt(0)
			self.addCrystal( upgCount==1 and PERMENANTUPGCOST or 0 )
			--debug code
			local val = campaingDataConfig:get(towerName):get(upgradeName):get(permUnlocked and "permUnlocked" or "buyable",0):getInt()
			assert(val==0, "Clearing failed for unlocked upgrades!!!")
		else
			error("this should not happen!!!")
		end
	end
	function self.getLevelCompleted(map)
		return campaingDataConfig:get(map):get("levelCompleted",4):getInt()--4 because there is 5 base levels available (you have level 5 unlocked by beating level 4)
	end
	return self
end