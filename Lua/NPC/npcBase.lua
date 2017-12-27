require("NPC/soul.lua")
require("NPC/deathManager.lua")
require("NPC/npcPath.lua")
require("Game/targetSelector.lua")
--this = SceneNode()
--timer = StopWatch()
NpcBase = {}
function NpcBase.new()
	local self = {}
	local deathManager = DeathManager.new()
	local npcPath = NpcPath.new()
	local soul = TheSoul.new()
	local model
	local gainGoldOnDeath = true
	local value
	local lifeValueCount = "1"--npc is usually only one soul
	local defaultState = 0
	local speed
	local NETSpeedMod = 0.0
	local mover
	local stateOfSoul
	--
	local billboard
	local statsBilboard = Core.getBillboard("stats")
	local launcWave = -1
	--local soulNode
	local centerOffset
	local comUnit
	local comUnitTable = {}
	local deathAnimationTable
	local deathFrameTable
	local deathRigidBodyFunc
	local deathSoftBodyFunc
	local physicDeathInfo
	local npcSpawnCounter = 0
	local waypointReachedList = {}
	local idName
	local useDeathAnimationOrPhysic = true
	local retargetForHighPpriorityTarget = 0.0
	--stats
	local npcAge = 0.0
	local npcIsDestroyed = false
	--debug
	local startPos
	local firstUpdate
	
	local syncConfirmedDeath = false
	local networkSyncPlayerId = 0
	local spawnOwnerPlayerId = 0
	local syncHealthTimer = 0.0
	local restartListener
	local eventListener
	local prevState = -1
	local sentUpdateTimer = 0
	local tmpUpdate = update
	
	print("NpcBase.new()")
	
	function self.destroy()
		if tmpUpdate and type(tmpUpdate)=="function" then
			update = tmpUpdate
		end
	end
	
	local function destroyUpdate()
		this:destroyTree()
		return false
	end
	
--	local function restartMap()
--		local npcData = {node=this,id=comUnit:getIndex(),netname=Core.getNetworkName()}
--		eventListener:pushEvent("removeSoul", npcData )
--		
--		comUnit:sendTo("SoulManager","remove","")
--		if destroyUpdate and type(destroyUpdate)=="function" then
--			update = destroyUpdate
--			print("Changed-restartMap[update = "..tostring(update).."]("..Core.getNetworkName()..")")
--		else
--			error("unable to set new update function")
--		end
--	end
	
	function self.init(name,modelName,particleOffset,size,aimHeight,pspeed)
		--
		if Core.isInMultiplayer() then
			Core.requireScriptNetworkIdToRunUpdate(true)
		end
		--launched on wave
		launcWave = statsBilboard:getInt("wave")
		--set name for the scene
		idName = name
		this:setSceneName("npc_"..name)
		--model and animation
		if modelName then
			model = Core.getModel(modelName)
			this:addChild(model)
			model:getAnimation():play("run",1.0,PlayMode.stopSameLayer)
			model:getAnimation():fastForwardAnimations(math.randomFloat()*model:getAnimation():getLengthOfClip("run"))
		end
		centerOffset = Vec3(0.0,aimHeight,0.0)
		
--		restartListener = Listener("Restart")
--		restartListener:registerEvent("restart", restartMap)
		
		eventListener = Listener("souls")
		
		--stats
		local billboardStats = Core.getBillboard("stats")
		local hpMax = math.max(1.0,billboardStats:getInt("npc_"..name.."_hp"))
		local val1 = billboardStats:getInt("npc_"..name.."_gold")
		value = tostring(val1)
		--
		speed = pspeed	
		--
		
		--mobility
		mover = NodeMover(this, size, speed, Core.getBillboard():getDouble("pathOffset"))--node, npcSize, walkSpeed
		npcPath.findPath(mover, this)
		mover:addCallbackWayPointReached(self.reachedWaypointCallback)
		--ComUnit
		comUnit = Core.getComUnit()
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(true)
		billboard = comUnit:getBillboard()
		billboard:setNodeMover("nodeMover",mover)
		billboard:setBool("isAlive",true)
		--ComUnitCallbacks
		--local soul managment
		soul.defaultStats(hpMax,mover,speed)
		soul.setComSystem(comUnit,comUnitTable)
		soul.setParticleNode(this,Vec3(0.0,particleOffset,0.0),Vec3(0.0,aimHeight*1.4+0.4,0.0))
		--global lifeManager
