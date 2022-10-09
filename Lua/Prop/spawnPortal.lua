require("Prop/spawnPortalMesh.lua")

--State,
--0 = closed
--1 = opening
--2 = fully opened
local state = 0
local stateChangeTime = 0
	
--this = Model()
function create()
	this:setColor(Vec3(0.8,0.0,0.78))

	local portalSize = Vec3(1, 1.5, 1)

	--sound
	local soundPortal = SoundNode.new("spawnPortal")
	soundPortal:setSoundRolloff(2)
	this:addChild(soundPortal:toSceneNode())
	soundPortal:play(0.05,true)
	
	local meshList = this:findAllNodeByTypeTowardsLeaf(NodeId.mesh)	
	for i=1, #meshList do
		meshList[i]:destroy()
	end
	
	
	spawnportalMesh = SpawnPortalMesh.new(portalSize)
	--
	local pLight = PointLight.new(Vec3(0.0,1.25,0.0),Vec3(1.75,0.4,1.75),8.0)
	pLight:setCutOff(0.25)
	pLight:addFlicker(Vec3(0.075,0.075,0.0),0.1,0.2)
	pLight:addSinCurve(Vec3(0.4,0.4,0.0),2.0)
	this:addChild(pLight:toSceneNode())
	--
	
	restartListener = Listener("Restart")
	restartListener:registerEvent("restart", restartMap)
	
	return true
end


function restartMap()
	state = 0	
	stateChangeTime = 0
end


function isPlayerReady()
	local buildingBillboard = Core.getBillboard("buildings")
	return buildingBillboard:getBool("Ready")
end

function getPortalSize()
	if state == 0 then
		return 0.2
	elseif state == 1 then
		return 0.2 + 0.8 * math.sin(stateChangeTime * math.pi * 0.5) 
	else
		return 1.0
	end
end

function updateState()
	if state == 0 and isPlayerReady() then
		state = 1
	elseif state == 1 then
		stateChangeTime = stateChangeTime + Core.getDeltaTime()
		if stateChangeTime > 1.0 then
			stateChangeTime = 1.0
			state = 2
		end
	end
end

function update()
	
	updateState()
	
	spawnportalMesh.update(getPortalSize())

	return true
end