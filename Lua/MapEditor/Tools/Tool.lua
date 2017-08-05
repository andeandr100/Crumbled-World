--this = SceneNode()

Tool = {}

local camera = nil
local mapEditor = nil
local copyBufferBillboard = nil

function Tool.create()
	camera = this:getRootNode():findNodeByType(NodeId.camera)
	--camera = Camera()
	mapEditor = Core.getBillboard("MapEditor")
	buildAreaPanel = mapEditor:getPanel("BuildAreaPanel")
	
--	oldMousePos = Vec2()
	mouseDownPos = Vec2()
	selectedAreaSprite = mapEditor:getScene2DNode("selectedArea")
	
	--Overide the deActivated event and add a a local function
	superDeActivated = deActivated
	deActivated = Tool.deactivated
	Tool.enableChangeOfSelectedScene = true
	
	
	copyBufferBillboard = Core.getGlobalBillboard("copyBuffer")
	
	selectState = 0	
end

function Tool.deactivated()
	superDeActivated()
	print("Overide deactivation\n")
	if selectedAreaSprite then
		selectedAreaSprite:setVisible(false)
		selectState = 0
	end
end

local function setMoveTool()
	print("setMoveTool 1\n")
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	print("setMoveTool 2\n")
	if toolManager then
		print("setMoveTool 3\n")
		toolManager:setToolScript("MapEditor/Tools/SceneMoveTool.lua")
		print("setMoveTool 4\n")
	end
	print("setMoveTool Done\n")
end

local function selectNode(sceneNode)
	if sceneNode then
		local result = sceneNode:findAllNodeByTypeTowardsLeaf({NodeId.islandMesh, NodeId.mesh, NodeId.animatedMesh, NodeId.nodeMesh})
		for i=1, #result do
			local node = result[i]
			print("Node Type: "..node:getNodeType().."\n")
			local shader = node:getShader()
			if shader then
				local newShader = Core.getShader(shader:getName(),"SELECTED")
				print("New shader fullName: "..newShader:getFullName().."\n")
				if newShader then
					node:setShader(newShader)			
				end
			end
		end
	end
end

local function deSelectSceneNode(sceneNode)
	if sceneNode then
		local result = sceneNode:findAllNodeByTypeTowardsLeaf({NodeId.islandMesh, NodeId.mesh, NodeId.nodeMesh})
		for i=1, #result do
			--print("Node Type: "..result[i]:getNodeType().."\n")
			local shader = result[i]:getShader()
			if shader then 
				local newShader = Core.getShader(shader:getName())
				print("New shader fullName: "..newShader:getFullName().."\n")
				if newShader then
					result[i]:setShader(newShader)			
				end
			end
		end
	end
end

--Clear all selected nodes
function Tool.clearSelectedNodes()
	local selectedNodes = Tool.getSelectedSceneNodes()
	for i=1, #selectedNodes do
		deSelectSceneNode(selectedNodes[i])
	end
	Tool.saveSelectedScene({})
	
end

