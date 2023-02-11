require("Tower/rotator.lua")
require("NPC/state.lua")
require("Projectile/projectileManager.lua")
require("Projectile/Arrow.lua")
require("Projectile/ArrowMortar.lua")
require("Game/campaignTowerUpg.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
require("Tower/TowerData.lua")

--this = SceneNode()
ArrowTower = {}
function ArrowTower.new()
	local self = {}
	local waveCount = 0
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local projectiles = projectileManager.new()
	local cData = CampaignData.new()
	local rotator = Rotator.new()
	local currentGlobalVec = ""
	--constants
	local RECOIL_ON_ATTACK = math.pi/18.0	 	 --default kickback
	local SCOPE_ROTATION_ON_BOOST = math.pi*30/180 --rotation to avoid ammo coger when boost is activated
	local TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION = 0.2
	--Model
	local model
	local rotaterMesh
	local crossbowMesh
	local defaultRotaterMeshMatrix
	--Sound
	local soundNode
	
	local data = TowerData.new()
	--attack
	local targetMode = 1
	local activeProjectile = "Arrow"
	local activeProjectileBoost = "ArrowMortar"
	local reloadTime = 0.0
	local reloadTimeLeft = 0.0
	local boostedOnLevel = 0
	local boostActive = false
	--Upgrades
	local reRotateTowerCostMultiplyer = 0   
	local isSettingRotation = 0.0
	--effects
	--Comunication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local billboardWaveStats
	--Events
	--Other
	local syncTimer = 0.0
	local visibleState = 2
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this	
	local lastRestored = -1
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	--stats
	local isCircleMap = MapInfo.new().isCricleMap()
	local mapName = MapInfo.new().getMapName()
	--
	
	local function canSyncTower()
		return (Core.isInMultiplayer()==false or self.getCurrentIslandPlayerId()==0 or networkSyncPlayerId==Core.getPlayerId())
	end
	local function achievementUnlocked(whatAchievement)
		if canSyncTower() then
			comUnit:sendTo("SteamAchievement",whatAchievement,"")
		end
	end
	
	local function SetTargetMode(param)
		targetMode = math.clamp(tonumber(param),1,4)
		billboard:setInt("currentTargetMode",targetMode)
		if billboard:getBool("isNetOwner") and Core.isInMultiplayer() then
			comUnit:sendNetworkSync("SetTargetMode", tostring(param) )
		end
	end
	local function updateMeshesAndparticlesForSubUpgrades()
		for index =1, 3, 1 do
			model:getMesh( string.format("scope%d", index) ):setVisible( data.getLevel("range")==index )
			model:getMesh( string.format("flamer%d", index) ):setVisible( false )
			model:getMesh( string.format("markForDeath%d", index) ):setVisible( data.getLevel("markOfDeath")==index )
		end
		model:getMesh( "masterAim" ):setVisible(false)
		model:getMesh( "physic" ):setVisible(false)
		model:getMesh( "hull" ):setVisible(false)
		model:getMesh( "space0" ):setVisible(false)
	
		model:getMesh( "ammoDrumBoost" ):setVisible(data.getBoostActive())
		model:getMesh( "ammoDrum" ):setVisible(not data.getBoostActive())
		
		--set ambient map
		for index=0, model:getNumMesh()-1 do
			local mesh = model:getMesh(index)
			local shader = mesh:getShader()
			local texture = Core.getTexture(data.getBoostActive() and "towergroup_boost_a" or "towergroup_a")
			
			mesh:setTexture(shader,texture,4)
		end
		
		for i=1, 3 do
			if model:getMesh("scope"..i) then
				model:getMesh("scope"..i):setVisible(data.getLevel("range")==i)
			end
			if model:getMesh("markForDeath"..i) then
				model:getMesh("markForDeath"..i):setVisible(data.getLevel("markOfDeath")==i)
			end
		end
		if data.getBoostActive() and model:getMesh("scope"..data.getLevel("range")) then
			model:getMesh("scope"..data.getLevel("range")):rotate(Vec3(0.0, 1.0, 0.0), SCOPE_ROTATION_ON_BOOST)
		end	
	end

	--
	local function restartWave(param)
		projectiles.clear()
	end

	
	local function resetModel()
		--Meshes
		rotaterMesh = model:getMesh( "rotater" )
		crossbowMesh = model:getMesh( "crossbow" )
		crossbowMesh:setLocalPosition(Vec3(0.0,0.0,0.44))
		
		defaultRotaterMeshMatrix = defaultRotaterMeshMatrix or rotaterMesh:getLocalMatrix()
	
		--init the crossbow (instant reload)
		
		model:getAnimation():play("init",1.0,PlayMode.stopSameLayer)
		reloadTimeLeft  = 0.0
		
		--performance check
		for i=0, model:getNumMesh()-1, 1 do
			if not model:getMesh(i):getName() =="tower" then
				model:getMesh(i):DisableBoundingVolumesDynamicUpdates()
			end
		end
	end
	local function updateStats()
		targetSelector.setRange(data.getValue("range"))
	end
	local function setCurrentInfo()
		data.updateStats()
		--xpToLevel	   = 1000.0*(1.5^level)
		--range	 	  = data.getValue("range")--info[upgradeLevel]["range"]*(1.025^level)*upgradeScopeRangeMultiplayer
		--dmg	 		= data.getValue("Damage")--info[upgradeLevel]["dmg"]*(1.02^level)
		--reloadTime	  = 1.0/data.getValue("RPS")--info[upgradeLevel]["reloadTime"]*(0.99^level)	
		model:getAnimation():play("init",1.0,PlayMode.stopSameLayer)
		billboard:setDouble("hittStrength",data.getTowerLevel()+(data.getLevel("hardArrow")>0 and 1 or 0)+(data.getBoostActive() and 1 or 0))
		reloadTimeLeft  = 0.0
		updateStats()
		--achivment
		if data.getIsMaxedOut() then
			achievementUnlocked("CrossbowMaxed")
		end
	end

	function self.setRotateTarget(globalVec, isWaveRestart)
		currentGlobalVec = globalVec
		if globalVec:sub(1,1)==":" then
			globalVec = globalVec:sub(2)
		else
			if Core.isInMultiplayer() and billboard:getBool("isNetOwner") then
				comUnit:sendNetworkSyncSafe("setRotateTarget",":"..globalVec)
--				local tab = {mat=billboard:getMatrix("TargetAreaOffset")}
--				comUnit:sendNetworkSyncSafe("setTargetAreaOffset",tabToStrMinimal(tab))
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
		local defaultPlatformRotMeshMatrix = model:getMesh( "tower" ):getGlobalMatrix()
		--set matrix for platform
		rotMesh:setLocalMatrix(rotMeshParentGIMatrix * (defaultPlatformRotMeshMatrix * globalMat))
		--set matrix for rotater on platform
		rotaterMesh:setLocalMatrix(defaultRotaterMeshMatrix)
		
		local pipeAt = -crossbowMesh:getGlobalMatrix():getUpVec():normalizeV()
		local angleLimit = data.getValue("targetAngle")
		targetSelector.setAngleLimits(pipeAt,angleLimit)
		rotator.setHorizontalLimits(pipeAt,-angleLimit,angleLimit)
	
		reloadTimeLeft = (reloadTimeLeft>0.25) and reloadTimeLeft or 0.25--0.25 is the inactivity time when changing rotation of the tower
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
	function self.handleUpgrade()
		local copyPreviousData = model and rotaterMesh and crossbowMesh
		
		local rotaterMatrix = copyPreviousData and rotaterMesh:getLocalMatrix() or nil--get rotation for rotater
		local crossbowMatrix = copyPreviousData and crossbowMesh:getLocalMatrix() or nil--get rotation for engine
		local rotaterBaseMatrix = copyPreviousData and model:getMesh( "rotaterBase" ):getLocalMatrix() or nil
	
	
		local newModel = Core.getModel( string.format("tower_crossbow_l%d.mym", data.getTowerLevel()) )
		if newModel then
			if model then
				this:removeChild(model:toSceneNode())
			end
			model = newModel
			this:addChild(model:toSceneNode())
			billboard:setModel("tower",model);
		
			resetModel()--resets the model and reload time
		end
		
		--model:setIsStatic(true)
		--model:render()
		if copyPreviousData then
			rotaterMesh:setLocalMatrix(rotaterMatrix)--set the old rotation
			crossbowMesh:setLocalMatrix(crossbowMatrix)--set the old rotation
			model:getMesh( "rotaterBase" ):setLocalMatrix(rotaterBaseMatrix)
		end
		--instant reload
		reloadTimeLeft = 0.0
		--visual changes
		RECOIL_ON_ATTACK = RECOIL_ON_ATTACK*1.15
		--

		setCurrentInfo()
	end


	local function handleRotate(param)
--		reRotateTowerCostMultiplyer = reRotateTowerCostMultiplyer + 1
--		upgrade.fixBillboardAndStats()
--		this:loadLuaScript("Game/buildRotater.lua")
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
				reloadTimeLeft = (1.0/data.getValue("RPS"))--if we are over due for fiering(reloading timer is past this frame)
			else
				reloadTimeLeft = reloadTimeLeft + (1.0/data.getValue("RPS"))--if we was supposed to fire this frame just add reload timer
			end
		
			if data.getBoostActive() then
				projectiles.launch(ArrowMortar,{})
			else 
				projectiles.launch(Arrow,{})
			end
			
			local animationSpeed = model:getAnimation():getLengthOfClip("attack")/reloadTimeLeft
			model:getAnimation():play("attack",animationSpeed,PlayMode.stopSameLayer)
			crossbowMesh:rotate(Vec3(1.0, 0.0, 0.0),RECOIL_ON_ATTACK )--add some recoil for more kick in the tower
			
			soundNode:play(1.1,false)
		end
	end
	local function NetSyncTarget(param)
		local target = tonumber(Core.getIndexOfNetworkName(param))
		if target>0 then
			targetSelector.setTarget(target)
		end
	end
	
	local function updateTarget()
		--only select new target if we own the tower or we are not told anything usefull
		if (billboard:getBool("isNetOwner") or targetSelector.getTargetIfAvailable()==0) then
			if targetSelector.selectAllInRange() then
				targetSelector.filterOutState(state.ignore)
				if data.getBoostActive() then
					--density
					targetSelector.scoreDensity(30)
					targetSelector.scoreClosestToExit(10)
					targetSelector.scoreRandom(15)
				elseif targetMode==1 then
					--priority targets
					targetSelector.scoreHP(20)
					targetSelector.scoreName("dino",10)
					targetSelector.scoreName("turtle",20)
					targetSelector.scoreName("reaper",25)
					targetSelector.scoreState(state.shielded,-10)	--decreased damage against this target
					targetSelector.scoreName("skeleton_cf",-20)
					targetSelector.scoreName("skeleton_cb",-20)
					
					if data.getLevel("markOfDeath")>0 then
						targetSelector.scoreState(state.markOfDeath,-15)	--because we placed the mark, it is therefore better to mark another unit
					else
						targetSelector.scoreState(state.markOfDeath,15)		--attack marked unit for damage bonus
					end
				elseif targetMode==2 then
					--attackWeakestTarget
					targetSelector.scoreHP(-30)
					targetSelector.scoreClosestToExit(20)
					targetSelector.scoreName("skeleton_cf",-10)
					targetSelector.scoreName("skeleton_cb",-10)
					targetSelector.scoreState(state.markOfDeath,15)
				elseif targetMode==3 then
					--attackStrongestTarget
					targetSelector.scoreHP(30)
					targetSelector.scoreState(state.markOfDeath,10)
					targetSelector.scoreName("reaper",15)
					targetSelector.scoreName("skeleton_cf",-20)
					targetSelector.scoreName("skeleton_cb",-20)
				elseif targetMode==4 then
					--closest to exit
					targetSelector.scoreClosestToExit(40)
					targetSelector.scoreState(state.markOfDeath,10)
					targetSelector.scoreHP(-10)
				end
				
				if data.getLevel("hardArrow")>0 then
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
			if targetSelector.getTarget()==0 then
				reloadTimeLeft = TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION
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
--		if upgrade.update() then
--			resetModel()
--			setCurrentInfo()
--			--only boost that uses timer
--			if upgrade.getLevel("range")>0 then
--		 	   model:getMesh("scope"..upgrade.getLevel("range")):rotate(Vec3(0.0, 1.0, 0.0), -SCOPE_ROTATION_ON_BOOST)
--			end
--			--if the tower was upgraded while boosted, then the boost should be available
--			if boostedOnLevel~=upgrade.getLevel("upgrade") then
--				upgrade.clearCooldown()
--			end
--		end
	
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
--		if upgrade.update() then
--			resetModel()
--			setCurrentInfo()
--			--only boost that uses timer
--			if upgrade.getLevel("range")>0 then
--		 	   model:getMesh("scope"..upgrade.getLevel("range")):rotate(Vec3(0.0, 1.0, 0.0), -SCOPE_ROTATION_ON_BOOST)
--			end
--			--if the tower was upgraded while boosted, then the boost should be available
--			if boostedOnLevel~=upgrade.getLevel("upgrade") then
--				upgrade.clearCooldown()
--			end
--		end
		if boostActive ~= data.getBoostActive() then
			boostActive = data.getBoostActive()	
			setCurrentInfo()
			updateMeshesAndparticlesForSubUpgrades()
		end
		

		comUnit:setPos(this:getGlobalPosition())
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
		if targetSelector.getTargetIfAvailable()>0 then
			updateSync()
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
--					upgrade.setUsed()--set value changed
				end
			end
		else
			updateTarget()
			--if no target, update pipe to make it look alive
			rotator.setFrameDataAndUpdate(pipeAt)
			rotaterMesh:rotate(Vec3(0.0,0.0,1.0), rotator.getHorizontalRotation())
			crossbowMesh:rotate(Vec3(1.0, 0.0, 0.0), rotator.getVerticalRotation())
		end

	
		model:getAnimation():update(Core.getDeltaTime())
		projectiles.update()
		
		--model:render()
		return true;
	end
	
	function self.handleSubUpgrade()
		updateMeshesAndparticlesForSubUpgrades()
		setCurrentInfo()
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
		
		if isThisReal then
			restartListener = Listener("RestartWave")
			restartListener:registerEvent("restartWave", restartWave)
			restartListener2 = Listener("RestartWaveBuilder")
			restartListener2:registerEvent("restartWaveBuilder", restartWave)
		end
		
		model = Core.getModel("tower_crossbow_l1.mym")
		this:addChild(model:toSceneNode())
		
		soundNode = SoundNode.new("bow_release")
		this:addChild(soundNode:toSceneNode())
	
		--
		--
		rotator.setSpeedHorizontalMaxMinAcc(math.pi,math.pi*0.1,math.pi*0.8)
		rotator.setSpeedVerticalMaxMinAcc(math.pi*0.4,math.pi*0.05,math.pi*0.3)
		rotator.setVerticalLimits(-math.pi*0.20,math.pi*0.45)
		

		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug myStats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
		billboard:setDouble("rangePerUpgrade",1.5)
		billboard:setModel("tower",model)
		billboard:setVec3("Position",this:getGlobalPosition()+Vec3(0,2.3,0))--for locating where the physical attack originated
		billboard:setString("TargetArea","cone")
		billboard:setFloat("targetAngleY",math.pi*0.5)
		local localMat =  model:getGlobalMatrix():inverseM() * model:getMesh( "rotater" ):getGlobalMatrix()
		localMat:setPosition( localMat:getPosition() + Vec3(0,0.6,0) )
		billboard:setString("Name", "Arrow tower")
		billboard:setString("FileName", "Tower/ArrowTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		billboard:setFloat("baseRange", 9)
		--
		billboard:setDouble("DamagePreviousWave",0)
		billboard:setDouble("DamagePreviousWavePassive",0)
		billboard:setDouble("DamageTotal",0)
	
		--ComUnitCallbacks
		comUnitTable["boost"] = data.activateBoost
		comUnitTable["upgrade6"] = handleRotate
		comUnitTable["setRotateTarget"] = self.setRotateTarget
		comUnitTable["NetTarget"] = NetSyncTarget
		comUnitTable["Retarget"] = handleRetarget
		comUnitTable["SetTargetMode"] = self.SetTargetMode
		
		data.setBillboard(billboard)
		data.setCanSyncTower(canSyncTower())
		data.setComUnit(comUnit, comUnitTable)
		data.setTowerUpgradeCallback(self.handleUpgrade)
		data.setUpgradeCallback(self.handleSubUpgrade)
		data.enableSupportManager()
		data.addDisplayStats("damage")
		data.addDisplayStats("RPS")
		data.addDisplayStats("range")
		data.addDisplayStats("weakenValue")
		if isThisReal then
			restartListener = Listener("RestartWave")
			restartListener:registerEvent("restartWave", restartWave)
			data.setRestoreFunction(restartListener, nil, nil)
		end
		
		data.addTowerUpgrade({	cost = {200,400,800},
								name = "upgrade",
								info = "Arrow tower level",
								iconId = 56,
								level = 1,
								maxLevel = 3,
								stats = {
										range =		{ 9.0, 9.0, 9.0 },
										damage = 	{ 360, 955, 1920},
										RPS = 		{ 1.0/1.5, 1.0/1.3, 1.0/1.1},
										targetAngle =	{ math.pi*0.175, math.pi*0.175, math.pi*0.175 }  }
							})
		
		data.addBoostUpgrade({	cost = 0,
								name = "boost",
								info = "minigun tower boost",
								duration = 10,
								cooldown = 3,
								iconId = 57,
								level = 0,
								maxLevel = 1,
								stats = {range = 			{ 1.5, func = data.add },
										damage =			{ 3, func = data.mul },
										detonationRange = 	{ 2.25, func = data.set } }
							})
		
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "range",
								info = "Arrow tower range",
								infoValues = {"range"},
								iconId = 59,
								level = 0,
								maxLevel = 3,
								achievementName = "Range",
								stats = {range = { 1.5, 3.0, 4.5, func = data.add }}
							})
							
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "hardArrow",
								info = "Arrow tower hardArrow",
								infoValues = {"damage", "RPS"},
								iconId = 2,
								level = 0,
								maxLevel = 3,
								achievementName = "HardArrow",
								stats = {RPS = { 0.5, 0.4, 0.3, func = data.mul },
										damage = { 2.35, 3.4, 5.1, func = data.mul }}
							})
							
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "markOfDeath",
								info = "Arrow tower mark of death",
								infoValues = {"weakenValue"},
								iconId = 61,
								level = 0,
								maxLevel = 3,
								achievementName = "MarkOfDeath",
								stats = {weaken = { 0.08, 0.16, 0.24, func = data.set },
										weakenValue = { 8, 16, 24, func = data.set },
										weakenTimer = { 5.0, 5.0, 5.0, func = data.set }}
							})

		
		data.buildData()

--		function calculateReRotateCost() return 25*reRotateTowerCostMultiplyer end
--		upgrade.addUpgrade( {	cost = 0,
--								name = "rotate",
--								info = "Arrow tower rotate",
--								order = 6,
--								icon = 60,
--								stats = {}
--							} )
							
							
							
		
		if isCircleMap then
			billboard:setString("targetMods","attackPriorityTarget;attackWeakestTarget;attackStrongestTarget")
			targetMode = 1
			billboard:setInt("currentTargetMode",1)
		else
			billboard:setString("targetMods","attackPriorityTarget;attackWeakestTarget;attackStrongestTarget;attackClosestToExit")
			targetMode = 1
			billboard:setInt("currentTargetMode",1)
		end
		
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
	
		setCurrentInfo()
		resetModel()
	
		local pipeAt = -crossbowMesh:getGlobalMatrix():getUpVec():normalizeV()
		local angleLimit = data.getValue("targetAngle")
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setAngleLimits(pipeAt,angleLimit)
		rotator.setHorizontalLimits(pipeAt,-angleLimit,angleLimit)
		
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