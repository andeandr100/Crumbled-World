require("Tower/rotator.lua")
require("NPC/state.lua")
require("Projectile/LaserBullet.lua")
require("Projectile/projectileManager.lua")
require("Game/graphicParticleSystems.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
require("Game/soundManager.lua")
require("Tower/TowerData.lua")
require("Tower/TowerValues.lua")

--this = SceneNode()

MinigunTower = {}
function MinigunTower.new()
	local self = {}
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local projectiles = projectileManager.new()
	local data = TowerData.new()
	local towerValues = TowerValues.new()
	
	--constants
	local ROTATEPIPETIMEAFTERFIERING = 1.0
	local TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION = 0.2
	--sound
	local soundLaser = nil
	local soundGun = nil
	local soundTarget = 0	--what target we are playing the sound for
	local soundManager = SoundManager.new(this)
	local attackCounter = 0
	local CONTINUES_SOUND_MIN_TIME = 1.0
	--Mesh
	local model
	local engineMesh
	local rotatorMesh
	local pipesMesh
	local cabelMesh
	local pipeBoostMesh
	local rotator = Rotator.new()
	--Attack
	local targetMode = 1
	local activePipe = 0
	local pipeAt = Vec3()
	local boostActive = false

	local reloadTime = 0.0
	local reloadTimeLeft = 0.0
	local pipeRotateTimer = -0.01
	local targetTime = {average=0.01, average3=0.01}
	--Upgrades
	local overHeatPer = 0.0
	local overheatAdd = 0.0
	local overheatDec = 0.0
	local heatPointLight1
	local heatPointLight2
	local particleEffectSmoke

	--effects
	local particleEffectGun = {}
	local particleEffectGunLaser = {}
	local particleEffectTracer = {}

	
	local pointLight = PointLight.new(Vec3(5,2.5,0.0),1.25)
	pointLight:setVisible(false)
	local pointLightTimer = -1.0
	--cummunication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}

	--stats
	local isCircleMap = MapInfo.new().isCricleMap()
	local mapName = MapInfo.new().getMapName()
	local machinegunActiveTimeWithoutOverheat = 0.0
	--other
	local syncTargetTimer = 0.0
	local visibleState = 2
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this
	
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	--
	local function SetTargetMode(param)
		targetMode = math.clamp(tonumber(param),1,4)
		billboard:setInt("currentTargetMode",targetMode)
		if billboard:getBool("isNetOwner") and Core.isInMultiplayer() then
			comUnit:sendNetworkSync("SetTargetMode", tostring(param) )
		end
	end
	--
	local function canSyncTower()
		return (Core.isInMultiplayer()==false or self.getCurrentIslandPlayerId()==0 or networkSyncPlayerId==Core.getPlayerId())
	end
	local function achievementUnlocked(whatAchievement)
		if canSyncTower() then
			comUnit:sendTo("SteamAchievement",whatAchievement,"")
		end
	end
	--
	
	local function storeWaveChangeStats()
		tab = {}
		tab["overHeatPer"] = overHeatPer
		tab["overheated"] = overheated
		tab["engineMatrix"] = engineMesh:getLocalMatrix()
		tab["rotatorMatrix"] = rotatorMesh:getLocalMatrix()
		return tab
	end
	
	local function setRotatorSpeed(multiplyer)
		local pi=math.pi
		rotator.setSpeedHorizontalMaxMinAcc(pi*1.45*multiplyer,pi*0.275*multiplyer,pi*1.30*multiplyer)
		rotator.setSpeedVerticalMaxMinAcc(pi*0.45*multiplyer,pi*0.055*multiplyer,pi*0.35*multiplyer)
	end

	local function setCurrentInfo()
	
		data.updateStats()

		dmg 			= data.getValue("damage")
		reloadTime		= 1.0/data.getValue("RPS")
		
		targetSelector.setRange(data.getValue("range"))
		setRotatorSpeed(data.getValue("rotationSpeed"))
		
		if data.getLevel("overCharge") > 0 then
			overheatDec = (1.0/data.getValue("cooldown"))
			overheatAdd = (1.0/data.getValue("overheat")/data.getValue("RPS") + (overheatDec*reloadTime))		
		end
		
		
		reloadTimeLeft  = 0.0--instant fire after upgrade
		
		overHeatPer = 0.0
		overheated = false
		-- overheatAdd = percent increase per bullet = percent increase per secound/RPS
		

		if data.getTowerLevel()==1 then
			rotationSpeed = math.pi*4.0*(data.getValue("RPS")/3.0)
		elseif data.getTowerLevel()==2 then
			rotationSpeed = math.pi*4.0*(data.getValue("RPS")/6.0)
		else
			rotationSpeed = math.pi*4.0*(data.getValue("RPS")*0.5/6.0)
		end

	end
	
	local function setPipePointLightPos(pLight,num)
		if data.getTowerLevel()==3 then
			if num==0 then
				pLight:setLocalPosition(Vec3(-0.16,-0.95,0.18))
			else
				pLight:setLocalPosition(Vec3(0.16,-0.95,0.18))
			end
		else
			pLight:setLocalPosition(Vec3(0,-0.95,0.17))
		end
	end
	
	
	local function updateMeshesAndparticlesForSubUpgrades()
	
		--------------------------------------------------
		-- Handle Range upgrades Mesh & particle effect --
		--------------------------------------------------
		
		local rangeLevel = data.getLevel("range")
		for i=1,3,1 do
			if model:getMesh("lasersight"..i) then
				model:getMesh("lasersight"..i):setVisible(i == rangeLevel)
			end
		end
		
		if rangeLevel > 0 and model:getMesh( "lasersight"..rangeLevel ) then
			particleEffectBeam = particleEffectBeam or ParticleSystem.new( ParticleEffect.LaserSight1 )
			
			local laserBeamRange = 0.45+(rangeLevel*0.12)
			particleEffectBeam:setSpawnRate( 1.0+rangeLevel )
			
			particleEffectBeam:activate(Vec3(0.0,-0.1,0.0),Vec3(0.0,-1.0,0.0))
			particleEffectBeam:setFullAlphaOnRange(laserBeamRange)
			particleEffectBeam:setEmitterLine(Line3D(Vec3(0.0,-0.6,0.0),Vec3(0.0,-laserBeamRange,0.0)),Vec3(0.0,-1.0,0.0))
			model:getMesh( "lasersight"..rangeLevel ):addChild(particleEffectBeam:toSceneNode())
		elseif particleEffectBeam then
			--hide the particle effect beam if enabled once
			particleEffectBeam:deactivate()
			if particleEffectBeam:getParent() then
				particleEffectBeam:getParent():removeChild(particleEffectBeam:toSceneNode())
			end
		end
		
		
		
		-------------------------------------------------------
		-- Handle overCharge upgrades Mesh & particle effect --
		-------------------------------------------------------
		
		local overChargeLevel = data.getLevel("overCharge")
		for i=1,3,1 do
			if model:getMesh("engineboost"..i) then
				model:getMesh("engineboost"..i):setVisible(i == overChargeLevel)
			end
		end
	
		if overChargeLevel==0 then
			if heatPointLight1 then
				heatPointLight1:setVisible(false)
			end
			if heatPointLight2 then
				heatPointLight2:setVisible(false)
			end
			billboard:erase("overHeatPer")
		else
			if not particleEffectSmoke then
				particleEffectSmoke = {}
				particleEffectSmoke[0] = ParticleSystem.new( ParticleEffect.MinigunOverheatSmoke )
				this:addChild(particleEffectSmoke[0]:toSceneNode())
			end
			billboard:setFloat("overHeatPer",0.0)

			if not heatPointLight1 then
				heatPointLight1 = PointLight.new(Vec3(),Vec3(3.0,0.15,0.0),0.2)
				model:getMesh( "engine" ):addChild( heatPointLight1:toSceneNode() )
				setPipePointLightPos(heatPointLight1,0)
				particleEffectSmoke[0]:activate(Vec3())
				particleEffectSmoke[0]:setSpawnRate(0.0)
			end
			heatPointLight1:setVisible(false)
			heatPointLight1:setCutOff(0.15)
			if data.getTowerLevel()==3 and overChargeLevel>0 then
				if not heatPointLight2 then
					particleEffectSmoke[1] = ParticleSystem.new( ParticleEffect.MinigunOverheatSmoke )
					heatPointLight2 = PointLight.new(Vec3(),Vec3(3.0,0.15,0.0),0.2)
					model:getMesh( "engine" ):addChild( heatPointLight2:toSceneNode() )
					setPipePointLightPos(heatPointLight2,1)
					this:addChild(particleEffectSmoke[1]:toSceneNode())
					particleEffectSmoke[1]:activate(Vec3())
					particleEffectSmoke[1]:setSpawnRate(0.0)
				end
				heatPointLight2:setVisible(false)
				heatPointLight2:setCutOff(0.15)
			end
		end
		
		
		-----------------------------------------------------
		-- Handle overkill upgrades Mesh & particle effect --
		-----------------------------------------------------
		
		local overkillLevel = data.getLevel("overkill")
		for i=1,3,1 do
			if model:getMesh("fireCrit"..i) then
				model:getMesh("fireCrit"..i):setVisible(i == overkillLevel)
			end
		end
	
	end
	
	local function restoreWaveChangeStats( tab )
		SetTargetMode(tab.currentTargetMode)
		engineMesh:setLocalMatrix(tab.engineMatrix)
		rotatorMesh:setLocalMatrix(tab.rotatorMatrix)
		overHeatPer = tab.overHeatPer
		overheated = tab.overheated
	end
	
	function restartWave(param)
		projectiles.clear()
		
	end
	
	local function initModel()

		for index =1, data.getTowerLevel(), 1 do
			model:getMesh( "lasersight"..index ):setVisible(data.getLevel("range")==index)
			model:getMesh( "engineboost"..index ):setVisible(data.getLevel("overCharge")==index)
			model:getMesh( "oil"..index ):setVisible(data.getLevel("overkill")==index)
		end
		model:getMesh( "physic" ):setVisible(false)
		model:getMesh( "hull" ):setVisible(false)
		model:getMesh( "masterAim" ):setVisible(false)
		
		engineMesh = model:getMesh( "engine" )
		rotatorMesh = model:getMesh( "rotater" )
		pipesMesh = model:getMesh( "pipe1" )
		cabelMesh = model:getMesh( "cabels" )
		pipeBoostMesh = model:getMesh("pipeBoost" )
		
		
		--performance check
		for i=0, model:getNumMesh()-1, 1 do
			if not model:getMesh(i):getName() =="tower" then
				model:getMesh(i):DisableBoundingVolumesDynamicUpdates()
			end
		end
	end
	local function isUsingMultipleAttackSoundsInOneSound()
		if Core.getTimeSpeed()>1.5 then
			return targetTime.average3>CONTINUES_SOUND_MIN_TIME
		else
			return targetTime.average>CONTINUES_SOUND_MIN_TIME
		end
		return false
	end
	local function stopAllAttackSound()
	--latest version
		if not soundManager.isAllStopped() then
			local attacksPerSec = (data.getTowerLevel()==3 and 5 or 2.5)*(Core.getTimeSpeed()>1.5 and 3 or 1)
			soundManager.stopAll(1.0/attacksPerSec*0.5)
		end
		
		attackCounter = 0
		soundAttackActive = nil
	end
	local function attack()
		local target = targetSelector.getTarget()
		if target>0 then
			--start location for bullets
			activePipe = (data.getTowerLevel()==3 and activePipe == 0) and 1 or 0
		
			local targetPosition = targetSelector.getTargetPosition()
			
			local lengthToTarget = (particleEffectTracer[activePipe]:getGlobalPosition()-targetPosition):length() - 0.5
		
			--local atVec = (model:getMesh( "tower" ):getGlobalMatrix():inverseM()*targetPosition):normalizeV()
			local bulletStartPos = engineMesh:getGlobalMatrix() * (data.getTowerLevel()==1 and Vec3(0.0,-0.8,0.0) or Vec3(0,-0.95,0) )
			if targetSelector.getIndexOfShieldCovering(bulletStartPos)~=targetSelector.getIndexOfShieldCovering(targetPosition) then
				--there is a shield in the way.
				--the test of start and end position is close enough to determin if there is a shield in the way of the attack
				local index = targetSelector.getIndexOfShieldCovering(targetPosition)
				if index==0 then
					index = targetSelector.getIndexOfShieldCovering(bulletStartPos)
				end
				targetPosition = targetPosition+math.randomVec3()+(targetPosition-bulletStartPos):normalizeV()
				local hitTime = "0.45"
				comUnit:sendTo(index,"attack",tostring(dmg))
				comUnit:sendTo(index,"addForceFieldEffect",tostring(bulletStartPos.x)..";"..bulletStartPos.y..";"..bulletStartPos.z..";"..targetPosition.x..";"..targetPosition.y..";"..targetPosition.z..";"..hitTime)
			else
				--nothing in the way do the attack	
