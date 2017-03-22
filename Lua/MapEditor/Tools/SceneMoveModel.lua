--this = SceneNode()

SceneMoveModel = {}


function SceneMoveModel.create()
	
	local lines = NodeMesh()
	
	SceneMoveModel.addLine(lines, Vec3(0,0,0), Vec3(1,0,0))
	SceneMoveModel.addLine(lines, Vec3(0,0,0), Vec3(0,1,0))
	SceneMoveModel.addLine(lines, Vec3(0,0,0), Vec3(0,0,1))
	
	lines:compile()
	lines:setShader(Core.getShader("toolShader"))
	lines:setRenderLevel(10)
	lines:setBoundingSphere(Sphere(Vec3(0),1))
	
	SceneMoveModel.sceneNode = SceneNode()
	this:getRootNode():addChild(SceneMoveModel.sceneNode)
	SceneMoveModel.lineModel = lines
	
	SceneMoveModel.rightModel = SceneMoveModel.createConeMesh(Vec3(1,0,0), Vec3(1,0,0), Vec3(1.25,0,0))
	SceneMoveModel.upModel = SceneMoveModel.createConeMesh(Vec3(0,1,0), Vec3(0,1,0), Vec3(0,1.25,0))
	SceneMoveModel.atModel = SceneMoveModel.createConeMesh(Vec3(0,0,1), Vec3(0,0,1), Vec3(0,0,1.25))
	
	
	SceneMoveModel.sceneNode:addChild(SceneMoveModel.rightModel)
	SceneMoveModel.sceneNode:addChild(SceneMoveModel.upModel)
	SceneMoveModel.sceneNode:addChild(SceneMoveModel.atModel)
	SceneMoveModel.sceneNode:addChild(lines)
end

function SceneMoveModel.setVisible(visible)
	SceneMoveModel.sceneNode:setVisible(visible)
end

local function getDirectionsFromPoints(startPoint, endPoint)
	local atVec = (endPoint-startPoint):normalizeV()
	local rightVec = Vec3(1,0,0)
	
	if math.abs(atVec:dot(rightVec)) > 0.8 then
		rightVec = Vec3(0,1,0)
	end
	
	local upVec = atVec:crossProductV(rightVec):normalizeV()
	
	return rightVec, upVec, atVec
end

function SceneMoveModel.setMatrix(matrix)
	
	camera = this.getRootNode(this):findNodeByName("MainCamera")
	--camera = Camera()
	local length = (matrix:getPosition() - camera:getGlobalPosition()):length()
	matrix:setScale(Vec3(length * 0.1))
	
	SceneMoveModel.lineModel:setLocalMatrix(matrix)
	SceneMoveModel.rightModel:setLocalMatrix(matrix)
	SceneMoveModel.upModel:setLocalMatrix(matrix)
	SceneMoveModel.atModel:setLocalMatrix(matrix)
end

function SceneMoveModel.createConeMesh(color, startPoint, endPoint)
	local mesh = NodeMesh()
	
	local rightVec, upVec = getDirectionsFromPoints(startPoint, endPoint)
	local coneRadius = 0.07
	
	local oldR = 0
	local stepSize = math.pi/8
	for r=stepSize, math.pi*2+stepSize*0.5, stepSize do
		
		local i = mesh:getNumVertex()
		mesh:addPosition(startPoint + rightVec * math.cos(oldR) * coneRadius + upVec * math.sin(oldR) * coneRadius)
		mesh:addPosition(startPoint + rightVec * math.cos(r) * coneRadius + upVec * math.sin(r) * coneRadius)		
		mesh:addPosition(endPoint)
		
		for n=0,2 do
			mesh:addColor(color)
			mesh:addIndex(i+n)
		end
		
		
		
		local i = mesh:getNumVertex()
		mesh:addPosition(startPoint + rightVec * math.cos(r) * coneRadius + upVec * math.sin(r) * coneRadius)	
		mesh:addPosition(startPoint + rightVec * math.cos(oldR) * coneRadius + upVec * math.sin(oldR) * coneRadius)	
		mesh:addPosition(startPoint)
		
		for n=0,2 do
			mesh:addColor(color*0.5)
			mesh:addIndex(i+n)
		end
		
		oldR = r
	end
	
		
	mesh:compile()
	mesh:setShader(Core.getShader("toolShader"))
	mesh:setRenderLevel(10)
	mesh:setBoundingSphere(Sphere(Vec3(startPoint),(startPoint-endPoint):length()))
	
	return mesh
end

function SceneMoveModel.addLine(mesh, startPoint, endPoint)
	

	local lineWidth = (endPoint-startPoint):length() * 0.02
	local rightVec, upVec, atVec = getDirectionsFromPoints(startPoint, endPoint)
	
	local i1 = mesh:getNumVertex()
	mesh:addPosition(startPoint + upVec * lineWidth + rightVec * lineWidth + atVec * lineWidth * 0.5)
	mesh:addPosition(startPoint + upVec * lineWidth - rightVec * lineWidth + atVec * lineWidth * 0.5)
	mesh:addPosition(startPoint - upVec * lineWidth - rightVec * lineWidth + atVec * lineWidth * 0.5)
	mesh:addPosition(startPoint - upVec * lineWidth + rightVec * lineWidth + atVec * lineWidth * 0.5)
	
	local i2 = mesh:getNumVertex()
	mesh:addPosition(endPoint + upVec * lineWidth + rightVec * lineWidth)
	mesh:addPosition(endPoint + upVec * lineWidth - rightVec * lineWidth)
	mesh:addPosition(endPoint - upVec * lineWidth - rightVec * lineWidth)
	mesh:addPosition(endPoint - upVec * lineWidth + rightVec * lineWidth)
	
	for i=1, 8 do
		mesh:addColor(atVec * 0.8)
	end
	
	for i=0, 3 do
		local a = i
		local b = (i+1) % 4
		mesh:addTriangleIndex(i1 + a, i1 + b, i2 + a)
		
		mesh:addTriangleIndex(i1 + b, i2 + b, i2 + a)	
	end
end

function SceneMoveModel.collision()
	
	
	local mapEditor = Core.getBillboard("MapEditor")
	local buildAreaPanel = mapEditor:getPanel("BuildAreaPanel")
	local selectedScene =  mapEditor:getSceneNode("editScene")

	if selectedScene and buildAreaPanel == getPanelFromGlobalPos( Core.getInput():getMousePos() ) then
		local mouseLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
		local outNormal = Vec3()
		local node = SceneMoveModel.sceneNode:collisionTree(mouseLine, outNormal)
		if node then
			
			if node:toSceneNode() == SceneMoveModel.upModel:toSceneNode() then
				return true, Vec3(0,1,0)
			elseif node:toSceneNode() == SceneMoveModel.rightModel:toSceneNode() then
				return true, Vec3(1,0,0)
			elseif node:toSceneNode() == SceneMoveModel.atModel:toSceneNode() then
				return true, Vec3(0,0,1)
			end
		end
	end
	return false
end