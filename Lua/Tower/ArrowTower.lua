require("Tower/rotator.lua")
require("Tower/upgrade.lua")
require("Tower/xpSystem.lua")
require("Tower/supportManager.lua")
require("NPC/state.lua")
require("stats.lua")
require("Projectile/projectileManager.lua")
require("Projectile/Arrow.lua")
require("Projectile/ArrowMortar.lua")
require("Game/campaignTowerUpg.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
--this = SceneNode()
ArrowTower = {}
function ArrowTower.new()
	local self = {}
	local myStats = {}
	local myStatsTimer = 0
	local waveCount = 0
	local projectiles = projectileManager.new()
	local tStats = Stats.new()
	local cData = CampaignData.new()
	local upgrade = Upgrade.new()
	local supportManager = SupportManager.new()
	local cTowerUpg = CampaignTowerUpg.new("Tower/ArrowTower.lua",upgrade)
	local rotator = Rotator.new()
	--XP
	local xpManager = XpSystem.new(upgrade)
	--constants
	local RECOIL_ON_ATTACK = math.pi/18.0	 	 --default kickback
	local SCOPE_ROTATION_ON_BOOST = math.pi*30/180 --rotation to avoid ammo coger when boost is activated
	--Model
	local model
	local rotaterMesh
	local crossbowMesh
	local defaultPlatformRotMeshMatrix
	local defaultRotaterMeshMatrix
	--Sound
	local soundNode
	--attack
	local targetMode = 1
	local activeProjectile = "Arrow"
	local activeProjectileBoost = "ArrowMortar"
	local reloadTime = 0.0
	local reloadTimeLeft = 0.0
	local boostedOnLevel = 0
	--Upgrades
	local reRotateTowerCostMultiplyer = 0   
	local isSettingRotation = 0.0
	--effects
	--Comunication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local billboardWaveStats = Core.getGameSessionBillboard( "tower_"..Core.getNetworkName() )
	--Events
	--Other
	local syncTimer = 0.0
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local visibleState = 2
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this	
	local lastRestored = -1
	--stats
	local mapName = MapInfo.new().getMapName()
	--
	local function storeWaveChangeStats( waveStr )
		--update wave stats only if it has not been set (this function will be called on wave changes when going back in time)
		if billboardWaveStats:exist( waveStr )==false then
			local tab = {
				xpTab = xpManager and xpManager.storeWaveChangeStats() or nil,
				upgradeTab = upgrade.storeWaveChangeStats(),
				DamagePreviousWave = billboard:getDouble("DamagePreviousWave"),
				DamagePreviousWavePassive = billboard:getDouble("DamagePreviousWavePassive"),
				DamageTotal = billboard:getDouble("DamageTotal"),
				currentTargetMode = billboard:getInt("currentTargetMode")
			}
			billboardWaveStats:setTable( waveStr, tab )
		end
	end
	local function restoreWaveChangeStats( wave )
		if wave>0 then
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
				billboard:setDouble("DamagePreviousWave", tab.DamagePreviousWave)
				billboard:setDouble("DamageCurrentWave", tab.DamagePreviousWave)
				billboard:setDouble("DamagePreviousWavePassive", tab.DamagePreviousWavePassive)
				billboard:setDouble("DamageTotal", tab.DamageTotal)
				self.SetTargetMode(tab.currentTargetMode)
				if xpManager then
					xpManager.restoreWaveChangeStats(tab.xpTab)
				end
				upgrade.restoreWaveChangeStats(tab.upgradeTab)
			end
		end
	end
	--
	local function myStatsReset()
		if myStats.dmgDone then
			billboard:setDouble("DamagePreviousWave",myStats.dmgDone)
			billboard:setDouble("DamagePreviousWavePassive",myStats.dmgDoneMarkOfDeath or 0.0)
			billboard:setDouble("DamageTotal",billboard:getDouble("DamageTotal")+myStats.dmgDone)
			comUnit:sendTo("stats", "addTotalDmg", myStats.dmgDone+(myStats.dmgDoneMarkOfDeath or 0.0) )
		end
		myStats = {	activeTimer=0.0,
					hitts=0,
					attacks=0,	
					dmgDone=0,
					dmgDoneMarkOfDeath=0,
					dmgLost=0,
					retargeted=0,
					disqualified=false}
		myStatsTimer = Core.getGameTime()
	end
	local function restartWave(param)
		projectiles.clear()
		restoreWaveChangeStats( tonumber(param) )
	end
	local function damageDealt(param)
		local addDmg = supportManager.handleSupportDamage( tonumber(param) )
		myStats.hitts = myStats.hitts + 1
		myStats.dmgDone = myStats.dmgDone + addDmg
		billboard:setDouble("DamageCurrentWave",myStats.dmgDone)
		billboard:setDouble("DamageCurrentWavePassive",myStats.dmgDoneMarkOfDeath or 0.0)
		if xpManager then
			xpManager.addXp(addDmg)
			local interpolation  = xpManager.getLevelPercentDoneToNextLevel()
			upgrade.setInterpolation(interpolation)
			upgrade.fixBillboardAndStats()
		end
	end
	local function dmgDealtMarkOfDeath(param)
		if xpManager then
			xpManager.addXp(tonumber(param))
		end
		myStats.dmgDoneMarkOfDeath = myStats.dmgDoneMarkOfDeath + tonumber(param)
	end
	local function damageLost(param)
		myStats.dmgLost = myStats.dmgLost + tonumber(param)
	end
	local function retargeted(param)
		myStats.retargeted = myStats.retargeted + 1
	end
	local function waveChanged(param)
		local name
		local waveCount
		name,waveCount = string.match(param, "(.*);(.*)")
		--update and save stats only if we did not just restore this wave
		if tonumber(waveCount)>=lastRestored then
			if not xpManager then
				--
				if myStats.disqualified==false and upgrade.getLevel("boost")==0  and Core.getGameTime()-myStatsTimer>0.25 and myStats.activeTimer>1.0  then
					myStats.disqualified=nil
					myStats.DPS = myStats.dmgDone/myStats.activeTimer
					myStats.DPSpG = myStats.DPS/upgrade.getTotalCost()
					myStats.DPG = myStats.dmgDone/upgrade.getTotalCost()
					if upgrade.getLevel("markOfDeath")>0 then
						myStats.DPSTmod = (myStats.dmgDone+myStats.dmgDoneMarkOfDeath)/myStats.activeTimer
						myStats.DPSpGTmod = (myStats.dmgDone+myStats.dmgDoneMarkOfDeath)/upgrade.getTotalCost()
						myStats.DPGTmod = (myStats.dmgDone+myStats.dmgDoneMarkOfDeath)/upgrade.getTotalCost()
					end
					--damage lost
					if myStats.attacks>myStats.hitts then
						if upgrade.getLevel("hardArrow")>0 then
							myStats.dmgLost = myStats.dmgLost + ((upgrade.getValue("damage"))*(myStats.attacks-myStats.hitts))
						else
							myStats.dmgLost = myStats.dmgLost + (upgrade.getValue("damage")*(myStats.attacks-myStats.hitts))
						end
					end
					myStats.dmgLostPer = myStats.dmgLost/(myStats.dmgDone+myStats.dmgLost)
					myStats.DPSpGWithDamageLostInc = (myStats.DPS+(myStats.dmgLost/myStats.activeTimer))/upgrade.getTotalCost()
					myStats.dmgLost = nil
					--
					local key = "range"..upgrade.getLevel("range").."_hardArrow"..upgrade.getLevel("hardArrow").."_markOfDeath"..upgrade.getLevel("markOfDeath")
					tStats.addValue({mapName,"wave"..name,"arrowTower_l"..upgrade.getLevel("upgrade"),key,"sampleSize"},1)
					for variable, value in pairs(myStats) do
						tStats.setValue({mapName,"wave"..name,"arrowTower_l"..upgrade.getLevel("upgrade"),key,variable},value)
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
	
	local function resetModel()
		for index =1, 3, 1 do
			model:getMesh( string.format("scope%d", index) ):setVisible( upgrade.getLevel("range")==index )
			model:getMesh( string.format("flamer%d", index) ):setVisible( false )
			model:getMesh( string.format("markForDeath%d", index) ):setVisible( upgrade.getLevel("markOfDeath")==index )
		end
		model:getMesh( "masterAim" ):setVisible(false)
		model:getMesh( "physic" ):setVisible(false)
		model:getMesh( "hull" ):setVisible(false)
		model:getMesh( "space0" ):setVisible(false)
	
		local showBoostActive = (upgrade.getLevel("boost")>0)
		model:getMesh( "ammoDrumBoost" ):setVisible(showBoostActive)
		model:getMesh( "ammoDrum" ):setVisible(not showBoostActive)
		--Meshes
		rotaterMesh = model:getMesh( "rotater" )
		crossbowMesh = model:getMesh( "crossbow" )
		crossbowMesh:setLocalPosition(Vec3(0.0,0.0,0.44))
		
		defaultPlatformRotMeshMatrix = defaultPlatformRotMeshMatrix or model:getMesh( "rotaterBase" ):getGlobalMatrix()
		defaultRotaterMeshMatrix = defaultRotaterMeshMatrix or rotaterMesh:getLocalMatrix()
	
		--init the crossbow (instant reload)
		
		model:getAnimation():play("init",1.0,PlayMode.stopSameLayer)
		reloadTimeLeft  = 0.0
		
		--performance check
		for i=0, model:getNumMesh()-1, 1 do
			if not model:getMesh(i):getName():toString()=="tower" then
				model:getMesh(i):DisableBoundingVolumesDynamicUpdates()
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
		if myStats.activeTimer and myStats.activeTimer>0.0001 then
			myStats.disqualified = true
		end
		--xpToLevel	   = 1000.0*(1.5^level)
		--range	 	  = upgrade.getValue("range")--info[upgradeLevel]["range"]*(1.025^level)*upgradeScopeRangeMultiplayer
		--dmg	 		= upgrade.getValue("Damage")--info[upgradeLevel]["dmg"]*(1.02^level)
		--reloadTime	  = 1.0/upgrade.getValue("RPS")--info[upgradeLevel]["reloadTime"]*(0.99^level)	
		model:getAnimation():play("init",1.0,PlayMode.stopSameLayer)
		billboard:setDouble("hittStrength",upgrade.getLevel("upgrade")+(upgrade.getLevel("hardArrow")>0 and 1 or 0)+(upgrade.getLevel("boost")>0 and 1 or 0))
		reloadTimeLeft  = 0.0
		updateStats()
		--achivment
		if upgrade.getLevel("upgrade")==3 and upgrade.getLevel("range")==3 and upgrade.getLevel("hardArrow")==3 and upgrade.getLevel("markOfDeath")==3 then
			comUnit:sendTo("SteamAchievement","CrossbowMaxed","")
		end
	end
	local function setTargetAreaOffset(tabStr)
		local tab = totable(tabStr)
		billboard:setMatrix("TargetAreaOffset", tab.mat)
	end
	local function setRotateTarget(globalVec)
		if globalVec:sub(1,1)==":" then
			globalVec = globalVec:sub(2)
		else
			if Core.isInMultiplayer() and billboard:getBool("isNetOwner") then
				comUnit:sendNetworkSyncSafe("setRotateTarget",":"..globalVec)
				local tab = {mat=billboard:getMatrix("TargetAreaOffset")}
				comUnit:sendNetworkSyncSafe("setTargetAreaOffset",tabToStrMinimal(tab))
			end
		end
		
		local x,y,z = globalVec:match("(.*),(.*),(.*)")
		local rotMesh = model:getMesh( "rotaterBase" )
		local globalMat = Matrix()
		
		isSettingRotation = Core.getTime()
		
		if update==self.updateReal then
			update = self.updateRotate
		end
	
		local rotMeshParent = rotMesh:getParent()
		local rotMeshParentGIMatrix = rotMeshParent:getGlobalMatrix():inverseM()
		local vector = rotMeshParentGIMatrix * Vec4( tonumber(x),0,tonumber(z), 0)
		globalMat:createMatrix( Vec3(0,0,1), Vec3(-vector.x, vector.z, 0) )
		--set matrix for platform
		rotMesh:setLocalMatrix(rotMeshParentGIMatrix * (defaultPlatformRotMeshMatrix * globalMat))
		--set matrix for rotater on platform
		rotaterMesh:setLocalMatrix(defaultRotaterMeshMatrix)
		
		local pipeAt = -crossbowMesh:getGlobalMatrix():getUpVec():normalizeV()
		local angleLimit = upgrade.getValue("targetAngle")
		targetSelector.setAngleLimits(pipeAt,angleLimit)
		rotator.setHorizontalLimits(pipeAt,-angleLimit,angleLimit)
	
		reloadTimeLeft = (reloadTimeLeft>0.25) and reloadTimeLeft or 0.25--0.25 is the inactivity time when changing rotation of the tower
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
			local rotaterMatrix = rotaterMesh:getLocalMatrix()--get rotation for rotater
			local crossbowMatrix = crossbowMesh:getLocalMatrix()--get rotation for engine
			local rotaterBaseMatrix = model:getMesh( "rotaterBase" ):getLocalMatrix()
		
			this:removeChild(model)
			model = Core.getModel( string.format("tower_crossbow_l%d.mym", upgrade.getLevel("upgrade")) )
			this:addChild(model)
			billboard:setModel("tower",model);
		
			resetModel()--resets the model and reload time
			--model:setIsStatic(true)
			--model:render()
			rotaterMesh:setLocalMatrix(rotaterMatrix)--set the old rotation
			crossbowMesh:setLocalMatrix(crossbowMatrix)--set the old rotation
			model:getMesh( "rotaterBase" ):setLocalMatrix(rotaterBaseMatrix)
		
			if upgrade.getLevel("boost")>0 and upgrade.getLevel("range")>0 then
				model:getMesh("scope"..upgrade.getLevel("range")):rotate(Vec3(0.0, 1.0, 0.0), SCOPE_ROTATION_ON_BOOST)
			end
		
			--instant reload
			reloadTimeLeft = 0.0
			--visual changes
			RECOIL_ON_ATTACK = RECOIL_ON_ATTACK*1.15
			--
			cTowerUpg.fixAllPermBoughtUpgrades()
		end
		upgrade.clearCooldown()
		setCurrentInfo()
	end
	local function handleBoost(param)
		if tonumber(param)>upgrade.getLevel("boost") then
			if Core.isInMultiplayer() then
				comUnit:sendNetworkSyncSafe("upgrade2","1")
			end
			boostedOnLevel = upgrade.getLevel("upgrade")
			upgrade.upgrade("boost")
			setCurrentInfo()
			model:getMesh( "ammoDrumBoost" ):setVisible(true)
			model:getMesh( "ammoDrum" ):setVisible(false)
			if upgrade.getLevel("range")>0 then
				model:getMesh("scope"..upgrade.getLevel("range")):rotate(Vec3(0.0, 1.0, 0.0), SCOPE_ROTATION_ON_BOOST)
			end
			--Achievement
			comUnit:sendTo("SteamAchievement","Boost","")
		elseif upgrade.getLevel("boost")>tonumber(param) then
			upgrade.degrade("boost")
			resetModel()
			setCurrentInfo()
			--only boost that uses timer
			if upgrade.getLevel("range")>0 then
		 	   model:getMesh("scope"..upgrade.getLevel("range")):rotate(Vec3(0.0, 1.0, 0.0), -SCOPE_ROTATION_ON_BOOST)
			end
			--clear coldown info for boost upgrade
			upgrade.clearCooldown()
		else
			return--level unchanged
		end
	end
	local function handleUpgradeScope(param)
		if tonumber(param)>upgrade.getLevel("range") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("range")
		elseif upgrade.getLevel("range")>tonumber(param) then
			model:getMesh("scope"..upgrade.getLevel("range")):setVisible(false)
			upgrade.degrade("range")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade3",tostring(param))
		end
		if upgrade.getLevel("range")>0 then
			model:getMesh("scope"..upgrade.getLevel("range")):setVisible(true)
			if upgrade.getLevel("range")>1 then
				model:getMesh("scope"..upgrade.getLevel("range")-1):setVisible(false)
			end
			if upgrade.getLevel("boost")>0 then
				model:getMesh("scope"..upgrade.getLevel("range")):rotate(Vec3(0.0, 1.0, 0.0), SCOPE_ROTATION_ON_BOOST)
			end			
			--Acievement
			if upgrade.getLevel("range")==3 then
				comUnit:sendTo("SteamAchievement","Range","")
			end
		end
		setCurrentInfo()
	end
	local function handleFireball(param)
		if tonumber(param)>upgrade.getLevel("hardArrow") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("hardArrow")
		elseif upgrade.getLevel("hardArrow")>tonumber(param) then
			upgrade.degrade("hardArrow")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade4",tostring(param))
		end
		if upgrade.getLevel("hardArrow")==0 then
			--no mesh in use
		else
			--no mesh in use
			--Achievement
			if upgrade.getLevel("hardArrow")==3 then
				comUnit:sendTo("SteamAchievement","HardArrow","")
			end
		end
		setCurrentInfo()
	end
	local function handleRotate(param)
--		if param==nil or (type(param)=="string" and param=="") then
--			comUnit:sendNetworkSyncSafe("upgrade6","1")
--		end
		reRotateTowerCostMultiplyer = reRotateTowerCostMultiplyer + 1
		upgrade.fixBillboardAndStats()
		this:loadLuaScript("Game/buildRotater.lua")
	end
	local function handleWeakenTarget(param)
		if tonumber(param)>upgrade.getLevel("markOfDeath") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("markOfDeath")
		elseif upgrade.getLevel("markOfDeath")>tonumber(param) then
			model:getMesh("markForDeath"..upgrade.getLevel("markOfDeath")):setVisible(false)
			upgrade.degrade("markOfDeath")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade5",tostring(param))
		end
		if upgrade.getLevel("markOfDeath")>0 then
			if upgrade.getLevel("markOfDeath")>1 then
				model:getMesh("markForDeath"..upgrade.getLevel("markOfDeath")-1):setVisible(false)
			end
			model:getMesh("markForDeath"..upgrade.getLevel("markOfDeath")):setVisible(true)
			if upgrade.getLevel("markOfDeath")==3 then
				comUnit:sendTo("SteamAchievement","MarkOfDeath","")
			end
		end
		setCurrentInfo()
	end
	local function attack()
		local target = targetSelector.getTargetIfAvailable()
		if target>0 then
			local bulletStartPos = crossbowMesh:getGlobalMatrix()*Vec3(0.0,-1.15,0.0)
			local pipeAt = -crossbowMesh:getGlobalMatrix():getUpVec():normalizeV()
			billboard:setVec3("bulletStartPos",bulletStartPos)
			billboard:setVec3("pipeAtVector",pipeAt)
			billboard:setInt("targetIndex",target)
			
			--set reload timer
			if reloadTimeLeft<-Core.getDeltaTime() then
				reloadTimeLeft = (1.0/upgrade.getValue("RPS"))--if we are over due for fiering(reloading timer is past this frame)
			else
				reloadTimeLeft = reloadTimeLeft + (1.0/upgrade.getValue("RPS"))--if we was supposed to fire this frame just add reload timer
			end
		
			myStats.attacks = myStats.attacks + 1
		
			local projectile = "Arrow"
			if upgrade.getLevel("boost")>0 then
				projectiles.launch(ArrowMortar,{})
			else 
				projectiles.launch(Arrow,{})
			end
			
			local animationSpeed = model:getAnimation():getLengthOfClip("attack")/reloadTimeLeft
			model:getAnimation():play("attack",animationSpeed,PlayMode.stopSameLayer)
			crossbowMesh:rotate(Vec3(1.0, 0.0, 0.0),RECOIL_ON_ATTACK )--add some recoil for more kick in the tower
			
--			if upgrade.getValue("smartTargeting")>0.5 then
--				targetSelector.deselect()
--			end
			
			soundNode:play(1.1,false)
		end
	end
	local function NetSyncTarget(param)
		local target = tonumber(Core.getIndexOfNetworkName(param))
		if target>0 then
			targetSelector.setTarget(target)
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
		--only select new target if we own the tower or we are not told anything usefull
		if (billboard:getBool("isNetOwner") or targetSelector.getTargetIfAvailable()==0) then
			local previousTarget = targetSelector.getTarget()
			if targetSelector.selectAllInRange() then
				targetSelector.filterOutState(state.ignore)
				if targetMode==1 then
					--priority targets
					targetSelector.scoreHP(20)
					targetSelector.scoreName("dino",10)
					targetSelector.scoreName("turtle",20)
					targetSelector.scoreName("reaper",25)
					targetSelector.scoreState(state.shielded,-10)	--decreased damage against this target
					targetSelector.scoreName("skeleton_cf",-20)
					targetSelector.scoreName("skeleton_cb",-20)
					
					if upgrade.getLevel("markOfDeath")>0 then
						targetSelector.scoreState(state.markOfDeath,-10)	--because we placed the mark, it is therefore better to mark another unit
					else
						targetSelector.scoreState(state.markOfDeath,10)		--attack marked unit for damage bonus
					end
				elseif targetMode==2 then
					--closest to exit
					targetSelector.scoreClosestToExit(40)
					targetSelector.scoreState(state.markOfDeath,10)
					targetSelector.scoreHP(-10)
				elseif targetMode==3 then
					--attackWeakestTarget
					targetSelector.scoreHP(-30)
					targetSelector.scoreClosestToExit(20)
					targetSelector.scoreName("skeleton_cf",-10)
					targetSelector.scoreName("skeleton_cb",-10)
					targetSelector.scoreState(state.markOfDeath,15)	
				elseif targetMode==4 then
					--attackStrongestTarget
					targetSelector.scoreHP(30)
					targetSelector.scoreState(state.markOfDeath,10)
					targetSelector.scoreName("reaper",15)
					targetSelector.scoreName("skeleton_cf",-20)
					targetSelector.scoreName("skeleton_cb",-20)
				end
				
				if upgrade.getLevel("hardArrow")>0 then
					targetSelector.scoreHP(20)--we realy want to shoot the strongest unit
				end
				targetSelector.scoreState(state.highPriority,30)
				
				targetSelector.selectTargetAfterMaxScore()
			end
			if billboard:getBool("isNetOwner") then
				local newTarget = targetSelector.getTargetIfAvailable()
				if newTarget>0 then
					comUnit:sendNetworkSync("NetTarget", Core.getNetworkNameOf(newTarget))
				end
			end
		end
	end
	local function handleRetarget()
		targetSelector.deselect()
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
	function self.updateRotate()
	
		--update time based upgrades
		if upgrade.update() then
			resetModel()
			setCurrentInfo()
			--only boost that uses timer
			if upgrade.getLevel("range")>0 then
		 	   model:getMesh("scope"..upgrade.getLevel("range")):rotate(Vec3(0.0, 1.0, 0.0), -SCOPE_ROTATION_ON_BOOST)
			end
			--if the tower was upgraded while boosted, then the boost should be available
			if boostedOnLevel~=upgrade.getLevel("upgrade") then
				upgrade.clearCooldown()
			end
		end
	
		--Handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
		 	   comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
	
		if Core.getTime()-isSettingRotation>0.5 then
			update = self.updateReal
		end
		model:getAnimation():update(Core.getDeltaTime())
		--model:render()
		return true;
	end
	function self.updateReal()
		--update time based upgrades
		if upgrade.update() then
			resetModel()
			setCurrentInfo()
			--only boost that uses timer
			if upgrade.getLevel("range")>0 then
		 	   model:getMesh("scope"..upgrade.getLevel("range")):rotate(Vec3(0.0, 1.0, 0.0), -SCOPE_ROTATION_ON_BOOST)
			end
			--if the tower was upgraded while boosted, then the boost should be available
			if boostedOnLevel~=upgrade.getLevel("upgrade") then
				upgrade.clearCooldown()
			end
		end
		if xpManager then
			xpManager.update()
		end
		--change update speed
--		local tmpCameraNode = cameraNode
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 20) * 2)
--		print("state "..state)
--		print("Hz: "..((state == 2) and 60.0 or (state == 1 and 30 or 10)))
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end
		
		--Handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
		 	   comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		reloadTimeLeft = reloadTimeLeft - Core.getDeltaTime()
		local pipeAt = -crossbowMesh:getGlobalMatrix():getUpVec():normalizeV()
		--find new target if target is unavailable
		updateTarget()
		if targetSelector.getTargetIfAvailable()>0 then
			updateSync()
			--debug
			myStats.activeTimer = myStats.activeTimer + Core.getDeltaTime()
			--debug
			local targetAt = targetSelector.getTargetPosition()-crossbowMesh:getGlobalPosition()
			--rotate pipe toward the target
			rotator.setFrameDataTargetAndUpdate(targetAt,pipeAt)
			rotaterMesh:rotate(Vec3(0.0,0.0,1.0), rotator.getHorizontalRotation())
			crossbowMesh:rotate(Vec3(1.0, 0.0, 0.0), rotator.getVerticalRotation())
			if reloadTimeLeft<0.0 then
				local npcSize = 1.75
				local FireMinAngle = math.pi*0.025--math.max(math.abs(math.atan2(npcSize, targetAt:normalize())), 0.025)
				local targetAngleDiffXZ = math.abs( Vec2(targetAt.x, targetAt.z):angle( Vec2(pipeAt.x, pipeAt.z) ) )
				local targetAngleDiffY = math.abs( Vec2(targetAt.x, targetAt.y):angle( Vec2(pipeAt.x, pipeAt.y) ) )
				--if target inside aceptable angle, then fire
				if targetAngleDiffXZ<FireMinAngle and targetAngleDiffY<FireMinAngle then
					attack()--just do the attack
					upgrade.setUsed()--set value changed
				end
			end
		else
			--if no target, update pipe to make it look alive
			rotator.setFrameDataAndUpdate(pipeAt)
			rotaterMesh:rotate(Vec3(0.0,0.0,1.0), rotator.getHorizontalRotation())
			crossbowMesh:rotate(Vec3(1.0, 0.0, 0.0), rotator.getVerticalRotation())
		end
		--local vec = model:getGlobalPosition()+Vec3(0.0,1.0,0.0);
		--Core.addDebugLine(vec,vec+(gloabalAt*3.0),0.0,Vec3(1.0,0.0,0.0))
	
	
		model:getAnimation():update(Core.getDeltaTime())
		projectiles.update()
		
		--model:render()
		return true;
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
		
		Core.setUpdateHz(60.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		
		isSettingRotation = Core.getTime()
		if xpManager then
			xpManager.setUpgradeCallback(self.handleUpgrade)
		end
		
		restartListener = Listener("RestartWave")
		restartListener:registerEvent("restartWave", restartWave)
	
		model = Core.getModel("tower_crossbow_l1.mym")
		local hullModel = Core.getModel("tower_resource_hull.mym")
		this:addChild(model)
		
		soundNode = SoundNode("bow_release")
		this:addChild(soundNode)
	
		--
		--
		rotator.setSpeedHorizontalMaxMinAcc(math.pi,math.pi*0.1,math.pi*0.8)
		rotator.setSpeedVerticalMaxMinAcc(math.pi*0.4,math.pi*0.05,math.pi*0.3)
		rotator.setVerticalLimits(-math.pi*0.20,math.pi*0.45)
		
		--this:addChild(candle1)
		--this:addChild(candle2)
		
		if particleEffectUpgradeAvailable then
			this:addChild(particleEffectUpgradeAvailable)
		end
	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug myStats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),3.0,"shockwave","")
		billboard:setDouble("rangePerUpgrade",1.5)
		billboard:setString("hullName","hull")
		billboard:setVectorVec3("hull3d",createHullList3d(hullModel:getMesh("hull")))
		billboard:setVectorVec2("hull2d",createHullList2d(hullModel:getMesh("hull")))
		billboard:setModel("tower",model)
		billboard:setVec3("Position",this:getGlobalPosition()+Vec3(0,2.3,0))--for locating where the physical attack originated
		billboard:setString("TargetArea","cone")
		billboard:setFloat("targetAngleY",math.pi*0.5)
		local localMat =  model:getGlobalMatrix():inverseM() * model:getMesh( "rotater" ):getGlobalMatrix()
		localMat:setPosition( localMat:getPosition() + Vec3(0,0.6,0) )
		billboard:setMatrix("TargetAreaOffset", localMat)
		billboard:setString("Name", "Arrow tower")
		billboard:setString("FileName", "Tower/ArrowTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
	
		--ComUnitCallbacks
		comUnitTable["dmgDealt"] = damageDealt
		comUnitTable["dmgDealtMarkOfDeath"] = dmgDealtMarkOfDeath
		comUnitTable["dmgLost"] = damageLost
		comUnitTable["waveChanged"] = waveChanged
		comUnitTable["retargeted"] = retargeted
		comUnitTable["upgrade1"] = self.handleUpgrade
		comUnitTable["upgrade2"] = handleBoost
		comUnitTable["upgrade3"] = handleUpgradeScope
		comUnitTable["upgrade4"] = handleFireball
		comUnitTable["upgrade5"] = handleWeakenTarget
		comUnitTable["upgrade6"] = handleRotate
		comUnitTable["setRotateTarget"] = setRotateTarget
		comUnitTable["setTargetAreaOffset"] = setTargetAreaOffset
		comUnitTable["NetOwner"] = setNetOwner
		comUnitTable["NetTarget"] = NetSyncTarget
		comUnitTable["Retarget"] = handleRetarget
		comUnitTable["SetTargetMode"] = self.SetTargetMode
		supportManager.setComUnitTable(comUnitTable)
		supportManager.addCallbacks()
	
		upgrade.setBillboard(billboard)
		upgrade.addDisplayStats("damage")
		upgrade.addDisplayStats("RPS")
		--upgrade.addDisplayStats("fireDPS")
		--upgrade.addDisplayStats("burnTime")
		upgrade.addDisplayStats("range")
		upgrade.addDisplayStats("weaken")
		upgrade.addBillboardStats("weakenTimer")
		upgrade.addBillboardStats("detonationRange")
		upgrade.addBillboardStats("targetAngle")
		
		--
		--	LIMITATION OF ANGLE GRANTS it 0% DMG INCREASE ;-)
		--
		
		upgrade.addUpgrade( {	cost = 200,
								name = "upgrade",
								info = "Arrow tower level",
								order = 1,
								icon = 56,
								value1 = 1,
								stats ={range =		{ upgrade.add, 9.0},
										damage = 	{ upgrade.add, 360},
										RPS = 		{ upgrade.add, 1.0/1.5},
										targetAngle =		{ upgrade.add, math.pi*0.175 } }
							} )
		--DPSpG == Damage*RPS*(radius/2+2.5)*0.111/cost == 0.79
		--DPSpG == Damage*RPS*(radius/2+2.5)*0.111/cost == 360*(1.0/1.5)/150 == 1.20
		upgrade.addUpgrade( {	cost = 400,
								name = "upgrade",
								info = "Arrow tower level",
								order = 1,
								icon = 56,
								value1 = 2,
								stats ={range =		{ upgrade.add, 9.0},
										damage = 	{ upgrade.add, 955},
										RPS = 		{ upgrade.add, 1.0/1.3},
										targetAngle =		{ upgrade.add, math.pi*0.175 } } 
							},0 )
		--DPSpG == Damage*RPS*(radius/2+3)*0.111/cost == 955*(1.0/1.3)/600 == 1.22
		upgrade.addUpgrade( {	cost = 800,
								name = "upgrade",
								info = "Arrow tower level",
								order = 1,
								icon = 56,
								value1 = 3,
								stats ={range =		{ upgrade.add, 9.0},
										damage = 	{ upgrade.add, 1920},
										RPS = 		{ upgrade.add, 1.0/1.1},
										targetAngle =		{ upgrade.add, math.pi*0.175 }} 
							},0 )
		--DPSpG == Damage*RPS*(radius/2+3)*0.111/cost == 1920*(1/1.1)/1400 == 1.25
		-- BOOST (increases damage output with 400%)
		function boostDamage() return upgrade.getStats("damage")*2.0*(waveCount/25+1.0) end
		--(total)	0=2x	25=4x	50=6x
		upgrade.addUpgrade( {	cost = 0,
								name = "boost",
								info = "Arrow tower boost",
								duration = 10,
								cooldown = 3,
								order = 10,
								icon = 57,
								stats ={range =				{ upgrade.add, 1.5},
										damage = 			{ upgrade.func, boostDamage},
										detonationRange =	{ upgrade.add, 2.0}}
							} )
		-- RANGE
		upgrade.addUpgrade( {	cost = 100,
								name = "range",
								info = "Arrow tower range",
								order = 2,
								icon = 59,
								value1 = 9 + 1.5,
								levelRequirement = cTowerUpg.getLevelRequierment("range",1),
								stats ={range =		{ upgrade.add, 1.5, ""} }
							} )
		upgrade.addUpgrade( {	cost = 200,
								name = "range",
								info = "Arrow tower range",
								order = 2,
								icon = 59,
								value1 = 9 + 3.0,
								levelRequirement = cTowerUpg.getLevelRequierment("range",2),
								stats ={range =		{ upgrade.add, 3.0, ""} }
							} )
		upgrade.addUpgrade( {	cost = 300,
								name = "range",
								info = "Arrow tower range",
								order = 2,
								icon = 59,
								value1 = 9 + 4.5,
								levelRequirement = cTowerUpg.getLevelRequierment("range",3),
								stats ={range =		{ upgrade.add, 4.5, ""} }
							} )
		-- HardArrow (not stackable damage, increase damage output with 35% per upgrade)
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "hardArrow",
								info = "Arrow tower hardArrow",
								order = 3,
								icon = 2,
								value1 = 135,
								value2 = 50,
								levelRequirement = cTowerUpg.getLevelRequierment("hardArrow",1),
								stats ={RPS = 		{ upgrade.mul, 0.5},
										damage = 	{ upgrade.mul, 2.35} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "hardArrow",
								info = "Arrow tower hardArrow",
								order = 3,
								icon = 2,
								value1 = 240,
								value2 = 60,
								levelRequirement = cTowerUpg.getLevelRequierment("hardArrow",2),
								stats ={RPS = 		{ upgrade.mul, 0.4},
										damage = 	{ upgrade.mul, 3.4} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "hardArrow",
								info = "Arrow tower hardArrow",
								order = 3,
								icon = 2,
								value1 = 510,
								value2 = 70,
								levelRequirement = cTowerUpg.getLevelRequierment("hardArrow",3),
								stats ={RPS = 		{ upgrade.mul, 0.3},
										damage = 	{ upgrade.mul, 6.1} }
							} )
		-- MARK OF DEATH (amplified by other towers, increases damage take to target with 5% every upgrade)
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "markOfDeath",
								info = "Arrow tower mark of death",
								order = 4,
								icon = 61,
								value1 = 10,
								levelRequirement = cTowerUpg.getLevelRequierment("markOfDeath",1),
								stats ={weaken =		{ upgrade.add, 0.10, ""},
										weakenTimer =	{ upgrade.add, 5.0, ""} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "markOfDeath",
								info = "Arrow tower mark of death",
								order = 4,
								icon = 61,
								value1 = 20,
								levelRequirement = cTowerUpg.getLevelRequierment("markOfDeath",2),
								stats ={weaken =		{ upgrade.add, 0.20, ""},
										weakenTimer =	{ upgrade.add, 5.0, ""} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "markOfDeath",
								info = "Arrow tower mark of death",
								order = 4,
								icon = 61,
								value1 = 30,
								levelRequirement = cTowerUpg.getLevelRequierment("markOfDeath",3),
								stats ={weaken =		{ upgrade.add, 0.30, ""},
										weakenTimer =	{ upgrade.add, 5.0, ""} }
							} )
