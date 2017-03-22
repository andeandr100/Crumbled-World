require("Tower/upgrade.lua")
require("Tower/xpSystem.lua")
require("Tower/supportManager.lua")
require("stats.lua")
require("Projectile/projectileManager.lua")
require("Projectile/CutterBlade.lua")
require("Projectile/Spear.lua")
require("NPC/deathManager.lua")
require("Game/campaignTowerUpg.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
--this = SceneNode()
BladeTower = {}
function BladeTower.new()
	local self = {}
	local myStats = {}
	local myStatsTimer = 0
	local waveCount = 0
	local projectiles = projectileManager.new()
	local deathManager = DeathManager.new()
	local tStats = Stats.new()
	local cData = CampaignData.new()
	local upgrade = Upgrade.new()
	local supportManager = SupportManager.new()
	local cTowerUpg = CampaignTowerUpg.new("Tower/BladeTower.lua",upgrade)
	--XP
	local xpManager = XpSystem.new(upgrade)
	--constants
	local STATUS_WAITING   							= 1
	local STATUS_MOVING_ARM_INTO_ATTACK_POSITION	= 2
	local STATUS_MOVING_TO_WAITING_AREA				= 3
	local angle = 0.0
	local anglePreviousFrame = 0.0
	local status = STATUS_WAITING
	local lastEnemyInRange = 0.0
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
	local range = 0.0
	local maxRange
	local bulletStartPos
	--comunication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	--sound
	local soundRelease = SoundNode("bladeTower_attack")
	--other
	local staticNodes--used for range tests
	local towerBuiltListener
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local visibleState = 2
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this
	
	local function myStatsReset()
		if myStats.dmgDone then
			billboard:setDouble("DamagePreviousWave",myStats.dmgDone)
			comUnit:sendTo("stats", "addTotalDmg", myStats.dmgDone )
		end
		myStats = {	activeTimer=0.0,
					hitts=0,
					attacks=0,
					dmgDone=0,
					bladeBlocked=0,
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
	local function waveChanged(param)
		if not xpManager then
			local name
			name,waveCount = string.match(param, "(.*);(.*)")
			if myStats.disqualified==false and upgrade.getLevel("boost")==0  and Core.getGameTime()-myStatsTimer>0.25 and myStats.activeTimer>1.0 then
				myStats.disqualified = nil
				myStats.DPS = myStats.dmgDone/myStats.activeTimer
				myStats.DPSpG = myStats.DPS/upgrade.getTotalCost()
				myStats.DPG = myStats.dmgDone/upgrade.getTotalCost()
				if upgrade.getLevel("overCharge")==0 then myStats.inoverHeatTimer=nil end
				local key = "attackSpeed"..upgrade.getLevel("attackSpeed").."_masterBlade"..upgrade.getLevel("masterBlade").."_electricBlade"..upgrade.getLevel("electricBlade")
				myStats.hittsPerBlade = myStats.hitts/myStats.attacks
				myStats.hitts = nil
				tStats.addValue({"wave"..name,"bladeTower_l"..upgrade.getLevel("upgrade"),key,"sampleSize"},1)
				for variable, value in pairs(myStats) do
					tStats.setValue({"wave"..name,"bladeTower_l"..upgrade.getLevel("upgrade"),key,variable},value)
				end
			end
			myStatsReset()
		else
			xpManager.payStoredXp(waveCount)
			--update billboard
			upgrade.fixBillboardAndStats()
		end
	end
	local function bladeBlocked(param)
		local x1,y1,z1,x2,y2,z2 = string.match(param, "(.*);(.*);(.*);(.*);(.*);(.*)")
		billboard:setVec3("bladeBlockedPos", Vec3(tonumber(x1),tonumber(y1),tonumber(z1)) )
		billboard:setVec3("bladeBlockedDir", Vec3(tonumber(x2),tonumber(y2),tonumber(z2)) )
		myStats.bladeBlocked = myStats.bladeBlocked + 1
	end
	local function orderItemByVal(itemA,itemB)
		return itemA<itemB
	end
	
	
	local function checkRange()
		
		if staticNodes == nil then
			local staticIslandBilboard = Core.getGameSessionBillboard("staticIslandMeshList")
			if staticIslandBilboard:exist("staticNodes") then
				staticNodes = staticIslandBilboard:getTable("staticNodes")
				if staticNodes==nil then
					return
				end
			else
				return
			end
		end
		
		local buildNode = this:findNodeByType(NodeId.buildNode)
		--buildNode = buildNode()
		
		
		local minRange = maxRange
		--do 3 collision checks
		for x=-0.2, 0.25, 0.1 do
			local globalMatrix = model:getGlobalMatrix()
			local collisionLine = Line3D(globalMatrix * Vec3(x,0.6,0), globalMatrix * Vec3(x,0.6,minRange))
			
			--collision check against towers
			if buildNode then
				buildNode:getBuldingFromLine(collisionLine)
			end
			
			--do collision against static mesh
			for i=1, #staticNodes do
				staticNodes[i]:collisionTree(collisionLine)
			end
			
			--add debug line
--			Core.addDebugLine(collisionLine, 0, Vec3(1,0,0))
			
			minRange = math.min(minRange, collisionLine:length())
		end

		
		if math.abs(minRange-range) > 0.05 then
			upgrade.getUpgradesAvailable()["upgrade"][1]["stats"]["range"][2] = minRange
			upgrade.getUpgradesAvailable()["upgrade"][2]["stats"]["range"][2] = minRange
			upgrade.getUpgradesAvailable()["upgrade"][3]["stats"]["range"][2] = minRange
			upgrade.fixBillboardAndStats()
			range = upgrade.getValue("range")
		end
	end
	local function updateStats()
		range	 	  = upgrade.getValue("range")
		checkRange()
	end
	local function setCurrentInfo()
		if xpManager then
			xpManager.updateXpToNextLevel()
		end
		if myStats.activeTimer and myStats.activeTimer>0.0001 then
			myStats.disqualified = true
		end
	
		--xpToLevel		= 1000.0*(1.5^level);
		--info[upgradeLevel]["range"]
		--dmg	 		= upgrade.getValue("damage")--info[upgradeLevel]["dmg"]*(1.035^level)
		--reloadTime	  = 1.0/upgrade.getValue("RPS")--info[upgradeLevel]["reloadTime"] 
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
			--manage effects
			if upgrade.getLevel("electricBlade")>0 then
				 sparkCenter1:setScale( upgradeElectricScale ) 
				 sparkCenter2:setScale( upgradeElectricScale )
			end
		end
		billboard:setDouble("bladeSpeed",upgrade.getValue("bladeSpeed"))
		--achievment
		if upgrade.getLevel("upgrade")==3 and upgrade.getLevel("electricBlade")==3 and upgrade.getLevel("shieldBreaker")==1 and upgrade.getLevel("masterBlade")==3 then
			comUnit:sendTo("SteamAchievement","BladeMaxed","")
		end
	end
	local function setHeatShader(mesh)
		mesh:setShader(Core.getShader("minigunPipe"))	
		mesh:setUniform(mesh:getShader(), "heatUvCoordOffset", Vec2(256/mesh:getTexture(mesh:getShader(),0):getSize().x,0))
		mesh:setUniform(mesh:getShader(), "heat", 0.0)
	end
	local function initModel()
	
		towerBuiltListener = Listener("builder")
		towerBuiltListener:registerEvent("built",checkRange)
	
		model:createBoundVolumeGroup()
		model:setBoundingVolumeCanShrink(false)
	
		if not bulletStartPos then
			bulletStartPos = model:getMesh( "blade" ):getGlobalPosition()
		end
		for index = 1, math.floor(upgrade.getLevel("upgrade")+0.01) do
			model:getMesh( "speed"..index ):setVisible(upgrade.getLevel("attackSpeed")==index)
		end
		model:getMesh( "electric" ):setVisible(upgrade.getLevel("electricBlade")>0)
		model:getMesh( "spear" ):setVisible(upgrade.getLevel("boost")==1)
		model:getMesh( "blade" ):setVisible(upgrade.getLevel("boost")==0)
		model:getMesh( "shield" ):setVisible(upgrade.getLevel("shieldBreaker")>0)
		model:getMesh( "boost" ):setVisible(upgrade.getLevel("boost")==1)
		model:getMesh( "showBlade" ):setVisible( (upgrade.getLevel("masterBlade")>0 and upgrade.getLevel("boost")==0) )
		model:getMesh( "showSpear" ):setVisible( (upgrade.getLevel("masterBlade")>0 and upgrade.getLevel("boost")==1) )
	
		model:getMesh( "physic" ):setVisible(false)
	
		tower = model:getMesh( "tower" )
		arm = model:getMesh( "arm" )
		blade = model:getMesh( "blade" )
		spear = model:getMesh( "spear" )
		
		setHeatShader(blade)
		setHeatShader(spear)
		setHeatShader(model:getMesh( "showBlade" ))
		setHeatShader(model:getMesh( "showSpear" ))
		
		piston = {}
		pistonMatrix = {}
		pistonAtVec = {}
		for index = 0, 1+math.floor(upgrade.getLevel("upgrade")+0.01), 1 do
			piston[index] = model:getMesh( string.format("piston%d", index+1) )
			pistonMatrix[index] = piston[index]:getLocalMatrix()
			pistonAtVec[index] = Vec3()-piston[index]:getLocalPosition()--tower:getGlobalPosition()-piston[index]:getGlobalPosition()
		end
		pistonAng = {}
		if upgrade.getLevel("upgrade")<2 then
			angleStart=3.65--209.0
			pistonAng[0]=3.65--209.0
			pistonAng[1]=4.28--245.0
			pistonAng[2]=4.93--283.0
			pistonAng[3]=5.43--311.0
		elseif upgrade.getLevel("upgrade")<3 then
			angleStart=2.98--171.0
			pistonAng[0]=2.98--171.0
			pistonAng[1]=3.74--214.0
			pistonAng[2]=4.28--245.0
			pistonAng[3]=4.93--283.0
			pistonAng[4]=5.43--311.0
		elseif upgrade.getLevel("upgrade")==3 then
			angleStart=2.37--136.0
			pistonAng[0]=2.37--136.0
			pistonAng[1]=3.05--175.0
			pistonAng[2]=3.74--214.0
			pistonAng[3]=4.28--245.0
			pistonAng[4]=4.93--283.0
			pistonAng[5]=5.43--311.0
		end
		pistonCount = 2+math.floor(upgrade.getLevel("upgrade")+0.01)
	
		local len=2.0*math.pi*(arm:getGlobalPosition()-bulletStartPos):length()
		local rotTime=len/15.0
		rotationSpeed=math.pi/rotTime--not accurate (this looks good enough)
		
		--performance check
		for i=0, model:getNumMesh()-1, 1 do
			if not model:getMesh(i):getName():toString()=="tower" then
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
			if upgrade.getLevel("electricBlade")>0 then
				 sparkCenter1:setScale( upgradeElectricScale ) 
				 sparkCenter2:setScale( upgradeElectricScale )
			end
		end
		anglePreviousFrame = angle
		arm:rotate(Vec3(1.0,0.0,0.0), angle)--generateRotationMatrix(_angle);
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
		if upgrade.getLevel("boost")==0 then
			--Core.launchProjectile(this, "CutterBlade",0)
			projectiles.launch(CutterBlade,{dManager=deathManager})
		else
			--Core.launchProjectile(this, "Spear",0)
			projectiles.launch(Spear,{})
		end
		if upgrade.getLevel("electricBlade")>0 then
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
		reloadTimeLeft = reloadTimeLeft + (1.0/upgrade.getValue("RPS"))
		--debug
		myStats.attacks = myStats.attacks + 1
	end
	local function isAnyTargetInRange()
		if targetSelector.isAnyInCapsule(Line3D(this:getGlobalPosition(),this:getGlobalPosition()+(pipeAt*range)),1.5) then
			if lastEnemyInRange>1.5 then
				--if the npc are entering close to the tower we will wait 1.25s for him and his friend to get in the line before attack (otherwise first blade will only hitt 1-2npcs)
				targetSelector.selectAllInCapsule(Line3D(this:getGlobalPosition(),this:getGlobalPosition()+(pipeAt*range)),1.5)
				targetSelector.scoreClosest(10)
				targetSelector.selectTargetAfterMaxScore()
				local pos = targetSelector.getTargetPosition()
				if (this:getGlobalPosition()-pos):length()<4.0 then
					reloadTimeLeft = 1.25
				end
			end
			lastEnemyInRange=0.0
			return true
		end
		return false
	end
	function self.handleUpgrade(param)
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
			if upgrade.getLevel("electricBlade")>0 then
				model:getMesh( "tower" ):removeChild(sparkCenter1)
				model:getMesh( "tower" ):removeChild(sparkCenter2)
			end
			this:removeChild(model)
			model = Core.getModel( upgrade.getValue("model") )
		
			this:addChild(model)
			billboard:setModel("tower",model);
			if upgrade.getLevel("electricBlade")>0 then
				model:getMesh( "tower" ):addChild(sparkCenter1)
				model:getMesh( "tower" ):addChild(sparkCenter2)
			end
		
			initModel()--resets the model
			if upgrade.getLevel("masterBlade")>0 then
				--heat level
				local percentage = upgrade.getLevel("masterBlade")/3.0
				blade:setUniform(blade:getShader(), "heat", percentage)
				spear:setUniform(spear:getShader(), "heat", percentage)
				model:getMesh( "showBlade" ):setUniform(model:getMesh( "showBlade" ):getShader(), "heat", percentage)
				model:getMesh( "showSpear" ):setUniform(model:getMesh( "showSpear" ):getShader(), "heat", percentage)
			end
		end
		cTowerUpg.fixAllPermBoughtUpgrades()
		setCurrentInfo()--updates variables
	end
	local function handleBoost(param)
		if (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade2","1")
		end
		upgrade.upgrade("boost")
		model:getMesh( "boost" ):setVisible(true)
		model:getMesh( "showSpear" ):setVisible(true)
		model:getMesh( "showBlade" ):setVisible(false)
		model:getMesh( "spear" ):setVisible(status==STATUS_MOVING_ARM_INTO_ATTACK_POSITION)
		model:getMesh( "blade" ):setVisible(false)
		setCurrentInfo()
		--Achievement
		comUnit:sendTo("SteamAchievement","Boost","")
	end
	local function handleAttackSpeed(param)
		if (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade3","1")
		end
		upgrade.upgrade("attackSpeed")
		model:getMesh("speed"..upgrade.getLevel("attackSpeed")):setVisible(true)
		if upgrade.getLevel("attackSpeed")>1 then
			model:getMesh("speed"..upgrade.getLevel("attackSpeed")-1):setVisible(false)
		end
		setCurrentInfo()
		--Achievement
		if upgrade.getLevel("attackSpeed")==3 then
			comUnit:sendTo("SteamAchievement","BladeSpeed","")
		end
	end
	local function handleMasterBlade(param)
		if (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade4","1")
		end
		upgrade.upgrade("masterBlade")
		local percentage = upgrade.getLevel("masterBlade")/3.0
		billboard:setInt("masterBladeHeat",percentage)
		if upgrade.getLevel("boost")==0 then
			model:getMesh("showBlade"):setVisible(true)
		else
			model:getMesh("showSpear"):setVisible(true)
		end
		--heat level
		blade:setUniform(blade:getShader(), "heat", percentage)
		spear:setUniform(spear:getShader(), "heat", percentage)
		model:getMesh( "showBlade" ):setUniform(model:getMesh( "showBlade" ):getShader(), "heat", percentage)
		model:getMesh( "showSpear" ):setUniform(model:getMesh( "showSpear" ):getShader(), "heat", percentage)
		--
		setCurrentInfo()
		--Achievement
		if upgrade.getLevel("masterBlade")==3 then
			comUnit:sendTo("SteamAchievement","MasterBlade","")
		end
	end
	local function handleShieldBypass(param)
		if (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade6","1")
		end
		upgrade.upgrade("shieldBreaker")
		model:getMesh("shield"):setVisible(upgrade.getLevel("shieldBreaker")>0)
		setCurrentInfo()
	end
	local function handleElectrified(param)
		if (type(param)=="string" and param=="") then
			comUnit:sendNetworkSyncSafe("upgrade5","1")
		end
		myStats.disqualified = true
		upgrade.upgrade("electricBlade")
		model:getMesh("electric"):setVisible(true)
		upgradeElectricScale = 0.20 + (upgrade.getLevel("electricBlade")*0.05)
		billboard:setFloat("electricBlade",upgrade.getLevel("electricBlade"))
		if upgrade.getLevel("electricBlade")==1 then
			--electric balls
			sparkCenter1 = ParticleSystem(ParticleEffect.SparkSpirit)
			sparkCenter2 = ParticleSystem(ParticleEffect.SparkSpirit)
			model:getMesh( "tower" ):addChild( sparkCenter1 )
			model:getMesh( "tower" ):addChild( sparkCenter2 )
			sparkCenter1:activate(Vec3(-0.35,-0.54,-0.5))
			sparkCenter2:activate(Vec3(0.35,-0.54,-0.5))
			--lightning effect when the blade is released
			electric1 = ParticleEffectElectricFlash("Lightning_D.tga")
			electric2 = ParticleEffectElectricFlash("Lightning_D.tga")
			this:addChild(electric1)
			this:addChild(electric2)
			--lighting
			local pointLight = PointLight(Vec3(-0.35,0.85,0.61),Vec3(0.0,5.0,5.0),0.5)
			pointLight:setCutOff(0.05)
			this:addChild(pointLight)
			pointLight = PointLight(Vec3(0.35,0.85,0.61),Vec3(0.0,5.0,5.0),0.5)
			pointLight:setCutOff(0.05)
			this:addChild(pointLight)
		end
		sparkCenter1:setScale( upgradeElectricScale ) 
		sparkCenter2:setScale( upgradeElectricScale )
		setCurrentInfo()
		--Achievement
		if upgrade.getLevel("electric")==3 then
			comUnit:sendTo("SteamAchievement","ElectricBlade","")
		end
	end
	function self.update()
	
		local deltaTime = Core.getDeltaTime()
		--Handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
		 	   comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		if xpManager then
			xpManager.update()
		end
		
		--change update speed
--		local tmpCameraNode = cameraNode
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 20) * 2)
--		print("state "..state)
--		print("Hz: "..((state == 2) and 60.0 or (state == 1 and 30 or 10)))
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end
		--
		projectiles.update()--placed here to avoid bladeBlocked message
		deathManager.update()
		--handle boost
		if upgrade.update() then
			model:getMesh( "boost" ):setVisible(false)
			model:getMesh( "spear" ):setVisible(false)
			model:getMesh( "blade" ):setVisible(true)
			model:getMesh( "showBlade" ):setVisible( upgrade.getLevel("masterBlade")>0 )
			model:getMesh( "showSpear" ):setVisible( false )
			setCurrentInfo()
		end
	
		reloadTimeLeft = reloadTimeLeft - deltaTime
		--
		--debug start
		--
		lastEnemyInRange = lastEnemyInRange + deltaTime
		local anyInRange = isAnyTargetInRange()
		if anyInRange then
			myStats.activeTimer = myStats.activeTimer + deltaTime
		end
		--
		--debug end
		--
		if reloadTimeLeft<0.0 then
			--we can fire at any time
			if status==STATUS_WAITING and anyInRange then
				--start the attack
				status = STATUS_MOVING_ARM_INTO_ATTACK_POSITION
				--manage reload timer
				if reloadTimeLeft+deltaTime<0.0 then
					reloadTimeLeft = 0.0--we have been waiting to start an attack
				end
				--show blade/spear
				blade:setVisible(upgrade.getLevel("boost")==0)
				spear:setVisible(upgrade.getLevel("boost")==1)
				--play sound
				soundRelease:play(0.75,false)
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
					upgrade.setUsed()--set value changed
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
			if reloadTimeLeft+deltaTime>0.0 then
				local procent=reloadTimeLeft/(1.0/upgrade.getValue("RPS"))
				--manage pistons
				for index = 0, pistonCount-1, 1 do
			 	   if procent>1.0 then 
						procent=1.0
					end
			 	   if procent<0.0 then procent=0.0 end--procent=(procent<0.0f)?0.0f:procent;
			 	   piston[index]:setLocalPosition(pistonMatrix[index]:getPosition() + ((pistonAtVec[index]*procent)*0.21))
				end
				--manage effects
				if upgrade.getLevel("electricBlade")>0 then
				 	sparkCenter1:setScale( upgradeElectricScale*(1.0-(0.75*procent)) ) 
				 	sparkCenter2:setScale( upgradeElectricScale*(1.0-(0.75*procent)) )
				end
			end
		end
		return true
	end
	local function setNetOwner(param)
		if param=="YES" then
			billboard:setBool("isNetOwner",true)
		else
			billboard:setBool("isNetOwner",false)
		end
		upgrade.fixBillboardAndStats()
	end
	local function init()
		Core.setUpdateHz(60.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		
		if xpManager then
			xpManager.setUpgradeCallback(self.handleUpgrade)
		end
		
		model = Core.getModel("tower_cutter_l1.mym")
		local hullModel = Core.getModel("tower_resource_hull.mym")
		this:addChild(model)
		--
		if particleEffectUpgradeAvailable then
			this:addChild(particleEffectUpgradeAvailable)
		end
		
		maxRange = 12.0
	
		--upgrade
		
		deathManager.setEnableSelfDestruct(false)
		
		--
		--  ComUnit
		--
		
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug myStats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),3.0,"shockwave","")
		billboard:setVectorVec3("hull3d",createHullList3d(hullModel:getMesh("hull")))
		billboard:setVectorVec2("hull2d",createHullList2d(hullModel:getMesh("hull")))
		billboard:setModel("tower",model)
		billboard:setVec3("Position",this:getGlobalPosition()+Vec3(0,0.8,0))
		billboard:setString("TargetArea","capsule")
		billboard:setVec3("TargetAreaOffset", Vec3(0,0.5,0))--this should be collected from a mesh
		billboard:setString("Name", "Blade tower")
		billboard:setBool("isNetOwner",true)
		billboard:setVec3("bladeBlockedPos",Vec3(0,-1000000,0))
		billboard:setVec3("bladeBlockedDir",Vec3(0,-1000000,0))
		billboard:setInt("level", 1)
	
		--ComUnitCallbacks
		comUnitTable["dmgDealt"] = damageDealt
		comUnitTable["waveChanged"] = waveChanged
		comUnitTable["bladeBlocked"] = bladeBlocked
		comUnitTable["upgrade1"] = self.handleUpgrade
		comUnitTable["upgrade2"] = handleBoost
		comUnitTable["upgrade3"] = handleAttackSpeed
		comUnitTable["upgrade4"] = handleMasterBlade
		comUnitTable["upgrade5"] = handleElectrified
		comUnitTable["upgrade6"] = handleShieldBypass
		comUnitTable["NetOwner"] = setNetOwner
		comUnitTable["checkRange"] = checkRange
		comUnitTable["NetAttack"] = NetAttack
		supportManager.setComUnitTable(comUnitTable)
		supportManager.addCallbacks()
		
		upgrade.setBillboard(billboard)
		upgrade.addDisplayStats("damage")
		upgrade.addDisplayStats("RPS")
		upgrade.addDisplayStats("range")
		--upgrade.addDisplayStats("bladeSpeed")
		upgrade.addBillboardStats("slow")
		upgrade.addBillboardStats("slowTimer")
		upgrade.addBillboardStats("stateDamageMul")
		upgrade.addBillboardStats("shieldBypass")
		billboard:setInt("masterBladeLevel",0)
		
	
		--attack speed equal to 2.5 is probably a good idea
		upgrade.addUpgrade( {	cost = 200,
								name = "upgrade",
								info = "blade tower level",
								order = 1,
								icon = 56,
								value1 = 1,
								stats ={range =				{ upgrade.add, maxRange},
										damage = 			{ upgrade.add, 110},
										RPS = 				{ upgrade.add, 1.0/2.75},
										bladeSpeed =		{ upgrade.add, 7.0},
										shieldBypass =		{ upgrade.add, 0.0},
										model = 			{ upgrade.set, "tower_cutter_l1.mym"} }
							} )
		--DPSpG = (RPS*AHB(Average hits per blade)*damage)/cost = ((1/2.75)*5.5*92))/200 == 0.92
		--DPSpG = 1/3*6*100*0.8 = 0.8
		upgrade.addUpgrade( {	cost = 400,
								name = "upgrade",
								info = "blade tower level",
								order = 1,
								icon = 56,
								value1 = 2,
								stats ={range =				{ upgrade.add, maxRange},
										damage = 			{ upgrade.add, 340},
										RPS = 				{ upgrade.add, 1.0/2.75},
										bladeSpeed =		{ upgrade.add, 7.0},
										shieldBypass =		{ upgrade.add, 0.0},
										model = 			{ upgrade.set, "tower_cutter_l2.mym"} }
							},0 )
		--DPSpG = (RPS*AHB(Average hits per blade)*damage)/cost = ((1/2.75)*5.5*282))/600 == 0.94
		--DPSpG = 1/3*6*330*0.8 = 0.88
		upgrade.addUpgrade( {	cost = 800,
								name = "upgrade",
								info = "blade tower level",
								order = 1,
								icon = 56,
								value1 = 3,
								stats ={range =				{ upgrade.add, maxRange},
										damage = 			{ upgrade.add, 810},
										RPS = 				{ upgrade.add, 1.0/2.75},
										bladeSpeed =		{ upgrade.add, 7.0},
										shieldBypass =		{ upgrade.add, 0.0},
										model = 			{ upgrade.set, "tower_cutter_l3.mym"} }
							},0 )
		--AHB == 5.5 (max=9.0)
		--DPSpG = (RPS*AHB(Average hits per blade)*damage)/cost = (1/2.75)*5.5*670))/1400 == 0.96
		--DPSpG = 1/3*6*750(*0.8 = 0.96
		-- BOOST (increases damage output with 400%)
		function boostDamage() return upgrade.getStats("damage")*4.0*math.min(2.0,waveCount/20+1.0) end
		upgrade.addUpgrade( {	cost = 0,
								name = "boost",
								info = "blade tower boost",
								duration = 10,
								cooldown = 3,
								order = 10,
								icon = 57,
								stats ={damage = 			{ upgrade.func, boostDamage},
										shieldBypass =		{ upgrade.add, 1.0}, }
							} )
		-- attack speed
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "attackSpeed",
								info = "blade tower attackSpeed",
								order = 2,
								icon = 58,
								value1 = 15,
								levelRequirement = cTowerUpg.getLevelRequierment("attackSpeed",1),
								stats ={RPS = 			{ upgrade.mul, 1.15},
										bladeSpeed =	{ upgrade.mul, 1.15} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "attackSpeed",
								info = "blade tower attackSpeed",
								order = 2,
								icon = 58,
								value1 = 30,
								levelRequirement = cTowerUpg.getLevelRequierment("attackSpeed",2),
								stats ={RPS = 			{ upgrade.mul, 1.30},
										bladeSpeed =	{ upgrade.mul, 1.30} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "attackSpeed",
								info = "blade tower attackSpeed",
								order = 2,
								icon = 58,
								value1 = 45,
								levelRequirement = cTowerUpg.getLevelRequierment("attackSpeed",3),
								stats ={RPS = 			{ upgrade.mul, 1.45},
										bladeSpeed =	{ upgrade.mul, 1.45}}
							} )
		-- MasterBlade
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "masterBlade",
								info = "blade tower firecrit",
								order = 3,
								icon = 36,
								value1 = 20,
								levelRequirement = cTowerUpg.getLevelRequierment("masterBlade",1),
								stats ={stateDamageMul ={ upgrade.add, 1.20} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "masterBlade",
								info = "blade tower firecrit",
								order = 3,
								icon = 36,
								value1 = 40,
								levelRequirement = cTowerUpg.getLevelRequierment("masterBlade",2),
								stats ={stateDamageMul ={ upgrade.add, 1.40} }
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "masterBlade",
								info = "blade tower firecrit",
								order = 3,
								icon = 36,
								value1 = 60,
								levelRequirement = cTowerUpg.getLevelRequierment("masterBlade",3),
								stats ={stateDamageMul ={ upgrade.add, 1.60} }
							} )
		-- electricBlade
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "electricBlade",
								info = "blade tower slow",
								order = 4,
								icon = 55,
								value1 = 15,
								levelRequirement = cTowerUpg.getLevelRequierment("electricBlade",1),
								stats ={slow =		{ upgrade.add, 0.15},
										slowTimer =	{ upgrade.add, 2.0} }--resault==0.2
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "electricBlade",
								info = "blade tower slow",
								order = 4,
								icon = 55,
								value1 = 28,
								levelRequirement = cTowerUpg.getLevelRequierment("electricBlade",2),
								stats ={slow =		{ upgrade.add, 0.28},
										slowTimer =	{ upgrade.add, 2.0} }--resault==0.4
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "electricBlade",
								info = "blade tower slow",
								order = 4,
								icon = 55,
								value1 = 39,
								levelRequirement = cTowerUpg.getLevelRequierment("electricBlade",3),
								stats ={slow =		{ upgrade.add, 0.39},
										slowTimer =	{ upgrade.add, 2.0} }--resault==0.6
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "shieldBreaker",
								info = "blade tower shield",
								order = 5,
								icon = 40,
								levelRequirement = cTowerUpg.getLevelRequierment("shieldBreaker",3),
								stats ={shieldBypass =	{ upgrade.add, 1.0}}
							} )
		supportManager.setUpgrade(upgrade)
		supportManager.addHiddenUpgrades()
		supportManager.addSetCallbackOnChange(updateStats)
	
		self.handleUpgrade()
	
		myStatsReset()
	
		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(range)
		--
		this:addChild(soundRelease)
		soundRelease:setSoundPlayLimit(4)
		soundRelease:setLocalSoundPLayLimit(3)
	
		--set default vector for pipe
		pipeAt = this:getGlobalMatrix():getAtVec()
		checkRange()
		billboard:setVec3("towerDirection",pipeAt)
		billboard:setInt("currentTargetMode",0)
		billboard:setString("targetMods","")
		
		cTowerUpg.addUpg("attackSpeed",handleAttackSpeed)
		cTowerUpg.addUpg("masterBlade",handleMasterBlade)
		cTowerUpg.addUpg("electricBlade",handleElectrified)
		cTowerUpg.addUpg("shieldBreaker",handleShieldBypass)
		cTowerUpg.fixAllPermBoughtUpgrades()
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