--				if upgrade.getLevel("fireCrit")>0 and targetSelector.isTargetInState(state.burning) then
--					comUnit:sendTo(target,"attackPhysical",tostring(dmg))
--					achievementUnlocked("CriticalStrike")
--				else
				local damageWeak = data.getValue("damageWeak")
				local additionDamage = 0
--				print("")
--				print("")
--				print("default damage = "..dmg)
				if damageWeak > 1.0 then
					--damageWeak was to bad in the begining of the game when all NPC has full life
					--if enemies was damage 90% in one shot they only took 90% and the second shot killed them
					--Now we say that due to they will suffer 90% helath loss we say the NPC have
					--only 45% helath meaning this effect on level 1 now will add an additional 27.5% extra damage
					--Meaning the NPC now will suffer 114% killing the enemy in one shot
					local hp = targetSelector.getTargetHP()
					local maxHp = targetSelector.getTargetMaxHP()
					local hpAfterHalfDamage = math.max(hp-dmg*0.5,0)
					local averageHPercantage =  hpAfterHalfDamage / maxHp
					additionDamage = dmg * (1.0 - averageHPercantage) * (damageWeak-1.0)
					
--					print("hp = " .. hp)
--					print("maxHp = " .. maxHp)
--					print("hpAfterHalfDamage = "..hpAfterHalfDamage)
--					print("averageHPPercantage = "..averageHPercantage)
				end
				
