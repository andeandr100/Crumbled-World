require("Projectile/projectileManager.lua")
require("Projectile/missile.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
require("Tower/TowerData.lua")
require("Game/gameValues.lua")

--this = SceneNode()
MissileTower = {}
function MissileTower.new()
	local self = {}
	local TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION = 0.2
	local level = 0	--upgradedLevel
	local missile = {}
	local missilesAvailable = 0
	local missileToFireNext = 1
	local missilesInTheAir = false
	local reloadTimeLeft = 0.0
	local targetHistory = {}
	local targetHistoryCount = 0
	local gameValues = GameValues.new()
	
	local waveCount = 0
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local projectiles = projectileManager.new(targetSelector)
	local data = TowerData.new()
	local boostActive = false
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
	--stats
	local isCircleMap = MapInfo.new().isCricleMap()
	local mapName = MapInfo.new().getMapName()
	
	local function canSyncTower()
		return (Core.isInMultiplayer()==false or self.getCurrentIslandPlayerId()==0 or networkSyncPlayerId==Core.getPlayerId())
	end
	local function achievementUnlocked(whatAchievement)
		if canSyncTower() then
			comUnit:sendTo("SteamAchievement",whatAchievement,"")
		end
	end
	
	local function updateMeshesAndparticlesForSubUpgrades()
		--------------------
		--- Handle Boost ---
		--------------------
		
		model:getMesh( "boost" ):setVisible(data.getBoostActive())
		
		for index=0, model:getNumMesh()-1 do
			local mesh = model:getMesh(index)
			local shader = mesh:getShader()
			local texture = Core.getTexture(data.getBoostActive() and "towergroup_boost_a" or "towergroup_a")
			mesh:setTexture(shader,texture,4)
		end
		
		---------------------------
		--- Handle fuel upgrade ---
		---------------------------
		
		-- NOTE FUEL has been disabled du to removal of fire
		for index =1, 3 do
			model:getMesh( "range"..index ):setVisible(data.getLevel("range")==index)
			model:getMesh( "pipe"..index ):setVisible(false)
		end
		
		----------------------------
		--- Handle Range upgrade ---
		----------------------------
		
		if data.getLevel("range")>0 then
			activeRangeMesh = model:getMesh( "range"..data.getLevel("range") )
		end
		
		----------------------------
		--- Handle Tower upgrade ---
		----------------------------
				
		model:getMesh( "masterAim1" ):setVisible(false)
		if model:getMesh( "antenna1" ) then
			model:getMesh( "antenna1" ):setVisible( false )
		end
		if model:getMesh( "antenna2" ) then
			model:getMesh( "antenna2" ):setVisible( false )
		end

	end
	
	local function storeWaveChangeStats( )
		tab = {
			reloadTimeLeft = reloadTimeLeft,
			missilesAvailable = missilesAvailable,
			missileToFireNext = missileToFireNext,
			missile = {},
		}
		for i = 1, 2+data.getTowerLevel(), 1 do
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
		return tab
	end
	
	local function SetTargetMode(param)
		targetMode = math.clamp(tonumber(param),1,6)
		billboard:setInt("currentTargetMode",targetMode)
		if billboard:getBool("isNetOwner") and Core.isInMultiplayer() then
			comUnit:sendNetworkSync("SetTargetMode", tostring(param) )
		end
	end

	local function restoreWaveChangeStats( tab )
		SetTargetMode(tab.currentTargetMode)
		
		reloadTimeLeft = tab.reloadTimeLeft
		missilesAvailable = tab.missilesAvailable
		missileToFireNext = tab.missileToFireNext
		missilesInTheAir = false
		--parse all missiles
		for i = 1, 2+data.getTowerLevel(), 1 do
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
	
	local function reloadMissiles()
		reloadTimeLeft = reloadTimeLeft - Core.getDeltaTime()
		local doorOpenAngle = math.pi*0.50
		for i = 1, 2+data.getTowerLevel(), 1 do
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
		targetSelector.setRange(data.getValue("range"))
	end
	local function setCurrentInfo()
		data.updateStats()
		missilesAvailable = 0
		for i = 1, 2+data.getTowerLevel(), 1 do
			missile[i] = missile[i] or {}
			missile[i].timer = data.getValue("replaceTime")
			missile[i].replaceTime = data.getValue("replaceTime")
			missile[i].missile = model:getMesh( "missile"..i )
			missile[i].hatch1 = model:getMesh( "hatch"..(i*10+1) )
			missile[i].hatch2 = model:getMesh( "hatch"..(i*10+2) )
			missile[i].hatch1:setLocalMatrix( missile[i].hatch1matrix )
			missile[i].hatch2:setLocalMatrix( missile[i].hatch2matrix )
			missile[i].state = 0
		end
		updateStats()
		billboard:setInt("FirestormLevel",0)
		reloadMissiles()
	end
	function restartWave(param)
		projectiles.clear()
	end

	local function initModel(setMissilePos)

		model:getMesh( "physic" ):setVisible(false)
		model:getMesh( "hull" ):setVisible(false)
		
		if setMissilePos then
			for i = 1, 2+data.getTowerLevel(), 1 do
				missile[i] = missile[i] or {}
				missile[i].missilePosition = model:getMesh( "missile"..i ):getLocalPosition()
				missile[i].hatch1matrix = model:getMesh( "hatch"..(i*10+1) ):getLocalMatrix()
				missile[i].hatch2matrix = model:getMesh( "hatch"..(i*10+2) ):getLocalMatrix()
			end
		end
		
		--performance check
		for i=0, model:getNumMesh()-1, 1 do
			if not model:getMesh(i):getName() =="tower" then
				model:getMesh(i):DisableBoundingVolumesDynamicUpdates()
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
	function self.handleUpgrade()
		local newModel = Core.getModel( "tower_missile_l"..data.getTowerLevel()..".mym" )
		if newModel then
			if model then
				this:removeChild(model:toSceneNode())
			end
			model = newModel
			this:addChild(model:toSceneNode())
			initModel(true)	
		end
		updateMeshesAndparticlesForSubUpgrades()
		setCurrentInfo()
	end
	
	function self.destroy()
		projectiles.destroy()
	end
	
	local function updateTarget()
		if targetSelector.isTargetAvailable()==false then -- or rotator:isAtHorizontalLimit() then
			if targetSelector.selectAllInRange() then
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
					if data.getLevel("shieldSmasher")>0 then
						targetSelector.scoreName("turtle",40)
					end
					targetSelector.selectTargetAfterMaxScore()
				elseif targetMode==4 then
					--attackWeakestTarget
					targetSelector.scoreHP(-30)
					targetSelector.scoreSelectedTargets( targetHistory, -10 )
					targetSelector.scoreDensity(10)
					targetSelector.scoreClosestToExit(10)
					targetSelector.selectTargetAfterMaxScore()
				elseif targetMode==5 then
					--attackStrongestTarget
					targetSelector.scoreHP(30)
					targetSelector.scoreSelectedTargets( targetHistory, -10 )
					targetSelector.scoreDensity(10)
					targetSelector.scoreClosestToExit(10)
					targetSelector.selectTargetAfterMaxScore()
				elseif targetMode==6 then
					--closest to exit
					targetSelector.scoreDensity(20)
					targetSelector.scoreClosestToExit(25)
					targetSelector.scoreRandom(10)
					targetSelector.scoreSelectedTargets( targetHistory, -10 )
					targetSelector.selectTargetAfterMaxScore()
				end
			end
			if targetSelector.getTarget()==0 then
				reloadTimeLeft = TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION
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
		missileToFireNext = (missileToFireNext==2+data.getTowerLevel()) and 1 or missileToFireNext + 1
		missilesAvailable = missilesAvailable - 1
	end
	local function attack()
		local target = targetSelector.getTargetIfAvailable()
		if target>0 then
			local targetPos = targetSelector.getTargetPosition(target)
			reloadTimeLeft = reloadTimeLeft+Core.getDeltaTime()>0 and reloadTimeLeft+data.getValue("fieringTime") or data.getValue("fieringTime")
			targetHistoryCount = targetHistoryCount + 1
			if targetHistoryCount<2+data.getTowerLevel() then
				targetHistory[targetHistoryCount] = target
			else
				targetHistoryCount = 0
				targetHistory = {}
			end
			local counter=1
			while missile[missileToFireNext].state~=3 and counter<2+data.getTowerLevel() do
				counter = counter + 1
				missileToFireNext = (missileToFireNext==2+data.getTowerLevel()) and 1 or missileToFireNext + 1
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
					missileToFireNext = (missileToFireNext==2+data.getTowerLevel()) and 1 or missileToFireNext + 1
					missilesAvailable = missilesAvailable - 1
				end
			end
		end
	end
	--
	function self.update()
		comUnit:setPos(this:getGlobalPosition())
		
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		
		if boostActive ~= data.getBoostActive() then
			boostActive = data.getBoostActive()	
			setCurrentInfo()
			updateMeshesAndparticlesForSubUpgrades()
		end

		reloadMissiles()
		if missilesAvailable>0 and reloadTimeLeft<0 and updateTarget() then
			attack()
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
	function self.handleSubUpgrade()
		updateMeshesAndparticlesForSubUpgrades()
		setCurrentInfo()
	end
	
	--
	local function init()
		this:createBoundVolumeGroup()
		this:setBoundingVolumeCanShrink(false)

		Core.setUpdateHz(24.0)--slow gates and a slow rise of an missile
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		--

		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug for stats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
		
		billboard:setDouble("rangePerUpgrade",1.0)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Missile tower")
		billboard:setString("FileName", "Tower/missileTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		billboard:setFloat("baseRange", 7.0)
		--
		billboard:setDouble("DamageCurrentWave",0)
		billboard:setDouble("DamagePreviousWave",0)
		
		
		--ComUnitCallbacks
		comUnitTable["boost"] = data.activateBoost
		comUnitTable["NetLaunchMissile"] = NetLaunchMissile
		comUnitTable["SetTargetMode"] = self.SetTargetMode
	
		data.setBillboard(billboard)
		data.setCanSyncTower(canSyncTower())
		data.setComUnit(comUnit, comUnitTable)
		data.setTowerUpgradeCallback(self.handleUpgrade)
		data.setUpgradeCallback(self.handleSubUpgrade)
		data.setMaxedOutAchivement("MissileMaxed")
		data.enableSupportManager()
		data.addDisplayStats("damage")
		data.addDisplayStats("RPS")
		data.addDisplayStats("range")
		data.addDisplayStats("dmg_range")
		if isThisReal then
			restartListener = Listener("RestartWave")
			restartListener:registerEvent("restartWave", restartWave)
			data.setRestoreFunction(restartListener, restoreWaveChangeStats, storeWaveChangeStats)
		end
		
		
		data.addTowerUpgrade(gameValues.getTowerAbilityValues("MissileTower","upgrade"))
		data.addBoostUpgrade(gameValues.getTowerAbilityValues("MissileTower","boost"))
		data.addSecondaryUpgrade(gameValues.getTowerAbilityValues("MissileTower","range"))
		data.addSecondaryUpgrade(gameValues.getTowerAbilityValues("MissileTower","Blaster"))
		data.addSecondaryUpgrade(gameValues.getTowerAbilityValues("MissileTower","shieldSmasher"))
		
		data.buildData()

		if isCircleMap then
			billboard:setString("targetMods","attackHighDensity;attackVariedTargets;attackPriorityTarget;attackWeakestTarget;attackStrongestTarget")
			targetMode = 1
			billboard:setInt("currentTargetMode",1)
		else
			billboard:setString("targetMods","attackHighDensity;attackVariedTargets;attackPriorityTarget;attackWeakestTarget;attackStrongestTarget;attackClosestToExit")
				targetMode = 1
			billboard:setInt("currentTargetMode",1)
		end
		
		--soulManager and targetSelecter
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(data.getValue("range"))


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