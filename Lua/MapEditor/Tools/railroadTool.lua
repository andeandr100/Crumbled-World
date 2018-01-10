require("MapEditor/Tools/Tool.lua")
require("MapEditor/menuStyle.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("MapEditor/Tools/railwaysModels.lua")
--this = SceneNode()

function createRailroadButton(data)
	local button = Button( PanelSize( Vec2(-1), Vec2(1)), "B" )
	
	local posterCamera =  Camera.new(Text("TowerCamera"), true, 200,200);
	posterCamera:setAmbientLight(AmbientLight(Vec3(0.5)))
	posterCamera:setDirectionLight(DirectionalLight(Vec3(0.5, 0.8, 0.5), Vec3(1,1,1)))
	posterCamera:setShadowScale(3.0)
	
	data.cameraModel = Model(data.model)
	data.cameraModel:addChild(posterCamera:toSceneNode())
	data.camera = posterCamera
	
	local lookAt = Vec3(0.5,1,-1) * data.offset:getPosition() * 0.5
	local rotateTime = Core.getTime() * 0.1
	local camPos = lookAt + Vec3(0,1,1):normalizeV() * 4.5
	local camMatrix = Matrix();
	camMatrix:createMatrix((camPos-lookAt):normalizeV(), Vec3(0,1.0,0))
	camMatrix:setPosition(camPos)
	posterCamera:setLocalMatrix(camMatrix)	

	posterCamera:render()
	
	button:setBackground(Sprite(posterCamera:getTexture()))
	
	button:setEdgeColor(Vec4(MainMenuStyle.borderColor), Vec4(MainMenuStyle.borderColor))
	button:setEdgeHoverColor(Vec4(MainMenuStyle.borderColor), Vec4(MainMenuStyle.borderColor))
	button:setEdgeDownColor(Vec4(MainMenuStyle.borderColor), Vec4(MainMenuStyle.borderColor))

	button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
	button:setInnerHoverColor(Vec4(Vec3(1),0.3), Vec4(Vec3(1),0.3), Vec4(Vec3(1),0.3))
	button:setInnerDownColor(Vec4(Vec3(1),0.1), Vec4(Vec3(1),0.1), Vec4(Vec3(1),0.1))
	
	button:addEventCallbackExecute(buttonClick)
	button:addEventCallbackMouseFocusGain(mouseEnterButton)
	
	--default id
	button:setTag("1")
	--find the real id
	for i=1, #railways do	
		if railways[i] == data then
			button:setTag(tostring(i))
		end
	end
	
	return button
end

function mouseEnterButton(button)
	local num = tonumber(button:getTag():toString())
	local selectedNode = getSelectedNode()
	if selectedNode then
		changeMode(num)
		railwayScene:setLocalMatrix( selectedNode:getGlobalMatrix() * railways[num].offset )
	end
end

function buttonClick(button)
	local num = tonumber(button:getTag():toString())
	
	local selectedNode = getSelectedNode()
	if selectedNode then
		local aIsland = selectedNode:findNodeByType(NodeId.island)
		local model = Model(railways[num].model)
		if aIsland then
			model:setLocalMatrix(aIsland:getGlobalMatrix():inverseM() * ( selectedNode:getGlobalMatrix() * railways[num].offset ) )
			aIsland:addChild(model:toSceneNode())
			
			Tool.clearSelectedNodes()
			Tool.addSelectedScene(model)
			
			railwayScene:setLocalMatrix( model:getGlobalMatrix() * railways[num].offset )
		end
	else
		changeMode(num)
	end
end

function createMenu(panel)
	
	local title = panel:add(Panel(PanelSize(Vec2(1,1), Vec2(1,1),PanelSizeType.ParentPercent)))
	title:setLayout(GridLayout(3,3))
	
	title:add( createRailroadButton(railways[7]) )
	title:add( createRailroadButton(railways[2]) )
	title:add( createRailroadButton(railways[8]) )
	
	title:add( createRailroadButton(railways[5]) )
	title:add( createRailroadButton(railways[1]) )
	title:add( createRailroadButton(railways[6]) )
	
	title:add( createRailroadButton(railways[3]) )
	title:add( createRailroadButton(railways[1]) )
	title:add( createRailroadButton(railways[4]) )

end

function create()
	
	print("\n\n---------------- Railroad Tool ---------------\n\n\n")
	
	Tool.create()
	Tool.enableChangeOfSelectedScene = false
	
	railways = RailwaysModels.getModelTable()
		
	railwayScene = SceneNode.new()
	this:addChild(railwayScene)
	railwayScene:setVisible(false)
	
	placeIndex = 1
	for i=1, #railways do
		railwayScene:addChild( railways[i].model:toSceneNode() )
		if i ~= placeIndex then
			railways[i].model:setVisible(false)
		end
	end
	
	
		
	--Get billboard for the map editor
	mapEditor = Core.getBillboard("MapEditor")
	--Get the setting panel
	settingsPanel = mapEditor:getPanel("SettingPanel")
	
	camera = this:getRootNode():findNodeByType(NodeId.camera)
	
	
	editorListener = Listener("Editor")
	editorListener:registerEvent("newMap", newMap)
	
	if settingsPanel then
		titlePanel, bodyPanel =  MenuStyle.createTitleAndBody(settingsPanel, "Railroad tool")
		
		--body = Panel()
		titlePanel:setVisible(false)
		createMenu(bodyPanel)
		
	else
		print("\nno settingsPanel\n\n")
		return false
	end
	
	changeMode( 1 )
	return true
end

function newMap()
	
	print("\n\nRailroad tool New World\n\n\n")

end

function activated()
	railwayScene:setVisible(true)
	titlePanel:setVisible(true)
	--check if there exist data to init
	print("activated\n")
end

function deActivated()
	railwayScene:setVisible(false)
	titlePanel:setVisible(false)
	print("Deactivated\n")
end

function mouseCollision(offset)
	local selectedScene =  mapEditor:getSceneNode("editScene")
	local screenPos = Core.getInput():getMousePos() + offset
	
	if selectedScene and buildAreaPanel == Form.getPanelFromGlobalPos( screenPos ) then
		local mouseLine = camera:getWorldLineFromScreen(screenPos)
		local outNormal = Vec3()
		local collisionNode = nil
		
		if false then
			collisionNode = selectedScene:collisionTree( mouseLine, outNormal)
		else
			collisionNode = selectedScene:collisionTree( mouseLine, outNormal, {NodeId.islandMesh} )
		end
		
		return collisionNode, outNormal, mouseLine.endPos
	end
	
	return nil, nil, nil
end

function getOffsetMatrixFromNode(sceneNode)
	for i=1, #railways do
		if sceneNode:getSceneName() == railways[i].model:getSceneName() then
			return railways[i].offset
		end
	end
	return Matrix()
end

function updateModel(selectedNode, globalPos)
	
	local offsetMatrix = getOffsetMatrixFromNode(selectedNode)
	local previousMatrix = selectedNode:getGlobalMatrix() * offsetMatrix:inverseM()
	local centerPosition = (offsetMatrix:getPosition() + previousMatrix:getPosition())*0.5
	
	local rotMatrix = Matrix()
	local selectedMatrix = selectedNode:getGlobalMatrix()
	if selectedNode:getGlobalMatrix():getAtVec():dot((globalPos - centerPosition):normalizeV() ) < 0 then
		rotMatrix:setRotation(Vec3(0,math.pi,0))
		selectedMatrix = previousMatrix
	end
	
	local finalMatrix = railwayScene:getLocalMatrix()
	local minAngle = math.pi
	local minIndex = 1
	local minDist = 100
	for i=1, #railways do
		local matrix = selectedMatrix * rotMatrix * railways[i].offset
		
		local atVec = (globalPos - matrix:getPosition()):normalizeV()
		local angle = matrix:getAtVec():angle( (globalPos - selectedMatrix:getPosition()):normalizeV() )
		
		if angle < minAngle or (angle == minAngle and minDist > (globalPos - matrix:getPosition()):length()) then
			minIndex = i
			minAngle = angle
			minDist = (globalPos - matrix:getPosition()):length()	
			finalMatrix = matrix
		end
	end
	
	railwayScene:setLocalMatrix(finalMatrix)
	changeMode( minIndex )
end

function changeMode(newModelIndex)
	if newModelIndex ~= placeIndex then
		railways[placeIndex].model:setVisible(false)
		railways[newModelIndex].model:setVisible(true)
		placeIndex = newModelIndex
	end
end

function getSelectedNode()
	local selectedNodes = Tool.getSelectedSceneNodes()
	if #selectedNodes == 1 then
		local selectedNode = selectedNodes[1]
		if selectedNode:getNodeType() == NodeId.model then
			
			for i=1, #railways do
				if selectedNode:getSceneName() == railways[i].model:getSceneName() then
					return selectedNode
				end
			end
		end
	end
	
	Tool.clearSelectedNodes()
	return nil
end

function update()
	local node, collisionPos, collisionNormal = Tool.getCollision(false)
	--node = SceneNode.new()
	if node then
		
		local selectedNode = getSelectedNode()
		
		local aIsland = node:findNodeByType(NodeId.island)
		railwayScene:setVisible(true)
		
		print("Visble")	
		
		if selectedNode then
			
			updateModel( selectedNode, collisionPos )
			
		else
			
			
			local matrix = Matrix()
			matrix:setRotation(Vec3(0, Core.getInput():getMouseWheelTicks() * 0.05, 0))
			matrix = railwayScene:getLocalMatrix() * matrix
			matrix:setPosition(collisionPos)
			railwayScene:setLocalMatrix(matrix)
		end
		
		if aIsland and Core.getInput():getMouseDown( MouseKey.left ) then
			local model = Model(railways[placeIndex].model)
			model:setLocalMatrix(aIsland:getGlobalMatrix():inverseM() * railways[placeIndex].model:getGlobalMatrix() )
			aIsland:addChild(model:toSceneNode())
			
			
			Tool.clearSelectedNodes()
			Tool.addSelectedScene(model)
		end
	end
	
	Tool.update()
	return true
end