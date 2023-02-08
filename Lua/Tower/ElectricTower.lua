require("Tower/supportManager.lua")
require("NPC/state.lua")
require("Game/campaignTowerUpg.lua")
require("Game/particleEffect.lua")
require("Game/graphicParticleSystems.lua")
require("Game/targetSelector.lua")
require("Game/mapInfo.lua")
require("Game/soundManager.lua")
require("Tower/TowerData.lua")

--this = SceneNode()
ElectricTower = {}
function ElectricTower.new()
	local MAXTHEORETICALENERGYTRANSFERRANGE = (4+2.25)*1.3+0.75
	local TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION = 0.2
	local self = {}
	local waveCount = 0
	local dmgDone = 0
	local cData = CampaignData.new()
	local supportManager = SupportManager.new()
	local damagePerEnergy = 19
	--data
	local data = TowerData.new()
	--model
	local model
	local ring = {}
	local localRingCenterPos = Vec3()
	--attack
	local targetMode = 1
	local lastEnergyRequest = 0.0
	local slow = 0.0
	local slowRange = 0.0
	local SlowDuration = 0.0
	local reloadTimeLeft = 0.0
	local energy = 0.0
	local energyReg = 0.0
	local AttackEnergyCost = 0.0
	local oneDamageCost = 0.0
	local minAttackCost = 0.0
	local equalizer =	false
	local boostedOnLevel = 0
	--effect
	local energyLightShow = 2.0
	local pointLightBaseRange = 1.75
	local particleSparcleCenter = GraphicParticleSystems.new().createTowerElectricEffect()
