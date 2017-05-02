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
	--
	local function xpSetSubupgradeDiscount(amount)
		upgrade.setUpgradeDiscount(0.0)
		upgrade.setSubUpgradeDiscount(amount)
		upgrade.fixBillboardAndStats()
	end
	local function xpSetUpgradeDiscount(amount)
		upgrade.setUpgradeDiscount(amount)
		upgrade.setSubUpgradeDiscount(0.0)
		upgrade.fixBillboardAndStats()
	end
	--
	--
	--
	function self.setUpgradeCallback(upgradeCallback)
		upgCallback = upgradeCallback
	end
	function self.hasBeenUpgraded()
		xpForLevel = upgrade.getLevel("upgrade")
		xp = 0.0
		billboard:setDouble("xpToNextLevel",xp)
		billboard:setDouble("xp",xp)
	end
	function self.hasBeenSubUpgraded()
		xpForSubLevel = upgrade.getSubUpgradeCount()+upgrade.getFreeSubUpgradeCounts()
		xp = 0.0
		billboard:setDouble("xpToNextLevel",xp)
		billboard:setDouble("xp",xp)
	end
	--updated the xp for next level and keep check if upgraded from the outside
	function self.updateXpToNextLevel()
		if xp then
			local subUpGradesGained = upgrade.getSubUpgradeCount()+upgrade.getFreeSubUpgradeCounts()
			if xpForLevel~=upgrade.getLevel("upgrade") then
				--tower has been upgraded
				self.hasBeenUpgraded()
			end
			if xpForSubLevel~=subUpGradesGained then
				--tower has been sub upgraded
				self.hasBeenSubUpgraded()
			end
			if (upgrade.getLevel("upgrade")==2 and subUpGradesGained<1) or (upgrade.getLevel("upgrade")==3 and subUpGradesGained<3) then
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
	function self.getLevelPercentDoneToNextLevel()
		if xpToNextLevel>=0 then
			return xp/xpToNextLevel
		else
			return 0.0
		end
	end
	local function updateXpBonus()
		if xpForLevel==1 then
			xpBonusMul = 1.0 + (currentWave/6.0)
		elseif xpForLevel==2 then
			xpBonusMul = 1.0
		else
			xpBonusMul = 1.0 - math.min(0.7,(currentWave/30.0))	
		end
	end
	--removed the xp and gold from the wave stack, and manages all the communications
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
	--manage when new xp has been added
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
				xpForLevel = upgrade.getLevel("upgrade")
				if whatIsLeveling==SUBUPGRADE then
					upgrade.addFreeSubUpgrade()
				else
					xpCallback(tostring(upgrade.getLevel("upgrade")+1))
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
	local function init()
		this:addChild(particleEffectUpgradeAvailable)
		self.addXp(0)
	end
	init()
	--
	--
	--
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