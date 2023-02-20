require("NPC/state.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
require("Tower/TowerData.lua")
--this = SceneNode()
BankTower = {}
function BankTower.new()
	local TOWERRANGE = 2.8
	local TOWERRANGEMAX = 3.0
	--
	local self = {}
	local waveCount = 0
	local goldEarned = 0
	local cData = CampaignData.new()
	local coins = {}
	--local range = 2.5
	
	local data = TowerData.new()

	local supportGoldPerWave = 0 -- This value name is replaced on init, upgrade or boost
	--Gold
	local goldGainAmount = 0
	local goldUpdateTimer
	--model
	local pLight = PointLight.new(Vec3(2.0,0.4,0.0),3.5)
	local crystalPosition = Vec3()
	local model
	local meshCrystal --meshCrystal = Mesh()
	local timer = 0.0
	--
	for i=1, 16 do
		coins[i] = {
			time1=math.randomFloat()*16.0,
			time2=math.randomFloat()*16.0,
			timeMul1=math.randomFloat(0.60,1.0),
			timeMul2=math.randomFloat(0.15,0.30),
			mat1=Matrix(),
			mat2=Matrix(),
			axis=math.randomVec3(),
			posVec=math.randomVec3()*0.78,
			model=Core.getModel("Data/Models/props/gold_coin.mym")
		}
		coins[i].mat1:createMatrix(math.randomVec3(),math.randomVec3())
		coins[i].mat2:createMatrix(math.randomVec3(),math.randomVec3())
	end
	--effects

	--communication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
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
		goldEarned = goldEarned + supportGoldPerWave
		totalGoaldEarned = totalGoaldEarned + supportGoldPerWave
		if canSyncTower() then
			comUnit:sendTo("stats","addGold",tostring(supportGoldPerWave))
			comUnit:sendTo("stats","addBillboardDouble", "goldGainedFromSupportTowers;"..tostring(supportGoldPerWave))
		end
		

		billboard:setDouble("goldEarnedPreviousWave",goldEarned)
		billboard:setDouble("goldEarned", totalGoaldEarned)
		--store wave info to be able to restore it
		goldEarned = 0
		
		local tab = {
			goldEarnedPreviousWave = billboard:getDouble("goldEarnedPreviousWave"),
			goldEarned = billboard:getDouble("goldEarned"),
			totalGoaldEarned = totalGoaldEarned
		}
		return tab
	end
	
	local function restoreWaveChangeStats( tab )
		totalGoaldEarned = tab.totalGoaldEarned
		goldEarnedPreviousWave = tab.goldEarnedPreviousWave
		billboard:setDouble("goldEarnedPreviousWave",tab.goldEarnedPreviousWave)
		billboard:setDouble("goldEarned", tab.goldEarned)
		
	end
	
	function restartWave(param)
		goldEarned = 0
	end

	-- function:	handleGoldStats
	-- purpose:		called when a unit has died with the effect active
	local function handleGoldStats(param)
		local goldGained = tonumber(param)
		goldEarned = goldEarned + goldGained
		totalGoaldEarned = totalGoaldEarned + goldGained
		billboard:setDouble("goldEarned", totalGoaldEarned)
		if canSyncTower() then
			comUnit:sendTo("SteamStats","MaxGoldEarnedFromSingleSupportTower",totalGoaldEarned)
			comUnit:sendTo("stats","addBillboardDouble","goldGainedFromSupportTowers;"..tostring(goldGained))
		end
	end
	
	-- function:	setCurrentInfo
	-- purpose:		
	local function setCurrentInfo()
		data.updateStats()
		supportGoldPerWave = data.getValue("supportGoldPerWave")
		goldUpdateTimer = 0.0
		goldGainAmount = data.getValue("supportGold", 0)
	end
	-- function:	initModel
	-- purpose:		to initialize the model and set the visibility flag for every mesh
	local function initModel()
		--update the bounding volume for the tower
		model:createBoundVolumeGroup()
		model:setBoundingVolumeCanShrink(false)
		
		--set visibility on all meshes
		if model:getMesh( "physic" ) then
			model:getMesh( "physic" ):setVisible(false)
		end
		
		local crystal = model:getMesh( "crystal" )
		pLight:setLocalPosition(Vec3(0,0.5,0))
		crystal:addChild(pLight:toSceneNode())
		crystalPosition = crystal:getLocalPosition()
		for i=1, 16 do
			crystal:addChild(coins[i].model:toSceneNode())
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
		local newModel = Core.getModel( "tower_gold_l"..data.getTowerLevel()..".mym" )
		if newModel then
			this:removeChild(model:toSceneNode())
			model = newModel
			initModel()
			this:addChild(model:toSceneNode())
			billboard:setModel("tower",model)
		end
		setCurrentInfo()
	end


	function self.handleSubUpgrade()
		setCurrentInfo()		
	end
	

	-- function:	update
	-- purpose:		default update sycle
	function self.update()
		comUnit:setPos(this:getGlobalPosition())

		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
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
		--meshCrystal:setLocalPosition(Vec3(0, 0.65+(0.1*math.sin(timer)), 0))

		local crystal = model:getMesh( "crystal" )
		-- coins
		local deltaTime = Core.getDeltaTime()
		local dist = 0.35+(data.getTowerLevel()*0.15)
		for i=1, 4+(4*data.getTowerLevel()) do
			local coin = coins[i]
			coin.time1 = coin.time1 + deltaTime*coin.timeMul1
			coin.time2 = coin.time2 + deltaTime*coin.timeMul2
			coin.mat1:rotate(coin.axis,coin.time1)
			coin.mat2:rotate(coin.mat1:getUpVec(),coin.time2)
			coin.model:setLocalPosition(coin.mat2*coin.posVec*dist)
			coin.model:rotate(coin.axis, deltaTime)
		end
		--crystal
		crystal:setLocalPosition(Vec3(0,0.1+0.1*math.sin(timer),0)+crystalPosition)
		
		--change update speed
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 25) * 2)
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end

		return true
	end
	
	-- function:	functionName
	-- purpose:		
	local function init()
		--this:setIsStatic(true)
		Core.setUpdateHz(12.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		
		if isThisReal then
			restartListener = Listener("RestartWave")
			restartListener:registerEvent("restartWave", restartWave)
		end
		
		model = Core.getModel("tower_gold_l1.mym")
		this:addChild(model:toSceneNode())

		
		meshCrystal = model:getMesh( "crystal" )

	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug myStats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
	
		billboard:setModel("tower",model)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Bank tower")
		billboard:setString("FileName", "Tower/BankTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		billboard:setFloat("baseRange", TOWERRANGE)
		--
		billboard:setDouble("goldEarnedPreviousWave",0)
		billboard:setDouble("goldEarned", 0)
	
		--ComUnitCallbacks
		comUnitTable["shockwave"] = handleShockwave
		comUnitTable["extraGoldEarned"] = handleGoldStats

	
		data.setBillboard(billboard)
		data.setCanSyncTower(canSyncTower())
		data.setComUnit(comUnit, comUnitTable)
		data.setTowerUpgradeCallback(self.handleUpgrade)
		data.setUpgradeCallback(self.handleSubUpgrade)
		data.setMaxedOutAchivement("MaxedBankTower")--TODO
		data.addDisplayStats("range")
		data.addDisplayStats("supportGoldPerWave")
		if isThisReal then
			restartListener = Listener("RestartWave")
			restartListener:registerEvent("restartWave", restartWave)
			data.setRestoreFunction(restartListener, restoreWaveChangeStats, storeWaveChangeStats)
		end


		data.addTowerUpgrade({	cost = {500,500,500},
								name = "upgrade",
								info = "bank tower level",
								iconId = 56,
								level = 1,
								maxLevel = 3,
								stats = {
										range =					{ TOWERRANGE, TOWERRANGE, TOWERRANGE },
										supportGoldPerWave = 	{ 50, 105, 160} }
							})
							
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "gold",
								info = "support tower gold",
								iconId = 67,
								level = 0,
								maxLevel = 3,
								achievementName = "UpgradeSupportGold",
								stats = {supportGold =	{ 1, 2, 3, func = data.set} }
							})
		
		
		data.buildData()
		
		
		--target modes (default stats)
		billboard:setString("targetMods","")
		billboard:setInt("currentTargetMode",0)
	
		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(TOWERRANGE)
	
		initModel()
		setCurrentInfo()
	
	
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