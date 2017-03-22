require("Game/particleEffect.lua")
--this = SceneNode()
local comUnit
local comUnitTable = {}
local npcReachedTable = {}
local npcPassedByCounter = 0
local effect
local pLight
local restartListener = Listener("Restart")
function create()
	Core.setUpdateHz(10.0)
	--comSystem
	comUnit = Core.getComUnit()
	comUnit:setCanReceiveTargeted(true)
	comUnit:setCanReceiveBroadcast(true)
	comUnitTable["NpcReachedWayPoint"] = handleNpcReachedWayPoint
	comUnitTable["NpcDeath"] = handleNpcDeath
	comUnitTable["waveChanged"] = handleWaveChanged
	--particle effect
	pLight = PointLight(Vec3(0.0,0.5,0.0),Vec3(0,2,2),2.5)
	pLight:setCutOff(0.1)
	pLight:addFlicker(Vec3(0,0.2,0.2)*0.75,0.05,0.1)
	pLight:addSinCurve(Vec3(0,0.2,0.2),1.0)
	effect = ParticleSystem(ParticleEffect.MidPointColorBlueShort)
	pLight:setRange(0.0)
	this:addChild(effect)
	this:addChild(pLight)
	effect:activate(Vec3(0.0,0.15,0.0))
	effect:setSpawnRate(0.0)
	restartListener:registerEvent("restart", restartMap)
	--
	return true
end
function update()
	comUnit:setPos(this:getGlobalPosition())
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message]~=nil then
			comUnitTable[msg.message](msg.fromIndex,msg.parameter)
		end
	end
	return true
end
function hideEffect()
	effect:setSpawnRate(0.0)
	pLight:pushRangeChange(0.0,0.5)
end
function handleNpcReachedWayPoint(fromIndex,param)
	if npcPassedByCounter==0 then
		effect:setSpawnRate(1.0)
		pLight:pushRangeChange(2.5,0.5)
	end
	npcReachedTable[fromIndex] = param.name
	npcPassedByCounter = npcPassedByCounter + 1
end
function handleNpcDeath(fromIndex,param)
	if npcReachedTable[fromIndex] then
		npcPassedByCounter = npcPassedByCounter - 1
		npcReachedTable[fromIndex] = nil
		if npcPassedByCounter==0 then
			hideEffect()
		end
	end
end
function handleWaveChanged()
	if npcPassedByCounter~=0 then
		npcPassedByCounter = 0
		npcReachedTable = {}
		hideEffect()
	end
end
function restartMap()
	handleWaveChanged()
end