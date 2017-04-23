require("NPC/npcBase.lua")
require("Game/particleEffect.lua")
--this = SceneNode()
local npcBase = NpcBase.new()
local soundReaperSpawn = SoundNode("reaper_spawn")
function create()
	playerNode = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	
	npcBase.init("reaper","npc_reaper.mym",1.4,0.6,1.7,1.5)
	
	--Spawning system
	nextSpawnState = 0
	nextSpawnIn = 3.5
	spawnTimeAdd = 2.2
	spawnTimeAddPerSpawn = 0.5
	spawnTimeMax = 5.5
	SpawnCount = 0
	--particle effect
	reaperCloud = ParticleSystem(ParticleEffect.reaperCloud)
	reaperSpawnEffect = ParticleSystem(ParticleEffect.reaperSpawn)
	playerNode:addChild(reaperCloud)
	this:addChild(reaperSpawnEffect)
	this:addChild(soundReaperSpawn)
	reaperSpawnEffect:setSpawnRate(0.0)
	reaperSpawnEffect:activate(Vec3(0,0,0))
	npcBase.addParticleEffect(reaperSpawnEffect,0.1)
	reaperCloud:activate(Vec3(0,0.75,0))
	npcBase.addParticleEffect(reaperCloud,0.5)
	--
	npcBase.createDeadBody = createDeadBody
	
	return true
end

function update()
	local ret = npcBase.update()
	--npcBase.mover:getDistanceToExit() is far from a good method
	if ret and npcBase.getSoul().getHp()>0.0 and npcBase.getMover():getDistanceToExit()>15.0 then
		nextSpawnIn = nextSpawnIn - Core.getDeltaTime()
		if nextSpawnState==0 and nextSpawnIn<0.5 and nextSpawnIn>0.0 then
			npcBase.getModel():getAnimation():blend("spawn",0.5,PlayMode.stopSameLayer)
			nextSpawnState = 1
		end
		if nextSpawnIn<0.25 or nextSpawnIn>2.0 then
			local handPos = npcBase.getModel():getMesh("npc_reaper"):getGlobalMatrix()*npcBase.getModel():getAnimation():getBonePosition("hand_l3")
			handPos = (this:getGlobalMatrix():inverseM()*handPos)
			reaperSpawnEffect:setEmitterPos(handPos)
			if nextSpawnState==1 then
				nextSpawnState=2
				reaperSpawnEffect:activate(handPos)
				reaperSpawnEffect:setSpawnRate(1.0)
				soundReaperSpawn:play(1,false)
			end
		end
		if nextSpawnIn<0.0 and this:getParent() then
			nextSpawnIn = nextSpawnIn + spawnTimeAdd
			SpawnCount = SpawnCount + 1
			spawnTimeAdd = math.min(spawnTimeMax,spawnTimeAdd+spawnTimeAddPerSpawn)
			--
			npcBase.spawnNPC("NPC/npc_skeletonReaperSpawn.lua", npcBase.getMover():getFuturePosition(1.0))
			--
			reaperSpawnEffect:setSpawnRate(0.0)
			nextSpawnState = 0
		end
		local pos = (this:getGlobalPosition()+npcBase.getMover():getCurrentVelocity()*0.1)
		reaperCloud:setEmitterPos(pos)
	end
	return ret
end
function createDeadBody()
	--replace death animations
	if updateDeath and type(updateDeath)=="function" then
		update = updateDeath
	else
		error("unable to set update function")
	end
	--replace shader, to start the fading
	npcBase.getModel():getMesh("npc_reaper"):setShader(Core.getShader("animatedForward"))
	npcBase.getModel():getMesh("npc_reaper"):setRenderLevel(9)
	deathTimer = 0.25
	deathTimerTotal = deathTimer
	--Achievement
	if SpawnCount==0 then
		npcBase.getComUnit():sendTo("SteamAchievement","Reaper","")
	end
	--
	npcBase.deathCleanup()
	--gold allready fixed
	return true
end
function updateDeath()
	deathTimer = deathTimer - Core.getDeltaTime()
	if deathTimer>0.0 then
		--still time to fade out
		npcBase.getModel():setColor(Vec4(1.0,1.0,1.0,deathTimer/deathTimerTotal))
		npcBase.getModel():getAnimation():update(Core.getDeltaTime())
		npcBase.getMover():update()
	else
		--nothing is left of the reaper
		this:destroy()
		playerNode:removeChild(reaperCloud)
		return false
	end
	return true
end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end