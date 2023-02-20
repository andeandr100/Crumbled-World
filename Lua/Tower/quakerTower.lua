require("NPC/state.lua")
require("Game/targetSelector.lua")
require("Game/particleEffect.lua")
require("Game/mapInfo.lua")
require("Game/soundManager.lua")
require("Tower/TowerData.lua")

--this = SceneNode()

QuakeTower = {}
function QuakeTower.new()
	local self = {}
	local TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION = 0.2
	--stats
	local waveCount = 1
	local dmgDone = 0
	--States
	local DROPPING = 1		--dropping the log to attack the enemy close by
	local RELOADING = 2		--pulling up the log
	local READY = 4			--waiting for an enemy to enter attack range
	local HOLD_READY = 8	--enemies are in range but holding back to attack
	--upgrades
	local data = TowerData.new()
	local boostActive = false
	--model
	local model
	local log
	local cogs
	--targeting
	local targetSelector = TargetSelector.new(activeTeam)
	local reloadTimeLeft = 0.0
	local reloadTime = 3.0
	local towerState = READY
	local defaultPos = Vec3()
	local dropLength = 0.0
	local startReloadTime = 0.0
	local dropTable = {}
	local hold = {}
	local boostedOnLevel = 0
	--communication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local billboardWaveStats
	--effects
	local quakeDust = ParticleSystem.new(ParticleEffect.QuakeDustLingeringEffect)
	local quakeDustBlast	--fireCrit
	local blasterFlame		--fireCrit
	local quakeFlameBlast	--fireStrike
	local fireBall			--fireStrike
	local firePointLigth	--fireStrike
	local electricBall		--electricStrike
	local electricPointLight--electricStrike
	local electrikStrike	--electricStrike
	--stats
	local mapName = MapInfo.new().getMapName()
	--sound
	local attackSounds = {"electric_attack1", "electric_attack2", "electric_attack3", "electric_attack4"}
	local soundManager = SoundManager.new(this)
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
		--------------------
		--- Handle Boost ---
		--------------------
		
		model:getMesh("boost"):setVisible( data.getBoostActive() )
		
		--------------------------------
		--- Handle fireCrit upgrades ---
		--------------------------------
		
		if data.getLevel("fireCrit")>0 then
			if (not quakeDustBlast) or (not blasterFlame) then
				quakeDustBlast = ParticleSystem.new(ParticleEffect.QuakeDustEffect)
				blasterFlame = ParticleSystem.new(ParticleEffect.quakeBlaster)
				log:addChild(blasterFlame:toSceneNode())
				this:addChild(quakeDustBlast:toSceneNode())
			end
			for i=1, data.getTowerLevel() do
				model:getMesh("blaster"..i):setVisible(data.getLevel("fireCrit") == i)
			end
		end
		
		----------------------------------
		--- Handle fireStrike upgrades ---
		----------------------------------
		
		for i=1, data.getTowerLevel() do
			model:getMesh("elementTower"..i):setVisible(false)
		end
		
		
		if true then
			if quakeFlameBlast  then
				quakeFlameBlast:deactivate()
				fireBall:deactivate()
				firePointLigth:setVisible(false)
			end
		else
			if quakeFlameBlast==nil  then
				quakeFlameBlast = ParticleSystem.new(ParticleEffect.qukeFireBlast)
				fireBall = ParticleSystem.new(ParticleEffect.quakeFireBall)
				firePointLigth = PointLight.new(Vec3(2.0,1.15,0.0),3.0)
				this:addChild( quakeFlameBlast:toSceneNode() )
				this:addChild( fireBall:toSceneNode() )
				this:addChild( firePointLigth:toSceneNode() )
			end
			fireBall:activate(Vec3(0,0.75,0))
			firePointLigth:setLocalPosition( Vec3(0,0.75,0) )
			model:getMesh("elementSmasher"):setVisible(true)
		end
		
		--------------------------------------
		--- Handle electricStrike upgrades ---
		--------------------------------------
		
		for i=1, data.getTowerLevel() do
			model:getMesh("elementTower"..i):setVisible(data.getLevel("electricStrike") == i)
		end
		
		if data.getLevel("electricStrike")==0 then
			if electricBall then
				electricBall:deactivate()
				electricPointLigth:setVisible(false)
				for i=1, 6 do
					electrikStrike[i].light:setVisible(false)
				end
			end
		else
			if electricBall==nil then
				electricBall = ParticleSystem.new(ParticleEffect.SparkSpirit)
				electricPointLigth = PointLight.new(Vec3(0.0,1.5,1.5),3.0)
				electrikStrike = {token=0}
				this:addChild( electricBall:toSceneNode() )
				this:addChild( electricPointLigth:toSceneNode() )
				for i=1, 6 do
					electrikStrike[i] = {effect=ParticleEffectElectricFlash.new("Lightning_D.tga"), light=PointLight.new(Vec3(0.0,1.0,1.0),2.5)}
					this:addChild(electrikStrike[i].effect:toSceneNode())
					this:addChild(electrikStrike[i].light:toSceneNode())
				end
			end
			electricBall:activate(Vec3(0,0.75,0))
			electricBall:setScale(0.5)
			electricPointLigth:setLocalPosition( Vec3(0,0.75,0) )
			if data.getLevel("electricStrike")>1 then
				model:getMesh("elementTower"..(data.getLevel("electricStrike")-1)):setVisible(false)
			end
			model:getMesh("elementTower"..data.getLevel("electricStrike")):setVisible(true)
			model:getMesh("elementSmasher"):setVisible(true)
			--Acievement
			if data.getLevel("electricStrike")==3 then
				achievementUnlocked("ElectricStorm")
			end
		end
	end
	
	--
	--	upgrades
	--
	local function setCurrentInfo()
		
		data.updateStats()
	
		if towerState~=DROPPING then
			towerState = READY
			reloadTimeLeft = 0.0
			dropTable.dist = 0.0
			dropTable.speed = 0.0
		end
		reloadTime = (1.0/data.getValue("RPS"))
		targetSelector.setRange(data.getValue("range"))
	end
	local function fixModel(setDefault)
		log = model:getMesh("loog")
		model:getMesh("elementSmasher"):setVisible( data.getLevel("electricStrike")>0)
		for i=1, data.getTowerLevel() do
			model:getMesh("blaster"..i):setVisible(data.getLevel("fireCrit")==i)
			model:getMesh("elementTower"..i):setVisible(data.getLevel("electricStrike")==i)
		end
		model:getMesh("boost"):setVisible( data.getBoostActive() )
		--set ambient map
		for index=0, model:getNumMesh()-1 do
			local mesh = model:getMesh(index)
			local shader = mesh:getShader()
			local texture = Core.getTexture(data.getBoostActive() and "towergroup_boost_a" or "towergroup_a")
			mesh:setTexture(shader,texture,4)
		end
		if setDefault then
			cogs = {}
			for i=1, 4, 1 do
				cogs[i] = {mesh=model:getMesh("cog"..i)}
				local atVec = cogs[i].mesh:getLocalPosition()
				atVec.y = 0.0
				local mat = Matrix()
				mat:createMatrix(atVec,Vec3(0,1,0))
				cogs[i].rightVec = Vec3(0,1,0)
			end
			defaultPos = model:getMesh("loog"):getLocalPosition()
			if data.getTowerLevel() == 1 then
				dropLength = 0.77
			elseif data.getTowerLevel()==2 then
				dropLength = 0.98
			else
				dropLength = 1.22
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
		local newModel = Core.getModel( "tower_quaker_l"..data.getTowerLevel()..".mym" )
		if newModel then
			this:removeChild(model:toSceneNode())
			model = newModel
			
			this:addChild(model:toSceneNode())
			billboard:setModel("tower",model)
			
			fixModel(true)
			
			if data.getLevel("fireCrit")>0 then
				log:addChild(blasterFlame:toSceneNode())
			end
		end
		
		setCurrentInfo()
		updateMeshesAndparticlesForSubUpgrades()
		
	end
	
	
	--
	--	Network sync
	--
	local function setNetOwner(param)
		if param=="YES" then
			billboard:setBool("isNetOwner",true)
		else
			billboard:setBool("isNetOwner",false)
		end
		--set the game sessionBillboard first here after this function we are sure that the builder has set the network id
		data.setGameSessionBillboard( Core.getGameSessionBillboard( "tower_"..Core.getNetworkName() ) )
		data.updateStats()
	end
	--
	--	targeting
	--
	local function isAnyOneInRange()
		if targetSelector.selectAllInRange() then
			if data.getLevel("electricStrike")>0 then
				targetSelector.scoreName("electroSpirit",-1000)
				if targetSelector.selectTargetAfterMaxScore(-500)>0 then
					return true
				end
			else
				return true
			end
		end
		if targetSelector.getTarget()==0 then
			reloadTimeLeft = TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION
		end
		return false
	end
	--
	--
	--
	local function doLightning(targetPosition,lightningItem,sphere)
		if targetPosition:length()>0.01 then
		
			local endPos = (this:getGlobalMatrix():inverseM()*targetPosition)
			endPos = endPos + (endPos:normalizeV()*math.randomFloat(0.25,2.0))
			
			lightningItem.light:setLocalPosition( (Vec3(0,0.65,0)+endPos)*0.5 )
			lightningItem.light:setVisible(true)
			lightningItem.light:setRange(4.0)
			lightningItem.light:pushRangeChange(0.25,math.min((1.0/data.getValue("RPS"))-0.05,0.5))
			lightningItem.light:pushVisible(false)
			
		
			if sphere then
				sphere = Sphere(this:getGlobalMatrix():inverseM()*sphere:getPosition(),sphere:getRadius())
				lightningItem.effect:setLine(Vec3(0,0.65,0),endPos,sphere,0.45)
			else
				lightningItem.effect:setLine(Vec3(0,0.65,0),endPos,0.45)
			end
		end
	end
	local function attack()
		local damageDone = 0
		targetSelector.setRange(data.getValue("range"))
		targetSelector.selectAllInRange()
		if data.getLevel("fireCrit")>0 then
			local targets = targetSelector.getAllTargets()
			local fireCritDamage = data.getValue("damage")
			local damage = data.getValue("damage")
			--sounds
			soundManager.play("quake_attack", 1.0, false)
			--
			for index,score in pairs(targets) do
				if targetSelector.isTargetInState(index,state.burning) then
					comUnit:sendTo(index,"attack",tostring(fireCritDamage))
					comUnit:sendTo(index,"clearFire","")
					achievementUnlocked("CriticalStrike")
					damageDone = damageDone + fireCritDamage
				else
					comUnit:sendTo(index,"attack",tostring(damage))
				end
			end
			quakeDustBlast:activate(Vec3(0,0.6,0))
			quakeDust:activate(Vec3(0,0.4,0))
		elseif data.getLevel("electricStrike")>0 then
			electricPointLigth:pushRangeChange(3,1.0)
			targetSelector.scoreHP(10)
			targetSelector.scoreClosestToExit(20)
			targetSelector.scoreName("rat",10)
			targetSelector.scoreName("rat_tank",10)
			targetSelector.scoreName("electroSpirit",-1000)
			local targets = targetSelector.selectTargetCountAfterMaxScore(-500,6)
			local dmg = tostring(data.getValue("damage"))
			local slow = data.getValue("slow")
			local duration = data.getValue("slowTimer")
			local slowTab = {per=slow,time=duration,type="electric"}
			--sounds
			if #targets>0 then
				soundManager.play(attackSounds[math.randomInt(1,#attackSounds)], 1.0, false)
			end
			soundManager.play("quake_attack", 1.0, false)
			--
			for i=1, #targets do
				electrikStrike.token = (electrikStrike.token%6) + 1
				local item = electrikStrike[electrikStrike.token]
				local targetPosition = targetSelector.getTargetPosition(targets[i])
				--
				if targetSelector.getIndexOfShieldCovering(targetPosition)==targetSelector.getIndexOfShieldCovering(this:getGlobalPosition()) then
					--direct hitt
					local endPos = this:getGlobalMatrix():inverseM()*targetSelector.getTargetPosition(targets[i])
					--electrikStrike[electrikStrike.token]:setLine(Vec3(0,0.65,0), endPos, 0.35)
					comUnit:sendTo(targets[i],"attackElectric",dmg)
					comUnit:sendTo(targets[i],"slow",slowTab)
					damageDone = damageDone + dmg
					doLightning(targetPosition,item)
				else
					--forcefield hitt
					local shieldIndex = targetSelector.getIndexOfShieldCovering(targetPosition)>0 and targetSelector.getIndexOfShieldCovering(targetPosition) or targetSelector.getIndexOfShieldCovering(this:getGlobalPosition())
					doLightning(targetPosition,item,Sphere(targetSelector.getTargetPosition(shieldIndex),3.5))
					comUnit:sendTo(shieldIndex,"attack",dmg)
					damageDone = damageDone + dmg
					--hitt effect
					local oldPosition = this:getGlobalPosition()+Vec3(0,0.65,0)
					local futurePosition = targetPosition
					local hitTime = "1.25"
					comUnit:sendTo(shieldIndex,"addForceFieldEffect",tostring(oldPosition.x)..";"..oldPosition.y..";"..oldPosition.z..";"..futurePosition.x..";"..futurePosition.y..";"..futurePosition.z..";"..hitTime)
				end
			end
		else
			if false then
				quakeFlameBlast:activate(Vec3(0,0.6,0))
				firePointLigth:pushRangeChange(3,1.0)
				fireBall:setScale(0.0)
				soundManager.play("fireFlash", 1.0, false)
			else
				soundManager.play("quake_attack", 1.0, false)
			end
			local targets = targetSelector.getAllTargets()
			local fireDPS = data.getValue("fireDPS")
			local fireTime = data.getValue("burnTime")
			local dmg = data.getValue("damage")
			for index,score in pairs(targets) do
				local distance = (this:getGlobalPosition()-targetSelector.getTargetPosition(index)):length()
				if false and data.getValue("range")>=distance then
					comUnit:sendTo(index,"attackFireDPS",{DPS=fireDPS,time=fireTime,type="fire"})
					damageDone = damageDone + (fireDPS*fireTime)
				end
				comUnit:sendTo(index,"attack",tostring(dmg))
				damageDone = damageDone + dmg
			end
			quakeDust:activate(Vec3(0,0.4,0))
		end
		--steam stats
		targetSelector.selectAllInRange()
		if canSyncTower() then
			comUnit:sendTo("SteamStats","QuakeMaxHittCount",targetSelector.getAllTargetCount())
			comUnit:sendTo("SteamStats","MaxDamageDealt",damageDone)
		end
	end
	local function dropp()
		towerState = DROPPING
--		dropTable.dist = 0.0
--		dropTable.speed = 0.0
		reloadTimeLeft = (reloadTimeLeft+Core.getDeltaTime())>0.0 and (reloadTimeLeft+reloadTime) or reloadTime
		if data.getLevel("fireCrit")>0 then
			blasterFlame:activate(Vec3(0,0,1.2))
		elseif false then
			firePointLigth:pushRangeChange(1,0.2)
		elseif data.getLevel("electricStrike")>0 then
			electricPointLigth:pushRangeChange(1,0.2)
		end
	end
	function self.update()
		comUnit:setPos(this:getGlobalPosition())
		
		--handle boost
		if boostActive ~= data.getBoostActive() then
			boostActive = data.getBoostActive()	
			setCurrentInfo()
			updateMeshesAndparticlesForSubUpgrades()
		end
		
		--handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end

		--Tower spesefic stuff
		reloadTimeLeft = reloadTimeLeft - Core.getDeltaTime()
		if towerState==HOLD_READY then
			--enemies are in range but holding back to attack
			hold.time = hold.time - Core.getDeltaTime()
			targetSelector.selectAllInRange()
			local newCount = targetSelector.getAllTargetCount()
			if hold.count~=newCount then
				if hold.count<newCount then
					hold.count = newCount
					hold.time = 0.6
				else
					reloadTimeLeft = -1.0
				end
			end
			if reloadTimeLeft<=0.0 or hold.time<=0.0 then
				if isAnyOneInRange() then
					--timed out do the attack
					dropp()
				else
					--if we missed our window of oppertunity
					towerState = READY
				end
			end
		end
		if towerState==READY then
			if reloadTimeLeft<=0.0 and isAnyOneInRange() then
				--if we have been waiting to attack and get someone in range then the group has just reached the edge wait some time before attack
				if reloadTimeLeft<-0.2 and targetSelector.getAllTargetCount()==1 then
					reloadTimeLeft = 1.75
					towerState = HOLD_READY
					hold.count = targetSelector.getAllTargetCount()
					hold.time = 0.5
				else
					--attack
					dropp()
				end
			end
		end
		local previousDist = dropTable.dist
		if towerState==RELOADING then
			local per = math.clamp((reloadTimeLeft-0.1)/(startReloadTime-0.1),0.0,1.0)
			if per<0.01 then
				towerState = READY
				per = 0.0
			end
			if false then
				fireBall:setScale(1.0-per)
			elseif data.getLevel("electricStrike")>0 then
				electricBall:setScale( (1.0-per)*0.5 )
			end
			dropTable.dist = dropLength*per
		end
		if towerState==DROPPING then
			dropTable.speed = dropTable.speed + (4*Core.getDeltaTime())
			dropTable.dist = dropTable.dist + (dropTable.speed*Core.getDeltaTime())
			if false then
				local left = dropLength-dropTable.dist
				local scale = math.clamp(left/0.4,0,1)
				fireBall:setScale(scale)
			elseif data.getLevel("electricStrike")>0 then
				local left = dropLength-dropTable.dist
				local scale = math.clamp(left/0.4,0,1)*0.5
				electricBall:setScale(scale)
			end
			if dropTable.dist>=dropLength then
				dropTable.dist = dropLength
				towerState = RELOADING
				startReloadTime = reloadTimeLeft-0.1
				attack()
			end
		end
		log:setLocalPosition( defaultPos+Vec3(0,-dropTable.dist,0) )
		
		local dist = previousDist-dropTable.dist
		local rotation = dist/(math.pi*0.2)*(math.pi*2.0)
		for i=1, 4 do
			cogs[i].mesh:rotate(cogs[i].rightVec,rotation)
		end
		return true
	end
	function self.handleSubUpgrade()
		updateMeshesAndparticlesForSubUpgrades()
		setCurrentInfo()
	end
	--
	--
	--
	local function init()
		----this:setIsStatic(true)
		Core.setUpdateHz(48.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end

		--
		model = Core.getModel("tower_quaker_l1.mym")
		this:addChild(model:toSceneNode())
	
		
		--sound limits
		for i=1, #attackSounds do
			local s1 = SoundNode.new(attackSounds[i])
			s1:setSoundPlayLimit(2)
		end
		local s1 = SoundNode.new("quake_attack")
		local s2 = SoundNode.new("fireFlash")
		s1:setSoundPlayLimit(2)
		s2:setSoundPlayLimit(2)
	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
		billboard:setDouble("rangePerUpgrade",0.75)
		billboard:setModel("tower",model)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Quake tower")
		billboard:setString("FileName", "Tower/quakerTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		billboard:setFloat("baseRange", 2.75)
		--
		billboard:setDouble("DamageCurrentWave",0)
		billboard:setDouble("DamagePreviousWave",0)
	
		--ComUnitCallbacks
		comUnitTable["boost"] = data.activateBoost
		
		data.setBillboard(billboard)
		data.setCanSyncTower(canSyncTower())
		data.setComUnit(comUnit, comUnitTable)
		data.setTowerUpgradeCallback(self.handleUpgrade)
		data.setUpgradeCallback(self.handleSubUpgrade)
		data.setMaxedOutAchivement("QuakeMaxed")
		data.enableSupportManager()
		data.addDisplayStats("damage")
		data.addDisplayStats("RPS")
		data.addDisplayStats("range")
		data.addDisplayStats("slow")
		if isThisReal then
			restartListener = Listener("RestartWave")
			data.setRestoreFunction(restartListener, nil, nil)
		end
	
		
		data.addTowerUpgrade({	cost = {200,400,800},
								name = "upgrade",
								info = "quak tower level",
								iconId = 56,
								level = 1,
								maxLevel = 3,
								stats = {
										range =				{ 2.75, 2.75, 2.75 },
										damage = 			{ 215, 580, 1200},
										RPS = 				{ 0.28, 0.34, 0.4} }
							})
							

		
		data.addBoostUpgrade({	cost = 0,
								name = "boost",
								info = "quak tower boost",
								duration = 10,
								cooldown = 3,
								iconId = 57,
								level = 0,
								maxLevel = 1,
								stats = {range = 		{ 0.4, func = data.add },
										damage =		{ 3, func = data.mul },
										RPS = 			{ 1.35, func = data.mul } }
							})
		
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "fireCrit",
								info = "quak tower firecrit",
								infoValues = {"damage"},
								iconId = 36,
								level = 0,
								maxLevel = 3,
								callback = self.handleSubUpgrade,
								achievementName = "Range",
								stats = {damage = { 1.3, 1.6, 1.9, func = data.mul }}
							})
							
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "electricStrike",
								info = "quak tower electric",
								infoValues = {"damage","slow"},
								iconId = 50,
								level = 0,
								maxLevel = 3,
								callback = self.handleSubUpgrade,
								achievementName = "ElectricStorm",
								stats = {damage = 	{ 1.3, 1.6, 1.9, func = data.mul },
										slow = 		{ 0.15, 0.28, 0.39, func = data.set },
										slowTimer = { 2.0, 2.0, 2.0, func = data.set },
										count = 	{ 7, 7, 7, func = data.set } }
							})

		
		data.buildData()

		self.handleUpgrade("upgrade;1")
		billboard:setInt("level",data.getTowerLevel())
		billboard:setString("targetMods","")
		billboard:setInt("currentTargetMode",0)
	
		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(data.getValue("range"))

		
		updateMeshesAndparticlesForSubUpgrades()
		return true
	end
	init()
	--
	return self
end
function create()
	quakeTower = QuakeTower.new()
	update = quakeTower.update
	return true
end