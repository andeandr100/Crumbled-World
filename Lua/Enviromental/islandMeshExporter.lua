--this = Island()

IslandMeshExporter = {}

function IslandMeshExporter.new()
	local self = {}
	local navLines
	local meshTable
	local listOfAllCombinedMeshes
	local hidenNodes = {}
	local meshes
	local importentMeshes--a list of meshes thats always need to be renderd	
	local minPos
	local maxPos
	local density = 1.0
	local combinedMeshes
	local debugNodes
	local debugNodeNames = { "debug_circle_5m", "debug_circle_7_5m", "debug_crossbow_attack_area", "debug_tower_platform_1x1", "debug_tower_platform_2x2", "debug_tower_platform_3x3", "debug_tower_platform_4x4" }
	local aFileNode
	local destroyFiles = {}
	
	--clear scene tree from exported data
	function self.destroy()
		if aFileNode then
			for i=1, #destroyFiles do
				aFileNode:removeFile(destroyFiles[i])
			end
		end
	end
	
	function self.getMeshTable()
		return listOfAllCombinedMeshes
	end
	
	local function getNodeBeforeIsland(sceneNode)
		if sceneNode and sceneNode:getParent() and sceneNode:getParent():getNodeType() == NodeId.island then
			return sceneNode
		end
		return sceneNode and getNodeBeforeIsland(sceneNode:getParent()) or nil
	end
	
	function self.hideExportedMeshes()
		--hide all meshes
		print("hideExportedMeshes\n")
		for i=1, #listOfAllCombinedMeshes do
			listOfAllCombinedMeshes[i]:setCanBeSaved(false)
		end
		
		for i=1, #debugNodes do
			debugNodes[i]:setCanBeSaved(false)
		end
		
		for i=1, #listOfAllCombinedMeshes do
			local node = getNodeBeforeIsland(listOfAllCombinedMeshes[i])
			if node then
				local meshList = node:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
				local allHiden = true
				for n=1, #meshList do
					if meshList[n]:getCanBeSaved() then
						allHiden = false
					end
				end
				if allHiden then
					node:setCanBeSaved(false)
					hidenNodes[#hidenNodes + 1] = node
				end
			end
		end
	end
	
	function self.showHidenNodes()
		print("showHidenNodes\n")
		for i=1, #listOfAllCombinedMeshes do
			listOfAllCombinedMeshes[i]:setCanBeSaved(true)
		end
		for i=1, #debugNodes do
			debugNodes[i]:setCanBeSaved(true)
		end
		for i=1, #hidenNodes do
			hidenNodes[i]:setCanBeSaved(true)
		end
		hidenNodes = {}
	end
	
	local optimizationIgnoreFileNameTable = {
		"props/watermelon.mym",
		"props/end_crystal.mym",
		"props/minecart_npc.mym",
		"nature/worldedge/edge_floater1.mym",
		"nature/worldedge/edge_floater2.mym",
		"nature/worldedge/edge_floater3.mym",
		"nature/worldedge/edge_floater4.mym",
		"nature/worldedge/edge_floater5.mym",
		"Constructions/buildings/mine.mym"
	}
	
	local function isOnNavMeshHullEdge(position)
		for i=1, #navLines do 
			if Collision.lineSegmentPointLength2( navLines[i], position) < 1 then
				return true
			end
		end
		return false
	end
	local function isInOptimizationIgnoreModelTable(fileName)
		for key,name in pairs(optimizationIgnoreFileNameTable) do
			if name==fileName then
				return true
			end
		end
		return false
	end
	
	local function findAllMeshes(node, inMeshTable)
		--node = Model()

		if node:getNodeType() == NodeId.model or node:getNodeType() == NodeId.islandMesh or (node:getNodeType() ~= NodeId.island and #node:getAllScript() > 0 ) then
			--nodes to ignore
			if (node:getNodeType() ~= NodeId.island and #node:getAllScript() > 0 ) then
				return false
			end
			if node:getNodeType() == NodeId.islandMesh or isInOptimizationIgnoreModelTable(node:getFileName()) then
				return false
			end
			for i=1, #debugNodeNames do
				if debugNodeNames[i] == node:getSceneName() then
					debugNodes[#debugNodes+1] = node
					return false
				end
			end
			
			if string.find(node:getFileName(),"tree") then
				return false
			end
		end
		local nodeLocalMatrix = this:getGlobalMatrix():inverseM() * node:getGlobalMatrix()
		local dontTochMesh = false
		if node:getNodeType() == NodeId.mesh then
			if isOnNavMeshHullEdge(nodeLocalMatrix:getPosition()) or string.find(node:getModelName(),"buildingParts") or string.find(node:getModelName(),"railroad") or string.find(node:getModelName(),"buildings") or string.find(node:getModelName(),"world_edge") then 
				importentMeshes[#importentMeshes+1] = {mesh=node,localMatrix=nodeLocalMatrix}
			else
				inMeshTable[#inMeshTable+1] = {mesh=node,localMatrix=nodeLocalMatrix}
				inMeshTable = inMeshTable[#inMeshTable]
				
			end
			
			if string.find(node:getModelName(),"minecart_npc") then
				print("ModelName: "..node:getModelName().."\n")
				abort()
			end
			
			listOfAllCombinedMeshes[#listOfAllCombinedMeshes + 1] = node
		end

		if not (node:getNodeType() == NodeId.model and isInOptimizationIgnoreModelTable(node:getFileName())) then--we only optimize children of none ignored parents
			if node:getNodeType() == NodeId.model and  node:getFileName() == "props/minecart_npc.mym" then
				abort()
			end
			for i=0, node:getChildSize() do
				--copy node to the final mesh table and save the local island matrix
				local childNode = node:getChildNode(i)
				if childNode and childNode:getCanBeSaved() then
					findAllMeshes( childNode, inMeshTable )
				end
			end
		end
	
		return true
	end
	
	--calculate bound volume
	local function calculateBounds(inMeshTable)
		if inMeshTable.mesh then
			local position = inMeshTable.localMatrix:getPosition()
			minPos:minimize( position )
			maxPos:maximize( position )
		end
		for i=1, #inMeshTable do
			calculateBounds(inMeshTable[i])
		end
	end
	
	local function addAllToMeshList(inMeshTable)
		if inMeshTable.mesh then
			meshes[#meshes+1] = {mesh = inMeshTable.mesh, localMatrix = inMeshTable.localMatrix}
		end
		for i=1, #inMeshTable do
			addAllToMeshList(inMeshTable[i])
		end
	end
	
	local function addToRenderList(inMeshTable, dropCount, dropfrekvence)
		dropCount = dropCount + dropfrekvence
	
		for i=1, #inMeshTable do
			dropCount = addToRenderList(inMeshTable[i], dropCount, dropfrekvence)
		end
		
		if dropCount >= 1 then
			dropCount = dropCount - 1
		else
			meshes[#meshes+1] = {mesh = inMeshTable.mesh, localMatrix = inMeshTable.localMatrix}
		end
		
		return dropCount
	end
	
	local function getMeshesToCombine()
		

		meshes = {}
		
		local dropfrekvence = 1.0 - density 
		print("dropfrekvence "..dropfrekvence.."\n")
		if dropfrekvence < 0.01 then
			addAllToMeshList(meshTable)		
		else
			local drop = 0
			for i=1, #meshTable do
				drop = addToRenderList(meshTable[i], drop, dropfrekvence)
			end
		end
		
		for i=1, #importentMeshes do
			meshes[#meshes+1] = importentMeshes[i]
		end
	end
	
	local function combineMeshes()
		local parent = nil
		local meshOldLocalMatrix = Matrix()
		for x = minPos.x, maxPos.x+5, 15 do
			for z = minPos.z, maxPos.z+5, 15 do
				local areaMeshes = {}
				for i=1, #meshes do

					local position = meshes[i].localMatrix:getPosition()
					
					if position.x > x and position.x <= x+15 and position.z > z and position.z <= z+15 then
						
						--prepare mesh to be added to a nodemesh
						meshOldLocalMatrix = meshes[i].mesh:getLocalMatrix() 
						parent = meshes[i].mesh:getParent()
						meshes[i].mesh:setLocalMatrix(meshes[i].localMatrix)
						parent:removeChild(meshes[i].mesh)
						

						--Try to add mesh and if so remove all triangles facing down and have a dot value greater then 0.75
						local added = false
						for n=1, #areaMeshes do
							if not added and areaMeshes[n]:addMesh(meshes[i].mesh, Vec3(0,-1,0), 0.75) then
								added = true
							end	
						end
						if not added then
							areaMeshes[#areaMeshes+1] = NodeMesh()
							areaMeshes[#areaMeshes]:setLocalPosition(Vec3(x+5,0,z+5))
							if not areaMeshes[#areaMeshes]:addMesh(meshes[i].mesh, Vec3(0,-1,0), 0.75) then
								print("Mesh was not added to a combined mesh\n")
							end
						end
						
						--restore the mesh information
						meshes[i].mesh:setLocalMatrix(meshOldLocalMatrix)
						parent:addChild(meshes[i].mesh)
						
					end	
				end
				
				for n=1, #areaMeshes do
					if areaMeshes[n]:getNumVertex() > 0 then
						combinedMeshes[#combinedMeshes+1] = areaMeshes[n]
					end
				end
			end
		end
	end
	
	local function convertNavVertexToLocalIslandPos(navVertex)
		if navVertex.island == this then
			return navVertex.position
		else
			return this:getGlobalMatrix():inverseM() * navVertex.island:getGlobalMatrix() * navVertex.position
		end
	end
	
	local function buildNavMeshEdgeLine()
		local navMesh = this:findNodeByType(NodeId.navMesh)
		navLines = {}
		if navMesh then
			local navMeshHull = navMesh:getHull()
			for i=1, #navMeshHull do
				local oldVertex = navMeshHull[i][#navMeshHull[i]]
				for n=1, #navMeshHull[i] do
					if navMeshHull[i][n].island and oldVertex.island and ( oldVertex.island == this or navMeshHull[i][n].island == this ) then
						navLines[#navLines+1] = Line3D(convertNavVertexToLocalIslandPos(oldVertex), convertNavVertexToLocalIslandPos(navMeshHull[i][n]))
						oldVertex = navMeshHull[i][n]
					end
				end
			end
		end
	end
	
	function self.export(fileNode)
		
		buildNavMeshEdgeLine()
		
		listOfAllCombinedMeshes = {}
		importentMeshes = {}
		meshTable = {}
		debugNodes = {}
		--find all meshes
		findAllMeshes(this, meshTable)
		
		
		minPos = Vec3()
		maxPos = Vec3()
		--calculate bound volume
		calculateBounds(meshTable)
		calculateBounds(importentMeshes)
		--increase size
		minPos = minPos -  Vec3(1)
		maxPos = maxPos +  Vec3(1)
		
		aFileNode = fileNode
		
		local fileId = 1
		local modelInfo = {}
		for newDensity = 1.0, -0.1, -0.2 do
			density = newDensity
			
			--calculate which meshes will be used
			getMeshesToCombine()
			
			combinedMeshes = {}
			combineMeshes()
			
			
			local models = {}
			for i=1, #combinedMeshes do
				print("Save model "..fileId.."\n")
				local nodeMesh = combinedMeshes[i]
				--nodeMesh = NodeMesh()
				local modelName = "Island"..this:getIslandId().."Model"..fileId
				local modelFile = nodeMesh:saveToFile(modelName)
				fileNode:addFile(modelName, modelFile)
				destroyFiles[#destroyFiles + 1] = modelName
				
				models[#models+1] = {modelName = modelName, localPosition = nodeMesh:getLocalPosition()}
				fileId = fileId + 1
			end
			modelInfo[#modelInfo + 1] = {value=density}
			modelInfo[#modelInfo].models = models
		end
		
		return modelInfo
	end
	
	
	
	
	
	
	
	
	local function init()
		
	end
	init()
	return self
end