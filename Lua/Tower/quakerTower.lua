require("Tower/upgrade.lua")
require("Tower/xpSystem.lua")
require("Tower/supportManager.lua")
require("NPC/state.lua")
require("stats.lua")
require("Game/campaignTowerUpg.lua")
require("Game/targetSelector.lua")
require("Game/particleEffect.lua")
require("Game/mapInfo.lua")
--this = SceneNode()

QuakeTower = {}
function QuakeTower.new()
	local self = {}
	--stats
	local tStats = Stats.new()
	local waveCount = 1
	local myStats = {}
	--States
	local DROPPING = 1		--dropping the log to attack the enemy close by
	local RELOADING = 2		--pulling up the log
	local READY = 4			--waiting for an enemy to enter attack range
	local HOLD_READY = 8	--enemies are in range but holding back to attack
	--upgrades
	local upgrade = Upgrade.new()
	local supportManager = SupportManager.new()
	local cTowerUpg = CampaignTowerUpg.new("Tower/quakerTower.lua",upgrade)
	--XP
	local xpManager = XpSystem.new(upgrade)
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
	--communication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	--effects
	local quakeDust = ParticleSystem(ParticleEffect.QuakeDustLingeringEffect)
	local quakeDustBlast	--fireCrit
	local blasterFlame		--fireCrit
	local quakeFlameBlast	--fireStrike
	local fireBall			--fireStrike
	local firePointLigth	--fireStrike
	local electricBall		--electricStrike
	local electricPointLight--electricStrike
	local electrikStrike	--electricStrike
	local soundAttack		--electricStrike
	--stats
	local mapName = MapInfo.new().getMapName()
	--sound
	
	--
	--	XP / stats
	--
	local function myStatsReset()
		if myStats.dmgDone then
			billboard:setDouble("DamagePreviousWave",myStats.dmgDone)
			comUnit:sendTo("stats", "addTotalDmg", myStats.dmgDone )
		end
		myStats = {	activeTimer=0.0,
					hitts=0,
					attacks=0,	
					dmgDone=0.01,
					disqualified=false}
		myStatsTimer = Core.getGameTime()
	end
	local function damageDealt(param)
		local addDmg = supportManager.handleSupportDamage( tonumber(param) )
		myStats.hitts = myStats.hitts + 1
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
	local function damageLost(param)
		myStats.dmgLost = myStats.dmgLost + tonumber(param)
	end
	local function waveChanged(param)
		if not xpManager then
			local name
			name,waveCount = string.match(param, "(.*);(.*)")
			if myStats.disqualified==false and upgrade.getLevel("boost")==0  and Core.getGameTime()-myStatsTimer>0.25 and myStats.activeTimer>1.0 then
				myStats.disqualified = nil
				myStats.DPS = myStats.dmgDone/myStats.activeTimer
				myStats.DPSpG = myStats.DPS/upgrade.getTotalCost()
				myStats.DPG = myStats.dmgDone/upgrade.getTotalCost()
				--
				local key = "fireCrit"..upgrade.getLevel("fireCrit").."_fireStrike"..upgrade.getLevel("fireStrike").."_electricStrike"..upgrade.getLevel("electricStrike")
				tStats.addValue({mapName,"wave"..name,"quakeTower_l"..upgrade.getLevel("upgrade"),key,"sampleSize"},1)
				for variable, value in pairs(myStats) do
					tStats.setValue({mapName,"wave"..name,"quakeTower_l"..upgrade.getLevel("upgrade"),key,variable},value)
				end
			end
			myStatsReset()
		else
			xpManager.payStoredXp(waveCount)
			--update billboard
			upgrade.fixBillboardAndStats()
		end
	end
	--
	--	upgrades
	--
	local function setCurrentInfo()
		if xpManager then
			xpManager.updateXpToNextLevel()
		end
		if myStats.activeTimer and myStats.activeTimer>0.0001 then
			myStats.disqualified = true
		end
		
		if towerState~=DROPPING then
			towerState = READY
			reloadTimeLeft = 0.0
			dropTable.dist = 0.0
			dropTable.speed = 0.0
		end
		reloadTime = (1.0/upgrade.getValue("RPS"))
		targetSelector.setRange(upgrade.getValue("range"))
		--achievment
		if upgrade.getLevel("upgrade")==3 and (upgrade.getLevel("fireCrit")==3 or upgrade.getLevel("fireStrike")==3 or upgrade.getLevel("electricStrike")==3) then
			comUnit:sendTo("SteamAchievement","QuakeMaxed","")
		end
	end
	local function fixModel()
		log = model:getMesh("loog")
		model:getMesh("elementSmasher"):setVisible(upgrade.getLevel("fireStrike")>0 or upgrade.getLevel("electricStrike")>0)
		for i=1, upgrade.getLevel("upgrade") do
			model:getMesh("blaster"..i):setVisible(upgrade.getLevel("fireCrit")==i)
			model:getMesh("elementTower"..i):setVisible(upgrade.getLevel("fireStrike")==i or upgrade.getLevel("electricStrike")==i)
		end
		model:getMesh("boost"):setVisible( upgrade.getLevel("boost")==1 )
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
		if upgrade.getLevel("upgrade")==1 then
			dropLength = 0.77
		elseif upgrade.getLevel("upgrade")==2 then
			dropLength = 0.98
		else
			dropLength = 1.22
		end
	end
	function self.handleUpgrade(param)
		if tonumber(param)<=upgrade.getLevel("upgrade") then
			return
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade1",param)
		end
		upgrade.upgrade("upgrade")
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		--Achievements
		local level = upgrade.getLevel("upgrade")
		comUnit:sendTo("stats","addBillboardInt","level"..level..";1")
		if upgrade.getLevel("upgrade")==3 then
			comUnit:sendTo("SteamAchievement","Upgrader","")
		end
		--
		--clear out the old data
		this:removeChild(model)
		if upgrade.getLevel("upgrade")==1 then
			this:addChild( quakeDust )
		end
		if upgrade.getLevel("fireCrit")>0 then
			log:removeChild(blasterFlame)
		end
		--insert the new data
		model = Core.getModel( upgrade.getValue("model") )
		this:addChild(model)
		cTowerUpg.fixAllPermBoughtUpgrades()	
		fixModel()
		if upgrade.getLevel("fireCrit")>0 then
			log:addChild(blasterFlame)
		end
		upgrade.clearCooldown()
		setCurrentInfo()
	end
	local function handleBoost(param)
		if tonumber(param)<=upgrade.getLevel("boost") then
			return
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade2","1")
		end
		upgrade.upgrade("boost")
		model:getMesh("boost"):setVisible(true)
		setCurrentInfo()
		--Achievement
		comUnit:sendTo("SteamAchievement","Boost","")
	end
	local function handleFireCrit(param)
		if tonumber(param)<=upgrade.getLevel("fireCrit") or tonumber(param)>upgrade.getLevel("upgrade") then
			return
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade3",param)
		end
		if upgrade.getLevel("fireCrit")==0 then
			quakeDustBlast = ParticleSystem(ParticleEffect.QuakeDustEffect)
			blasterFlame = ParticleSystem(ParticleEffect.quakeBlaster)
			log:addChild(blasterFlame)
			this:addChild(quakeDustBlast)
		end
		if upgrade.getLevel("fireCrit")>0 then
			model:getMesh("blaster"..upgrade.getLevel("fireCrit")):setVisible(false)
		end
		upgrade.upgrade("fireCrit")
		model:getMesh("blaster"..upgrade.getLevel("fireCrit")):setVisible(true)
		setCurrentInfo()
		--Acievement
		if upgrade.getLevel("fireCrit")==3 then
			comUnit:sendTo("SteamAchievement","QuakeFireCrit","")
		end
	end
	local function handleFlameStrike(param)
		if tonumber(param)<=upgrade.getLevel("fireStrike") or tonumber(param)>upgrade.getLevel("upgrade") then
			return
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade4",param)
		end
		if upgrade.getLevel("fireStrike")==0 then
			quakeFlameBlast = ParticleSystem(ParticleEffect.qukeFireBlast)
			fireBall = ParticleSystem(ParticleEffect.quakeFireBall)
			firePointLigth = PointLight(Vec3(2.0,1.15,0.0),3.0)
			this:addChild( quakeFlameBlast )
			this:addChild( fireBall )
			this:addChild( firePointLigth )
			fireBall:activate(Vec3(0,0.75,0))
			firePointLigth:setLocalPosition( Vec3(0,0.75,0) )
		end
		if upgrade.getLevel("fireStrike")>0 then
			model:getMesh("elementTower"..upgrade.getLevel("fireStrike")):setVisible(false)
		end
		upgrade.upgrade("fireStrike")
		model:getMesh("elementTower"..upgrade.getLevel("fireStrike")):setVisible(true)
		model:getMesh("elementSmasher"):setVisible(true)
		setCurrentInfo()
		--Acievement
		if upgrade.getLevel("fireStrike")==3 then
			comUnit:sendTo("SteamAchievement","FireWall","")
		end
	end
	local function handleElectricStrike(param)
		if tonumber(param)<=upgrade.getLevel("electricStrike") or tonumber(param)>upgrade.getLevel("upgrade") then
			return
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade5",param)
		end
		if upgrade.getLevel("electricStrike")==0 then
			electricBall = ParticleSystem(ParticleEffect.SparkSpirit)
			electricPointLigth = PointLight(Vec3(0.0,1.5,1.5),3.0)
			soundAttack = SoundNode("electric_attack")
			electrikStrike = {token=0}
			this:addChild( electricBall )
			this:addChild( electricPointLigth )
			this:addChild( soundAttack )
			for i=1, 6 do
				electrikStrike[i] = {effect=ParticleEffectElectricFlash("Lightning_D.tga"), light=PointLight(Vec3(0.0,1.0,1.0),2.5)}
				this:addChild(electrikStrike[i].effect)
				this:addChild(electrikStrike[i].light)
			end
			electricBall:activate(Vec3(0,0.75,0))
			electricBall:setScale(0.5)
			electricPointLigth:setLocalPosition( Vec3(0,0.75,0) )
		end
		if upgrade.getLevel("electricStrike")>0 then
			model:getMesh("elementTower"..upgrade.getLevel("electricStrike")):setVisible(false)
		end
		upgrade.upgrade("electricStrike")
		model:getMesh("elementTower"..upgrade.getLevel("electricStrike")):setVisible(true)
		model:getMesh("elementSmasher"):setVisible(true)
		setCurrentInfo()
		--Acievement
		if upgrade.getLevel("electricStrike")==3 then
			comUnit:sendTo("SteamAchievement","ElectricStorm","")
		end
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
		upgrade.fixBillboardAndStats()
	end
	--
	--	targeting
	--
	local function isAnyOneInRange()
		targetSelector.selectAllInRange()
		return targetSelector.isAnyInRange()
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
			lightningItem.light:pushRangeChange(0.25,math.min((1.0/upgrade.getValue("RPS"))-0.05,0.5))
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
		targetSelector.setRange(upgrade.getValue("range"))
		targetSelector.selectAllInRange()
		if upgrade.getLevel("fireCrit")>0 then
			local targets = targetSelector.getAllTargets()
			local fireCritDamage = upgrade.getValue("damage")*(1.0+upgrade.getValue("fireCrit"))
			local damage = upgrade.getValue("damage")
			for index,score in pairs(targets) do
				if targetSelector.isTargetInState(index,state.burning) then
					comUnit:sendTo(index,"attack",tostring(fireCritDamage))
					comUnit:sendTo(index,"clearFire","")
					comUnit:sendTo("SteamAchievement","CriticalStrike","")
					damageDone = damageDone + fireCritDamage
				else
					comUnit:sendTo(index,"attack",tostring(damage))
				end
			end
			quakeDustBlast:activate(Vec3(0,0.6,0))
			quakeDust:activate(Vec3(0,0.4,0))
		elseif upgrade.getLevel("electricStrike")>0 then
			electricPointLigth:pushRangeChange(3,1.0)
			targetSelector.scoreHP(10)
			targetSelector.scoreClosestToExit(20)
			targetSelector.scoreName("rat",10)
			targetSelector.scoreName("rat_tank",10)
			targetSelector.scoreName("electroSpirit",-1000)
			local targets = targetSelector.selectTargetCountAfterMaxScore(-500,6)
			local dmg = tostring(upgrade.getValue("damage"))
			local slow = upgrade.getValue("slow")
			local duration = upgrade.getValue("slowTimer")
			local slowTab = {per=slow,time=duration,type="electric"}
			if #targets>0 then
				soundAttack:play(0.6,false)
			end
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
			if upgrade.getLevel("fireStrike")>0 then
				quakeFlameBlast:activate(Vec3(0,0.6,0))
				firePointLigth:pushRangeChange(3,1.0)
				fireBall:setScale(0.0)
			end
			local targets = targetSelector.getAllTargets()
			local fireDPS = upgrade.getValue("fireDPS")
			local fireTime = upgrade.getValue("burnTime")
			local dmg = upgrade.getValue("damage")
			for index,score in pairs(targets) do
				if upgrade.getLevel("fireStrike")>0 then
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
		comUnit:sendTo("SteamStats","QuakeMaxHittCount",targetSelector.getAllTargetCount())
		comUnit:sendTo("SteamStats","MaxDamageDealt",damageDone)
	end
	local function dropp()
		towerState = DROPPING
