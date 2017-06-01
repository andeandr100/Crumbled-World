require("Game/particleEffect.lua")
--this = SceneNode()
XpSystem = {}
function XpSystem.new(upg)
	local self = {}
	local mapInfoBillboard = Core.getGlobalBillboard("MapInfo")
	--
	if  mapInfoBillboard:getString("GameMode")~="leveler" then
		return nil--most games will end the xp system here
	end
	--
	local bilboardStats = Core.getBillboard("stats")
	local xpLevel = 0--if upgrade==3 and we leveled up
	local xp = 0
	local xpToNextLevel = 100
	local xpCallback
	local xpNotPaid = 0.0
	local xpPerDamage = 1.0
	local xpForLevel = 1
	local xpForSubLevel = 1
	local currentWave = 0
	local xpBonusMul = 1.0
	local particleEffectUpgradeAvailable = ParticleSystem( ParticleEffect.upgradeAvailable )
	local SUBUPGRADE = 1
	local MAINUPGRADE = 2
	local whatIsLeveling = MAINUPGRADE
	--
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local upgCallback
	local upgrade = upg
	-- function:	xpSetSubupgradeDiscount
	-- purpose:		changes the discount for the subupgrades, so they can be bought cheaper
	local function xpSetSubupgradeDiscount(amount)
		upgrade.setUpgradeDiscount(0.0)
		upgrade.setSubUpgradeDiscount(amount)
		upgrade.fixBillboardAndStats()
	end
	-- function:	xpSetUpgradeDiscount
	-- purpose:		changes the discount for the main upgrade, so they can be bought cheaper
	local function xpSetUpgradeDiscount(amount)
		upgrade.setUpgradeDiscount(amount)
		upgrade.setSubUpgradeDiscount(0.0)
		upgrade.fixBillboardAndStats()
	end
	-- function:	updateXpBonus
	-- purpose:		updates how much xp the tower will recive from doing damage
	local function updateXpBonus()
		if xpForLevel==1 then
			xpBonusMul = 1.0 + (currentWave/6.0)
		elseif xpForLevel==2 then
			xpBonusMul = 1.0
		else
			xpBonusMul = 1.0 - math.min(0.7,(currentWave/30.0))	
		end
	end
	--
	--
	--
	-- function:	storeWaveChangeStats
	-- purpose:		store all data needed to restore the xpSystem to a previous state
	function self.storeWaveChangeStats()
		local tab = {
			xpLevel = xpLevel,
			xp = xp,
			xpNotPaid = xpNotPaid,
			xpPerDamage = xpPerDamage,
			xpForLevel = xpForLevel,
			xpForSubLevel = xpForSubLevel,
			particleEffectActive = particleEffectUpgradeAvailable:isActive(),
			whatIsLeveling = whatIsLeveling,
			--removes posability for sync issues
			xpBonusMul = xpBonusMul,
			xpToNextLevel = xpToNextLevel
		}
		return tab
	end
	-- function:	restoreWaveChangeStats
	-- purpose:		restore the cpSystem to a previous state, with data from self.storeWaveChangeStats()
	function self.restoreWaveChangeStats(tab)
		xpLevel = tab.xpLevel
		xp = tab.xp
		xpNotPaid = tab.xpNotPaid
		xpPerDamage = tab.xpPerDamage
		xpForLevel = tab.xpForLevel
		xpForSubLevel = tab.xpForSubLevel
		particleEffectActive = tab.particleEffectUpgradeAvailable:isActive()
		whatIsLeveling = tab.whatIsLeveling
		xpBonusMul = tab.xpBonusMul
		xpToNextLevel = tab.xpToNextLevel
		--fix callback
		if whatIsLeveling==SUBUPGRADE then
			xpCallback = nil
			billboard:setDouble("xpToNextLevel",xpToNextLevel)
		elseif whatIsLeveling==MAINUPGRADE then
			xpCallback = upgCallback
			billboard:setDouble("xpToNextLevel",xpToNextLevel)
		else
			billboard:setDouble("xpToNextLevel",xp)
			billboard:setDouble("xp",xp)
		end
	end
	--
	--
	--
	-- function:	setUpgradeCallback
	-- purpose:		sets the default callback function for MAINUPGRADE events
	function self.setUpgradeCallback(upgradeCallback)
		upgCallback = upgradeCallback
	end
	-- function:	updateXpToNextLevel
	-- purpose:		updated the xp for next level and keep check if upgraded from the outside
	function self.updateXpToNextLevel()
		if xp then
			local subUpGradesAvailable = upgrade.getSubUpgradeCount()+upgrade.getFreeSubUpgradeCounts()
			if xpForLevel~=upgrade.getLevel("upgrade") and whatIsLeveling==MAINUPGRADE then
				--tower has been upgraded
				xp = 0.0
			end
			if xpForSubLevel~=subUpGradesAvailable and whatIsLeveling==SUBUPGRADE then
				--tower has been sub upgraded
				xp = 0.0
			end
			if (upgrade.getLevel("upgrade")==2 and subUpGradesAvailable<1) or (upgrade.getLevel("upgrade")==3 and subUpGradesAvailable<3) then
				--next thing up is a subupgrade
				whatIsLeveling = SUBUPGRADE
				xpToNextLevel = upgrade.getNextPaidSubUpgradeCost()
				xpCallback = nil
				billboard:setDouble("xpToNextLevel",xpToNextLevel)
			elseif upgrade.getLevel("upgrade")<3 then
				--next up is a tower upgrade
				whatIsLeveling = MAINUPGRADE
				xpToNextLevel = upgrade.getNextUpgradeCost("upgrade")
				xpCallback = upgCallback
				billboard:setDouble("xpToNextLevel",xpToNextLevel)
			else
				--all leveling is done
				whatIsLeveling = 0
				xpToNextLevel = -1
				billboard:setDouble("xpToNextLevel",xp)
				billboard:setDouble("xp",xp)
			end
		end
	end
	-- function:	getLevelPercentDoneToNextLevel
	-- purpose:		returns how far gone the level is [0.0, 1.0]
	function self.getLevelPercentDoneToNextLevel()
		if whatIsLeveling==MAINUPGRADE and xpToNextLevel>=0 then
			return xp/xpToNextLevel
		else
			return 0.0
		end
	end
	-- function:	payStoredXp
	-- purpose:		pays the xp stored and removes it from the total hp stack
	function self.payStoredXp(waveChangedTo)
		if xpNotPaid>0.0 then
			if not waveChangedTo then
				comUnit:sendTo("stats","removeTotalHp",xpNotPaid/xpPerDamage)
			end
			if xpToNextLevel>0 then
				comUnit:sendTo("stats","removeWaveGold",xpNotPaid)
			end
			xpNotPaid = 0.0
		end
		if waveChangedTo then
			currentWave = waveChangedTo
		end
	end
	-- function:	addXp
	-- purpose:		manage when new xp has been added
	function self.addXp(amount)
		amount = amount * xpPerDamage
		xp = xp + amount
		xpNotPaid = xpNotPaid + amount
		if xpToNextLevel>0 then
			--can still level
			if xpNotPaid>1.0 then
				--the if statment is to minimize trafic
				if whatIsLeveling==SUBUPGRADE then
					xpSetSubupgradeDiscount(math.clamp(xp/xpToNextLevel,0.0,1.0))
				else
					xpSetUpgradeDiscount(math.clamp(xp/xpToNextLevel,0.0,1.0))
				end
				self.payStoredXp()
			end
			if xp>xpToNextLevel then
				xp = xp - xpToNextLevel
				xpForLevel = upgrade.getLevel("upgrade")+1
				if whatIsLeveling==SUBUPGRADE then
					upgrade.addFreeSubUpgrade()
				else
					xpCallback(tostring(xpForLevel))
				end
				xpSetUpgradeDiscount(0.0)
				self.updateXpToNextLevel()
				self.payStoredXp()
			end
		else
			--reached max level
			if xpNotPaid>10.0 then
				--the if statment is to minimize trafic
				self.payStoredXp()--this still removes hp from the pool and makes it easier for low dmg towers to earn
			end
			billboard:setDouble("xpToNextLevel",xp)
		end
		xpPerDamage = bilboardStats:getDouble("xpPerDamage")
		billboard:setDouble("xp",xp)
	end
	--
	--
	--
	-- function:	init
	-- purpose:		creates everything needed to run the xpSystem
	local function init()
		this:addChild(particleEffectUpgradeAvailable)
		self.addXp(0)
	end
	init()
	--
	--
	--
	-- function:	update
	-- purpose:		updates the the dynamic part of the xpSystem, like the particle effects
	function self.update()
		if upgrade.getFreeSubUpgradeCounts()>=1.0 then
			if particleEffectUpgradeAvailable:isActive()==false then
				particleEffectUpgradeAvailable:setSpawnRate(1.0)
				particleEffectUpgradeAvailable:activate(Vec3(0,1.5,0))
			end
		else
			if particleEffectUpgradeAvailable:isActive()==true then
				particleEffectUpgradeAvailable:setSpawnRate(0.0)
			end
		end
	end
	return self
end