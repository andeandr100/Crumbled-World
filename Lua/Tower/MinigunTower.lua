require("Tower/rotator.lua")
require("Tower/upgrade.lua")
require("Tower/xpSystem.lua")
require("Tower/supportManager.lua")
require("NPC/state.lua")
require("Projectile/LaserBullet.lua")
require("Projectile/projectileManager.lua")
require("stats.lua")
require("Game/campaignTowerUpg.lua")
require("Game/particleEffect.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
--this = SceneNode()
MinigunTower = {}
function MinigunTower.new()
	local self = {}
	local projectiles = projectileManager.new()
	local myStats = {	}
	local myStatsTimer = 0
	local waveCount = 0
	local smartTargetingRetargetTime = 0.0
	local tStats = Stats.new()
	local supportManager = SupportManager.new()
	local cTowerUpg = CampaignTowerUpg.new("Tower/MinigunTower.lua",upgrade)
	--XP
	local xpManager = XpSystem.new(upgrade,"Tower/MinigunTower.lua")
	--Upgrade
	local upgrade = Upgrade.new()
	--constants
	local ROTATEPIPETIMEAFTERFIERING = 1.0
	--sound
	local soundLaser = nil
	local soundAttack = nil
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
	local dmg = 0.0
	local dmgFire = 0.0
	local reloadTime = 0.0
	local reloadTimeLeft = 0.0
	local pipeRotateTimer = -0.01
	--Upgrades
	local overHeatPer = 0.0
	local overheatAdd = 0.0
	local overheatDec = 0.0
	local heatPointLight1
	local heatPointLight2
	local particleEffectSmoke
	local increasedDamageToFire = 0.0
	local boostedOnLevel = 0
	--effects
	local particleEffectGun = {}
	local particleEffectGunLaser = {}
	local particleEffectTracer = {}
	local pointLight = PointLight(Vec3(0.16,-1.0,0.18),Vec3(5,2.5,0.0),1.25)
	local pointLightTimer = -1.0
	--cummunication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local billboardWaveStats
	--stats
	local mapName = MapInfo.new().getMapName()
	local machinegunActiveTimeWithoutOverheat = 0.0
	--other
	local syncTargetTimer = 0.0
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local visibleState = 2
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this
	local lastRestored = -1
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
	
	local function storeWaveChangeStats( waveStr )
		if isThisReal then
			print("storeWaveChangeStats( "..waveStr.." )")
			billboardWaveStats = billboardWaveStats or Core.getGameSessionBillboard( "tower_"..Core.getNetworkName() )
			--update wave stats only if it has not been set (this function will be called on wave changes when going back in time)
			if billboardWaveStats:exist( waveStr )==false then
				local tab = {
					xpTab = xpManager and xpManager.storeWaveChangeStats() or nil,
					upgradeTab = upgrade.storeWaveChangeStats(),
					DamagePreviousWave = billboard:getDouble("DamagePreviousWave"),
					DamagePreviousWavePassive = billboard:getDouble("DamagePreviousWavePassive"),
					DamageTotal = billboard:getDouble("DamageTotal"),
					currentTargetMode = billboard:getInt("currentTargetMode"),
					engineMatrix = engineMesh:getLocalMatrix(),
					rotatorMatrix = rotatorMesh:getLocalMatrix(),
					boostedOnLevel = boostedOnLevel,
					boostLevel = upgrade.getLevel("boost"),
					upgradeLevel = upgrade.getLevel("upgrade"),
					rangeLevel = upgrade.getLevel("range"),
					overChargeLevel = upgrade.getLevel("overCharge"),
					fireCritLevel = upgrade.getLevel("fireCrit")
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
		print("restoreWaveChangeStats( "..wave.." )")
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
				if upgrade.getLevel("boost")~=tab.boostLevel then self.handleBoost(tab.boostLevel) end
				doDegrade(upgrade.getLevel("range"),tab.rangeLevel,self.upgradeRange)
				doDegrade(upgrade.getLevel("fireCrit"),tab.fireCritLevel,self.upgradeGreaseBullet)
				doDegrade(upgrade.getLevel("overCharge"),tab.overChargeLevel,self.upgradeOverCharge)
				doDegrade(upgrade.getLevel("upgrade"),tab.upgradeLevel,self.handleUpgrade)--main upgrade last as the assets might not be available for higer levels
				--
				upgrade.restoreWaveChangeStats(tab.upgradeTab)
				--
				billboard:setDouble("DamagePreviousWave", tab.DamagePreviousWave)
				billboard:setDouble("DamageCurrentWave", tab.DamagePreviousWave)
				billboard:setDouble("DamagePreviousWavePassive", tab.DamagePreviousWavePassive)
				billboard:setDouble("DamageTotal", tab.DamageTotal)
				SetTargetMode(tab.currentTargetMode)
				engineMesh:setLocalMatrix(tab.engineMatrix)
				rotatorMesh:setLocalMatrix(tab.rotatorMatrix)
				boostedOnLevel = tab.boostedOnLevel
			end
		end
	end
	
	local function myStatsReset()
		if myStats.dmgDone then
			billboard:setDouble("DamagePreviousWave",myStats.dmgDone)
			billboard:setDouble("DamagePreviousWavePassive",0.0)
			comUnit:sendTo("stats", "addTotalDmg", myStats.dmgDone )
		end
		myStats = {	activeTimer=0.0,	
					dmgDone=0,
					inoverHeatTimer=0.0,
					disqualified=false}
		myStatsTimer = Core.getGameTime()
	end
	local function setRotatorSpeed(multiplyer)
		local pi=math.pi
		rotator.setSpeedHorizontalMaxMinAcc(pi*1.45*multiplyer,pi*0.275*multiplyer,pi*1.30*multiplyer)
		rotator.setSpeedVerticalMaxMinAcc(pi*0.45*multiplyer,pi*0.055*multiplyer,pi*0.35*multiplyer)
	end
	local function updateStats()
		if xpManager then
			local interpolation  = xpManager.getLevelPercentDoneToNextLevel()
			upgrade.setInterpolation(interpolation)
			upgrade.fixBillboardAndStats()
		end
		targetSelector.setRange(upgrade.getValue("range"))
		dmg			 	= upgrade.getValue("damage")
		dmgFire			= upgrade.getValue("fireDPS")
		reloadTime		= 1.0/upgrade.getValue("RPS")
		setRotatorSpeed(upgrade.getValue("rotationSpeed"))
		--
		billboard:setFloat("damage",dmg)
		--
		overheatDec = (1.0/upgrade.getValue("cooldown"))
		overheatAdd = (1.0/upgrade.getValue("overheat")/upgrade.getValue("RPS") + (overheatDec*reloadTime))
	end
	function restartWave(param)
		myStats.disqualified = true
		myStatsReset()
		--
		projectiles.clear()
		supportManager.restartWave()
		restoreWaveChangeStats( tonumber(param) )
	end
	local function setCurrentInfo()
		if xpManager then
			xpManager.updateXpToNextLevel()
		end
		if myStats.activeTimer and myStats.activeTimer>0.01 then
			myStats.disqualified = true
		end
		
		updateStats()
		reloadTimeLeft  = 0.0--instant fire after upgrade
		
		overHeatPer = 0.0
		overheated = false
		-- overheatAdd = percent increase per bullet = percent increase per secound/RPS
		
		increasedDamageToFire = 1.0+upgrade.getValue("fireCrit")
		
		if upgrade.getLevel("upgrade")==1 then
			rotationSpeed = math.pi*2.0*(upgrade.getValue("RPS")/3.0)
		elseif upgrade.getLevel("upgrade")==2 then
			rotationSpeed = math.pi*2.0*(upgrade.getValue("RPS")/6.0)
		else
			rotationSpeed = math.pi*2.0*(upgrade.getValue("RPS")*0.5/6.0)
		end
		--achivment
		if upgrade.getLevel("upgrade")==3 and upgrade.getLevel("range")==3 and upgrade.getLevel("overCharge")==3 and upgrade.getLevel("fireCrit")==3 then
			comUnit:sendTo("SteamAchievement","MinigunMaxed","")
		end
	end
	local function damageDealt(param)
		local addDmg = supportManager.handleSupportDamage( tonumber(param) )
		myStats.dmgDone = myStats.dmgDone + addDmg
		billboard:setDouble("DamageCurrentWave",myStats.dmgDone)
		billboard:setDouble("DamageTotal",billboard:getDouble("DamagePreviousWave")+myStats.dmgDone)
		if xpManager then
			xpManager.addXp(addDmg)
			updateStats()
		end
	end
	local function waveChanged(param)
		local name
		local waveCount
		name,waveCount = string.match(param, "(.*);(.*)")
		--update and save stats only if we did not just restore this wave
		if tonumber(waveCount)>=lastRestored then
			if not xpManager then
				--
				if myStats.disqualified==false and upgrade.getLevel("boost")==0 and Core.getGameTime()-myStatsTimer>0.25 and myStats.activeTimer>1.0 then
					myStats.disqualified=nil
					myStats.cost = upgrade.getTotalCost()
					myStats.DPS = myStats.dmgDone/myStats.activeTimer
					myStats.DPSpG = myStats.DPS/upgrade.getTotalCost()
					myStats.DPG = myStats.dmgDone/upgrade.getTotalCost()
					if upgrade.getLevel("overCharge")==0 then myStats.inoverHeatTimer=nil end
					local key = "range"..upgrade.getLevel("range").."_overCharge"..upgrade.getLevel("overCharge").."_fireCrit"..upgrade.getLevel("fireCrit")
					tStats.addValue({mapName,"wave"..name,"minigunTower_l"..upgrade.getLevel("upgrade"),key,"sampleSize"},1)
					table.sort( myStats, cmp_multitype )
					for variable, value in pairs(myStats) do
						tStats.setValue({mapName,"wave"..name,"minigunTower_l"..upgrade.getLevel("upgrade"),key,variable},value)
					end
				end
				myStatsReset()
			else
				xpManager.payStoredXp(waveCount)
				--update billboard
				upgrade.fixBillboardAndStats()
			end
			--store wave info to be able to restore it
			storeWaveChangeStats( tostring(tonumber(waveCount)+1) )
		end
	end
	local function initModel()
		for index =1, upgrade.getLevel("upgrade"), 1 do
			model:getMesh( "lasersight"..index ):setVisible(upgrade.getLevel("range")==index)
			model:getMesh( "engineboost"..index ):setVisible(upgrade.getLevel("overCharge")==index)
			model:getMesh( "oil"..index ):setVisible(upgrade.getLevel("fireCrit")==index)
		end
		model:getMesh( "physic" ):setVisible(false)
		model:getMesh( "hull" ):setVisible(false)
		model:getMesh( "pipeBoost" ):setVisible(upgrade.getLevel("boost")==1)
		model:getMesh( "cabels" ):setVisible(upgrade.getLevel("boost")==0)
		model:getMesh( "pipe1" ):setVisible(upgrade.getLevel("boost")==0)
		model:getMesh( "masterAim" ):setVisible(false)
		engineMesh = model:getMesh( "engine" )
		rotatorMesh = model:getMesh( "rotater" )
		pipesMesh = model:getMesh( "pipe1" )
		cabelMesh = model:getMesh( "cabels" )
		pipeBoostMesh = model:getMesh("pipeBoost" )
		if upgrade.getLevel("upgrade")==3 then
			model:getMesh( "pipe2" ):setVisible(upgrade.getLevel("boost")==0)
			pipes2Mesh = model:getMesh( "pipe2" )
		end
		--performance check
		for i=0, model:getNumMesh()-1, 1 do
			if not model:getMesh(i):getName():toString()=="tower" then
				model:getMesh(i):DisableBoundingVolumesDynamicUpdates()
			end
		end
	end
	local function attack()
		local target = targetSelector.getTarget()
		if target>0 then
			--start location for bullets
			if upgrade.getLevel("upgrade")==3 then
				activePipe = (activePipe==1) and 0 or 1
			end
		
			--print("damage = "..dmg)
			local targetPosition = targetSelector.getTargetPosition()
			local length = -(this:getGlobalPosition()-targetPosition):length()
		
			--local atVec = (model:getMesh( "tower" ):getGlobalMatrix():inverseM()*targetPosition):normalizeV()
			local bulletStartPos = engineMesh:getGlobalMatrix() * (upgrade.getLevel("upgrade")==1 and Vec3(0.0,-0.8,0.0) or Vec3(0,-0.95,0) )
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
				if upgrade.getLevel("fireCrit")>0 and targetSelector.isTargetInState(state.burning) then
					comUnit:sendTo(target,"attackPhysical",tostring(dmg*increasedDamageToFire))
					comUnit:sendTo("SteamAchievement","CriticalStrike","")
				else
					comUnit:sendTo(target,"attackPhysical",tostring(dmg))
				end
			end
			--attackSound:playSound(0.5,this.bulletStartPos)
			local pipeEnd = (upgrade.getLevel("upgrade")<2) and Vec3(0.0,-0.8,0.0) or Vec3(0,-0.95,0)
			particleEffectGun[activePipe]:activate(pipeEnd,Vec3(0,-1,0))
			particleEffectTracer[activePipe]:setSpawnRadius(math.min(-0.1,length-1.0))-- (-1) is just a magic number for the length of the tracerline
			particleEffectTracer[activePipe]:activate(Vec3(0.0,-2.0,0.0),Vec3(0,-1,0))
			--particleEffectHitt:activate( (this:getGlobalMatrix():inverseM()*targetPosition)+Vec3(0.0,0.45,0.0) )
			--
			soundAttack:play(0.3,false)
		end
	end
	local function attackLaserBeam()
		local target = targetSelector.getTargetIfAvailable()
		if target>0 then
			local targetPosition = targetSelector.getTargetPosition() + Vec3(0.75)
			if upgrade.getLevel("upgrade")==3 then
				local bulletStartPos2 = pipesMesh:getGlobalMatrix()*Vec3(0.0,-0.8,0.0)
			end
			local gMatrix = model:getMesh( "pipeBoost" ):getGlobalMatrix()
			local bulletStartPos = gMatrix:getPosition()
			if upgrade.getLevel("upgrade")<3 then
				bulletStartPos = bulletStartPos-(gMatrix:getUpVec()*0.0)+(gMatrix:getAtVec()*0.18)
			else
				activePipe = (activePipe==1) and 0 or 1
				bulletStartPos = bulletStartPos-(gMatrix:getUpVec()*0.0)+(gMatrix:getAtVec()*0.18)+gMatrix:getRightVec()*(0.17-(activePipe*0.34))
			end
			--
			if upgrade.getLevel("upgrade")==3 then
				particleEffectGunLaser[activePipe]:activate(Vec3(0.17-(activePipe*0.34), -0.45, 0.17), Vec3(0,-1,0))
			end
			--
			soundLaser:play(0.35,false)
			--
			projectiles.launch(LaserBullet,{target,bulletStartPos})
		end
	end
	local function setPipePointLightPos(pLight,num)
		if upgrade.getLevel("upgrade")==3 then
			if num==0 then
				pLight:setLocalPosition(Vec3(-0.16,-0.95,0.18))
			else
				pLight:setLocalPosition(Vec3(0.16,-0.95,0.18))
			end
		else
			pLight:setLocalPosition(Vec3(0,-0.95,0.17))
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
			local previousTarget = targetSelector.getTarget()
			if targetSelector.selectAllInRange() then
				targetSelector.filterOutState(state.ignore)
				targetSelector.scoreState(state.markOfDeath,10)
				if upgrade.getLevel("fireCrit")>0 then
					targetSelector.scoreState(state.burning,6.66*upgrade.getLevel("fireCrit"))
				end
				if targetMode==1 then
					--attack close to exit
					--local pipeAt = -engineMesh:getGlobalMatrix():getUpVec()
					targetSelector.scoreHP(-5)
					targetSelector.scoreName("reaper",5)
					targetSelector.scoreName("skeleton_cf",-10)
					targetSelector.scoreName("skeleton_cb",-10)
					targetSelector.scoreClosestToExit(40)
				elseif targetMode==2 then
					--attack priority targets
					targetSelector.scoreHP(10)
					targetSelector.scoreSelectedTargets({previousTarget},10)
					targetSelector.scoreName("reaper",50)
					targetSelector.scoreName("dino",20)
					targetSelector.scoreName("skeleton_cf",-20)
					targetSelector.scoreName("skeleton_cb",-20)
					targetSelector.scoreClosestToExit(15)
				elseif targetMode==3 then
					--attack the weakest unit
					targetSelector.scoreHP(-30)
					targetSelector.scoreSelectedTargets({previousTarget},10)
					targetSelector.scoreName("skeleton_cf",-10)
					targetSelector.scoreName("skeleton_cb",-10)
					targetSelector.scoreClosestToExit(10)
				elseif targetMode==4 then
					--attackStrongestTarget
					targetSelector.scoreHP(30)
					targetSelector.scoreSelectedTargets({previousTarget},10)
					targetSelector.scoreName("skeleton_cf",-20)
					targetSelector.scoreName("skeleton_cb",-20)
					targetSelector.scoreClosestToExit(10)
				end
				targetSelector.scoreState(state.highPriority,30)
			end
			targetSelector.selectTargetAfterMaxScore()
			local newTarget = targetSelector.getTarget()
			if billboard:getBool("isNetOwner") and previousTarget~=newTarget then
				if newTarget>0 then
					comUnit:sendNetworkSync("NetTarget", Core.getNetworkNameOf(newTarget))
				end
			end
		end
	end
	local function handleRetarget()
		targetSelector.deselect()
	end
	function self.handleUpgrade(param)
		if tonumber(param)>upgrade.getLevel("upgrade") then
			upgrade.upgrade("upgrade")
		elseif upgrade.getLevel("upgrade")>tonumber(param) then
			upgrade.degrade("upgrade")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() and Core.getNetworkName():len()>0 then
			comUnit:sendNetworkSyncSafe("upgrade1",tostring(param))
		end
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		--Achievements
		comUnit:sendTo("stats","addBillboardInt","level"..upgrade.getLevel("upgrade")..";1")
		if upgrade.getLevel("upgrade")==3 then
			comUnit:sendTo("SteamAchievement","Upgrader","")
		end
		--

		if not xpManager or upgrade.getLevel("upgrade")==1 or upgrade.getLevel("upgrade")==2 or upgrade.getLevel("upgrade")==3 then
			local rotaterMatrix = rotatorMesh:getLocalMatrix()--get rotation for rotater
			local engineMatrix = engineMesh:getLocalMatrix()--get rotation for engine
			local prevModel = model
			this:removeChild(model)
		
			model = Core.getModel( string.format("tower_minigun_l%d.mym", upgrade.getLevel("upgrade")) )
			this:addChild(model)
			initModel()
			rotatorMesh:setLocalMatrix(rotaterMatrix)
			rotatorMesh:setLocalPosition(Vec3())
			engineMesh:setLocalMatrix(engineMatrix)--set the old rotation
			
			particleEffectGun[0]:getParent():removeChild( particleEffectGun[0] )
			particleEffectGunLaser[0]:getParent():removeChild( particleEffectGunLaser[0] )
			if upgrade.getLevel("overCharge")>0 then
				particleEffectSmoke[0]:getParent():removeChild( particleEffectSmoke[0] )
			end
			pointLight:getParent():removeChild( pointLight )
			if heatPointLight1 then heatPointLight1:getParent():removeChild( heatPointLight1 ) end
			particleEffectTracer[0]:getParent():removeChild( particleEffectTracer[0] )
			if upgrade.getLevel("range")>0 then
				particleEffectBeam:getParent():removeChild(particleEffectBeam)
				model:getMesh( "lasersight"..upgrade.getLevel("range") ):addChild(particleEffectBeam)
			end
			
			if upgrade.getLevel("overCharge")>0 then
				this:addChild(particleEffectSmoke[0])
			end
			engineMesh:addChild(pointLight)
			pointLight:setVisible(false)
			if heatPointLight1 then engineMesh:addChild(heatPointLight1) end
			pipesMesh:addChild(particleEffectGun[0])
			model:getMesh( "pipeBoost" ):addChild(particleEffectGunLaser[0])
			pipesMesh:addChild(particleEffectTracer[0])
			if upgrade.getLevel("upgrade")==3 then
				if upgrade.getLevel("overCharge")>0 then
					particleEffectSmoke[1] = ParticleSystem( ParticleEffect.MinigunOverheatSmoke )
					heatPointLight2 = PointLight(Vec3(),Vec3(3.0,0.15,0.0),0.2)
					model:getMesh( "engine" ):addChild( heatPointLight2 )
					setPipePointLightPos(heatPointLight2,1)
					this:addChild(particleEffectSmoke[1])
					particleEffectSmoke[1]:activate(Vec3())
					particleEffectSmoke[1]:setSpawnRate(0.0)
				end
				pipes2Mesh:addChild(particleEffectGun[1])
				model:getMesh( "pipeBoost" ):addChild(particleEffectGunLaser[1])
				pipes2Mesh:addChild(particleEffectTracer[1])
			end
			--
			--save the memory
			--prevModel:destroy()
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
			cTowerUpg.fixAllPermBoughtUpgrades()--fix the permanant upgrades from the shop
		end
		upgrade.clearCooldown()
		setCurrentInfo()
	end
	function self.handleBoost(param)
		if tonumber(param)>upgrade.getLevel("boost") then
			upgrade.upgrade("boost")
			if Core.isInMultiplayer() then
				comUnit:sendNetworkSyncSafe("upgrade2","1")
			end
			boostedOnLevel = upgrade.getLevel("upgrade")
			overHeatPer = 0.0
			model:getMesh( "pipeBoost" ):setVisible(true)
			model:getMesh( "cabels" ):setVisible(false)
			model:getMesh( "pipe1" ):setVisible(false)
			--particleEffectBoostBeam:setLocalPosition(Vec3(0.0,-0.4,0.17))
			if upgrade.getLevel("upgrade")==3 then
				model:getMesh( "pipe2" ):setVisible(false)
			end
			setCurrentInfo()
			--Achievement
			comUnit:sendTo("SteamAchievement","Boost","")
		elseif upgrade.getLevel("boost")>tonumber(param) then
			upgrade.degrade("boost")
			upgrade.clearCooldown()
			--
			initModel()
			setCurrentInfo()
		else
			return--level unchanged
		end
	end
	function self.upgradeRange(param)
		if tonumber(param)>upgrade.getLevel("range") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("range")
		elseif upgrade.getLevel("range")>tonumber(param) then
			model:getMesh("lasersight".. upgrade.getLevel("range")):setVisible(false)
			upgrade.degrade("range")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade3",tostring(param))
		end
		if upgrade.getLevel("range")==0 then
			if particleEffectBeam then
				particleEffectBeam:deactivate()
			end
		else
			particleEffectBeam = particleEffectBeam or ParticleSystem( ParticleEffect.LaserSight1 )
			model:getMesh("lasersight"..upgrade.getLevel("range")):setVisible(true)
			local laserBeamRange = 0.45+(upgrade.getLevel("range")*0.12)
			if upgrade.getLevel("range")>1 then
				model:getMesh("lasersight"..upgrade.getLevel("range")-1):setVisible(false)
				model:getMesh("lasersight"..upgrade.getLevel("range")-1):removeChild(particleEffectBeam)
				particleEffectBeam:setSpawnRate( 1.0+(upgrade.getLevel("range")) )
			end
			--particleEffectBeam:setSpawnRadius(0.5)
			particleEffectBeam:activate(Vec3(0.0,-0.1,0.0),Vec3(0.0,-1.0,0.0))
			particleEffectBeam:setFullAlphaOnRange(laserBeamRange)
			particleEffectBeam:setEmitterLine(Line3D(Vec3(0.0,-0.6,0.0),Vec3(0.0,-laserBeamRange,0.0)),Vec3(0.0,-1.0,0.0))
			model:getMesh( "lasersight"..upgrade.getLevel("range") ):addChild(particleEffectBeam)
			--Acievement
			if upgrade.getLevel("range")==3 then
				comUnit:sendTo("SteamAchievement","Range","")
			end
		end
		setCurrentInfo()
	end
	local function doMeshUpgradeForLevel(name,meshName)
		local d1 = meshName
		local d2 = upgrade.getLevel(name)
		local d3 = meshName..upgrade.getLevel(name)
		local d4 = model
		model:getMesh(meshName..upgrade.getLevel(name)):setVisible(true)
		if upgrade.getLevel(name)>1 then
			model:getMesh(meshName..(upgrade.getLevel(name)-1)):setVisible(false)
		end
	end
	function self.upgradeGreaseBullet(param)
		if tonumber(param)>upgrade.getLevel("fireCrit") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("fireCrit")
		elseif upgrade.getLevel("fireCrit")>tonumber(param) then
			model:getMesh("oil"..upgrade.getLevel("fireCrit")):setVisible(false)
			upgrade.degrade("fireCrit")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade5",tostring(param))
		end
		if upgrade.getLevel("fireCrit")>0 then
			doMeshUpgradeForLevel("fireCrit","oil")
		end
		setCurrentInfo()
	end
	local function handleSupportBase(param,index)
		local activeLevel = tonumber(param)
		support["supportBase"][index] = activeLevel
	end
	function self.upgradeOverCharge(param)
		if tonumber(param)>upgrade.getLevel("overCharge") and tonumber(param)<=upgrade.getLevel("upgrade") then
			upgrade.upgrade("overCharge")
		elseif upgrade.getLevel("overCharge")>tonumber(param) then
			model:getMesh("engineboost"..upgrade.getLevel("overCharge")):setVisible(false)
			upgrade.degrade("overCharge")
		else
			return--level unchanged
		end
		if Core.isInMultiplayer() then
			comUnit:sendNetworkSyncSafe("upgrade4",tostring(param))
		end
		if upgrade.getLevel("overCharge")==0 then
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
				particleEffectSmoke[0] = ParticleSystem( ParticleEffect.MinigunOverheatSmoke )
				this:addChild(particleEffectSmoke[0])
			end
			billboard:setFloat("overHeatPer",0.0)
			doMeshUpgradeForLevel("overCharge","engineboost")
			if not heatPointLight1 then
				heatPointLight1 = PointLight(Vec3(),Vec3(3.0,0.15,0.0),0.2)
				model:getMesh( "engine" ):addChild( heatPointLight1 )
				setPipePointLightPos(heatPointLight1,0)
				particleEffectSmoke[0]:activate(Vec3())
				particleEffectSmoke[0]:setSpawnRate(0.0)
			end
			heatPointLight1:setVisible(false)
			heatPointLight1:setCutOff(0.15)
			if upgrade.getLevel("overCharge")==3 or upgrade.getLevel("upgrade")==3 then
				if not heatPointLight2 then
					particleEffectSmoke[1] = ParticleSystem( ParticleEffect.MinigunOverheatSmoke )
					heatPointLight2 = PointLight(Vec3(),Vec3(3.0,0.15,0.0),0.2)
					model:getMesh( "engine" ):addChild( heatPointLight2 )
					setPipePointLightPos(heatPointLight2,1)
					this:addChild(particleEffectSmoke[1])
					particleEffectSmoke[1]:activate(Vec3())
					particleEffectSmoke[1]:setSpawnRate(0.0)
				end
				heatPointLight2:setVisible(false)
				heatPointLight2:setCutOff(0.15)
			end
		end
		setCurrentInfo()
	end
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
	local function init()
		--this:setIsStatic(true)
		Core.setUpdateHz(60.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end

		
		this:createBoundVolumeGroup()
		this:setBoundingVolumeCanShrink(false)
		
		restartListener = Listener("RestartWave")
		restartListener:registerEvent("restartWave", restartWave)
	
		model = Core.getModel("tower_minigun_l1.mym")
		local hullModel = Core.getModel("tower_resource_hull.mym")
		this:addChild(model)
		this:addChild(StaticBody(model:getMesh("physic")))
		--
		--
		--
		if xpManager then
			xpManager.setUpgradeCallback(self.handleUpgrade)
		end
		--set level 0 info
		--horMaxSpeed,horMinSpeed,horSpeedAcc,verMaxSpeed,verMinSpeed,verSpeedAcc
		rotator.setVerticalLimits(-math.pi*0.25,math.pi*0.45)
		--
		--ParticleEffects
		--
		particleEffectGun[0] = ParticleSystem( ParticleEffect.MinigunFire2 )
		particleEffectGun[0]:setScale(0.80)
		particleEffectGun[1] = ParticleSystem( ParticleEffect.MinigunFire2 )
		particleEffectGun[1]:setScale(0.80)
		
		particleEffectGunLaser[0] = ParticleSystem( ParticleEffect.MinigunLaserBlast )
		particleEffectGunLaser[0]:setScale(0.80)
		particleEffectGunLaser[1] = ParticleSystem( ParticleEffect.MinigunLaserBlast )
		particleEffectGunLaser[1]:setScale(0.80)
		
		if particleEffectUpgradeAvailable then
			this:addChild(particleEffectUpgradeAvailable)
		end
	
		particleEffectTracer[0] = ParticleSystem( ParticleEffect.TracerLine )
		particleEffectTracer[1] = ParticleSystem( ParticleEffect.TracerLine )
		
		pointLight:setVisible(false)
		
		model:getMesh( "pipe1" ):addChild(particleEffectGun[0])
		model:getMesh( "pipeBoost" ):addChild(particleEffectGunLaser[0])
		model:getMesh( "engine" ):addChild(pointLight)
		--model:getMesh( "pipe2" ):addChild(particleEffectGun[1])
	
		--model:addChild(particleEffectHitt)
		model:getMesh( "pipe1" ):addChild(particleEffectTracer[0])
		--model:getMesh( "pipe2" ):addChild(particleEffectTracer[1]
	

		--Laser
		soundLaser = SoundNode("laser_bullet1")
		soundLaser:setSoundPlayLimit(8)
		soundLaser:setLocalSoundPLayLimit(4)
		this:addChild(soundLaser)
		--Gun
		soundAttack = SoundNode("minigunTower_attack")
		soundAttack:setSoundPlayLimit(8)
		soundAttack:setLocalSoundPLayLimit(3)
		this:addChild(soundAttack)
		
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
		billboard:setString("hullName","hull")
		billboard:setVectorVec3("hull3d",createHullList3d(hullModel:getMesh("hull")))
		billboard:setVectorVec2("hull2d",createHullList2d(hullModel:getMesh("hull")))
		billboard:setModel("tower",model)
		billboard:setVec3("Position",this:getGlobalPosition()+Vec3(0,2.2,0))--for locating where the physical attack originated
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Minigun tower")
		billboard:setString("FileName", "Tower/MinigunTower.lua")
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
	
		-- UPGRADES
		billboard:setDouble("rangePerUpgrade",0.75)
		upgrade.setBillboard(billboard)
		upgrade.addDisplayStats("damage")
		upgrade.addDisplayStats("RPS")
		upgrade.addDisplayStats("fireDPS")
		upgrade.addDisplayStats("burnTime")
		upgrade.addDisplayStats("range")
		upgrade.addDisplayStats("text")
		
		upgrade.addUpgrade({	cost = 200,
								name = "upgrade",
								info = "minigun tower level",
								order = 1,
								icon = 56,
								value1 = 1,
								stats = {range =	{ upgrade.add, 5.0, ""},
										damage = 	{ upgrade.add, 115, ""},
										RPS = 		{ upgrade.add, 2.5, ""},
										rotationSpeed =	{ upgrade.add, 1.20, ""} }
							} )
		--DPSpG == Damage*RPS/cost*0.111 == 40*2.5/100 = 0.99
		upgrade.addUpgrade( {	cost = 400,
								name = "upgrade",
								info = "minigun tower level",
								order = 1,
								icon = 56,
								value1 = 2,
								stats = {range =	{ upgrade.add, 5.0, ""},
										damage = 	{ upgrade.add, 325, ""},
										RPS = 		{ upgrade.add, 2.5, ""},
										rotationSpeed =	{ upgrade.add, 1.40, ""} }
							}, 0 )
		--DPSpG == Damage*RPS/cost == 81*3.75/300 == 1.01
		upgrade.addUpgrade( {	cost = 800,
								name = "upgrade",
								info = "minigun tower level",
								order = 1,
								icon = 56,
								value1 = 3,
								stats = {range =	{ upgrade.add, 5.0, ""},
										damage = 	{ upgrade.add, 405, ""},
										RPS = 		{ upgrade.add, 5.0, ""},
										rotationSpeed =	{ upgrade.add, 1.60, ""} }
							}, 0 )
		--DPSpG == Damage*RPS/cost == 146*5/700 = 1.04
		-- BOOST
		local function fireDamage() return upgrade.getStats("damage")*2.0*(waveCount/25+1.0) end
		--(boost)	0=1x	25=2x	50=3x
		local function boostDamage() return upgrade.getStats("damage")*3.0*(waveCount/25+1.0) end
		--(boost)	0=1x	25=2x	50=3x
		--(total)	0=2x	25=4x	50=6x
		upgrade.addUpgrade( {	cost = 0,
								name = "boost",
								info = "minigun tower boost",
								order = 10,
								duration = 10,
								cooldown = 3,
								icon = 57,
								stats = {range = 	{ upgrade.add, 0.75, ""},
										fireDPS =	{ upgrade.func, fireDamage, ""},
										burnTime =	{ upgrade.add, 1.0, ""},
										damage =	{ upgrade.func, boostDamage, ""},
										RPS = 		{ upgrade.mul, 1.25, ""},
										rotationSpeed =	{ upgrade.mul, 2.5, ""} }
							} )
		-- RANGE
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 0 or 100,
								name = "range",
								info = "minigun tower range",
								order = 2,
								icon = 59,
								value1 = 5 + 0.75,
								levelRequirement = cTowerUpg.getLevelRequierment("range",1),
								stats = {range = 		{ upgrade.add, 0.75, ""}}
							} )
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 100 or 200,
								name = "range",
								info = "minigun tower range",
								order = 2,
								icon = 59,
								value1 = 5 + 1.5,
								levelRequirement = cTowerUpg.getLevelRequierment("range",2),
								stats = {range = 		{ upgrade.add, 1.50, ""}}
							} )
		upgrade.addUpgrade( {	cost = cTowerUpg.isPermUpgraded("range",1) and 200 or 300,
								name = "range",
								info = "minigun tower range",
								order = 2,
								icon = 59,
								value1 = 5 + 2.25,
								levelRequirement = cTowerUpg.getLevelRequierment("range",3),
								stats = {range = 		{ upgrade.add, 2.25, ""}}
							} )
		-- OVERCHARGE (increases peak DPS with 30% every upgrade +-1%), can optimal used in combo with boost because of 8s before over heat with an top 90% damage increase
		-- multiplicative with the 400% damage boost will net you 760% damage. or if constant shooting only 608%
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "overCharge",
								info = "minigun tower overcharge",
								order = 3,
								icon = 63,
								value1 = 40,
								levelRequirement = cTowerUpg.getLevelRequierment("overCharge",1),
								stats = {	damage = 	{ upgrade.mul, 1.27, ""},
											RPS =		{ upgrade.mul, 1.1, ""},
											cooldown =	{ upgrade.add, 10.0, "s"},
											overheat =	{ upgrade.add, 12.0, "s"} }--(10/(10+12))*RPS*damge==0.76 (worst case -26%) [15% is target for average]
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "overCharge",
								info = "minigun tower overcharge",
								order = 3,
								icon = 63,
								value1 = 80,
								levelRequirement = cTowerUpg.getLevelRequierment("overCharge",2),
								stats = {	damage = 	{ upgrade.mul, 1.56, ""},
											RPS =		{ upgrade.mul, 1.15, ""},
											cooldown =	{ upgrade.add, 10.0, "s"},
											overheat =	{ upgrade.add, 12.0, "s"} }--(10/(10+12))*RPS*damge==0.98 (worst case -2%) [30% is target for average]
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "overCharge",
								info = "minigun tower overcharge",
								order = 3,
								icon = 63,
								value1 = 120,
								levelRequirement = cTowerUpg.getLevelRequierment("overCharge",3),
								stats = {	damage = 	{ upgrade.mul, 1.84, ""},
											RPS =		{ upgrade.mul, 1.2, ""},
											cooldown =	{ upgrade.add, 10.0, "s"},
											overheat =	{ upgrade.add, 12.0, "s"} }--(10/(10+12))*RPS*damge==1.20 (worst case +20%)	[45% is target for average]
							} )
		-- Grease bullets (increases the damage to burning targets by 20% every upgrade)
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fireCrit",
								info = "minigun tower firecrit",
								order = 4,
								icon = 36,
								value1 = 20,
								levelRequirement = cTowerUpg.getLevelRequierment("fireCrit",1),
								stats = {	fireCrit = 	{ upgrade.add, 0.20, ""}}
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fireCrit",
								info = "minigun tower firecrit",
								order = 4,
								icon = 36,
								value1 = 40,
								levelRequirement = cTowerUpg.getLevelRequierment("fireCrit",2),
								stats = {	fireCrit = 	{ upgrade.add, 0.40, ""}}
							} )
		upgrade.addUpgrade( {	costFunction = upgrade.calculateCostUpgrade,
								name = "fireCrit",
								info = "minigun tower firecrit",
								order = 4,
								icon = 36,
								value1 = 60,
								levelRequirement = cTowerUpg.getLevelRequierment("fireCrit",3),
								stats = {	fireCrit = 	{ upgrade.add, 0.60, ""}}
							} )
		--support tower functions
		supportManager.setUpgrade(upgrade)
		supportManager.addHiddenUpgrades()
		supportManager.addSetCallbackOnChange(updateStats)
		
		upgrade.upgrade("upgrade")
		billboard:setInt("level",upgrade.getLevel("upgrade"))
		billboard:setString("targetMods","attackClosestToExit;attackPriorityTarget;attackWeakestTarget;attackStrongestTarget")
		billboard:setInt("currentTargetMode",1)
	
		--ComUnitCallbacks
		comUnitTable["dmgDealt"] = damageDealt
		comUnitTable["waveChanged"] = waveChanged
		comUnitTable["upgrade1"] = self.handleUpgrade
		comUnitTable["upgrade2"] = self.handleBoost
		comUnitTable["upgrade3"] = self.upgradeRange
		comUnitTable["upgrade4"] = self.upgradeOverCharge
		comUnitTable["upgrade5"] = self.upgradeGreaseBullet
		comUnitTable["NetOwner"] = setNetOwner
		comUnitTable["NetTarget"] = NetSyncTarget
		comUnitTable["Retarget"] = handleRetarget
		comUnitTable["SetTargetMode"] = SetTargetMode
		supportManager.setComUnitTable(comUnitTable)
		supportManager.addCallbacks()
		
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(upgrade.getValue("range"))

	
		initModel()
		setCurrentInfo()
				
		cTowerUpg.addUpg("range",self.upgradeRange)
		cTowerUpg.addUpg("overCharge",self.upgradeOverCharge)
		cTowerUpg.addUpg("fireCrit",self.upgradeGreaseBullet)
		cTowerUpg.fixAllPermBoughtUpgrades()--fix the permanant upgrades from the shop
		
		myStatsReset()
		
