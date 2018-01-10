--this = SceneNode()

SpawnPortalMesh = {}

function SpawnPortalMesh.createPortal(PortalSize)
	local mesh = NodeMesh.new()
	mesh:setVertexType(VertexType.position3, VertexType.uvcoord, VertexType.color4)
	
	mesh:setRenderLevel(4)
	mesh:setShader(Core.getShader("portal"))
	mesh:setTexture(Core.getShader("portal"), Core.getTexture("portal"),0)
	mesh:setTexture(Core.getShader("portal"), Core.getTexture("portal"),1)
	mesh:setColor(Vec4(1))
	mesh:setCanBeSaved(false)
	mesh:setCollisionEnabled(false)
	
		
	mesh:clearMesh();
	
	local midColor = Vec4(0,1,1,1)
	local edgeColor = Vec4(1,1,0,1)
	
	local cos = math.cos
	local sin = math.sin
	local stepSize = math.pi / 24.0
	local centerPos = Vec3(0,PortalSize.y,0)
	local index = 0
	mesh:addVertex(centerPos, Vec2(0.5, 1), midColor)
	
	for rad = stepSize, math.pi * 2 + stepSize*0.5, stepSize do
		index = mesh:getNumVertex()
		mesh:addVertex(centerPos + Vec3(cos(rad - stepSize), sin(rad - stepSize), 0) * PortalSize, Vec2(0.5, 0), edgeColor)
		mesh:addVertex(centerPos + Vec3(cos(rad), sin(rad), 0) * PortalSize, Vec2(0.5, 0), edgeColor)
		
		mesh:addIndex(0)
		mesh:addIndex(index + 0)
		mesh:addIndex(index + 1)
	end
	
	
	
	mesh:compile()
	mesh:setBoundingSphere(Sphere( centerPos, math.max(PortalSize.x, PortalSize.y,PortalSize.z)))	
	this:addChild(mesh:toSceneNode())	
	
	return mesh
end

function SpawnPortalMesh.createPortalEdge(PortalSize)
	local mesh = NodeMesh.new()
	mesh:setVertexType(VertexType.position3, VertexType.color4)
	
	mesh:setRenderLevel(4)
	mesh:setShader(Core.getShader("normalSimpleForward"))
	mesh:setColor(Vec4(1))
	mesh:setCanBeSaved(false)
	mesh:setCollisionEnabled(false)
	
		
	mesh:clearMesh();
	
	local midColor = Vec4(0,1,1,1)
	local edgeColor = Vec4(1,1,0,1)
	
	local cos = math.cos
	local sin = math.sin
	local stepSize = math.pi / 24.0
	local centerPos = Vec3(0,PortalSize.y,0)
	local pos1 = {}
	local pos2 = {}
	local index = 0
	
	for rad = stepSize, math.pi * 2 + stepSize*0.5, stepSize do
		

		pos1[1] = centerPos + Vec3(cos(rad - stepSize), sin(rad - stepSize), 0) * (PortalSize + Vec3(0.05, 0.05,0))
		pos1[2] = centerPos + Vec3(cos(rad - stepSize), sin(rad - stepSize), 0) * PortalSize 
		pos1[3] = centerPos + Vec3(cos(rad - stepSize), sin(rad - stepSize), 0) * (PortalSize  - Vec3(0.05, 0.05,0))
		
		pos1[4] = centerPos + Vec3(cos(rad), sin(rad), 0) * (PortalSize + Vec3(0.05, 0.05,0))
		pos1[5] = centerPos + Vec3(cos(rad), sin(rad), 0) * PortalSize 
		pos1[6] = centerPos + Vec3(cos(rad), sin(rad), 0) * (PortalSize  - Vec3(0.05, 0.05,0))
		
		pos2[1] = centerPos + Vec3(cos(rad - stepSize), sin(rad - stepSize), 0) * PortalSize + Vec3(0,0,0.05)
		pos2[2] = centerPos + Vec3(cos(rad - stepSize), sin(rad - stepSize), 0) * PortalSize
		pos2[3] = centerPos + Vec3(cos(rad - stepSize), sin(rad - stepSize), 0) * PortalSize - Vec3(0,0,0.05)
		
		pos2[4] = centerPos + Vec3(cos(rad), sin(rad), 0) * PortalSize + Vec3(0,0,0.05)
		pos2[5] = centerPos + Vec3(cos(rad), sin(rad), 0) * PortalSize 
		pos2[6] = centerPos + Vec3(cos(rad), sin(rad), 0) * PortalSize - Vec3(0,0,0.05)
		
		
		
		
		index = mesh:getNumVertex()
		for i=1, #pos1 do
			mesh:addVertex(pos1[i], (i==2 or i==5) and Vec4(1,1,0,0.75) or Vec4(1,1,0,0))
		end
		for i=1, #pos2 do
			mesh:addVertex(pos2[i], (i==2 or i==5) and Vec4(1,1,0,0.75) or Vec4(1,1,0,0))
		end
		
		for n=0, 1 do
			for i=0, 1 do
				mesh:addIndex(index + i + 0 + n * 6)
				mesh:addIndex(index + i + 1 + n * 6)
				mesh:addIndex(index + i + 3 + n * 6)
				
				mesh:addIndex(index + i + 3 + n * 6)
				mesh:addIndex(index + i + 1 + n * 6)
				mesh:addIndex(index + i + 4 + n * 6)
			end
		end
	end
	
	
	
	mesh:compile()
	mesh:setBoundingSphere(Sphere( centerPos, math.max(PortalSize.x, PortalSize.y,PortalSize.z)))	
	this:addChild(mesh:toSceneNode())	
	
	return mesh
end

function SpawnPortalMesh.create(PortalSize)
	return SpawnPortalMesh.createPortal(PortalSize), SpawnPortalMesh.createPortalEdge(PortalSize)
end
	