--this = SceneNode()
MineEntrance = {}

function MineEntrance.create(mineNode, localMatrix)
	local mesh = NodeMesh()
	
	mesh:addPosition(Vec3(-1.3,0,0))
	mesh:addPosition(Vec3(-1.3,3.4,0))
	mesh:addPosition(Vec3( 1.15,3.4,0))
	mesh:addPosition(Vec3( 1.15,0,0))
	
	mesh:addTriangleIndex(0,1,2)
	mesh:addTriangleIndex(2,0,3)
	
	

	local mineEntranceShader = Core.getShader("mineEntrance")

	mineNode:addChild(mesh)
	
	mesh:setBoundingSphere(Sphere(Vec3(0,1.5,0), 2.0))
	mesh:setShader(mineEntranceShader)
	mesh:setUniform(mineEntranceShader, "ScreenSize", Core.getRenderResolution())
	mesh:setColor(Vec4(1))
	mesh:setRenderLevel(4)
	mesh:setLocalMatrix(localMatrix)
	mesh:compile()
end