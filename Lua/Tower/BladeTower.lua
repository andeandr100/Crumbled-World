require("Projectile/projectileManager.lua")
require("Projectile/CutterBlade.lua")
require("Projectile/Spear.lua")
require("NPC/deathManager.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
require("Tower/TowerData.lua")

--this = SceneNode()
BladeTower = {}
function BladeTower.new()
	local self = {}
	local dmgDone = 0
	local waveCount = 0
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local projectiles = projectileManager.new(targetSelector)
	local deathManager = DeathManager.new()
	local boostActive = false
	--
	local electricPointLight1
	local electricPointLight2
	
	local data = TowerData.new()
	--constants
	local STATUS_WAITING   							= 1
	local STATUS_MOVING_ARM_INTO_ATTACK_POSITION	= 2
	local STATUS_MOVING_TO_WAITING_AREA				= 3
	local TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION = 0.2
	local angle = 0.0
	local anglePreviousFrame = 0.0
	local status = STATUS_WAITING
	local reloadTimeLeft = 0.0
	--model
	local model
	local tower
	local arm
	local blade
	local spear
	local piston = {}
	local pistonMatrix = {}
	local pistonAtVec = {}
	local pistonAng = {}
	local pistonCount = 0
	local rotationSpeed = 0
	--attack
	local pipeAt = Vec3()
	local attackLine
	local range = 0.0
	local maxRange
	local bulletStartPos
	local boostedOnLevel = 0
	--comunication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local billboardWaveStats

	--sound
	local soundRelease = SoundNode.new("bladeTower_attack")
	--other
	local upgradeElectricScale = 0.0
	local staticNodes--used for range tests
	local visibleState = 2
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this
	local lastRestored = -1
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	--stats
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
		
		model:getMesh( "spear" ):setVisible(data.getBoostActive())
		model:getMesh( "blade" ):setVisible(data.getBoostActive() == false)
		model:getMesh( "boost" ):setVisible(data.getBoostActive())

		--set ambient map
		for index=0, model:getNumMesh()-1 do
			local mesh = model:getMesh(index)
			local shader = mesh:getShader()
			local texture = Core.getTexture(data.getBoostActive() and "towergroup_boost_a" or "towergroup_a")
			mesh:setTexture(shader,texture,4)
		end
	
		-------------------------------------
		--- Handle shieldBreaker upgrades ---
		-------------------------------------
		
		model:getMesh("shield"):setVisible(data.getLevel("shieldBreaker") > 0)
		
		-----------------------------------
		--- Handle attackSpeed upgrades ---
		-----------------------------------
		
		for i=1, data.getTowerLevel() do
			model:getMesh("speed"..i):setVisible(data.getLevel("attackSpeed") == i)
		end
		
		-----------------------------------
		--- Handle masterBlade upgrades ---
		-----------------------------------
		
		model:getMesh("showSpear"):setVisible(data.getBoostActive())
		model:getMesh("showBlade"):setVisible(not data.getBoostActive())
		
		-- NOTE THIS IS THE FIRE CRIT UPGRADE THAT HAS BEEN DISABLE
		
--		if data.getLevel("masterBlade")>0 then
--			local percentage = data.getLevel("masterBlade")/3.0
--			billboard:setFloat("masterBladeHeat",percentage)
--			if data.getBoostActive() then
--				model:getMesh("showSpear"):setVisible(true)
--				model:getMesh("showBlade"):setVisible(false)
--			else
--				model:getMesh("showBlade"):setVisible(true)
--				model:getMesh("showSpear"):setVisible(false)
--			end
--			--heat level
--			blade:setUniform(blade:getShader(), "heat", percentage)
--			spear:setUniform(spear:getShader(), "heat", percentage)
--			model:getMesh( "showBlade" ):setUniform(model:getMesh( "showBlade" ):getShader(), "heat", percentage)
--			model:getMesh( "showSpear" ):setUniform(model:getMesh( "showSpear" ):getShader(), "heat", percentage)
--			--Achievement
--			if data.getLevel("masterBlade")==3 then
--				achievementUnlocked("MasterBlade")
--			end
--		else
--			model:getMesh("showBlade"):setVisible(false)
--			model:getMesh("showSpear"):setVisible(false)
--		end
		
		-------------------------------------
		--- Handle electricBlade upgrades ---
		-------------------------------------
		
		
		if data.getLevel("electricBlade")==0 then
			if sparkCenter1 then
				sparkCenter1:deactivate()
				sparkCenter2:deactivate()
				electric1:setVisible(false)
				electric2:setVisible(false)
				electricPointLight1:setVisible(false)
				electricPointLight2:setVisible(false)
			end
			model:getMesh("electric"):setVisible(false)
		else
			model:getMesh("electric"):setVisible(true)
			upgradeElectricScale = 0.20 + (data.getLevel("electricBlade")*0.05)
			if sparkCenter1==nil then
				--electric balls
				sparkCenter1 = ParticleSystem.new(ParticleEffect.SparkSpirit)
				sparkCenter2 = ParticleSystem.new(ParticleEffect.SparkSpirit)
				model:getMesh( "tower" ):addChild( sparkCenter1:toSceneNode() )
				model:getMesh( "tower" ):addChild( sparkCenter2:toSceneNode() )
				sparkCenter1:activate(Vec3(-0.35,-0.54,-0.5))
				sparkCenter2:activate(Vec3(0.35,-0.54,-0.5))
				--lightning effect when the blade is released
				electric1 = ParticleEffectElectricFlash.new("Lightning_D.tga")
				electric2 = ParticleEffectElectricFlash.new("Lightning_D.tga")
				this:addChild(electric1:toSceneNode())
				this:addChild(electric2:toSceneNode())
				--lighting
				electricPointLight1 = PointLight.new(Vec3(-0.35,0.85,0.61),Vec3(0.0,5.0,5.0),0.5)
				electricPointLight1:setCutOff(0.05)
				this:addChild(electricPointLight1:toSceneNode())
				electricPointLight2 = PointLight.new(Vec3(0.35,0.85,0.61),Vec3(0.0,5.0,5.0),0.5)
				electricPointLight2:setCutOff(0.05)
				this:addChild(electricPointLight2:toSceneNode())
			else
				sparkCenter1:activate(Vec3(-0.35,-0.54,-0.5))
				sparkCenter2:activate(Vec3(0.35,-0.54,-0.5))
				electric1:setVisible(true)
				electric2:setVisible(true)
				electricPointLight1:setVisible(true)
				electricPointLight2:setVisible(true)
			end
			sparkCenter1:setScale( upgradeElectricScale ) 
			sparkCenter2:setScale( upgradeElectricScale )
		end
	end
	
	local function restartWave(param)
		projectiles.clear()
	end

	local function bladeBlocked(param)
		local x1,y1,z1,x2,y2,z2 = string.match(param, "(.*);(.*);(.*);(.*);(.*);(.*)")
		billboard:setVec3("bladeBlockedPos", Vec3(tonumber(x1),tonumber(y1),tonumber(z1)) )
		billboard:setVec3("bladeBlockedDir", Vec3(tonumber(x2),tonumber(y2),tonumber(z2)) )
	end
	local function orderItemByVal(itemA,itemB)
		return itemA<itemB
	end
	

	local function updateStats()
		range	 	  = data.getValue("range")
	end
	local function setCurrentInfo()
		data.updateStats()
		--xpToLevel		= 1000.0*(1.5^level);
		--info[upgradeLevel]["range"]
		--dmg	 		= data.getValue("damage")--info[upgradeLevel]["dmg"]*(1.035^level)
		--reloadTime	  = 1.0/data.getValue("RPS")--info[upgradeLevel]["reloadTime"] 
		updateStats()
		if status~=STATUS_MOVING_ARM_INTO_ATTACK_POSITION then
			--we are reloading or waiting to attack
			reloadTimeLeft=0.0
			angle = angleStart
			arm:rotate(Vec3(1.0, 0.0, 0.0), angle-anglePreviousFrame)
			anglePreviousFrame = angle
			status = STATUS_WAITING
			--
			--manage pistons
			for index = 0, pistonCount-1, 1 do
			 	piston[index]:setLocalPosition(pistonMatrix[index]:getPosition())
			end
		end
		billboard:setDouble("bladeSpeed",data.getValue("bladeSpeed"))
		--
		attackLine = Line3D(this:getGlobalPosition(),this:getGlobalPosition()+(pipeAt*data.getValue("range")))
	end
	local function setHeatShader(mesh)
		mesh:setShader(Core.getShader("minigunPipe"))	
		mesh:setUniform(mesh:getShader(), "heatUvCoordOffset", Vec2(256/mesh:getTexture(mesh:getShader(),0):getSize().x,0))
		mesh:setUniform(mesh:getShader(), "heat", 0.0)
	end
	local function initModel(setDefaults)
	
		model:createBoundVolumeGroup()
		model:setBoundingVolumeCanShrink(false)
	
		model:getMesh( "physic" ):setVisible(false)
	
		tower = model:getMesh( "tower" )
		arm = model:getMesh( "arm" )
		blade = model:getMesh( "blade" )
		spear = model:getMesh( "spear" )
		
		setHeatShader(blade)
		setHeatShader(spear)
		setHeatShader(model:getMesh( "showBlade" ))
		setHeatShader(model:getMesh( "showSpear" ))
		
		if setDefaults then
			if not bulletStartPos then
				bulletStartPos = model:getMesh( "blade" ):getGlobalPosition()
			end
		
			piston = {}
			pistonMatrix = {}
			pistonAtVec = {}
			for index = 0, 1+math.floor(data.getTowerLevel()+0.01), 1 do
				piston[index] = model:getMesh( string.format("piston%d", index+1) )
				pistonMatrix[index] = piston[index]:getLocalMatrix()
				pistonAtVec[index] = Vec3()-piston[index]:getLocalPosition()--tower:getGlobalPosition()-piston[index]:getGlobalPosition()
			end
			pistonAng = {}
			if data.getTowerLevel()<2 then
				angleStart=3.65--209.0
				pistonAng[0]=3.65--209.0
				pistonAng[1]=4.28--245.0
				pistonAng[2]=4.93--283.0
				pistonAng[3]=5.43--311.0
			elseif data.getTowerLevel()<3 then
				angleStart=2.98--171.0
				pistonAng[0]=2.98--171.0
				pistonAng[1]=3.74--214.0
				pistonAng[2]=4.28--245.0
				pistonAng[3]=4.93--283.0
				pistonAng[4]=5.43--311.0
			elseif data.getTowerLevel()==3 then
				angleStart=2.37--136.0
				pistonAng[0]=2.37--136.0
				pistonAng[1]=3.05--175.0
				pistonAng[2]=3.74--214.0
				pistonAng[3]=4.28--245.0
				pistonAng[4]=4.93--283.0
				pistonAng[5]=5.43--311.0
			end
			pistonCount = 2+math.floor(data.getTowerLevel()+0.01)
		
			local len=2.0*math.pi*(arm:getGlobalPosition()-bulletStartPos):length()
			local rotTime=len/15.0
			rotationSpeed=math.pi/rotTime--not accurate (this looks good enough)
			
			--performance check
			for i=0, model:getNumMesh()-1, 1 do
				if not model:getMesh(i):getName() =="tower" then
					model:getMesh(i):DisableBoundingVolumesDynamicUpdates()
				end
			end
			
			if status~=STATUS_MOVING_ARM_INTO_ATTACK_POSITION then
				status = STATUS_WAITING
				reloadTimeLeft = 0.0--model is reseted
				angle = angleStart
				--
				--manage pistons
				for index = 0, pistonCount-1, 1 do
				 	piston[index]:setLocalPosition(pistonMatrix[index]:getPosition())
				end
				--manage effects
				if data.getLevel("electricBlade")>0 then
					 sparkCenter1:setScale( upgradeElectricScale ) 
					 sparkCenter2:setScale( upgradeElectricScale )
				end
			end
			anglePreviousFrame = angle
			arm:rotate(Vec3(1.0,0.0,0.0), angle)--generateRotationMatrix(_angle);
		end
	end
	local function NetAttack()
		if reloadTimeLeft<0.0 and status==STATUS_MOVING_ARM_INTO_ATTACK_POSITION and angle>2.0*math.pi then
			attack()
		end
	end
	local function attack()
		billboard:setVec3("bladeBlocked",Vec3(0,-100000,0))
		billboard:setVec3("pipeAt",pipeAt)
		billboard:setVec3("BulletStartPos",bulletStartPos)
		if data.getBoostActive() then
			projectiles.launch(Spear,{})
		else
			projectiles.launch(CutterBlade,{dManager=deathManager})
		end
		if data.getLevel("electricBlade")>0 then
			Vec3(-0.35,-0.54,-0.5)
			Vec3(0.35,-0.54,-0.5)
			electric1:setLine(Vec3(-0.36,0.76,0.6),Vec3(0.36,0.65,0.6),0.2)
			electric2:setLine(Vec3(0.36,0.76,0.6),Vec3(-0.36,0.65,0.6),0.3)
		end
		--
		if billboard:getBool("isNetOwner") then
			comUnit:sendNetworkSync("NetAttack","")
		end
		--add reloadTime directly as we start the count down when the arm is moving into dropping the blade
		reloadTimeLeft = reloadTimeLeft + (1.0/data.getValue("RPS"))
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
		local newModel = Core.getModel("tower_cutter_l"..data.getTowerLevel()..".mym")
		if newModel then

			this:removeChild(model:toSceneNode())
			model = newModel
			this:addChild(model:toSceneNode())
			billboard:setModel("tower",model);
			
			if data.getLevel("electricBlade")>0 then
				model:getMesh( "tower" ):addChild(sparkCenter1:toSceneNode())
				model:getMesh( "tower" ):addChild(sparkCenter2:toSceneNode())
			end
	
			initModel(true)--resets the model
		end

		setCurrentInfo()--updates variables
	end

	function self.update()
	
		local deltaTime = Core.getDeltaTime()
		comUnit:setPos(this:getGlobalPosition())
		--Handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
		 	   comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		

		--change update speed
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 20) * 2)
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end
		--
		if isThisReal then
			projectiles.update()--placed here to avoid bladeBlocked message
			deathManager.update()
		end
		--handle boost
		if boostActive ~= data.getBoostActive() then
			boostActive = data.getBoostActive()	
			setCurrentInfo()
			updateMeshesAndparticlesForSubUpgrades()
		end
	
		reloadTimeLeft = reloadTimeLeft - deltaTime