--		if upgrade.getFreeSubUpgradeCounts()>0 then
--			abort()
--		end
		
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
		if upgrade.update() then
			myStats.disqualified = true
			pipeRotateTimer = 0.0
			initModel()
			setCurrentInfo()
			--if the tower was upgraded while boosted, then the boost should be available
			if boostedOnLevel~=upgrade.getLevel("upgrade") then
				upgrade.clearCooldown()
			end
		end
		
		comUnit:setPos(this:getGlobalPosition())
		
		--change update speed
--		local tmpCameraNode = cameraNode
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 20) * 2)
--		print("state "..state)
--		print("Hz: "..((state == 2) and 60.0 or (state == 1 and 30 or 10)))
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end
		
		
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
		if pointLightTimer>0.0 then
			pointLightTimer = pointLightTimer - Core.getDeltaTime()
			if pointLightTimer<=0.0 then
				pointLight:setVisible(false)
			end
		end
		reloadTimeLeft = reloadTimeLeft - Core.getDeltaTime()
		local pipeAt = -engineMesh:getGlobalMatrix():getUpVec()
		updateTarget()
		updateSync()
		
		if overheated==false and targetSelector.getTargetIfAvailable()>0 then
			local npcSize = 1.75--target:getNPCSize()
			local targetAt = targetSelector.getTargetPosition()-engineMesh:getGlobalPosition()
			
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
					if upgrade.getLevel("overCharge")>0 then
						overHeatPer = overHeatPer + overheatAdd
						if overHeatPer>1.0 then
							overHeatPer = 1.0
							overheated = true
							targetSelector.deselect()
							reloadTimeLeft = upgrade.getValue("coolDown")
						end
					end
					--if time to attack
					reloadTimeLeft = (reloadTimeLeft<-Core.getDeltaTime()) and reloadTime or reloadTimeLeft + reloadTime
					if upgrade.getLevel("boost")==1 then
						attackLaserBeam()
						overHeatPer = 0.0
					else
						attack()
						upgrade.setUsed()--set value changed
						pointLightTimer = 0.075
						pointLight:clear()
						pointLight:setRange(1.25)
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
		--if we are not fiering the pipe will cooldown
		if upgrade.getLevel("overCharge")>0 then
			--debug stats
			if overheated then myStats.inoverHeatTimer = myStats.inoverHeatTimer + Core.getDeltaTime() end
			--debug stats
			local mat = model:getMesh( "engine" ):getGlobalMatrix()
			if upgrade.getLevel("upgrade")==3 then
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
				if upgrade.getLevel("upgrade")==3 then
					particleEffectSmoke[1]:setSpawnRate(0.0)
				end
			end
			billboard:setFloat("overHeatPer",overHeatPer)
			
			local visiblePer = overheated and math.min(1.0,overHeatPer*1.5+0.05) or overHeatPer*overHeatPer
			if upgrade.getLevel("boost")>0 then
				model:getMesh( "pipeBoost" ):setUniform(model:getMesh( "pipeBoost" ):getShader(), "heat", visiblePer)
			else
				model:getMesh( "pipe1" ):setUniform(model:getMesh( "pipe1" ):getShader(), "heat", visiblePer)
				if upgrade.getLevel("upgrade")==3 then
					model:getMesh( "pipe2" ):setUniform(model:getMesh( "pipe2" ):getShader(), "heat", visiblePer)
				end
			end
			setOverHeatPointLigth(heatPointLight1,visiblePer,Vec3())
			particleEffectSmoke[0]:setSpawnRate( (visiblePer>0.5) and (visiblePer-0.5)*2.0 or 0.0 )
			if upgrade.getLevel("overCharge")==3 then
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
		if upgrade.getLevel("boost")==0 then
			--rotate the pipes
			if pipeRotateTimer>0.0 then
				local pipeRotation = (pipeRotateTimer/ROTATEPIPETIMEAFTERFIERING)*Core.getDeltaTime()*rotationSpeed
				pipeRotateTimer = pipeRotateTimer - Core.getDeltaTime()
	
				pipesMesh:rotate(Vec3(0.0, 1.0, 0.0), pipeRotation)
				if upgrade.getLevel("upgrade")==3 then
					pipes2Mesh:rotate(Vec3(0.0, 1.0, 0.0), pipeRotation)
				end
			end
		end
		--
		--projectiles
		--
		projectiles.update()
		--
		--debug stats
		--
		if targetSelector.isTargetAvailable() then
			if not overheated then myStats.activeTimer = myStats.activeTimer + Core.getDeltaTime() end
		end
		--
		--debug stats
		--
	
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