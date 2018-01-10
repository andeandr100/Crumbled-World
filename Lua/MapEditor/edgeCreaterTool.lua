require("MapEditor/Tools/Tool.lua")

local island = nil

--this = SceneNode()
function create()
	--Create tool
	Tool.create()
	--get seleced scene nodes
	selectedNodes = Tool.getSelectedSceneNodes()
	islands = {}
	
	--Init data
	dataSet = {}
	dataSet[1] = {length=0,modelName="world_edge_0deg_1m1.mym", matrix=Matrix(),positions={Vec3(0.62,0, 0.00), Vec3(0.28,0, 0.00), Vec3(0,0,0), Vec3(-0.30,0, 0.00), Vec3(-0.70,0, 0.00)}}
	dataSet[2] = {length=0,modelName="world_edge_0deg_3m1.mym", matrix=Matrix(),positions={Vec3(1.61,0, 0.00), Vec3(0.75,0, 0.00), Vec3(0,0,0), Vec3(-0.70,0, 0.00), Vec3(-1.51,0, 0.00)}}
	dataSet[3] = {length=0,modelName="world_edge_0deg_3m2.mym", matrix=Matrix(),positions={Vec3(1.52,0,-0.04), Vec3(0.74,0,-0.02), Vec3(0,0,0), Vec3(-0.70,0,-0.02), Vec3(-1.491,0,-0.04)}}
	dataSet[4] = {length=0,modelName="world_edge_22deg_3m1.mym", matrix=Matrix(),positions={Vec3(1.56,0, 0.42), Vec3(0.61,0, 0.16), Vec3(0,0,0), Vec3(-0.49,0, 0.13), Vec3(-1.40,0, 0.35)}}
	dataSet[5] = {length=0,modelName="world_edge_22deg_3m2.mym", matrix=Matrix(),positions={Vec3(1.46,0, 0.31), Vec3(0.67,0, 0.11), Vec3(0,0,0), Vec3(-0.61,0, 0.12), Vec3(-1.40,0, 0.33)}}
	dataSet[6] = {length=0,modelName="world_edge_45deg_3m1.mym", matrix=Matrix(),positions={Vec3(1.47,0, 0.52), Vec3(0.54,0, 0.12), Vec3(0,0,0), Vec3(-0.44,0, 0.20), Vec3(-1.28,0, 0.55)}}
	dataSet[7] = {length=0,modelName="world_edge_45deg_3m2.mym", matrix=Matrix(),positions={Vec3(1.40,0, 0.507), Vec3(0.60,0, 0.14), Vec3(0,0,0), Vec3(-0.58,0, 0.14), Vec3(-1.377,0, 0.49)}}
	dataSet[8] = {length=0,modelName="world_edge_n22deg_3m1.mym", matrix=Matrix(),positions={Vec3(1.63,0,-0.31), Vec3(0.77,0,-0.06), Vec3(0,0,0), Vec3(-0.64,0,-0.03), Vec3(-1.46,0,-0.24)}}
	dataSet[9] = {length=0,modelName="world_edge_n22deg_3m2.mym", matrix=Matrix(),positions={Vec3(1.52,0,-0.32), Vec3(0.47,0,-0.05), Vec3(0,0,0), Vec3(-0.62,0,-0.10), Vec3(-1.44,0,-0.33)}}
	dataSet[10] = {length=0,modelName="world_edge_n45deg_3m1.mym", matrix=Matrix(),positions={Vec3(1.47,0,-0.57), Vec3(0.65,0,-0.12), Vec3(0,0,0), Vec3(-0.49,0,-0.07), Vec3(-1.40,0,-0.54)}}
	dataSet[11] = {length=0,modelName="world_edge_n45deg_3m2.mym", matrix=Matrix(),positions={Vec3(1.39,0,-0.61), Vec3(0.49,0,-0.08), Vec3(0,0,0), Vec3(-0.61,0,-0.18), Vec3(-1.36,0,-0.57)}}
	dataSet[12] = {length=0,modelName="world_edge_n90deg_3m1.mym", matrix=Matrix(),positions={Vec3(1.26,0,-0.88), Vec3(0.65,0,-0.20), Vec3(0,0,0), Vec3(-0.55,0,-0.13), Vec3(-1.26,0,-0.81)}}
	dataSet[13] = {length=0,modelName="world_edge_n90deg_3m2.mym", matrix=Matrix(),positions={Vec3(1.14,0,-0.90), Vec3(0.57,0,-0.25), Vec3(0,0,0), Vec3(-0.53,0,-0.30), Vec3(-1.26,0,-0.87)}}
	dataSet.size = #dataSet
	
	--updates the length and matrix
	for i=1, dataSet.size do
		dataSet[i].length = (dataSet[i].positions[1]-dataSet[i].positions[5]):length()

		local offset = Matrix()
		offset:createMatrixR( (dataSet[i].positions[1]-dataSet[i].positions[5]):normalizeV(), Vec3(0,1,0))
		offset:setPosition(dataSet[i].positions[5])

		dataSet[i].matrix = offset:inverseM()
	end
	
	for i=1, #selectedNodes do
		island = selectedNodes[i]:findNodeByTypeTowardsRoot(NodeId.island)
		local compiled = false
		--check if the island has been compiled
		for n=1, #islands do
			if islands[n] == island then
				compiled = true
			end
		end
		if not compiled then
			--if island has not been compiled build island edge
			islands[#islands + 1] = island
			
			print("create() - START\n")
			--Clear earlier runs
			worldEdges = island:findAllNodeByNameTowardsLeaf("WorldEdge")
			for i=1, #worldEdges do
				local worldEdge = worldEdges[i]
				worldEdge:destroy()
			end
			
			local islandEdge = island:findNodeByTypeTowardsLeafe(NodeId.islandEdge)
			local hulls = islandEdge:getHulls()
		
			print("hulls.size="..#hulls.."\n")
			--create the edge
			for i=1, #hulls do
				compileHull(hulls[i], i==1);		
			end
			print("create() - END\n")
		end
	end
	return true
end

function compileHull( hull, reverseDir )
	print("compileHull() - START\n")
	
	local startPos = hull[1]
	local forceStop = false


	local swapDir = 0
	local numTest = 0
	for i=2, math.max(6, #hull) do
		local right = ((hull[i-1]-hull[i]):normalizeV()):crossProductV(Vec3(0,1,0))	
		if testIsPointInsidehull(hull[i] + right, Vec2(200.0), hull) then
			swapDir = swapDir + 1
		end
		numTest = numTest + 1
	end
	if swapDir > (numTest/2) == reverseDir then
		local size = #hull + 1
		for i=1, #hull/2 do
			hull[i], hull[size-i] = hull[size-i], hull[i]
		end
	end

	local n=2
	print("hull.size="..#hull.."\n")
	print("hull[hull.size]="..tostring(hull[hull.size]))
	while n <= hull.size do
		print("n="..n.."\n")
		
		printVec3("hull["..n.."]",hull[n])
		local success, misDist, collPos, hullindex, dataSetIndex = findNextModel(startPos, hull, n, 2, 0)
		printVec3("hull["..hullindex.."]",hull[hullindex])

		if hullindex>=n then
			if success then
				addModel(dataSet[dataSetIndex], startPos, collPos)
				
				n = hullindex
				startPos = collPos
		
--				if forceStop then
--					print("break\n")
--					break
--				end
--		
			else
				print("(startPos-hull[1]):dot()="..(startPos-hull[1]):dot()..", forceStop="..(forceStop and "true" or "false").."\n")
				if (startPos-hull[1]):dot() > 0.1 and not forceStop then
					--add a last model
					forceStop = true
					n = 1
					local endDist = (collPos-hull[1]):length()
					if endDist<2.0 then
						local success, misDist, collPos, hullindex, dataSetIndex = findNextModel(startPos, hull, n, 0, 1)
						addModel(dataSet[dataSetIndex], startPos, collPos)
					else
						local success, misDist, collPos, hullindex, dataSetIndex = findNextModel(startPos, hull, n, 0, 2)
						addModel(dataSet[dataSetIndex], startPos, collPos)
					end
					break--shoud continue
				else
					break
				end
			end
		else
--			if success then
--				addModel(dataSet[dataSetIndex], startPos, collPos)
--			end
			print("calculate the end piece here")
			break
		end

	end
	print("compileHull() - END\n")
end
function printVec3(name,vec)
	print(name.."("..vec.x..", "..vec.y..","..vec.z..")\n")
end

function testIsPointInsidehull(point, pointOutSide, hull)
	local value = 0
	for i=1, 5 do
		local randVec = math.randomVec3() * 0.6
		if isPointInsideHull( Line2D(Vec2(point.x, point.z) + Vec2(randVec.x, randVec.z), pointOutSide), hull ) then
			value = value + 1
		end
	end
	return (value > 2)
end

function isPointInsideHull(collisionLine, hull)
	local nummCollision = 0
	local oldIndex = hull["size"]
	for i=1, hull["size"] do
		if Collision.lineSegmentLineSegmentIntersection(Line2D(Vec2(hull[oldIndex].x, hull[oldIndex].z), Vec2(hull[i].x, hull[i].z)),collisionLine) then
			nummCollision = nummCollision + 1
		end
		oldIndex = i
	end
	return (nummCollision%2) == 1
end
function findNextModel(startPos, hull, n, depth, useOnlyModel)
	local success=false
	local misDist=256.0
	local collPos
	local hullindex
	local dataSetIndex = 1
	
	local iStart = 1
	local iEnd = dataSet.size
	if useOnlyModel>0 then
		iStart = useOnlyModel
		iEnd = useOnlyModel
	end
	
	for i=iStart, iEnd do
		tmpSuccess, tmpMisDist, tmpCollPos, tmpHullIndex = testModel(startPos, hull, n, dataSet[i], depth-1)
		if not success or (tmpSuccess and tmpMisDist < misDist)  then
			success = tmpSuccess
			misDist = tmpMisDist
			collPos = tmpCollPos
			hullindex = tmpHullIndex
			dataSetIndex = i
		end
	end
	return success, misDist, collPos, hullindex, dataSetIndex
end
function testModel( startPos, hull, startHullIndex, dataSet, depth )
	local oldPos = startPos
	local sphere = Sphere(startPos, dataSet.length)
	local collisionPos = Vec3()

	local convertMatrix = Matrix()

	for i=startHullIndex, hull["size"] do
		local collision, collisionPos = Collision.lineSegmentSphereIntersection(Line3D(hull[i], oldPos), sphere )
		if collision then
			
			convertMatrix:createMatrixR( (collisionPos-startPos):normalizeV(), Vec3(0,1,0))
			convertMatrix:setPosition(startPos)
			convertMatrix = convertMatrix * dataSet.matrix

			local misDist = getMinDistToPointFromHull(startPos, hull, startHullIndex, i, convertMatrix * dataSet.positions[2])
			misDist = misDist + getMinDistToPointFromHull(startPos, hull, startHullIndex, i, convertMatrix * dataSet.positions[3])
			misDist = misDist + getMinDistToPointFromHull(startPos, hull, startHullIndex, i, convertMatrix * dataSet.positions[4])
			--take in considiration the length
			misDist = misDist/dataSet.length
			--make length important
			misDist = misDist - (dataSet.length*0.01)
			
			if depth>0 then
				local success, misDist2, collPos, hullindex, dataSetIndex = findNextModel(collisionPos, hull, i, depth, 0)
				if success then
					return true, misDist2+misDist, collisionPos, i
				end
			end

			return true, misDist, collisionPos, i
		end
		oldPos = hull[i]
	end
	return false, 0, startPos, startHullIndex
end

function getMinDistToPointFromHull(startPos, Hull, startIndex, endIndex, point)

	--Core.addDebugSphere(Sphere(this:getGlobalMatrix() * point + Vec3(0,0.2,0), 0.25), 500.0, Vec3(1,1,1))

	local minDist = Collision.lineSegmentPointLength2(Line3D(startPos, Hull[startIndex]), point)
	for i= startIndex+1, endIndex do
		local tmpLength = Collision.lineSegmentPointLength2(Line3D(Hull[i-1], Hull[i]), point)
		if tmpLength < minDist then
			minDist = tmpLength
		end
	end
	return minDist
end

function addModel( dataSet, pos1, pos2 )
	model = Core.getModel(dataSet.modelName)
	print("Add model\n")

	--Core.addDebugLine( this:getGlobalMatrix() * pos1, this:getGlobalMatrix() * (pos1+Vec3(0,2,0)), 500.0, Vec3(1))
	--Core.addDebugLine( this:getGlobalMatrix() * pos2, this:getGlobalMatrix() * (pos2+Vec3(0,2,0)), 500.0, Vec3(0.1))

	--Core.addDebugSphere(Sphere(this:getGlobalMatrix() * pos1, 0.5), 500.0, Vec3(0,1,0))
	--Core.addDebugSphere(Sphere(this:getGlobalMatrix() * (pos2+Vec3(0,0.3,0)), 0.5), 500.0, Vec3(1,0,0))
	

	local mat = Matrix()
	mat:createMatrixR( (pos1 - pos2):normalizeV(), Vec3(0,1,0))
	mat:setPosition(pos1)

	model:setLocalMatrix( mat * dataSet.matrix:inverseM())

	island:addChild(model:toSceneNode())
	model:setSceneName("WorldEdge")
	

end

function update()
	print("UPDATE() - return false\n")
	return false
end