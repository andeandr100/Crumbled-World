require("NPC/state.lua")
require("Projectile/projectileManager.lua")
require("Projectile/SwarmBall.lua")
require("Game/campaignTowerUpg.lua")
require("Game/particleEffect.lua")
require("Game/graphicParticleSystems.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
require("Tower/TowerData.lua")

--this = SceneNode()
SwarmTower = {}
function SwarmTower.new()
	local self = {}
	--
	local TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION = 0.2
	--targetSelector
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local piston = {}
	local targetHistory = {0,0,0,0, 0,0,0,0}
	local targetHistoryToken = 1
	local dmgDone = 0
	local waveCount = 0
	local projectiles = projectileManager.new(targetSelector)

	local data = TowerData.new()
	--model
	local model
	--attack
	local targetMode = 1
	local currentAttackCountOnTarget = 0
	local reloadTimeLeft = 0.0
	local boostedOnLevel = 0
	--effects
	local particleFireCenter = GraphicParticleSystems.new().createTowerFireCenter()
	--local fireCenter = ParticleSystem.new(ParticleEffect.SwarmTowerFlame)
	local pointLight
	--communication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local attackCounter = 0
	local billboardWaveStats
	local boostActive = false

	--sound
	local visibleState = 2
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this
	--stats
	local isCircleMap = MapInfo.new().isCricleMap()
	local mapName = MapInfo.new().getMapName()
	--other
	local lastRestored = -1
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	
	local function canSyncTower()
		return (Core.isInMultiplayer()==false or self.getCurrentIslandPlayerId()==0 or networkSyncPlayerId==Core.getPlayerId())
	end
	local function achievementUnlocked(whatAchievement)
		if canSyncTower() then
			comUnit:sendTo("SteamAchievement",whatAchievement,"")
		end
	end
	
	local function updateMeshesAndparticlesForSubUpgrades()
		for index =1, data.getTowerLevel() do
			model:getMesh( string.format("fuel%d", index) ):setVisible( false )
			model:getMesh( string.format("speed%d", index) ):setVisible( data.getLevel("burnDamage")==index )
		end
		
		model:getMesh( "boost" ):setVisible( data.getBoostActive() )
		--set ambient map
		for index=0, model:getNumMesh()-1 do
			local mesh = model:getMesh(index)
			local shader = mesh:getShader()
			local texture = Core.getTexture(data.getBoostActive() and "towergroup_boost_a" or "towergroup_a")
			mesh:setTexture(shader,texture,4)
		end		
	end
	
	local function restartWave(param)
		projectiles.clear()
	end
	
	local function updateStats()
		targetSelector.setRange(data.getValue("range"))
	end
	local function setCurrentInfo()
		data.updateStats()
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
		if data.getIsMaxedOut() then
			achievementUnlocked("SwarmMaxed")
		end
	end
	local function initModel()
		model:createBoundVolumeGroup()
		model:setBoundingVolumeCanShrink(false)

	
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
			if not model:getMesh(i):getName() =="tower" then
				model:getMesh(i):DisableBoundingVolumesDynamicUpdates()
			end
		end
	
		--no reload
		reloadTimeLeft = 0.0
	end
	local function pushPiston(index,pushItDown)
		local aPiston = piston[index]
		if pushItDown then
			aPiston.timer = data.getValue("fieringTime")*3.9*0.1
			aPiston.timerStart = data.getValue("fieringTime")*3.9*0.1
			aPiston.pistonGoingDown = true
		else
			aPiston.timer = data.getValue("fieringTime")*3.9*0.9
			aPiston.timerStart = data.getValue("fieringTime")*3.9*0.9
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
				
				projectiles.launch(SwarmBall,{target, this:getGlobalPosition()+Vec3(0.0,2.0,0.0), data.getValue("range"), projectileName and projectileName or "n"..attackCounter})
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
				reloadTimeLeft = reloadTimeLeft + data.getValue("fieringTime")
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
		if targetSelector.selectAllInRange() then
			targetSelector.filterOutState(state.ignore)
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
				--target weakest unit
				targetSelector.scoreHP(-25)
				targetSelector.scoreClosestToExit(15)
				targetSelector.scoreState(state.burning,-5)
				targetSelector.scoreSelectedTargets( targetHistory, -5 )
			elseif targetMode==3 then
				--attackStrongestTarget
				targetSelector.scoreHP(30)
				targetSelector.scoreClosestToExit(20)
				targetSelector.scoreState(state.burning,-5)
				targetSelector.scoreSelectedTargets( targetHistory, -5 )
			elseif targetMode==4 then
				--attackClosestToExit
				targetSelector.scoreClosestToExit(30)
				targetSelector.scoreState(state.burning,-10)
				targetSelector.scoreSelectedTargets( targetHistory, -5 )
				targetSelector.scoreHP(10)
			end
			
			targetSelector.scoreName("fireSpirit",-1000)
			targetSelector.scoreState(state.markOfDeath,5)
			targetSelector.scoreState(state.highPriority,30)
			targetSelector.selectTargetAfterMaxScore(-500)
				
			return targetSelector.isTargetAvailable()
		end
		if targetSelector.getTarget()==0 then
			reloadTimeLeft = TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION
		end
		return false
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
		local newModel = Core.getModel( "tower_swarm_l"..data.getTowerLevel()..".mym" )
		if newModel then
			this:removeChild(model:toSceneNode())
			model = newModel
			
			this:addChild(model:toSceneNode())
			billboard:setModel("tower",model)
			
			initModel()
		end
		
		setCurrentInfo()
	end

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
		

		pointLight:setRange(1.25+(data.getBoostActive() and 1.0 or 0.0))
		
		--change update speed
--		local tmpCameraNode = cameraNode
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 25) * 2)
--		print("state "..state)
--		print("Hz: "..((state == 2) and 60.0 or (state == 1 and 30 or 10)))
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end
		
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
		--
		reloadTimeLeft = reloadTimeLeft - Core.getDeltaTime()
		if reloadTimeLeft<0.0 and billboard:getBool("isNetOwner")and updateTarget() then
			attack()--can now attack
		end
		--
		projectiles.update()
		--Achievements
		if projectiles.getSize()>=12 then
			achievementUnlocked("SwarmBall")
		end
	
		return true
	end
	function self.handleSubUpgrade()
		updateMeshesAndparticlesForSubUpgrades()
		setCurrentInfo()
	end
	--
	local function init()
		--this:setIsStatic(true)
		Core.setUpdateHz(60.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		
		model = Core.getModel("tower_swarm_l1.mym")
		this:addChild(model:toSceneNode())
	
--		if particleEffectUpgradeAvailable then
--			this:addChild(particleEffectUpgradeAvailable:toSceneNode())
--		end
	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug myStats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
	
		billboard:setDouble("rangePerUpgrade",0.75)
		billboard:setModel("tower",model)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Swarm tower")
		billboard:setString("FileName", "Tower/SwarmTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		billboard:setFloat("baseRange", 6.5)
	
		--ComUnitCallbacks
		comUnitTable["boost"] = data.activateBoost
		comUnitTable["NetLaunch"] = NetLaunch
		comUnitTable["NetBall"] = NetBall
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
		if isThisReal then
			restartListener = Listener("RestartWave")
			restartListener:registerEvent("restartWave", restartWave)
			data.setRestoreFunction(restartListener, nil, nil)
		end
		
		
		data.addTowerUpgrade({	cost = {200,400,800},
								name = "upgrade",
								info = "swarm tower level",
								iconId = 56,
								level = 1,
								maxLevel = 3,
								stats = {
										range =				{ 6.5, 6.5, 6.5 },
										damage = 			{ 120, 370, 890},
										RPS = 				{ 1.0/2.25, 1.0/2.25, 1.0/2.25},
										fireballSpeed =		{ 5.5, 5.5, 5.5 },
										fireballLifeTime =	{ 13.0, 13.0, 13.0 },
										fieringTime =		{ 2.25, 2.25, 2.25 },
										targeting =			{ 1, 1, 1 },
										detonationRange =	{ 0.5, 1.0, 1.5 } }
							})
							

		
		data.addBoostUpgrade({	cost = 0,
								name = "boost",
								info = "swarm tower boost",
								duration = 10,
								cooldown = 3,
								iconId = 57,
								level = 0,
								maxLevel = 1,
								stats = {range = 		{ 0.75, func = data.add },
										damage =		{ 3, func = data.mul },
										RPS = 			{ 2.0, func = data.mul } }
							})
		
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "range",
								info = "swarm tower range",
								infoValues = {"range"},
								iconId = 59,
								level = 0,
								maxLevel = 3,
								achievementName = "Range",
								stats = {range = { 0.75, 1.5, 2.25, func = data.add }}
							})
		
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "burnDamage",
								info = "swarm tower damage",
								infoValues = {"damage"},
								iconId = 2,
								level = 0,
								maxLevel = 3,
								achievementName = "burnDamage",
								stats = {damage = { 1.3, 1.6, 1.9, func = data.mul }}
							})

--		data.addSecondaryUpgrade({	
--								cost = {100,200,300},
--								name = "burnDamage",
--								info = "swarm tower range",
--								infoValues = {"damage"},
--								iconId = 2,
--								level = 0,
--								maxLevel = 3,
--								achievementName = "FireDPS",
--								stats = {damage = { 1.3, 1.6, 1.9, func = data.mul }}
--							})

		
		data.buildData()
		
		if isCircleMap then
			billboard:setString("targetMods","attackPriorityTarget;attackWeakestTarget;attackStrongestTarget")
			targetMode = 1
			billboard:setInt("currentTargetMode",1)
		else
			billboard:setString("targetMods","attackPriorityTarget;attackWeakestTarget;attackStrongestTarget;attackClosestToExit")
			targetMode = 1
			billboard:setInt("currentTargetMode",1)
		end
	
		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(data.getValue("range"))
	
		initModel()
		setCurrentInfo()
		
	
		--ParticleEffects
		this:addChild( particleFireCenter:toSceneNode() )
		particleFireCenter:setLocalPosition(Vec3(0,2.1,0))
		
		pointLight = PointLight.new(Vec3(0,2.45,0),Vec3(5,2.5,0.0),1.25)
		this:addChild(pointLight:toSceneNode())
		
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