--		-- SMART TARGETING
--		-- if markOfDeath or flame upgraded then it will try to retarget every attack, it will also avoid shield npcs to a degree
--		upgrade.addUpgrade( {	cost = 75,
--								name = "smartTargeting",
--								info = "Arrow tower smart targeting",
--								order = 5,
--								icon = 62,
--								levelRequirement = cTowerUpg.getLevelRequierment("smartTargeting",1),
--								stats = {	smartTargeting =	{ upgrade.add, 1.0, ""} }
--							} )
		function calculateReRotateCost() return 25*reRotateTowerCostMultiplyer end
		upgrade.addUpgrade( {	cost = 0,
								name = "rotate",
								info = "Arrow tower rotate",
								order = 6,
								icon = 60,
								stats = {}
							} )
		supportManager.setUpgrade(upgrade)
		supportManager.addHiddenUpgrades()
		supportManager.addSetCallbackOnChange(updateStats)
		--
		upgrade.upgrade("upgrade")
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		billboard:setInt("currentTargetMode",1)
		billboard:setString("targetMods","attackPriorityTarget;attackClosestToExit;attackWeakestTarget;attackStrongestTarget")
		
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
	
		setCurrentInfo()
		resetModel()
	
		myStatsReset()
	
		local pipeAt = -crossbowMesh:getGlobalMatrix():getUpVec():normalizeV()
		local angleLimit = upgrade.getValue("targetAngle")
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setAngleLimits(pipeAt,angleLimit)
		rotator.setHorizontalLimits(pipeAt,-angleLimit,angleLimit)
		
		cTowerUpg.addUpg("range",handleUpgradeScope)
		cTowerUpg.addUpg("hardArrow",handleFireball)
		cTowerUpg.addUpg("markOfDeath",handleWeakenTarget)
		cTowerUpg.fixAllPermBoughtUpgrades()
		return true
	end
	init()
	function self.destroy()
		projectiles.destroy()
	end
	return self
end
function create()
	arrowTower = ArrowTower.new()
	update = arrowTower.updateRotate
	destroy = arrowTower.destroy
	return true
end