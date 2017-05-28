--this = SceneNode()

function destroy()
	--clear bilboard
	--local bilboard = Core.getGlobalBillboard("Paths")
	--print("Destroy pathNode!!!!!!!!!!!!!!!!!!!!!!\n")
	--bilboard:clear();
end

function create()
	
	pathData = {}
	pathData.paths = {}
	pathData.spawnAreas = {}
	pathData.pathPoints = {}
	pathData.targetAreas = {}
	pathData.railPaths = {}
	
	pathListener = Listener("Path node")
	pathListener:registerEvent("Change", changed)
	
	return true
end

function changed(text)
	pathData = text
end

function save()
	return "table="..tabToStrMinimal(pathData)
end

function getIslandFromId(islands, id)
	for i=1, #islands do
		if islands[i]:getIslandId() == id then
			return islands[i]
		end
	end
	return nil
end

function load(inData)
	if this:getRootNode():findNodeByName("MainCamera") == nil then
		update = stopUpdate
		print( "PathNode id: "..this:getId().." is not in the main tree\n" )
		return
	end
	print( "PathNode load id: "..this:getId().."\n" )
	local pathNodes = this:getRootNode():findAllNodeByNameTowardsLeaf("Path node")

	if #pathNodes > 1 then
		--remove from tree	
		this:getParent():removeChild(this)
		update = stopUpdate
	else	
		numTowers = 0
		
		print("\nLoad path node: "..inData.."\n")
		pathData = totable( inData )
		pathListener:pushEvent("Loaded", pathData)
		
		if not init() then
			oldUpdate = update
			update = backupUpdate
		end
	end
end

