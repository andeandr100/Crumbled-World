require("Tower/UpgradeData.lua")

TowerData = {}
function TowerData.new()
	local self = {}
	
	local stats = {}
	local displayStats = {}
	local upgrades = {}
	local towerLevel = UpgradeData.new()
	local boostData = UpgradeData.new()
	local billboard = nil
--	local valueEfficiency = 1.0	--(0.75 if used)how much you will get back upon selling this tower
--	local totalCost = 0			--cost for only "upgrade"
	local dmgDone = 0
	--billboard = Billboard()
	local billboardWaveStats = nil
	--billboardWaveStats = Billboard()
	local canSyncTower = false
	--gameSessionBillboard = Billboard()
	local comUnit = nil
	local updateIndex = 0
	--comUnit = ComUnit()

	
	function self.setGameSessionBillboard(inGameSessionBillboard)
		billboardWaveStats = inGameSessionBillboard
	end
	
	function self.setBillboard( inBillboard )
		billboard = inBillboard
	end
	
	function self.setCanSyncTower(canSync)
		canSyncTower = canSync
	end
	
	function self.setComUnit(inComUnit)
		comUnit = inComUnit
	end
	
	local function achievementUnlocked(whatAchievement)
		if canSyncTower then
			comUnit:sendTo("SteamAchievement",whatAchievement,"")
		end
	end
	
	function self.addDisplayStats(displayStat)
		displayStats[#displayStats+1] = displayStat
	end
	
	function self.addTowerUpgrade(data)
		towerLevel.init( data )
		billboard:setFloat("cost", towerLevel.getCost(1))		
		billboard:setInt("level",towerLevel.getLevel())		
	end
	
	function self.addSecondaryUpgrade( data )
		local myData = UpgradeData.new()
		myData.init(data)
		upgrades[data.name] = myData
		return myData
	end
	
	function self.setTowerLevel(level)
		billboard:setInt("level",level)
		towerLevel.setLevel(level)
		
		if Core.isInMultiplayer() and Core.getNetworkName():len()>0 and canSyncTower then
			comUnit:sendNetworkSyncSafe("upgrade",tostring(param))
		end
		
		--Achievements
		comUnit:sendTo("stats","addBillboardInt","level"..level..";1")
		if level==3 then
			achievementUnlocked("Upgrader")
		end
		--
	end
	
--	function self.setUsed()
--		if valueEfficiency>0.75 then
--			valueEfficiency = 0.75
--			billboard:setFloat("value", totalCost*valueEfficiency)
--			comUnit:sendTo("stats","updateTowerValue","")
--		end
--	end
	
	function self.addBoostUpgrade( data )
		boostData.init(data)
	end
	
	function self.activateBoost()
		achievementUnlocked("Boost")
		boostData.activate()
	end
	
	function self.getBoostActive()
		return boostData.isActive()
	end
	
	function self.getUpgrade( upgrade )
		return upgrades[upgrade]
		--outUpgrade = 
	end
	
	function self.setUpgradeLevel( upgrade, level )
		if upgrades[upgrade] then
			upgrades[upgrade].setLevel(level)
			
			if Core.isInMultiplayer() and canSyncTower then
				comUnit:sendNetworkSyncSafe(upgrade,tostring(param))
			end
			
			if upgrade == "range" and level==3 then
				achievementUnlocked("Range")
			end
			
			return true
		end
		return false
		--outUpgrade = 
	end
	
	function self.getTowerLevel()
		return towerLevel.getLevel()
	end
	
	function self.getLevel(secondaryUpgradeName)
		return upgrades[secondaryUpgradeName].getLevel()
	end
	
	function self.getValue(value)
		return stats[value]
	end
	
	function self.getValue(value, defaultValue)
		return stats[value] and stats[value] or defaultValue
	end
	
	function self.addDamage( addDmg )
		dmgDone = dmgDone + addDmg
		billboard:setDouble("DamageCurrentWave",dmgDone)
		billboard:setDouble("DamageTotal",billboard:getDouble("DamagePreviousWave")+dmgDone)
	end
	
	
	function self.storeWaveChangeStats( wave, tab )
		billboard:setDouble("DamagePreviousWave",dmgDone)
		billboard:setDouble("DamagePreviousWavePassive",0.0)
		if canSyncTower then
			comUnit:sendTo("stats", "addTotalDmg", dmgDone )
		end
		
		--save the wave state
		if billboardWaveStats:exist( wave )==false then

			tab["DamagePreviousWave"] = billboard:getDouble("DamagePreviousWave")
			tab["DamagePreviousWavePassive"] = billboard:getDouble("DamagePreviousWavePassive")
			tab["DamageTotal"] = billboard:getDouble("DamageTotal")
			tab["currentTargetMode"] = billboard:getInt("currentTargetMode")
			tab["upgradeLevel"] = towerLevel.getLevel()
			
			for name,upgrade in pairs(upgrades) do
				tab[name] = upgrade.getLevel()
			end
			billboardWaveStats:setTable( wave, tab )

		end
		dmgDone = 0
	end
	
	function self.restoreWaveChangeStats( wave )
		dmgDone = 0
		--restore the wave state
		if wave<=0 then
			return nil
		end
		
		--we have gone back in time erase all tables that is from the future, that can never be used
		local index = wave+1
		while billboardWaveStats:exist( tostring(index) ) do
			billboardWaveStats:erase( tostring(index) )
			index = index + 1
		end
		
		--restore the stats from the wave
		local tab = billboardWaveStats:getTable( tostring(wave) )
		if tab then
			
			towerLevel.setLevel(tab.upgradeLevel)
			for name,upgrade in pairs(upgrades) do
				upgrades[name].setLevel( tab[name] )
			end
			
			billboard:setDouble("DamagePreviousWave", tab.DamagePreviousWave)
			billboard:setDouble("DamageCurrentWave", tab.DamagePreviousWave)
			billboard:setDouble("DamagePreviousWavePassive", tab.DamagePreviousWavePassive)
			billboard:setDouble("DamageTotal", tab.DamageTotal)
			
			
		end
		
		self.updateStats()
		
		return tab
	end
	
	-- function:	add
	-- purpose:
	function self.add(value1, value2)
		return value1 + value2
	end
	-- function:	mul
	-- purpose:
	function self.mul(value1, value2)
		return value1 * value2
	end
	
	-- function:	mul
	-- purpose:
	function self.set(value1, value2)
		return value2
	end
	
	--Calculate all Values
	function self.updateStats()

		stats = {}
		
		--Set base stats
		local level = towerLevel.getLevel()
		for key,value in pairs(towerLevel.getStats()) do
			stats[key] = value[level]
		end

		local towerStats = {}		
--		for i=1, #displayStats, 1 do
--			billboard:setFloat(displayStats[i], stats[displayStats[i]])
--			towerStats[displayStats[i]] = stats[displayStats[i]]
--		end
		for key,value in pairs(stats) do
			billboard:setDouble(key, value)
			towerStats[key] = value
		end
		
		--Apply all Secondary upgrades
		for name,upgrade in pairs(upgrades) do
			local level = upgrade.getLevel()
			--Only apply if the
			if level > 0 then
				for key,value in pairs(upgrade.getStats()) do
					stats[key] = value.func( stats[key], value[level] )
				end
			end
		end
		
		--Apply Boost
		if boostData.isActive() then
	
			local level = boostData.getLevel()+1
			--Only apply if the
			if level > 0 then
				for key,value in pairs(boostData.getStats()) do
					stats[key] = value.func( stats[key], value[level] )
				end
			end

		end
		
		--Infromation for selected Tower Menu
		
		billboard:setTable("displayStats", displayStats)
		billboard:setInt("value", 123 )
		
--		for i=1, #displayStats, 1 do
--			billboard:setFloat(displayStats[i].."-upg", stats[displayStats[i]] - towerStats[displayStats[i]])
--		end
		
		for key,value in pairs(stats) do
			billboard:setFloat(key.."-upg", value - (towerStats[key] and towerStats[key] or 0.0))
		end
		
		
		updateAllUpgradeBillboard()
	end
	
	function updateAllUpgradeBillboard()
		
		
		
		--Main tower upgrade
		if towerLevel.getLevel() < towerLevel.getMaxLevel() then
			local towerUpgrade = {}
			towerUpgrade.name = towerLevel.getName()
			towerUpgrade.icon = towerLevel.getIconId()
			towerUpgrade.info = towerLevel.getInfo()
			towerUpgrade.level = towerLevel.getLevel() + 1
			towerUpgrade.maxLevel = towerLevel.getMaxLevel()
			towerUpgrade.cost = towerLevel.getCost(towerUpgrade.level)
			
			if billboard:getBool("isNetOwner")==false then
				towerUpgrade.locked =  "not your tower"
			elseif TODO then
				towerUpgrade.locked =  "shop required"
			else
				towerUpgrade.locked = nil
			end
			
			towerUpgrade.values = {}
			towerUpgrade.stats = {}
			for key,value in pairs(towerLevel.getStats()) do
				
				local diffValue = value[towerUpgrade.level] - value[towerUpgrade.level - 1]
				if diffValue ~= 0 then
					towerUpgrade.values[#towerUpgrade.values+1] = diffValue
					towerUpgrade.stats[key] = diffValue
				end
			end
			
			billboard:setTable("towerUpgrade", towerUpgrade)
		else
			local towerUpgrade = {}
			towerUpgrade.name = towerLevel.getName()
			towerUpgrade.level = towerLevel.getMaxLevel() + 1
			towerUpgrade.maxLevel = towerLevel.getMaxLevel()
			towerUpgrade.cost = 0
			billboard:setTable("towerUpgrade", towerUpgrade)
		end
		
		
		local towerUpgrades = {}
		local activeTowerUpgrades = {}
		
		--Sub upgrades
		for name, data in pairs(upgrades) do
			
			local upgrade = {}
			
			local level = data.getLevel() + 1
			if level < data.getMaxLevel()+1 then
				upgrade.name = data.getName()
				upgrade.icon = data.getIconId()
				upgrade.info = data.getInfo()
				upgrade.level = level
				upgrade.maxLevel = data.getMaxLevel()
				upgrade.cost = data.getCost(level)
				
				if billboard:getBool("isNetOwner")==false then
					upgrade.locked =  "not your tower"
				elseif level > towerLevel.getLevel() then
					upgrade.locked =  "tower level "..level
				elseif TODO then
					upgrade.locked =  "shop required"
				else
					upgrade.locked = nil
				end
				
				--This values are used for tooltip in towerMenu
				--TODO add sort value to get the values in correct order
				upgrade.values = {}
				upgrade.stats = {}
				for key,value in pairs(data.getStats()) do
					local displayValue = (not value.func or value.func == self.add) and value[level] or (value[level] - 1.0) * 100
					upgrade.values[#upgrade.values+1] = displayValue
					upgrade.stats[key] = displayValue
				end
			else
				upgrade.name = data.getName()
				upgrade.level = data.getMaxLevel() + 1
				upgrade.maxLevel = data.getMaxLevel()
			end
			
			
			towerUpgrades[#towerUpgrades+1] = upgrade
			
			
			--this is used for the info icons in the select menu
			local activeUpgrade = {}
			level = data.getLevel()
			if level > 0 then
				activeUpgrade.name = data.getName()
				activeUpgrade.icon = data.getIconId()
				activeUpgrade.info = data.getInfo()
				activeUpgrade.level = level
				
				activeUpgrade.values = {}
				activeUpgrade.stats = {}
				for key,value in pairs(data.getStats()) do
					local displayValue = (not value.func or value.func == self.add) and value[level] or (value[level] - 1.0) * 100
					activeUpgrade.values[#activeUpgrade.values+1] = displayValue
					activeUpgrade.stats[key] = displayValue
				end
				activeTowerUpgrades[#activeTowerUpgrades+1] = activeUpgrade
			end
		end
		updateIndex = updateIndex + 1
		billboard:setTable("upgrades", towerUpgrades)
		billboard:setTable("activeTowerUpgrades", activeTowerUpgrades)
		billboard:setInt( "updateIndex", updateIndex )
	end
	
	function self.getIsMaxedOut()
		if towerLevel.getLevel() < 3 then
			return false
		end
		for name,upgrade in pairs(upgrades) do
			if upgrade.getLevel() < 3 then
				return false
			end
		end
		return true
	end
	
	return self
end