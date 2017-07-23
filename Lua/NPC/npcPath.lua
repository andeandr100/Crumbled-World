--this = SceneNode()

NpcPath = {}
function NpcPath.new()
	local self = {}
	local spawns = nil
	local points = nil
	local paths = nil
	local ends = nil
	local nodeMover = nil
	local groupId = nil
	local lastPointIdAdded = nil
	local restoreMeshData = {}
	local resetTime = 0
	
	local function wayPointReached()
		local lastId = lastPointIdAdded
		local groupId = groupId
		local posibleTargetLocation = paths[groupId][lastPointIdAdded]
		if posibleTargetLocation then
			local nextId = posibleTargetLocation[math.randomInt(1, #posibleTargetLocation)]
			nodeMover:addMoveTo(points[nextId].island, points[nextId].position)
			lastPointIdAdded = nextId
		end
	end
	
	function self.findPath(nodeMover, model)
		nodeMover = nodeMover
		local bilboard = Core.getBillboard("Paths")
		if bilboard then
			resetTime = Core.getGameTime() + 5
			spawns = bilboard:getTable("spawns")
			points = bilboard:getTable("points")
			paths = bilboard:getTable("paths")
			ends = bilboard:getTable("ends")
			local spawnPortals = bilboard:getTable("spawnPortals")
			
	--		print("Spawns: "..tostring(spawns).."\n")
	--		print("points: "..tostring(points).."\n")
	--		print("paths: "..tostring(paths).."\n")
			
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
							
							restoreMeshData[n] = {mesh = meshList[n], shader = meshList[n]:getShader(), shadowShader = meshList[n]:getShadowShader()}
							
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
			
	--		print(tostring(spawns).."\n\n")
	--		print(tostring(points).."\n\n")
	--		print(tostring(paths).."\n\n")
	--		print(tostring(ends).."\n\n")
			
			local island = this:findNodeByTypeTowardsRoot(NodeId.island)
			local spawn = nil
			--find the spawn
			for i=1, #spawns do
				if ((spawns[i].island:getGlobalMatrix() * spawns[i].position) - globalPosition):length() < 1.0 then
					spawn = spawns[i]				
				end
			end
			
			if not spawn then
				print("No spawn found\n")
				print("set random end as end point\n")
				local endPoint = ends[math.randomInt(1, #ends)]
				
				if endPoint and endPoint.followNode then
					nodeMover:followNode(endPoint.followNode)
				elseif endPoint then
					nodeMover:addMoveTo(endPoint.island, endPoint.position)
				else
					print("No end where found on the map\n")
				end
				return
			end
			
			groupId = 0
			local numGroup = #spawn.groups
			if numGroup > 0 then
				groupId = spawn.groups[math.randomInt(1, numGroup)]
			else
				print("no path found set random end as end point\n")
				local endPoint = ends[math.randomInt(1, #ends)]
				nodeMover:addMoveTo(endPoint.island, endPoint.position)
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
						nodeMover:followNode(points[nextId].followNode)
					else
						nodeMover:addMoveTo(points[nextId].island, points[nextId].position)
					end
					usedPoints[id] = true
					
					id = nextId
					print("Next id: "..id)
				else
					run = false
				end
			end
			
			lastPointIdAdded = id
			if usedPoints[id] then
				nodeMover:addCallbackWayPointReached(wayPointReached)
			end
			
			
			
		else
			abort()
			print("No path bilboard was found")
		end
	end
	
	function self.update()
		if Core.getGameTime() - resetTime > 0 then
			--NpcPath.restoreMeshData[n] = {mesh = meshList[n], shader = meshList[n]:getShader(), shadowShader = meshList[n]:getShadowShader()}
			for i=1, #restoreMeshData do
				local data = restoreMeshData[i]
				data.mesh:setShader(data.shader)
				data.mesh:setShadowShader(data.shadowShader)
			end
			--clear table
			restoreMeshData = {}
			
			
			resetTime = Core.getGameTime() + 3600
		end
	end
	
	return self
end