function Tool.saveSelectedScene(selectedNodes)
	local previousNumScene = mapEditor:getInt("numSelectedScene")
	mapEditor:setInt("numSelectedScene", #selectedNodes)
	for i=1, #selectedNodes do
		mapEditor:setSceneNode("selectedScene"..tostring(i), selectedNodes[i])
	end
	for i=#selectedNodes+1, previousNumScene do
		mapEditor:setSceneNode("selectedScene"..tostring(i), nil)
	end
end

--try to add a sceneNode or deselect the node if its allready added
function Tool.addSelectedScene(sceneNode)
	local selectedScenes = Tool.getSelectedSceneNodes()
	--Try to deselect the sceneNode
	for i=1, #selectedScenes do
		if selectedScenes[i] == sceneNode then
			--deselect node
			deSelectSceneNode(sceneNode)
			
			selectedScenes[i] = selectedScenes[#selectedScenes]
			table.remove(selectedScenes,#selectedScenes)
			Tool.saveSelectedScene(selectedScenes)

			return
		end
	end

	--Check if the node is allready selected
	local tmpSceneNode = sceneNode
	while tmpSceneNode do
		for i=1, #selectedScenes do
			if selectedScenes[i] == tmpSceneNode then
				--The node is allready added in a sub node
				return
			end
		end
		tmpSceneNode = tmpSceneNode:getParent()
	end
	
	--Deselect nodes that has the new added node as a parent
	for i=1, #selectedScenes do
		local tmpSceneNode = selectedScenes[i]
		while tmpSceneNode do
			if sceneNode == tmpSceneNode then
				--this node will be selected by the newly added node
				deSelectSceneNode(sceneNode)		
				selectedScenes[i] = selectedScenes[#selectedScenes]
				table.remove(selectedScenes,#selectedScenes)
				i = i - 1
				tmpSceneNode = nil
			else
				tmpSceneNode = tmpSceneNode:getParent()
			end
		end
	end
	
	
	--The node needs to be added 
	selectNode(sceneNode)
	selectedScenes[#selectedScenes+1] = sceneNode
	Tool.saveSelectedScene(selectedScenes)
end

function Tool.getCollision(collisionAgainsObject, collisionAgainsSpace)
	local selectedScene =  mapEditor:getSceneNode("editScene")

	if selectedScene and buildAreaPanel == Form.getPanelFromGlobalPos( Core.getInput():getMousePos() ) then
		local mouseLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
		local outNormal = Vec3()
		local collisionNode = nil
		local collisionPos = Vec3()
		
		if collisionAgainsObject then
			collisionNode = selectedScene:collisionTree( mouseLine, outNormal)
		else
			collisionNode = selectedScene:collisionTree( mouseLine, outNormal, {NodeId.islandMesh} )
		end
		
		if collisionNode then
			if collisionNode:getNodeType() == NodeId.islandMesh then
				collisionNode = collisionNode:findNodeByTypeTowardsRoot(NodeId.island)
			elseif collisionNode:getNodeType() == NodeId.mesh or collisionNode:getNodeType() == NodeId.animatedMesh then
				collisionNode = collisionNode:findNodeByTypeTowardsRoot(NodeId.model)
			end
		end
		
		if collisionNode then
			--Core.addDebugSphere(Sphere(mouseLine.endPos, 0.1), 0.01, Vec3(1))
			--Core.addDebugLine(mouseLine.endPos, mouseLine.endPos + outNormal, 0.01, Vec3(0,1,0))
			return collisionNode, mouseLine.endPos, outNormal:normalizeV()
		elseif collisionAgainsSpace and Collision.lineSegmentPlaneIntersection(collisionPos, mouseLine, Vec3(0,1,0), Vec3(0))then
			local closestIsland = nil
			local closestDist = nil
			--Core.addDebugSphere(Sphere(collisionPos, 1.0),0, Vec3(1,0,0))
			ilands = selectedScene:getRootNode():findAllNodeByTypeTowardsLeaf(NodeId.island)					
			for i=1, #ilands do
				local island = ilands[i]
				--island = Island()
				local point = Vec3(collisionPos)
				local dist = island:getDistanceToIsland(point)
				if not closestIsland or dist < closestDist then
					--print("collision found\n")
					closestIsland = island
					closestDist = dist
				end
			end
			--Core.addDebugSphere(Sphere(collisionPos, 0.9),0, Vec3(0,1,0))
			return closestIsland, collisionPos, Vec3(0,1,0)

		else
			return nil, Vec3(), Vec3()
		end
	end
	
	return nil, Vec3(), Vec3()
end

function Tool.trySelectNewScene(changeTool)
	if Core.getInput():getMouseDown( MouseKey.left ) and buildAreaPanel == Form.getPanelFromGlobalPos( Core.getInput():getMousePos() ) then
		print("mouseDown\n")
		mouseDownPos = Core.getInput():getMousePos()
		selectState = 1
	elseif Core.getInput():getMouseHeld(MouseKey.left) and ( selectState == 1 or selectState == 2) then
		--Render select area, blue sprite
		selectState = 2
		local mousePos = Core.getInput():getMousePos()

		if (mousePos-mouseDownPos):length() > 8 then
		
			if not selectedAreaSprite then
				selectedAreaSprite = Sprite(Vec4(0.2,0.2,1,0.5))
				camera:add2DScene(selectedAreaSprite)
				mapEditor:setScene2DNode("selectedArea", selectedAreaSprite)	
--				print("Selected area visible")
			else
				selectedAreaSprite:setVisible(true)
--				print("Selected area visible")
			end

			local minPos = Vec2(mouseDownPos)
			minPos:minimize( mousePos )
			local maxPos = Vec2(mouseDownPos)
			maxPos:maximize( mousePos )
			
			minPos = Vec2(math.round(minPos.x), math.round(minPos.y))
			maxPos = Vec2(math.round(maxPos.x), math.round(maxPos.y))
			
			selectedAreaSprite:setPosition(minPos)
			selectedAreaSprite:setSize(maxPos-minPos)
			
--			if (oldMousePos-mouseDownPos):length() > 2 then
--				oldMousePos = mouseDownPos
--				print("position: "..minPos.x..", "..minPos.y)
--				print("size: "..(maxPos-minPos).x..", "..(maxPos-minPos).y)
--			end
		end
		
	elseif Core.getInput():getMousePressed(MouseKey.left) and selectState == 2 then
		selectState = 0
		if selectedAreaSprite then
			selectedAreaSprite:setVisible(false)
--			print("Selected area hidden")
		end
		local mousePos = Core.getInput():getMousePos()
		if (mousePos-mouseDownPos):length() > 8 then
			print("Select area\n")
			local corner1 = camera:getWorldLineFromScreen(mouseDownPos).endPos
			local corner2 = camera:getWorldLineFromScreen(Vec2(mousePos.x,mouseDownPos.y)).endPos
			local corner3 = camera:getWorldLineFromScreen(mousePos).endPos
			local corner4 = camera:getWorldLineFromScreen(Vec2(mouseDownPos.x, mousePos.y)).endPos
			local frustrum = Frustrum( camera:getGlobalPosition(), corner1, corner2, corner3, corner4)
			
			local playerNode = this:getRootNode():findNodeByType(NodeId.playerNode)
			local nodeList = playerNode:collisionTree(frustrum, {NodeId.mesh})
			if #nodeList ~= 0 then			
				if not Core.getInput():getKeyHeld(Key.lctrl) then
					Tool.clearSelectedNodes()
				end
				
				local selectedModels = {}
				for i=1, #nodeList do
					local modelNode = nodeList[i]:findNodeByTypeTowardsRoot(NodeId.model)
					
					local  added = false
					for n=1, #selectedModels do
						if selectedModels[n] == modelNode then
							added = true
						end
					end
					if not added then
						selectedModels[#selectedModels + 1] = modelNode
						Tool.addSelectedScene(modelNode)
					end
				end
				if ( changeTool == nil or changeTool == true ) then
					setMoveTool()
				end
			end
		else
			local sceneNode = Tool.getCollision(true,false)
		
			if sceneNode and sceneNode:getNodeType() == NodeId.mesh then
				sceneNode = sceneNode:findNodeByTypeTowardsRoot(NodeId.model)
				--disclaimer this will not work when we have the mesh parent model as edit node
			end
		
			
			if not Core.getInput():getKeyHeld(Key.lctrl) then
				Tool.clearSelectedNodes()
			end
			
			Tool.addSelectedScene( sceneNode )
			
			if sceneNode and ( changeTool == nil or changeTool == true ) then
				setMoveTool()
			end
		end
		local selectedNodes = Tool.getSelectedSceneNodes()
	end
end

function Tool.tryChangeTool()
	if buildAreaPanel == Form.getPanelFromGlobalPos( Core.getInput():getMousePos() ) and mapEditor:getInt("numSelectedScene") > 0 then
		toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
		if toolManager then
			if Core.getInput():getKeyDown( Key.t ) then
				toolManager:setToolScript("MapEditor/Tools/SceneScaleTool.lua")
			elseif Core.getInput():getKeyDown( Key.r ) then
				toolManager:setToolScript("MapEditor/Tools/SceneRotateTool.lua")
			elseif Core.getInput():getKeyDown( Key.g ) or Core.getInput():getKeyDown( Key.m ) then
				toolManager:setToolScript("MapEditor/Tools/SceneMoveTool.lua")
			end
		end
	end
end

function Tool.getSelectedSceneNodes()
	local out = {}
	local numSelectedNodes = mapEditor:getInt("numSelectedScene")
	for i=1, numSelectedNodes do
		out[i] = mapEditor:getSceneNode("selectedScene"..tostring(i))
	end
	return out
end

function Tool.getSelectedNodesMatrix(selectedScenesNodes)
	if #selectedScenesNodes == 0 then
		return Matrix()
	elseif #selectedScenesNodes == 1 then
		return selectedScenesNodes[1]:getGlobalMatrix()
	else
		local centerPos = Vec3()
		for i=1, #selectedScenesNodes do
			centerPos = centerPos + selectedScenesNodes[i]:getGlobalPosition()
		end
		centerPos = centerPos / #selectedScenesNodes
		return Matrix(centerPos)
	end
end

function Tool.update()

	
	if Core.getInput():getMouseDown( MouseKey.right ) then
		toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
		if toolManager then
			toolManager:setToolScript("MapEditor/Tools/SceneSelectTool.lua")
		end
		
		print("Deselect nodes\n")
		
		
		local selectedNodes = Tool.getSelectedSceneNodes()
		for i=1, #selectedNodes do
			deSelectSceneNode(selectedNodes[i])
		end
		mapEditor:setInt("numSelectedScene",0)
	end
	if Core.getInput():getKeyHeld(Key.lctrl) and Core.getInput():getKeyDown(Key.h) then
		if showDebugModels==nil then
			showDebugModels = false
		else
			showDebugModels = not showDebugModels
		end
		local nodeList = this:getRootNode():findAllNodeByNameTowardsLeaf("*debug*")
		for i=1, #nodeList, 1 do
			nodeList[i]:setVisible(showDebugModels)
		end
	end
	
	if Tool.enableChangeOfSelectedScene then
		
		if Core.getInput():getKeyDown(Key.delete) then
			local selectedScene =  Tool.getSelectedSceneNodes()
			Tool.clearSelectedNodes()
			
			for i=1, #selectedScene do
				selectedScene[i]:destroy()
			end
			
		end
		
		if Core.getInput():getKeyHeld(Key.lctrl) then
			
			local selectedScene =  Tool.getSelectedSceneNodes()
			if selectedScene and Core.getInput():getKeyDown(Key.c)then
				copyBufferBillboard:setInt("numBuffers", #selectedScene)
				local globalCenterPos = Vec3()
				for i=1, #selectedScene do
					globalCenterPos = globalCenterPos + selectedScene[i]:getGlobalPosition()
				end
				local globalMatrixOffset = Matrix(globalCenterPos / #selectedScene)
				globalMatrixOffset:inverse()
				
				for i=1, #selectedScene do
					selectedScene[i]:saveScene("Data/Dynamic/tmpbuffer/scenes/sceneCopyBuffer"..i)
					copyBufferBillboard:setBool("isBufferAIsland"..i, selectedScene[i]:findNodeByTypeTowardsLeafe(NodeId.island) ~= nil )
					copyBufferBillboard:setMatrix("LocalMatrix"..i, globalMatrixOffset * selectedScene[i]:getGlobalMatrix());
				end
				
			elseif selectedScene and Core.getInput():getKeyDown(Key.v) then
				
				local node, globalPosition = Tool.getCollision(false, true)
				local parentNode = node:findNodeByTypeTowardsRoot(NodeId.island) and node:findNodeByTypeTowardsRoot(NodeId.island) or node:findNodeByTypeTowardsRoot(NodeId.playerNode)
				local offsetLocalPos = parentNode:getGlobalMatrix():inverseM() * globalPosition
				
				if parentNode then
					Tool.clearSelectedNodes()
					
					local numBuffers = copyBufferBillboard:getInt("numBuffers")
					for i=1, numBuffers do
	
						if copyBufferBillboard:getBool("isBufferAIsland"..i) and parentNode:getNodeType() ~= NodeId.playerNode then
							local playerNode = parentNode:findNodeByType(NodeId.playerNode)
							if playerNode then
								local node = parentNode:loadScene("Data/Dynamic/tmpbuffer/scenes/sceneCopyBuffer"..i)
								node:setLocalMatrix( copyBufferBillboard:getMatrix("LocalMatrix"..i))
								node:setLocalPosition( node:getLocalPosition() + globalPosition )
								Tool.addSelectedScene( node )
							else
								print("player node was not found the copy buffer is ignored")
							end
							
						else
							local node = parentNode:loadScene("Data/Dynamic/tmpbuffer/scenes/sceneCopyBuffer"..i)
							node:setLocalMatrix( copyBufferBillboard:getMatrix("LocalMatrix"..i))
							node:setLocalPosition( node:getLocalPosition() + offsetLocalPos )
							Tool.addSelectedScene( node )
						end
						
					end
				end
			end
			
			if #selectedScene and #selectedScene > 0 then
				if Core.getInput():getKeyDown(Key.d) then
					Tool.clearSelectedNodes()
					copyBufferBillboard:setInt("numBuffers", 0)
					for i=1, #selectedScene do
						selectedScene[i]:saveScene("Data/Dynamic/tmpbuffer/scenes/sceneCopyBuffer")
						Tool.addSelectedScene( selectedScene[i]:getParent():loadScene("Data/Dynamic/tmpbuffer/scenes/sceneCopyBuffer") )
					end
				end
				
				if Core.getInput():getKeyHeld(Key.lshift) and Core.getInput():getKeyDown(Key.j) then
					Tool.clearSelectedNodes()
					
					if #selectedScene == 1 then
						
						local meshes = selectedScene[1]:findAllNodeByTypeTowardsLeaf({NodeId.mesh, NodeId.animatedMesh})
						local parentNode = selectedScene[1]:getParent()
						local invParentMatrix = parentNode:getGlobalMatrix():inverseM()
						
						for i=1, #meshes do
							local model = Model()
							parentNode:addChild(model)
							model:setLocalMatrix(invParentMatrix * meshes[i]:getGlobalMatrix())
							meshes[i]:setLocalMatrix(Matrix())
							model:addChild(meshes[i])
							Tool.addSelectedScene(model)
						end
						--destroy remaining nodes
						selectedScene[1]:destroy()
					end
				elseif Core.getInput():getKeyDown(Key.j) then
					local model = Model()
					selectedScene[1]:getParent():addChild(model)
					local globalCenterPos = selectedScene[1]:getGlobalPosition()
					for i=2, #selectedScene do
						globalCenterPos = globalCenterPos + selectedScene[i]:getGlobalPosition()
					end
					globalCenterPos = globalCenterPos / #selectedScene
					model:setLocalPosition( model:getGlobalMatrix():inverseM() * globalCenterPos )
					local inverseModelMatrix = model:getGlobalMatrix():inverseM()
					
					for i=1, #selectedScene do
						local nodes = selectedScene[i]:getChildNodes()
						for n=1, #nodes do
							local matix = nodes[n]:getGlobalMatrix()
							nodes[n]:setLocalMatrix(inverseModelMatrix * matix)
							model:addChild(nodes[n])
						end
						selectedScene[i]:destroy()
					end
					
					Tool.clearSelectedNodes()
					Tool.addSelectedScene(model)
				end
			end
		end
		
		--Render the selected scene
	--	local selectedScene = mapEditor:getSceneNode("selectedScene1")
	--	if selectedScene then
	--		Core.addDebugBox(selectedScene:getGlobalBoundingBox(), 0.0, Vec3(0.8))
	--	end
	end
end