--			soulNode = this:findNodeByType(NodeId.soulManager)
--			soulNode:addSoul(0,this,mover,Vec3(0.0,aimHeight,0.0),hpMax,name)
		--Owner
		spawnOwnerPlayerId = self.getCurrentIslandPlayerId()
		--
		comUnitTable["disappear"] = self.disappear
		comUnitTable["byPassedWaypoint"] = self.reachedWaypointCallback
		comUnitTable["physicPushIfDead"] = self.physicPushIfDead
		comUnitTable["addState"] = self.setState
		--
		comUnitTable["Net-death"] = self.NETSyncDeath
		comUnitTable["Net-HP"] = self.NETSyncHP
		comUnitTable["Net-DistanceLeft"] = self.NETSyncMover
		--
		comUnitTable["notSubscribed"] = self.setSubscribed
		
		--if wave retart this npc should disapear
		restartListener = Listener("Restart")
		restartListener:registerEvent("restart", self.disappear)
		restartListener = Listener("RestartWave")
		restartListener:registerEvent("restartWave", self.disappear)
			
		local npcData = {node=this,id=comUnit:getIndex(),netname=Core.getNetworkName()}
		eventListener:pushEvent("addSoul", npcData )
		
		comUnit:sendTo("SoulManager","addSoul",{pos=mover:getCurrentPosition(), hpMax=hpMax, name=name, team=0, aimHeight = centerOffset})
		--DEBUG
		startPos = mover:getCurrentPosition()
		return true
	end
	function self.setSubscribed()
		local npcData = {node=this,id=comUnit:getIndex(),netname=Core.getNetworkName()}
		eventListener:pushEvent("addSoul", npcData )
		
		comUnit:sendTo("SoulManager","addSoul",{pos=mover:getCurrentPosition(), hpMax=hpMax, name=name, team=0, aimHeight = centerOffset})
	end
	local function endUpdate()
		print("endScript")
		return false
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
	local function canSyncNPC()
		return (Core.isInMultiplayer()==false or self.getCurrentIslandPlayerId()==0 or networkSyncPlayerId==Core.getPlayerId())
	end
	function self.setGainGoldOnDeath(set)
		gainGoldOnDeath = set
		soul.setMarkOfGoldImmunity(set)
	end
	function self.getSpeed()
		return speed
	end
	function self.getModel()
		return model
	end
	function self.getMover()
		return mover
	end
	function self.getComUnit()
		return comUnit
	end
	function self.getSoul()
		return soul
	end
	function self.getComUnitTable()
		return comUnitTable
	end
	function self.disappear()
		print("self.disappear() - "..LUA_INDEX)
		soul.setHp(-1.0)
		npcIsDestroyed = true
		syncConfirmedDeath = true
		useDeathAnimationOrPhysic = false
		self.setGainGoldOnDeath(false)
		billboard:setBool("isAlive",false)
		--
		this:destroyTree()
		--
		comUnit:clearMessages()
		--Core.addDebugLine(this:getGlobalPosition(),this:getGlobalPosition()+Vec3(0,3,0),3.0,Vec3(1,0,0))
		update = endUpdate
	end
	function self.NETSyncDeath(param)
		soul.setHp(-1.0)
		syncConfirmedDeath = true
		if param=="byEndCrystal" then			
			local pos = this:getGlobalPosition()+centerOffset
			comUnit:sendTo("stats", "npcReachedEnd",lifeValueCount)
			comUnit:broadCast(pos,256.0, "npcReachedEnd","")
		end
	end
	function self.NETSyncHP(param)
		--this message can be recived in wrong order
		if not syncConfirmedDeath then
			if not canSyncNPC() then
				syncHealthTimer = 0.0
			end
			local hp = tonumber(param)
			if networkSyncPlayerId==0 then
				soul.setHp(math.min(hp,soul.getHp()))
			else
				soul.setHp(hp)
			end
		else
			soul.setHp(-1.0)
		end
	end
	function self.NETSyncMover(param)
		local diff = mover:getDistanceToExit()-(param-mover:getCurrentSpeed()*Core.getNetworkClient():getPing()*2.0)
		if math.abs(diff)>mover:getCurrentSpeed()*(0.5) then
			--npc are out of sync with over 0.5s
			NETSpeedMod = 0.25*math.clamp(diff,-2,2)
			mover:setWalkSpeed(speed+NETSpeedMod)
		end
	end
		
	function self.reachedWaypointCallback(position)
		if soul.getHp()>0 then
			position = this:getGlobalPosition()
