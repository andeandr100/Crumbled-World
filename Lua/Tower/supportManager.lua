require("Tower/TowerData.lua")

SupportManager = {}
function SupportManager.new()
	local self = {}
	local data		--upgrade = Upgrade.new()
	local comUnitTable
	local comUnit = Core.getComUnit()
	local onChangeCallback
	--
	local PERUNITDAMGINCPERLEVEL = 10
	local PERDAMGINCPERLEVEL = 0.10
	--
	local restartListenerSupport
	--
	local supportLevel = {}
	
	-- function:	fixLevel
	-- purpose:		To set the correct upgrade level for a specefic upgrade
	-- upg:			The name of the upgrade
	-- level:		What level is should have
--	local function fixLevel(upg,level)
--		local dCount = 0
--		while upgrade.getLevel(upg)~=level do
--			dCount = dCount + 1
--			if upgrade.getLevel(upg)>level then
--				upgrade.degrade(upg)
--			else
--				upgrade.upgrade(upg)
--			end
--			if dCount==5 then
--				error("Never ending loop detected in SupportManager.fixLevel("..tostring(upg)..", "..tostring(level)..")")
--			end
--		end
--	end
	-- function:	updateSupportUpgrades
	-- purpose: 	fix all level for all upgrades
	-- upg:			The name of the upgrade
	local function updateSupportUpgrades(upg)
		--support
		if supportLevel[upg] then
			local tab =  {}
			local maxLevel = 0
			for k,v in pairs(supportLevel[upg]) do
				if v>maxLevel then
					tab = {[1]=k}
					maxLevel = v
				elseif v==maxLevel then
					tab[#tab+1] = k
				end
			end
			data.setSupportUpgradeLevel(upg,maxLevel,tab)
		end
	end
	
	-- function:	handleSupportDamage
	-- purpose:		a help function for calculating who the damge should be attributed to
	-- upg:			The name of the upgrade
	-- damage:		The amount of damage dealt
	-- return:		The amount of damage the tower actual did by it self
--	function self.handleSupportDamage(damage)
--		local tab =  {}
--		if supportLevel["supportDamage"] then
--			local maxLevel = 0
--			for k,v in pairs(supportLevel["supportDamage"]) do
--				if v>maxLevel then
--					tab = {[1]=k}
--					maxLevel = v
--				elseif v==maxLevel then
--					tab[#tab+1] = k
--				end
--			end
--			--
--			local tDamage = damage*( 1.0/(1.0+(maxLevel*PERDAMGINCPERLEVEL)) )
--			local sDamage = damage*( (maxLevel*PERDAMGINCPERLEVEL)/(1.0+(maxLevel*PERDAMGINCPERLEVEL)) )
--			local size = #tab
--			for i=1, size do
--				comUnit:sendTo(tab[i],"dmgDealtFromSupportDamage",tostring(sDamage/size) )--dmgDealtMarkOfDeath only because it already does it, just wrong name
--			end
--			fixLevel("supportDamage",maxLevel)
--			return tDamage
--		end
--		return damage
--	end
	
	-- function:	handle
	-- purpose:		a help function for handleSupportRange, handleSupportDamage	
	-- upg:			The name of the upgrade
	-- param:		the level of the tower
	-- index:		what tower it is from
	local function handle(upg, param, index)
		local level = tonumber(param)
		supportLevel[upg] = supportLevel[upg] or {}
		supportLevel[upg][index] = level
		--fix level on all upgrades
		updateSupportUpgrades(upg)
	end
	-- function:	handleSupportRange
	-- purpose:		a support tower has been upgraded or sold
	-- param:		the level of the tower
	-- index:		what tower it is from
	local function handleSupportRange(param,index)
		handle("supportRange",param,index)
		if onChangeCallback then
			onChangeCallback()
		end
	end
	-- function:	handleSupportDamage
	-- purpose:		a support tower has been upgraded or sold
	-- param:		the level of the tower
	-- index:		what tower it is from
	local function handleSupportDamage(param,index)
		handle("supportDamage",param,index)
		if onChangeCallback then
			onChangeCallback()
		end
	end
	-- function:	handleSupportBoost
	-- purpose:		a support tower has been upgraded or sold
	-- param:		the level of the tower
	-- index:		what tower it is from
	local function handleSupportBoost(param,index)
--		if upgrade.getLevel("supportBoost")==0 then
--			upgrade.upgrade("supportBoost")
--		end
	end
	-- function:	setUpgrade
	-- purpose:		Sets the upgrade class, that will be used
	-- upg:			The class that will be used
	function self.setUpgrade(upg)
		data = upg
	end
	-- function:	addHiddenUpgrades
	-- purpose:		Add the hidden upgrades for the support tower to the upgrade list
	function self.addHiddenUpgrades()
--		restartListenerSupport = Listener("RestartWave")
--		restartListenerSupport:registerEvent("restartWave", self.waveRestart)
		--
		if not data then
			error("The setUpgrade must have been used")
		else
			--local function spportBoostDamage() return upgrade.getStats("damage")*(1.0+math.clamp(0.25+(waveCount/100),0.25,0.5)) end
			data.addSupportUpgrade({cost = {0,0,0},
									name = "supportRange",
									info = "support manager range",
									iconId = 65,
									level = 0,
									maxLevel = 3,
									stats = { range = { 1.1, 1.2, 1.3, func = data.mul }}
								})
								
			data.addSupportUpgrade({cost = {0,0,0},
									name = "supportDamage",
									info = "support manager damage",
									iconId = 64,
									level = 0,
									maxLevel = 3,
									stats = { damage = { 1.1, 1.2, 1.3, func = data.mul }}
								})					



--			upgrade.addUpgrade( {	cost = 0,
--								name = "supportBoost",
--								info = "support boost",
--								order = 9,
--								duration = 10,
--								cooldown = 0,
--								icon = 68,
--								hidden = true,
--								stats = {	damage =	{ upgrade.mul, 1.80, ""},
--											range =		{ upgrade.mul, 1.15 } }
--							} )
--			upgrade.addUpgrade( {	cost = 0,
--									name = "supportRange",
--									info = "support manager range",
--									icon = 65,
--									order = 7,
--									hidden = true,
--									value1 = 10,
--									stats = {	range = 	{ upgrade.mul, 1+(PERDAMGINCPERLEVEL*1) }}
--								} )
--			upgrade.addUpgrade( {	cost = 0,
--									name = "supportRange",
--									info = "support manager range",
--									icon = 65,
--									order = 7,
--									hidden = true,
--									value1 = 20,
--									stats = {	range = 	{ upgrade.mul, 1+(PERDAMGINCPERLEVEL*2) }}
--								} )
--			upgrade.addUpgrade( {	cost = 0,
--									name = "supportRange",
--									info = "support manager range",
--									icon = 65,
--									order = 7,
--									hidden = true,
--									value1 = 30,
--									stats = {	range = 	{ upgrade.mul, 1+(PERDAMGINCPERLEVEL*3) }}
--								} )
--			upgrade.addUpgrade( {	cost = 0,
--									name = "supportDamage",
--									info = "support manager damage",
--									icon = 64,
--									order = 8,
--									hidden = true,
--									value1 = 10,
--									stats = {	damage = 	{ upgrade.mul, 1+(PERDAMGINCPERLEVEL*1) }}
--								} )
--			upgrade.addUpgrade( {	cost = 0,
--									name = "supportDamage",
--									info = "support manager damage",
--									icon = 64,
--									order = 8,
--									hidden = true,
--									value1 = 20,
--									stats = {	damage = 	{ upgrade.mul, 1+(PERDAMGINCPERLEVEL*2) }}
--								} )
--			upgrade.addUpgrade( {	cost = 0,
--									name = "supportDamage",
--									info = "support manager damage",
--									icon = 64,
--									order = 8,
--									hidden = true,
--									value1 = 30,
--									stats = {	damage = 	{ upgrade.mul, 1+(PERDAMGINCPERLEVEL*3) }}
--								} )
		end
	end
	-- function:	setComUnitTable
	-- purpose:		Sets what comUnitTable will be used
	function self.setComUnitTable(pcomUnitTable)
		comUnitTable = pcomUnitTable
	end
	-- function:	addCallbacks
	-- purpose:		Adds all callbacks that will be used for the support tower
	function self.addCallbacks()
		comUnitTable["supportRange"] = handleSupportRange
		comUnitTable["supportDamage"] = handleSupportDamage
		comUnitTable["supportBoost"] = handleSupportBoost
	end
	function self.addSetCallbackOnChange(func)
		onChangeCallback = func
	end
	function self.restartWave()
		supportLevel = {}
	end
	return self
end