require("Game/particleEffect.lua")
--this = SceneNode()
local restartWaveListener = Listener("RestartWave")
local waveData = {}

function updateDead()
	return false
end

function restartMap()
	this:setLocalPosition(localPos)
	this:setVisible(true)
	if model then
		model:destroyTree()
		model = nil
	end
	
	for i=1, #rigidBodies do
		rigidBodies[i]:destroyTree()
	end
	if destroyNode then
		destroyNode:destroyTree()
	end
	
	particleNode:destroyTree()
	pLight:destroyTree()
	
	update = updateDead
	this:loadLuaScript(this:getCurrentScript():getFileName());
end
function restartWave(param)
	local waveNum = tonumber(param)
	if waveData[waveNum] then
		waveSpiritCount = waveData[waveNum].waveSpiritCount
	end
end
function handleWaveChanged(param)
	local name
	local waveCount
	name,waveCount = string.match(param, "(.*);(.*)")
	--
	waveData[ tostring(tonumber(waveCount)+1) ] = {
		waveSpiritCount = spiritCount
	}
end

function create()
	--comUnit
	comUnit = Core.getComUnit()
	comUnit:setCanReceiveBroadcast(true)
	comUnitTable = {}
	comUnitTable["npcReachedEnd"] = handleNpcReachedEnd
	comUnitTable["waveChanged"] = handleWaveChanged
	rigidBodies = {}
	model = nil
	
	restartListener = Listener("Restart")
	restartListener:registerEvent("restart", restartMap)
	restartWaveListener:registerEvent("restartWave", restartWave)
	
	--crystal
	timer = 0.0
	localPos = this:getLocalPosition()
	pLight = PointLight(Vec3(2.0,0.4,0.0),3.5)
	pLight:setLocalPosition(Vec3(0,0.5,0))
	this:addChild(pLight)
	
	particleNode = SceneNode()
	this:addChild(particleNode)
	
	--spirits
	spiritCount = 20
	spirits = {}
	for i=1, spiritCount do
		spirits[i] = {time1=math.randomFloat()*16.0,time2=math.randomFloat()*16.0,timeMul1=math.randomFloat(0.30,0.50),timeMul2=math.randomFloat(0.075,0.15),mat1=Matrix(),mat2=Matrix(),axis=math.randomVec3(),posVec=math.randomVec3()*0.78,effect=ParticleSystem(ParticleEffect.endCrystalSpirit)}
		local spirit = spirits[i]
		spirit.mat1:createMatrix(math.randomVec3(),math.randomVec3())
		spirit.mat2:createMatrix(math.randomVec3(),math.randomVec3())
		particleNode:addChild(spirit.effect)
		spirit.effect:activate(Vec3())
	end
	--electric
	electric = {size=0}
	explosion = {size=0}

	return true
end
function miniUpdate()
	return true
end
function update()
	if spiritCount>0 then
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		
		for i=1, spiritCount do
			local spirit = spirits[i]
			spirit.time1 = spirit.time1 + Core.getDeltaTime()*spirit.timeMul1
			spirit.time2 = spirit.time2 + Core.getDeltaTime()*spirit.timeMul2
			spirit.mat1:rotate(spirit.axis,spirit.time1)
			spirit.mat2:rotate(spirit.mat1:getUpVec(),spirit.time2)
			spirit.effect:setLocalPosition(spirit.mat2*spirit.posVec+Vec3(0.0,1.05,0.0))
		end
	

		--crystal
		timer = timer + (Core.getDeltaTime()*0.75)
		this:setLocalPosition(Vec3(0,0.25+0.1*math.sin(timer),0)+localPos)
		
		return true
	else
		destroyCrystal()
		update = miniUpdate
		return true
	end
end
function destroyCrystal()
	--particle effect
	destroyNode = SceneNode()
	destroyNode:setLocalPosition(localPos)
	this:getParent():addChild(destroyNode)
 	effect = ParticleSystem(ParticleEffect.endCrystalExplosion)
	destroyNode:addChild(effect)
	effect:activate(Vec3(0,0.75,0))
	--physic
	model=Core.getModel("end_crystal_cracked.mym")
	this:getParent():addChild(model)
	model:setLocalMatrix(this:getLocalMatrix())
	model:setVisible(false)
	
	for i=1, 24 do
		local atVec = model:getMesh("crystal"..i):getLocalPosition()-Vec3(0.0,0.3,0.0)
		atVec = Vec3(atVec.x*6,atVec.y*4,atVec.z*6)
		rigidBodies[#rigidBodies+1] = RigidBody(this:findNodeByType(NodeId.island),model:getMesh("crystal"..i),atVec)
	end
	this:setVisible(false)
end
function handleNpcReachedEnd(param)
	local x,y,z = string.match(param, "(.*);(.*);(.*)")
	local gPos = Vec3(tonumber(x),tonumber(y),tonumber(z))
	if spiritCount>0 then
		doSpiritExplosion(spirits[spiritCount].effect:getLocalPosition())
		--
		local lPos = this:getGlobalMatrix():inverseM()*gPos
		doLightning(Vec3(0.0,0.7-0.2,0.0),lPos-Vec3(0,0.25,0))
		doLightning(Vec3(0.0,0.7,0.0),lPos)
		doLightning(Vec3(0.0,0.7+0.2,0.0),lPos+Vec3(0,0.25,0))
		--
		spirits[spiritCount].effect:setVisible(false)
		spirits[spiritCount] = nil
		spiritCount = spiritCount - 1
	end
end
function doSpiritExplosion(pos)
	for i=1, explosion.size do
		if explosion[i]:isActive()==false then
			explosion[i]:activate(pos)
			return
		end
	end
	explosion.size = explosion.size + 1
	explosion[explosion.size] = ParticleSystem(ParticleEffect.endCrystalSpiritExplosion)
	this:addChild(explosion[explosion.size])
	explosion[explosion.size]:activate(pos)
end
function doLightning(startPos,endPos)
	for i=1, electric.size do
		if electric[i]:getTimer()<0.0 then
			doLightningOnIndex(startPos,endPos,i)
			return
		end
	end
	doLightningOnIndex(startPos,endPos,addLightningEffect())
end
function addLightningEffect()
	electric.size = electric.size + 1
	electric[electric.size] = ParticleEffectElectricFlash("LightningRed_D.tga")
	this:addChild(electric[electric.size])
	return electric.size
end
function doLightningOnIndex(startPos,endPos,index)
	if (endPos-startPos):length()<3.0 then
		electric[index]:setLine(startPos,endPos,0.25)
	end
end