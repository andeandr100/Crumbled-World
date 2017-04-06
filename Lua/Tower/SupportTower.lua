require("Tower/upgrade.lua")
require("NPC/state.lua")
require("Tower/xpSystem.lua")
require("stats.lua")
require("Projectile/projectileManager.lua")
require("Projectile/SwarmBall.lua")
require("Game/campaignTowerUpg.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
--this = SceneNode()
SwarmTower = {}
function SwarmTower.new()
	local self = {}
	local myStats = {}
	local myStatsTimer = 0
	local waveCount = 0
	local tStats = Stats.new()
	local cData = CampaignData.new()
	local upgrade = Upgrade.new()
	local cTowerUpg = CampaignTowerUpg.new("Tower/SupportTower.lua",upgrade)
	local range = 2.5
	--Weaken
	local weakenPer
	local weakeningArea
	local weakenTimer
	local weakenUpdateTimer
	--Gold
	local goldGainAmount
	local goldUpdateTimer
	--XP
	local xpManager = XpSystem.new(upgrade)
	--model
	local model
	local meshCrystal --meshCrystal = Mesh()
	local meshRange
	local timer = 0.0
	--effects
	sparkCenter = ParticleSystem(ParticleEffect.EndCrystal)
	weakenEffects = {}
	weakenPointLight = {}
	--communication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	--sound
	--targetSelector
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this
	
	-- function:	myStatsReset
	-- purpose:		resets the stats collected for the tower during the previous wave
	local function myStatsReset()
		if myStats.dmgDone then
			billboard:setDouble("DamagePreviousWave",myStats.dmgDone)
			billboard:setDouble("DamagePreviousWavePassive",myStats.dmgDoneMarkOfDeath or 0.0)
			billboard:setDouble("goldEarnedPreviousWave",myStats.goldEarned)
			billboard:setDouble("goldEarned",billboard:getDouble("goldEarned")+myStats.goldEarned)
			comUnit:sendTo("stats", "addTotalDmg", myStats.dmgDone+(myStats.dmgDoneMarkOfDeath or 0.0) )
		end
		myStats = {	activeTimer=0.0,	
					dmgDone=0,
					dmgDoneMarkOfDeath=0,
					goldEarned = 0,
					inoverHeatTimer=0.0,
					hitts=0,
					projectileLaunched=0,
					disqualified=false}
		myStatsTimer = Core.getGameTime()
	end
	-- function:	damageDealt
	-- purpose:		called when the tower have done some damage
	-- param:		the amount of damage dealt
	local function damageDealt(param)
		myStats.dmgDone = myStats.dmgDone + tonumber(param)
		billboard:setDouble("DamageCurrentWave",myStats.dmgDone)
		billboard:setDouble("DamageTotal",billboard:getDouble("DamagePreviousWave")+myStats.dmgDone+(myStats.dmgDoneMarkOfDeath or 0.0))
		if xpManager then
			xpManager.addXp(tonumber(param))
			local interpolation  = xpManager.getLevelPercentDoneToNextLevel()
			upgrade.setInterpolation(interpolation)
			upgrade.fixBillboardAndStats()
		end
	end
	-- function:	waveChanged
	-- purpose:		called on wavechange. updates the towers stats
	local function waveChanged(param)
		if not xpManager then
			local name
			name,waveCount = string.match(param, "(.*);(.*)")
			if myStats.disqualified==false and upgrade.getLevel("boost")==0 and Core.getGameTime()-myStatsTimer>0.25 and myStats.activeTimer>0 then
				myStats.disqualified=nil
				myStats.DPS =myStats.dmgDone/myStats.activeTimer
				myStats.DPSpG = myStats.DPS/upgrade.getTotalCost()
				myStats.DPG = myStats.dmgDone/upgrade.getTotalCost()
				myStats.hittsPerProjectile = myStats.hitts / myStats.projectileLaunched
				--myStats.hitts=nil
				if upgrade.getLevel("overCharge")==0 then myStats.inoverHeatTimer=nil end
				local key = "burnDamage"..upgrade.getLevel("burnDamage").."_fuel"..upgrade.getLevel("fuel").."_smartTargeting"..upgrade.getLevel("smartTargeting")
				tStats.addValue({"wave"..name,"swarmTower_l"..upgrade.getLevel("upgrade"),key,"sampleSize"},1)
				if myStats.activeTimer>1.0 then
					for variable, value in pairs(myStats) do
						tStats.setValue({"wave"..name,"swarmTower_l"..upgrade.getLevel("upgrade"),key,variable},value)
					end
				end
			end
			myStatsReset()
		else
			xpManager.payStoredXp(waveCount)
			--update billboard
			upgrade.fixBillboardAndStats()
		end
	end
	-- function:	dmgDealtMarkOfDeath
	-- purpose:		called when a unit has taken increased damage because of weaken
	-- param:		the amount of damage increased
	local function dmgDealtMarkOfDeath(param)
		myStats.dmgDoneMarkOfDeath = myStats.dmgDoneMarkOfDeath + tonumber(param)
		billboard:setDouble("DamageCurrentWavePassive",myStats.dmgDoneMarkOfDeath or 0.0)
	end
	-- function:	handleGoldStats
	-- purpose:		called when a unit has died with the effect active
	local function handleGoldStats(param)
		myStats.goldEarned = myStats.goldEarned + tonumber(param)
		billboard:setDouble("goldEarnedCurrentWave",myStats.goldEarned)
	end
	-- function:	sendSupporUpgrade
	-- purpose:		broadcasting what upgrades the towers close by should use
	local function sendSupporUpgrade()
		comUnit:broadCast(this:getGlobalPosition(),upgrade.getValue("range"),"supportRange",upgrade.getLevel("range"))
		comUnit:broadCast(this:getGlobalPosition(),upgrade.getValue("range"),"supportDamage",upgrade.getLevel("damage"))
	end
	-- function:	setCurrentInfo
	-- purpose:		
	local function setCurrentInfo()
		if xpManager then
			xpManager.updateXpToNextLevel()
		end
		if myStats.activeTimer and myStats.activeTimer>0.0001 then
			myStats.disqualified = true
		end
		--
		meshRange = upgrade.getLevel("range")==0 and nil or model:getMesh( "range"..upgrade.getLevel("range") )
		if upgrade.getLevel("weaken")>0 then
			weakenPer = upgrade.getValue("weaken")
			weakenTimer = upgrade.getValue("weakenTimer")
			weakenUpdateTimer = 0.0
		end
		range = upgrade.getValue("range")
		--manage support upgrades
		sendSupporUpgrade()
	end
	-- function:	initModel
	-- purpose:		to initialize the model and set the visibility flag for every mesh
	local function initModel()
		--update the bounding volume for the tower
		model:createBoundVolumeGroup()
		model:setBoundingVolumeCanShrink(false)
		
		--set visibility on all meshes
		model:getMesh( "physic" ):setVisible(false)
		model:getMesh( "weaken" ):setVisible(upgrade.getLevel("weaken")>0)
		model:getMesh( "boost" ):setVisible(upgrade.getLevel("boost")>0)
		for i=1, upgrade.getLevel("upgrade") do
			model:getMesh( "range"..i ):setVisible(upgrade.getLevel("range")==i)
			model:getMesh( "dmg"..i ):setVisible(upgrade.getLevel("damage")==i)
		end
		
		--get all meshes that we will interact with later
		if meshCrystal then
			meshCrystal:removeChild( sparkCenter )
		end
		meshCrystal = model:getMesh( "crystal" )
		meshCrystal:addChild( sparkCenter )
		sparkCenter:activate(Vec3(0,0,1))
		local rangeMatrix
		if meshRange then
			rangeMatrix = meshRange:getLocalMatrix()
		end
		meshRange = upgrade.getLevel("range")==0 and nil or model:getMesh( "range"..upgrade.getLevel("range") )
		if rangeMatrix then
			meshRange:setLocalMatrix(rangeMatrix)
		end
	end
	-- function:	doMeshUpgradeForLevel
	-- purpose:		changing visability on meshes for the new level
	local function doMeshUpgradeForLevel(name,meshName)
		model:getMesh(meshName..upgrade.getLevel(name)):setVisible(true)
		if upgrade.getLevel(name)>1 then
			model:getMesh(meshName..(upgrade.getLevel(name)-1)):setVisible(false)
		end
	end
	-- function:	handleUpgrade
	-- purpose:		upgrades the tower and all the meshes and stats for the new level
	function self.handleUpgrade(param)
		if param==nil or (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade1","1")
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
		if not xpManager or upgrade.getLevel("upgrade")==1 or upgrade.getLevel("upgrade")==2 or upgrade.getLevel("upgrade")==3 then
			--
			this:removeChild(model)
			model = Core.getModel( upgrade.getValue("model") )
			initModel()
			this:addChild(model)
			billboard:setModel("tower",model)
			cTowerUpg.fixAllPermBoughtUpgrades()
		end
		setCurrentInfo()
	end
	-- function:	handleBoost
	-- purpose:		boost has been upgraded
	local function handleBoost(param)
		if param==nil or (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade2","1")
		end
		upgrade.upgrade("boost")
		setCurrentInfo()
		--
		comUnit:broadCast(this:getGlobalPosition(),upgrade.getValue("range"),"supportBoost",1)
		--Achievement
		comUnit:sendTo("SteamAchievement","Boost","")
	end
	-- function:	handleUpgradeRange
	-- purpose:		do all changes for upgrading the range
	local function handleUpgradeRange(param)
		if param==nil or (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade3","1")
		end
		upgrade.upgrade("range")
		if meshRange then
			rangeMatrix = meshRange:getLocalMatrix()
		end
		doMeshUpgradeForLevel("range","range")
		setCurrentInfo()
		if rangeMatrix then
			meshRange:setLocalMatrix(rangeMatrix)
		end
		--
		comUnit:broadCast(this:getGlobalPosition(),upgrade.getValue("range"),"supportRange",upgrade.getLevel("range"))
		--Acievement
		if upgrade.getLevel("range")==3 then
			comUnit:sendTo("SteamAchievement","SupportRange","")
		end
	end
	-- function:	handleUpgradeDamage
	-- purpose:		do all changes for upgrading the damage
	local function handleUpgradeDamage(param)
		if param==nil or (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade4","1")
		end
		upgrade.upgrade("damage")
		doMeshUpgradeForLevel("damage","dmg")
		setCurrentInfo()
		--
		comUnit:broadCast(this:getGlobalPosition(),upgrade.getValue("range"),"supportDamage",upgrade.getLevel("damage"))
		--Achievement
		if upgrade.getLevel("burnDamage")==3 then
			comUnit:sendTo("SteamAchievement","SupportDamage","")
		end
	end
	-- function:	handleUpgradeWeaken
	-- purpose:		do all changes for upgrading the weakening
	local function handleUpgradeWeaken(param)
		if param==nil or (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade5","1")
		end
		upgrade.upgrade("weaken")
		model:getMesh("weaken"):setVisible(true)
		setCurrentInfo()
		--loop all effects and create them
		if upgrade.getLevel("weaken")==1 then
			for i=1, 4 do
				weakenEffects[i] = ParticleSystem(ParticleEffect.weakening)
				weakenPointLight[i] = PointLight(Vec3(1.0,1.0,0.0), 1.0)
				weakenPointLight[i]:setCutOff(0.05)
				this:addChild( weakenEffects[i] )
				this:addChild( weakenPointLight[i] )
				if i==1 then
					weakenEffects[i]:activate(Vec3(-0.575,0.75,0.0))
					weakenPointLight[i]:setLocalPosition(Vec3(-0.575,0.75,0.0))
				elseif i==2 then
					weakenEffects[i]:activate(Vec3(0.575,0.75,0.0))
					weakenPointLight[i]:setLocalPosition(Vec3(0.575,0.75,0.0))
				elseif i==3 then
					weakenEffects[i]:activate(Vec3(0.0,0.75,0.575))
					weakenPointLight[i]:setLocalPosition(Vec3(0.0,0.75,0.575))
				else
					weakenEffects[i]:activate(Vec3(0.0,0.75,-0.575))
					weakenPointLight[i]:setLocalPosition(Vec3(0.0,0.75,-0.575))
				end
			end
			weakeningArea = ParticleSystem(ParticleEffect.weakeningArea)
			this:addChild(weakeningArea)
			weakeningArea:activate(Vec3(0,0.5,0))
		end
		--update the spawn rate on the main effect
		weakeningArea:setSpawnRate( 0.4+(upgrade.getLevel("weaken")*0.2) )
		--update the spawn rate on the 4 tower effects
		for i=1, 4 do
			weakenEffects[i]:setScale( 0.25+(upgrade.getLevel("weaken")*0.25) )
			weakenPointLight[i]:setRange( 0.5+(upgrade.getLevel("weaken")*0.5) )
		end
		--Acievement
		if upgrade.getLevel("range")==3 then
			comUnit:sendTo("SteamAchievement","SupportWeaken","")
		end
	end
	-- function:	Upgrades the towers gold upgrade.
	-- callback:	Is called when the tower has been upgraded
	local function handleUpgradegold(param)
		if param==nil or (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade6","1")
		end
		upgrade.upgrade("gold")
		--model:getMesh("gold"):setVisible(true)
		goldUpdateTimer = 0.0
		setCurrentInfo()
		--
		goldGainAmount = upgrade.getValue("supportGold")
	end
	-- function:	Updates all tower what upgrades that is available
	-- callback:	Is called when a tower is built closeby
	local function handleShockwave()
		sendSupporUpgrade()
	end
	-- function:	update
	-- purpose:		default update sycle
	function self.update()

		if upgrade.update() then
			model:getMesh("boost"):setVisible( false )
			setCurrentInfo()
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
		
		--weaken aura
		if weakenPer then
			weakenUpdateTimer = weakenUpdateTimer - Core.getDeltaTime()
			if weakenUpdateTimer<0.0 then
				weakenUpdateTimer = 0.25
				comUnit:broadCast(this:getGlobalPosition(),range,"markOfDeath",{per=weakenPer,timer=weakenTimer,type="area"})
			end
		end
		--gold gain aura
		if goldGainAmount then
			goldUpdateTimer = goldUpdateTimer - Core.getDeltaTime()
			if goldUpdateTimer<0.0 then
				goldUpdateTimer = 0.25
				comUnit:broadCast(this:getGlobalPosition(),range,"markOfGold",{goldGain=goldGainAmount,timer=1.0,type="area"})
			end
		end
		
		--if range has been upgraded, then rotate the dishes
		if meshRange then
			meshRange:rotate(Vec3(0,0,1),Core.getDeltaTime()*0.1)
		end
		
		--update the crystal animation
		timer = timer + (Core.getDeltaTime()*0.75)
		meshCrystal:setLocalPosition(Vec3(0, 0.65+(0.1*math.sin(timer)), 0))
		
		--change update speed
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 25) * 2)
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end
		
		--model:render()
		return true
	end
	
	-- function:	setNetOwner
	-- purpose:		sets the owener of this script, for multiplayer
	local function setNetOwner(param)
		if param=="YES" then
			billboard:setBool("isNetOwner",true)
		else
			billboard:setBool("isNetOwner",false)
		end
		upgrade.fixBillboardAndStats()
	end
	-- function:	functionName
	-- purpose:		
	local function init()
		--this:setIsStatic(true)
		Core.setUpdateHz(20.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		if xpManager then
			xpManager.setUpgradeCallback(self.handleUpgrade)
		end
	
		model = Core.getModel("tower_support_l1.mym")
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
	
		billboard:setString("hullName","hull")
		billboard:setVectorVec3("hull3d",createHullList3d(hullModel:getMesh("hull")))
		billboard:setVectorVec2("hull2d",createHullList2d(hullModel:getMesh("hull")))
		billboard:setModel("tower",model)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Swarm tower")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
	
		--ComUnitCallbacks
		comUnitTable["dmgDealt"] = damageDealt
		comUnitTable["waveChanged"] = waveChanged
		comUnitTable["upgrade1"] = self.handleUpgrade
		comUnitTable["upgrade2"] = handleBoost
		comUnitTable["upgrade3"] = handleUpgradeRange
		comUnitTable["upgrade4"] = handleUpgradeDamage
		comUnitTable["upgrade5"] = handleUpgradeWeaken
		comUnitTable["upgrade6"] = handleUpgradegold
		comUnitTable["NetOwner"] = setNetOwner
		comUnitTable["SetTargetMode"] = SetTargetMode
		comUnitTable["shockwave"] = handleShockwave
		comUnitTable["extraGoldEarned"] = handleGoldStats
		comUnitTable["dmgDealtMarkOfDeath"] = dmgDealtMarkOfDeath
	
		upgrade.setBillboard(billboard)
		upgrade.addDisplayStats("range")
		upgrade.addBillboardStats("weaken")
		upgrade.addBillboardStats("weakenTimer")
		

		upgrade.addUpgrade( {	cost = 200,
								name = "upgrade",
								info = "support tower level",
								order = 1,
								icon = 56,
								value1 = 1,
								stats ={range =				{ upgrade.add, 2.8},
										model = 			{ upgrade.set, "tower_support_l1.mym"} }
							} )
		upgrade.addUpgrade( {	cost = 200,
								name = "upgrade",
								info = "support tower level",
								order = 1,
								icon = 56,
								value1 = 2,
								stats ={range =				{ upgrade.add, 2.8},
										model = 			{ upgrade.set, "tower_support_l2.mym"}}
							},0 )
		upgrade.addUpgrade( {	cost = 200,
								name = "upgrade",
								info = "support tower level",
								order = 1,
								icon = 56,
								value1 = 3,
								stats ={range =				{ upgrade.add, 2.8},
										model = 			{ upgrade.set, "tower_support_l3.mym"}}
							},0 )
		upgrade.addUpgrade( {	cost = 0,
								name = "boost",
								info = "support tower boost",
								duration = 10,
								cooldown = 3,
								order = 10,
								icon = 68,
								stats =	{}
							} )
		-- RANGE
		upgrade.addUpgrade( {	cost = 100,
								name = "range",
								info = "support tower range",
								order = 2,
								icon = 65,
								value1 = 8,
								levelRequirement = cTowerUpg.getLevelRequierment("range",1),
								stats = {SupportRange =			{ upgrade.add, 1}}
							} )
		upgrade.addUpgrade( {	cost = 200,
								name = "range",
								info = "support tower range",
								order = 2,
								icon = 65,
								value1 = 16,
								levelRequirement = cTowerUpg.getLevelRequierment("range",2),
								stats = {SupportRange =			{ upgrade.add, 2}}
							} )
		upgrade.addUpgrade( {	cost = 300,
								name = "range",
								info = "support tower range",
								order = 2,
								icon = 65,
								value1 = 24,
								levelRequirement = cTowerUpg.getLevelRequierment("range",3),
								stats = {SupportRange =			{ upgrade.add, 3}}
							} )
		-- Damage
		upgrade.addUpgrade( {	cost = 100,
								name = "damage",
								info = "support tower damage",
								order = 3,
								icon = 64,
								value1 = 8,
								levelRequirement = cTowerUpg.getLevelRequierment("damage",1),
								stats = {supportDamage =		{ upgrade.add, 1}}
							} )
		upgrade.addUpgrade( {	cost = 200,
								name = "damage",
								info = "support tower damage",
								order = 3,
								icon = 64,
								value1 = 16,
								levelRequirement = cTowerUpg.getLevelRequierment("damage",2),
								stats = {supportDamage =		{ upgrade.add, 2}}
							} )
		upgrade.addUpgrade( {	cost = 300,
								name = "damage",
								info = "support tower damage",
								order = 3,
								icon = 64,
								value1 = 24,
								levelRequirement = cTowerUpg.getLevelRequierment("damage",3),
								stats = {supportDamage =		{ upgrade.add, 3}}
							} )
		-- weaken
		upgrade.addUpgrade( {	cost = 100,
								name = "weaken",
								info = "support tower weaken",
								order = 4,
								icon = 66,
								value1 = 8,
								levelRequirement = cTowerUpg.getLevelRequierment("weaken",1),
								stats = {weaken =		{ upgrade.add, 0.08},
										 weakenTimer =	{ upgrade.add, 1} }
							} )
		upgrade.addUpgrade( {	cost = 200,
								name = "weaken",
								info = "support tower weaken",
								order = 4,
								icon = 66,
								value1 = 16,
								levelRequirement = cTowerUpg.getLevelRequierment("weaken",2),
								stats = {weaken =		{ upgrade.add, 0.16},
										 weakenTimer =	{ upgrade.add, 1} }
							} )
		upgrade.addUpgrade( {	cost = 300,
								name = "weaken",
								info = "support tower weaken",
								order = 4,
								icon = 66,
								value1 = 24,
								levelRequirement = cTowerUpg.getLevelRequierment("weaken",3),
								stats = {weaken =		{ upgrade.add, 0.24},
										 weakenTimer =	{ upgrade.add, 1} }
							} )
		-- gold
		upgrade.addUpgrade( {	cost = 100,
								name = "gold",
								info = "support tower gold",
								order = 5,
								icon = 67,
								value1 = 2,
								levelRequirement = cTowerUpg.getLevelRequierment("gold",1),
								stats = {supportGold =	{ upgrade.add, 3} }
							} )
		upgrade.addUpgrade( {	cost = 200,
								name = "gold",
								info = "support tower gold",
								order = 5,
								icon = 67,
								value1 = 4,
								levelRequirement = cTowerUpg.getLevelRequierment("gold",2),
								stats = {supportGold =	{ upgrade.add, 6} }
							} )
		upgrade.addUpgrade( {	cost = 300,
								name = "gold",
								info = "support tower gold",
								order = 5,
								icon = 67,
								value1 = 6,
								levelRequirement = cTowerUpg.getLevelRequierment("gold",3),
								stats = {supportGold =	{ upgrade.add, 9} }
							} )
	
		upgrade.upgrade("upgrade")
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		
		--target modes (default stats)
		billboard:setString("targetMods","")
		billboard:setInt("currentTargetMode",0)
	
		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(upgrade.getValue("range"))
	
		initModel()
		setCurrentInfo()
	
		myStatsReset()
		
		cTowerUpg.addUpg("range",handleUpgradeRange)
		cTowerUpg.addUpg("damage",handleUpgradeDamage)
		cTowerUpg.addUpg("weaken",handleUpgradeWeaken)
		cTowerUpg.addUpg("gold",handleUpgradegold)
		cTowerUpg.fixAllPermBoughtUpgrades()
	
		--ParticleEffects
		
		return true
	end
	init()
	function self.destroy()
		comUnit:broadCast(this:getGlobalPosition(),range,"supportRange",0)
		comUnit:broadCast(this:getGlobalPosition(),range,"supportDamage",0)
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