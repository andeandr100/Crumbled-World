require("Tower/upgrade.lua")
require("NPC/state.lua")
require("Tower/xpSystem.lua")
require("Game/campaignTowerUpg.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
--this = SceneNode()
BankTower = {}
function BankTower.new()
	local TOWERRANGE = 2.8
	local TOWERRANGEMAX = 3.0
	--
	local self = {}
	local waveCount = 0
	local dmgDoneMarkOfDeath = 0
	local goldEarned = 0
	local cData = CampaignData.new()
	local upgrade = Upgrade.new()
	local cTowerUpg = CampaignTowerUpg.new("Tower/SupportTower.lua",upgrade)
	local range = 2.5

	local supportGoldPerWave = 20
	--Gold
	local goldGainAmount = 0
	local goldUpdateTimer
	--XP
	local xpManager = XpSystem.new(upgrade)
	--model
	local model
	local meshCrystal --meshCrystal = Mesh()
	local timer = 0.0
	--effects

	--communication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local billboardWaveStats
	--sound
	--targetSelector
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this
	--stats
	local mapName = MapInfo.new().getMapName()
	local totalGoaldEarned = 0
	--other
	local lastRestored = -1
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	--lastGlobalPosition used for crash safty when tower nodes is destroyed before script is
	local lastGlobalPosition = Vec3()
	
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
					upgradeTab = upgrade.storeWaveChangeStats(),
					DamagePreviousWave = billboard:getDouble("DamagePreviousWave"),
					DamagePreviousWavePassive = billboard:getDouble("DamagePreviousWavePassive"),
					DamageTotal = billboard:getDouble("DamageTotal"),
					upgradeLevel = upgrade.getLevel("upgrade"),
					goldLevel = upgrade.getLevel("gold")
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
				--
				doDegrade(upgrade.getLevel("gold"),tab.goldLevel,self.handleUpgradegold)
				doDegrade(upgrade.getLevel("upgrade"),tab.upgradeLevel,self.handleUpgrade)--main upgrade last as the assets might not be available for higer levels
				--
				upgrade.restoreWaveChangeStats(tab.upgradeTab)
				--
				billboard:setDouble("DamagePreviousWave", tab.DamagePreviousWave)
				billboard:setDouble("DamageCurrentWave", tab.DamagePreviousWave)
				billboard:setDouble("DamagePreviousWavePassive", tab.DamagePreviousWavePassive)
				billboard:setDouble("DamageTotal", tab.DamageTotal)
			end
		end
	end
	-- function:	sendSupporUpgrade
	-- purpose:		broadcasting what upgrades the towers close by should use
	local function sendSupporUpgrade()
		
	end
	local function restartWave(param)
		restoreWaveChangeStats( tonumber(param) )
		sendSupporUpgrade()
		goldEarned = 0
		dmgDoneMarkOfDeath = 0
	end
	-- function:	waveChanged
	-- purpose:		called on wavechange. updates the towers stats
	local function waveChanged(param)
		local name
		local waveCountStr
		name,waveCountStr = string.match(param, "(.*);(.*)")
		waveCount = tonumber(waveCountStr)
		
		goldEarned = supportGoldPerWave
		totalGoaldEarned = totalGoaldEarned + goldEarned
		if canSyncTower() then
			comUnit:sendTo("stats","addGold",tostring(goldEarned))
			comUnit:sendTo("stats","addBillboardInt", "totalGoldSupportEarned;"..tostring(goldEarned))
		end
		
		--update and save stats only if we did not just restore this wave
		if waveCount>=lastRestored then
			if not xpManager then
				billboard:setDouble("DamagePreviousWave",0)
				billboard:setDouble("DamagePreviousWavePassive",dmgDoneMarkOfDeath)
				billboard:setDouble("goldEarnedPreviousWave",goldEarned)
				billboard:setDouble("goldEarned",billboard:getDouble("goldEarned")+goldEarned)
				if canSyncTower() then
					comUnit:sendTo("stats", "addTotalDmg", dmgDoneMarkOfDeath )
				end
			else
				xpManager.payStoredXp(waveCount)
				--update billboard
				upgrade.fixBillboardAndStats()
			end
			--store wave info to be able to restore it
			storeWaveChangeStats( tostring(waveCount+1) )
		end
		--tell every tower how it realy is
		sendSupporUpgrade()
		--
		goldEarned = 0
		dmgDoneMarkOfDeath = 0
	end

	-- function:	handleGoldStats
	-- purpose:		called when a unit has died with the effect active
	local function handleGoldStats(param)
		local goldGained = tonumber(param)
		goldEarned = goldEarned + goldGained
		totalGoaldEarned = totalGoaldEarned + goldGained
		billboard:setDouble("goldEarnedCurrentWave",goldEarned)
		if canSyncTower() then
			comUnit:sendTo("SteamStats","MaxGoldEarnedFromSingleSupportTower",totalGoaldEarned)
			comUnit:sendTo("stats","addBillboardDouble","goldGainedFromSupportTowers;"..tostring(goldGained))
		end
	end
	
	-- function:	setCurrentInfo
	-- purpose:		
	local function setCurrentInfo()
		if xpManager then
			xpManager.updateXpToNextLevel()
		end

		supportGoldPerWave = upgrade.getValue("supportGoldPerWave")
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
		model:getMesh( "weaken" ):setVisible(false)
		model:getMesh( "boost" ):setVisible(false)
		for index=0, model:getNumMesh()-1 do
			local mesh = model:getMesh(index)
			local shader = mesh:getShader()
			local texture = Core.getTexture("towergroup_a")
			mesh:setTexture(shader,texture,4)
		end
		for i=1, upgrade.getLevel("upgrade") do
			model:getMesh( "range"..i ):setVisible(false)
			model:getMesh( "dmg"..i ):setVisible(false)
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
	-- function:	handleUpgrade
	-- purpose:		upgrades the tower and all the meshes and stats for the new level
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
		--
		if not xpManager or upgrade.getLevel("upgrade")==1 or upgrade.getLevel("upgrade")==2 or upgrade.getLevel("upgrade")==3 then
			--
			this:removeChild(model:toSceneNode())
			model = Core.getModel( upgrade.getValue("model") )
			initModel()
			this:addChild(model:toSceneNode())
			billboard:setModel("tower",model)
			cTowerUpg.fixAllPermBoughtUpgrades()
		end
		upgrade.clearCooldown()
		setCurrentInfo()

	end

	
	-- function:	Upgrades the towers gold upgrade.
	-- callback:	Is called when the tower has been upgraded
	function self.handleUpgradegold(param)
		if tonumber(param)>upgrade.getLevel("gold") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("gold")
		elseif upgrade.getLevel("gold")>tonumber(param) then
			upgrade.degrade("gold")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() and canSyncTower() then
			comUnit:sendNetworkSyncSafe("upgrade6",tostring(param))
		end
		if upgrade.getLevel("gold")>0 then
			--model:getMesh("gold"):setVisible(true)
			goldUpdateTimer = 0.0
			setCurrentInfo()
			--
			goldGainAmount = upgrade.getValue("supportGold")
		else
			goldGainAmount = 0
		end
		--Acievement
		if upgrade.getLevel("gold")==3 then
			achievementUnlocked("UpgradeSupportGold")
		end
	end
	-- function:	Updates all tower what upgrades that is available
	-- callback:	Is called when a tower is built closeby
	local function handleShockwave()
		sendSupporUpgrade()
	end
	-- function:	update
	-- purpose:		default update sycle
	function self.update()
		comUnit:setPos(this:getGlobalPosition())
		if upgrade.update() then
			model:getMesh("boost"):setVisible( false )
			setCurrentInfo()
			initModel()
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
		lastGlobalPosition = this:getGlobalPosition()
		
		--gold gain aura
		if goldGainAmount>0 then
			goldUpdateTimer = goldUpdateTimer - Core.getDeltaTime()
			if goldUpdateTimer<0.0 then
				goldUpdateTimer = 0.1
				comUnit:broadCast(lastGlobalPosition,TOWERRANGE,"markOfGold",{goldGain=goldGainAmount,timer=0.15,type="area"})
			end
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
		Core.setUpdateHz(12.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		if xpManager then
			xpManager.setUpgradeCallback(self.handleUpgrade)
		end
		
		restartListener = Listener("RestartWave")
		restartListener:registerEvent("restartWave", restartWave)
	
		model = Core.getModel("tower_support_l1.mym")
		local hullModel = Core.getModel("tower_resource_hull.mym")
		this:addChild(model:toSceneNode())

		
		meshCrystal = model:getMesh( "crystal" )

	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug myStats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
	
		billboard:setString("hullName","hull")
		billboard:setVectorVec3("hull3d",createHullList3d(hullModel:getMesh("hull")))
		billboard:setVectorVec2("hull2d",createHullList2d(hullModel:getMesh("hull")))
		billboard:setModel("tower",model)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Bank tower")
		billboard:setString("FileName", "Tower/BankTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		billboard:setFloat("baseRange", TOWERRANGE)
		--
		billboard:setDouble("DamagePreviousWave",0)
		billboard:setDouble("DamagePreviousWavePassive",0)
		billboard:setDouble("goldEarnedPreviousWave",0)
	
		--ComUnitCallbacks
		comUnitTable["waveChanged"] = waveChanged
		comUnitTable["upgrade1"] = self.handleUpgrade
		comUnitTable["upgrade3"] = self.handleUpgradegold
		comUnitTable["NetOwner"] = setNetOwner
		comUnitTable["shockwave"] = handleShockwave
		comUnitTable["extraGoldEarned"] = handleGoldStats

	
		upgrade.setBillboard(billboard)
		upgrade.addDisplayStats("range")
		upgrade.addDisplayStats("supportGoldPerWave")


		upgrade.addUpgrade( {	cost = 200,
								name = "upgrade",
								info = "Bank tower level",
								order = 1,
								icon = 56,
								value1 = 1,
								stats ={range =					{ upgrade.add, TOWERRANGE},
										supportGoldPerWave =	{ upgrade.add, 30},
										model = 				{ upgrade.set, "tower_support_l1.mym"} }
							} )
		upgrade.addUpgrade( {	cost = 300,
								name = "upgrade",
								info = "Bank tower level",
								order = 1,
								icon = 56,
								value1 = 2,
								stats ={range =					{ upgrade.add, TOWERRANGE},
										supportGoldPerWave =	{ upgrade.add, 75},
										model = 				{ upgrade.set, "tower_support_l2.mym"}}
							},0 )
		upgrade.addUpgrade( {	cost = 500,
								name = "upgrade",
								info = "Bank tower level",
								order = 1,
								icon = 56,
								value1 = 3,
								stats ={range =					{ upgrade.add, TOWERRANGE},
										supportGoldPerWave =	{ upgrade.add, 150},
										model = 				{ upgrade.set, "tower_support_l3.mym"}}
							},0 )
		
		-- gold
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("gold",1) and 0 or 100,
								name = "gold",
								info = "Bank tower gold",
								order = 5,
								icon = 67,
								value1 = 1,
								levelRequirement = cTowerUpg.getLevelRequierment("gold",1),
								stats = {supportGold =	{ upgrade.add, 1} }
							} )
		upgrade.addUpgrade( {	cost = 100,
								name = "gold",
								info = "Bank tower gold",
								order = 5,
								icon = 67,
								value1 = 2,
								levelRequirement = cTowerUpg.getLevelRequierment("gold",2),
								stats = {supportGold =	{ upgrade.add, 2} }
							} )
		upgrade.addUpgrade( {	cost = 100,
								name = "gold",
								info = "Bank tower gold",
								order = 5,
								icon = 67,
								value1 = 3,
								levelRequirement = cTowerUpg.getLevelRequierment("gold",3),
								stats = {supportGold =	{ upgrade.add, 3} }
							} )
	
		self.handleUpgrade("1")
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		
		--target modes (default stats)
		billboard:setString("targetMods","")
		billboard:setInt("currentTargetMode",0)
	
		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(TOWERRANGE)
	
		initModel()
		setCurrentInfo()
		
		cTowerUpg.addUpg("gold",self.handleUpgradegold)
		cTowerUpg.fixAllPermBoughtUpgrades()
	
		return true
	end
	init()
	function self.destroy()

	end
	--
	return self
end

function create()
	bankTower = BankTower.new()
	update = bankTower.update
	destroy = bankTower.destroy
	return true
end