require("Tower/upgrade.lua")
require("Tower/xpSystem.lua")
require("Tower/supportManager.lua")
require("NPC/state.lua")
require("Game/campaignTowerUpg.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
require("Game/soundManager.lua")
--this = SceneNode()
ElectricTower = {}
function ElectricTower.new()
	local MAXTHEORETICALENERGYTRANSFERRANGE = (4+2.25)*1.3+0.75
	local TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION = 0.2
	local self = {}
	local waveCount = 0
	local dmgDone = 0
	local cData = CampaignData.new()
	local upgrade = Upgrade.new()
	local supportManager = SupportManager.new()
	local cTowerUpg = CampaignTowerUpg.new("Tower/ElectricTower.lua",upgrade)
	local damagePerEnergy = 19
	--XP
	local xpManager = XpSystem.new(upgrade)
	--model
	local model
	local ring = {}
	local localRingCenterPos = Vec3()
	--attack
	local targetMode = 1
	local lastEnergyRequest = 0.0
	local slow = 0.0
	local slowRange = 0.0
	local SlowDuration = 0.0
	local reloadTimeLeft = 0.0
	local energy = 0.0
	local energyReg = 0.0
	local AttackEnergyCost = 0.0
	local oneDamageCost = 0.0
	local minAttackCost = 0.0
	local equalizer =	false
	local boostedOnLevel = 0
	--effect
	local energyLightShow = 2.0
	local pointLightBaseRange = 1.75
	local sparkCenter = ParticleSystem.new(ParticleEffect.SparkSpirit)
	local electric1 = ParticleEffectElectricFlash.new("Lightning_D.tga")
	local electric2 = ParticleEffectElectricFlash.new("Lightning_D.tga")
	local pointLight = PointLight.new(Vec3(0,2.5,0),Vec3(0.0,4.0,4.0),pointLightBaseRange)
	local pointLightAttack = PointLight.new(Vec3(),Vec3(0.0,3.0,3.0),3.0)
	--upgrades
	local energyOffers = {size=0,frameCounter=0,depth=0}
	--communication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local billboardWaveStats
	--sound
	local attackSounds = {"electric_attack1", "electric_attack2", "electric_attack3", "electric_attack4"}
	local soundManager = SoundManager.new(this)
	--other
	local isAnyInRange = {timer=0.0, isAnyInRange=false}
	local syncTimer = 0.0 
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local visibleState = 2
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this
	local energySent = 0
	local lastRestored = -1
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	--stats
	local isCircleMap = MapInfo.new().isCricleMap()
	local mapName = MapInfo.new().getMapName()
	--Achievements
	--
	
	local function canSyncTower()
		return (Core.isInMultiplayer()==false or self.getCurrentIslandPlayerId()==0 or networkSyncPlayerId==Core.getPlayerId())
	end
	local function achievementUnlocked(whatAchievement)
		if canSyncTower() then
			comUnit:sendTo("SteamAchievement",whatAchievement,"")
		end
	end
	
	local function storeWaveChangeStats( waveStr )
		if isThisReal then
			billboardWaveStats = billboardWaveStats or Core.getGameSessionBillboard( "tower_"..Core.getNetworkName() )
			--update wave stats only if it has not been set (this function will be called on wave changes when going back in time)
			if billboardWaveStats:exist( waveStr )==false then
				local tab = {
					xpTab = xpManager and xpManager.storeWaveChangeStats() or nil,
					energy = energy,
					upgradeTab = upgrade.storeWaveChangeStats(),
					DamagePreviousWave = billboard:getDouble("DamagePreviousWave"),
					DamagePreviousWavePassive = billboard:getDouble("DamagePreviousWavePassive"),
					DamageTotal = billboard:getDouble("DamageTotal"),
					currentTargetMode = billboard:getInt("currentTargetMode"),
					boostedOnLevel = boostedOnLevel,
					currentTargetAreaOffset = billboard:getMatrix("TargetAreaOffset"),
					boostLevel = upgrade.getLevel("boost"),
					upgradeLevel = upgrade.getLevel("upgrade"),
					rangeLevel = upgrade.getLevel("range"),
					ampedSlowLevel = upgrade.getLevel("ampedSlow"),
					energyPoolLevel = upgrade.getLevel("energyPool"),
					energyLevel = upgrade.getLevel("energy")
				}
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
				if upgrade.getLevel("boost")~=tab.boostLevel then self.handleBoost(tab.boostLevel) end
				doDegrade(upgrade.getLevel("range"),tab.rangeLevel,self.handleUpgradeRange)
				doDegrade(upgrade.getLevel("ampedSlow"),tab.ampedSlowLevel,self.handleUpgradeSlow)
				doDegrade(upgrade.getLevel("energyPool"),tab.energyPoolLevel,self.handleUpgradeEnergyPool)
				doDegrade(upgrade.getLevel("energy"),tab.energyLevel,self.handleUpgradeEnergy)
				doDegrade(upgrade.getLevel("upgrade"),tab.upgradeLevel,self.handleUpgrade)--main upgrade last as the assets might not be available for higer levels
				--
				upgrade.restoreWaveChangeStats(tab.upgradeTab)
				--
				billboard:setDouble("DamagePreviousWave", tab.DamagePreviousWave)
				billboard:setDouble("DamageCurrentWave", tab.DamagePreviousWave)
				billboard:setDouble("DamagePreviousWavePassive", tab.DamagePreviousWavePassive)
				billboard:setDouble("DamageTotal", tab.DamageTotal)
				energy = tab.energy
				self.SetTargetMode(tab.currentTargetMode)
				boostedOnLevel = tab.boostedOnLevel
			end
		end
	end
	local function restartWave(param)
		supportManager.restartWave()
		restoreWaveChangeStats( tonumber(param) )
		dmgDone = 0
	end
	
	local function doLightning(targetPosition,sphere)
		if targetPosition:length()>0.01 then
		
			local endPos = this:getGlobalMatrix():inverseM()*targetPosition
			
			pointLightAttack:setLocalPosition( (localRingCenterPos+endPos)*0.5 )
			pointLightAttack:setVisible(true)
			pointLightAttack:setRange(4.0)
			pointLightAttack:pushRangeChange(0.25,math.min((1.0/upgrade.getValue("RPS"))-0.05,0.5))
			pointLightAttack:pushVisible(false)
			
		
			if sphere then
				sphere = Sphere(this:getGlobalMatrix():inverseM()*sphere:getPosition(),sphere:getRadius())
				electric1:setLine(localRingCenterPos,endPos,sphere,0.35)
				electric2:setLine(localRingCenterPos,endPos,sphere,0.45)
			else
				electric1:setLine(localRingCenterPos,endPos,0.35)
				electric2:setLine(localRingCenterPos,endPos,0.45)
			end
		
			if reloadTimeLeft<-Core.getDeltaTime() then--if over due for fiering
				reloadTimeLeft = (1.0/upgrade.getValue("RPS"))
			else--if we was supposed to fire this frame
				reloadTimeLeft = reloadTimeLeft + (1.0/upgrade.getValue("RPS"))
			end
			--lastEnergyRequest = 0.75--tower can ask for energy every 0.75s
			return true
		end
		return false
	end
	local function canOfferEnergy(askerInPrioOverUs)
		if energy>AttackEnergyCost then
			return math.clamp(AttackEnergyCost*1.5, energy*(askerInPrioOverUs and 0.35 or 0.1), energy)
		else
			return 0
		end
	end
	local function doWeHaveEnergyOver(param, fromIndex)
		--energy transfer can only occure if there is no enemy in range
		--we will only give energy if they have priority(an enemy in range)
		--or we have shorter time to max energy +2s
		
		--make sure we don't have priority (enemy in range)
		if targetSelector.isAnyInRange()==false and reloadTimeLeft<0.0 then
			local energyMax = upgrade.getValue("energyMax")
			local percentage = energy/energyMax
			--make sure the tower is in range
			if (this:getGlobalPosition()-Core.getBillboard(fromIndex):getVec3("GlobalPosition")):length()<=upgrade.getValue("range")+0.75 then
				local rechargeTimeLeft = (energyMax-energy)/energyReg
				if param.deficit>1 then
					local canOffer = canOfferEnergy(param.prio)
					if canOffer>AttackEnergyCost*0.5 then
						local canOfferPercentage = (canOffer*2)/energyMax
						if param.prio or rechargeTimeLeft+2.0<param.rechargeTimeLeft then
							--give energy if they are in priority or we have 2s shorter resharge time
							if energy>AttackEnergyCost then
								comUnit:sendTo(fromIndex,"canOfferEnergy",{canOffer=canOffer, rechargeTimeLeft=rechargeTimeLeft})
							end
						end
					end
				elseif energy+1>energyMax then
					--if we are full on energy and the other tower is not requesting energy, then we can do a light show to visualize the link
					comUnit:sendTo(fromIndex,"canOfferEnergy",{canOffer=0.1, rechargeTimeLeft=0})-- offers<1 will not send any energy
				end
			end
		end
	end
	--a tower have asked for our energy reserve
	local function sendEnergyTo(parameter, fromIndex)
		local neededEnergy = parameter.energyNeed
		--we assume he has prio. (because they will not ask for more that our offer)
		local canOffer = canOfferEnergy(true)
		local willSend = canOffer>neededEnergy and neededEnergy or canOffer
		comUnit:sendTo(fromIndex,"sendEnergyTo",tostring(willSend))
		energy = energy - willSend
		doLightning(parameter.pos+Vec3(0.0,2.75,0.0))
		--stats
		energySent = energySent + willSend
		comUnit:sendTo("SteamStats","ElectricTowerMaxEnergySent",energySent)
	end
	local function updateAskForEnergy()
		--we wait for 2 frames so all offer can be heard at the same time
		energyOffers.frameCounter = energyOffers.frameCounter - 1
		if energyOffers.frameCounter==0 then
			local energyMax = upgrade.getValue("energyMax")
			local energyNeed = energy+1>energyMax and 0 or energyMax-(energy+(energyReg*Core.getDeltaTime()*2.0)) --energyReg*Core.getDeltaTime()*2.0) estimated delta time before reciving energy
			local maxOffer = -1
			local bestIndex = 0
			for index=1, energyOffers.size, 1 do
				if energyOffers[index].offer>maxOffer then
					maxOffer = energyOffers[index].offer
					bestIndex = energyOffers[index].from
					--if we have gotten an offer of what we need
					if maxOffer>energyNeed then
						maxOffer = energyNeed
						break
					end
				end
			end
			if bestIndex>0 then
				comUnit:sendTo(bestIndex,"sendMeEnergy",{energyNeed=energyNeed>1 and maxOffer or 0,pos=this:getGlobalPosition()})
			end
		end
	end
	--a tower is serching for more energy
	--recive information when a tower can lend some energy
	local function someoneCanOfferEnergy(parameter, fromIndex)
		energyOffers.size = energyOffers.size + 1
		energyOffers[energyOffers.size] = {offer=parameter.canOffer, rechargeTimeLeft=parameter.rechargeTimeLeft, from=fromIndex}
	end
	local function recivingEnergy(parameter, fromIndex)
		energy = energy + tonumber(parameter)
		local energyMax = upgrade.getValue("energyMax")
		if energy>energyMax then
			local diff = energyMax-energy
			if diff>2 then--ops we got to much energy send it back. no fancy show, it was pure unluck
				comUnit:sendTo(fromIndex,"sendEnergyTo",tostring(diff))
			end
			energy = energyMax
		end
		--
		--Achievement
		--
		if not LinkAchievement then
			LinkAchievement = true
			achievementUnlocked("Link")
		end
	end
	local function updateStats()
		slow =			upgrade.getValue("slow")
		slowRange = 	upgrade.getValue("slowRange")
		SlowDuration =	upgrade.getValue("slowTimer")
		energyReg =		 	upgrade.getValue("energyReg")--info[upgradeLevel]["energyMax"]/info[upgradeLevel][chargeTime]
		AttackEnergyCost =	upgrade.getValue("attackCost")
		oneDamageCost =		upgrade.getValue("attackCost")/upgrade.getValue("damage")
		minAttackCost = 	upgrade.getValue("minDamage")*oneDamageCost
		equalizer =			(upgrade.getValue("equalizer")>0.5)
		targetSelector.setRange(upgrade.getValue("range"))
	end
	local function setCurrentInfo()
		if xpManager then
			xpManager.updateXpToNextLevel()
		end

		reloadTimeLeft =	0.0
		energy =			upgrade.getValue("energyMax")--info[upgradeLevel]["energyMax"]
		
		updateStats()
		--achievment
		if upgrade.getLevel("upgrade")==3 and upgrade.getLevel("energyPool")==3 and upgrade.getLevel("ampedSlow")==3 and upgrade.getLevel("energy")==3 and upgrade.getLevel("range")==3 then
			achievementUnlocked("ElectricMaxed")
		end
	end
	local function initModel()
	
		model:createBoundVolumeGroup()
		model:setBoundingVolumeCanShrink(false)
	
		for index =1, 3, 1 do
			model:getMesh( string.format("range%d", index) ):setVisible( upgrade.getLevel("energyPool")==index )--this is just reusing the smae model
			model:getMesh( string.format("slow%d", index) ):setVisible( upgrade.getLevel("ampedSlow")==index )
			model:getMesh( string.format("amplifier%d", index) ):setVisible( upgrade.getLevel("energy")==index )
			model:getMesh( string.format("equalizer%d", index) ):setVisible( upgrade.getLevel("range")==index )
			model:getMesh( string.format("masterAim%d", index) ):setVisible( false )
		end
		--model:getMesh( "physic" ):setVisible(false)
		model:getMesh("hull"):setVisible(false)
		model:getMesh("space0"):setVisible(false)
		model:getMesh("boost"):setVisible(upgrade.getLevel("boost")==1)
		--set ambient map
		for index=0, model:getNumMesh()-1 do
			local mesh = model:getMesh(index)
			local shader = mesh:getShader()
			local texture = Core.getTexture(upgrade.getLevel("boost")==0 and "towergroup_a" or "towergroup_boost_a")
			
			mesh:setTexture(shader,texture,4)
		end
		for index = 1, upgrade.getLevel("upgrade"), 1 do
			ring[index] = model:getMesh( string.format("ring%d", index) )
		end
		localRingCenterPos = ring[1]:getLocalMatrix():getPosition()
		--performance check
		for index = 1, upgrade.getLevel("upgrade"), 1 do
			ring[index]:DisableBoundingVolumesDynamicUpdates()
		end
	end
	local function doMeshUpgradeForLevel(name,meshName)
		if upgrade.getLevel(name)>0 then
			model:getMesh(meshName..upgrade.getLevel(name)):setVisible(true)
			if upgrade.getLevel(name)>1 then
				model:getMesh(meshName..upgrade.getLevel(name)-1):setVisible(false)
			end
		end
	end
	function self.getCurrentIslandPlayerId()
		local islandPlayerId = 0--0 is no owner
		local island = this:findNodeByTypeTowardsRoot(NodeId.island)
		if island then
			islandPlayerId = island:getPlayerId()
		end
		--if islandPlayerId>0 then
		networkSyncPlayerId = islandPlayerId
		if type(networkSyncPlayerId)=="number" and Core.getNetworkClient():isPlayerIdInUse(networkSyncPlayerId)==false then
			networkSyncPlayerId = 0
		end
		--end
		return networkSyncPlayerId
	end
	local function canSyncTower()
		return (Core.isInMultiplayer()==false or self.getCurrentIslandPlayerId()==0 or networkSyncPlayerId==Core.getPlayerId())
	end
	function self.handleUpgrade(param)
		if tonumber(param)>upgrade.getLevel("upgrade") then
			upgrade.upgrade("upgrade")
		elseif upgrade.getLevel("upgrade")>tonumber(param) then
			upgrade.degrade("upgrade")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() and Core.getNetworkName():len()>0 and canSyncTower() then
			comUnit:sendNetworkSyncSafe("upgrade1",tostring(param))
		end
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		--Achievements
		local level = upgrade.getLevel("upgrade")
		comUnit:sendTo("stats","addBillboardInt","level"..level..";1")
		if upgrade.getLevel("upgrade")==3 then
			achievementUnlocked("Upgrader")
		end
		if not xpManager or upgrade.getLevel("upgrade")==1 or upgrade.getLevel("upgrade")==2 or upgrade.getLevel("upgrade")==3 then
			local matrixList = {}
			for i=1, upgrade.getLevel("upgrade")-1, 1 do
				matrixList[i] = model:getMesh("ring"..i):getLocalMatrix()
			end
			this:removeChild(model:toSceneNode())
			
			model = Core.getModel( upgrade.getValue("model") )
			this:addChild(model:toSceneNode())
			for i=1, upgrade.getLevel("upgrade")-1, 1 do
				model:getMesh("ring"..i):setLocalMatrix( matrixList[i] )
			end
			initModel()
			cTowerUpg.fixAllPermBoughtUpgrades()
		end
		upgrade.clearCooldown()
		setCurrentInfo()
	end
	function self.handleBoost(param)
		if tonumber(param)>upgrade.getLevel("boost") then
			if Core.isInMultiplayer() and canSyncTower() then
				comUnit:sendNetworkSyncSafe("upgrade2","1")
			end
			boostedOnLevel = upgrade.getLevel("upgrade")
			upgrade.upgrade("boost")
			model:getMesh("boost"):setVisible(true)
			setCurrentInfo()
			--Achievement
			achievementUnlocked("Boost")
		elseif upgrade.getLevel("boost")>tonumber(param) then
			upgrade.degrade("boost")
			model:getMesh("boost"):setVisible( false )
			setCurrentInfo()
			--clear coldown info for boost upgrade
			upgrade.clearCooldown()
		end
		initModel()
	end
	function self.handleUpgradeRange(param)
		if tonumber(param)>upgrade.getLevel("range") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("range")
		elseif upgrade.getLevel("range")>tonumber(param) then
			upgrade.degrade("range")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() and canSyncTower() then
			comUnit:sendNetworkSyncSafe("upgrade3",tostring(param))
		end
		if upgrade.getLevel("range")>0 then
			--no mesh in use
			--Acievement
			if upgrade.getLevel("range")==3 then
				achievementUnlocked("Range")
			end
		end
		setCurrentInfo()
	end
	function self.handleUpgradeSlow(param)
		if tonumber(param)>upgrade.getLevel("ampedSlow") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("ampedSlow")
		elseif upgrade.getLevel("ampedSlow")>tonumber(param) then
			model:getMesh("slow"..upgrade.getLevel("ampedSlow")):setVisible(false)
			upgrade.degrade("ampedSlow")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() and canSyncTower() then
			comUnit:sendNetworkSyncSafe("upgrade4",tostring(param))
		end
		if upgrade.getLevel("ampedSlow")>0 then
			doMeshUpgradeForLevel("ampedSlow","slow")
			--Achievement
			if upgrade.getLevel("ampedSlow")==3 then
				achievementUnlocked("Slow")
			end
		end
		setCurrentInfo()
	end
	function self.handleUpgradeEnergyPool(param)
		if tonumber(param)>upgrade.getLevel("energyPool") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("energyPool")
		elseif upgrade.getLevel("energyPool")>tonumber(param) then
			model:getMesh("range"..upgrade.getLevel("energyPool")):setVisible(false)
			upgrade.degrade("energyPool")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() and canSyncTower() then
			comUnit:sendNetworkSyncSafe("upgrade5",tostring(param))
		end
		if upgrade.getLevel("energyPool")>0 then
			doMeshUpgradeForLevel("energyPool","range")--this is just reusing the same model
			--Achievement
			if upgrade.getLevel("energyPool")==3 then
				achievementUnlocked("EnergyBatery")
			end
		end
		setCurrentInfo()
	end
	function self.handleUpgradeEnergy(param)
		if tonumber(param)>upgrade.getLevel("energy") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("energy")
		elseif upgrade.getLevel("energy")>tonumber(param) then
			model:getMesh("amplifier"..upgrade.getLevel("energy")):setVisible(false)
			upgrade.degrade("energy")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() and canSyncTower() then
			comUnit:sendNetworkSyncSafe("upgrade6",tostring(param))
		end
		if upgrade.getLevel("energy")>0 then
			doMeshUpgradeForLevel("energy","amplifier")
			--Achievement
		end
		setCurrentInfo()
	end
	local function damageDealt(param)
		local addDmg = supportManager.handleSupportDamage( tonumber(param) )
		dmgDone = dmgDone + addDmg
		billboard:setDouble("DamageCurrentWave",dmgDone)
		billboard:setDouble("DamageTotal",billboard:getDouble("DamagePreviousWave")+dmgDone)
		if xpManager then
			xpManager.addXp(addDmg)
			local interpolation  = xpManager.getLevelPercentDoneToNextLevel()
			upgrade.setInterpolation(interpolation)
			upgrade.fixBillboardAndStats()
		end
	end
	local function waveChanged(param)
		local name
		local waveCountStr
		name,waveCountStr = string.match(param, "(.*);(.*)")
		waveCount = tonumber(waveCountStr)
		--update and save stats only if we did not just restore this wave
		if waveCount>=lastRestored then
			if not xpManager then
				billboard:setDouble("DamagePreviousWave",dmgDone)
				if canSyncTower() then
					comUnit:sendTo("stats", "addTotalDmg", dmgDone )
				end
			else
				xpManager.payStoredXp(waveCount)
				--update billboard
				upgrade.fixBillboardAndStats()
			end
			--store wave info to be able to restore it
			storeWaveChangeStats( tostring(waveCount+1) )
		end
		dmgDone = 0
	end
	local function NetSyncTarget(param)
		local target = tonumber(Core.getIndexOfNetworkName(param))
		if target>0 then
			targetSelector.setTarget(target)
		end
	end
	function self.SetTargetMode(param)
		targetMode = math.clamp(tonumber(param),1,5)
		billboard:setInt("currentTargetMode",targetMode)
		if billboard:getBool("isNetOwner") and Core.isInMultiplayer() then
			comUnit:sendNetworkSync("SetTargetMode", tostring(param) )
		end
	end
	local function updateTarget()
		--only select new target if we own the tower or we are not told anything usefull
		if (billboard:getBool("isNetOwner") or targetSelector.getTargetIfAvailable()==0) then
			if targetSelector.selectAllInRange() then
				targetSelector.filterOutState(state.ignore)
				if targetMode==1 then
					--high priority
					targetSelector.scoreHP(10)
					targetSelector.scoreName("dino",10)
					targetSelector.scoreName("reaper",25)
					targetSelector.scoreName("skeleton_cf",25)
					targetSelector.scoreName("skeleton_cb",25)
				elseif targetMode==2 then
					--density
					targetSelector.scoreClosestToExit(10)
					targetSelector.scoreDensity(25)
				elseif targetMode==3 then
					--attackWeakestTarget
					targetSelector.scoreHP(-30)
					targetSelector.scoreClosestToExit(10)
				elseif targetMode==4 then
					--attackStrongestTarget
					targetSelector.scoreHP(30)
					targetSelector.scoreClosestToExit(20)
					targetSelector.scoreName("reaper",20)
					targetSelector.scoreName("skeleton_cf",20)
					targetSelector.scoreName("skeleton_cb",20)
				elseif targetMode==5 then
					--closest to exit
					targetSelector.scoreClosestToExit(20)
				end
				targetSelector.scoreState(state.markOfDeath,10)
				targetSelector.scoreState(state.highPriority,30)
				targetSelector.scoreName("electroSpirit",-1000)
				targetSelector.selectTargetAfterMaxScore(-500)
				--sync
				if billboard:getBool("isNetOwner") then
					local newTarget = targetSelector.getTarget()
					if newTarget>0 then
						comUnit:sendNetworkSync("NetTarget", Core.getNetworkNameOf(newTarget))
					end
				end
			end
			if targetSelector.getTarget()==0 then
				reloadTimeLeft = TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION
			end
		end
	end
	local function handleRetarget()
		targetSelector.deselect()
	end
	
	local function attack()
		local target = targetSelector.getTargetIfAvailable()
		if target>0 then
			local targetPosition = targetSelector.getTargetPosition(target)
			local ringCenterPos = ring[1]:getGlobalPosition()
			--
			soundManager.play(attackSounds[math.randomInt(1,#attackSounds)], 1.0, false)
			--
			if targetSelector.getIndexOfShieldCovering(targetPosition)==targetSelector.getIndexOfShieldCovering(ringCenterPos) then
				--direct hitt
				if doLightning(targetPosition) then
					local hp = targetSelector.getTargetHP(target)
					local totalKillCost = math.max(minAttackCost,hp*oneDamageCost)
					if totalKillCost<AttackEnergyCost then
						energy = energy - totalKillCost
						comUnit:sendTo(target,"attackElectric",tostring(totalKillCost/oneDamageCost+(hp*1.015)))--+regen for dino with 50% extra
					else
						energy = energy - AttackEnergyCost
						comUnit:sendTo(target,"attackElectric",tostring(upgrade.getValue("damage")))
					end
					if slowRange==0.0 then
						comUnit:sendTo(target,"slow",{per=slow,time=SlowDuration,type="electric"})
					else
						comUnit:broadCast(targetPosition,slowRange,"slow",{per=slow,time=SlowDuration,type="electric"})
					end
				end
			else
				--forcefield hitt
				local shieldIndex = targetSelector.getIndexOfShieldCovering(targetPosition)>0 and targetSelector.getIndexOfShieldCovering(targetPosition) or targetSelector.getIndexOfShieldCovering(ringCenterPos)
				target = targetSelector.getIndexOfShieldCovering(targetPosition)>0 and targetSelector.getIndexOfShieldCovering(targetPosition) or targetSelector.getIndexOfShieldCovering(ringCenterPos)
				if doLightning(targetPosition,Sphere(targetSelector.getTargetPosition(shieldIndex),3.5)) then--shieldIndex was target
					local hp = targetSelector.getTargetHP(shieldIndex)--shieldIndex was target
					local totalKillCost = math.max(minAttackCost,hp*oneDamageCost)
					if totalKillCost<AttackEnergyCost then				
						energy = energy - totalKillCost
						comUnit:sendTo(shieldIndex,"attack",tostring(totalKillCost/oneDamageCost))
					else
						energy = energy - AttackEnergyCost
						comUnit:sendTo(shieldIndex,"attack",tostring(upgrade.getValue("damage")))
					end
					--hitt effect
					local oldPosition = ring[1]:getGlobalPosition()
					local futurePosition = targetPosition
					local hitTime = "1.25"
					comUnit:sendTo(shieldIndex,"addForceFieldEffect",tostring(oldPosition.x)..";"..oldPosition.y..";"..oldPosition.z..";"..futurePosition.x..";"..futurePosition.y..";"..futurePosition.z..";"..hitTime)
				end
			end
		end
		--targetSelector.deselect()
	end
	local function updateEnergy()
		isAnyInRange.timer = isAnyInRange.timer + Core.getDeltaTime()
		if isAnyInRange.timer<0.0 then
			isAnyInRange.timer = isAnyInRange.timer + 0.5
			isAnyInRange.isAnyInRange = targetSelector.isAnyInRange()
		end
		local regenMul = 1.0 + (isAnyInRange.isAnyInRange and 1.0 or 1.5)
		energy = math.min(upgrade.getValue("energyMax"),energy + (energyReg*Core.getDeltaTime()*regenMul))
		billboard:setFloat("energy", energy )
	end
	local function updateSync()
		if billboard:getBool("isNetOwner") then
			syncTimer = syncTimer + Core.getRealDeltaTime()
			if syncTimer>0.5 then
				syncTimer = 0.0
				local newTarget = targetSelector.getTargetIfAvailable()
				if newTarget>0 then
					comUnit:sendNetworkSync("NetTarget", Core.getNetworkNameOf(newTarget))
				end
			end
		end
	end
	function self.update()

		if upgrade.update() then
			model:getMesh("boost"):setVisible( false )
			setCurrentInfo()
			initModel()
			--if the tower was upgraded while boosted, then the boost should be available
			if boostedOnLevel~=upgrade.getLevel("upgrade") then
				upgrade.clearCooldown()
			end
		end
		comUnit:setPos(this:getGlobalPosition())
		updateEnergy()
		local deltaTime = Core.getDeltaTime()
		local energyMax = upgrade.getValue("energyMax")
		local energyPer = (energy/energyMax)+0.05--0.05 is so we never reaches 0
		local rotationThisFrame = math.pi*deltaTime*energyPer
		reloadTimeLeft = reloadTimeLeft - deltaTime
		--handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		if xpManager then
			xpManager.update()
		end
		
		--change update speed
--		local tmpCameraNode = cameraNode
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 20) * 2)
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end
		
		--update the energy asking
		updateAskForEnergy()
		--if we can attack the enemy
		updateSync()
		if energy>AttackEnergyCost and reloadTimeLeft<0.0 then
			updateTarget()
			if targetSelector.getTargetIfAvailable()>0 then
				local targetAt = targetSelector.getTargetPosition(targetSelector.getTarget())-ring[1]:getGlobalPosition()
				attack()
				upgrade.setUsed()--set value changed
			end
		end
		--ask fo energy
		lastEnergyRequest = lastEnergyRequest + Core.getDeltaTime()
		if energy<energyMax*0.9 and lastEnergyRequest>(targetSelector.isAnyInRange() and 0.5 or 1.0) then--can ask 1/s or 2/s if there is any enemies in range
			lastEnergyRequest = 0.0
			local rechargeTimeLeft = (energyMax-energy)/energyReg
			if targetSelector.isAnyInRange() then
				comUnit:broadCast(this:getGlobalPosition(),MAXTHEORETICALENERGYTRANSFERRANGE,"requestEnergy",{prio=true,deficit=(energyMax-energy),rechargeTimeLeft=rechargeTimeLeft})
			else
				comUnit:broadCast(this:getGlobalPosition(),MAXTHEORETICALENERGYTRANSFERRANGE,"requestEnergy",{prio=false,deficit=(energyMax-energy),rechargeTimeLeft=rechargeTimeLeft})
			end
			energyOffers.size=0
			energyOffers.frameCounter=2
		elseif energy+1>energyMax and not targetSelector.isAnyInRange() and lastEnergyRequest>energyLightShow then
			--max energy (make a light show, to indicate that there is a link between the towers)
			lastEnergyRequest = 0.0
			energyLightShow = math.randomFloat(3.0,7.0)
			comUnit:broadCast(this:getGlobalPosition(),MAXTHEORETICALENERGYTRANSFERRANGE,"requestEnergy",{prio=false,deficit=0,rechargeTimeLeft=0.0})
			energyOffers.size=0
			energyOffers.frameCounter=2
		end
	
		local bLevel = upgrade.getLevel("boost")
		local ampliture = 0.25+(energyPer*0.75) + (bLevel*0.5)
		sparkCenter:setScale( ampliture ) 
		pointLight:setRange(pointLightBaseRange*energyPer + bLevel)
		
		ring[1]:rotate(math.randomVec3(), rotationThisFrame*0.33*math.randomFloat())
		ring[1]:rotate(Vec3(0,1,0), rotationThisFrame*(math.randomFloat()*0.5+0.5))
		ring[1]:rotate(Vec3(0,0,1), rotationThisFrame*(math.randomFloat()*0.5+0.5))
		if upgrade.getLevel("upgrade")>=2 then
			ring[2]:rotate(Vec3(0,1,0), rotationThisFrame*(math.randomFloat()*0.5+0.5))
			if upgrade.getLevel("upgrade")==3 then
				ring[3]:rotate(Vec3(0,0,1), rotationThisFrame*(math.randomFloat()*0.5+0.5))
			end
		end
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
		----this:setIsStatic(true)
		Core.setUpdateHz(60.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		if xpManager then
			xpManager.setUpgradeCallback(self.handleUpgrade)
		end
		
		restartListener = Listener("RestartWave")
		restartListener:registerEvent("restartWave", restartWave)
		
		--
		--comTimer = 0.0
		model = Core.getModel("tower_electric_l1.mym")
		local hullModel = Core.getModel("tower_resource_hull.mym")
		--this:handleTowerHullAndSpace(model)
		this:addChild(model:toSceneNode())
	
		if particleEffectUpgradeAvailable then
			this:addChild(particleEffectUpgradeAvailable:toSceneNode())
		end
		--sound limits
		for i=1, #attackSounds do
			local s1 = SoundNode.new(attackSounds[i])
			s1:setSoundPlayLimit(2)
		end
	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
		billboard:setDouble("rangePerUpgrade",0.75)
		billboard:setString("hullName","hull")
		billboard:setVectorVec3("hull3d",createHullList3d(hullModel:getMesh("hull")))
		billboard:setVectorVec2("hull2d",createHullList2d(hullModel:getMesh("hull")))
		billboard:setModel("tower",model)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Electric tower")
		billboard:setString("FileName", "Tower/ElectricTower.lua")
		billboard:setVec3("GlobalPosition",this:getGlobalPosition())
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		--
		billboard:setDouble("DamagePreviousWave",0)
		billboard:setDouble("DamageCurrentWave",0)
	
		--ComUnitCallbacks
		comUnitTable["dmgDealt"] = damageDealt
		comUnitTable["dmgLost"] = damageLost
		comUnitTable["waveChanged"] = waveChanged
		comUnitTable["upgrade1"] = self.handleUpgrade
		comUnitTable["upgrade2"] = self.handleBoost
		comUnitTable["upgrade3"] = self.handleUpgradeRange
		comUnitTable["upgrade4"] = self.handleUpgradeSlow
		comUnitTable["upgrade5"] = self.handleUpgradeEnergyPool
		comUnitTable["upgrade6"] = self.handleUpgradeEnergy
		if isThisReal then
			comUnitTable["sendMeEnergy"] = sendEnergyTo
			comUnitTable["requestEnergy"] = doWeHaveEnergyOver
			comUnitTable["canOfferEnergy"] = someoneCanOfferEnergy
			comUnitTable["sendEnergyTo"] = recivingEnergy
		end
		comUnitTable["NetOwner"] = setNetOwner
		comUnitTable["NetTarget"] = NetSyncTarget
		comUnitTable["Retarget"] = handleRetarget
		comUnitTable["SetTargetMode"] = self.SetTargetMode
		supportManager.setComUnitTable(comUnitTable)
		supportManager.addCallbacks()
		
		upgrade.setBillboard(billboard)
		upgrade.addDisplayStats("damage")
		upgrade.addDisplayStats("RPS")
		upgrade.addDisplayStats("range")
		upgrade.addDisplayStats("slow", 100.0, 0, "%")
		upgrade.addDisplayStats("energyPool")
		upgrade.addDisplayStats("ERPS")
		upgrade.addBillboardStats("energyMax")
		upgrade.addBillboardStats("equalizer")
		
		
	
		--magic number 19 == damage per energy
		upgrade.addUpgrade( {	cost = 200,
								name = "upgrade",
								info = "electric tower level",
								order = 1,
								icon = 56,
								value1 = 1,
								stats ={range =		{ upgrade.add, 4.0},
										damage = 	{ upgrade.add, 575*1.30},
										minDamage = { upgrade.add, 145},
										RPS = 		{ upgrade.add, 3.0/3.0},
										slow = 		{ upgrade.add, 0.15},
										slowInc = 	{ upgrade.add, 0.0},
										slowTimer = { upgrade.add, 2.0},
										slowRange = { upgrade.add, 0.0},
										attackCost ={ upgrade.add, 575/damagePerEnergy},
										energyMax = { upgrade.add, (575/damagePerEnergy)*11.0},
										energyReg =	{ upgrade.add, (575/damagePerEnergy)*5/36*1.10},--0.021/g  [1.25 is just a magic number to increase regen]
										ERPS = 		{ upgrade.set, ((575/damagePerEnergy)*5/36*1.10) / (575/damagePerEnergy)},
										equalizer =	{ upgrade.add, 0.0},
										model = 	{ upgrade.set, "tower_electric_l1.mym"} }
							} )
		--MDPSpG == RPS*DMG/cost = 2.87
		--ADPSpG = RPS*damge/cost == (5/36)*575/200 = 0.40
		upgrade.addUpgrade( {	cost = 400,
								name = "upgrade",
								info = "electric tower level",
								order = 1,
								icon = 56,
								value1 = 2,
								stats ={range =		{ upgrade.add, 4.0},
										damage = 	{ upgrade.add, 1370*1.30},
										minDamage = { upgrade.add, 340},
										RPS = 		{ upgrade.add, 4.0/3.0},
										slow = 		{ upgrade.add, 0.28},
										slowInc = 	{ upgrade.add, 0.0},
										slowTimer = { upgrade.add, 2.0},
										slowRange = { upgrade.add, 0.0},
										attackCost ={ upgrade.add, 1370/damagePerEnergy},--71.9
										energyMax = { upgrade.add, (1370/damagePerEnergy)*11.0},--575
										energyReg =	{ upgrade.add, (1370/damagePerEnergy)*6.5/36*1.10},--0.021/g [1.25 is just a magic number to increase regen]
										ERPS = 		{ upgrade.set, ((1370/damagePerEnergy)*6.5/36*1.10) / (1370/damagePerEnergy)},
										equalizer =	{ upgrade.add, 0.0},
										model = 	{ upgrade.set, "tower_electric_l2.mym"} }
							},0 )
		--MDPSpG == RPS*DMG/cost = 3.0
		--ADPSpG = RPS*damge/cost == (6.5/36)*1370/600 = 0.41
		upgrade.addUpgrade( {	cost = 800,
								name = "upgrade",
								info = "electric tower level",
								order = 1,
								icon = 56,
								value1 = 3,
								stats ={range =		{ upgrade.add, 4.0},
										damage = 	{ upgrade.add, 2700*1.30},
										minDamage = { upgrade.add, 675},
										RPS = 		{ upgrade.add, 5.0/3.0},
										slow = 		{ upgrade.add, 0.39},
										slowInc = 	{ upgrade.add, 0.0},
										slowTimer = { upgrade.add, 2.0},
										slowRange = { upgrade.add, 0.0},
										attackCost ={ upgrade.add, 2700/damagePerEnergy},--143
										energyMax = { upgrade.add, (2700/damagePerEnergy)*11},--953
										energyReg =	{ upgrade.add, (2700/damagePerEnergy)*8/36*1.10},--0.022/g == energy regen per second per gold [1.25 is just a magic number to increase regen]
										ERPS = 		{ upgrade.set, ((2700/damagePerEnergy)*8/36*1.10) / (2700/damagePerEnergy)},
										equalizer =	{ upgrade.add, 0.0},
										model = 	{ upgrade.set, "tower_electric_l3.mym"} }
							},0 )
		--MDPSpG == RPS*DMG/cost = 3.2
		--ADPSpG = RPS*damge/cost == (8/36)*2700/1400 = 0.42
		function boostDamage() return upgrade.getStats("damage")*1.5*(waveCount/50+1.0) end
		--(total)	0=1.2x	25=2.4x	50=3.6x	(+ unlimited energy)
		upgrade.addUpgrade( {	cost = 0,
								name = "boost",
								info = "electric tower boost",
								duration = 10,
								cooldown = 3,
								order = 10,
								icon = 57,
								stats ={range =		{ upgrade.add, 1.0},
										damage = 	{ upgrade.func, boostDamage},
										RPS = 		{ upgrade.mul, 1.5},
										attackCost ={ upgrade.set, 0.0}}
							} )
		-- RANGE
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 0 or 100,
								name = "range",
								info = "electric tower range",
								order = 2,
								icon = 59,
								value1 = 4 + 0.75,
								levelRequirement = cTowerUpg.getLevelRequierment("range",1),
								stats ={range =		{ upgrade.add, 0.75, ""} }
							} )
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 100 or 200,
								name = "range",
								info = "electric tower range",
								order = 2,
								icon = 59,
								value1 = 4 + 1.5,
								levelRequirement = cTowerUpg.getLevelRequierment("range",2),
								stats ={range =		{ upgrade.add, 1.50, ""} }
							} )
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 200 or 300,
								name = "range",
								info = "electric tower range",
								order = 2,
								icon = 59,
								value1 = 4 + 2.25,
								levelRequirement = cTowerUpg.getLevelRequierment("range",3),
								stats ={range =		{ upgrade.add, 2.25, ""} }
							} )
		--slow
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "ampedSlow",
								info = "electric tower slow",
								order = 3,
								icon = 55,
								value1 = 15,
								value2 = 0.75,
								levelRequirement = cTowerUpg.getLevelRequierment("ampedSlow",1),
								stats ={slowInc =	{ upgrade.add, 0.15},
										damage =	{ upgrade.mul, 0.90},
										RPS =		{ upgrade.mul, 0.75},
										slowRange = { upgrade.add, 0.75} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "ampedSlow",
								info = "electric tower slow",
								order = 3,
								icon = 55,
								value1 = 28,
								value2 = 1.25,
								levelRequirement = cTowerUpg.getLevelRequierment("ampedSlow",2),
								stats ={slowInc =	{ upgrade.add, 0.28},
										damage =	{ upgrade.mul, 0.81},
										RPS =		{ upgrade.mul, 0.56},
										slowRange = { upgrade.add, 1.25} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "ampedSlow",
								info = "electric tower slow",
								order = 3,
								icon = 55,
								value1 = 39,
								value2 = 1.75,
								levelRequirement = cTowerUpg.getLevelRequierment("ampedSlow",3),
								stats ={slowInc =	{ upgrade.add, 0.39},
										damage =	{ upgrade.mul, 0.73},
										RPS =		{ upgrade.mul, 0.42},
										slowRange = { upgrade.add, 1.75} }
							} )
		-- EnergyPool
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "energyPool",
								info = "electric tower energy pool",
								order = 4,
								icon = 41,
								value1 = 30,
								levelRequirement = cTowerUpg.getLevelRequierment("energyPool",1),
								stats ={energyMax =	{ upgrade.mul, 1.30} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "energyPool",
								info = "electric tower energy pool",
								order = 4,
								icon = 41,
								value1 = 60,
								levelRequirement = cTowerUpg.getLevelRequierment("energyPool",2),
								stats ={energyMax =	{ upgrade.mul, 1.60} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "energyPool",
								info = "electric tower energy pool",
								order = 4,
								icon = 41,
								value1 = 90,
								levelRequirement = cTowerUpg.getLevelRequierment("energyPool",3),
								stats ={energyMax =	{ upgrade.mul, 1.90} }
							} )
		-- Energy
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "energy",
								info = "electric tower energy regen",
								order = 5,
								icon = 50,
								value1 = 15,
								levelRequirement = cTowerUpg.getLevelRequierment("energy",1),
								stats ={energyReg =	{ upgrade.mul, 1.15},
										ERPS = 		{ upgrade.mul, 1.15},
										equalizer =	{ upgrade.add, 1.0}}
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "energy",
								info = "electric tower energy regen",
								order = 5,
								icon = 50,
								value1 = 30,
								levelRequirement = cTowerUpg.getLevelRequierment("energy",2),
								stats ={energyReg =	{ upgrade.mul, 1.30},
										ERPS = 		{ upgrade.mul, 1.30}}
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "energy",
								info = "electric tower energy regen",
								order = 5,
								icon = 50,
								value1 = 45,
								levelRequirement = cTowerUpg.getLevelRequierment("energy",3),
								stats ={energyReg =	{ upgrade.mul, 1.45},
										ERPS = 		{ upgrade.mul, 1.45}}
							} )
		function calcSlow() return 1.0-( (1.0-upgrade.getStats("slow"))*(1.0-upgrade.getStats("slowInc")) ) end
		upgrade.addUpgrade( {	cost = 0,
								name = "calculate",
								info = "calc",
								order = 11,
								icon = 62,
								hidden = true,
								stats = {	slow =	{ upgrade.func, calcSlow} }
							} )
		supportManager.setUpgrade(upgrade)
		supportManager.addHiddenUpgrades()
		supportManager.addSetCallbackOnChange(updateStats)
	
		upgrade.upgrade("upgrade")
		upgrade.upgrade("calculate")
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		if isCircleMap then
			billboard:setString("targetMods","attackPriorityTarget;attackHighDensity;attackWeakestTarget;attackStrongestTarget")
			billboard:setInt("currentTargetMode",3)
		else
			billboard:setString("targetMods","attackPriorityTarget;attackHighDensity;attackWeakestTarget;attackStrongestTarget;attackClosestToExit")
			billboard:setInt("currentTargetMode",5)
		end
	
		initModel()
	
		--ParticleEffects
		this:addChild(sparkCenter:toSceneNode())
		ring[1]:rotate(math.randomVec3(), math.pi*2.0*math.randomFloat())
		sparkCenter:activate(Vec3(0,2.75,0))
		this:addChild(electric1:toSceneNode())
		this:addChild(electric2:toSceneNode())
		pointLightAttack:setCutOff(0.05)
		pointLightAttack:setVisible(false)
	
		pointLight:setCutOff(0.05)
		--pointLight = Core.getLight(LightType.point,Vec3(),Vec3(0.0,1.3,1.3),2.35)
		--pLight = Core.getLightFlicker(LightType.point,Vec3(),Vec3(0.0,0.95,0.95),2.35)
		--pointLight:addSinCurve(3.0,Vec3(0.0,0.4,0.4))
		--pointLight:addFlicker(Vec3(0.0,0.3,0.3),0.2,0.6)
		--pointLight:addFlicker(Vec3(0.0,0.3,0.3),0.0,0.3)
		--pointLight:setIsStatic(true)--so we dont have to call update()
		this:addChild(pointLight:toSceneNode())
		this:addChild(pointLightAttack:toSceneNode())
		--pLight:setLocalPosition(Vec3(0,2.75,0))
	
	
		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(1.0)
		
		setCurrentInfo()
		cTowerUpg.addUpg("range",self.handleUpgradeRange)
		cTowerUpg.addUpg("ampedSlow",self.handleUpgradeSlow)
		cTowerUpg.addUpg("energyPool",self.handleUpgradeEnergyPool)
		cTowerUpg.addUpg("energy",self.handleUpgradeEnergy)
		cTowerUpg.fixAllPermBoughtUpgrades()
		return true
	end
	init()
	--
	return self
end
function create()
	electricTower = ElectricTower.new()
	update = electricTower.update
	return true
end