--				print("additionDamage = "..additionDamage)
--				print("default damage = "..dmg)
				comUnit:sendTo(target,"attackPhysical",tostring(dmg + additionDamage))
				
				
--				end
			end
			--attackSound:playSound(0.5,this.bulletStartPos)
			local pipeEnd = (data.getTowerLevel()<2) and Vec3(0.0,-0.8,0.0) or Vec3(0,-0.95,0)
			
			particleEffectGun[activePipe]:activate(Vec3(),-pipesMesh:getGlobalMatrix():getUpVec())

			--100 is the velocity the particle effect is moving
			particleEffectTracer[activePipe]:setCutOfTime(lengthToTarget / 80)
			particleEffectTracer[activePipe]:activate()
			
			
			
			--particleEffectHitt:activate( (this:getGlobalMatrix():inverseM()*targetPosition)+Vec3(0.0,0.45,0.0) )
			--
			if isUsingMultipleAttackSoundsInOneSound() then
				local attackCountMax = (data.getTowerLevel()==3 and 8 or 3)*(Core.getTimeSpeed()>1.5 and 2 or 1)
				local currentTab = (data.getTowerLevel()==3 and "5" or "2")..(Core.getTimeSpeed()>1.5 and "_3x" or "")
				local currentSound = "minigun_attack_"..(data.getTowerLevel()==3 and "5" or "2_5")..(Core.getTimeSpeed()>1.5 and "_3x" or "")
				attackCounter = attackCounter==attackCountMax and 1 or attackCounter + 1
				soundTarget = target
				
				if soundAttackActive~=currentTab and soundAttackActive then
					--we are going to play a new sound, stop all old and prep for the new
					stopAllAttackSound()
					attackCounter = 1
				end
				if attackCounter==1 then
					--play new sound
					soundAttackActive = currentTab--name of current sound
					soundManager.play(currentSound, 1.0, false)
					--Core.addDebugLine(this:getGlobalPosition(),this:getGlobalPosition()+Vec3(-0.2,3.5,-0.2),0.1,Vec3(0,0,1))
				end
			else
				soundGun:play(0.35,false)
			end
