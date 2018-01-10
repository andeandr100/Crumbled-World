--this = PlayerNode()

--this script is specialized and should be run after all nodes has been created.
--All unesacery nodes will be removed after this scripts has been runed.
--nodes with script and below will not be cahanged.


function collapseNode(aIsland, node)
	if node == nil then
		return false
	end
	
	
	for i=0, node:getChildSize()-1 do
		if collapseNode(aIsland, node:getChildNode(i)) then
			i = i - 1
		end
	end

	
	--on the back tear down the nodes and if they are mesh move
	if not ( node:getNodeType() == NodeId.model or node:getNodeType() == NodeId.sceneNode ) then
		local globalMat = node:getGlobalMatrix()
		node:getParent():removeChild(node:toSceneNode())
		
		aIsland:addChild(node:toSceneNode())
		node:setLocalMatrix( aIsland:getGlobalMatrix():inverseM() * globalMat )
		return true
	else
		node:getParent():removeChild(node:toSceneNode())
		return true
	end
end

function islandOptimization(aIsland)
	local staticNode = aIsland:addChild(SceneNode.new())
	--staticNode:setIsStatic(true)
	staticNode:setEnableUpdates(false)
	
	local i=0
	while i < aIsland:getChildSize()-1 do
		local node = aIsland:getChildNode(i)
		if node and node:getNodeType() == NodeId.model and #node:getAllScript() == 0 then
			if collapseNode(staticNode, node) then
				i = i - 1
			end
		end
		i = i + 1
	end
	
	--staticNode:createBoundVolumeGroup()
	
end

--Tries to group togheter a bunch of nodes with script and
--create a group with a thread
local groupSize = 10
function islandScriptGroupOptimizer(aIsland)
	local list = {}
	local size = 0
	for i=0, aIsland:getChildSize()-1 do
		local node = aIsland:getChildNode(i)
		if node and #node:getAllScript() > 0 then
			size = size + 1
			list[size] = node
		end
	end
	if size > groupSize then
		print("----------\nIsland created group\n-----------")
		local groupNode = aIsland:addChild(SceneNode("Island group node"))
		--groupNode:setIsStatic(true)
		groupNode:createWork()
		for i=1, groupSize do
			groupNode:addChild(	list[i]:toSceneNode() )	
		end
	end
end

function findAllNodes(node)
	if node then
		return
	end
	if node:getNodeType() == NodeId.mesh then
		meshList[counter] = node
		counter = counter + 1
	end
	
	for i=0, node:getChildSize()-1 do
		findAllNodes( node:getChildNode(i))
	end
end

function createRenderMesh(island)
	for i=1, 50 do
		print("#")
	end
	meshList = {}
	counter = 1
	maxRuns = 8
	--find all meshes on the island and save them in meshlist
	findAllNodes(island)
	
	while counter > 1 and maxRuns > 0 do
		newList = {}
		counter = 1
		mesh = NodeMesh.new()
		for i=1, #meshList do
			if not mesh:addMesh(meshList[i]) then
				newList[counter] = meshList[i]
				counter = counter + 1
			else
				meshList[i]:getParent():removeChild(meshList[i]:toSceneNode())
			end
		end
		mesh:compile()
		if mesh:getNumVertex() > 0 then
			island:addChild(mesh:toSceneNode())
			meshList = newList
			newList = {}
		else
			counter = 1			
		end
		maxRuns = maxRuns - 1
	end
end

function create()
--	local islands = this:findAllNodeByTypeTowardsLeaf(NodeId.island)
--	
--	for i=0, islands:size()-1 do
--		createRenderMesh(islands:item(i))
--		--islandOptimization(islands:item(i))
--	end
	
	updateInterval = 5
	timeToNextUpdata = updateInterval
	
	updateIslandBoundingVolumes = Core.getTime() + 5
	return true
end

function update()
--	if updateIslandBoundingVolumes < Core.getTime() then
--		updateIslandBoundingVolumes = Core.getTime() + 5
--		
--		local islands = this:findAllNodeByTypeTowardsLeaf(NodeId.island)
--	
--		for i=0, islands:size()-1 do
--			local island = islands:item(i)
--			--island = Island()
--			local box = island:getGlobalMatrix():inverseM() * island:getBoundingBox()
--			--box = Box()
--			box = Box( box:getMinPos() - Vec3(1), box:getMaxPos() + Vec3(1))
--			island:setBoundingBox(box)
--		end
--	end
--	timeToNextUpdata = timeToNextUpdata - Core.getDeltaTime()
--	if timeToNextUpdata < 0 then
--		timeToNextUpdata = updateInterval
--		
--		local islands = this:findAllNodeByTypeTowardsLeaf(NodeId.island)
--	
--		for i=0, islands:size()-1 do
--			islandScriptGroupOptimizer(islands:item(i))
--		end
--	end
	return true
end