--this = SceneNode()

SceneScaleModel = {}


function SceneScaleModel.create()
	
	local lines = NodeMesh()
	
	local blockSize = 0.2
	SceneScaleModel.addLine(lines, Vec3(blockSize*0.5,0,0), Vec3(1,0,0))
	SceneScaleModel.addLine(lines, Vec3(0,blockSize*0.5,0), Vec3(0,1,0))
	SceneScaleModel.addLine(lines, Vec3(0,0,blockSize*0.5), Vec3(0,0,1))
	
	lines:compile()
	lines:setShader(Core.getShader("toolShader"))
	lines:setRenderLevel(10)
	lines:setBoundingSphere(Sphere(Vec3(0),1))
	
	SceneScaleModel.sceneNode = SceneNode()
	this:getRootNode():addChild(SceneScaleModel.sceneNode)
	SceneScaleModel.lineModel = lines
	
	
	SceneScaleModel.rightModel = SceneScaleModel.createBoxMesh(Vec3(1,0,0), Vec3(1,0,0), Vec3(1+blockSize,0,0))
	SceneScaleModel.upModel = SceneScaleModel.createBoxMesh(Vec3(0,1,0), Vec3(0,1,0), Vec3(0,1+blockSize,0))
	SceneScaleModel.atModel = SceneScaleModel.createBoxMesh(Vec3(0,0,1), Vec3(0,0,1), Vec3(0,0,1+blockSize))
	SceneScaleModel.centerModel = SceneScaleModel.createBoxMesh(Vec3(0.8,0.8,0.8), Vec3(0,-blockSize*0.5,0), Vec3(0,blockSize*0.5,0))
	
	
	SceneScaleModel.sceneNode:addChild(SceneScaleModel.rightModel)
	SceneScaleModel.sceneNode:addChild(SceneScaleModel.upModel)
	SceneScaleModel.sceneNode:addChild(SceneScaleModel.atModel)
	SceneScaleModel.sceneNode:addChild(SceneScaleModel.centerModel)
	SceneScaleModel.sceneNode:addChild(lines)
end

function SceneScaleModel.setVisible(visible)
	SceneScaleModel.sceneNode:setVisible(visible)
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

function SceneScaleModel.setMatrix(matrix)
	
	camera = this.getRootNode(this):findNodeByName("MainCamera")
	--camera = Camera()
	local length = (matrix:getPosition() - camera:getGlobalPosition()):length()
	matrix:setScale(Vec3(length * 0.1))
	--matrix:setScale(Vec3(5))
	
	SceneScaleModel.lineModel:setLocalMatrix(matrix)
	SceneScaleModel.rightModel:setLocalMatrix(matrix)
	SceneScaleModel.upModel:setLocalMatrix(matrix)
	SceneScaleModel.atModel:setLocalMatrix(matrix)
	SceneScaleModel.centerModel:setLocalMatrix(matrix)
end

function SceneScaleModel.createBoxMesh(color, startPoint, endPoint)
	local mesh = NodeMesh()
	
	local centerPos = (startPoint + endPoint) * 0.5
	local rightVec, upVec, atVec = getDirectionsFromPoints(startPoint, endPoint)
	local width = (centerPos - endPoint):length()
	
	local sideColor = color
	
	for side = 1, 6 do
		local center = centerPos
		if side == 1 then center = center + Vec3(width,0,0) end
		if side == 2 then center = center + Vec3(-width,0,0) end
		if side == 3 then center = center + Vec3(0,0,width) end
		if side == 4 then center = center + Vec3(0,0,-width) end
		if side == 5 then center = center + Vec3(0,width,0) end
		if side == 6 then center = center + Vec3(0,-width,0) end
		
		if atVec:dot((center-centerPos):normalizeV()) < -0.9 then
			sideColor = color * 0.5
		elseif atVec:dot((center-centerPos):normalizeV()) > 0.9 then
			sideColor = color * 0.75
		elseif math.abs(rightVec:dot((center-centerPos):normalizeV())) > 0.9 then
			sideColor = color * 0.9
		else
			sideColor = color
		end
		
		local rightVec = Vec3()
		local upVec = Vec3()
		
		if side >= 1 and side <= 4 then
			rightVec = (center - centerPos):crossProductV(Vec3(0,1,0)):normalizeV()
			upVec = (center - centerPos):crossProductV(rightVec):normalizeV()
		else
			rightVec = (center - centerPos):crossProductV(Vec3(1,0,0)):normalizeV()
			upVec = (center - centerPos):crossProductV(rightVec):normalizeV()
		end
		
		local i = mesh:getNumVertex()
		mesh:addPosition( center + rightVec * width + upVec * width )
		mesh:addPosition( center + rightVec * width - upVec * width )
		mesh:addPosition( center - rightVec * width - upVec * width )
		mesh:addPosition( center - rightVec * width + upVec * width )
		
		for n=1, 4 do
			mesh:addColor(sideColor)
		end
		
		mesh:addTriangleIndex(i + 0, i + 2, i + 1)
--		mesh:addIndex(i + 0)
--		mesh:addIndex(i + 2)
--		mesh:addIndex(i + 1)
		
		mesh:addTriangleIndex(i + 0, i + 3, i + 2)
--		mesh:addIndex(i + 0)
--		mesh:addIndex(i + 3)
--		mesh:addIndex(i + 2)	
	end
		
	mesh:compile()
	mesh:setShader(Core.getShader("toolShader"))
	mesh:setRenderLevel(10)
	mesh:setBoundingSphere(Sphere(Vec3(startPoint),(startPoint-endPoint):length()))
	
	return mesh
end

function SceneScaleModel.addLine(mesh, startPoint, endPoint)
	

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

function SceneScaleModel.collision()
	
	local mapEditor = Core.getBillboard("MapEditor")
	local buildAreaPanel = mapEditor:getPanel("BuildAreaPanel")
	local selectedScene =  mapEditor:getSceneNode("editScene")

	if selectedScene and buildAreaPanel == getPanelFromGlobalPos( Core.getInput():getMousePos() ) then

		local mouseLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
		local outNormal = Vec3()
		local node = SceneScaleModel.sceneNode:collisionTree(mouseLine, outNormal)
		if node then
			
			if node:toSceneNode() == SceneScaleModel.upModel:toSceneNode() then
				return true, Vec3(0,1,0)
			elseif node:toSceneNode() == SceneScaleModel.rightModel:toSceneNode() then
				return true, Vec3(1,0,0)
			elseif node:toSceneNode() == SceneScaleModel.atModel:toSceneNode() then
				return true, Vec3(0,0,1)
			elseif node:toSceneNode() == SceneScaleModel.centerModel:toSceneNode() then
				return true, Vec3(1,1,1)
			end
		end
	end
	return false
end