--			["2"]=	{	{sound=SoundNode.new("minigun_attack_2_5"),		counter=0,	totalAttackSounds=3},
--						{sound=SoundNode.new("minigun_attack_2_5"),		counter=0,	totalAttackSounds=3}},
		end
	end
	local function attackLaserBeam()
		local target = targetSelector.getTargetIfAvailable()
		if target>0 then

	
			local gMatrix = model:getMesh( "pipeBoost" ):getGlobalMatrix()
			local bulletStartPos = gMatrix:getPosition()
			if data.getTowerLevel()<3 then
				bulletStartPos = bulletStartPos-(gMatrix:getUpVec()*0.0)+(gMatrix:getAtVec()*0.18)
			else
				activePipe = (activePipe==1) and 0 or 1
				bulletStartPos = bulletStartPos-(gMatrix:getUpVec()*0.0)+(gMatrix:getAtVec()*0.18)+gMatrix:getRightVec()*(0.17-(activePipe*0.34))
			end
			--
			if data.getTowerLevel()==3 then
				particleEffectGunLaser[activePipe]:activate(Vec3(0.17-(activePipe*0.34), -0.45, 0.17), Vec3(0,-1,0))
			end
			--
			soundLaser:play(0.25,false)
			--
			print("Damage " .. billboard:getFloat("damage"))
			print("Damage " .. billboard:getFloat("damage"))
			print("Damage " .. billboard:getFloat("damage"))
			print("Damage " .. billboard:getFloat("damage"))
			projectiles.launch(LaserBullet,{target,bulletStartPos})
		end
	end
	
	local function setOverHeatPointLigth(heatPointLight,visiblePer,pos)
		if visiblePer>0.1 then
			heatPointLight:setVisible(true)
			heatPointLight:setColor(Vec3(3.0,0.15,0.0)*visiblePer)
			heatPointLight:setRange(2.0*visiblePer)
		else
			heatPointLight:setVisible(false)
		end
	end
	local function NetSyncTarget(param)
		local target = tonumber(Core.getIndexOfNetworkName(param))
		if target>0 then
			targetSelector.setTarget(target)
		end
	end
	local function updateTarget()
		--only select new target if we own the tower or we are not told anything usefull
		if targetSelector.isTargetAvailable()==false then
			if Core.getTimeSpeed()>1.5 then
				if targetTime.startTime3 then
					targetTime.average3 = (targetTime.average3*0.75)+((Core.getTime()-targetTime.startTime3)*0.25)
				end
			elseif targetTime.startTime then
				targetTime.average = (targetTime.average*0.75)+((Core.getTime()-targetTime.startTime)*0.25)
			end
			targetTime.startTime = nil
			targetTime.startTime3 = nil
			--
			--
			local previousTarget = targetSelector.getTarget()
			if targetSelector.selectAllInRange() then
				targetSelector.filterOutState(state.ignore)
				if targetMode==4 then
					--attack close to exit
					targetSelector.scoreHP(-5)
					targetSelector.scoreName("reaper",5)
					targetSelector.scoreClosestToExit(40)
				elseif targetMode==1 then
					--attack priority targets
					targetSelector.scoreHP(10)
					targetSelector.scoreSelectedTargets({previousTarget},10)
					targetSelector.scoreName("reaper",50)
					targetSelector.scoreName("dino",20)
					targetSelector.scoreClosestToExit(15)
				elseif targetMode==2 then
					--attack the weakest unit
					targetSelector.scoreHP(-30)
					targetSelector.scoreSelectedTargets({previousTarget},10)
					targetSelector.scoreClosestToExit(10)
				elseif targetMode==3 then
					--attackStrongestTarget
					targetSelector.scoreHP(30)
					targetSelector.scoreSelectedTargets({previousTarget},10)
					targetSelector.scoreClosestToExit(10)
				end
				targetSelector.scoreName("skeleton_cf",-20)
				targetSelector.scoreName("skeleton_cb",-20)
				targetSelector.scoreState(state.markOfDeath,10)
				targetSelector.scoreState(state.highPriority,40)
			end
			targetSelector.selectTargetAfterMaxScore()
			local newTarget = targetSelector.getTarget()
			if billboard:getBool("isNetOwner") and previousTarget~=newTarget and newTarget>0 then
				comUnit:sendNetworkSync("NetTarget", Core.getNetworkNameOf(newTarget))
			end
			if targetSelector.getTarget()==0 then
				reloadTimeLeft = TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION
			else
				--
				--
				if Core.getTimeSpeed()>1.5 then
					targetTime.startTime3 = Core.getTime()
				else
					targetTime.startTime = Core.getTime()
				end
			end
		end
	end
	local function handleRetarget()
		targetSelector.deselect()
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
	
	

	function self.handleUpgrade()
		local copyPreviousData = model and rotatorMesh and engineMesh
		
		local rotaterMatrix = copyPreviousData and rotatorMesh:getLocalMatrix() or nil--get rotation for rotater
		local engineMatrix = copyPreviousData and engineMesh:getLocalMatrix() or nil--get rotation for engine