function init()	
	pathData.paths = pathData.paths or {}
	pathData.spawnAreas = pathData.spawnAreas or {}
	pathData.pathPoints = pathData.pathPoints or {}
	pathData.targetAreas = pathData.targetAreas or {}
	pathData.railPaths = pathData.railPaths or {}
	 
	local bilboard = Core.getGlobalBillboard("Paths")
	bilboard:clear();
	
	print( "PathNode bilboard clear id: "..this:getId().."\n" )

	spawns = {}
	ends = {}
	points = {}
	paths = {}
	railPaths = pathData.railPaths
	
	
	for i=1, #railPaths do
		local minecart = Core.getModel("props/minecart_npc")			
		railPaths[i].followNode = minecart
	end
	
	
	print("railPaths: "..tostring(railPaths).."\n")
	local islands = this:getPlayerNode():findAllNodeByTypeTowardsLeaf(NodeId.island)
	
	local data = {pathData.spawnAreas, pathData.pathPoints, pathData.targetAreas, pathData.railPaths}
	local maxId = 0
	print("local data = "..tostring(data).."\n")
	print("size = "..#data.."\n")
	for i=1, #data  do
		local pointData = data[i]
		print("local pointData = "..tostring(pointData).."\n")
		print("size = "..#pointData.."\n")
		for n=1, #pointData do
			local island = getIslandFromId(islands, pointData[n].islandId)
			if island == nil then
				print("Island "..pointData[n].islandId.." not found\n")
				print("Islands registerd: "..tostring(islands).."\n\n")	
				return false				
			end
			print("local island = "..tostring(island).."\n")
			local point = { island = island, id = pointData[n].id, position = pointData[n].position, followNode = pointData[n].followNode }
			points[point.id] = point
			maxId = maxId > point.id and maxId or point.id
			if i == 1 then
				spawns[#spawns+1] = point
			elseif i == 3 or i == 4 then
				ends[#ends + 1] = point
			end
		end
	end
	--abort()
	
	if not Core.isInEditor() then
		for i=1, #railPaths do
			local railPath = railPaths[i]
			local minecart = railPath.followNode
			minecart:setCanBeSaved(false)
			points[railPath.id].island:addChild( minecart )
			
			
			local atVec = (railPath.points[2] - railPath.points[1]):normalizeV()
			local nextPoint = 3
			while atVec:dot() < 0.1 and nextPoint < #railPath.points do
				atVec = (railPath.points[nextPoint] - railPath.points[1]):normalizeV()
				nextPoint = nextPoint + 1
			end
			
			local localMatrix = Matrix()
			if atVec:dot() > 0.1 then
				localMatrix:createMatrix(atVec, Vec3(0,1,0))
			end
			localMatrix:setPosition(railPath.points[1])
			
			minecart:setLocalMatrix( localMatrix )
			local script = minecart:toSceneNode():loadLuaScript("Game/mineCart.lua")
			script:callFunction("init", railPath.points)
		end
	end
	
	local linePaths = {}
	for i=1, #pathData.paths do
		local aPath = pathData.paths[i]
		linePaths[#linePaths+1] = {groupId = aPath.groupId, id = aPath[1].id, nextId = aPath[2].id}
	end
	
	local maxGroupId = 0
	local maxPointId = 0
	for i=1, #linePaths do
		--make sure group path has been created
		if not paths[linePaths[i].groupId] then
			maxGroupId = maxGroupId > linePaths[i].groupId and maxGroupId or linePaths[i].groupId
			paths[linePaths[i].groupId] = {}
		end
		local groupPath = paths[linePaths[i].groupId]
		local startPoint = linePaths[i].id
		local endPoint = linePaths[i].nextId
		
		
		
		if startPoint ~= endPoint then
			if not groupPath[startPoint] then
				groupPath[startPoint] = {}
			end
			
			groupPath[startPoint][#groupPath[startPoint]+1] = endPoint
		end
	end
	
	--gather all groups on all points
	for i=1, maxId do
		--check if the point exist
		if points[i] then
			--create a holder for all groups that has a path away from this point
			local groups = {}
			points[i].groups = groups
			for n=1, #linePaths do
				--get a paths startid
				local pointId = linePaths[n].id
				if pointId == i then
					--check if allready added
					local exist = false
					for j=1, #groups do
						if groups[j] == linePaths[n].groupId then
							exist = true
						end
					end
					--if the group has not yet been added add it to the point group list
					if not exist then
						groups[#groups+1] = linePaths[n].groupId			
					end
				end
			end
		end
	end
	print("\n==========================\n\n")
	print("spawns: "..tostring(spawns).."\n")
	print("ends: "..tostring(ends).."\n")
	print("points: "..tostring(points).."\n")
	print("paths: "..tostring(paths).."\n")
	
	
	
	bilboard:setTable("spawns", spawns)
	bilboard:setTable("ends", ends)
	bilboard:setTable("points", points)
	bilboard:setTable("paths", paths)
	bilboard:setTable("railPaths", railPaths)
	bilboard:setTable("railPaths", railPaths)
	
	print("\n==========================\n\n")
	buildNode = this:getPlayerNode():findNodeByTypeTowardsLeafe(NodeId.buildNode)
	if buildNode then
		for groupId = 1, maxGroupId do
			local groupPath = paths[groupId]
			if groupPath then
				print("group "..groupId.."\n")
				for pointId = 1, maxId do
					
					local startPoint = points[pointId]
					if groupPath[pointId] then
						print("start point id "..pointId.."\n")
						
						for n = 1, #groupPath[pointId] do
							local endPoint = points[groupPath[pointId][n]]
							
							print("add path id "..pointId..", id2 "..groupPath[pointId][n].."\n")

							local node1 = startPoint.island:toSceneNode()
							local node2 = endPoint.island:toSceneNode()
							buildNode:addPath(node1, startPoint.position, node2, endPoint.position)

						end
					end
				end
			end
			
		end

		for i=1, #points do
			if points[i] then
				buildNode:addProtectedPoint(points[i].island:toSceneNode(), points[i].position)
			end
		end
		
		
		for i=1, #railPaths do
			local island = points[railPaths[i].id].island
			local points = railPaths[i].points
			local offset = 0.6
			
			local oldRight = (points[2] - points[1]):normalizeV():crossProductV(Vec3(0,1,0))
			local midRight = oldRight
			for n=2, #points do
				local nextRight = Vec3()
				if #points > n then
					nextRight = (points[n+1] - points[n]):normalizeV():crossProductV(Vec3(0,1,0))
				else
					nextRight = oldRight
				end
				midRight = (oldRight + nextRight) * 0.5
				
				
	
				buildNode:addProtectedLine(island:toSceneNode(), Line3D(points[n] + midRight * offset, points[n-1] + oldRight * offset))
				buildNode:addProtectedLine(island:toSceneNode(), Line3D(points[n] - midRight * offset, points[n-1] - oldRight * offset))
				
				
				oldRight = nextRight
			end
		end
		
		------------------------------
		--- find all spawn portals ---
		------------------------------
		spawnPortals = {}
		
		for i=1, #spawns do
			print("Finding spawn portal from spawn "..i.."\n")
			local nodes = spawns[i].island:findAllNodeByNameTowardsLeaf("spawn_portal")
			
			if #nodes > 0 then
				for n=1, #nodes do
					print("found spawn portal\n")
					local inList = false
					for n=1, #spawnPortals do
						if spawnPortals[n] == nodes[n] then
							inList = true
							print("In list allready\n")
						end
					end
					
					if not inList then
						spawnPortals[#spawnPortals+1] = nodes[n]
						print("add portal to list\n")
					else
						print("portal is allready added to list\n")
					end
				end
			else
				nodes = this:getRootNode():findAllNodeByNameTowardsLeaf("spawn_portal")
				print("num spawn portal in tree: "..#nodes.."\n")
				print("No Spawn portal was found\n")
			end
			
		end
		
		print("spawnPortals: "..tostring(spawnPortals).."\n")
		
		bilboard:setTable("spawnPortals", spawnPortals)
		
		------------------------------
		---- Rotate spawn portals ----
		------------------------------
		
		rotateSpawnPortals()
		
		
	else
		print("buildNode not found\n")
		return false
	end
	return true
end

function findNextPointFromSpawn(spawn)
	
	local returnPoint = nil
	
	if spawn then
		local groupId = 0
		local numGroup = #spawn.groups
		if numGroup > 0 then
			groupId = spawn.groups[math.randomInt(1, numGroup)]
			
			local posibleTargetLocation = paths[groupId][spawn.id]
			if posibleTargetLocation and #posibleTargetLocation > 0 then
				local nextId = posibleTargetLocation[math.randomInt(1, #posibleTargetLocation)]
				returnPoint = points[nextId]
			end
		end		
	end
	
	
	if returnPoint then
		return returnPoint
	elseif #ends > 0 then
		print("set random end as end point for the spawn portal\n")
		return ends[math.randomInt(1, #ends)]
	else
		return nil
	end
end

function rotateSpawnPortals()
	local navMesh = this:findNodeByType(NodeId.navMesh)
	if navMesh then
		print("navMesh Found\n")
	end
	
	print("Num portals: "..#spawnPortals.."\n")
		
	for i=1, #spawnPortals do
		local spawnPortal = spawnPortals[i]
		local spawn = nil
		for n=1, #spawns do
			local distance = (spawnPortal:getGlobalPosition() - (spawns[n].island:getGlobalMatrix() * spawns[n].position)):length()
			print("distance to spawn"..n..": "..distance.."\n")
			if distance < 2.0 then
				spawn = spawns[n]
			end
		end
		
		
		local nextPoint = findNextPointFromSpawn(spawn)
		
		if spawn then
			print("Spawn Found\n")
		end
		if nextPoint then
			print("nextPoint Found\n")
		end
		
		
		if spawn and nextPoint and navMesh then
			local path = navMesh:getPath(0.8, spawn, nextPoint)
			
			print("Path size: "..#path.."\n")
			
			if path and #path > 1 then
				print("all well\n")
--				Core.addDebugLine(path[2].island:getGlobalMatrix() * path[2].position + Vec3(0,1,0), path[1].island:getGlobalMatrix() * path[1].position + Vec3(0,1,0), 500.0, Vec3(0,0,1))
--				Core.addDebugSphere(Sphere(path[1].island:getGlobalMatrix() * path[1].position + Vec3(0,1,0), 0.5), 500.0, Vec3(0,0,1))
				
				
				local atVec = Vec4()
				local nextPoint = 2
				while atVec:dot() < 0.1 and nextPoint < #path do
					atVec = spawn.island:getGlobalMatrix():inverseM() * Vec4((path[nextPoint].island:getGlobalMatrix() * path[nextPoint].position - path[1].island:getGlobalMatrix() * path[1].position):normalizeV(),0)
					nextPoint = nextPoint + 1
				end

					
				local newLocalMatrix = Matrix(spawn.position + Vec3(0,0.3,0))
				if atVec:dot() > 0.1 then
					newLocalMatrix:createMatrix(atVec:toVec3(), Vec3(0,1,0))
				end
				spawnPortals[i]:setLocalMatrix(newLocalMatrix)
			end
		else
			print("Missing data\n")
		end
	end
end

--return true when a new tower has been built
function hasTowerBeenBuilt()
	local buildingBillboard = Core.getBillboard("buildings")
	local currentNumberOfTowers = buildingBillboard:getInt("NumBuildingBuilt");
	if numTowers == currentNumberOfTowers then
		return false
	else
		numTowers = currentNumberOfTowers
		return true
	end
end

function backupUpdate()
	if this:getPlayerNode():findNodeByTypeTowardsLeafe(NodeId.buildNode) then
		if init() then
			update = oldUpdate
		end
	end
	return true
end

function stopUpdate()
	return false
end

function update()
	
	if buildNode and hasTowerBeenBuilt() then
		--when a tower has been built the spawn portals may need to rotate
		--This is unlikely but needs to be done to not get graphic problem
		rotateSpawnPortals()
	end
	return true
end