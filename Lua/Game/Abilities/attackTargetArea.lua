--this = SceneNode()

AttackArea = {}
function AttackArea.new()
	local self = {}
	local mesh
	local slowFieldShader = Core.getShader("attackTargetArea")
	local texture = Core.getTexture("gas.tga")

	local nodeArea = SceneNode.new()
	
	

	function self.hiddeTargetMesh()
		nodeArea:setVisible(false)
		mesh:setVisible(false)
	end
	
	function self.destroyTargetMesh()
		if nodeArea then
			self.hiddeTargetMesh()
			nodeArea:destroyTree()
			nodeArea = nil
		end
	end
	
	local function buildTargetAreaMesh(mesh)
		mesh:clearMesh()
	
		mesh:addPosition( Vec3(-2,-2, -1) )
		mesh:addPosition( Vec3( 2,-2, -1) )
		mesh:addPosition( Vec3(-2, 2, -1) )
		mesh:addPosition( Vec3( 2, 2, -1) )
	
		mesh:addTriangleIndex(0,1,2)
		mesh:addTriangleIndex(2,1,3)
	
		mesh:compile()
	end
	
	local function initTargetMesh()
		--Sphere
		mesh = NodeMesh.new()
		mesh:setRenderLevel(6)
		
		buildTargetAreaMesh(mesh)
		mesh:setShader(slowFieldShader)
		mesh:setUniform(slowFieldShader, "ScreenSize", Core.getRenderResolution())
		mesh:setUniform(slowFieldShader, "CenterPosition", Vec3(0,100,0))
		mesh:setUniform(slowFieldShader, "Radius", 3)
		mesh:setUniform(slowFieldShader, "effectColor", Vec3(1,0.1,0.1))
		mesh:setVisible(false)
		nodeArea:addChild(mesh:toSceneNode())
		
		--find main camera
		local rootNode = this:getRootNode()
		rootNode:addChild(nodeArea:toSceneNode())
		mainCamera = rootNode:findNodeByName("MainCamera")
		
		self.hiddeTargetMesh()
	end
	
	
	local function updateModel(globalposition)
		mesh:setBoundingSphere(Sphere(globalposition, 4.0))
		mesh:setUniform(slowFieldShader, "CenterPosition", globalposition)
	end
	
	function self.update(visible, globalposition)
		nodeArea:setVisible(visible)
		mesh:setVisible(visible)
		
		updateModel( globalposition)
	end
	
	initTargetMesh()
	
	return self
end