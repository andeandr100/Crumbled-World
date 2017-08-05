require("Tower/upgrade.lua")
require("NPC/state.lua")
require("Tower/xpSystem.lua")
require("Tower/supportManager.lua")
require("stats.lua")
require("Projectile/projectileManager.lua")
require("Projectile/SwarmBall.lua")
require("Game/campaignTowerUpg.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
--this = SceneNode()
SwarmTower = {}
function SwarmTower.new()
	local self = {}
	local piston = {}
	local targetHistory = {0,0,0,0, 0,0,0,0}
	local targetHistoryToken = 1
	local myStats = {}
	local myStatsTimer = 0
	local waveCount = 0
	local projectiles = projectileManager.new()
	local tStats = Stats.new()
	local cData = CampaignData.new()
	local upgrade = Upgrade.new()
	local supportManager = SupportManager.new()
	local cTowerUpg = CampaignTowerUpg.new("Tower/SwarmTower.lua",upgrade)
	--XP
	local xpManager = XpSystem.new(upgrade)
	--model
	local model
	--attack
	local targetMode = 1
	local currentAttackCountOnTarget = 0
	local reloadTimeLeft = 0.0
	local boostedOnLevel = 0
	--effects
	local fireCenter = ParticleSystem(ParticleEffect.SwarmTowerFlame)
	local pointLight
	--communication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local attackCounter = 0
	local billboardWaveStats
	--Events
	restartListener = Listener("Restart")
	--sound
	--targetSelector
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local visibleState = 2
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this
	--stats
	local mapName = MapInfo.new().getMapName()
	--other
	local lastRestored = -1
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	
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
					boostedOnLevel = boostedOnLevel,
					boostLevel = upgrade.getLevel("boost"),
					upgradeLevel = upgrade.getLevel("upgrade"),
					rangeLevel = upgrade.getLevel("range"),
					burnDamageLevel = upgrade.getLevel("burnDamage"),
					fuelLevel = upgrade.getLevel("fuel")
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
				doDegrade(upgrade.getLevel("burnDamage"),tab.burnDamageLevel,self.handleUpgradeBurnDamage)
				doDegrade(upgrade.getLevel("fuel"),tab.fuelLevel,self.handleUpgradeFuel)
				doDegrade(upgrade.getLevel("upgrade"),tab.upgradeLevel,self.handleUpgrade)--main upgrade last as the assets might not be available for higer levels
				--
				upgrade.restoreWaveChangeStats(tab.upgradeTab)
				--
				billboard:setDouble("DamagePreviousWave", tab.DamagePreviousWave)
				billboard:setDouble("DamageCurrentWave", tab.DamagePreviousWave)
				billboard:setDouble("DamagePreviousWavePassive", tab.DamagePreviousWavePassive)
				billboard:setDouble("DamageTotal", tab.DamageTotal)
				self.SetTargetMode(tab.currentTargetMode)
				boostedOnLevel = tab.boostedOnLevel
			end
		end
	end
	
	local function restartWave(param)
		restoreWaveChangeStats( tonumber(param) )
		projectiles.clear()
	end
	
	local function myStatsReset()
		if myStats.dmgDone then
			billboard:setDouble("DamagePreviousWave",myStats.dmgDone)
			comUnit:sendTo("stats", "addTotalDmg", myStats.dmgDone )
		end
		myStats = {	activeTimer=0.0,	
					dmgDone=0,
					inoverHeatTimer=0.0,
					hitts=0,
					projectileLaunched=0,
					disqualified=false}
		myStatsTimer = Core.getGameTime()
	end
	local function swarmBallHitt(param)
		myStats.hitts = myStats.hitts + 1
	end
	local function damageDealt(param)
		local addDmg = supportManager.handleSupportDamage( tonumber(param) )
		myStats.dmgDone = myStats.dmgDone + addDmg
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
				if myStats.disqualified==false and upgrade.getLevel("boost")==0 and Core.getGameTime()-myStatsTimer>0.25 and myStats.activeTimer>0 then
					myStats.disqualified=nil
					myStats.DPS =myStats.dmgDone/myStats.activeTimer
					myStats.DPSpG = myStats.DPS/upgrade.getTotalCost()
					myStats.DPG = myStats.dmgDone/upgrade.getTotalCost()
					myStats.hittsPerProjectile = myStats.hitts / myStats.projectileLaunched
					--myStats.hitts=nil
					local key = "burnDamage"..upgrade.getLevel("burnDamage").."_fuel"..upgrade.getLevel("fuel").."_range"..upgrade.getLevel("range")
					tStats.addValue({mapName,"wave"..name,"swarmTower_l"..upgrade.getLevel("upgrade"),key,"sampleSize"},1)
					if myStats.activeTimer>1.0 then
						for variable, value in pairs(myStats) do
							tStats.setValue({mapName,"wave"..name,"swarmTower_l"..upgrade.getLevel("upgrade"),key,variable},value)
						end
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
	local function updateStats()
		targetSelector.setRange(upgrade.getValue("range"))
	end
	local function setCurrentInfo()
		if xpManager then
			xpManager.updateXpToNextLevel()
		end
		if myStats.activeTimer and myStats.activeTimer>0.0001 then
			myStats.disqualified = true
		end
		currentAttackCountOnTarget = 0
	
		for index = 1, 4, 1 do
			--if piston[index].timer>0.0 then
			local aPiston = piston[index]
			aPiston.timer = -0.001
			aPiston.timerStart=0.25
			aPiston.pistonGoingDown = false
			aPiston.mesh:setLocalPosition( aPiston.atVec*(0.7))
			--end
		end
		reloadTimeLeft = 0.0
		updateStats()
		--achivment
		if upgrade.getLevel("upgrade")==3 and upgrade.getLevel("range")==3 and upgrade.getLevel("burnDamage")==3 and upgrade.getLevel("fuel")==3 then
			comUnit:sendTo("SteamAchievement","SwarmMaxed","")
		end
	end
	local function initModel()
		model:createBoundVolumeGroup()
		model:setBoundingVolumeCanShrink(false)

		for index =1, upgrade.getLevel("upgrade"), 1 do
			model:getMesh( string.format("fuel%d", index) ):setVisible( upgrade.getLevel("fuel")==index )
			model:getMesh( string.format("speed%d", index) ):setVisible( upgrade.getLevel("burnDamage")==index )
		end
		--model:getMesh( "masterAim" ):setVisible( upgrade.getLevel("smartTargeting")>0 )
		model:getMesh( "boost" ):setVisible( upgrade.getLevel("boost")==1 )
		
		--model:getMesh( "notBoosted" ):setVisible( upgrade.getLevel("boost")==0 )
		--local towerPos = model:getMesh("tower"):getLocalMatrix():getPosition()
	
		for index = 1, 4, 1 do
			piston[index] = {	mesh=model:getMesh(string.format("p%d", index)),
								atVec=model:getMesh(string.format("p%d", index)):getLocalMatrix():getAtVec(),
								timerStart=0.25,
								timer=0.0,
								pistonGoingDown = false
								}
		end
		
		--performance check
		for i=0, model:getNumMesh()-1, 1 do
			if not model:getMesh(i):getName():toString()=="tower" then
				model:getMesh(i):DisableBoundingVolumesDynamicUpdates()
			end
		end
	
		--no reload
		reloadTimeLeft = 0.0
	end
	local function pushPiston(index,pushItDown)
		local aPiston = piston[index]
		if pushItDown then
			aPiston.timer = upgrade.getValue("fieringTime")*3.9*0.1
			aPiston.timerStart = upgrade.getValue("fieringTime")*3.9*0.1
			aPiston.pistonGoingDown = true
		else
			aPiston.timer = upgrade.getValue("fieringTime")*3.9*0.9
			aPiston.timerStart = upgrade.getValue("fieringTime")*3.9*0.9
			aPiston.pistonGoingDown = false
		end
	end
	local function NetBall(param)
		local tab = totable(param)
		projectiles.netSync(tab.projectileNetName ,tab)
	end
	local function attack(projectileName)
		local target = targetSelector.getTargetIfAvailable()
		if billboard:getBool("isNetOwner") or projectileName then
			if target>0 or billboard:getBool("isNetOwner")==false then
				billboard:setVec3("bulletStartPos",this:getGlobalPosition() + Vec3(0.0,2.0,0.0));
				billboard:setVec3("escapeVector",Vec3((math.randomFloat()*0.45),1.0,(math.randomFloat()*0.45)) )
				
				--upgrade.getValue("damage")
				currentAttackCountOnTarget = 1
				targetHistoryToken = targetHistoryToken==8 and 1 or targetHistoryToken + 1
				targetHistory[targetHistoryToken] = target
				billboard:setInt("targetIndex",target)
				
				--Core.launchProjectile(this, "SwarmBall",target)
				attackCounter = attackCounter + 1
				
				projectiles.launch(SwarmBall,{target, this:getGlobalPosition()+Vec3(0.0,2.0,0.0), upgrade.getValue("range"), projectileName and projectileName or "n"..attackCounter})
				--
				if billboard:getBool("isNetOwner") then
					local tab = {tName=Core.getNetworkNameOf(target), pName="n"..attackCounter}
					comUnit:sendNetworkSyncSafe("NetLaunch",tabToStrMinimal(tab))
				end
				--
			
				for index = 1, 4, 1 do
					if piston[index].pistonGoingDown==false and piston[index].timer<=0.0 then
						pushPiston(index,true)
						break
					end
				end
				--if it was not from previos frame then time is 0.0
				if reloadTimeLeft < Core.getDeltaTime() then
					reloadTimeLeft = 0.0
				end
				reloadTimeLeft = reloadTimeLeft + upgrade.getValue("fieringTime")
				--debug
				myStats.projectileLaunched = myStats.projectileLaunched + 1
			end
		end
	end
	local function NetLaunch(param)
		local tab = totable(param)
		local target = tonumber(Core.getIndexOfNetworkName(tab.tName))
		if target>0 then
			targetSelector.setTarget(target)
			attack(tab.pName)
		end
	end
	function self.SetTargetMode(param)
		targetMode = math.clamp(tonumber(param),1,4)
		billboard:setInt("currentTargetMode",targetMode)
		if billboard:getBool("isNetOwner") and Core.isInMultiplayer() then
			comUnit:sendNetworkSync("SetTargetMode", tostring(param) )
		end
	end
	local function updateTarget()
		targetSelector.selectAllInRange()
		targetSelector.filterOutState(state.ignore)
		targetSelector.scoreState(state.markOfDeath,5)
		if targetMode==1 then
			--target high prioriy
			targetSelector.scoreHP(20)
			targetSelector.scoreName("reaper",30)
			targetSelector.scoreName("skeleton_cf",25)
			targetSelector.scoreName("skeleton_cb",25)
			targetSelector.scoreName("dino",20)
			targetSelector.scoreState(state.burning,-10)
			targetSelector.scoreSelectedTargets( targetHistory, -10 )
		elseif targetMode==2 then
			--attackClosestToExit
			targetSelector.scoreClosestToExit(30)
			targetSelector.scoreState(state.burning,-10)
			targetSelector.scoreSelectedTargets( targetHistory, -5 )
			targetSelector.scoreHP(10)
		elseif targetMode==3 then
			--target weakest unit
			targetSelector.scoreHP(-25)
			targetSelector.scoreClosestToExit(15)
			targetSelector.scoreState(state.burning,-5)
			targetSelector.scoreSelectedTargets( targetHistory, -5 )
		elseif targetMode==4 then
			--attackStrongestTarget
			targetSelector.scoreHP(30)
			targetSelector.scoreClosestToExit(20)
			targetSelector.scoreState(state.burning,-5)
			targetSelector.scoreSelectedTargets( targetHistory, -5 )
		end
		
		targetSelector.scoreName("fireSpirit",-1000)
		targetSelector.scoreState(state.highPriority,30)
		targetSelector.selectTargetAfterMaxScore(-500)
			
		return targetSelector.isTargetAvailable()
	end
	local function doMeshUpgradeForLevel(name,meshName)
		model:getMesh(meshName..upgrade.getLevel(name)):setVisible(true)
		if upgrade.getLevel(name)>1 then
			model:getMesh(meshName..(upgrade.getLevel(name)-1)):setVisible(false)
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
			initModel()
			this:addChild(model)
			billboard:setModel("tower",model)
			cTowerUpg.fixAllPermBoughtUpgrades()
		end
		upgrade.clearCooldown()
		setCurrentInfo()
	end
	function self.handleBoost(param)
		if tonumber(param)>upgrade.getLevel("boost") then
			if Core.isInMultiplayer() then
				comUnit:sendNetworkSyncSafe("upgrade2","1")
			end
			boostedOnLevel = upgrade.getLevel("upgrade")
			upgrade.upgrade("boost")
			model:getMesh("boost"):setVisible( true )
			--model:getMesh("notBoosted"):setVisible( false )
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
	function self.handleUpgradeBurnDamage(param)
		if tonumber(param)>upgrade.getLevel("burnDamage") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("burnDamage")
		elseif upgrade.getLevel("burnDamage")>tonumber(param) then
			model:getMesh("speed"..upgrade.getLevel("burnDamage")):setVisible(false)
			upgrade.degrade("burnDamage")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade4",tostring(param))
		end
		if upgrade.getLevel("burnDamage")>0 then
			doMeshUpgradeForLevel("burnDamage","speed")
			--Achievement
			if upgrade.getLevel("burnDamage")==3 then
				comUnit:sendTo("SteamAchievement","Fire","")
			end
		end
		setCurrentInfo()
	end
	function self.handleUpgradeFuel(param)
		if tonumber(param)>upgrade.getLevel("fuel") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("fuel")
		elseif upgrade.getLevel("fuel")>tonumber(param) then
			model:getMesh("fuel"..upgrade.getLevel("fuel")):setVisible(false)
			upgrade.degrade("fuel")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade5",tostring(param))
		end
		if upgrade.getLevel("fuel")>0 then
			doMeshUpgradeForLevel("fuel","fuel")
			--Achievement
			if upgrade.getLevel("fuel")==3 then
				comUnit:sendTo("SteamAchievement","FireDPS","")
			end
		end
		setCurrentInfo()
	end
	function self.handleUpgradeRange(param)
		if tonumber(param)>upgrade.getLevel("range") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("range")
		elseif upgrade.getLevel("range")>tonumber(param) then
			upgrade.degrade("range")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade3",tostring(param))
		end
		if upgrade.getLevel("range")==0 then
			--no mesh in use
		else
			--no mesh in use
			--Acievement
			if upgrade.getLevel("range")==3 then
				comUnit:sendTo("SteamAchievement","Range","")
			end
		end
		setCurrentInfo()
	end
	function self.update()

		if upgrade.update() then
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
		reloadTimeLeft = reloadTimeLeft - Core.getDeltaTime()
		
		local bLevel = upgrade.getLevel("boost")
		fireCenter:setScale(1.0+(bLevel*0.4))
		pointLight:setRange(1.25+(bLevel))
		
		--change update speed
--		local tmpCameraNode = cameraNode
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 25) * 2)
--		print("state "..state)
--		print("Hz: "..((state == 2) and 60.0 or (state == 1 and 30 or 10)))
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end
		
		--debug
		if targetSelector.getTargetIfAvailable()>0 then
			myStats.activeTimer = myStats.activeTimer + Core.getDeltaTime()
		end
		--
		
		--update pushPiston()
		for index = 1, 4, 1 do
			if piston[index].timer>0.0 then
				local aPiston = piston[index]
				aPiston.timer = aPiston.timer - Core.getDeltaTime()
				--0% == that the piston is ready to be pushed down
				local per = aPiston.timer/aPiston.timerStart
				per = per<0.0 and 0.0 or per
				per = aPiston.pistonGoingDown and 1.0-per or per
				aPiston.mesh:setLocalPosition( aPiston.atVec*((0.7)+(per*(-0.21))) )
				if aPiston.timer<=0.0 then
					if aPiston.pistonGoingDown==false then
					else
						pushPiston(index,false)
					end
				end
			end
		end
		--piston[index]:setLocalPosition( pistonAtVec[index]*((0.7)+(per*(-0.16))) )
		if reloadTimeLeft<0.0 and updateTarget() and billboard:getBool("isNetOwner") then
			attack()--can now attack
			upgrade.setUsed()--set value changed
		end
		--
		projectiles.update()
		--Achievements
		if projectiles.getSize()>=12 then
			comUnit:sendTo("SteamAchievement","SwarmBall","")
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
		--this:setIsStatic(true)
		Core.setUpdateHz(60.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		if xpManager then
			xpManager.setUpgradeCallback(self.handleUpgrade)
		end
		
		restartListener = Listener("RestartWave")
		restartListener:registerEvent("restartWave", restartWave)
	
		model = Core.getModel("tower_swarm_l1.mym")
		local hullModel = Core.getModel("tower_resource_hull.mym")
		this:addChild(model)
	
		if particleEffectUpgradeAvailable then
			this:addChild(particleEffectUpgradeAvailable)
		end
	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug myStats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),3.0,"shockwave","")
	
		billboard:setDouble("rangePerUpgrade",0.75)
		billboard:setString("hullName","hull")
		billboard:setVectorVec3("hull3d",createHullList3d(hullModel:getMesh("hull")))
		billboard:setVectorVec2("hull2d",createHullList2d(hullModel:getMesh("hull")))
		billboard:setModel("tower",model)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Swarm tower")
		billboard:setString("FileName", "Tower/SwarmTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
	
		--ComUnitCallbacks
		comUnitTable["swarmBallHitt"] = swarmBallHitt
		comUnitTable["dmgDealt"] = damageDealt
		comUnitTable["waveChanged"] = waveChanged
		comUnitTable["upgrade1"] = self.handleUpgrade
		comUnitTable["upgrade2"] = self.handleBoost
		comUnitTable["upgrade3"] = self.handleUpgradeRange
		comUnitTable["upgrade4"] = self.handleUpgradeBurnDamage
		comUnitTable["upgrade5"] = self.handleUpgradeFuel
		comUnitTable["NetOwner"] = setNetOwner
		comUnitTable["NetLaunch"] = NetLaunch
		comUnitTable["NetBall"] = NetBall
		comUnitTable["SetTargetMode"] = self.SetTargetMode
		supportManager.setComUnitTable(comUnitTable)
		supportManager.addCallbacks()
	
		upgrade.setBillboard(billboard)
		upgrade.addDisplayStats("damage")
		upgrade.addDisplayStats("fireDPS")
		upgrade.addDisplayStats("burnTime")
		upgrade.addDisplayStats("range")
		--upgrade.addDisplayStats("weaken")
		upgrade.addBillboardStats("fireballSpeed")
		upgrade.addBillboardStats("fireballLifeTime")
		upgrade.addBillboardStats("detonationRange")
		--upgrade.addBillboardStats("targetingSystem")
		
		
	
		--default fireball does ruffly 3 attacks, before death, with 3s bettween attacks after the first
		--25% damage bonus, because damage over time
		--one attack every 3.1s
		upgrade.addUpgrade( {	cost = 200,
								name = "upgrade",
								info = "swarm tower level",
								order = 1,
								icon = 56,
								value1 = 1,
								stats ={range =				{ upgrade.add, 6.5},
										damage = 			{ upgrade.add, 100},--120
										fireDPS = 			{ upgrade.add, 50},--60
										burnTime = 			{ upgrade.add, 2.0},
										burnTimeMul =		{ upgrade.add, 1.0},
										fireballSpeed = 	{ upgrade.add, 5.5},
										fireballLifeTime = 	{ upgrade.add, 13.0},
										fieringTime =		{ upgrade.add, 2.25},
										detonationRange = 	{ upgrade.add, 0.5},
										targeting = 		{ upgrade.add, 1},
										model = 			{ upgrade.set, "tower_swarm_l1.mym"} }
							} )
		--theoreticalMaxDPSPG = activeProjectiles*DPS/cost = (fireballLifeTime/fieringTime)*((damage+(fireDPS*fieringTime))/averageHittTime)/cost = (13/2)*((110+(55*2))/3)/200 = 2.38
		--actualActiveProjectilePer = 0.5, actualHittsPerProjectile = 3 = efficency = (3*3)/13 = 0.69
		--bestEstimateDPSPG = (13/2)*0.5*((108+(54*2))/3)*0.69/200 = 0.81
		
	
		upgrade.addUpgrade( {	cost = 400,
								name = "upgrade",
								info = "swarm tower level",
								order = 1,
								icon = 56,
								value1 = 2,
								stats ={range =				{ upgrade.add, 6.5},
										damage = 			{ upgrade.add, 308},
										fireDPS = 			{ upgrade.add, 154},
										burnTime = 			{ upgrade.add, 2.0},
										burnTimeMul =		{ upgrade.add, 1.0},
										fireballSpeed = 	{ upgrade.add, 5.5},
										fireballLifeTime = 	{ upgrade.add, 13.0},
										fieringTime =		{ upgrade.add, 2.25},
										detonationRange = 	{ upgrade.add, 1.0},
										targeting = 		{ upgrade.add, 1.0},
										model = 			{ upgrade.set, "tower_swarm_l2.mym"}}
							},0 )
		--bestEstimateDPSPG = (13/2)*0.5*((350+(175*2))/3)*0.69/600 = 0.82
		upgrade.addUpgrade( {	cost = 800,
								name = "upgrade",
								info = "swarm tower level",
								order = 1,
								icon = 56,
								value1 = 3,
								stats ={range =				{ upgrade.add, 6.5},
										damage = 			{ upgrade.add, 736},
										fireDPS = 			{ upgrade.add, 368},
										burnTime = 			{ upgrade.add, 2.0},
										burnTimeMul =		{ upgrade.add, 1.0},
										fireballSpeed = 	{ upgrade.add, 5.5},
										fireballLifeTime = 	{ upgrade.add, 13.0},
										fieringTime =		{ upgrade.add, 2.25},
										detonationRange = 	{ upgrade.add, 1.5},
										targeting = 		{ upgrade.add, 1.0},
										model = 			{ upgrade.set, "tower_swarm_l3.mym"}}
							},0 )
		--bestEstimateDPSPG = (13/2)*0.5*((790+(395*2))/3)*0.69/1400 = 0.84
		function boostDamage() return upgrade.getStats("damage")*2.0*(waveCount/25+1.0) end
		function boostFireDamage() return upgrade.getStats("fireDPS")*2.0*(waveCount/25+1.0) end
		--(total)	0=2x	25=4x	50=6x
		upgrade.addUpgrade( {	cost = 0,
								name = "boost",
								info = "swarm tower boost",
								duration = 10,
								cooldown = 3,
								order = 10,
								icon = 57,
								stats ={range =				{ upgrade.add, 0.5},
										damage = 			{ upgrade.func, boostDamage},
										fireDPS = 			{ upgrade.func, boostFireDamage},
										fieringTime =		{ upgrade.set, 0.55}}
							} )
		-- RANGE
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 0 or 100,
								name = "range",
								info = "swarm tower range",
								order = 2,
								icon = 59,
								value1 = 6.5 + 0.75,
								levelRequirement = cTowerUpg.getLevelRequierment("range",1),
								stats = {range = 		{ upgrade.add, 0.75, ""}}
							} )
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 100 or 200,
								name = "range",
								info = "swarm tower range",
								order = 2,
								icon = 59,
								value1 = 6.5 + 1.5,
								levelRequirement = cTowerUpg.getLevelRequierment("range",2),
								stats = {range = 		{ upgrade.add, 1.5, ""}}
							} )
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 200 or 300,
								name = "range",
								info = "swarm tower range",
								order = 2,
								icon = 59,
								value1 = 6.5 + 2.25,
								levelRequirement = cTowerUpg.getLevelRequierment("range",3),
								stats = {range = 		{ upgrade.add, 2.25, ""}}
							} )
		-- Burn
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "burnDamage",
								info = "swarm tower damage",
								order = 3,
								icon = 2,
								value1 = 30,
								levelRequirement = cTowerUpg.getLevelRequierment("burnDamage",1),
								stats ={damage =	{ upgrade.mul, 1.3} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "burnDamage",
								info = "swarm tower damage",
								order = 3,
								icon = 2,
								value1 = 60,
								levelRequirement = cTowerUpg.getLevelRequierment("burnDamage",2),
								stats ={damage =	{ upgrade.mul, 1.6} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "burnDamage",
								info = "swarm tower damage",
								order = 3,
								icon = 2,
								value1 = 90,
								levelRequirement = cTowerUpg.getLevelRequierment("burnDamage",3),
								stats ={damage =	{ upgrade.mul, 1.9} }
							} )
		-- fuel
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fuel",
								info = "swarm tower fire",
								order = 4,
								icon = 38,
								value1 = 22,
								value2 = 15,
								levelRequirement = cTowerUpg.getLevelRequierment("fuel",1),
								stats ={fireDPS =		{ upgrade.mul, 1.22},
										burnTimeMul =	{ upgrade.add, 0.15} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fuel",
								info = "swarm tower fire",
								order = 4,
								icon = 38,
								value1 = 38,
								value2 = 30,
								levelRequirement = cTowerUpg.getLevelRequierment("fuel",2),
								stats ={fireDPS =		{ upgrade.mul, 1.38},
										burnTimeMul =	{ upgrade.add, 0.30,} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fuel",
								info = "swarm tower fire",
								order = 4,
								icon = 38,
								value1 = 52,
								value2 = 45,
								levelRequirement = cTowerUpg.getLevelRequierment("fuel",3),
								stats ={fireDPS =		{ upgrade.mul, 1.52},
										burnTimeMul =	{ upgrade.add, 0.45,} }
							} )
		-- to calculate values together
		function burnTimeCalc() return upgrade.getStats("burnTime") * upgrade.getStats("burnTimeMul") end
		upgrade.addUpgrade( {	cost = 0,
								name = "calculate",
								info = "calc",
								order = 11,
								icon = 62,
								stats = {	burnTime =	{ upgrade.func, burnTimeCalc} }
							} )
		supportManager.setUpgrade(upgrade)
		supportManager.addHiddenUpgrades()
		supportManager.addSetCallbackOnChange(updateStats)
	
		upgrade.upgrade("upgrade")
		upgrade.upgrade("calculate")
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		billboard:setString("targetMods","attackPriorityTarget;attackClosestToExit;attackWeakestTarget;attackStrongestTarget")
		billboard:setInt("currentTargetMode",1)
	
		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(upgrade.getValue("range"))
	
		initModel()
		setCurrentInfo()
	
		myStatsReset()
		
		cTowerUpg.addUpg("range",self.handleUpgradeRange)
		cTowerUpg.addUpg("burnDamage",self.handleUpgradeBurnDamage)
		cTowerUpg.addUpg("fuel",self.handleUpgradeFuel)
		cTowerUpg.fixAllPermBoughtUpgrades()
	
		--ParticleEffects
		this:addChild( fireCenter )
		fireCenter:activate(Vec3(0.0,1.9,0.0))
		pointLight = PointLight(Vec3(0,2.45,0),Vec3(5,2.5,0.0),1.25)
		this:addChild(pointLight)
		
		return true
	end
	init()
	function self.destroy()
		projectiles.destroy()
	end
	--
	return self
end

function create()
	swarmTower = SwarmTower.new()
	update = swarmTower.update
	destroy = swarmTower.destroy
	return true
end