--	local sparkCenter = ParticleSystem.new(ParticleEffect.SparkSpirit)
	local electric1 = ParticleEffectElectricFlash.new("Lightning_D.tga")
	local electric2 = ParticleEffectElectricFlash.new("Lightning_D.tga")
	local pointLight = PointLight.new(Vec3(0,2.5,0),Vec3(0.0,4.0,4.0),pointLightBaseRange)
	local pointLightAttack = PointLight.new(Vec3(),Vec3(0.0,3.0,3.0),3.0)
	--upgrades
	local energyOffers = {size=0,frameCounter=0,depth=0}
	--communication
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local billboardWaveStats
	--sound
	local attackSounds = {"electric_attack1", "electric_attack2", "electric_attack3", "electric_attack4"}
	local soundManager = SoundManager.new(this)
	--other
	local isAnyInRange = {timer=0.0, isAnyInRange=false}
	local syncTimer = 0.0 
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	local visibleState = 2
	local cameraNode = this:getRootNode():findNodeByName("MainCamera") or this
	local energySent = 0
	local lastRestored = -1
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	--stats
	local isCircleMap = MapInfo.new().isCricleMap()
	local mapName = MapInfo.new().getMapName()
	--Achievements
	--
	local boostActive = false
	
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
			tab = {}
			tab["storedEnergy"] = energy
			
			data.storeWaveChangeStats(waveStr, tab)
		end
	end
	
	local function updateMeshesAndparticlesForSubUpgrades()
		for index =1, 3, 1 do
			model:getMesh( string.format("range%d", index) ):setVisible( data.getLevel("energyPool")==index )--this is just reusing the same model
			model:getMesh( string.format("slow%d", index) ):setVisible( data.getLevel("ampedSlow")==index )
			model:getMesh( string.format("amplifier%d", index) ):setVisible( data.getLevel("energy")==index )
			model:getMesh( string.format("equalizer%d", index) ):setVisible( data.getLevel("range")==index )
			model:getMesh( string.format("masterAim%d", index) ):setVisible( false )
		end
		
		model:getMesh("boost"):setVisible(data.getBoostActive())
		--set ambient map
		for index=0, model:getNumMesh()-1 do
			local mesh = model:getMesh(index)
			local shader = mesh:getShader()
			local texture = Core.getTexture(data.getBoostActive() and "towergroup_boost_a" or "towergroup_a")
			
			mesh:setTexture(shader,texture,4)
		end
		
		for index = 1, data.getTowerLevel(), 1 do
			ring[index] = model:getMesh( string.format("ring%d", index) )
		end
		localRingCenterPos = ring[1]:getLocalMatrix():getPosition()
		--performance check
		for index = 1, data.getTowerLevel(), 1 do
			ring[index]:DisableBoundingVolumesDynamicUpdates()
		end
		
	end
	
	local function SetTargetMode(param)
		targetMode = math.clamp(tonumber(param),1,5)
		billboard:setInt("currentTargetMode",targetMode)
		if billboard:getBool("isNetOwner") and Core.isInMultiplayer() then
			comUnit:sendNetworkSync("SetTargetMode", tostring(param) )
		end
	end
	
	local function restoreWaveChangeStats( wave )
		if isThisReal then
			local towerLevel = data.getTowerLevel()
			local tab = data.restoreWaveChangeStats( wave )	
			if tab ~= nil then
				energy = tab.storedEnergy
				SetTargetMode(tab.currentTargetMode)
			end
		
			if towerLevel ~= data.getTowerLevel() then
				self.handleUpgrade("upgrade;"..tostring(data.getTowerLevel()))
			else
				updateMeshesAndparticlesForSubUpgrades()
			end
		end
	end
	
	local function restartWave(param)
		supportManager.restartWave()
		restoreWaveChangeStats( tonumber(param) )
		dmgDone = 0
	end
	
	local function doLightning(targetPosition,sphere)
		if targetPosition:length()>0.01 then
		
			local endPos = this:getGlobalMatrix():inverseM()*targetPosition
			
			pointLightAttack:setLocalPosition( (localRingCenterPos+endPos)*0.5 )
			pointLightAttack:setVisible(true)
			pointLightAttack:setRange(4.0)
			pointLightAttack:pushRangeChange(0.25,math.min((1.0/data.getValue("RPS"))-0.05,0.5))
			pointLightAttack:pushVisible(false)
			
		
			if sphere then
				sphere = Sphere(this:getGlobalMatrix():inverseM()*sphere:getPosition(),sphere:getRadius())
				electric1:setLine(localRingCenterPos,endPos,sphere,0.35)
				electric2:setLine(localRingCenterPos,endPos,sphere,0.45)
			else
				electric1:setLine(localRingCenterPos,endPos,0.35)
				electric2:setLine(localRingCenterPos,endPos,0.45)
			end
		
			if reloadTimeLeft<-Core.getDeltaTime() then--if over due for fiering
				reloadTimeLeft = (1.0/data.getValue("RPS"))
			else--if we was supposed to fire this frame
				reloadTimeLeft = reloadTimeLeft + (1.0/data.getValue("RPS"))
			end
			--lastEnergyRequest = 0.75--tower can ask for energy every 0.75s
			return true
		end
		return false
	end
	local function canOfferEnergy(askerInPrioOverUs)
		if energy>AttackEnergyCost then
			return math.clamp(AttackEnergyCost*1.5, energy*(askerInPrioOverUs and 0.35 or 0.1), energy)
		else
			return 0
		end
	end
	local function doWeHaveEnergyOver(param, fromIndex)
		--energy transfer can only occure if there is no enemy in range
		--we will only give energy if they have priority(an enemy in range)
		--or we have shorter time to max energy +2s
		
		--make sure we don't have priority (enemy in range)
		if targetSelector.isAnyInRange()==false and reloadTimeLeft<0.0 then
			local energyMax = data.getValue("energyMax")
			local percentage = energy/energyMax
			--make sure the tower is in range
			if (this:getGlobalPosition()-Core.getBillboard(fromIndex):getVec3("GlobalPosition")):length()<=data.getValue("range")+0.75 then
				local rechargeTimeLeft = (energyMax-energy)/energyReg
				if param.deficit>1 then
					local canOffer = canOfferEnergy(param.prio)
					if canOffer>AttackEnergyCost*0.5 then
						local canOfferPercentage = (canOffer*2)/energyMax
						if param.prio or rechargeTimeLeft+2.0<param.rechargeTimeLeft then
							--give energy if they are in priority or we have 2s shorter resharge time
							if energy>AttackEnergyCost then
								comUnit:sendTo(fromIndex,"canOfferEnergy",{canOffer=canOffer, rechargeTimeLeft=rechargeTimeLeft})
							end
						end
					end
				elseif energy+1>energyMax then
					--if we are full on energy and the other tower is not requesting energy, then we can do a light show to visualize the link
					comUnit:sendTo(fromIndex,"canOfferEnergy",{canOffer=0.1, rechargeTimeLeft=0})-- offers<1 will not send any energy
				end
			end
		end
	end
	--a tower have asked for our energy reserve
	local function sendEnergyTo(parameter, fromIndex)
		local neededEnergy = parameter.energyNeed
		--we assume he has prio. (because they will not ask for more that our offer)
		local canOffer = canOfferEnergy(true)
		local willSend = canOffer>neededEnergy and neededEnergy or canOffer
		comUnit:sendTo(fromIndex,"sendEnergyTo",tostring(willSend))
		energy = energy - willSend
		doLightning(parameter.pos+Vec3(0.0,2.75,0.0))
		--stats
		energySent = energySent + willSend
		comUnit:sendTo("SteamStats","ElectricTowerMaxEnergySent",energySent)
	end
	local function updateAskForEnergy()
		--we wait for 2 frames so all offer can be heard at the same time
		energyOffers.frameCounter = energyOffers.frameCounter - 1
		if energyOffers.frameCounter==0 then
			local energyMax = data.getValue("energyMax")
			local energyNeed = energy+1>energyMax and 0 or energyMax-(energy+(energyReg*Core.getDeltaTime()*2.0)) --energyReg*Core.getDeltaTime()*2.0) estimated delta time before reciving energy
			local maxOffer = -1
			local bestIndex = 0
			for index=1, energyOffers.size, 1 do
				if energyOffers[index].offer>maxOffer then
					maxOffer = energyOffers[index].offer
					bestIndex = energyOffers[index].from
					--if we have gotten an offer of what we need
					if maxOffer>energyNeed then
						maxOffer = energyNeed
						break
					end
				end
			end
			if bestIndex>0 then
				comUnit:sendTo(bestIndex,"sendMeEnergy",{energyNeed=energyNeed>1 and maxOffer or 0,pos=this:getGlobalPosition()})
			end
		end
	end
	--a tower is serching for more energy
	--recive information when a tower can lend some energy
	local function someoneCanOfferEnergy(parameter, fromIndex)
		energyOffers.size = energyOffers.size + 1
		energyOffers[energyOffers.size] = {offer=parameter.canOffer, rechargeTimeLeft=parameter.rechargeTimeLeft, from=fromIndex}
	end
	local function recivingEnergy(parameter, fromIndex)
		energy = energy + tonumber(parameter)
		local energyMax = data.getValue("energyMax")
		if energy>energyMax then
			local diff = energyMax-energy
			if diff>2 then--ops we got to much energy send it back. no fancy show, it was pure unluck
				comUnit:sendTo(fromIndex,"sendEnergyTo",tostring(diff))
			end
			energy = energyMax
		end
		--
		--Achievement
		--
		if not LinkAchievement then
			LinkAchievement = true
			achievementUnlocked("Link")
		end
	end
	local function updateStats()
		slow =			data.getValue("slow")
		slowRange = 	data.getValue("slowRange")
		SlowDuration =	data.getValue("slowTimer")
		energyReg =		 	data.getValue("energyReg")--info[upgradeLevel]["energyMax"]/info[upgradeLevel][chargeTime]
		AttackEnergyCost =	data.getValue("attackCost")
		oneDamageCost =		data.getValue("attackCost")/data.getValue("damage")
		minAttackCost = 	data.getValue("minDamage")*oneDamageCost
		equalizer =			(data.getValue("equalizer")>0.5)
		targetSelector.setRange(data.getValue("range"))
	end
	local function setCurrentInfo()
	
		data.updateStats()

		reloadTimeLeft =	0.0
		energy =			data.getValue("energyMax")--info[upgradeLevel]["energyMax"]
		
		updateStats()
		--achievment
		if data.getIsMaxedOut() then
			achievementUnlocked("ElectricMaxed")
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
	function self.handleUpgrade(param)
		
		print("handleUpgrade("..param..")")
		local subString, size = split(param, ";")
		local level = tonumber(subString[2])

		data.setTowerLevel(level)
		
		local newModel = Core.getModel( "tower_electric_l"..level..".mym" )			
		if newModel then
			local matrixList = {}
			for i=1, level-1, 1 do
				matrixList[i] = model:getMesh("ring"..i):getLocalMatrix()
			end
		
			this:removeChild(model:toSceneNode())
			model = newModel
			this:addChild(model:toSceneNode())
			for i=1, level-1, 1 do
				model:getMesh("ring"..i):setLocalMatrix( matrixList[i] )
			end
			
			model:createBoundVolumeGroup()
			model:setBoundingVolumeCanShrink(false)
		
			--model:getMesh( "physic" ):setVisible(false)
			model:getMesh("hull"):setVisible(false)
			model:getMesh("space0"):setVisible(false)
			
			updateMeshesAndparticlesForSubUpgrades()
		end
		setCurrentInfo()
	end
	function self.handleBoost(param)
		data.activateBoost()
		setCurrentInfo()
	end
	function self.handleSubUpgrade()
		updateMeshesAndparticlesForSubUpgrades()
		setCurrentInfo()
	end

	local function waveChanged(param)
		local name
		local waveCountStr
		name,waveCountStr = string.match(param, "(.*);(.*)")
		local waveCount = tonumber(waveCountStr)

		--update and save stats only if we did not just restore this wave
		if waveCount>=lastRestored then
			storeWaveChangeStats( tostring(waveCount+1) )
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
		if (billboard:getBool("isNetOwner") or targetSelector.getTargetIfAvailable()==0) then
			if targetSelector.selectAllInRange() then
				targetSelector.filterOutState(state.ignore)
				if targetMode==1 then
					--high priority
					targetSelector.scoreHP(10)
					targetSelector.scoreName("dino",10)
					targetSelector.scoreName("reaper",25)
					targetSelector.scoreName("skeleton_cf",25)
					targetSelector.scoreName("skeleton_cb",25)
				elseif targetMode==2 then
					--density
					targetSelector.scoreClosestToExit(10)
					targetSelector.scoreDensity(25)
				elseif targetMode==3 then
					--attackWeakestTarget
					targetSelector.scoreHP(-30)
					targetSelector.scoreClosestToExit(10)
				elseif targetMode==4 then
					--attackStrongestTarget
					targetSelector.scoreHP(30)
					targetSelector.scoreClosestToExit(20)
					targetSelector.scoreName("reaper",20)
					targetSelector.scoreName("skeleton_cf",20)
					targetSelector.scoreName("skeleton_cb",20)
				elseif targetMode==5 then
					--closest to exit
					targetSelector.scoreClosestToExit(20)
				end
				targetSelector.scoreState(state.markOfDeath,10)
				targetSelector.scoreState(state.highPriority,30)
				targetSelector.scoreName("electroSpirit",-1000)
				targetSelector.selectTargetAfterMaxScore(-500)
				--sync
				if billboard:getBool("isNetOwner") then
					local newTarget = targetSelector.getTarget()
					if newTarget>0 then
						comUnit:sendNetworkSync("NetTarget", Core.getNetworkNameOf(newTarget))
					end
				end
			end
			if targetSelector.getTarget()==0 then
				reloadTimeLeft = TIME_BETWEEN_RETARGETING_ON_FAILED_SELECTION
			end
		end
	end
	local function handleRetarget()
		targetSelector.deselect()
	end
	
	local function attack()
		local target = targetSelector.getTargetIfAvailable()
		if target>0 then
			local targetPosition = targetSelector.getTargetPosition(target)
			local ringCenterPos = ring[1]:getGlobalPosition()
			--
			soundManager.play(attackSounds[math.randomInt(1,#attackSounds)], 1.0, false)
			--
			if targetSelector.getIndexOfShieldCovering(targetPosition)==targetSelector.getIndexOfShieldCovering(ringCenterPos) then
				--direct hitt
				if doLightning(targetPosition) then
					local hp = targetSelector.getTargetHP(target)
					local totalKillCost = math.max(minAttackCost,hp*oneDamageCost)
					if totalKillCost<AttackEnergyCost then
						energy = energy - totalKillCost
						comUnit:sendTo(target,"attackElectric",tostring(totalKillCost/oneDamageCost+(hp*1.015)))--+regen for dino with 50% extra
					else
						energy = energy - AttackEnergyCost
						comUnit:sendTo(target,"attackElectric",tostring(data.getValue("damage")))
					end
					if slowRange==0.0 then
						comUnit:sendTo(target,"slow",{per=slow,time=SlowDuration,type="electric"})
					else
						comUnit:broadCast(targetPosition,slowRange,"slow",{per=slow,time=SlowDuration,type="electric"})
					end
				end
			else
				--forcefield hitt
				local shieldIndex = targetSelector.getIndexOfShieldCovering(targetPosition)>0 and targetSelector.getIndexOfShieldCovering(targetPosition) or targetSelector.getIndexOfShieldCovering(ringCenterPos)
				target = targetSelector.getIndexOfShieldCovering(targetPosition)>0 and targetSelector.getIndexOfShieldCovering(targetPosition) or targetSelector.getIndexOfShieldCovering(ringCenterPos)
				if doLightning(targetPosition,Sphere(targetSelector.getTargetPosition(shieldIndex),3.5)) then--shieldIndex was target
					local hp = targetSelector.getTargetHP(shieldIndex)--shieldIndex was target
					local totalKillCost = math.max(minAttackCost,hp*oneDamageCost)
					if totalKillCost<AttackEnergyCost then				
						energy = energy - totalKillCost
						comUnit:sendTo(shieldIndex,"attack",tostring(totalKillCost/oneDamageCost))
					else
						energy = energy - AttackEnergyCost
						comUnit:sendTo(shieldIndex,"attack",tostring(data.getValue("damage")))
					end
					--hitt effect
					local oldPosition = ring[1]:getGlobalPosition()
					local futurePosition = targetPosition
					local hitTime = "1.25"
					comUnit:sendTo(shieldIndex,"addForceFieldEffect",tostring(oldPosition.x)..";"..oldPosition.y..";"..oldPosition.z..";"..futurePosition.x..";"..futurePosition.y..";"..futurePosition.z..";"..hitTime)
				end
			end
		end
		--targetSelector.deselect()
	end
	local function updateEnergy()
		isAnyInRange.timer = isAnyInRange.timer + Core.getDeltaTime()
		if isAnyInRange.timer<0.0 then
			isAnyInRange.timer = isAnyInRange.timer + 0.5
			isAnyInRange.isAnyInRange = targetSelector.isAnyInRange()
		end
		local regenMul = 1.0 + (isAnyInRange.isAnyInRange and 1.0 or 1.5)
		energy = math.min(data.getValue("energyMax"),energy + (energyReg*Core.getDeltaTime()*regenMul))
		billboard:setFloat("energy", energy )
	end
	local function updateSync()
		if billboard:getBool("isNetOwner") then
			syncTimer = syncTimer + Core.getRealDeltaTime()
			if syncTimer>0.5 then
				syncTimer = 0.0
				local newTarget = targetSelector.getTargetIfAvailable()
				if newTarget>0 then
					comUnit:sendNetworkSync("NetTarget", Core.getNetworkNameOf(newTarget))
				end
			end
		end
	end
	function self.update()
		
		if boostActive ~= data.getBoostActive() then
			boostActive = data.getBoostActive()	
			setCurrentInfo()		
			
			model:getMesh("boost"):setVisible(data.getBoostActive())
			
		end


		comUnit:setPos(this:getGlobalPosition())
		updateEnergy()
		local deltaTime = Core.getDeltaTime()
		local energyMax = data.getValue("energyMax")
		local energyPer = (energy/energyMax)+0.05--0.05 is so we never reaches 0
		local rotationThisFrame = math.pi*deltaTime*energyPer
		reloadTimeLeft = reloadTimeLeft - deltaTime
		--handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end

		
		--change update speed
--		local tmpCameraNode = cameraNode
		local state = tonumber(this:getVisibleInCamera()) * math.max(1,tonumber(cameraNode:getGlobalPosition().y < 20) * 2)
		if visibleState ~= state then
			visibleState = state			
			Core.setUpdateHz( (state == 2) and 60.0 or (state == 1 and 30 or 10) )
		end
		
		--update the energy asking
		updateAskForEnergy()
		--if we can attack the enemy
		updateSync()
		if energy>AttackEnergyCost and reloadTimeLeft<0.0 then
			updateTarget()
			if targetSelector.getTargetIfAvailable()>0 then
				local targetAt = targetSelector.getTargetPosition(targetSelector.getTarget())-ring[1]:getGlobalPosition()
				attack()
			end
		end
		--ask fo energy
		lastEnergyRequest = lastEnergyRequest + Core.getDeltaTime()
		if energy<energyMax*0.9 and lastEnergyRequest>(targetSelector.isAnyInRange() and 0.5 or 1.0) then--can ask 1/s or 2/s if there is any enemies in range
			lastEnergyRequest = 0.0
			local rechargeTimeLeft = (energyMax-energy)/energyReg
			if targetSelector.isAnyInRange() then
				comUnit:broadCast(this:getGlobalPosition(),MAXTHEORETICALENERGYTRANSFERRANGE,"requestEnergy",{prio=true,deficit=(energyMax-energy),rechargeTimeLeft=rechargeTimeLeft})
			else
				comUnit:broadCast(this:getGlobalPosition(),MAXTHEORETICALENERGYTRANSFERRANGE,"requestEnergy",{prio=false,deficit=(energyMax-energy),rechargeTimeLeft=rechargeTimeLeft})
			end
			energyOffers.size=0
			energyOffers.frameCounter=2
		elseif energy+1>energyMax and not targetSelector.isAnyInRange() and lastEnergyRequest>energyLightShow then
			--max energy (make a light show, to indicate that there is a link between the towers)
			lastEnergyRequest = 0.0
			energyLightShow = math.randomFloat(3.0,7.0)
			comUnit:broadCast(this:getGlobalPosition(),MAXTHEORETICALENERGYTRANSFERRANGE,"requestEnergy",{prio=false,deficit=0,rechargeTimeLeft=0.0})
			energyOffers.size=0
			energyOffers.frameCounter=2
		end
	
		local bLevel = data.getBoostActive() and 1.0 or 0.0
--		local ampliture = 0.25+(energyPer*0.75) + (bLevel*0.5)
--		sparkCenter:setScale( ampliture )
		local mat = particleSparcleCenter:getLocalMatrix()
		mat:setScale(Vec3(math.clamp( energyPer * 1.2, 0.06, 1.0) + (bLevel*0.5)))
		particleSparcleCenter:setLocalMatrix(mat)
		
		pointLight:setRange(pointLightBaseRange*energyPer + bLevel)
		
		ring[1]:rotate(math.randomVec3(), rotationThisFrame*0.33*math.randomFloat())
		ring[1]:rotate(Vec3(0,1,0), rotationThisFrame*(math.randomFloat()*0.5+0.5))
		ring[1]:rotate(Vec3(0,0,1), rotationThisFrame*(math.randomFloat()*0.5+0.5))
		if data.getTowerLevel() > 2 then
			ring[2]:rotate(Vec3(0,1,0), rotationThisFrame*(math.randomFloat()*0.5+0.5))
			if data.getTowerLevel()==3 then
				ring[3]:rotate(Vec3(0,0,1), rotationThisFrame*(math.randomFloat()*0.5+0.5))
			end
		end
		return true
	end
	--
	local function setNetOwner(param)
		if param=="YES" then
			billboard:setBool("isNetOwner",true)
		else
			billboard:setBool("isNetOwner",false)
		end
		
		data.setGameSessionBillboard( Core.getGameSessionBillboard( "tower_"..Core.getNetworkName() ) )
		data.updateStats()
	end
	--
	local function init()
		----this:setIsStatic(true)
		Core.setUpdateHz(60.0)
		if Core.isInMultiplayer() and this:findNodeByTypeTowardsRoot(NodeId.playerNode) then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		
		if isThisReal then
			restartListener = Listener("RestartWave")
			restartListener:registerEvent("restartWave", restartWave)
		end
		--
		--comTimer = 0.0
		model = Core.getModel("tower_electric_l1.mym")
		local hullModel = Core.getModel("tower_resource_hull.mym")
		this:addChild(model:toSceneNode())
	

		for i=1, #attackSounds do
			local s1 = SoundNode.new(attackSounds[i])
			s1:setSoundPlayLimit(2)
		end
	
		--ComUnit
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)
		comUnit:setPos(this:getGlobalPosition())
		comUnit:broadCast(this:getGlobalPosition(),4.0,"shockwave","")
		billboard:setDouble("rangePerUpgrade",0.75)
		billboard:setString("hullName","hull")
		billboard:setVectorVec3("hull3d",createHullList3d(hullModel:getMesh("hull")))
		billboard:setVectorVec2("hull2d",createHullList2d(hullModel:getMesh("hull")))
		billboard:setModel("tower",model)
		billboard:setString("TargetArea","sphere")
		billboard:setString("Name", "Electric tower")
		billboard:setString("FileName", "Tower/ElectricTower.lua")
		billboard:setVec3("GlobalPosition",this:getGlobalPosition())
		billboard:setBool("isNetOwner",true)
		billboard:setInt("level", 1)
		billboard:setFloat("baseRange", 4)
		--
		billboard:setDouble("DamagePreviousWave",0)
		billboard:setDouble("DamageCurrentWave",0)
	
		--ComUnitCallbacks
		comUnitTable["dmgDealt"] = data.addDamage
		--comUnitTable["dmgLost"] = damageLost --There is no code for this function
		comUnitTable["waveChanged"] = waveChanged
		comUnitTable["upgrade"] = self.handleUpgrade
		comUnitTable["boost"] = self.handleBoost
		comUnitTable["range"] = data.handleSecondaryUpgrade
		comUnitTable["ampedSlow"] = data.handleSecondaryUpgrade
		comUnitTable["energyPool"] = data.handleSecondaryUpgrade
		comUnitTable["energy"] = data.handleSecondaryUpgrade
		if isThisReal then
			comUnitTable["sendMeEnergy"] = sendEnergyTo
			comUnitTable["requestEnergy"] = doWeHaveEnergyOver
			comUnitTable["canOfferEnergy"] = someoneCanOfferEnergy
			comUnitTable["sendEnergyTo"] = recivingEnergy
		end
		comUnitTable["NetOwner"] = setNetOwner
		comUnitTable["NetTarget"] = NetSyncTarget
		comUnitTable["Retarget"] = handleRetarget
		comUnitTable["SetTargetMode"] = self.SetTargetMode
		supportManager.setComUnitTable(comUnitTable)
		supportManager.addCallbacks()
		

		data.setBillboard(billboard)
		data.setCanSyncTower(canSyncTower())
		data.setComUnit(comUnit)
		data.addDisplayStats("damage")
		data.addDisplayStats("RPS")
		data.addDisplayStats("range")
		data.addDisplayStats("slow")
		data.addDisplayStats("energyPool")
		data.addDisplayStats("ERPS")
		
		data.addTowerUpgrade({	cost = {200,400,800},
								name = "upgrade",
								info = "electric tower level",
								iconId = 56,
								level = 1,
								maxLevel = 3,
								stats = {range =	{ 4.0, 4.0, 4.0 },
										damage = 	{ 575*1.30, 1370*1.30, 2700*1.30 },
										minDamage = { 145, 340, 675 },
										RPS = 		{ 3.0/3.0, 4.0/3.0, 5.0/3.0 },
										slow = 		{ 0.0, 0.0, 0.0},
										slowTimer = { 2.0, 2.0, 2.0},
										slowRange = { 0.0, 0.0, 0.0},
										attackCost ={ 575/damagePerEnergy, 1370/damagePerEnergy, 2700/damagePerEnergy },
										energyMax = { (575/damagePerEnergy)*10.0, (1370/damagePerEnergy)*10.0, (2700/damagePerEnergy)*10.0},
										energyReg =	{ (575/damagePerEnergy)*5/36*1.05, (575/damagePerEnergy)*6.5/36*1.05, (575/damagePerEnergy)*8/36*1.05},--0.021/g  [1.25 is just a magic number to increase regen]
										ERPS = 		{ ((575/damagePerEnergy)*5/36*1.05) / (575/damagePerEnergy), ((1370/damagePerEnergy)*6.5/36*1.05) / (1370/damagePerEnergy), ((2700/damagePerEnergy)*8/36*1.05) / (2700/damagePerEnergy)},
										equalizer =	{ 0.0, 0.0, 0.0} }
							})
		
		data.addBoostUpgrade({	cost = 0,
								name = "boost",
								info = "electric tower boost",
								duration = 10,
								cooldown = 3,
								iconId = 57,
								level = 0,
								maxLevel = 1,
								stats = {range = 		{ 1.0, func = data.add },
										damage =		{ 2, func = data.mul },
										RPS = 			{ 1.5, func = data.mul },
										attackCost =	{ 0.0, func = data.set } }
							})
		
		
		
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "ampedSlow",
								info = "electric tower slow",
								infoValues = {"slow","slowRange"},
								iconId = 55,
								level = 0,
								maxLevel = 3,
								callback = self.handleSubUpgrade,
								stats = {slow =		{ 0.15, 0.28, 0.39, func = data.add},
										damage =	{ 0.90, 0.81, 0.73, func = data.mul},
										RPS =		{ 0.75, 0.56, 0.42, func = data.mul},
										slowRange = { 0.75, 1.25, 1.75, func = data.add} }
							})
		
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "energyPool",
								info = "electric tower energy pool",
								infoValues = {"energyMax"},
								iconId = 41,
								level = 0,
								maxLevel = 3,
								callback = self.handleSubUpgrade,
								stats = {energyMax = { 1.30, 1.60, 1.90, func = data.mul }}
							})
							

		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "energy",
								info = "electric tower energy regen",
								infoValues = {"energyReg"},
								iconId = 50,
								level = 0,
								maxLevel = 3,
								callback = self.handleSubUpgrade,
								stats = {energyReg ={ 1.15, 1.30, 1.45, func = data.mul},
										ERPS =		{ 1.15, 1.30, 1.45, func = data.mul},
										equalizer =	{ 1.0, 1.0, 1.0, func = data.add} }
							})
		
		data.addSecondaryUpgrade({	
								cost = {100,200,300},
								name = "range",
								info = "electric tower range",
								infoValues = {"range"},
								iconId = 59,
								level = 0,
								maxLevel = 3,
								callback = self.handleSubUpgrade,
								achievementName = "Range",
								stats = {range = { 0.75, 1.5, 2.25, func = data.add }}
							})

		
		data.updateStats()
		
		supportManager.setUpgrade(data)
		supportManager.addHiddenUpgrades()
		supportManager.addSetCallbackOnChange(data.updateStats)


		if isCircleMap then
			billboard:setString("targetMods","attackPriorityTarget;attackHighDensity;attackWeakestTarget;attackStrongestTarget")
			targetMode = 3
			billboard:setInt("currentTargetMode",3)
		else
			billboard:setString("targetMods","attackPriorityTarget;attackHighDensity;attackWeakestTarget;attackStrongestTarget;attackClosestToExit")
			targetMode = 5
			billboard:setInt("currentTargetMode",5)
		end
	
		self.handleUpgrade("upgrade;1")
	
		--ParticleEffects
		this:addChild(particleSparcleCenter:toSceneNode())
		particleSparcleCenter:setLocalPosition(Vec3(0,2.75,0))
		
		ring[1]:rotate(math.randomVec3(), math.pi*2.0*math.randomFloat())
		this:addChild(electric1:toSceneNode())
		this:addChild(electric2:toSceneNode())
		pointLightAttack:setCutOff(0.05)
		pointLightAttack:setVisible(false)
	
		pointLight:setCutOff(0.05)
		this:addChild(pointLight:toSceneNode())
		this:addChild(pointLightAttack:toSceneNode())
	
	
		--soulManager
		comUnit:sendTo("SoulManager","addSoul",{pos=this:getGlobalPosition(), hpMax=1.0, name="Tower", team=activeTeam})
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setRange(1.0)
		
		setCurrentInfo()
		return true
	end
	init()
	--
	return self
end
function create()
	electricTower = ElectricTower.new()
	update = electricTower.update
	return true
end