--		local prevModel = model
		if model then
			this:removeChild(model:toSceneNode())
		end
		
		model = Core.getModel( string.format("tower_minigun_l%d.mym", data.getTowerLevel()) )
		this:addChild(model:toSceneNode())
		initModel()
		if copyPreviousData then
			rotatorMesh:setLocalMatrix(rotaterMatrix)
			rotatorMesh:setLocalPosition(Vec3())
			engineMesh:setLocalMatrix(engineMatrix)--set the old rotation
		end
		

		if data.getLevel("overCharge")>0 then
			particleEffectSmoke[0]:getParent():removeChild( particleEffectSmoke[0]:toSceneNode() )
		end

		
		if data.getLevel("overCharge")>0 then
			this:addChild(particleEffectSmoke[0]:toSceneNode())
		end
		pipesMesh:addChild(pointLight:toSceneNode())
--		pointLight:setVisible(false)
		
		model:getMesh( "pipeBoost" ):addChild(particleEffectGunLaser[0]:toSceneNode())
		
		if heatPointLight1 then pipesMesh:addChild(heatPointLight1:toSceneNode()) end
		local particleEffectLocalPos = pipesMesh:getLocalMatrix():getUpVec() * (data.getTowerLevel()==3 and -0.95 or -0.8)
		pipesMesh:addChild(particleEffectGun[0]:toSceneNode())
		particleEffectGun[0]:setLocalPosition(particleEffectLocalPos)
		
		pipesMesh:addChild(particleEffectTracer[0]:toSceneNode())
		particleEffectTracer[0]:setLocalPosition(-pipesMesh:getLocalMatrix():getUpVec())
		
		
		if data.getTowerLevel()==3 then
			model:getMesh( "pipeBoost" ):addChild(particleEffectGunLaser[1]:toSceneNode())
			
			pipes2Mesh = model:getMesh( "pipe2" )
			
			pipes2Mesh:addChild(particleEffectGun[1]:toSceneNode())
			particleEffectGun[1]:setLocalPosition(particleEffectLocalPos)
			
			pipes2Mesh:addChild(particleEffectTracer[1]:toSceneNode())
			particleEffectTracer[1]:setLocalPosition(-pipesMesh:getLocalMatrix():getUpVec())
		end
		--
		--instant reload
		reloadTimeLeft = 0.0
		
		for i=1,2 do
			local pipeMesh = model:getMesh( "pipe"..i )
			if pipeMesh then
				pipeMesh:setUniform(pipeMesh:getShader(), "heatUvCoordOffset", Vec2(100/pipeMesh:getTexture(pipeMesh:getShader(),0):getSize().x,0))
				pipeMesh:setUniform(pipeMesh:getShader(), "heat", 0.0)
			end
		end
		--
		updateMeshesAndparticlesForSubUpgrades()

		setCurrentInfo()
	end
	function self.handleBoost(param)
		data.activateBoost()
		overHeatPer = 0.0
	end
	
	function self.handleSubUpgrade()
		print("")
		print("")
		print("handleSubUpgrade")
		print("")
		updateMeshesAndparticlesForSubUpgrades()
		setCurrentInfo()
	end
	
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
	local function init()
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		
		this:createBoundVolumeGroup()
		this:setBoundingVolumeCanShrink(false)
		
		
		
		model = Core.getModel("tower_minigun_l1.mym")
		this:addChild(model:toSceneNode())
		--
		--
		rotator.setVerticalLimits(-math.pi*0.25,math.pi*0.45)
		--
		--ParticleEffects
		--