--		print("-- update Blade Tower() --")
--		print("anyInRange["..tostring(status==STATUS_WAITING).."]" )
--		print("reloadTimeLeft == "..tostring(reloadTimeLeft) )
		--
		--debug end
		--
		if reloadTimeLeft<0.0 then
			--we can fire at any time
			if status==STATUS_WAITING then
				if targetSelector.selectAllInCapsule(attackLine,1.5) then
					--start the attack
					status = STATUS_MOVING_ARM_INTO_ATTACK_POSITION
					--manage reload timer
					if reloadTimeLeft+deltaTime<0.0 then
						reloadTimeLeft = 0.0--we have been waiting to start an attack
					end
					
					--show blade/spear
					blade:setVisible(data.getBoostActive() == false)
					spear:setVisible(data.getBoostActive())
					--play sound
					soundRelease:play(1.0,false)
				else
					reloadTimeLeft = TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION
				end
			end
			if status==STATUS_MOVING_ARM_INTO_ATTACK_POSITION then
				--we are moving the arm into position to drop the blade
				angle = angle+(rotationSpeed*deltaTime)
				arm:rotate(Vec3(1.0, 0.0, 0.0), angle-anglePreviousFrame)
				anglePreviousFrame = angle
				--manage pistons
				for index = 0, pistonCount-1, 1 do
			 	   local procent=1.0-((pistonAng[index+1]-angle)/(pistonAng[index+1]-pistonAng[index]));
			 	   if procent>1.0 then procent=1.0 end
			 	   if procent<0.0 then procent=0.0 end
			 	   piston[index]:setLocalPosition(pistonMatrix[index]:getPosition()+(pistonAtVec[index]*procent*0.21))
				end
				--check if we are gonna release the blade to launch the attack
				if angle>2.0*math.pi then
					angle = angle-(2.0*math.pi)
					attack()
					
					status = STATUS_MOVING_TO_WAITING_AREA
					--hide blade/spear
					blade:setVisible(false)
					spear:setVisible(false)
				end
			end
		else
			if status==STATUS_MOVING_TO_WAITING_AREA then
				--rotationg to reload dock
				angle = angle+(rotationSpeed*deltaTime)
				if angle>=angleStart then
					--we have reached it, stop on correct spott
					angle = angleStart
					--arm:setLocalMatrix(armMatrixInReloadState)
					status = STATUS_WAITING
				end
				--do the rotation
				arm:rotate(Vec3(1.0, 0.0, 0.0), angle-anglePreviousFrame)
				anglePreviousFrame = angle
			end
			--reload animations/particles
			if reloadTimeLeft+deltaTime>0.0 and status~=STATUS_WAITING then
				local procent=reloadTimeLeft/(1.0/data.getValue("RPS"))
				--manage pistons
				for index = 0, pistonCount-1, 1 do
					if procent>1.0 then 
						procent=1.0
					end
			 	   if procent<0.0 then procent=0.0 end--procent=(procent<0.0f)?0.0f:procent;
			 	   piston[index]:setLocalPosition(pistonMatrix[index]:getPosition() + ((pistonAtVec[index]*procent)*0.21))
				end
			end
			if data.getLevel("electricBlade")>0 then
				local procent=reloadTimeLeft/(1.0/data.getValue("RPS"))
				sparkCenter1:setScale( upgradeElectricScale*(1.0-(0.75*procent)) ) 
				sparkCenter2:setScale( upgradeElectricScale*(1.0-(0.75*procent)) )
			end
		end
		return true
	end
	function self.handleSubUpgrade()
		updateMeshesAndparticlesForSubUpgrades()
		setCurrentInfo()
	end
	
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
	local function init()
		Core.setUpdateHz(60.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		
		model = Core.getModel("tower_cutter_l1.mym")
		this:addChild(model:toSceneNode())
		--

		--upgrade
		deathManager.setEnableSelfDestruct(false)
		
		--
		--  ComUnit
		--
		
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug myStats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
		billboard:setModel("tower",model)
		billboard:setVec3("Position",this:getGlobalPosition()+Vec3(0,0.8,0))
		billboard:setString("TargetArea","capsule")
		billboard:setVec3("TargetAreaOffset", Vec3(0,0.5,0))--this should be collected from a mesh
		billboard:setString("Name", "Blade tower")
		billboard:setString("FileName", "Tower/BladeTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setVec3("bladeBlockedPos",Vec3(0,-1000000,0))
		billboard:setVec3("bladeBlockedDir",Vec3(0,-1000000,0))
		billboard:setInt("level", 1)
		billboard:setFloat("baseRange", 10.0)
		
		--
		billboard:setDouble("DamageCurrentWave",0)
		billboard:setDouble("DamagePreviousWave",0)
		
		--ComUnitCallbacks
		comUnitTable["bladeBlocked"] = bladeBlocked
		comUnitTable["boost"] = data.activateBoost
		comUnitTable["NetAttack"] = NetAttack

		
		billboard:setDouble("rangePerUpgrade",1.5)
		
		data.setBillboard(billboard)
		data.setCanSyncTower(canSyncTower())
		data.setComUnit(comUnit, comUnitTable)
		data.setTowerUpgradeCallback(self.handleUpgrade)
		data.setUpgradeCallback(self.handleSubUpgrade)
		data.setMaxedOutAchivement("BladeMaxed")
		data.enableSupportManager()
		data.addDisplayStats("damage")
		data.addDisplayStats("RPS")
		data.addDisplayStats("range")
		data.addDisplayStats("slow")	
		if isThisReal then
			restartListener = Listener("RestartWave")
			restartListener:registerEvent("restartWave", restartWave)
			data.setRestoreFunction(restartListener, nil, nil)
		end
	
		data.addTowerUpgrade({	cost = {200,400,800},
								name = "upgrade",
								info = "blade tower level",
								iconId = 56,
								level = 1,
								maxLevel = 3,
								stats = {
										range =			{ 10.0, 10.0, 10.0 },
										damage = 		{ 150, 480, 1135},
										RPS = 			{ 1.0/2.5, 1.0/2.5, 1.0/2.5},
										bladeSpeed =	{ 10.5, 10.5, 10.5 },
										shieldBypass =	{ 0.0, 0.0, 0.0 } }
							})
							

		
		data.addBoostUpgrade({	cost = 0,
								name = "boost",
								info = "blade tower boost",
								duration = 10,
								cooldown = 3,
								iconId = 57,
								level = 0,
								maxLevel = 1,
								stats = {shieldBypass = { 1.0, func = data.add },
										damage =		{ 3, func = data.mul },
										RPS = 			{ 2.0, func = data.mul } }
							})
		
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "range",
								info = "blade tower range",
								infoValues = {"range"},
								iconId = 59,
								level = 0,
								maxLevel = 3,
								callback = self.handleSubUpgrade,
								achievementName = "Range",
								stats = {range = { 1.5, 3.0, 4.5, func = data.add }}
							})
		
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "attackSpeed",
								info = "blade tower attackSpeed",
								infoValues = {"RPS"},
								iconId = 58,
								level = 0,
								maxLevel = 3,
								callback = self.handleSubUpgrade,
								achievementName = "BladeSpeed",
								stats = {RPS = { 1.15, 1.3, 1.45, func = data.mul }}
							})
							
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "electricBlade",
								info = "blade tower slow",
								infoValues = {"slow"},
								iconId = 55,
								level = 0,
								maxLevel = 3,
								callback = self.handleSubUpgrade,
								achievementName = "ElectricBlade",
								stats = {slow = 	{ 0.20, 0.36, 0.49, func = data.set },
										slowTimer = { 2.0, 2.0, 2.0, func = data.set }}
							})
						
		data.addSecondaryUpgrade({	
								cost = {100},
								name = "shieldBreaker",
								info = "blade tower shield",
								iconId = 40,
								level = 0,
								maxLevel = 1,
								callback = self.handleSubUpgrade,
								achievementName = "shieldBreaker",
								stats = {shieldBypass = { 1, func = data.set }}
							})
		
		
		data.buildData()
		

		--set default vector for pipe
		pipeAt = this:getGlobalMatrix():getAtVec()
		billboard:setVec3("towerDirection",pipeAt)
		billboard:setInt("currentTargetMode",0)
		billboard:setString("targetMods","")
	

		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(data.getValue("range"))
		--
		this:addChild(soundRelease:toSceneNode())
		soundRelease:setSoundPlayLimit(4)
		soundRelease:setLocalSoundPLayLimit(3)
		
		initModel(true)--resets the model
		updateMeshesAndparticlesForSubUpgrades()
		setCurrentInfo()
		
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
	bladeTower = BladeTower.new()
	update = bladeTower.update
	destroy = bladeTower.destroy
	return true
end