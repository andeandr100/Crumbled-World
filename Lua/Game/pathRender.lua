require("Game/spirits.lua")
require("Menu/settings.lua")
--this = SceneNode()

local ourRootNode
function destroy()
	ourRootNode:destroy()
end

function init()

	if bilboard:exist("spawnPortals") then
		local buildNode = this:getPlayerNode():findNodeByTypeTowardsLeafe(NodeId.buildNode)
		local navMesh = this:getPlayerNode():findNodeByTypeTowardsLeafe(NodeId.navMesh)
		
		if not buildNode or not navMesh then
			return false
		end
				
		local protectedPaths = buildNode:getProtectedPaths()
		print("protectedPaths: "..tostring(protectedPaths))
		for i=1, #protectedPaths do
			local line = protectedPaths[i]
			local path = navMesh:getPath(0.8, line[1], line[2])
			paths[#paths + 1] = path
--			for n=2, #path do
--				Core.addDebugLine(Line3D(path[n-1].island:getGlobalMatrix() * path[n-1].position + Vec3(0,1,0), path[n].island:getGlobalMatrix() * path[n].position + Vec3(0,1,0)), 1000, Vec3(1))
--			end
		end
		ourRootNode = SceneNode()
		this:findNodeByTypeTowardsRoot(NodeId.playerNode):addChild(ourRootNode)
--		createMesh()
		return true
	end
	return false
end

--function createMesh()
--	nodeMesh = NodeMesh(RenderMode.points)
--	nodeMesh:setVertexType(VertexType.vec3, VertexType.vec3)
--	nodeMesh:bindVertexToShaderName("pos1", "pos2" )
--	nodeMesh:setShader(Core.getShader("pathRender"))
--	nodeMesh:setShadowShader(Core.getShader("pathRender"))
--	nodeMesh:setBoundingSphere(Sphere(Vec3(), 75.0))
--	nodeMesh:setColor(Vec4(1))
--	
--	updateMesh()
--	
--	
--	this:addChild(nodeMesh)
--end

function create()
	bilboard = Core.getGlobalBillboard("Paths")
	bilboard:setBool("started", false)
	mainUpdate = update
	update = tmpUpdate
	
	sleepTime = 0.1 + Core.getRealDeltaTime()
	offset = 0
	
	numSpawns = 1
	canSpawn = true
	spawnInterval = 4
	spawnTime = 0
	spawnIndex = 1
	spirits = {}
	
	restartListener = Listener("Restart")
	restartListener:registerEvent("restart", restartMap)
	
	paths = {}
	return true
end

function restartMap()
	canSpawn = true
	bilboard:setBool("started", false)
end

function tmpUpdate()
	sleepTime = sleepTime - Core.getRealDeltaTime()
	if sleepTime < 0 and init() then
		update = mainUpdate
	end
	return true
end

--function updateMesh()
--	local lineLength = 0.9
--	local disttBettwenLines = 2.0
--		
--	nodeMesh:clearMesh()
--	local index = 0
--	for i=1, #paths do
--		local path = paths[i]
--		
--		
--		--curentPos = Vec3()
--		local n=1
--		local curentPos = (path[n].island:getGlobalMatrix() * path[n].position)
--		local distanceToNextPoint = offset
--		local point = nil
--		
--		if offset > disttBettwenLines then
--			point = curentPos
--			distanceToNextPoint = distanceToNextPoint - disttBettwenLines
--		end
--		
--		while n <= #path do
--			if distanceToNextPoint <= 0 then
--				--time to add a line
--				if point == nil then
--					point = curentPos
--					--find the next pos
--					distanceToNextPoint = lineLength
--				else
--					--add line
--					nodeMesh:addVertex(point + Vec3(0,0.25,0), curentPos + Vec3(0,0.25,0))
--					nodeMesh:addIndex(index)
--					index = index + 1
--					point = nil
--					
--					--find the next pos
--					distanceToNextPoint = disttBettwenLines
--				end
--			else
--				--move along line
--				local position = path[n].island:getGlobalMatrix() * path[n].position
--				local dist = (position - curentPos):length()
--				if dist > distanceToNextPoint then
--					curentPos = curentPos + (position - curentPos):normalizeV() * distanceToNextPoint
--					distanceToNextPoint = 0
--				else
--					curentPos = position
--					distanceToNextPoint = distanceToNextPoint - dist
--					n = n + 1
--				end
--			end
--		end
--		
--		if point and (curentPos-point):length() > 0.05 then
--			--add line
--			nodeMesh:addVertex(point + Vec3(0,0.25,0), curentPos + Vec3(0,0.25,0))
--			nodeMesh:addIndex(index)
--			index = index + 1
--		end
--	end
--	nodeMesh:compile()
--	
--	offset = (offset + Core.getDeltaTime()) % (disttBettwenLines+lineLength)
--end

function spawnSpirit()
	local bilboard = Core.getBillboard("Paths")
	if bilboard then

		local spawns = bilboard:getTable("spawns")
		local points = bilboard:getTable("points")
		local paths = bilboard:getTable("paths")
		local ends = bilboard:getTable("ends")
		local spawnPortals = bilboard:getTable("spawnPortals")
		
		numSpawns = #spawns
		
		
		--find the spawn
		spawnIndex = spawnIndex + 1
		if spawnIndex > #spawns then
			spawnIndex = 1
		end
		
		if spawnIndex > #spawns then
			return
		end
		
		
		
		--get spawn
		local spawn = spawns[spawnIndex]
		
		--create node
		local node = SceneNode()
		spawn.island:addChild(node)
		node:setLocalPosition(spawn.position)
		node:setVisible(true)
		
		local particle = node:addChild( ParticleSystem(SpiritsParticleEffect["endCrystalSpirit"..math.clamp(spawnIndex,1,3)]) )
		particle:activate(Vec3(0,0.5,0))
		particle:setVisible(true)
		--
		local particleTale = ourRootNode:addChild( ParticleSystem(SpiritsParticleEffect["endCrystalSpiritTale"..math.clamp(spawnIndex,1,3)]) )
		particleTale:activate( particle:getGlobalPosition() )
		particleTale:setVisible(true)
		--
		local pLight = particle:addChild( PointLight(Vec3(0.5,0.5,0.0),4.0) )
		pLight:setLocalPosition(Vec3(0,0.5,0))
		--
		
		--add Spirit
		local nodeMover = NodeMover(node, 0.5, 1.5, 0 )--sizes used are 0.5 and 0.8
		local spirit = {nodeMover=nodeMover, node=node, particle=particle, particleTale=particleTale, pLight=pLight,time=math.randomFloat()*math.pi*2.0}
		spirit.lifeTime = -1
		spirits[#spirits + 1] = spirit
		
		
		
		
		local groupId = 0
		local numGroup = #spawn.groups
		if numGroup > 0 then
			groupId = spawn.groups[math.randomInt(1, numGroup)]
		else
			print("no path found set random end as end point\n")
			local endPoint = ends[math.randomInt(1, #ends)]
			nodeMover:addMoveTo(endPoint.island, endPoint.position)
			spirit.finalIsland = endPoint.island
			spirit.finalPosition = endPoint.position
			return
		end
		
		
		local id = spawn.id
		local run = true
		local usedPoints = {}
		while run and not usedPoints[id] do
			local posibleTargetLocation = paths[groupId][id]
			if posibleTargetLocation and #posibleTargetLocation > 0 then
				local nextId = posibleTargetLocation[math.randomInt(1, #posibleTargetLocation)]
				if points[nextId].followNode then
					local island = points[nextId].followNode:findNodeByTypeTowardsRoot(NodeId.island)
					--nodeMover:followNode(points[nextId].followNode)
					--spirit.finalNode = points[nextId].followNode
					spirit.finalIsland = island
					spirit.finalPosition = points[nextId].followNode:getLocalPosition()
					nodeMover:addMoveTo(island, points[nextId].followNode:getLocalPosition())
				else
					nodeMover:addMoveTo(points[nextId].island, points[nextId].position)
					spirit.finalIsland = points[nextId].island
					spirit.finalPosition = points[nextId].position
				end
				usedPoints[id] = true
				
				id = nextId
				print("Next id: "..id)
			else
				run = false
			end
		end
		
		
		
	end
end

function update()
	
--	local buildingBillboard = Core.getBillboard("buildings")
--	if buildingBillboard:getBool("Ready") then
--		canSpawn = false
----		nodeMesh:setVisible(false)
----		nodeMesh:destroy()
----		return false
--	end
	
	spawnTime = spawnTime - Core.getDeltaTime()
	if spawnTime < 0 and canSpawn then
		spawnTime = spawnInterval / math.max( 1, numSpawns )
		spawnSpirit()
	end
	
	if canSpawn == true and bilboard:getBool("started") then
		canSpawn = false
		
		for i=1, #spirits do
			spirits[i].lifeTime = 1
			
			if spirits[i].killSpirit==nil then
				spirits[i].particleTale:setSpawnRate(0.0)
				spirits[i].particle:setSpawnRate(0.0)
				spirits[i].pLight:pushRangeChange(0.1,1.0)
				spirits[i].killSpirit = true
			end
		end
	end
	
	local i=1
	while i <= #spirits do
		spirits[i].time = spirits[i].time + Core.getDeltaTime()
		spirits[i].nodeMover:update()
		spirits[i].particle:setLocalPosition(Vec3(math.sin(spirits[i].time*0.8), math.sin(spirits[i].time)*2+1.0, math.cos(spirits[i].time*0.9))*0.2)
		local gPos = spirits[i].particle:getGlobalPosition()+Vec3(0,0.5,0)
		spirits[i].particleTale:setEmitterPos( gPos )
		spirits[i].particleTale:setBoundingSphere( Sphere(gPos, 1.0) )
		
		if spirits[i].nodeMover:getDistanceToExit()<2.0 then
			spirits[i].particleTale:setSpawnRate(spirits[i].nodeMover:getDistanceToExit()/2.0)
			if spirits[i].killSpirit==nil then
				spirits[i].particle:setSpawnRate(0.0)
				spirits[i].pLight:pushRangeChange(0.1,1.0)
				spirits[i].killSpirit = true
			end
		end
		
		if spirits[i].nodeMover:isAtFinalDestination() or ( spirits[i].lifeTime > 0 and (spirits[i].lifeTime - Core.getDeltaTime()) < 0 ) then
			spirits[i].nodeMover = nil
			spirits[i].node:destroyTree()
			spirits[i].particleTale:destroyTree()
			table.remove(spirits,i)
		else
			spirits[i].lifeTime = spirits[i].lifeTime - Core.getDeltaTime()
			i=i+1
		end
	end
	
	
--	updateMesh()
	return true
end