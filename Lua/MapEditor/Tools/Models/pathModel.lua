--this = SceneNode()

PathModel = {}
function PathModel.new(inParentNode, inColor)
	--inParentNode = SceneNode.new()
	local self = {}
	local mesh = NodeMesh.new()
	local color = inColor
	local s = 2
	local w = 0.1
	local boxSize = Vec3()
	local boxWidth = 0
	
	function self.setVisible(visible)
		mesh:setVisible(visible)
	end
	
	function self.setPosition(globalPos)
		mesh:setLocalPosition(globalPos)
	end
	
	function self.collision(globalLine)
		
		local box = Box( -Vec3(boxSize.x,0, boxSize.z) - Vec3(boxWidth), Vec3(boxSize.x, boxSize.y*2, boxSize.z) + Vec3(boxWidth))
		local localLine = Line3D( mesh:getGlobalMatrix():inverseM() * globalLine.startPos, mesh:getGlobalMatrix():inverseM() * globalLine.endPos)
		local collision, position = Collision.line3DSegmentBoxIntersection( localLine, box)
		return collision, mesh:getGlobalMatrix() * position
	end
	
	function self.destroy()
		mesh:destroy()
		mesh = nil
	end
	
	function addPanel(p1, p2, at, color)
		local up = (p2-p1):normalizeV() * w
		local right = at:crossProductV(up):normalizeV() * w
		
		local index = mesh:getNumVertex()
		mesh:addVertex(p1 + up + right + at, color)
		mesh:addVertex(p1 + up + right - at, color)
		
		mesh:addVertex(p2 - up + right + at, color)
		mesh:addVertex(p2 - up + right - at, color)
		
		mesh:addIndex(index + 0)
		mesh:addIndex(index + 1)
		mesh:addIndex(index + 2)
		
		mesh:addIndex(index + 1)
		mesh:addIndex(index + 3)
		mesh:addIndex(index + 2)
	end
	
	function addSide(p1, p2, p3, p4, color, rightColor, upColor)
		local up = (p2-p1):normalizeV() * w
		local right = (p4-p1):normalizeV() * w
		local atVec = up:crossProductV(right):normalizeV() * w
		
		local index = mesh:getNumVertex()
		mesh:addVertex(p1 - up - right + atVec, color)
		mesh:addVertex(p1 + up + right + atVec, color)
		
		mesh:addVertex(p2 + up - right + atVec, color)
		mesh:addVertex(p2 - up + right + atVec, color)
		
		mesh:addVertex(p3 + up + right + atVec, color)
		mesh:addVertex(p3 - up - right + atVec, color)
		
		mesh:addVertex(p4 - up + right + atVec, color)
		mesh:addVertex(p4 + up - right + atVec, color)
		
		for i=0, 6, 2 do
			mesh:addIndex(index + (i + 0) % 8)
			mesh:addIndex(index + (i + 1) % 8)
			mesh:addIndex(index + (i + 2) % 8)
			
			mesh:addIndex(index + (i + 1) % 8)
			mesh:addIndex(index + (i + 3) % 8)
			mesh:addIndex(index + (i + 2) % 8)
		end
		
		addPanel(p1, p2, atVec, rightColor)
		addPanel(p2, p3, atVec, upColor)
		addPanel(p3, p4, atVec, rightColor)
		addPanel(p4, p1, atVec, upColor)
		
	end

	function self.setQubeSize(cubeSize, lineWidth)
		--cubeSize = Vec3()
		--lineWidth = number()
		
		boxSize = cubeSize
		boxWidth = lineWidth
		
		mesh:clearMesh()
		
		s = cubeSize
		w = lineWidth
		corner = {Vec3(-s.x,0,-s.z), Vec3(-s.x,0,s.z), Vec3(s.x,0,s.z), Vec3(s.x,0,-s.z), Vec3(-s.x,s.y*2,-s.z), Vec3(-s.x,s.y*2,s.z), Vec3(s.x,s.y*2,s.z), Vec3(s.x,s.y*2,-s.z)}
		
		local atColor = inColor
		local rightColor = inColor * 0.5
		local upColor = inColor * 0.75
		
		addSide(corner[1], corner[5], corner[8], corner[4], atColor, rightColor, upColor)
		addSide(corner[3], corner[7], corner[6], corner[2], atColor, rightColor, upColor)
		
		addSide(corner[2], corner[6], corner[5], corner[1], rightColor, atColor, upColor)
		addSide(corner[4], corner[8], corner[7], corner[3], rightColor, atColor, upColor)
		
		addSide(corner[6], corner[7], corner[8], corner[5], upColor, atColor, rightColor)
		addSide(corner[1], corner[4], corner[3], corner[2], upColor, atColor, rightColor)
		
		mesh:compile()
		mesh:setBoundingSphere(Sphere( Vec3(0,cubeSize.y,0), cubeSize:length()))
	end
	
	function init()
		mesh = NodeMesh.new()
		mesh:setVertexType(VertexType.position3, VertexType.color3)
		inParentNode:addChild(mesh:toSceneNode())	
		mesh:setRenderLevel(31)
		mesh:setShader(Core.getShader("toolNormal"))
		mesh:setColor(Vec4(1))
		mesh:setCanBeSaved(false)
		mesh:setCollisionEnabled(false)
	end

	init()
		
	return self
end