--		particleEffectGun[0] = GraphicParticleSystems.new().createMinigunFireEffect()
--		particleEffectGun[1] = GraphicParticleSystems.new().createMinigunFireEffect()
		particleEffectGun[0] = ParticleSystem.new( ParticleEffect.MinigunFire2 )
		particleEffectGun[0]:setScale(0.80)
		particleEffectGun[1] = ParticleSystem.new( ParticleEffect.MinigunFire2 )
		particleEffectGun[1]:setScale(0.80)
		
		particleEffectGunLaser[0] = ParticleSystem.new( ParticleEffect.MinigunLaserBlast )
		particleEffectGunLaser[0]:setScale(0.80)
		particleEffectGunLaser[1] = ParticleSystem.new( ParticleEffect.MinigunLaserBlast )
		particleEffectGunLaser[1]:setScale(0.80)
		
	
		particleEffectTracer[0] = GraphicParticleSystems.new().createMingunAttackTraceEffect()
		particleEffectTracer[1] = GraphicParticleSystems.new().createMingunAttackTraceEffect()
		
		
--		pointLight:setVisible(false)
		

		model:getMesh( "engine" ):addChild(pointLight:toSceneNode())


		--Sound
		soundLaser = SoundNode.new("laser_bullet1")
		soundLaser:setSoundPlayLimit(8)
		soundLaser:setLocalSoundPLayLimit(4)
		this:addChild(soundLaser:toSceneNode())
		soundGun = SoundNode.new("minigun_attack")
		soundGun:setSoundPlayLimit(8)
		soundGun:setLocalSoundPLayLimit(4)
		this:addChild(soundGun:toSceneNode())
		--
		soundAttackTarget = 0
		local m2 = SoundNode.new("minigun_attack_2_5")
		local m23 = SoundNode.new("minigun_attack_2_5_3x")
		local m5 = SoundNode.new("minigun_attack_5")
		local m53 = SoundNode.new("minigun_attack_5_3x")
		soundGun:setSoundPlayLimit(8)
		soundGun:setLocalSoundPLayLimit(8)
		m2:setSoundPlayLimit(3)
		m23:setSoundPlayLimit(3)
		m5:setSoundPlayLimit(3)
		m53:setSoundPlayLimit(3)
		m2:setLocalSoundPLayLimit(3)
		m23:setLocalSoundPLayLimit(3)
		m5:setLocalSoundPLayLimit(3)
		m53:setLocalSoundPLayLimit(3)
		
		for i=1,2 do
			local pipeMesh = model:getMesh( "pipe"..i )
			if pipeMesh then
				pipeMesh:setUniform(pipeMesh:getShader(), "heatUvCoordOffset", Vec2(100/pipeMesh:getTexture(pipeMesh:getShader(),0):getSize().x,0))
				pipeMesh:setUniform(pipeMesh:getShader(), "heat", 0.0)
			end
		end
		local pipeMesh = model:getMesh( "pipeBoost" )
		if pipeMesh then
			pipeMesh:setUniform(pipeMesh:getShader(), "heatUvCoordOffset", Vec2(100/pipeMesh:getTexture(pipeMesh:getShader(),0):getSize().x,0))
			pipeMesh:setUniform(pipeMesh:getShader(), "heat", 0.0)
		end
	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)--debug myStats
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
		billboard:setModel("tower",model)
		billboard:setVec3("Position",this:getGlobalPosition()+Vec3(0,2.2,0))--for locating where the physical attack originated
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Minigun tower")
		billboard:setString("FileName", "Tower/MinigunTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		billboard:setFloat("baseRange", 5)
		--
		billboard:setDouble("DamagePreviousWave",0)
		billboard:setDouble("DamagePreviousWavePassive",0)
	
		-- UPGRADES
		billboard:setDouble("rangePerUpgrade",0.75)
		
		data.setBillboard(billboard)
		data.setCanSyncTower(canSyncTower())
		data.setComUnit(comUnit, comUnitTable)
		data.setTowerUpgradeCallback(self.handleUpgrade)
		data.setUpgradeCallback(self.handleSubUpgrade)
		data.setMaxedOutAchivement("MinigunMaxed")
		data.enableSupportManager()
		data.addDisplayStats("damage")
		data.addDisplayStats("RPS")
		data.addDisplayStats("range")
		if isThisReal then
			restartListener = Listener("RestartWave")
			restartListener:registerEvent("restartWave", restartWave)
			data.setRestoreFunction(restartListener, restoreWaveChangeStats, storeWaveChangeStats)
		end
		
		
		
		data.addTowerUpgrade(towerValues.getTowerAbilityValues("MinigunTower","upgrade"))
		data.addBoostUpgrade(towerValues.getTowerAbilityValues("MinigunTower","boost"))
		data.addSecondaryUpgrade(towerValues.getTowerAbilityValues("MinigunTower","range"))
		data.addSecondaryUpgrade(towerValues.getTowerAbilityValues("MinigunTower","overCharge"))
		data.addSecondaryUpgrade(towerValues.getTowerAbilityValues("MinigunTower","overkill"))		
		
				
		data.buildData()
		
--							} )
--		--support tower functions
		
		
		billboard:setInt("level",data.getTowerLevel())
		if isCircleMap then
			billboard:setString("targetMods","attackPriorityTarget;attackWeakestTarget;attackStrongestTarget")
			targetMode = 2
			billboard:setInt("currentTargetMode",2)
		else
			billboard:setString("targetMods","attackPriorityTarget;attackWeakestTarget;attackStrongestTarget;attackClosestToExit")
			targetMode = 4
			billboard:setInt("currentTargetMode",4)
		end
	
		--ComUnitCallbacks
		
		comUnitTable["NetTarget"] = NetSyncTarget
		comUnitTable["Retarget"] = handleRetarget
		comUnitTable["SetTargetMode"] = SetTargetMode
		comUnitTable["boost"] = self.handleBoost
		
		
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(data.getValue("range"))

	
		initModel()
		setCurrentInfo()
				
		return true
	end
	init()
	--
	local function updateSync()
		if billboard:getBool("isNetOwner") then
			syncTargetTimer = syncTargetTimer + Core.getRealDeltaTime()
			if syncTargetTimer>0.5 then
				syncTimer = 0.0
				local target = targetSelector.getTargetIfAvailable()
				if target>0 then
					comUnit:sendNetworkSync("NetTarget", Core.getNetworkNameOf(target))
				end
			end
		end
	end
	function self.update()	
		
		comUnit:setPos(this:getGlobalPosition())
		
		--change update speed
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 20) * 2)
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end
		
		
--		local gPos = particleEffectTracer[activePipe]:getGlobalPosition()
--		Core.addDebugLine( gPos,gPos + Vec3(0,3,0), 0.1, Vec3(1))
--		Core.addDebugSphere(Sphere(gPos, 0.5), 0.1, Vec3(1))
--		Core.addDebugLine( gPos,gPos - particleEffectTracer[activePipe]:getGlobalMatrix():getUpVec(), 0.02, Vec3(1,0,0))
		
		if boostActive ~= data.getBoostActive() then
			boostActive = data.getBoostActive()	
			setCurrentInfo()		
			
			pipeBoostMesh:setVisible(data.getBoostActive())
			cabelMesh:setVisible(not data.getBoostActive())
			pipesMesh:setVisible(not data.getBoostActive())
			
			
			if data.getTowerLevel()==3 then
				model:getMesh( "pipe2" ):setVisible(not data.getBoostActive())
			end
			--set ambient map
			for index=0, model:getNumMesh()-1 do
				local mesh = model:getMesh(index)
				local shader = mesh:getShader()
				local texture = Core.getTexture( not data.getBoostActive() and "towergroup_a" or "towergroup_boost_a")
				
				mesh:setTexture(shader,texture,4)
			end
		end
		
		
		--Handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				--print("minigun update("..msg.parameter..")")
				comUnitTable[msg.message](msg.parameter, msg.fromIndex)
			end
		end

