--this = SceneNode()

slowFieldTargetArea = {}
function slowFieldTargetArea.new()
	local self = {}
	local mesh
	local slowFieldShader = Core.getShader("slowfield")
	local texture = Core.getTexture("portal")
	local particleEffect = GraphicParticleSystem.new(15,3)
	
	--particle_effects_D

	local nodeArea = SceneNode.new()
	
	local electric = {}
	local timeBettwenLightning = 0
	

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
		nodeArea:addChild(mesh:toSceneNode())
		buildTargetAreaMesh(mesh)
		mesh:setShader(slowFieldShader)
		mesh:setTexture(slowFieldShader, texture, 0 )
		mesh:setUniform(slowFieldShader, "ScreenSize", Core.getRenderResolution())
		mesh:setUniform(slowFieldShader, "CenterPosition", Vec3(0,100,0))
		mesh:setUniform(slowFieldShader, "Radius", 3.5)
		mesh:setUniform(slowFieldShader, "effectColor", Vec3(0.1,0.1,1))
		
		
		local shader = Core.getShader("ParticleEffectSlowField")
		particleEffect:setShader(shader)
		particleEffect:setRenderBlendMode(GL_Blend.SRC_ALPHA, GL_Blend.ONE)
		for i=1, particleEffect:getMaxParticles() do 
			particleEffect:addparticle( Vec3(math.randomFloat(-1,1),0,math.randomFloat(-1,1)):normalizeV() * math.randomFloat(0,3.5) + Vec3(0,0.1,0),Vec3(),Vec2(0.75,0), Vec4(0.80,1.20,2.00,0.9), Vec4(0.42,0.65,1.00,-1.5), 0.05, 2, i/particleEffect:getMaxParticles() )
		end
		particleEffect:compile()
		nodeArea:addChild(particleEffect:toSceneNode())
		
		
		nodeArea:setVisible(false)
		mesh:setVisible(false)
		
		--find main camera
		local rootNode = this:getRootNode()
		rootNode:addChild(nodeArea:toSceneNode())
		mainCamera = rootNode:findNodeByName("MainCamera")
		
		
		for i=1, 6 do
			electric[i] = ParticleEffectElectricFlash.new("Lightning_D.tga")
			nodeArea:addChild(electric[i]:toSceneNode())
		end
		
		self.hiddeTargetMesh()
	end
	
	
	local function updateModel(globalposition)
		mesh:setBoundingSphere(Sphere(globalposition, 4.0))
		mesh:setUniform(slowFieldShader, "CenterPosition", globalposition)
	end
	
	local function getRandomElectricAttackPos(centerPos)
		local offsetDir = Vec3(math.randomFloat(-1,1), 0.1, math.randomFloat(-1,1) ):normalizeV()
		return centerPos + offsetDir * math.randomFloat(2,3.5)
	end
	
	function self.update(visible, globalposition, active)
		nodeArea:setVisible(visible)
		mesh:setVisible(visible)
		
		if visible then
			particleEffect:setLocalPosition(globalposition)
--			Core.addDebugSphere(particleEffect:getGlobalBoundingSphere(),0.1,Vec3(1))
--			Core.addDebugSphere(Sphere(globalposition,0.2),0.1,Vec3(1))
		end
		
		if active then
--			print("Active - slowField")
			
			
			timeBettwenLightning = timeBettwenLightning - Core.getDeltaTime()
			for i=1, #electric do
					
				if electric[i]:getTimer() < 0.01 and timeBettwenLightning < 0 then
--					print("electric " .. i .. ": Creating electric effect")
--					local localSphere = Sphere(this:getGlobalMatrix():inverseM()*globalposition,3.5)
					if false then
						local lightningTime = 0.5
						local startPos = getRandomElectricAttackPos(globalposition)
						local endPos = getRandomElectricAttackPos(globalposition)
						while (startPos-endPos):length() < 2 do
							startPos = getRandomElectricAttackPos(globalposition)
							endPos = getRandomElectricAttackPos(globalposition)
						end
						electric[i]:setLine( startPos + Vec3(0,8,0), startPos,lightningTime)
						timeBettwenLightning = timeBettwenLightning + 0.3
					elseif false then
						local lightningTime = 0.7
						electric[i]:setLine( globalposition+Vec3(0,0.1,0), getRandomElectricAttackPos(globalposition),lightningTime)
						timeBettwenLightning = timeBettwenLightning + 0.5
					else
						local lightningTime = 0.5
						local ligtningPos = globalposition + Vec3(math.randomFloat(-3.5,3.5), -0.5, math.randomFloat(-3.5,3.5) )
						electric[i]:setLine( ligtningPos, ligtningPos + Vec3(0,1.7,0),lightningTime)
						
						timeBettwenLightning = timeBettwenLightning + lightningTime/#electric
					end
					
				else
--					print("electric " .. i .. ": Time left " .. electric[i]:getTimer())
				end
			end
		end
		
		updateModel( globalposition)
	end
	
	initTargetMesh()
	
	return self
end