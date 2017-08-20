require("Tower/upgrade.lua")
require("Tower/xpSystem.lua")
require("Tower/supportManager.lua")
require("stats.lua")
require("Projectile/projectileManager.lua")
require("Projectile/missile.lua")
require("Game/campaignTowerUpg.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
--this = SceneNode()
MissileTower = {}
function MissileTower.new()
	local self = {}
	local level = 0	--upgradedLevel
	local missile = {}
	local missilesAvailable = 0
	local missileToFireNext = 1
	local missilesInTheAir = false
	local reloadTimeLeft = 0.0
	local targetHistory = {}
	local targetHistoryCount = 0
	
	local waveCount = 0
	local myStats = {}
	local myStatsTimer = 0.0
	local myStatDamageTimer = 0.0
	local projectiles = projectileManager.new()
	local tStats = Stats.new()
	local cData = CampaignData.new()
	local upgrade = Upgrade.new()
	local supportManager = SupportManager.new()
	local cTowerUpg = CampaignTowerUpg.new("Tower/missileTower.lua",upgrade)
	--XP
	local xpManager = XpSystem.new(upgrade)
	--model
	local model
	local activeRangeMesh
	--attack
	local targetMode = 1
	local boostedOnLevel = 0
	--communication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local billboardWaveStats
	--Events
	--other
	local lastRestored = -1
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	--local soulManager
	--local targetingSystem
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	--stats
	local mapName = MapInfo.new().getMapName()
	
	local function storeWaveChangeStats( waveStr )
		if isThisReal then
			billboardWaveStats = billboardWaveStats or Core.getGameSessionBillboard( "tower_"..Core.getNetworkName() )
			--update wave stats only if it has not been set (this function will be called on wave changes when going back in time)
			if billboardWaveStats:exist( waveStr )==false then
				local tab = {
					xpTab = xpManager and xpManager.storeWaveChangeStats() or nil,
					upgradeTab = upgrade.storeWaveChangeStats(),
					DamagePreviousWave = billboard:getDouble("DamagePreviousWave"),
					DamagePreviousWavePassive = billboard:getDouble("DamagePreviousWavePassive"),
					DamageTotal = billboard:getDouble("DamageTotal"),
					currentTargetMode = billboard:getInt("currentTargetMode"),
					reloadTimeLeft = reloadTimeLeft,
					missilesAvailable = missilesAvailable,
					missileToFireNext = missileToFireNext,
					missile = {},
					boostedOnLevel = boostedOnLevel,
					boostLevel = upgrade.getLevel("boost"),
					upgradeLevel = upgrade.getLevel("upgrade"),
					rangeLevel = upgrade.getLevel("range"),
					BlasterLevel = upgrade.getLevel("Blaster"),
					fuelLevel = upgrade.getLevel("fuel"),
					shieldSmasherLevel = upgrade.getLevel("shieldSmasher")
				}
				--parse all missiles
				for i = 1, 2+level, 1 do
					tab.missile[i] = {}
					tab.missile[i].state = missile[i].state
					tab.missile[i].timer = missile[i].timer
					tab.missile[i].replaceTime = missile[i].replaceTime
					tab.missile[i].missilePosition = missile[i].missilePosition
					tab.missile[i].localPosition = missile[i].missile:getLocalPosition()
					tab.missile[i].visible = missile[i].missile:getVisible()
					tab.missile[i].hatch1Matrix = missile[i].hatch1:getLocalMatrix()
					tab.missile[i].hatch2Matrix = missile[i].hatch2:getLocalMatrix()
				end
				billboardWaveStats:setTable( waveStr, tab )
			end
		end
	end
	local function doDegrade(fromLevel,toLevel,callback)
		while fromLevel>toLevel do
			fromLevel = fromLevel - 1
			callback(fromLevel)
		end
	end
	local function restoreWaveChangeStats( wave )
		if isThisReal and wave>0 then
			billboardWaveStats = billboardWaveStats or Core.getGameSessionBillboard( "tower_"..Core.getNetworkName() )
			lastRestored = wave
			--we have gone back in time erase all tables that is from the future, that can never be used
			local index = wave+1
			while billboardWaveStats:exist( tostring(index) ) do
				billboardWaveStats:erase( tostring(index) )
				index = index + 1
			end
			--restore the stats from the wave
			local tab = billboardWaveStats:getTable( tostring(wave) )
			if tab then
				if xpManager then
					xpManager.restoreWaveChangeStats(tab.xpTab)
				end
				--
				if upgrade.getLevel("boost")~=tab.boostLevel then self.handleBoost(tab.boostLevel) end
				doDegrade(upgrade.getLevel("range"),tab.rangeLevel,self.handleRange)
				doDegrade(upgrade.getLevel("Blaster"),tab.BlasterLevel,self.handleBlaster)
				doDegrade(upgrade.getLevel("fuel"),tab.fuelLevel,self.handleFuel)
				doDegrade(upgrade.getLevel("shieldSmasher"),tab.shieldSmasherLevel,self.handleShieldSmasher)
				doDegrade(upgrade.getLevel("upgrade"),tab.upgradeLevel,self.handleUpgrade)--main upgrade last as the assets might not be available for higer levels
				--
				upgrade.restoreWaveChangeStats(tab.upgradeTab)
				--
				billboard:setDouble("DamagePreviousWave", tab.DamagePreviousWave)
				billboard:setDouble("DamageCurrentWave", tab.DamagePreviousWave)
				billboard:setDouble("DamagePreviousWavePassive", tab.DamagePreviousWavePassive)
				billboard:setDouble("DamageTotal", tab.DamageTotal)
				self.SetTargetMode(tab.currentTargetMode)
				reloadTimeLeft = tab.reloadTimeLeft
				missilesAvailable = tab.missilesAvailable
				missileToFireNext = tab.missileToFireNext
				missilesInTheAir = false
				--parse all missiles
				for i = 1, 2+level, 1 do
					missile[i].state = tab.missile[i].state
					missile[i].timer = tab.missile[i].timer
					missile[i].replaceTime = tab.missile[i].replaceTime
					missile[i].missilePosition = tab.missile[i].missilePosition
					missile[i].missile:setLocalPosition(tab.missile[i].localPosition)
					missile[i].missile:setVisible(tab.missile[i].visible)
					missile[i].hatch1:setLocalMatrix(tab.missile[i].hatch1Matrix)
					missile[i].hatch2:setLocalMatrix(tab.missile[i].hatch2Matrix)
				end
			end
		end
	end
	
	local function reloadMissiles()
		reloadTimeLeft = reloadTimeLeft - Core.getDeltaTime()
		local doorOpenAngle = math.pi*0.50
		for i = 1, 2+level, 1 do
			missile[i].timer = missile[i].timer + Core.getDeltaTime()
			if missile[i].timer<0.0 then missile[i].timer=0.0 end
			local per = missile[i].timer/missile[i].replaceTime
			local perInc = Core.getDeltaTime()/missile[i].replaceTime
			if missile[i].state==4 then--close the hatches
				if per>0.4 then
					missile[i].state = 0
					missile[i].hatch1:setLocalMatrix( missile[i].hatch1matrix )
					missile[i].hatch2:setLocalMatrix( missile[i].hatch2matrix )
				else
					if per==perInc then 
						missile[i].missile:setLocalPosition( missile[i].missilePosition )
						missile[i].missile:setVisible(false) 
					end
					perInc = perInc * (1.0/0.4)
					missile[i].hatch1:rotate(Vec3(0,1,0),(-doorOpenAngle)*perInc)
					missile[i].hatch2:rotate(Vec3(0,1,0),(-doorOpenAngle)*perInc)
				end
			end
			if missile[i].state<3 then
				if missile[i].state==0 then--just wait
					if per>0.5 then 
						missile[i].state = 1
						perInc = per-0.5
						missile[i].missile:setVisible(true)
					end
				end
				if missile[i].state==1 then--open the hatches
					local perChange = perInc
					if per>0.9 then
						missile[i].state = 2
						perChange = perInc - (per-0.9)
						perInc = perInc-0.9
					end
					perChange = perChange * (1.0/0.4)
					missile[i].hatch1:rotate(Vec3(0,1,0),doorOpenAngle*perChange)
					missile[i].hatch2:rotate(Vec3(0,1,0),doorOpenAngle*perChange)
				end
				if per>0.70 then--raise the missile
					if per>1.0 then
						missile[i].state = 3
						missilesAvailable = missilesAvailable + 1
						per = 1.0
					end
					per = (per-0.70)/0.3
					missile[i].missile:setLocalPosition( (missile[i].missilePosition + Vec3(0,0.3*per,0.0)) )
				end
			end
		end
	end
	local function updateStats()
		targetSelector.setRange(upgrade.getValue("range"))
	end
	local function setCurrentInfo()
		if xpManager then
			xpManager.updateXpToNextLevel()
		end
		if myStats.activeTimer and myStats.activeTimer>0.01 then
			myStats.disqualified = true
		end
		missilesAvailable = 0
		for i = 1, 2+level, 1 do
			missile[i] = missile[i] or {}
			missile[i].timer = upgrade.getValue("replaceTime")
			missile[i].replaceTime = upgrade.getValue("replaceTime")
			missile[i].missile = model:getMesh( "missile"..i )
			missile[i].hatch1 = model:getMesh( "hatch"..(i*10+1) )
			missile[i].hatch2 = model:getMesh( "hatch"..(i*10+2) )
			missile[i].hatch1:setLocalMatrix( missile[i].hatch1matrix )
			missile[i].hatch2:setLocalMatrix( missile[i].hatch2matrix )
			missile[i].state = 0
		end
		updateStats()
		billboard:setInt("FirestormLevel",upgrade.getLevel("fuel"))
		reloadMissiles()
		--achievment
		if upgrade.getLevel("upgrade")==3 and upgrade.getLevel("range")==3 and upgrade.getLevel("shieldSmasher")==1 and upgrade.getLevel("fuel")==3 and upgrade.getLevel("Blaster")==3 then
			comUnit:sendTo("SteamAchievement","MissileMaxed","")
		end
	end
	function restartWave(param)
		projectiles.clear()
		supportManager.restartWave()
		restoreWaveChangeStats( tonumber(param) )
	end
	local function doMeshUpgradeForLevel(name,meshName)
		model:getMesh(meshName..upgrade.getLevel(name)):setVisible(true)
		if upgrade.getLevel(name)>1 then
			model:getMesh(meshName..(upgrade.getLevel(name)-1)):setVisible(false)
		end
	end
	local function initModel()
		level = upgrade.getLevel("upgrade")
		for index =1, 3, 1 do
			model:getMesh( "range"..index ):setVisible(upgrade.getLevel("range")==index)
			model:getMesh( "pipe"..index ):setVisible(upgrade.getLevel("fuel")==index)
		end
		model:getMesh( "physic" ):setVisible(false)
		model:getMesh( "hull" ):setVisible(false)
		model:getMesh( "boost" ):setVisible(upgrade.getLevel("boost")==1)
		model:getMesh( "masterAim1" ):setVisible(false)
		if upgrade.getLevel("range")>0 then
			activeRangeMesh = model:getMesh( "range"..upgrade.getLevel("range") )
		end
		for i = 1, 2+level, 1 do
			missile[i] = missile[i] or {}
			missile[i].missilePosition = model:getMesh( "missile"..i ):getLocalPosition()
			missile[i].hatch1matrix = model:getMesh( "hatch"..(i*10+1) ):getLocalMatrix()
			missile[i].hatch2matrix = model:getMesh( "hatch"..(i*10+2) ):getLocalMatrix()
		end
		if level>1 then
			model:getMesh( "antenna1" ):setVisible( false )
			if level>2 then
				model:getMesh( "antenna2" ):setVisible( false )
			end
		end
		--performance check
		for i=0, model:getNumMesh()-1, 1 do
			if not model:getMesh(i):getName():toString()=="tower" then
				model:getMesh(i):DisableBoundingVolumesDynamicUpdates()
			end
		end
	end
	function self.handleUpgrade(param)
		if tonumber(param)>upgrade.getLevel("upgrade") then
			upgrade.upgrade("upgrade")
		elseif upgrade.getLevel("upgrade")>tonumber(param) then
			upgrade.degrade("upgrade")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() and Core.getNetworkName():len()>0 then
			comUnit:sendNetworkSyncSafe("upgrade1",tostring(param))
		end
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		--Achievements
		local level = upgrade.getLevel("upgrade")
		comUnit:sendTo("stats","addBillboardInt","level"..level..";1")
		if upgrade.getLevel("upgrade")==3 then
			comUnit:sendTo("SteamAchievement","Upgrader","")
		end
		--
		if not xpManager or upgrade.getLevel("upgrade")==1 or upgrade.getLevel("upgrade")==2 or upgrade.getLevel("upgrade")==3 then
			this:removeChild(model)
			model = Core.getModel( upgrade.getValue("model") )
			this:addChild(model)
			initModel()
		end
		upgrade.clearCooldown()
		cTowerUpg.fixAllPermBoughtUpgrades()
		setCurrentInfo()
	end
	function self.handleBoost(param)
		if tonumber(param)>upgrade.getLevel("boost") then
			if Core.isInMultiplayer() then
				comUnit:sendNetworkSyncSafe("upgrade2","1")
			end
			boostedOnLevel = upgrade.getLevel("upgrade")
			upgrade.upgrade("boost")
			model:getMesh( "boost" ):setVisible(true)
			setCurrentInfo()
			--Achievement
			comUnit:sendTo("SteamAchievement","Boost","")
		elseif upgrade.getLevel("boost")>tonumber(param) then
			upgrade.degrade("boost")
			model:getMesh("boost"):setVisible( false )
			setCurrentInfo()
			--clear coldown info for boost upgrade
			upgrade.clearCooldown()
		else
			return--level unchanged
		end
	end
	function self.handleFuel(param)
		if tonumber(param)>upgrade.getLevel("fuel") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("fuel")
		elseif upgrade.getLevel("fuel")>tonumber(param) then
			model:getMesh("pipe"..upgrade.getLevel("fuel")):setVisible(false)
			upgrade.degrade("fuel")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade5",tostring(param))
		end
		if upgrade.getLevel("fuel")>0 then
			doMeshUpgradeForLevel("fuel","pipe")
			--Acievement
			if upgrade.getLevel("fuel")==3 then
				comUnit:sendTo("SteamAchievement","FireStorm","")
			end
		end
		setCurrentInfo()
	end
	function self.handleRange(param)
		if tonumber(param)>upgrade.getLevel("range") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("range")
		elseif upgrade.getLevel("range")>tonumber(param) then
			--model:getMesh("???"..upgrade.getLevel("range")):setVisible(false)
			upgrade.degrade("range")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade3",tostring(param))
		end
		if upgrade.getLevel("range")>0 then
			--Acievement
			if upgrade.getLevel("range")==3 then
				comUnit:sendTo("SteamAchievement","Range","")
			end
		end
		setCurrentInfo()
	end
	function self.handleBlaster(param)
		if tonumber(param)>upgrade.getLevel("Blaster") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("Blaster")
		elseif upgrade.getLevel("Blaster")>tonumber(param) then
			--model:getMesh("???"..upgrade.getLevel("Blaster")):setVisible(false)
			upgrade.degrade("Blaster")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade4",tostring(param))
		end
		if upgrade.getLevel("Blaster")>0 then
			--Acievement
			if upgrade.getLevel("Blaster")==3 then
				comUnit:sendTo("SteamAchievement","Blaster","")
			end
		end
		setCurrentInfo()
	end
	function self.handleShieldSmasher(param)
		if tonumber(param)>upgrade.getLevel("shieldSmasher") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("shieldSmasher")
		elseif upgrade.getLevel("shieldSmasher")>tonumber(param) then
			--model:getMesh("???"..upgrade.getLevel("shieldSmasher")):setVisible(false)
			upgrade.degrade("shieldSmasher")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade6",tostring(param))
		end
		if upgrade.getLevel("shieldSmasher")>0 then
			comUnit:sendTo("SteamAchievement","forcefieldSmasher","")
		end
		setCurrentInfo()
	end
	
	function self.destroy()
		projectiles.destroy()
	end
	local function myStatsReset()
		if myStats.dmgDone then
			billboard:setDouble("DamagePreviousWave",myStats.dmgDone)
			comUnit:sendTo("stats", "addTotalDmg", myStats.dmgDone )
		end
		myStats = {	activeTimer=0.0,	
					dmgDone=0.01,
					unitsHitt=0,
					uniqueHitts=0,
					missileLaunched=0,
					disqualified=false}
		myStatsTimer = Core.getGameTime()
	end
	local function damageDealt(param)
		local addDmg = supportManager.handleSupportDamage( tonumber(param) )
		if Core.getGameTime()-myStatDamageTimer<0.25 then
			myStatDamageTimer = Core.getGameTime()
			myStats.uniqueHitts = myStats.uniqueHitts + 1
		end
		myStats.dmgDone = myStats.dmgDone + addDmg
		myStats.unitsHitt = myStats.unitsHitt + 1
		billboard:setDouble("DamageCurrentWave",myStats.dmgDone)
		billboard:setDouble("DamageTotal",billboard:getDouble("DamagePreviousWave")+myStats.dmgDone)
		if xpManager then
			xpManager.addXp(addDmg)
			local interpolation  = xpManager.getLevelPercentDoneToNextLevel()
			upgrade.setInterpolation(interpolation)
			upgrade.fixBillboardAndStats()
		end
	end
	local function waveChanged(param)
		local name
		local waveCount
		name,waveCount = string.match(param, "(.*);(.*)")
		--update and save stats only if we did not just restore this wave
		if tonumber(waveCount)>=lastRestored then
			if not xpManager then
				--
				if myStats.disqualified==false and upgrade.getLevel("boost")==0 and Core.getGameTime()-myStatsTimer>0.25 and myStats.activeTimer>1.0 then
					myStats.disqualified=nil
					myStats.DPS = myStats.dmgDone/myStats.activeTimer
					myStats.DPSpG = myStats.DPS/upgrade.getTotalCost()
					myStats.DPG = myStats.dmgDone/upgrade.getTotalCost()
					local key = "blaster"..upgrade.getLevel("Blaster").."_fuel"..upgrade.getLevel("fuel").."_shieldSmasher"..upgrade.getLevel("shieldSmasher").."_range"..upgrade.getLevel("range")
					tStats.addValue({mapName,"wave"..name,"missileTower_l"..upgrade.getLevel("upgrade"),key,"sampleSize"},1)
					for variable, value in pairs(myStats) do
						tStats.setValue({mapName,"wave"..name,"missileTower_l"..level,key,variable},value)
					end
				end
				myStatsReset()
			else
				xpManager.payStoredXp(waveCount)
				--update billboard
				upgrade.fixBillboardAndStats()
			end
			--store wave info to be able to restore it
			storeWaveChangeStats( tostring(tonumber(waveCount)+1) )
		end
	end
	function self.SetTargetMode(param)
		targetMode = math.clamp(tonumber(param),1,6)
		billboard:setInt("currentTargetMode",targetMode)
		if billboard:getBool("isNetOwner") and Core.isInMultiplayer() then
			comUnit:sendNetworkSync("SetTargetMode", tostring(param) )
		end
	end
	local function updateTarget()
		if targetSelector.isTargetAvailable()==false then -- or rotator:isAtHorizontalLimit() then
			targetSelector.selectAllInRange()
			targetSelector.filterOutState(state.ignore)
			targetSelector.scoreState(state.highPriority,25)
			if targetMode==1 then
				--density
				targetSelector.scoreDensity(30)
				targetSelector.scoreClosestToExit(15)
				targetSelector.scoreRandom(20)			--so we don't shoot the exakt same target with every missile
				targetSelector.selectTargetAfterMaxScore()
			elseif targetMode==2 then
				--varied targeting
				targetSelector.scoreSelectedTargets( targetHistory, -25 )
				targetSelector.scoreClosestToExit(15)
				if missileToFireNext==1 then
					targetSelector.selectTargetAfterMaxScorePer(-1.0,0.9)
				elseif missileToFireNext==2 then
					targetSelector.selectTargetAfterMaxScorePer(-1.0,0.5)
				elseif missileToFireNext==3 then
					targetSelector.selectTargetAfterMaxScorePer(-1.0,0.1)
				elseif missileToFireNext==4 then
					targetSelector.selectTargetAfterMaxScorePer(-1.0,0.7)
				elseif missileToFireNext==5 then
					targetSelector.selectTargetAfterMaxScorePer(-1.0,0.3)
				end
				if targetSelector.isAnyInRange() and targetSelector.getTarget()==0 then
					targetSelector.selectTargetAfterMaxScore()
				end
			elseif targetMode==3 then
				--priority
				targetSelector.scoreSelectedTargets( targetHistory, -10 )
				targetSelector.scoreDensity(15)
				targetSelector.scoreClosestToExit(10)
				targetSelector.scoreName("reaper",25)
				if upgrade.getLevel("shieldSmasher")>0 then
					targetSelector.scoreName("turtle",40)
				end
				targetSelector.selectTargetAfterMaxScore()
			elseif targetMode==4 then
				--closest to exit
				targetSelector.scoreDensity(20)
				targetSelector.scoreClosestToExit(25)
				targetSelector.scoreRandom(10)
				targetSelector.scoreSelectedTargets( targetHistory, -10 )
				targetSelector.selectTargetAfterMaxScore()
			elseif targetMode==5 then
				--attackWeakestTarget
				targetSelector.scoreHP(-30)
				targetSelector.scoreSelectedTargets( targetHistory, -10 )
				targetSelector.scoreDensity(10)
				targetSelector.scoreClosestToExit(10)
				targetSelector.selectTargetAfterMaxScore()
			elseif targetMode==6 then
				--attackStrongestTarget
				targetSelector.scoreHP(30)
				targetSelector.scoreSelectedTargets( targetHistory, -10 )
				targetSelector.scoreDensity(10)
				targetSelector.scoreClosestToExit(10)
				targetSelector.selectTargetAfterMaxScore()
			end
		end
		return (targetSelector.getTarget()>0)
	end
	local function NetLaunchMissile(param)
		local tab = totable(param)
		local target = tonumber(Core.getIndexOfNetworkName(tab.tName))
		--Core.launchProjectile(this, "missile",target)
		projectiles.launch(Missile,{target=target,startPos=model:getMesh( "missile"..tab.mToFire ):getGlobalPosition(),targetPos=tab.tPos,missileIndex=tab.mToFire})
		targetSelector.deselect()
		missile[missileToFireNext].timer = 0
		missile[missileToFireNext].state = 4
		--missile[missileToFireNext].missile:setVisible(false)
		missileToFireNext = (missileToFireNext==2+level) and 1 or missileToFireNext + 1
		missilesAvailable = missilesAvailable - 1
	end
	local function attack()
		local target = targetSelector.getTargetIfAvailable()
		if target>0 then
			local targetPos = targetSelector.getTargetPosition(target)
			reloadTimeLeft = reloadTimeLeft+Core.getDeltaTime()>0 and reloadTimeLeft+upgrade.getValue("fieringTime") or upgrade.getValue("fieringTime")
			targetHistoryCount = targetHistoryCount + 1
			if targetHistoryCount<2+level then
				targetHistory[targetHistoryCount] = target
			else
				targetHistoryCount = 0
				targetHistory = {}
			end
			local counter=1
			while missile[missileToFireNext].state~=3 and counter<2+level do
				counter = counter + 1
				missileToFireNext = (missileToFireNext==2+level) and 1 or missileToFireNext + 1
			end
			if missile[missileToFireNext].state==3 then
				billboard:setVec3("bulletStartPos",model:getMesh( "missile"..missileToFireNext ):getGlobalPosition() )
				if Core.isInMultiplayer()==false or billboard:getBool("isNetOwner")==true then
					--Core.launchProjectile(this, "missile",target)
					--local soulMangerBillboard = Core.getBillboard("SoulManager")
					--targetSelector.debug()
					projectiles.launch(Missile,{target=target,startPos=model:getMesh( "missile"..missileToFireNext ):getGlobalPosition(),targetPos=targetPos,missileIndex=missileToFireNext})
					targetSelector.deselect()
					missile[missileToFireNext].timer = 0
					missile[missileToFireNext].state = 4
					--missile[missileToFireNext].missile:setVisible(false)
					missileToFireNext = (missileToFireNext==2+level) and 1 or missileToFireNext + 1
					missilesAvailable = missilesAvailable - 1
				end
			end
			myStats.missileLaunched = myStats.missileLaunched + 1
		end
	end
	--
	function self.update()
		comUnit:setPos(this:getGlobalPosition())
		if upgrade.update() then
			myStats.disqualified = true
			model:getMesh("boost"):setVisible( false )
			setCurrentInfo()
			--if the tower was upgraded while boosted, then the boost should be available
			if boostedOnLevel~=upgrade.getLevel("upgrade") then
				upgrade.clearCooldown()
			end
		end
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		if xpManager then
			xpManager.update()
		end
		reloadMissiles()
		--
		--debug
		--
		if targetSelector.isAnyInRange() then
			myStats.activeTimer = myStats.activeTimer + Core.getDeltaTime()
		end
		--
		--debug
		--
		if missilesAvailable>0 and reloadTimeLeft<0 and updateTarget() then
			attack()
			upgrade.setUsed()--set value changed
		end
		if projectiles.update() then
			if missilesInTheAir==false then
				Core.setUpdateHz(60.0)
				missilesInTheAir = true
			end
		elseif missilesInTheAir==true then
			Core.setUpdateHz(24.0)
			missilesInTheAir = false
		end
		
		if activeRangeMesh then
			activeRangeMesh:rotate(Vec3(0,0,1),Core.getDeltaTime()*0.15)
		end
	
		--model:render()
		return true
	end
	--
	local function setNetOwner(param)
		if param=="YES" then
			billboard:setBool("isNetOwner",true)
		else
			billboard:setBool("isNetOwner",false)
		end
		upgrade.fixBillboardAndStats()
	end
	--
	local function init()
		this:createBoundVolumeGroup()
		this:setBoundingVolumeCanShrink(false)
		if particleEffectUpgradeAvailable then
			this:addChild(particleEffectUpgradeAvailable)
		end
		
		Core.setUpdateHz(24.0)--slow gates and a slow rise of an missile
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end

		restartListener = Listener("RestartWave")
		restartListener:registerEvent("restartWave", restartWave)
		--
		if xpManager then
			xpManager.setUpgradeCallback(self.handleUpgrade)
		end
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug for stats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
		
		billboard:setDouble("rangePerUpgrade",1.0)
		upgrade.setBillboard(billboard)
		upgrade.addDisplayStats("dmg")
		upgrade.addDisplayStats("RPS")
		upgrade.addDisplayStats("range")
		upgrade.addDisplayStats("dmg_range")
		upgrade.addBillboardStats("missileSpeed")
		upgrade.addBillboardStats("missileSpeedAcc")
		upgrade.addBillboardStats("weaken")
		upgrade.addBillboardStats("weakenTimer")
		upgrade.addBillboardStats("fireDPS")
		upgrade.addBillboardStats("burnTime")
		upgrade.addBillboardStats("slow")
		upgrade.addBillboardStats("shieldDamageMul")
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Missile tower")
		billboard:setString("FileName", "Tower/missileTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		
		
		--upgrade
		upgrade.addUpgrade( {	cost = 200,
								name = "upgrade",
								info = "missile tower level",
								order = 1,
								icon = 56,
								value1 = 1,
								stats = {range =		{ upgrade.add, 7.0},
										dmg = 			{ upgrade.add, 270},
										RPS = 			{ upgrade.add, 3.0/12.0,},
										replaceTime =	{ upgrade.add, 12},
										fieringTime =	{ upgrade.add, 1.25},
										dmg_range =		{ upgrade.add, 1.5},
										missileSpeed =	{ upgrade.add, 7.0},
										missileSpeedAcc={ upgrade.add, 4.5},
										shieldDamageMul={ upgrade.add, 1.0},
										model =			{ upgrade.set, "tower_missile_l1.mym"} }
							} )
		--AUH == Average Units Hitts
		--DPSpG == dmg*AUH*RPS*(Diameter/2+2.5)*0.111/cost == 310*(1.5*1.6)*(3/12)/200 == 0.93
		upgrade.addUpgrade( {	cost = 400,
								name = "upgrade",
								info = "missile tower level",
								order = 1,
								icon = 56,
								value1 = 2,
								stats = {range =		{ upgrade.add, 7.0},
										dmg = 			{ upgrade.add, 570},
										RPS = 			{ upgrade.add, 4.0/12.0,},
										replaceTime =	{ upgrade.add, 12},
										fieringTime =	{ upgrade.add, 1.25},
										dmg_range =		{ upgrade.add, 1.75},
										missileSpeed =	{ upgrade.add, 7.0},
										missileSpeedAcc={ upgrade.add, 4.5},
										shieldDamageMul={ upgrade.add, 1.0},
										model =			{ upgrade.set, "tower_missile_l2.mym"} }
							},0 )
		--AUH == Average Units Hitts == (1.75*1.6) == 2.8	(wave11-15==2.95)(wave16-20==3.85)
		--DPSpG == dmg*AUH*RPS*(Diameter/2+2.5)*0.111/cost == 630*(1.75*1.6)*(4/12)/600 == 0.98
		upgrade.addUpgrade( {	cost = 800,
								name = "upgrade",
								info = "missile tower level",
								order = 1,
								icon = 56,
								value1 = 3,
								stats = {range =		{ upgrade.add, 7.0},
										dmg = 			{ upgrade.add, 980},
										RPS = 			{ upgrade.add, 5.0/12.0,},
										replaceTime =	{ upgrade.add, 12},
										fieringTime =	{ upgrade.add, 1.25},
										dmg_range =		{ upgrade.add, 2.0},
										missileSpeed =	{ upgrade.add, 7.0},
										missileSpeedAcc={ upgrade.add, 4.5},
										shieldDamageMul={ upgrade.add, 1.0},
										model =			{ upgrade.set, "tower_missile_l3.mym"} }
							},0 )
		--AUH == Average Units Hitts == (2.0*1.6) == 3.2
		--DPSpG == dmg*AUH*RPS*(Diameter/2+2.5)*0.111/cost == 1080*(2.0*1.6)*(5/12)/1400 == 1.03
		--boost
		function boostDamage() return upgrade.getStats("dmg")*2.5*(waveCount/25+1.0) end
		--(total)	0=2x	25=4x	50=6x
		upgrade.addUpgrade( {	cost = 0,
								name = "boost",
								info = "missile tower boost",
								order = 10,
								duration = 10,
								cooldown = 3,
								icon = 57,
								stats = {range = 		{ upgrade.add, 1.0},
										dmg =		{ upgrade.func, boostDamage},
										dmg_range ={ upgrade.mul, 1.25},
										missileSpeedAcc={ upgrade.mul, 1.25},
										fieringTime =	{ upgrade.add, -0.25},
										replaceTime =	{ upgrade.mul, 0.5} }
							} )
		-- RANGE
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 0 or 100,
								name = "range",
								info = "missile tower range",
								order = 2,
								icon = 59,
								value1 = 7 + 1,
								levelRequirement = cTowerUpg.getLevelRequierment("range",1),
								stats = {range = 		{ upgrade.add, 1.0}}
							} )
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 100 or 200,
								name = "range",
								info = "missile tower range",
								order = 2,
								icon = 59,
								value1 = 7 + 2,
								levelRequirement = cTowerUpg.getLevelRequierment("range",2),
								stats = {range = 		{ upgrade.add, 2.0}}
							} )
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 200 or 300,
								name = "range",
								info = "missile tower range",
								order = 2,
								icon = 59,
								value1 = 7 + 3,
								levelRequirement = cTowerUpg.getLevelRequierment("range",3),
								stats = {range = 		{ upgrade.add, 3.0}}
							} )
		-- MARK OF DEATH (amplified by other towers, increases damage take to target with 5% every upgrade)
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "Blaster",
								info = "missile tower explosion",
								order = 3,
								icon = 39,
								value1 = 8,
								levelRequirement = cTowerUpg.getLevelRequierment("Blaster",1),
								stats ={dmg =		{ upgrade.mul, 1.08},
										dmg_range= { upgrade.mul, 1.08} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "Blaster",
								info = "missile tower explosion",
								order = 3,
								icon = 39,
								value1 = 16,
								levelRequirement = cTowerUpg.getLevelRequierment("Blaster",2),
								stats ={dmg =		{ upgrade.mul, 1.16},
										dmg_range= { upgrade.mul, 1.16} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "Blaster",
								info = "missile tower explosion",
								order = 3,
								icon = 39,
								value1 = 24,
								levelRequirement = cTowerUpg.getLevelRequierment("Blaster",3),
								stats ={dmg =		{ upgrade.mul, 1.24},
										dmg_range= { upgrade.mul, 1.24} }
							} )
		-- fuel
		function fireDamage1() return upgrade.getStats("dmg") * 0.20 end
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fuel",
								info = "missile tower fire",
								order = 4,
								icon = 38,
								value1 = 20,--20% fire damage
								value2 = 1,--1 seconds
								levelRequirement = cTowerUpg.getLevelRequierment("fuel",1),
								stats ={fireDPS =		{ upgrade.set, fireDamage1},
										burnTime =		{ upgrade.add, 1.0} }
							} )
		function fireDamage2() return upgrade.getStats("dmg") * 0.22 end
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fuel",
								info = "missile tower fire",
								order = 4,
								icon = 38,
								value1 = 22,
								value2 = 1.75,
								levelRequirement = cTowerUpg.getLevelRequierment("fuel",2),
								stats ={fireDPS =		{ upgrade.set, fireDamage2},
										burnTime =		{ upgrade.add, 1.75} }
							} )
		function fireDamage3() return upgrade.getStats("dmg") * 0.24 end
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fuel",
								info = "missile tower fire",
								order = 4,
								icon = 38,
								value1 = 24,
								value2 = 2.5,
								levelRequirement = cTowerUpg.getLevelRequierment("fuel",3),
								stats ={fireDPS =		{ upgrade.set, fireDamage3},
										burnTime =		{ upgrade.add, 2.5} }
							} )
		--ShieldSmasher
		--1 of 8 gropus is turtle shielded, mening 15% increase in damage where 1 damage per wave will give 9.2 meaning to increase 1 wave to the same is 2.2
		--meaning 120% damage increase for shield is needed to neglect damage increase in the other waves (because special case upgrade we give it another 15%) ending in 2.5x dmage
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "shieldSmasher",
								info = "missile tower shield destroyer",
								order = 5,
								icon = 42,
								value1 = 200,--200% damage increase
								levelRequirement = cTowerUpg.getLevelRequierment("shieldSmasher",1),
								stats ={shieldDamageMul =	{ upgrade.mul, 3.0}}
							} )
		supportManager.setUpgrade(upgrade)
		supportManager.addHiddenUpgrades()
		supportManager.addSetCallbackOnChange(updateStats)
		
		upgrade.upgrade("upgrade")
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		billboard:setString("targetMods","attackHighDensity;attackVariedTargets;attackPriorityTarget;attackClosestToExit;attackWeakestTarget;attackStrongestTarget")
		billboard:setInt("currentTargetMode",1)
		
		--model
		model = Core.getModel(upgrade.getValue("model"))
		this:addChild(model)
		this:addChild(StaticBody(model:getMesh("physic")))
		
		--Hull
		local hullModel = Core.getModel("tower_resource_hull.mym")
		
		--default billboard stats
		billboard:setVectorVec3("hull3d",createHullList3d(hullModel:getMesh("hull")))
		billboard:setVectorVec2("hull2d",createHullList2d(hullModel:getMesh("hull")))
		
		--ComUnitCallbacks
		comUnitTable["dmgDealt"] = damageDealt
		comUnitTable["waveChanged"] = waveChanged
		comUnitTable["upgrade1"] = self.handleUpgrade
		comUnitTable["upgrade2"] = self.handleBoost
		comUnitTable["upgrade3"] = self.handleRange
		comUnitTable["upgrade4"] = self.handleBlaster
		comUnitTable["upgrade5"] = self.handleFuel
		comUnitTable["upgrade6"] = self.handleShieldSmasher
		comUnitTable["NetOwner"] = setNetOwner
		comUnitTable["NetLaunchMissile"] = NetLaunchMissile
		comUnitTable["SetTargetMode"] = self.SetTargetMode
		--comUnitTable["damageDealt"] = handleDamageDealt
		supportManager.setComUnitTable(comUnitTable)
		supportManager.addCallbacks()
	
		--soulManager and targetSelecter
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(upgrade.getValue("range"))
		
		initModel()
		setCurrentInfo()
		
		myStatsReset()
		cTowerUpg.addUpg("range",self.handleRange)
		cTowerUpg.addUpg("Blaster",self.handleBlaster)
		cTowerUpg.addUpg("fuel",self.handleFuel)
		cTowerUpg.addUpg("shieldSmasher",self.handleShieldSmasher)
		cTowerUpg.fixAllPermBoughtUpgrades()
		
		--this:setIsStatic(true)
		return true
	end
	init()
	--
	return self
end

function create()
	missileTower = MissileTower.new()
	update = missileTower.update
	destroy = missileTower.destroy
	return true
end