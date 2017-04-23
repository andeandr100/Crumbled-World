require("Menu/settings.lua")
--this = Island()

IslandMeshOptimizer = {}
IslandMeshOptimizer.staticNode = SceneNode()		--meshes that will never change (in theory)
IslandMeshOptimizer.dynamicNode = SceneNode()		--Dynamic nodes that will need to be updated
IslandMeshOptimizer.oldNodes = SceneNode()
IslandMeshOptimizer.meshTable = {mesh=nil, localMatrix=Matrix()}
IslandMeshOptimizer.meshTableLocked = {mesh=nil, localMatrix=Matrix()}
IslandMeshOptimizer.notMovedNodes = {}
IslandMeshOptimizer.combinedMeshes = {}
IslandMeshOptimizer.unusedSpecialNodes = {}
IslandMeshOptimizer.activeSpecialNodes = {}
IslandMeshOptimizer.meshes = {}
IslandMeshOptimizer.minPos = Vec3()
IslandMeshOptimizer.maxPos = Vec3()
IslandMeshOptimizer.density = 1.0
IslandMeshOptimizer.addToIsland = {}
IslandMeshOptimizer.moveNodes = false
local optimizationIgnoreFileNameTable = {
	"props/watermelon.mym",
	"props/end_crystal.mym",
	"nature/worldedge/edge_floater1.mym",
	"nature/worldedge/edge_floater2.mym",
	"nature/worldedge/edge_floater3.mym",
	"nature/worldedge/edge_floater4.mym",
	"nature/worldedge/edge_floater5.mym",
}

local function isOnNavMeshHullEdge(position)
	for i=1, #IslandMeshOptimizer.navLines do 
		if Collision.lineSegmentPointLength2( IslandMeshOptimizer.navLines[i], position) < 1 then
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

--
--
--

function IslandMeshOptimizer.findAllMeshes(node, meshTable, moveNodes)
	local self = IslandMeshOptimizer
	--node = Model()

