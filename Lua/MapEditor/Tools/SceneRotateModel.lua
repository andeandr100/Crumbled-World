--this = SceneNode()

SceneRotateModel = {}


function SceneRotateModel.create()
	
	local lines = NodeMesh()
	

	SceneRotateModel.addLine(lines, Vec3(0,0,0), Vec3(1,0,0))
	SceneRotateModel.addLine(lines, Vec3(0,0,0), Vec3(0,1,0))
	SceneRotateModel.addLine(lines, Vec3(0,0,0), Vec3(0,0,1))
	
	lines:compile()
	lines:setShader(Core.getShader("toolShader"))
	lines:setRenderLevel(10)
	lines:setBoundingSphere(Sphere(Vec3(0),1))
	
	SceneRotateModel.sceneNode = SceneNode()
	this:getRootNode():addChild(SceneRotateModel.sceneNode)
	SceneRotateModel.lineModel = lines
	
	
	SceneRotateModel.xRotation = SceneRotateModel.createRing(Vec3(1,0,0), 1, 1)
	SceneRotateModel.yRotation = SceneRotateModel.createRing(Vec3(0,1,0), 2, 1)
	SceneRotateModel.zRotation = SceneRotateModel.createRing(Vec3(0,0,1), 3, 1)
	
	
	SceneRotateModel.sceneNode:addChild(SceneRotateModel.xRotation)
	SceneRotateModel.sceneNode:addChild(SceneRotateModel.yRotation)
	SceneRotateModel.sceneNode:addChild(SceneRotateModel.zRotation)
	SceneRotateModel.sceneNode:addChild(lines)
end

function SceneRotateModel.setVisible(visible)
	SceneRotateModel.sceneNode:setVisible(visible)
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

function SceneRotateModel.setMatrix(matrix)
	
	camera = this.getRootNode(this):findNodeByName("MainCamera")
	--camera = Camera()
	local length = (matrix:getPosition() - camera:getGlobalPosition()):length()
	matrix:setScale(Vec3(length * 0.1))
	--matrix:setScale(Vec3(5))
	
	SceneRotateModel.lineModel:setLocalMatrix(matrix)
	SceneRotateModel.xRotation:setLocalMatrix(matrix)
	SceneRotateModel.yRotation:setLocalMatrix(matrix)
	SceneRotateModel.zRotation:setLocalMatrix(matrix)
end

function SceneRotateModel.createRing(color, id, length)
	local mesh = NodeMesh()
	
	local rightVec = color * 0.03
	
	local stepSize = math.pi / 48
	
	local at = Vec3
	for r=0, math.pi*2+stepSize*0.5, stepSize do
		
		if id == 1 then
			at = Vec3(0,math.sin(r), math.cos(r)) * 0.995
		elseif id == 2 then
			at = Vec3(math.cos(r),0, math.sin(r)) * 1.005
		else
			at = Vec3(math.sin(r), math.cos(r), 0)
		end
		
		mesh:addPosition(at - rightVec)
		mesh:addPosition(at + rightVec)
		
		mesh:addPosition(at*1.06 + rightVec)
		mesh:addPosition(at*1.06 - rightVec)
		
		mesh:addPosition(at + rightVec)
		mesh:addPosition(at*1.06 + rightVec)
		
		mesh:addPosition(at*1.06 - rightVec)
		mesh:addPosition(at - rightVec)
		
		for i=1, 4 do
			mesh:addColor(color)
		end
		for i=1, 4 do
			mesh:addColor(color*0.7)
		end
	end
	
	local index = 0
	for r=0, math.pi*2-stepSize*0.5, stepSize do
		--bottom
		mesh:addTriangleIndex(index + 1, index + 0, index + 8 + 1)
--		mesh:addIndex(index + 1)
--		mesh:addIndex(index + 0)
--		mesh:addIndex(index + 8 + 1)
	
		mesh:addTriangleIndex(index + 0, index + 8 + 0, index + 8 + 1)	
--		mesh:addIndex(index + 0)
--		mesh:addIndex(index + 8 + 0)
--		mesh:addIndex(index + 8 + 1)
		
		--Top
		mesh:addTriangleIndex(index + 3, index + 2, index + 8 + 3)
--		mesh:addIndex(index + 3)
--		mesh:addIndex(index + 2)
--		mesh:addIndex(index + 8 + 3)
		
		mesh:addTriangleIndex(index + 2, index + 8 + 2, index + 8 + 3)
--		mesh:addIndex(index + 2)
--		mesh:addIndex(index + 8 + 2)
--		mesh:addIndex(index + 8 + 3)
		
		--Left
		mesh:addTriangleIndex(index + 5, index + 4, index + 8 + 5)
--		mesh:addIndex(index + 5)
--		mesh:addIndex(index + 4)
--		mesh:addIndex(index + 8 + 5)
		
		mesh:addTriangleIndex(index + 4, index + 8 + 4, index + 8 + 5)
--		mesh:addIndex(index + 4)
--		mesh:addIndex(index + 8 + 4)
--		mesh:addIndex(index + 8 + 5)
		
		--Right
		mesh:addTriangleIndex(index + 7, index + 6, index + 8 + 7)
--		mesh:addIndex(index + 7)
--		mesh:addIndex(index + 6)
--		mesh:addIndex(index + 8 + 7)
		
		mesh:addTriangleIndex(index + 6, index + 8 + 6, index + 8 + 7)
--		mesh:addIndex(index + 6)
--		mesh:addIndex(index + 8 + 6)
--		mesh:addIndex(index + 8 + 7)
		
		
		index = index + 8
	end
	
		
	mesh:compile()
	mesh:setShader(Core.getShader("toolShader"))
	mesh:setRenderLevel(10)
	mesh:setBoundingSphere(Sphere(Vec3(0),1.2))
	
	return mesh
end


function SceneRotateModel.addLine(mesh, startPoint, endPoint)
	

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
--		mesh:addIndex(i1 + a)
--		mesh:addIndex(i1 + b)
--		mesh:addIndex(i2 + a)
		
		mesh:addTriangleIndex(i1 + b, i2 + b, i2 + a)
--		mesh:addIndex(i1 + b)
--		mesh:addIndex(i2 + b)
--		mesh:addIndex(i2 + a)	
	end
end

function SceneRotateModel.collision()

	local mapEditor = Core.getBillboard("MapEditor")
	local buildAreaPanel = mapEditor:getPanel("BuildAreaPanel")
	local selectedScene =  mapEditor:getSceneNode("editScene")

	if selectedScene and buildAreaPanel == getPanelFromGlobalPos( Core.getInput():getMousePos() ) then
		local mouseLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
		local outNormal = Vec3()
		local node = SceneRotateModel.sceneNode:collisionTree(mouseLine, outNormal)
		if node then
			if node:toSceneNode() == SceneRotateModel.xRotation:toSceneNode() then
				return true, Vec3(1,0,0)
			elseif node:toSceneNode() == SceneRotateModel.yRotation:toSceneNode() then
				return true, Vec3(0,1,0)
			elseif node:toSceneNode() == SceneRotateModel.zRotation:toSceneNode() then
				return true, Vec3(0,0,1)
			end
		end
	end
	return false
end