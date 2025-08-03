--this = SceneNode()

TargetAreaEffect = {}
function TargetAreaEffect.new(shaderName)
	local self = {}
	local mesh
	local slowFieldShader = Core.getShader(shaderName)
	local texture = Core.getTexture("portal")

	function self.hiddeTargetMesh()
		mesh:setVisible(false)
	end
	
	function self.getSceneNode()
		return mesh:toSceneNode()
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
	
	function self.setUniform(uniformName, value)
		mesh:setUniform(slowFieldShader, uniformName, value)
	end
	
	local function initTargetMesh()
		--Sphere
		mesh = NodeMesh.new()
		mesh:setRenderLevel(6)
		
		buildTargetAreaMesh(mesh)
		mesh:setShader(slowFieldShader)
		mesh:setTexture(slowFieldShader, texture, 0 )
		mesh:setUniform(slowFieldShader, "ScreenSize", Core.getRenderResolution())
		mesh:setUniform(slowFieldShader, "CenterPosition", Vec3(0,100,0))
		mesh:setUniform(slowFieldShader, "Radius", 3)
		mesh:setUniform(slowFieldShader, "effectColor", Vec3(1,0.1,0.1))
		mesh:setVisible(false)
		
		self.hiddeTargetMesh()
	end
	
	
	local function updateModel(globalposition)
		mesh:setBoundingSphere(Sphere(globalposition, 4.0))
		mesh:setUniform(slowFieldShader, "CenterPosition", globalposition)
	end
	
	function self.update(visible, globalposition)
		mesh:setVisible(visible)
		
		updateModel( globalposition)
	end
	
	initTargetMesh()
	
	return self
end