--		if pointLightTimer>0.0 then
--			pointLightTimer = pointLightTimer - Core.getDeltaTime()
--			if pointLightTimer<=0.0 then
--				pointLight:setVisible(false)
--			end
--		end
		reloadTimeLeft = reloadTimeLeft - Core.getDeltaTime()
		local pipeAt = -engineMesh:getGlobalMatrix():getUpVec()
		updateTarget()
		updateSync()
				
		if not soundManager.isAllStopped() then
			if targetSelector.isTargetAvailable() then
				local attacksPerSec = ((data.getTowerLevel()==3 and 5 or 2.5)*(Core.getTimeSpeed()>1.5 and 3 or 1))
				if soundTarget~=targetSelector.getTarget() and rotator.isReadyToFireIn()>(1.0/attacksPerSec)*1.5 then
					stopAllAttackSound()
					--Core.addDebugLine(this:getGlobalPosition(),this:getGlobalPosition()+Vec3(0.2,3.5,0.2),1.0/attacksPerSec,Vec3(0,1,0))
				end
			else
				stopAllAttackSound()
				--Core.addDebugLine(this:getGlobalPosition(),this:getGlobalPosition()+Vec3(0,3,0),0,Vec3(1,0,0))
			end
		end
		if overheated==false and targetSelector.getTargetIfAvailable()>0 then
			local targetAt = targetSelector.getTargetPosition()-engineMesh:getGlobalPosition()
			
