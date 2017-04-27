--this = SceneNode()
local npcBase
function createHydra(level,scale,pnpcBase)
	npcBase = pnpcBase
	npcBase.init("hydra","npc_hydra"..level..".mym",0.5*scale,0.6,0.8,1.45)
	npcBase.getSoul().enableBlood("BloodSplatterSphere",2.5*scale,Vec3(0,0.3*scale,-0.4*scale))
	local mat = npcBase.getModel():getLocalMatrix()
	mat:scale(Vec3(scale))
	npcBase.getModel():setLocalMatrix(mat)
	if level>1 then
		npcBase.setGainGoldOnDeath(false)
	end
	--
	npcBase.getComUnitTable()["setPathPoints"] = setPathPoints
end
--push functionality is to splitt up the group as fast as possible, otherwise AOE will oblitirate the hydras instantly
function createPushFunctions()
	npcBase.getComUnitTable()["npcPush"] = handlePushed
	pushTimer = 0.1
	pushTable = {}
	pushSpeedAdd = 0.0
end
function spawnHydras(level)
	local atVec = math.randomVec3()
	atVec = Vec3(atVec.x,0.0,atVec.z):normalizeV()*math.randomFloat(0.1,0.2)
	local index = npcBase.spawnNPC("NPC/npc_hydra"..level..".lua", this:getGlobalPosition()+atVec)
	sendAllStatusEffectToChild(index)
	if npcBase.getMover():getDistanceToExit()>40 then
		--it is long time untill the end, push the spawned npc to the front to make to spawns as splitted as possible
		index = npcBase.spawnNPC("NPC/npc_hydra"..level..".lua", npcBase.getMover():getFuturePosition(0.75)-atVec)
		sendAllStatusEffectToChild(index)
	else
		--we are close to the end, push this npc backward. Because don't be evil
		local dist = npcBase.getMover():getDistanceToExit()
		local backDist = dist<20.0 and 0.5 or 0.5-((dist-20.0)/20.0*0.5)
		index = npcBase.spawnNPC("NPC/npc_hydra"..level..".lua", this:getGlobalPosition()-atVec-(npcBase.getMover():getCurrentVelocity()*backDist))
		sendAllStatusEffectToChild(index)
	end
end
function updatePush()
	pushTimer = pushTimer - Core.getDeltaTime()
	if pushTimer<0.0 then
		pushTimer = 1.0
		local param = tostring(this:getGlobalPosition().x)..";"..this:getGlobalPosition().y..";"..this:getGlobalPosition().z
		npcBase.getComUnit():broadCast(this:getGlobalPosition(),1.25,"npcPush",param)
		--forcefully update speed as it can be unsynced
		updatePushSpeed()
	end
	return npcBase.update()
end
function handlePushed(param,fromIndex)
	local x,y,z = string.match(param, "(.*);(.*);(.*)")
	local pos = Vec3(tonumber(x),tonumber(y),tonumber(z))
	local fromDirVec = (this:getGlobalPosition()-pos):normalizeV()
	if fromDirVec:length()>0.1 then--incase we got push message from our own position
		local angle = fromDirVec:angle(npcBase.getMover():getCurrentVelocity())
		--push npc back or forth
		if angle<math.pi*0.5 then
			pushTable[fromIndex] = {time=Core.getGameTime(),speedAdd=0.2}
		else
			pushTable[fromIndex] = {time=Core.getGameTime(),speedAdd=-0.2}
		end
	end
	updatePushSpeed()
end
function updatePushSpeed()
	pushSpeedAdd = 0.0
	for key, value in pairs(pushTable) do
		if Core.getGameTime()-value.time<1.0 then
			pushSpeedAdd = pushSpeedAdd + value.speedAdd
		else
			pushTable[key] = nil
		end
	end
	npcBase.getMover():setWalkSpeed(npcBase.getSpeed()+pushSpeedAdd)
end
--this will decrease the clutter of dead bodies, and because making 2 death animations for 4 extra models will cost to much time
function setUpAlphaDeath()
	--replace death animations
	if updateDeathAlphaDeath and type(updateDeathAlphaDeath)=="function" then
		update = updateDeathAlphaDeath
	else
		error("unable to set new update function")
	end
	--replace shader, to start the fading
	npcBase.getModel():getMesh(0):setShader(Core.getShader("animatedForward"))
	npcBase.getModel():getMesh(0):setRenderLevel(9)
	--
	deathTimer = 0.5
end
--update the fade, and then delete the npc
function updateDeathAlphaDeath()
	deathTimer = deathTimer - Core.getDeltaTime()
	if deathTimer>0.0 then
		--still time to fade out
		npcBase.getModel():setColor(Vec4(1.0,1.0,1.0,deathTimer/0.5))
		npcBase.getModel():getAnimation():update(Core.getDeltaTime())
		npcBase.getMover():update()
	else
		--remove everything
		this:destroy()
		return false
	end
	return true
end
--get parrent path to exit
function split(str,sep)
	local array = {}
	local reg = string.format("([^%s]+)",sep)
	for mem in string.gmatch(str,reg) do
		array[#array + 1] = mem
	end	
	return array
end
function setPathPoints(dataString)
	local pathPoints = {}
	--Split into pathpoints
	local points = split(dataString,";")
	for i=1, #points do
		--split data into data points
		local data = split(points[i],",")
		pathPoints[i] = {}
		pathPoints[i].localIslandPos = Vec3(tonumber(data[1]),tonumber(data[2]),tonumber(data[3]))
		pathPoints[i].islandId = tonumber(data[4])
	end
	npcBase.getMover():setPathPoints(pathPoints)
end
function sendAllStatusEffectToChild(toIndex)
	--fireDPS
	npcBase.getSoul().transferAllActiveEffectsTo(toIndex)
end
function reachedWaypointCallback(param)
	if npcBase.getSoul().getHp()>0.0 then
		npcBase.reachedWaypointCallback()
	end
end