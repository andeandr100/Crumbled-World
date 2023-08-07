require("Tower/TowerData.lua")
require("NPC/state.lua")
require("Projectile/projectileManager.lua")
require("Projectile/SwarmBall.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
require("Game/gameValues.lua")

--this = SceneNode()
SwarmTower = {}
function SwarmTower.new()
	local TOWERRANGE = 2.8
	local TOWERRANGEMAX = 3.0
	--
	local self = {}
	local waveCount = 0
	local goldEarned = 0
	local range = 2.5
	local boostActive = false
	local gameValues = GameValues.new()
	
	local data = TowerData.new()
	--Weaken
	local weakenPer
	local weakeningArea
	local weakenTimer
	local weakenUpdateTimer
	--Gold
	local goldGainAmount = 0
	local goldUpdateTimer
	--model
	local model
	local meshCrystal --meshCrystal = Mesh()
	local meshRange
	local timer = 0.0
	--effects
	sparkCenter = ParticleSystem.new(ParticleEffect.EndCrystal)
	weakenEffects = {}
	weakenPointLight = {}
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
	local totalGoldEarned = 0
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
	
	local function updateMeshesAndparticlesForSubUpgrades()
	
		--set visibility on all meshes
		model:getMesh( "physic" ):setVisible(false)
		model:getMesh( "weaken" ):setVisible(data.getLevel("weaken")>0)
		model:getMesh( "boost" ):setVisible(data.getBoostActive())--set ambient map
		for index=0, model:getNumMesh()-1 do
			local mesh = model:getMesh(index)
			local name = mesh:getName()
			local shader = mesh:getShader()
			if name~="crystal" then
				local texture = Core.getTexture(data.getBoostActive() and "towergroup_boost_a" or  "towergroup_a")
				mesh:setTexture(shader,texture,4)
			end
		end
		
		
		for i=1, data.getTowerLevel() do
			model:getMesh( "range"..i ):setVisible(data.getLevel("range")==i)
			model:getMesh( "dmg"..i ):setVisible(data.getTowerLevel()==i)
		end	
		
		local rangeMatrix
		if meshRange then
			rangeMatrix = meshRange:getLocalMatrix()
		end
		meshRange = data.getLevel("range")==0 and nil or model:getMesh( "range"..data.getLevel("range") )
		if rangeMatrix then
			meshRange:setLocalMatrix(rangeMatrix)
		end
		
		--- Weaken effect --
		if data.getLevel("weaken")==0 then
			model:getMesh("weaken"):setVisible(false)
			if weakeningArea then
				weakeningArea:deactivate()
				for i=1, 4 do
					weakenEffects[i]:deactivate()
					weakenPointLight[i]:setVisible(false)
				end
			end
		else
			--loop all effects and create them
			if not weakeningArea then
				for i=1, 4 do
					weakenEffects[i] = ParticleSystem.new(ParticleEffect.weakening)
					weakenPointLight[i] = PointLight.new(Vec3(1.0,1.0,0.0), 1.0)
					weakenPointLight[i]:setCutOff(0.05)
					this:addChild( weakenEffects[i]:toSceneNode() )
					this:addChild( weakenPointLight[i]:toSceneNode() )
				end
				weakeningArea = ParticleSystem.new(ParticleEffect.weakeningArea)
				this:addChild(weakeningArea:toSceneNode())
			end
			weakenEffects[1]:activate(Vec3(-0.575,0.75,0.0))
			weakenPointLight[1]:setLocalPosition(Vec3(-0.575,0.75,0.0))
			weakenEffects[2]:activate(Vec3(0.575,0.75,0.0))
			weakenPointLight[2]:setLocalPosition(Vec3(0.575,0.75,0.0))
			weakenEffects[3]:activate(Vec3(0.0,0.75,0.575))
			weakenPointLight[3]:setLocalPosition(Vec3(0.0,0.75,0.575))
			weakenEffects[4]:activate(Vec3(0.0,0.75,-0.575))
			weakenPointLight[4]:setLocalPosition(Vec3(0.0,0.75,-0.575))
			weakeningArea:activate(Vec3(0,0.5,0))
			weakeningArea:setSpawnRate( 0.4+(data.getLevel("weaken")*0.2) )
			--update the spawn rate on the 4 tower effects
			for i=1, 4 do
				weakenEffects[i]:setScale( 0.25+(data.getLevel("weaken")*0.25) )
				weakenPointLight[i]:setRange( 0.5+(data.getLevel("weaken")*0.5) )
				weakenPointLight[i]:setVisible(true)
			end	
		end
	end	

	local function restoreWaveChangeStats( tab )
		billboard:setDouble("goldEarnedPreviousWave", tab.goldEarnedPreviousWave)
		billboard:setDouble("goldEarned", tab.totalGoldEarned)
		totalGoldEarned = tab.totalGoldEarned
	end
	-- function:	sendSupporUpgrade
	-- purpose:		broadcasting what upgrades the towers close by should use
	local function sendSupporUpgrade()
		comUnit:broadCast(this:getGlobalPosition(),data.getLevel("range")==0 and TOWERRANGE*2.0 or TOWERRANGEMAX,"supportRange",data.getLevel("range"))
		comUnit:broadCast(this:getGlobalPosition(),data.getTowerLevel()==0 and TOWERRANGE*2.0 or TOWERRANGEMAX,"supportDamage",data.getTowerLevel())
	end
	local function restartWave(param)
		sendSupporUpgrade()
		goldEarned = 0
	end
	-- function:	waveChanged
	-- purpose:		called on wavechange. updates the towers stats
	local function storeWaveChangeStats()

		billboard:setDouble("goldEarnedPreviousWave",goldEarned)
		billboard:setDouble("goldEarned",totalGoldEarned)

		local tab = {
			goldEarnedPreviousWave = billboard:getDouble("goldEarnedPreviousWave"),
			totalGoldEarned = totalGoldEarned
		}
			
			
		--tell every tower how it realy is
		sendSupporUpgrade()
		--
		goldEarned = 0
		
		return tab
	end

	-- function:	handleGoldStats
	-- purpose:		called when a unit has died with the effect active
	local function handleGoldStats(param)
		local goldGained = tonumber(param)
		goldEarned = goldEarned + goldGained
		totalGoldEarned = totalGoldEarned + goldGained
		billboard:setDouble("goldEarnedCurrentWave",goldEarned)
		if canSyncTower() then
			comUnit:sendTo("SteamStats","MaxGoldEarnedFromSingleSupportTower",totalGoldEarned)
			comUnit:sendTo("stats","addBillboardDouble","goldGainedFromSupportTowers;"..tostring(goldGained))
		end
	end
	
	-- function:	setCurrentInfo
	-- purpose:		
	local function setCurrentInfo()

		data.updateStats()
		meshRange = data.getLevel("range")==0 and nil or model:getMesh( "range"..data.getLevel("range") )
		if data.getLevel("weaken")>0 then
			weakenPer = data.getValue("weaken")
			weakenTimer = data.getValue("weakenTimer")
			weakenUpdateTimer = 0.0
		else
			weakenPer = nil
		end
		range = data.getValue("range")
		--manage support upgrades
		sendSupporUpgrade()
		--achievment
		
		if data.getLevel("gold")>0 then
			--model:getMesh("gold"):setVisible(true)
			goldUpdateTimer = 0.0
			--
			goldGainAmount = data.getValue("supportGold", 0)
		else
			goldGainAmount = 0
		end
	end
	
	-- function:	initModel
	-- purpose:		to initialize the model and set the visibility flag for every mesh
	local function initModel()
		--update the bounding volume for the tower
		model:createBoundVolumeGroup()
		model:setBoundingVolumeCanShrink(false)
		
		updateMeshesAndparticlesForSubUpgrades()
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
		local newTowerModel = Core.getModel("tower_support_l"..data.getTowerLevel()..".mym")
		if newTowerModel then
			this:removeChild(model:toSceneNode())
			model = newTowerModel
			this:addChild(model:toSceneNode())
			billboard:setModel("tower",model)
			
			initModel()
		end
		
		setCurrentInfo()
	end

	
	function self.handleSubUpgrade()
		setCurrentInfo()
		updateMeshesAndparticlesForSubUpgrades()
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
		if boostActive ~= data.getBoostActive() then
			boostActive = data.getBoostActive()
			setCurrentInfo()
			updateMeshesAndparticlesForSubUpgrades()
		end

		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		lastGlobalPosition = this:getGlobalPosition()
		
		--weaken aura
		if weakenPer then
			weakenUpdateTimer = weakenUpdateTimer - Core.getDeltaTime()
			if weakenUpdateTimer<0.0 then
				weakenUpdateTimer = 0.25
				
				comUnit:broadCast(lastGlobalPosition,TOWERRANGE,"markOfDeath",{per=weakenPer,timer=weakenTimer,type="area"})
			end
		end
		--gold gain aura
		if goldGainAmount>0 then
			goldUpdateTimer = goldUpdateTimer - Core.getDeltaTime()
			if goldUpdateTimer<0.0 then
				goldUpdateTimer = 0.1
				
				comUnit:broadCast(lastGlobalPosition,TOWERRANGE,"markOfGold",{goldGain=goldGainAmount,timer=0.15,type="area"})
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
	
	-- function:	functionName
	-- purpose:		
	local function init()
		Core.setUpdateHz(12.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		

		
		model = Core.getModel("tower_support_l1.mym")
		this:addChild(model:toSceneNode())
	
		
		meshCrystal = model:getMesh( "crystal" )
		this:addChild( sparkCenter:toSceneNode() )
		sparkCenter:activate(Vec3(0,1.7,0))
	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug myStats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
	
		
		billboard:setModel("tower",model)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Support tower")
		billboard:setString("FileName", "Tower/SupportTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		billboard:setFloat("baseRange", TOWERRANGE)
		--
		billboard:setDouble("DamagePreviousWave",0)
		billboard:setDouble("DamagePreviousWavePassive",0)
		billboard:setDouble("goldEarnedPreviousWave",0)
	
		--ComUnitCallbacks
		comUnitTable["extraGoldEarned"] = handleGoldStats
		
	
		data.setBillboard(billboard)
		data.setCanSyncTower(canSyncTower())
		data.setComUnit(comUnit, comUnitTable)
		data.setTowerUpgradeCallback(self.handleUpgrade)
		data.setUpgradeCallback(self.handleSubUpgrade)
		data.setMaxedOutAchivement("MaxedSupportTower")
		data.addDisplayStats("range")
		data.addDisplayStats("supportDamage")
		data.addDisplayStats("SupportRange")
		data.addDisplayStats("supportWeaken")
		data.addDisplayStats("supportGold")
		if isThisReal then
			restartListener = Listener("RestartWave")
			restartListener:registerEvent("restartWave", restartWave)
			data.setRestoreFunction(restartListener, restoreWaveChangeStats, storeWaveChangeStats)
		end
		
	
		data.addTowerUpgrade(gameValues.getTowerAbilityValues("SupportTower","upgrade"))
		data.addSecondaryUpgrade(gameValues.getTowerAbilityValues("SupportTower","range"))
		data.addSecondaryUpgrade(gameValues.getTowerAbilityValues("SupportTower","weaken"))
		data.addSecondaryUpgrade(gameValues.getTowerAbilityValues("SupportTower","gold"))
		
		data.buildData()
		

		--target modes (default stats)
		billboard:setString("targetMods","")
		billboard:setInt("currentTargetMode",0)
	
		--soulManager
		
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(data.getValue("range"))
	
		initModel()
		setCurrentInfo()

		
		return true
	end
	init()
	function self.destroy()
		comUnit:broadCast(lastGlobalPosition,TOWERRANGE*2.0,"supportRange",0)
		comUnit:broadCast(lastGlobalPosition,TOWERRANGE*2.0,"supportDamage",0)
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