--			Core.addDebugSphere(Sphere(targetSelector.getTargetPosition(), 0.3), 0.01, Vec3(1))
			
			--continue to rotate what ever happens
			rotator.setFrameDataTargetAndUpdate(targetAt,pipeAt)
			rotatorMesh:rotate(Vec3(0.0,0.0,1.0), rotator.getHorizontalRotation())
			engineMesh:rotate(Vec3(1.0, 0.0, 0.0), rotator.getVerticalRotation())
			if reloadTimeLeft<0.0 then
				local FireMinAngle = math.pi*0.05
				local targetAngleDiffXZ = math.abs( Vec2(targetAt.x, targetAt.z):angle( Vec2(pipeAt.x, pipeAt.z) ) )
				local targetAngleDiffY = math.abs( Vec2(targetAt.x, targetAt.y):angle( Vec2(pipeAt.x, pipeAt.y) ) )
				if targetAngleDiffXZ<FireMinAngle and targetAngleDiffY<(FireMinAngle*2.0) then
					pipeRotateTimer = ROTATEPIPETIMEAFTERFIERING
		
					--
					if data.getLevel("overCharge")>0 then
						overHeatPer = overHeatPer + overheatAdd
						if overHeatPer>1.0 then
							overHeatPer = 1.0
							overheated = true
							targetSelector.deselect()
							reloadTimeLeft = data.getValue("cooldown")
						end
					end

					--if time to attack
					reloadTimeLeft = (reloadTimeLeft<-Core.getDeltaTime()) and reloadTime or reloadTimeLeft + reloadTime
					if data.getBoostActive() then
						attackLaserBeam()
						overHeatPer = 0.0
					else
						attack()
						pointLightTimer = 0.6
						pointLight:clear()
						pointLight:setRange(2.25)
						pointLight:pushRangeChange(0.25,0.075)
						pointLight:setCutOff(0.15)
						pointLight:setVisible(true)
						setPipePointLightPos(pointLight,activePipe)
					end
				end
			end
		else
			if not overheated then
				rotator.setFrameDataAndUpdate(pipeAt)
				rotatorMesh:rotate(Vec3(0.0,0.0,1.0), rotator.getHorizontalRotation())
				engineMesh:rotate(Vec3(1.0, 0.0, 0.0), rotator.getVerticalRotation())
			end
		end
		if data.getBoostActive() == false then
			--rotate the pipes
			if pipeRotateTimer>0.0 then
				local pipeRotation = (pipeRotateTimer/ROTATEPIPETIMEAFTERFIERING)*Core.getDeltaTime()*rotationSpeed
				pipeRotateTimer = pipeRotateTimer - Core.getDeltaTime()
				pipesMesh:rotate(Vec3(0.0, 1.0, 0.0), pipeRotation)
				if data.getTowerLevel() == 3 then
					pipes2Mesh:rotate(Vec3(0.0, 1.0, 0.0), pipeRotation)
				end
			end
		end
		
		--if we are not fiering the pipe will cooldown
		if data.getLevel("overCharge")>0 then
			local mat = model:getMesh( "engine" ):getGlobalMatrix()
			if data.getTowerLevel()==3 then
				particleEffectSmoke[0]:setEmitterPos( (this:getGlobalMatrix():inverseM()*(mat:getPosition() + (mat:getAtVec()*0.18) - (mat:getUpVec()*0.95) + (mat:getRightVec()*0.16))) )
				particleEffectSmoke[1]:setEmitterPos( (this:getGlobalMatrix():inverseM()*(mat:getPosition() + (mat:getAtVec()*0.18) - (mat:getUpVec()*0.95) - (mat:getRightVec()*0.16))) )
			else
				particleEffectSmoke[0]:setEmitterPos( (this:getGlobalMatrix():inverseM()*(mat:getPosition() + (mat:getAtVec()*0.17) - (mat:getUpVec()*0.95))) )
			end
			overHeatPer = overHeatPer - (overheatDec*Core.getDeltaTime())
			if overHeatPer<=0.0 then
				overHeatPer = -0.001
				overheated = false
				particleEffectSmoke[0]:setSpawnRate(0.0)
				if data.getTowerLevel()==3 then
					particleEffectSmoke[1]:setSpawnRate(0.0)
				end
			end
			billboard:setFloat("overHeatPer",overHeatPer)
			
			local visiblePer = overheated and math.min(1.0,overHeatPer*1.5+0.05) or overHeatPer*overHeatPer
--			if upgrade.getLevel("boost")>0 then
--				model:getMesh( "pipeBoost" ):setUniform(model:getMesh( "pipeBoost" ):getShader(), "heat", visiblePer)
--			else
				model:getMesh( "pipe1" ):setUniform(model:getMesh( "pipe1" ):getShader(), "heat", visiblePer)
				if data.getTowerLevel()==3 then
					model:getMesh( "pipe2" ):setUniform(model:getMesh( "pipe2" ):getShader(), "heat", visiblePer)
				end
--			end
			setOverHeatPointLigth(heatPointLight1,visiblePer,Vec3())
			particleEffectSmoke[0]:setSpawnRate( (visiblePer>0.5) and (visiblePer-0.5)*2.0 or 0.0 )
			if data.getLevel("overCharge")==3 then
				setOverHeatPointLigth(heatPointLight2,visiblePer,Vec3())
				particleEffectSmoke[1]:setSpawnRate( (visiblePer>0.5) and (visiblePer-0.5)*2.0 or 0.0 )
			end
			--
			if overheated then
				machinegunActiveTimeWithoutOverheat = 0.0
			else
				machinegunActiveTimeWithoutOverheat = machinegunActiveTimeWithoutOverheat + Core.getDeltaTime()
			end
		end

		--
		--projectiles
		--
		projectiles.update()
		
		--model:render()
		return true
	end
	function self.destroy()
		projectiles.destroy()
	end
	return self
end

function create()
	minigunTower = MinigunTower.new()
	update = minigunTower.update		--update function
	destroy = minigunTower.destroy		--destructor for projectiles if tower gets sold
	return true
end