--			if type(position)=="string" then
--				position = this:getGlobalPosition()
--			end
--			position = position or this:getGlobalPosition()
			--print("Reached waypoint\n")
			waypointReachedList[#waypointReachedList+1] = position
			comUnit:broadCast(position,1.0,"NpcReachedWayPoint",{id=#waypointReachedList,name=idName})
		end
	end
	function self.physicPushIfDead(position)
		physicDeathInfo = {pos=position,time=Core.getGameTime()}
	end
	local function rigidBodyExplosion()
		local meshSplitter = MeshSplitter()
		local subMeshList = meshSplitter:splitMesh(model:getMesh(0))
		--local playerNode = this:getPlayerNode()
		local npcCenterPos = this:getGlobalPosition()+centerOffset
		for i=0, subMeshList:size()-1, 1 do
			local rVec = math.randomVec3()
			rVec = ((npcCenterPos-physicDeathInfo.pos):normalizeV()+rVec):normalizeV()
			rVec = Vec3(rVec.x*2.5,math.abs(rVec.y)*4,rVec.z*2.5)
			local rigidBody = RigidBody(this:findNodeByType(NodeId.island), subMeshList:item(i), rVec)
			deathManager.addRigidBody(rigidBody)
			--deadBodyManger:addRigidBody(rigidBody)
		end
	end
	local function rigidBody()
		if not (physicDeathInfo and physicDeathInfo.time+0.1>Core.getGameTime()) then
			local meshSplitter = MeshSplitter()
			local subMeshList = meshSplitter:splitMesh(model:getMesh(0))
			--local playerNode = this:getPlayerNode()
			for i=0, subMeshList:size()-1, 1 do
				local rigidBody = RigidBody(this:findNodeByType(NodeId.island), subMeshList:item(i), mover:getCurrentVelocity())
				deathManager.addRigidBody(rigidBody)
				--deadBodyManger:addRigidBody(rigidBody)
			end
		else
			rigidBodyExplosion()
		end
	end
	function self.setLifeValue(countStr)
		lifeValueCount = countStr
	end
	--add death animations to be managed on npc death
	function self.addDeathAnimation(tableAnimationInfo,tableFrame)
		deathAnimationTable = tableAnimationInfo
		deathFrameTable = tableFrame
	end
	--add physical rigid body to be managed on npc death
	function self.addDeathRigidBody()
		deathRigidBodyFunc = rigidBody
		--deathRigidBodyFunc = rigidBodyExplosion
	end
	--add physical soft body to be managed on npc death
	function self.addDeathSoftBody(softBodyFunc)
		deathSoftBodyFunc = softBodyFunc
	end
	--add particle effect to be managed on npc death
	function self.addParticleEffect(pEffect,deathTime)
		deathManager.addParticleEffect(pEffect,deathTime)
	end
	--add pointlight to be managed on npc death
	function self.addPointLight(pPointLight,deathTime)
		deathManager.addPointLight(pPointLight,deathTime)
	end
	--returns a number for what kind of ground there is under the localPosition
	local function whatIsHere(localPosition)
		local node, localPos = deathManager.collisionAginstTheWorldLocal(localPosition)
		local globalMatrix = this:getParent():getGlobalMatrix()
		local globalPos = globalMatrix * localPosition
		if node then
			if node:getNodeType() == NodeId.ropeBridge then
				return 1--bridge
			else
				return 0--island
			end
		end
		return 2--space
	end
	--generate a string with the path this npc will take
	local function getPathPointInStringFormat()
		local pathPointTable = mover:getPathPoints()
		
		local outString = ""
		for i=1, #pathPointTable do
			outString = outString .. tostring(pathPointTable[i].localIslandPos.x) .. "," .. tostring(pathPointTable[i].localIslandPos.y) .. "," .. tostring(pathPointTable[i].localIslandPos.z)
			outString = outString .. "," .. tostring(pathPointTable[i].islandId) .. ";"
		end
		
		return outString
	end
	--spawns a npc on globalPosition, and sends the path list that the npc should take
	function self.spawnNPC(name,globalPosition)
		if canSyncNPC() then
			npcSpawnCounter = npcSpawnCounter + 1
			local newNpcNetworkName = Core.getNetworkName().."s"..npcSpawnCounter
			local target = tonumber(Core.getIndexOfNetworkName(newNpcNetworkName))
			if target==0 then			
				comUnit:sendTo("stats","addSpawn","")
				--
				local npc = SceneNode()
				this:getParent():addChild( npc )
				local lPos = this:getParent():getGlobalMatrix():inverseM()*globalPosition
				npc:setLocalPosition( lPos )
				local npcScript = npc:loadLuaScript(name)
				npcScript:setScriptNetworkId(newNpcNetworkName)
				comUnit:sendTo("stats", "npcSpawnedWave", tostring(npcScript:getIndex())..";"..tostring(statsBilboard:getInt("wave")))
				
				--
				--Force update
				--
				npc:update()
				--path points
				local pathInStr = getPathPointInStringFormat()
				comUnit:sendTo(npcScript:getIndex(), "setPathPoints", pathInStr)
				--add new npc to waypoints, that have been passed
				if Core.isInMultiplayer() then
					local tab = Core.getNetworkClient():getConnected()
					local spawnTable = {netName=newNpcNetworkName, scriptName = name, pos=lPos, islandId=this:getParent():getIslandId(), pathList=pathInStr, wayPoints=waypointReachedList}
					for index=1, Core.getNetworkClient():getConnectedPlayerCount() do
						comUnit:sendNetworkSyncSafeTo("Event"..tostring(tab[index].clientId),"NetSpawnNpc",tabToStrMinimal(spawnTable))
					end
				end
				--
				for index,position in pairs(waypointReachedList) do
					comUnit:sendTo(npcScript:getIndex(), "byPassedWaypoint", position )
				end
				return npcScript:getIndex()
			end
		end
	end
	--updated the death animations
	local function deathAnimation()
		local frame = model:getAnimation():getFrameTimeFromClip("run")
		local deathAnimationIndex = deathManager.closestTo(deathFrameTable.startFrame,deathFrameTable.endFrame,frame,deathFrameTable.framePositions)
		local localAtVec = (this:getParent():getGlobalMatrix():inverseM() * Vec4(mover:getCurrentVelocity():normalizeV(),0.0)):toVec3()
		local posT1 = this:getGlobalPosition()+(mover:getCurrentVelocity():normalizeV()*deathAnimationTable[deathAnimationIndex].length*0.6)
		local posT2 = this:getGlobalPosition()+(mover:getCurrentVelocity():normalizeV()*deathAnimationTable[deathAnimationIndex].length*1.0)
		local test1 = whatIsHere(posT1)

		if test1==0 and whatIsHere(posT2)>0 then
			--we can sheat, and make the animation distance shorter
			local safeLength=0.5
			for i=0.7, 1.0, 0.1 do
				if whatIsHere(this:getLocalPosition()+(localAtVec*deathAnimationTable[deathAnimationIndex].length*i))>0 then
					safeLength = i-0.1
				else
					break
				end
			end
			deathManager.setAnimation(model,deathAnimationTable[deathAnimationIndex].duration,safeLength,this:getLocalPosition(),localAtVec,speed)
			model:getAnimation():blend("death"..deathAnimationIndex,deathAnimationTable[deathAnimationIndex].blendTime,PlayMode.stopSameLayer)
		else
			--it is totaly safe to do the animation
			deathManager.setAnimation(model,deathAnimationTable[deathAnimationIndex].duration,deathAnimationTable[deathAnimationIndex].length,this:getLocalPosition(),localAtVec,speed)
			model:getAnimation():blend("death"..deathAnimationIndex,deathAnimationTable[deathAnimationIndex].blendTime,PlayMode.stopSameLayer)
		end
		return true
	end
	--give gold and interest when dead
	function goldOnDeath(mul)
		if gainGoldOnDeath then
			if Core.isInMultiplayer() then
				--there is always a 50% increased spawn rate in multiplayer
				--0.66 = 1 / (1+0.5)
				--with some lying for interest rate
				comUnit:sendTo("stats","goldInterest",0.67)--allways full interest
				comUnit:sendTo("stats","addGold", (value*mul*0.67)+soul.getGoldGainAdd() )
				comUnit:sendTo("stats","addBillboardInt", "totalGoldSupportEarned;"..soul.getGoldGainAdd())
			else
				comUnit:sendTo("stats","goldInterest",1.0)--allways full interest
				--gold from the killing
				local killValue = (value*mul)+soul.getGoldGainAdd()
				comUnit:sendTo("stats","addGold", killValue )
				comUnit:sendTo("stats","addBillboardDouble","goldGainedFromKills;"..tostring(killValue))
			end
		end
				comUnit:sendTo("stats","addKill","")
	end
	--removed from soulmanager, so we can't be targeted
	function self.deathCleanup()
		soul.manageDeath()
		--soulNode:removeThis()
		local npcData = {node=this,id=comUnit:getIndex(),netname=Core.getNetworkName()}
		eventListener:pushEvent("removeSoul", npcData )
		
		comUnit:sendTo("SoulManager","remove","")
	end
	--start the death animations/physic/effect
	function self.createDeadBody()
		if Settings.DeathAnimation.getSettings()~="Disabled" and useDeathAnimationOrPhysic then
			--death animations is enabled
			local otherOptions = false
			if Settings.DeathAnimation.getSettings()=="Enabled" and Settings.corpseTimer.getInt()>0 and (deathSoftBodyFunc or deathRigidBodyFunc) then
				--physic can be used
				otherOptions=true
			end
			local useAnimation = deathAnimationTable and #deathAnimationTable>0
			--if we have animations and other options the best course of action may still be physic
			if useAnimation and otherOptions then
				--we can do animation and physic, if there is a bridge then we can use physic
				local line = Line3D(this:getGlobalPosition()+Vec3(0,2,0), this:getGlobalPosition()-Vec3(0,2,0))
				local onABridge = this:getPlayerNode():collisionTree(line, {NodeId.ropeBridge}) 	
				--if on a bridge
				if onABridge then
					--66% chanse that we will use animation anyway one the bridge (performance'ish)
					if math.randomFloat()>0.66 then
						useAnimation = false
					end
				end
				--if unit can explode
				if useAnimation and deathRigidBodyFunc and physicDeathInfo and physicDeathInfo.time+0.1>Core.getGameTime() then
					useAnimation = false
				end
			end
			--
			-- DEBUG
			--useAnimation = false
			--
			--
			--use animation, can be aborted
			if useAnimation then
				deathAnimation()
			else
				if deathSoftBodyFunc then
					deathManager.addSoftBody(deathSoftBodyFunc())
					this:removeChild(model)
				elseif deathRigidBodyFunc then
					deathRigidBodyFunc()
					this:removeChild(model)
				end
			end
		end
		self.deathCleanup()
		if deathManager.hasWork() then
			--success, we have a death animation
			if deathManager.update and type(deathManager.update)=="function" then
				update = deathManager.update -- npcBase.update is just our local functions
				return true
			else
				error("unable to set new update function")
			end
		else
			--destroy this SceneNode if we can
			if deathManager.enableSelfDestruct then
				this:destroyTree()
			else
				this:removeChild(model)
			end
			return false--destroy this script
		end
		error("This code should never be reached!!!")
	end
	local function toBits(num)
		if num then
			local t={}
			local rest
			while num>0 do
				rest=math.fmod(num,2)
				t[#t+1]=rest
				num=(num-rest)/2
			end
			for i=#t+1, 16 do
				t[i]=0
			end
			return t
		end
		return {0,0,0,0,0,0,0,0}
	end
	function self.setDefaultState(state)
		defaultState = state
	end
	function self.setState(param)
		local lstate,bool = string.match(param, "(.*);(.*)")
		lstate = tonumber(lstate)
		bool = tonumber(bool)
		local binaryNumPos = {[1]=1,[2]=2,[4]=3,[8]=4,[16]=5,[32]=6,[64]=7,[128]=8,[256]=9,[512]=10,[1024]=11,[2048]=12}
		if toBits(defaultState)[binaryNumPos[lstate]]~=bool then
			defaultState = defaultState + (bool==0 and -lstate or lstate)
			if bool==1 and lstate==state.highPriority then
				comUnit:broadCast(this:getGlobalPosition(),7.5,"Retarget","")
				retargetForHighPpriorityTarget = Core.getGameTime()
			end
			--
		end
	end
	function self.update()
--		if syncConfirmedDeath==true then
--			local d1 = self
--			local d2 = syncConfirmedDeath
--			error("this should never happen!!!")
--		end

		while comUnit:hasMessage() and syncConfirmedDeath==false do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		--this is true when this is destroyed
		if npcIsDestroyed then
			return false
		end
		--update the movment
		--if we need to sync up the npc position
		if Core.isInMultiplayer() and math.abs(NETSpeedMod)>0.05 then
			NETSpeedMod = NETSpeedMod - (NETSpeedMod*Core.getDeltaTime())
			mover:setWalkSpeed(speed+NETSpeedMod)
		end
		npcAge = npcAge + Core.getDeltaTime()
		mover:update()
		--local p1 = this:getGlobalPosition()+mover:getCurrentVelocity():normalizeV()
		--Core.addDebugLine(Line3D(p1,p1+Vec3(0,1,0)),0.0,Vec3(1,1,0))
		if mover:isAtFinalDestination() and canSyncNPC() then
			--has reached the exit
			soul.setHp(-1.0)
			
			local pos = this:getGlobalPosition()+centerOffset
			comUnit:sendTo("stats", "npcReachedEnd",lifeValueCount)	--for menu stats
			comUnit:broadCast(pos,256.0, "npcReachedEnd","")		--for end crystals
			--fadeOut(body,deltaTime,"normal")
		else
			comUnit:sendTo("SoulManager","update",soul.getHp())
			billboard:setDouble("hp",soul.getHp())
		end
		
		--if is high priority target make towers close by attack you
		if lstate==state.highPriority and Core.getGameTime()-retargetForHighPpriorityTarget>2.5 then
			comUnit:broadCast(this:getGlobalPosition(),7.5,"Retarget","")
			retargetForHighPpriorityTarget = Core.getGameTime()
		end
		
		--update npc path
		npcPath.update()
		
		if launcWave ~= statsBilboard:getInt("wave") then
			syncConfirmedDeath = true
			useDeathAnimationOrPhysic = false
			self.setGainGoldOnDeath(false)
		end

		if (syncConfirmedDeath or soul.getHp()<=0) then--and soul.canDie() then
			if not soul.canDie() then
				error("THIS SHOULD NEVER EVER OCCURE ANYMORE!!!")
			end
			--npc is dead
			billboard:setBool("isAlive",false)
			if canSyncNPC() or syncConfirmedDeath then
				local binaryNumPos = {[1]=1,[2]=2,[4]=3,[8]=4,[16]=5,[32]=6,[64]=7,[128]=8,[256]=9,[512]=10,[1024]=11,[2048]=12}
				self.getCurrentIslandPlayerId()
				comUnit:sendTo("SteamStats","LongestLivingNPC",npcAge)
				if not mover:isAtFinalDestination() then
					--NPC killed in action
					--gold earned if npc did not reach end
					if not Core.isInMultiplayer() then
						--single player
						goldOnDeath(1.0)
						soul.fixGoldEarned()
					else
						--multiplayer
						goldOnDeath(1.0/Core.getNetworkClient():getConnectedPlayerCount())
						soul.fixGoldEarned()
					end
					if canSyncNPC() then
						comUnit:sendNetworkSyncSafe("Net-death","byTower")
						syncConfirmedDeath = true
						--Stats
						comUnit:sendTo("SteamStats","Kills",1)
						--Achievements
						local targetSelector = TargetSelector.new(1)
						if targetSelector.getIndexOfShieldCovering(this:getGlobalPosition())>0 then
							comUnit:sendTo("SteamAchievement","ForcefieldKill","")
						end
						if toBits(stateOfSoul)[binaryNumPos[state.markOfDeath]]==1 and toBits(stateOfSoul)[binaryNumPos[state.electrecuted]]==1 and toBits(stateOfSoul)[binaryNumPos[state.burning]]==1 then
							comUnit:sendTo("SteamAchievement","Unity","")
						end
						if mover:getDistanceToExit()<5 then
							comUnit:sendTo("stats","killedLessThan5m","")
						end
						if idName=="stoneSpirit" then
							comUnit:sendTo("SteamAchievement","StoneSpirit","")
						elseif idName=="hydra" then
							comUnit:sendTo("SteamAchievement","Hydra","")
						end
					end
				else
					--NPC reached the crystal
					if canSyncNPC() then
						comUnit:sendNetworkSyncSafe("Net-death","byEndCrystal")
						syncConfirmedDeath = true
						--Achievement
						if toBits(stateOfSoul)[binaryNumPos[state.ignore]]==1 then
							comUnit:sendTo("SteamAchievement","Ignore","")
						end
					end
				end
				--
				--generate the dead body
				--
				comUnit:broadCast(this:getGlobalPosition(),512.0,"NpcDeath","")
				if self.createDeadBody()then
					return true
				else
					if endUpdate and type(endUpdate)=="function" then
						update = endUpdate
						print("Changed-endUpdate[update = "..tostring(update).."]("..Core.getNetworkName()..")")
					else
						error("unable to set new update for dead body")
					end
					print("endScript["..tostring(index).."]("..Core.getNetworkName()..") return false")
					return false
				end
			else
				if not canSyncNPC() and syncHealthTimer>10.0 then
					if Core.isInMultiplayer() then
						--something is wrong, kill the npc (BAD SOLUTION)
						local d1 = self
						local d2 = Core.getNetworkName()
						local d3 = Core.getTime()
						--error("This should not actually happen!!!")
						comUnit:sendNetworkSyncSafe("Net-death","byTower")
						syncConfirmedDeath = true--(this is bad, will trigger saftey test)
					end
				else
					soul.setHp(1.0)--still alive bad sync only keep alive, should get a hp update soon
				end
			end
		else
			--npcAlive
			if Core.isInMultiplayer() then
				syncHealthTimer = syncHealthTimer + Core.getDeltaTime()
				if syncHealthTimer>0.33 and canSyncNPC() then
					syncHealthTimer = syncHealthTimer - 0.33
					comUnit:sendNetworkSync("Net-HP",tostring(soul.getHp()))
					comUnit:sendNetworkSync("Net-DistanceLeft",tostring(mover:getDistanceToExit()))
				end
			end
		end
		stateOfSoul = soul.update()+defaultState
		comUnit:sendTo("SoulManager","setState",stateOfSoul)
		billboard:setInt("stateOfSoul",stateOfSoul)
			
		comUnit:setPos(this:getGlobalPosition()+(centerOffset*0.75))--update the communication position (radius based attacks)
		
		--update the animation
		if model then
			model:getAnimation():update(Core.getDeltaTime())
		end
		return true
	end
	
	return self
end