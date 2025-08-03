require("Game/Abilities/targetAreaEffect.lua") 
--this = SceneNode()

boostTargetArea = {}
function boostTargetArea.new(inBuildNode)
	local self = {}
	local nodeArea = SceneNode.new()
	local areaEffect = TargetAreaEffect.new("abilities/boostTargetArea")
	local buildNode = inBuildNode
	local selectedNodes = {}
	--buildNode = BuildNode()
	
	function self.hiddeTargetMesh()
		nodeArea:setVisible(false)
		areaEffect.hiddeTargetMesh()
	end
	
	function self.destroyTargetMesh()
		if nodeArea then
			self.hiddeTargetMesh()
			nodeArea:destroyTree()
			nodeArea = nil
		end
	end
	
	local function initTargetMesh()

		areaEffect.setUniform( "Radius", 1.8)
		areaEffect.setUniform( "effectColor", Vec3(1) )
		nodeArea:addChild(areaEffect.getSceneNode())
		
		--find main camera
		local rootNode = this:getRootNode()
		rootNode:addChild(nodeArea:toSceneNode())
		mainCamera = rootNode:findNodeByName("MainCamera")
		
		self.hiddeTargetMesh()
	end
	
	local function updatedShaderSelected(sceneNode, selected)
		if sceneNode then
			local result = sceneNode:findAllNodeByTypeTowardsLeaf({NodeId.mesh, NodeId.animatedMesh, NodeId.nodeMesh})
			for i=1, #result do
				local node = result[i]
				--node = Mesh()
				print("Node Type: "..node:getNodeType().."\n")
				local shader = node:getShader()
				if shader then
					local newShader = selected and Core.getShader(shader:getName(),"SELECTED") or Core.getShader(shader:getName())
					print("New shader fullName: "..newShader:getFullName().."\n")
					if newShader then
						node:setShader(newShader)			
					end
				end
			end
		end
	end
	
	local function isASelectedNode( node )
		for i=1, #selectedNodes do
			if selectedNodes[i] == node then
				return true
			end
		end
		return false
	end
	
	local function unselectedNodeNotInList(buildingNodes)
		for i=1, #selectedNodes do
			local isInNewList = false
			for n=1, #buildingNodes do
				if selectedNodes[i] == buildingNodes[n] then
					isInNewList = true
					n = #buildingNodes
				end
			end
			if isInNewList == false then
				updatedShaderSelected( selectedNodes[i], false )
				selectedNodes[i] = selectedNodes[#selectedNodes]
				selectedNodes[#selectedNodes] = nil
			end
		end
	end
	
	local function updateSelectedNodes(buildingNodes)
		unselectedNodeNotInList(buildingNodes)
		for i=1, #buildingNodes do
			local building = buildingNodes[i]
			
			if isASelectedNode(building) == false then
				updatedShaderSelected(building, true)
				selectedNodes[#selectedNodes+1] = building
			end
		end
	end
	
	local function removeUnbostableTower(buildingNodes)
		
		for i=1, #buildingNodes do
			local node = buildingNodes[i]
			local script = node and node:getScriptByName("tower") or nil
			local scriptBilboard = script and script:getBillboard() or nil
			if scriptBilboard and scriptBilboard:getString("Name") == "tower.shop.WallTower.name"  then
				buildingNodes[i] = buildingNodes[#buildingNodes]
				buildingNodes[#buildingNodes] = nil
				i = i-1
			end
		end
		return buildingNodes		
	end

	function self.update(visible, globalposition)
		nodeArea:setVisible(visible)
		areaEffect.update(visible, globalposition)
		
		if visible then
			local bostableNodes = removeUnbostableTower(buildNode:getAllBuildingFromPoint(globalposition, 2))
			updateSelectedNodes( bostableNodes )
		elseif #selectedNodes > 0 then
			updateSelectedNodes( {} )
		end
	end
	
	initTargetMesh()
	
	return self
end