--		dropTable.dist = 0.0
--		dropTable.speed = 0.0
		reloadTimeLeft = (reloadTimeLeft+Core.getDeltaTime())>0.0 and (reloadTimeLeft+reloadTime) or reloadTime
		if upgrade.getLevel("fireCrit")>0 then
			blasterFlame:activate(Vec3(0,0,1.2))
		elseif upgrade.getLevel("fireStrike")>0 then
			firePointLigth:pushRangeChange(1,0.2)
		elseif upgrade.getLevel("electricStrike")>0 then
			electricPointLigth:pushRangeChange(1,0.2)
		end
	end
	function self.update()
		if upgrade.update() then
			model:getMesh("boost"):setVisible( false )
			setCurrentInfo()
		end
		
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
		--stats
		if DEBUG and targetSelector.selectAllInRange() and targetSelector.isAnyInRange() then
			myStats.activeTimer = myStats.activeTimer + Core.getDeltaTime()--debug
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
					hold.time = 0.6
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
			if upgrade.getLevel("fireStrike")>0 then
				fireBall:setScale(1.0-per)
			elseif upgrade.getLevel("electricStrike")>0 then
				electricBall:setScale( (1.0-per)*0.5 )
			end
			dropTable.dist = dropLength*per
		end
		if towerState==DROPPING then
			dropTable.speed = dropTable.speed + (4*Core.getDeltaTime())
			dropTable.dist = dropTable.dist + (dropTable.speed*Core.getDeltaTime())
			if upgrade.getLevel("fireStrike")>0 then
				local left = dropLength-dropTable.dist
				local scale = math.clamp(left/0.4,0,1)
				fireBall:setScale(scale)
			elseif upgrade.getLevel("electricStrike")>0 then
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
	--
	--
	--
	local function init()
		----this:setIsStatic(true)
		Core.setUpdateHz(48.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		if xpManager then
			xpManager.setUpgradeCallback(self.handleUpgrade)
		end
		--
		model = Core.getModel("tower_quaker_l1.mym")
		local hullModel = Core.getModel("tower_resource_hull.mym")
		this:addChild(model)
	
		if particleEffectUpgradeAvailable then
			this:addChild(particleEffectUpgradeAvailable)
		end
		--
		myStatsReset()
	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),3.0,"shockwave","")
		billboard:setDouble("rangePerUpgrade",0.75)
		billboard:setString("hullName","hull")
		billboard:setVectorVec3("hull3d",createHullList3d(hullModel:getMesh("hull")))
		billboard:setVectorVec2("hull2d",createHullList2d(hullModel:getMesh("hull")))
		billboard:setModel("tower",model)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Quake tower")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
	
		--ComUnitCallbacks
		comUnitTable["dmgDealt"] = damageDealt
		comUnitTable["waveChanged"] = waveChanged
		comUnitTable["upgrade1"] = self.handleUpgrade
		comUnitTable["upgrade2"] = handleBoost
		comUnitTable["upgrade3"] = handleFireCrit
		comUnitTable["upgrade4"] = handleFlameStrike
		comUnitTable["upgrade5"] = handleElectricStrike
		comUnitTable["NetOwner"] = setNetOwner
		supportManager.setComUnitTable(comUnitTable)
		supportManager.addCallbacks()
		
		upgrade.setBillboard(billboard)
		upgrade.addDisplayStats("damage")
		upgrade.addDisplayStats("RPS")
		upgrade.addDisplayStats("range")
		
		
		--AUHpR = 1.6
		--DPSpG = (DMG*SplashRange*AUHpR*RPS)/cost = (235*2.75*1.6*(1/3.5))/200 = 1.47
		upgrade.addUpgrade( {	cost = 200,
								name = "upgrade",
								info = "quak tower level",
								order = 1,
								icon = 56,
								value1 = 1,
								stats ={range =		{ upgrade.add, 2.75},
										damage = 	{ upgrade.add, 235},
										RPS = 		{ upgrade.add, 0.28},--1.0/3.5},
										model = 	{ upgrade.set, "tower_quaker_l1.mym"} }
							} )
		--DPSpG = (DMG*SplashRange*AUHpR*RPS)/cost = (645*2.75*1.6*(1/3.0))/600 = 1.58
		upgrade.addUpgrade( {	cost = 400,
								name = "upgrade",
								info = "quak tower level",
								order = 1,
								icon = 56,
								value1 = 2,
								stats ={range =		{ upgrade.add, 2.75},
										damage = 	{ upgrade.add, 645},
										RPS = 		{ upgrade.add, 0.34},--1.0/3.0},
										model = 	{ upgrade.set, "tower_quaker_l2.mym"} }
							}, 0 )
		--DPSpG = (DMG*SplashRange*AUHpR*RPS)/cost = (1330*2.75*1.6*(1/2.5))/1400 = 1.67
		upgrade.addUpgrade( {	cost = 800,
								name = "upgrade",
								info = "quak tower level",
								order = 1,
								icon = 56,
								value1 = 3,
								stats ={range =		{ upgrade.add, 2.75},
										damage = 	{ upgrade.add, 1330},
										RPS = 		{ upgrade.add, 0.4},--1.0/2.5},
										model = 	{ upgrade.set, "tower_quaker_l3.mym"} }
							}, 0 )
		function boostDamage() return upgrade.getStats("damage")*2.0*(waveCount/25+1.0) end
		--(total)	0=2x	25=4x	50=6x
		upgrade.addUpgrade( {	cost = 0,
								name = "boost",
								info = "quak tower boost",
								duration = 10,
								cooldown = 3,
								order = 10,
								icon = 57,
								stats ={range =		{ upgrade.add, 0.5},
										damage = 	{ upgrade.func, boostDamage},
										RPS = 		{ upgrade.mul, 1.25}}
							} )
		-- firecrit
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fireCrit",
								info = "quak tower firecrit",
								order = 2,
								icon = 36,
								value1 = 40,
								levelRequirement = cTowerUpg.getLevelRequierment("fireCrit",1),
								requirementNotUpgraded1 = "fireStrike",
								requirementNotUpgraded2 = "electricStrike",
								stats = {	fireCrit = 	{ upgrade.add, 0.40, ""}}
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fireCrit",
								info = "quak tower firecrit",
								order = 2,
								icon = 36,
								value1 = 80,
								levelRequirement = cTowerUpg.getLevelRequierment("fireCrit",2),
								stats = {	fireCrit = 	{ upgrade.add, 0.80, ""}}
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fireCrit",
								info = "quak tower firecrit",
								order = 2,
								icon = 36,
								value1 = 120,
								levelRequirement = cTowerUpg.getLevelRequierment("fireCrit",3),
								stats = {	fireCrit = 	{ upgrade.add, 1.20, ""}}
							} )
		--fire strike
		function fireDamage1() return upgrade.getStats("damage") * 0.15 end
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fireStrike",
								info = "quak tower fire",
								order = 3,
								icon = 38,
								value1 = 15,--15% fire damage
								value2 = 1,--1 seconds
								levelRequirement = cTowerUpg.getLevelRequierment("fireStrike",1),
								requirementNotUpgraded1 = "fireCrit",
								requirementNotUpgraded2 = "electricStrike",
								stats ={fireDPS =		{ upgrade.set, fireDamage1},
										burnTime =		{ upgrade.add, 1.0} }
							} )
		function fireDamage2() return upgrade.getStats("damage") * 0.17 end
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fireStrike",
								info = "quak tower fire",
								order = 3,
								icon = 38,
								value1 = 17,
								value2 = 1.75,
								levelRequirement = cTowerUpg.getLevelRequierment("fireStrike",2),
								stats ={fireDPS =		{ upgrade.set, fireDamage2},
										burnTime =		{ upgrade.add, 1.75} }
							} )
		function fireDamage3() return upgrade.getStats("damage") * 0.18 end
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fireStrike",
								info = "quak tower fire",
								order = 3,
								icon = 38,
								value1 = 18,
								value2 = 2.5,
								levelRequirement = cTowerUpg.getLevelRequierment("fireStrike",3),
								stats ={fireDPS =		{ upgrade.set, fireDamage3},
										burnTime =		{ upgrade.add, 2.5} }
							} )
		--electric strike
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "electricStrike",
								info = "quak tower electric",
								order = 4,
								icon = 50,
								value1 = 25,--25% extra damage
								value2 = 15,--15% slow
								value3 = 2,--2 seconds
								levelRequirement = cTowerUpg.getLevelRequierment("electricStrike",1),
								requirementNotUpgraded1 = "fireCrit",
								requirementNotUpgraded2 = "fireStrike",
								stats ={damage =	{ upgrade.mul, 1.25},
										slow = 		{ upgrade.add, 0.15},
										slowTimer =	{ upgrade.add, 2.0},
										count =		{ upgrade.add, 6}}
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "electricStrike",
								info = "quak tower electric",
								order = 4,
								icon = 50,
								value1 = 50,--50% extra damage
								value2 = 28,--28% slow
								value3 = 2,--2 seconds
								levelRequirement = cTowerUpg.getLevelRequierment("electricStrike",2),
								stats ={damage =	{ upgrade.mul, 1.50},
										slow = 		{ upgrade.add, 0.28},
										slowTimer =	{ upgrade.add, 2.0},
										count =		{ upgrade.add, 6}}
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "electricStrike",
								info = "quak tower electric",
								order = 4,
								icon = 50,
								value1 = 75,--75% extra damage
								value2 = 39,--39% slow
								value3 = 2,--2 seconds
								levelRequirement = cTowerUpg.getLevelRequierment("electricStrike",3),
								stats ={damage =	{ upgrade.mul, 1.75},
										slow = 		{ upgrade.add, 0.39},
										slowTimer =	{ upgrade.add, 2.0},
										count =		{ upgrade.add, 6}}
							} )
		supportManager.setUpgrade(upgrade)
		supportManager.addHiddenUpgrades()
		self.handleUpgrade("1")
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		billboard:setString("targetMods","")
		billboard:setInt("currentTargetMode",0)
		for i=1, 3 do
			if cTowerUpg.getIsPermUpgraded("freeUpgrade",i) then
				upgrade.addFreeSubUpgrade()
			end
		end
	
		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(1.0)
		
		setCurrentInfo()
		cTowerUpg.addUpg("fireCrit",handleFireCrit)
		cTowerUpg.fixAllPermBoughtUpgrades()
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