--	if node:getAllScript():size() > 0 then
--		move = true
--	end

	if node:getNodeType() == NodeId.model or node:getNodeType() == NodeId.islandMesh or (node:getNodeType() ~= NodeId.island and #node:getAllScript() > 0 ) then
	
		if (node:getNodeType() ~= NodeId.island and #node:getAllScript() > 0 ) then
			if moveNodes then
				local globalMatrix = node:getGlobalMatrix()
				node:getParent():removeChild(node)
				node:setLocalMatrix(this:getGlobalMatrix():inverseM() * globalMatrix)
				IslandMeshOptimizer.addToIsland[#IslandMeshOptimizer.addToIsland+1] = node
			else
				IslandMeshOptimizer.notMovedNodes[#IslandMeshOptimizer.notMovedNodes] = node
			end
			return false
		end
		if node:getNodeType() == NodeId.islandMesh or isInOptimizationIgnoreModelTable(node:getFileName()) then
			if moveNodes then
				if node:getNodeType() ~= NodeId.islandMesh then
					print("Ignore == "..node:getFileName().."\n")
				end
				local globalMatrix = node:getGlobalMatrix()
				node:getParent():removeChild(node)
				node:setLocalMatrix(this:getGlobalMatrix():inverseM() * globalMatrix)
				IslandMeshOptimizer.staticNode:addChild(node)	
			else
				IslandMeshOptimizer.notMovedNodes[#IslandMeshOptimizer.notMovedNodes] = node
			end
			return false
		end
		if string.find(node:getFileName(),"tree") then
			if moveNodes then
				local globalMatrix = node:getGlobalMatrix()
				node:getParent():removeChild(node)
				node:setLocalMatrix(this:getGlobalMatrix():inverseM() * globalMatrix)
				IslandMeshOptimizer.unusedSpecialNodes[#IslandMeshOptimizer.unusedSpecialNodes+1] = node
			else
				IslandMeshOptimizer.notMovedNodes[#IslandMeshOptimizer.notMovedNodes] = node
			end
			return false
		end
	end
	local nodeLocalMatrix = this:getGlobalMatrix():inverseM() * node:getGlobalMatrix()
	if node:getNodeType() == NodeId.mesh then
		if isOnNavMeshHullEdge(nodeLocalMatrix:getPosition()) or string.find(node:getModelName(),"railroad") or string.find(node:getModelName(),"buildings") or string.find(node:getModelName(),"world_edge") then 
			self.meshTableLocked[#self.meshTableLocked+1] = {mesh=node,localMatrix=nodeLocalMatrix}
			--print("--##-- locked meshes: "..node:getModelName().."\n")
		else
			meshTable[#meshTable+1] = {mesh=node,localMatrix=nodeLocalMatrix}
			meshTable = meshTable[#meshTable]
		end
	end
	local i=0
	if not (node:getNodeType() == NodeId.model and isInOptimizationIgnoreModelTable(node:getFileName())) then--we only optimize children of none ignored parents
		while i<node:getChildSize() do
			--copy node to the final mesh table and save the local island matrix
			local childNode = node:getChildNode(i)
			if childNode then
				if childNode:getNodeType() == NodeId.mesh or childNode:getNodeType() == NodeId.model or childNode:getNodeType() == NodeId.islandMesh then
					if self.findAllMeshes( childNode, meshTable, moveNodes) then
						if moveNodes then
							childNode:getParent():removeChild(childNode)		
						else
							IslandMeshOptimizer.notMovedNodes[#IslandMeshOptimizer.notMovedNodes] = childNode
							i=i+1
						end
					else
						i=i+1
					end
				else
					if self.findAllMeshes( childNode, meshTable, moveNodes) then
						i=i+1
					end
				end
			end
		end
	end

	if node:getNodeType() == NodeId.mesh and moveNodes then
		node:setLocalMatrix(nodeLocalMatrix)
	end
	return true
end

function IslandMeshOptimizer.addAllToMeshList(meshTable)
	if meshTable.mesh then
		IslandMeshOptimizer.meshes[#IslandMeshOptimizer.meshes+1] = {mesh = meshTable.mesh, localMatrix = meshTable.localMatrix}
	end
	for i=1, #meshTable do
		IslandMeshOptimizer.addAllToMeshList(meshTable[i])
	end
end

function IslandMeshOptimizer.calculateBounds(meshTable)
	if meshTable.mesh then
		local position = meshTable.mesh:getLocalPosition()
		IslandMeshOptimizer.minPos:minimize( position )
		IslandMeshOptimizer.maxPos:maximize( position )
	end
	for i=1, #meshTable do
		IslandMeshOptimizer.calculateBounds(meshTable[i])
	end
end

function IslandMeshOptimizer.addToRenderList(meshTable, dropCount, dropfrekvence)
	dropCount = dropCount + dropfrekvence

	for i=1, #meshTable do
		dropCount = IslandMeshOptimizer.addToRenderList(meshTable[i], dropCount, dropfrekvence)
	end
	
	if dropCount >= 1 then
		dropCount = dropCount - 1
	else
		IslandMeshOptimizer.meshes[#IslandMeshOptimizer.meshes+1] = {mesh = meshTable.mesh, localMatrix = meshTable.localMatrix}
	end
	
	return dropCount
end

function IslandMeshOptimizer.getMeshesToCombine()
	
	local meshTable = IslandMeshOptimizer.meshTable
	IslandMeshOptimizer.meshes = {}

	
	IslandMeshOptimizer.calculateBounds(IslandMeshOptimizer.meshTable)
	IslandMeshOptimizer.calculateBounds(IslandMeshOptimizer.meshTableLocked)
	IslandMeshOptimizer.minPos = IslandMeshOptimizer.minPos -  Vec3(1)
	IslandMeshOptimizer.maxPos = IslandMeshOptimizer.maxPos +  Vec3(1)
	
	local dropfrekvence = 1.0 - IslandMeshOptimizer.density 
	print("dropfrekvence "..dropfrekvence.."\n")
	if dropfrekvence < 0.01 then
		IslandMeshOptimizer.addAllToMeshList(IslandMeshOptimizer.meshTable)
		
		for i=1, #IslandMeshOptimizer.unusedSpecialNodes do
			IslandMeshOptimizer.staticNode:addChild(IslandMeshOptimizer.unusedSpecialNodes[i])
			IslandMeshOptimizer.activeSpecialNodes[#IslandMeshOptimizer.activeSpecialNodes + 1] = IslandMeshOptimizer.unusedSpecialNodes[i]
		end
		
	else
		local minPos = IslandMeshOptimizer.minPos
		local maxPos = IslandMeshOptimizer.maxPos
		local meshTable = IslandMeshOptimizer.meshTable
		for x = minPos.x, maxPos.x+2.5, 5 do
			for z = minPos.z, maxPos.z+2.5, 5 do
				local drop = 0
				for i=1, #meshTable do
					local position = meshTable[i].localMatrix:getPosition()
					if position.x > x and position.x <= x+5 and position.z > z and position.z < z+5 then
						drop = IslandMeshOptimizer.addToRenderList(meshTable[i], drop, dropfrekvence)
					end
				end
				
				for i=1, #IslandMeshOptimizer.unusedSpecialNodes do
					local position = IslandMeshOptimizer.unusedSpecialNodes[i]:getLocalPosition()
					if position.x > x and position.x <= x+5 and position.z > z and position.z < z+5 then
						drop = drop + dropfrekvence
						if drop < 1 then
							IslandMeshOptimizer.staticNode:addChild(IslandMeshOptimizer.unusedSpecialNodes[i])
							IslandMeshOptimizer.activeSpecialNodes[#IslandMeshOptimizer.activeSpecialNodes + 1] = IslandMeshOptimizer.unusedSpecialNodes[i]
						else
							drop = drop - 1
						end
					end
				end
			end
		end
	end
	
	local meshTableLocked = IslandMeshOptimizer.meshTableLocked
	for i=1, #meshTableLocked do
		IslandMeshOptimizer.meshes[#IslandMeshOptimizer.meshes+1] = meshTableLocked[i]
	end
end

function IslandMeshOptimizer.combineMeshes()
	local meshList = IslandMeshOptimizer.meshes
	local minPos = IslandMeshOptimizer.minPos
	local maxPos = IslandMeshOptimizer.maxPos
	local staticNode = IslandMeshOptimizer.staticNode
	print("minPos = Vec3( "..minPos.x..", "..minPos.y..", "..minPos.z..")\n")
	print("maxPos = Vec3( "..maxPos.x..", "..maxPos.y..", "..maxPos.z..")\n")
	local notMoveNodes = not IslandMeshOptimizer.moveNodes
	local parent = nil
	local meshOldLocalMatrix = Matrix()
	for x = minPos.x, maxPos.x+5, 10 do
		for z = minPos.z, maxPos.z+5, 10 do
			--print("------------------------ x:"..tostring(z).." z: "..tostring(z).."\n")
			local areaMeshes = {}
			--local mesh = NodeMesh()
	
			for i=1, #meshList do
				
				
				local position = meshList[i].mesh:getLocalPosition()
				
				if position.x > x and position.x <= x+10 and position.z > z and position.z <= z+10 then
					if notMoveNodes then
						meshOldLocalMatrix = meshList[i].mesh:getLocalMatrix() 
						parent = meshList[i].mesh:getParent()
						meshList[i].mesh:setLocalMatrix(meshList[i].localMatrix)
						parent:removeChild(meshList[i].mesh)
					end
				
					if meshList[i].mesh:getParent() and IslandMeshOptimizer.moveNodes then
						assert(false,"Something failed hard")
					end
					--Try to add mesh and if so remove all triangles facing down and have a dot value greater then 0.6
					local added = false
					for n=1, #areaMeshes do
						if not added and areaMeshes[n]:addMesh(meshList[i].mesh, Vec3(0,-1,0), 0.75) then
							added = true
						end	
					end
					if not added then
						areaMeshes[#areaMeshes+1] = NodeMesh()
						areaMeshes[#areaMeshes]:setLocalPosition(Vec3(x+5,0,z+5))
						if not areaMeshes[#areaMeshes]:addMesh(meshList[i].mesh, Vec3(0,-1,0), 0.75) then
							print("Mesh was not added to a combined mesh\n")
						end
					end
					
					if notMoveNodes then
						meshList[i].mesh:setLocalMatrix(meshOldLocalMatrix)
						parent:addChild(meshList[i].mesh)
					end
				end	
			end
			
			for n=1, #areaMeshes do
				if areaMeshes[n]:getNumVertex() > 0 then
					staticNode:addChild(areaMeshes[n])
					areaMeshes[n]:compile()	
					IslandMeshOptimizer.combinedMeshes[#IslandMeshOptimizer.combinedMeshes+1] = areaMeshes[n]
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

function IslandMeshOptimizer.initNodes()
	local self = IslandMeshOptimizer
	--create a bound volme for all static nodes
	self.staticNode:createBoundVolumeGroup()
	self.staticNode:setBoundingVolumeCanShrink(false)
	--no updates is needed
	self.staticNode:setEnableUpdates(false)
	--add static node to the island
	this:addChild(self.staticNode)
	
	
	self.dynamicNode:createBoundVolumeGroup()
	self.dynamicNode:setBoundingVolumeCanShrink(false)
	this:addChild(self.dynamicNode)
	
end

function IslandMeshOptimizer.optimize()
	local self = IslandMeshOptimizer
	--create a bound volme for all static nodes

	IslandMeshOptimizer.navMesh = this:findNodeByType(NodeId.navMesh)
	IslandMeshOptimizer.navLines = {}
	if IslandMeshOptimizer.navMesh and not Core.isInEditor() then
		local navMeshHull = IslandMeshOptimizer.navMesh:getHull()
		for i=1, #navMeshHull do
			local oldVertex = navMeshHull[i][#navMeshHull[i]]
			for n=1, #navMeshHull[i] do
				if navMeshHull[i][n].island and oldVertex.island and ( oldVertex.island == this or navMeshHull[i][n].island == this ) then
					IslandMeshOptimizer.navLines[#IslandMeshOptimizer.navLines+1] = Line3D(convertNavVertexToLocalIslandPos(oldVertex), convertNavVertexToLocalIslandPos(navMeshHull[i][n]))
					oldVertex = navMeshHull[i][n]
				end
			end
		end
	end
	

	--find and clear the island from all meshses that should be combined
	self.findAllMeshes(this,IslandMeshOptimizer.meshTable, IslandMeshOptimizer.moveNodes)
	

	IslandMeshOptimizer.getMeshesToCombine()

	IslandMeshOptimizer.combineMeshes()
	

	for i=1, #IslandMeshOptimizer.addToIsland do
		this:addChild(IslandMeshOptimizer.addToIsland[i])
	end
	IslandMeshOptimizer.addToIsland = {}

end

function IslandMeshOptimizer.destroy()
	--destroy all meshes tree
	destroyMeshTable(IslandMeshOptimizer.meshTable)	
end

function destroyMeshTable(meshTable)
	
	for i=1, #meshTable do
		destroyMeshTable(meshTable[i])	
	end
	
	if meshTable.mesh then
		meshTable.mesh:destroyTree()
	end
end

function IslandMeshOptimizer.settingsChanged()
	
	IslandMeshOptimizer.setDesity( Settings.modelDensity.getValue() )
	
end

function IslandMeshOptimizer.setDesity(density)
	print("-- Model density: "..tostring(density).."\n")
	if IslandMeshOptimizer.density ~= density then
		IslandMeshOptimizer.density = density
		
		for i=1, #IslandMeshOptimizer.combinedMeshes do
			IslandMeshOptimizer.combinedMeshes[i]:getParent():removeChild(IslandMeshOptimizer.combinedMeshes[i])
		end
		for i=1, #IslandMeshOptimizer.activeSpecialNodes do
			IslandMeshOptimizer.activeSpecialNodes[i]:getParent():removeChild(IslandMeshOptimizer.activeSpecialNodes[i])
		end
		IslandMeshOptimizer.activeSpecialNodes = {}
		
		IslandMeshOptimizer.combinedMeshes = {}
		
		IslandMeshOptimizer.getMeshesToCombine()
		
		IslandMeshOptimizer.combineMeshes()
	end
end