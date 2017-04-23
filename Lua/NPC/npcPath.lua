--this = SceneNode()

NpcPath = {}
NpcPath.spawns = nil
NpcPath.points = nil
NpcPath.paths = nil
NpcPath.ends = nil
NpcPath.nodeMover = nil
NpcPath.groupId = nil
NpcPath.lastPointIdAdded = nil
NpcPath.restoreMeshData = {}
NpcPath.resetTime = 0
function NpcPath.wayPointReached()
	local lastId = NpcPath.lastPointIdAdded
	local groupId = NpcPath.groupId
	local posibleTargetLocation = NpcPath.paths[NpcPath.groupId][NpcPath.lastPointIdAdded]
	if posibleTargetLocation then
		local nextId = posibleTargetLocation[math.randomInt(1, #posibleTargetLocation)]
		NpcPath.nodeMover:addMoveTo(NpcPath.points[nextId].island, NpcPath.points[nextId].position)
		NpcPath.lastPointIdAdded = nextId
	end
end

function NpcPath.findPath(nodeMover, model)
	NpcPath.nodeMover = nodeMover
	local bilboard = Core.getBillboard("Paths")
	if bilboard then
		NpcPath.resetTime = Core.getGameTime() + 5
		NpcPath.spawns = bilboard:getTable("spawns")
		NpcPath.points = bilboard:getTable("points")
		NpcPath.paths = bilboard:getTable("paths")
		NpcPath.ends = bilboard:getTable("ends")
		local spawnPortals = bilboard:getTable("spawnPortals")
		
--		print("Spawns: "..tostring(NpcPath.spawns).."\n")
--		print("points: "..tostring(NpcPath.points).."\n")
--		print("paths: "..tostring(NpcPath.paths).."\n")
		
		local globalPosition = this:getGlobalPosition()
		for i=1, #spawnPortals do
			local spawnModel = spawnPortals[i]
			if (globalPosition - spawnPortals[i]:getGlobalPosition()):dot() < 4 then
				
				--spawnMatrix = Matrix
				local spawnMatrix = spawnPortals[i]:getGlobalMatrix()
				local atVec = spawnMatrix:getAtVec():normalizeV()
				
				this:setLocalPosition( this:getLocalPosition() - atVec )				
				
				local centerPosition = spawnMatrix:getPosition() + spawnMatrix:getUpVec() * 0.75
--				Core.addDebugSphere(Sphere(centerPosition, 0.1), 500.0, Vec3(1,1,1))
--				Core.addDebugLine(centerPosition, centerPosition + atVec, 500, Vec3(1,0,0))
				
				local meshList = model:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
				local shader = Core.getShader("animatedSpawnPortal")
				local shadowShader = Core.getShader("animatedShadowPortal")
				if shader and shadowShader then
					for n=1, #meshList do
						
						NpcPath.restoreMeshData[n] = {mesh = meshList[n], shader = meshList[n]:getShader(), shadowShader = meshList[n]:getShadowShader()}
						
						meshList[n]:setShader(shader)
						meshList[n]:setShadowShader(shadowShader)
	
						--set diffuse shader uniforms
						meshList[n]:setUniform(shader,"portalPosition", centerPosition)
						meshList[n]:setUniform(shader,"portalAtVec", atVec)
						meshList[n]:setUniform(shader,"portalColor", Vec3(1,1,0))
						
						--set shadow shader
						meshList[n]:setUniform(shadowShader,"portalPosition", centerPosition)
						meshList[n]:setUniform(shadowShader,"portalAtVec", atVec)
					end
				end
			end
		end
		
--		print(tostring(NpcPath.spawns).."\n\n")
--		print(tostring(NpcPath.points).."\n\n")
--		print(tostring(NpcPath.paths).."\n\n")
--		print(tostring(NpcPath.ends).."\n\n")
		
		local island = this:findNodeByTypeTowardsRoot(NodeId.island)
		local spawn = nil
		--find the spawn
		for i=1, #NpcPath.spawns do
			if ((NpcPath.spawns[i].island:getGlobalMatrix() * NpcPath.spawns[i].position) - globalPosition):length() < 1.0 then
				spawn = NpcPath.spawns[i]				
			end
		end
		
		if not spawn then
			print("No spawn found\n")
			print("set random end as end point\n")
			local endPoint = NpcPath.ends[math.randomInt(1, #NpcPath.ends)]
			
			if endPoint and endPoint.followNode then
				nodeMover:followNode(endPoint.followNode)
			elseif endPoint then
				nodeMover:addMoveTo(endPoint.island, endPoint.position)
			else
				print("No end where found on the map\n")
			end
			return
		end
		
		NpcPath.groupId = 0
		local numGroup = #spawn.groups
		if numGroup > 0 then
			NpcPath.groupId = spawn.groups[math.randomInt(1, numGroup)]
		else
			print("no path found set random end as end point\n")
			local endPoint = NpcPath.ends[math.randomInt(1, #NpcPath.ends)]
			nodeMover:addMoveTo(endPoint.island, endPoint.position)
			return
		end
		
		
		local id = spawn.id
		local run = true
		local usedPoints = {}
		while run and not usedPoints[id] do
			local posibleTargetLocation = NpcPath.paths[NpcPath.groupId][id]
			if posibleTargetLocation and #posibleTargetLocation > 0 then
				local nextId = posibleTargetLocation[math.randomInt(1, #posibleTargetLocation)]
				if NpcPath.points[nextId].followNode then
					nodeMover:followNode(NpcPath.points[nextId].followNode)
				else
					nodeMover:addMoveTo(NpcPath.points[nextId].island, NpcPath.points[nextId].position)
				end
				usedPoints[id] = true
				
				id = nextId
				print("Next id: "..id)
			else
				run = false
			end
		end
		
		NpcPath.lastPointIdAdded = id
		if usedPoints[id] then
			nodeMover:addCallbackWayPointReached(NpcPath.wayPointReached)
		end
		
		
		
	else
		abort()
		print("No path bilboard was found")
	end
end

function NpcPath.update()
	if Core.getGameTime() - NpcPath.resetTime > 0 then
		--NpcPath.restoreMeshData[n] = {mesh = meshList[n], shader = meshList[n]:getShader(), shadowShader = meshList[n]:getShadowShader()}
		for i=1, #NpcPath.restoreMeshData do
			local data = NpcPath.restoreMeshData[i]
			data.mesh:setShader(data.shader)
			data.mesh:setShadowShader(data.shadowShader)
		end
		--clear table
		NpcPath.restoreMeshData = {}
		
		
		NpcPath.resetTime = Core.getGameTime() + 3600
	end
end