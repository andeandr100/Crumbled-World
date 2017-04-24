require("Game/campaignData.lua")
--this = SceneNode()
CampaignData = {}
function CampaignData.new()
	local self = {}
	local PERMENANTBOUGHTUPGRADECOUNT = 1
	local PERMENANTUPGCOST = 12
	local NORMALUPGCOST = 1
	local campaingData = Config("Campaign")
	local maps
	local towers = { "Tower/MinigunTower.lua", "Tower/ArrowTower.lua", "Tower/SwarmTower.lua", "Tower/ElectricTower.lua", "Tower/BladeTower.lua", "Tower/missileTower.lua", "Tower/quakerTower.lua", "Tower/SupportTower.lua" }
	local files = { 
		{file=File("Data/Map/Campaign/Beginning.map"), 		statId="Begining",		type="Crystal",	sead=258187458,	waveCount=10},--5500
		{file=File("Data/Map/Campaign/Intrusion.map"), 		statId="Intrusion",		type="Crystal",	sead=334652485,	waveCount=15},--8500
		{file=File("Data/Map/Campaign/Stockpile.map"),		statId="Stockpile",		type="Crystal",	sead=294158370,	waveCount=20},--11800		X
		{file=File("Data/Map/Campaign/Expansion.map"), 		statId="Expansion",		type="Crystal",	sead=864885368,	waveCount=25},
		{file=File("Data/Map/Campaign/Repair station.map"),	statId="RepairStation",	type="Cart",	sead=256546887,	waveCount=20},--12000
		{file=File("Data/Map/Campaign/Bridges.map"),		statId="Bridges",		type="Crystal",	sead=617196048,	waveCount=20},
		{file=File("Data/Map/Campaign/Spiral.map"),			statId="Spiral",		type="Crystal",	sead=109720780,	waveCount=25},--			X
		{file=File("Data/Map/Campaign/Town.map"),			statId="Town",			type="Crystal",	sead=956148502,	waveCount=25},--			LONGEST AVG PLAYTIME
		{file=File("Data/Map/Campaign/Plaza.map"),			statId="Plaza",			type="Crystal",	sead=169366078,	waveCount=20},
		{file=File("Data/Map/Campaign/Long haul.map"),		statId="LongHaul",		type="Cart",	sead=202469227,	waveCount=20},--			U
		{file=File("Data/Map/Campaign/Dock.map"),			statId="Dock",			type="Crystal",	sead=842172835,	waveCount=25},--			X
		{file=File("Data/Map/Campaign/Crossroad.map"),		statId="Crossroad",		type="Crystal",	sead=365654225,	waveCount=25},--17500		X
		{file=File("Data/Map/Campaign/Mine.map"),			statId="Mine",			type="Cart",	sead=464004721,	waveCount=20},--			U
		{file=File("Data/Map/Campaign/Blocked path.map"),	statId="BlockedPath",	type="Crystal",	sead=32111861,	waveCount=20},
		{file=File("Data/Map/Campaign/The line.map"),		statId="TheLine",		type="Cart",	sead=202469227,	waveCount=20},--			X
		{file=File("Data/Map/Campaign/Rifted.map"),			statId="Rifted",		type="Crystal",	sead=27518540,	waveCount=25},--			X ish
		{file=File("Data/Map/Campaign/Paths.map"), 			statId="Paths",			type="Crystal",	sead=620382518,	waveCount=25},
		{file=File("Data/Map/Campaign/Divided.map"),		statId="Divided",		type="Crystal",	sead=615837167,	waveCount=25},--18000
		{file=File("Data/Map/Campaign/Nature.map"),			statId="Nature",		type="Crystal",	sead=581083960,	waveCount=25},--			BAD MAP
		{file=File("Data/Map/Campaign/Train station.map"),	statId="TrainStation",	type="Cart",	sead=680821396,	waveCount=25},
		{file=File("Data/Map/Campaign/The end.map"),		statId="TheEnd",		type="Crystal",	sead=394914309,	waveCount=30} --23600
	}
	--
	function self.fixCrystalLimits()
		if campaingData:get("crystal",0):getInt()>self.getMaxGoldNeededToUnlockEverything() then
			campaingData:get("crystal"):setInt(self.getMaxGoldNeededToUnlockEverything())
		end
	end
	function self.getCrystal()
		return campaingData:get("crystal",0):getInt()
	end
	local function updateAvailableMaps()
		--upto 3 unbeaten maps are available
		local window = (maps.finishedCount>=3 and 3 or maps.finishedCount+1)
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
			local map = campaingData:get("mapsFinished")
			for counter=1, #files do
				if map:exist("L"..counter) then
					maps.finished[counter] = self.hasMapBeenBeaten(counter)
					if maps.finished[counter] then
						maps.finishedCount = maps.finishedCount + 1
					end
				else
					maps.finished[counter] = false
				end
			end
			updateAvailableMaps()
		end
		--
		return (num>#maps.available and 0 or maps.available[num])
	end
	function self.hasMapBeenBeaten(number)
		local map = campaingData:get("mapsFinished")
		if map:exist("L"..number) then
			map = map:get("L"..number)
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
	function self.getMapModeBeatenLevel(number,mode)
		return campaingData:get("mapsFinished"):get("L"..number):get(mode,0):getInt()
	end
	function self.hasMapModeBeenBeaten(number,mode)
		return campaingData:get("mapsFinished"):get("L"..number):get(mode,0):getInt()>0
	end
	function self.hasMapModeLevelBeenBeaten(number,mode,level)
		return campaingData:get("mapsFinished"):get("L"..number):get(mode,0):getInt()>=level
	end
	function self.setLevelCompleted(number,level,mode)
		campaingData:get("mapsFinished"):get("L"..number):get(mode):setInt(level)
		campaingData:save()
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
		local tab = campaingData:get(towerName):getTable()
		local ret = 0
		for k,v in pairs(tab) do
			ret = ret + self.getBuyablesTotal(k,permUnlocked)
		end
		return ret
	end
	function self.getTotalBuyablesBoughtForTower(towerName,permUnlocked)
		local tab = campaingData:get(towerName):getTable()
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
		print("for i=1, "..#towers.." do")
		for i=1, #towers do
			print("i = "..i)
			print("for k,v in pairs("..towers[i]..") do")
			for k,v in pairs(campaingData:get(towers[i]):getTable()) do
				if v.buyable then
					local leftToBuy = self.getBuyablesTotal(k,false)-v.buyable
					local costLeft = leftToBuyTab[self.getBuyablesTotal(k,false)][v.buyable]*NORMALUPGCOST
					if leftToBuy==1 and self.getBuyablesTotal(k,false)==leftToBuy then
						costLeft = 3*NORMALUPGCOST
					end
					print(k.." =="..self.getBuyablesTotal(k,false).." left "..leftToBuy.." ["..tostring(ret + costLeft).." = "..ret.." + "..costLeft.."]")
					ret = ret + costLeft
				end
			end
			local leftToBuy = PERMENANTBOUGHTUPGRADECOUNT-self.getTotalBuyablesBoughtForTower(towers[i],true)
			local costLeft = leftToBuyTab[PERMENANTBOUGHTUPGRADECOUNT][self.getTotalBuyablesBoughtForTower(towers[i],true)]*PERMENANTUPGCOST
			print("Permenant("..leftToBuy.."): "..tostring(ret + costLeft).." = "..ret.." + "..costLeft)
			ret = ret + costLeft
		end
		print("ret = "..ret)
		return ret
	end
	function self.getBoughtUpg(towerName,upgradeName,permUnlocked)
		return campaingData:get(towerName):get(upgradeName):get(permUnlocked and "permUnlocked" or "buyable",0):getInt()
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
		local item = campaingData:get(towerName):get(upgradeName):get(permUnlocked and "permUnlocked" or "buyable",0)
		if item:getInt()<self.getBuyablesTotal(upgradeName) then
			if self.getBuyablesTotal(upgradeName)==1 and permUnlocked==false then
				return 3*NORMALUPGCOST
			end
			return (item:getInt()+1)*(permUnlocked and PERMENANTUPGCOST or NORMALUPGCOST)
		end
		return 0
	end
	--
	function self.addCrystal(addCount)
		print("self.addCrystal("..addCount..")")
		campaingData:get("crystal"):setInt(self.getCrystal()+addCount)
		self.fixCrystalLimits()
		campaingData:save()
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
					self.getCrystal()>=self.getBuyCost(towerName,upgradeName,permUnlocked)--we must have wnough gold
		end
	end
	function self.buy(towerName,upgradeName,permUnlocked)
		local item = campaingData:get(towerName):get(upgradeName):get(permUnlocked and "permUnlocked" or "buyable",0)
		local cost = self.getBuyCost(towerName,upgradeName,permUnlocked)
		if item:getInt()<self.getBuyablesTotal(upgradeName,permUnlocked) and cost<=self.getCrystal() and (permUnlocked==false or self.canBuyUnlock(towerName,upgradeName,true)) then
			item:setInt(item:getInt()+1)
			self.addCrystal(-cost)
		end
	end
	function self.clear(towerName,upgradeName,permUnlocked)
		local count = {[0]=0,[1]=1,[2]=3,[3]=6}
		local upgCount = self.getBoughtUpg(towerName,upgradeName,permUnlocked)
		campaingData:get(towerName):get(upgradeName):get(permUnlocked and "permUnlocked" or "buyable",0):setInt(0)
		self.addCrystal( count[upgCount]*(permUnlocked and PERMENANTUPGCOST or NORMALUPGCOST) )
		local val = campaingData:get(towerName):get(upgradeName):get(permUnlocked and "permUnlocked" or "buyable",0):getInt()
		if val>0 then
			error("Clearing failed for unlocked upgrades!!!")
		end
	end
	function self.getLevelCompleted(map)
		return campaingData:get(map):get("levelCompleted",4):getInt()--4 because there is 5 base levels available (you have level 5 unlocked by beating level 4)
	end
	return self
end