-- assumption. All levels of an upgrade must have all the stats(that is used in that upgrade level[1,3]), even if not changed from previous level
-- assumption. All levels of an upgrade must have cost, icon, info
-- assumption. only one upgrade if using duration. [The GUI only supports one cooldown]
-- assumption. upgrading the base level on a tower is named "upgrade"

Upgrade = {}
function Upgrade.new()
	local self = {}
	local isInXpMode = Core.getGlobalBillboard("MapInfo"):getString("GameMode")=="leveler"
	local statsBilboard = isInXpMode and Core.getBillboard("stats") or nil
	local billboard		--billboard = Billboard()
	local upgradesAvailable = {}	--[upgrade][1].level	/	[upgrade][1][stats][damage][2]=31	--[upgrade][1][stats][damage][1]==how it should be added [upgrade][1][stats][damage][2]==the value
	local upgraded = {}			--[1].level				/	[1][stats][damage][2]=31			--[1]==order [2]==level
	local stats = {}				--stats[damage]=31
	local statsToBillboard = {}
	local valueEfficiency = 1.0	--(0.75 if used)how much you will get back upon selling this tower
	--local value = 0			--cost for everything with valueEfficiency used
	local totalCost = 0			--cost for only "upgrade"
	local displayStat = {}		--displayStat[1]="damage"
	local displayOrder = {}		--displayOrder["upgrade"]=1
	local subUpgradeCount = 0
	local subUpgradeCountTotal = 0
	local subUpgradeDiscount = 0.0
	local freeSubUpgradesCount = 0
	local upgradeDiscount = 0
	local diffUpgradeCount = 0 
	local interpolation = 0.0	--when leveling mode is active
	local comUnit = Core.getComUnit()
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	local bilboardStats = Core.getBillboard("stats")
	local ignoreUpgrade = true
	local xpSystem

	--real version:
	--billboard(cost) = 150
	--billboard(value) = 150*0.75
	--billboard(currentStats) = damage=230;RPS=0.5;range=8
	--billboard(numupgrades) = 6
	--billboard(upgrade1) = "cost=300;icon=56;info="upgrades the tower";damage=425;RPS=0.071428571428571;range=0.5"
	--billboard(upgrade2) = "cost=15;icon=57;info="fires rockets, that explode on impact for 10s";duration=10;damage=690;range=0.8"
	--billboard(upgrade3) = "cost=100;icon=59;info="increase range by 20%";range=1.6"
	--billboard(upgrade4) = "cost=100;icon=60;info="burns npcs for 50% damge over 2s";fireDPS=57.5;burnTime=2"
	--billboard(upgrade5) = "cost=100;icon=60;info="target takes 10% extra damage, for 5s";weaken=0.1"
	--billboard(upgrade6) = ""	--empty string, never gonna be available again. will take up an empty space
	----- fake version but valid:
	-- "currentStats" = "damage=1.0;RPS=2.0"
	-- "numupgrades" = 5												--upgrades available
	-- "upgrade1" = "cost=32;icon=4;duration=10;cooldown=180;damage=2;RPS=2.0"		--all none key values should be displayed. keyValues = {cost,icon,duration}
	-- "upgrade2" = "cost=10;icon=12;method=\"instant\""				--strings have \" around them
	-- "upgrade3" = "cost=32;icon=2;damage=2;RPS=-0.25"					-- -0.25 are a negative number
	-- "upgrade4" = "icon=16;duration=10;timerStart=230.1229369"		--temporarily disabled, due to timmer or level. should be greyed out
	-- "upgrade5" = ""													--never gonna be available again. will take up an empty space
	-- all numbers are the change, if they are upgraded
	
	-- function:	getUpgradesAvailable
	-- purpose:		returns a table with all upgrades available
	function self.getUpgradesAvailable()
		return upgradesAvailable
	end
	-- function:	setBillboard
	-- purpose:
	function self.setBillboard( theBillboard )
		billboard = theBillboard
		--self.billboard = Billboard()
	end
	-- function:	getCopyOfTable
	-- purpose:		returns a copy of a table, that has no references linking them
	local function getCopyOfTable(table)
		if type(table)~="table" then
			return table
		end
		--it is a table
		local ret = {}
		for k,v in pairs(table) do
			ret[k] = getCopyOfTable(v)
		end
		return ret
	end
	-- function:	getBetween
	-- purpose:		returns a intepolated number between the param and with the per as where it placed it
	local function getBetween(num1,num2,per)
		return num1+((num2-num1)*per)
	end
	-- function:	addUpgrade
	-- purpose:		adds an upgrade and all info needed to use it with the functions "upgrade()" and "degrade()"
	function self.addUpgrade( upg, addSubCount )
		addSubCount = addSubCount==nil and 0 or addSubCount--how many upgrades extra between that will be add
		if not upgradesAvailable[upg.name] then
			addSubCount = 0
			upgradesAvailable[upg.name] = {}
			diffUpgradeCount = diffUpgradeCount + 1
			displayOrder[upg.name] = diffUpgradeCount
			billboard:setInt("numupgrades",diffUpgradeCount)
			billboard:setString("upgrade"..diffUpgradeCount,"")--insert a default billboard
		end
		local prevUpg = upgradesAvailable[upg.name] and upgradesAvailable[upg.name][#upgradesAvailable[upg.name]] or nil
		for i=1, addSubCount do
			local subUpg = {}
			subUpg.name = upg.name
			subUpg.icon = upg.icon
			subUpg.info = "Partial upgrade"
			subUpg.level = #upgradesAvailable[upg.name]+1
			subUpg.cost = (upg.cost and upg.cost or upg.costFunction())/(addSubCount+1)
			subUpg.levelRequirement = upg.levelRequirement or 0
			subUpg.stats = getCopyOfTable(upg.stats)
			subUpg.value1 = upg.value1
			subUpg.value2 = upg.value2
			--stats
			for key,val in pairs(subUpg.stats) do
				if type(val)=="table" then
					if type(val[2])=="number" then
						subUpg.stats[key][2] = getBetween(prevUpg.stats[key][2],subUpg.stats[key][2],i*(1/(addSubCount+1)))
					end
				else
					error("stats must be formated like stats={damage={upgrade.add, 5.0}}")
				end
			end
			--
			--print("subUpg == "..tostring(subUpg).."\n")
			--add the subUpgrade
			upgradesAvailable[upg.name][#upgradesAvailable[upg.name]+1] = subUpg
		end
		upg.level = #upgradesAvailable[upg.name]+1
		if addSubCount==0 then
			upg.cost = upg.cost and upg.cost or upg.costFunction()
		else
			upg.cost = (upg.cost and upg.cost or upg.costFunction())/(addSubCount+1.0)
		end
		upg.levelRequirement = upg.levelRequirement or 0
		print("upgLevel == "..tostring(#upgradesAvailable[upg.name]+1))
		print("upg == "..tostring(upg))
		upgradesAvailable[upg.name][#upgradesAvailable[upg.name]+1] = upg
		-- set the default build cost
		billboard:setFloat("cost", upgradesAvailable["upgrade"][1].cost)
	end
	-- function:	addDisplayStats
	-- purpose:		stats that will be displayed in the "selected tower menu"
	function self.addDisplayStats( stat )
		displayStat[#displayStat+1] = stat
		statsToBillboard[#statsToBillboard+1] = stat
	end
	-- function:	addBillboardStats
	-- purpose:
	function self.addBillboardStats( stat )
		statsToBillboard[#statsToBillboard+1] = stat
	end
	--
	-- function:	storeWaveChangeStats
	-- purpose:		store all data needed to restore the xpSystem to a previous state
	function self.storeWaveChangeStats()
		--print("self.storeWaveChangeStats()")
		local tab = {
			upgradesAvailable = getCopyOfTable(upgradesAvailable),
			upgraded = getCopyOfTable(upgraded),
			stats = getCopyOfTable(stats),
			subUpgradeCount = subUpgradeCount,
			subUpgradeCountTotal = subUpgradeCountTotal,
			subUpgradeDiscount = subUpgradeDiscount,
			freeSubUpgradesCount = freeSubUpgradesCount,
			upgradeDiscount = upgradeDiscount,
			diffUpgradeCount = diffUpgradeCount,
			interpolation = interpolation,
			ignoreUpgrade = ignoreUpgrade,
			totalCost = totalCost,
			valueEfficiency = valueEfficiency
		}
		return tab
	end
	-- function:	mergeTables
	-- purpose:		merges 2 tables
	-- function:	combineTables
	-- purpose:		combines 2 tables and make them equal except for functions
	local function combineTables(destination,source)
		--remove all values that is not available in the source
		for key,value in pairs(destination) do
			if type(destination[key])~="function" and (not source[key]) then
				destination[key] = nil
			end
			if type(source[key])=="function" and type(destination[key])~="function" then
				destination[key] = source[key]
			end
		end
		--replace all variables
		for key,value in pairs(source) do
			if type(source[key])=="table" then
				if type(destination[key])~="table" then
					destination[key] = {}
				end
				combineTables(destination[key],source[key])
			else
				destination[key] = source[key]
			end
		end
	end
	-- function:	restoreWaveChangeStats
	-- purpose:		restore the cpSystem to a previous state, with data from self.storeWaveChangeStats()
	function self.restoreWaveChangeStats(tab)
		--print("self.restoreWaveChangeStats("..tostring(tab)..")")
		--mergeTables(tab.data,self)
		combineTables(upgradesAvailable,tab.upgradesAvailable)
		combineTables(upgraded,tab.upgraded)
		--upgraded = getCopyOfTable(tab.upgraded)
		combineTables(stats,tab.stats)
		subUpgradeCount = tab.subUpgradeCount
		subUpgradeCountTotal = tab.subUpgradeCountTotal
		subUpgradeDiscount = tab.subUpgradeDiscount
		freeSubUpgradesCount = tab.freeSubUpgradesCount
		upgradeDiscount = tab.upgradeDiscount
		diffUpgradeCount = tab.diffUpgradeCount
		interpolation = tab.interpolation
		ignoreUpgrade = tab.ignoreUpgrade
		totalCost = tab.totalCost
		valueEfficiency = tab.valueEfficiency
		self.fixBillboardAndStats()
	end
	-- function:	upgrade
	-- purpose:		do an upgrade
	function self.upgrade( name )
--		print("self.upgrade( "..name.." )c")
		--assert(upgradesAvailable[name],"no upgrade available with name:\""..name.."\" in upgradesAvailable:"..tostring(upgradesAvailable))
		--add cost to value
		
		local order = upgradesAvailable[name][1].order
		local prevInterpolation = interpolation
		interpolation = 0.0--interpolations must be 0 when upgrading
		
		--protection from upgrading non existing upgrades
		if upgraded[order] and not upgradesAvailable[name][upgraded[order].level+1] then
			return		
		end
		
		if isThisReal then
			if name=="upgrade" and upgraded[order] then
				comUnit:sendTo("stats","addTowerUpgraded","")
			elseif name=="boost" then
				comUnit:sendTo("stats","addTowerBoosted","")
			elseif (not upgradesAvailable[name][1].hidden) and name~="rotate" and name~="upgrade" then
				comUnit:sendTo("stats","addTowerSubUpgraded","")
			end
		end
		if not (name=="upgrade" or name=="boost" or name=="calculate" or upgradesAvailable[name][1].hidden) and freeSubUpgradesCount>0 then
			subUpgradeCount = subUpgradeCount - ((name=="upgrade" or name=="boost" or name=="calculate" or name=="range" or name=="rotate" or name=="gold" or name=="supportRange" or name=="supportDamage" or name=="smartTargeting") and 0 or 1)
			freeSubUpgradesCount = math.max(0,freeSubUpgradesCount - 1)
		else
			local lCost = (upgraded[order] and upgradesAvailable[name][upgraded[order].level+1].cost or upgradesAvailable[name][1].cost)
			totalCost = totalCost + lCost
			
			if isInXpMode then
				if name=="upgrade" then
					lCost = lCost - (lCost * upgradeDiscount)
					upgradeDiscount = 0.0
				else
					lCost = lCost - (lCost * subUpgradeDiscount)
					subUpgradeDiscount = 0.0
				end
			end
			
			if ignoreUpgrade == false then
				if billboard:getBool("isNetOwner") then
					comUnit:sendTo("stats","removeGold",tostring(lCost))
--					print("# upgrade: "..name)
--					print("# cost: "..lCost)
				end
			else
				ignoreUpgrade = false
			end
		end
		billboard:setDouble("value", totalCost*valueEfficiency)--value)
		billboard:setDouble("totalCost",totalCost)
		local d1 = (upgraded[order] and tostring(upgraded[order].level) or "0")
		self.upgradeOnly( name, true )
		if upgradesAvailable[name][1].duration then
			--if upgrade is temporary
			--self.timer = upgradesAvailable[name][1].duration
			upgradesAvailable[name][1].isOnDuration = true
			upgradesAvailable[name][1].startTimerDuration = Core.getGameTime()
			--self.timerName = name
		end
		if upgradesAvailable[name][1].cooldown then
			--if not temporary upgrade then set cooldown directly
			upgradesAvailable[name][1].startWaveCooldown = Core.getBillboard("stats"):getInt("wave")
			upgradesAvailable[name][1].isOnCoolDown = true
			--self.timer = upgradesAvailable[name][1].cooldown
			--self.timerName = ""
		end
		--Acievements
		if name=="boost" then
			if bilboardStats:getInt("boostCount")==49 then
				comUnit:sendTo("SteamAchievement","Booster","")
			end
			comUnit:sendTo("stats","addBillboardInt","boostCount;1")
		end
		--
		if name~="upgrade" then
			interpolation = prevInterpolation
		end
		self.fixBillboardAndStats()
		if isInXpMode then
			xpSystem.updateXpToNextLevel()
		end
	end
	-- function:	fixBillboardAndStats
	-- purpose:		updates all billboards and recalculates all stats
	function self.fixBillboardAndStats()
		--print("self.fixBillboardAndStats() - BEG\n")
		--recalculate the cost
		for key, value in pairs(upgradesAvailable) do
			local level = (not upgraded[value[1].order]) and 1 or upgraded[value[1].order].level+1
			if  value[level] then
				value[level].cost = value[level].costFunction and value[level].costFunction() or value[level].cost
			end
		end
		--fix the billboard
		self.updateAllUpgradeBillboard()
		self.calculateStats( "upgrade", true )
		--extra billboard stats
		for index, value in ipairs(statsToBillboard) do
			--print("["..index.."] = "..value.."\n")
			if stats[value] then
				local val = self.getValue(value)
				if type(val)=="number" then
					billboard:setFloat(value,val)
				else
					billboard:setString(value,val)
				end
				--print("billboard(\""..value.."\") == "..val.."\n")
			else
				billboard:setFloat(value,0.0)
				billboard:setString(value,"")
			end
		end
		--
		upgraded.version = upgraded.version and upgraded.version + 1 or 1
		billboard:setTable("upgraded",upgraded)
		--print("=======================================\n")
		--print(tostring(upgraded).."\n")
		--print("self.fixBillboardAndStats() - END\n")
	end
	-- function:	upgradeOnly
	-- purpose:		a fake upgrade to allow us to se what effect this upgrade will have
	function self.upgradeOnly( name, toBillboard )
		--print("self.upgradeOnly("..name..") - BEG\n")
		--upgrade name
		local order = upgradesAvailable[name][1].order
		local d1 = upgraded[order] and upgraded[order].level or 0
		if upgraded[order] then
			print("has been upgraded before")
			--has been upgraded before
			upgraded[order] = getCopyOfTable(upgradesAvailable[name][upgraded[order].level+1])
		else
			print("not listed, grab level 1 version of it")
			--not listed, grab level 1 version of it
			upgraded[order] = getCopyOfTable(upgradesAvailable[name][1])
		end
		if d1==upgraded[order].level then
			local d2 = upgradesAvailable[name]
			local d3 = upgraded[order]
			abort()
		end
		--value = value + upgraded[order].cost
		subUpgradeCount = subUpgradeCount + ((name=="upgrade" or name=="boost" or name=="calculate" or name=="range" or name=="gold" or name=="supportRange" or name=="supportDamage" or name=="smartTargeting") and 0 or 1)
		subUpgradeCountTotal = subUpgradeCountTotal + ((name=="upgrade" or name=="boost" or name=="calculate" or name=="gold" or name=="supportRange" or name=="supportDamage") and 0 or 1)
		--calculate the stats
		self.calculateStats( name, toBillboard )
		--print("self.upgradeOnly("..name..") - END\n")
	end
	-- function:	degrade
	-- purpose:		degrades an upgrade(usefull when going back in time or rolling back time based upgrades)
	function self.degrade( name )
		--print("self.degrade("..name..")\n")
		--degrade is only leagal for boost
		self.degradeOnly( name, true )
		--recalculate the cost
		for key, value in pairs(upgradesAvailable) do
			local level = (not upgraded[value[1].order]) and 1 or upgraded[value[1].order].level+1
			if  value[level] then
				value[level].cost = value[level].costFunction and value[level].costFunction() or value[level].cost
			end
		end
		--fix cooldown timer
		if upgradesAvailable[name][1].cooldown then
			--upgradesAvailable[name][1].startWaveCooldown = Core.getBillboard("stats"):getInt("wave")
			upgradesAvailable[name][1].isOnCoolDown = true
			--self.timer = upgradesAvailable[name][1].cooldown
			--self.timerName = ""
		end
		self.fixBillboardAndStats()
		if isInXpMode then
			xpSystem.updateXpToNextLevel()
		end
	end
	-- function:	degradeOnly
	-- purpose:		a fake degrade to allow us to se what effect this upgrade will have
	function self.degradeOnly( name, toBillboard )
		--degrade name
		local order = upgradesAvailable[name][1].order
		local currentLevel = upgraded[order].level
		--value = value - upgraded[order].cost
		subUpgradeCount = subUpgradeCount - ((name=="upgrade" or name=="boost" or name=="calculate" or name=="range" or name=="gold" or name=="supportRange" or name=="supportDamage" or name=="smartTargeting") and 0 or 1)
		subUpgradeCountTotal = subUpgradeCountTotal - ((name=="upgrade" or name=="boost" or name=="calculate" or name=="gold" or name=="supportRange" or name=="supportDamage") and 0 or 1)
		if currentLevel==1 then
			--set it to not been upgraded before
			upgraded[order] = nil
		else
			--revert to previous version
			upgraded[order] = getCopyOfTable(upgradesAvailable[name][currentLevel-1])
		end
		--calculate the stats
		self.calculateStats( name, toBillboard )
	end
	-- function:	clearCooldown
	-- purpose:
	function self.clearCooldown()
		for key, value in pairs(upgradesAvailable) do
			--get the next level for that upgrade
			local level = (not upgraded[value[1].order]) and 1 or upgraded[value[1].order].level+1
			if  value[level] and (not value[level].hidden) then
				if value[1].isOnDuration then
					value[1].isOnDuration = false
				end
				local onCooldown = (value[1].cooldown and value[1].isOnCoolDown==true and value[1].startWaveCooldown and (value[1].startWaveCooldown+value[1].cooldown)>Core.getBillboard("stats"):getInt("wave") )
				if onCooldown then
					value[1].isOnCoolDown = false
					self.fixBillboardAndStats()
				end
			end
		end
	end
	-- function:	updateAllUpgradeBillboard
	-- purpose:
	function self.updateAllUpgradeBillboard()
		--loop threw all upgrades there is
		for key, value in pairs(upgradesAvailable) do
			--get the next level for that upgrade
			local level = (not upgraded[value[1].order]) and 1 or upgraded[value[1].order].level+1
			if  value[level] and (not value[level].hidden) then
				local onCooldown = (value[1].cooldown and value[1].isOnCoolDown==true and value[1].startWaveCooldown and (value[1].startWaveCooldown+value[1].cooldown)>Core.getBillboard("stats"):getInt("wave") )
				--if there is a new level available for that upgrade
				local str = ""
				--create a table with all stats  before the upgrade, so we can get out the difference
				local beforeStats = {}
				self.saveDisplayStatsIn( beforeStats )
				self.upgradeOnly(value[level].name, false)
				--set base info for the buy window
				if billboard:getBool("isNetOwner")==false then
					str = str.."isOwner=false;"
					str = str.."require=\"not your tower\";"
				elseif (value[level].requirementNotUpgraded1 and self.getLevel(value[level].requirementNotUpgraded1)>0) or (value[level].requirementNotUpgraded2 and self.getLevel(value[level].requirementNotUpgraded2)>0) then
					str = str.."require=\"conflicting upgrade\";"
				elseif isInXpMode and value[level].name=="upgrade" and statsBilboard:getInt("wave")<(level-1)*10 then
					str = str.."require=\"Wave\";"
					value[1].startWaveCooldown = 0
					value[1].cooldown = (level-1)*10
					value[level].startWaveCooldown = 0
					value[level].cooldown = (level-1)*10
				elseif value[level].name~="upgrade" and  value[level].levelRequirement==4 then
					str = str.."require=\"shop required\";"
				elseif value[level].name~="upgrade" and self.getLevel("upgrade")<level then
					str = str.."require=\"tower level "..level.."\";"
				elseif value[level].levelRequirement>self.getLevel("upgrade") then
					str = str.."require=\"tower level "..value[level].levelRequirement.."\";"
				elseif onCooldown then
					str = str.."require=\"Wave\";"--..tostring(value[1].startWaveCooldown+value[1].cooldown).."\";"
				else
					--upgrade is available
					if isInXpMode then
						if value[level].name=="upgrade" then
							local calculatedCost = math.max(0.0, value[level].cost - (value[level].cost*upgradeDiscount) )
							str = str.."cost="..math.floor(calculatedCost)..";"
						else
							local calculatedCost = math.max(0.0, value[level].cost - (value[level].cost*subUpgradeDiscount) )
							str = str.."cost="..math.floor(calculatedCost)..";"
						end
					else
						str = str.."cost="..math.floor(value[level].cost)..";"
					end
				end
				str = str.."icon="..value[level].icon..";"
				str = str.."level="..level..";"
				str = str.."info=\""..value[level].info.."\";"
				str = str.."name=\""..value[level].name.."\";"
				if value[level].value1 then
					str = str.."value1="..value[level].value1..";"
				end
				if value[level].value2 then
					str = str.."value2="..value[level].value2..";"
				end
	--			if value[1].duration then
	--				str = str.."duration="..value[level].duration..";"
	--			end
				local cooldownStr = value[level].cooldown and tostring(value[level].cooldown) or "0"
				local startWaveCooldownStr = value[1].startWaveCooldown and tostring(value[1].startWaveCooldown) or "0"
				if isInXpMode and value[level].name=="upgrade" and statsBilboard:getInt("wave")<(level-1)*10 then
					str = str.."duration="..cooldownStr..";timerStart="..startWaveCooldownStr..";"
				elseif onCooldown then
					str = str.."duration="..cooldownStr..";timerStart="..startWaveCooldownStr..";"
				end
				--add specific information
				str = str..self.getDisplayStatStr( beforeStats, value[level].name )
				--remove the ';' character in the end
				str = str:sub(1,-2)
				--print("str = "..str)
				billboard:setString("upgrade"..displayOrder[value[1].name],str)
				self.degradeOnly(value[1].name,false)
			else
				--there is not an upgrade available (we have maxed it out)
				--print("level = "..tostring(level))
				--print("value = "..tostring(value))
				if value[1].duration then
					if value[level] and value[level].hidden then
						billboard:setString("upgrade"..displayOrder[value[1].name],"")
					else
						--it is based on a timer
						billboard:setString("upgrade"..displayOrder[value[1].name],"icon="..value[1].icon..";duration="..value[1].duration..";timerStart="..value[1].startTimerDuration)
					end
				else
					--not based on a timer
					billboard:setString("upgrade"..displayOrder[value[1].name],"")
				end
			end
		end
	end
	-- function:	saveDisplayStatsIn
	-- purpose:
	function self.saveDisplayStatsIn( tab )
		for key, value in ipairs(displayStat) do
			tab[value] = (type(stats[value])=="function") and stats[value]() or stats[value]
		end
	end
	-- function:	calculateStats
	-- purpose:
	function self.calculateStats( name, toBillboard )
		--print("self.calculateStats("..name..") - BEG\n")
		--recalculate all stats, because functions may have unknow dependencies
		local allToBeUpdated = {}
		for key, value in pairs(displayStat) do 
			allToBeUpdated[value] = 1
		end
		for key, value in pairs(upgradesAvailable[name][1].stats) do
			allToBeUpdated[key] = 1
		end
		for stat, index in pairs(allToBeUpdated) do
			--set default value to nil
			stats[stat] = nil
			--loop throgh all upgrades
			for key, value in pairs(upgraded) do
				if key ~= "version" and value.stats[stat] then
					value.stats[stat][1](stat,value.stats[stat][2])
				end
			end
			--update billboard
			if toBillboard then
				billboard:setString("currentStats",self.getDisplayStatStr({},nil):sub(1,-2))
			end
		end
		--print("self.calculateStats("..name..") - END\n")
	end
	-- function:	valueToString
	-- purpose:
	local function valueToString(value)
		--could use math.floor(math.log10) to get the 10^x but why complicate a simple issue
		--2 significants are to little, 3 is almost to much
		if math.abs(value)<0 then
			return string.format("%.3f",value)
		elseif math.abs(value)<10 then
			return string.format("%.2f",value)
		elseif math.abs(value)<100 then
			return string.format("%.1f",value)
		else
			return string.format("%.0f",value)
		end
	end
	-- function:	setInterpolation
	-- purpose:
	function self.setInterpolation(val)
		interpolation = val
	end
	-- function:	getDisplayStatStr
	-- purpose:
	function self.getDisplayStatStr( beforeStats, name )
		local str = ""
		--loop all stats that can be displayed and are in use
		for index, value in ipairs(displayStat) do
			if stats[value] then
				if beforeStats[value] then
					--if we have an earlier version of the stat, calulate the differens and use that
					local val = self.getValue(value)
					if type(val)=="number" then
						if (val-beforeStats[value])~=0 then
							str = str..value.."="..valueToString(val-beforeStats[value])..";"
						end
					elseif name and type(upgradesAvailable[name][1].stats[value])=="table" then
						str = str..value.."=\""..val.."\";"
					end
				else
					--no history just add it to string
					local val = self.getValue(value)
					if type(val)=="number" then
						str = str..value.."="..valueToString(val)..";"
					else
						str = str..value.."=\""..val.."\";"
					end
				end
			end
		end
		return str
	end
	-- function:	getLevel
	-- purpose:
	function self.getLevel( name )
		if upgradesAvailable[name] then
			if upgraded[upgradesAvailable[name][1].order] then
				return upgraded[upgradesAvailable[name][1].order].level
			end
		else
			error("no upgrade with the name(\""..name.."\")")
		end
		return 0
	end
	-- function:	getValue
	-- purpose:
	function self.getValue( stat )
		if (type(stats[stat])~="nil") then
			if interpolation and interpolation>0.0 and self.getLevel("upgrade")<3 then
				local d1 = self.getLevel("upgrade")
				local d2 = interpolation
				local currentStats = type(stats[stat])=="function" and stats[stat]() or stats[stat]
				--interpolation can only occurre if it is a number to work with
				if type(currentStats)=="string" then
					return currentStats
				else
					self.upgradeOnly( "upgrade", false)
					local futureStats = type(stats[stat])=="function" and stats[stat]()	 or stats[stat]
					self.degradeOnly( "upgrade", false)
					if currentStats and futureStats then
						return currentStats + (futureStats-currentStats)*interpolation
					end
				end
			end
			if type(stats[stat])=="function" then
				return stats[stat]()
			end
			return stats[stat]
		end
		return 0
	end
	-- function:	getValueForUpgrade
	-- purpose:
	function self.getValueForUpgrade( stat, upgradeName )
		local order = upgradesAvailable[upgradeName][1].order
		local currentLevel = upgraded[order].level
		return upgradesAvailable[upgradeName][currentLevel].stats[stat][2]
	end
	-- function:	getTotalCost
	-- purpose:
	function self.getTotalCost()
		return totalCost
	end
	-- function:	getStats
	-- purpose:
	function self.getStats(statsName)
		return stats[statsName]
	end
	-- function:	calculateCostBoost
	-- purpose:
	function self.calculateCostBoost()
		return totalCost*0.1
	end
	-- function:	getNextPaidSubUpgradeCost
	-- purpose:		returns the full price of the nextSubUpgrade
	function self.getNextPaidSubUpgradeCost()
		local baseCost = upgradesAvailable["upgrade"][1].cost*0.5
		local totalCost = isInXpMode and baseCost + (subUpgradeCountTotal*baseCost) or baseCost + (subUpgradeCount*baseCost)
		return totalCost-(totalCost*subUpgradeDiscount)--freeSubUpgrades is a discount value (sort of)
	end
	-- function:	getNextUpgradeCost
	-- purpose:
	function self.getNextUpgradeCost( name )
		local order = upgradesAvailable[name][1].order
		--protection from upgrading non existing upgrades
		if upgraded[order] and not upgradesAvailable[name][upgraded[order].level+1] then
			return 0
		end
		return (upgraded[order] and upgradesAvailable[name][upgraded[order].level+1].cost or upgradesAvailable[name][1].cost)
	end
	-- function:	calculateCostUpgrade
	-- purpose:		calculate actual subUpgradeCost with discount
	function self.calculateCostUpgrade()
		if freeSubUpgradesCount<1.0 then
			local baseCost = upgradesAvailable["upgrade"][1].cost*0.5
			local totalCost = isInXpMode and baseCost + (subUpgradeCountTotal*baseCost) or baseCost + (subUpgradeCount*baseCost)
			return totalCost-(totalCost*subUpgradeDiscount)--freeSubUpgrades is a discount value (sort of)
		end
		return 0
	end
	-- function:	calculateCostUpgrade
	-- purpose:		calculate actual subUpgradeCost with discount
	function self.calculateCostSubUpgrade()
		if freeSubUpgradesCount<1.0 then
			local baseCost = upgradesAvailable["upgrade"][1].cost*0.5
			local totalCost = isInXpMode and baseCost + (subUpgradeCountTotal*baseCost) or baseCost + (subUpgradeCount*baseCost)
			return totalCost-(totalCost*subUpgradeDiscount)--freeSubUpgrades is a discount value (sort of)
		end
		return 0
	end
	-- function:	getSubUpgradeCount
	-- purpose:
	function self.getSubUpgradeCount()
		return subUpgradeCountTotal
	end
	-- function:	getFreeSubUpgradeCounts
	-- purpose:
	function self.getFreeSubUpgradeCounts()
		return freeSubUpgradesCount
	end
	-- function:	addFreeSubUpgrade
	-- purpose:
	function self.addFreeSubUpgrade()
		freeSubUpgradesCount = math.max(freeSubUpgradesCount,0) + 1
	end
	-- function:	removeFreeSubUpgrade
	-- purpose:
	function self.removeFreeSubUpgrade()
		freeSubUpgradesCount = math.max(0,freeSubUpgradesCount - 1)
	end
	-- function:	setSubUpgradeDiscount
	-- purpose:		makes the next subUpgrade cheaper. 1.0==free upgrade, 0.0==full price
	function self.setSubUpgradeDiscount(amount)
		subUpgradeDiscount = amount
	end
	-- function:	setUpgradeDiscount
	-- purpose:		makes the next upgrade cheaper. 1.0==free upgrade, 0.0==full price
	function self.setUpgradeDiscount(discount)
		upgradeDiscount = discount
	end
	-- function:	add
	-- purpose:
	function self.add(stat, value)
		stats[stat] = stats[stat] or 0
		stats[stat] = stats[stat] + value
	end
	-- function:	mul
	-- purpose:
	function self.mul(stat, value)
		stats[stat] = stats[stat] or 0
		stats[stat] = stats[stat] * value
	end
	-- function:	getSisetUsedze
	-- purpose:
	function self.setUsed()
		if valueEfficiency>0.75 then
			valueEfficiency = 0.75
			billboard:setFloat("value", totalCost*valueEfficiency)
			comUnit:sendTo("stats","updateTowerValue","")
		end
	end
	-- function:	set
	-- purpose:
	function self.set(stat, value)
		stats[stat] = value
	end
	-- function:	func
	-- purpose:
	function self.func(stat, value)
		stats[stat] = value()
	end
	-- function:	setXpSystem
	-- purpose:		to set xp manager, to enable updates
	function self.setXpSystem(lXpSystem)
		xpSystem = lXpSystem
	end
	-- function:	update
	-- purpose:
	function self.update()
		for key, value in pairs(upgradesAvailable) do
			local level = 1--all cooldowns is on level 1 for simplicity
			if  value[level] then
				--the upgrades is active and waits to be degraded
				if value[level].isOnDuration and value[level].startTimerDuration then
					if (value[level].startTimerDuration+value[level].duration)<Core.getGameTime() then
						value[level].isOnDuration = false
						self.degrade(key)
						self.fixBillboardAndStats()
						return true--visual change
					end
				end
				--the upgrade waits to be available again
				if value[level].isOnCoolDown and value[level].startWaveCooldown then
					if (value[level].startWaveCooldown+value[level].cooldown)<=Core.getBillboard("stats"):getInt("wave") then
						value[level].isOnCoolDown = false
						self.fixBillboardAndStats()
						return false--no visiual change
					end
				end
			end
		end
		return false--no visiual change
	end
	return self
end