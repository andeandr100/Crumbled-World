--this = SceneNode()

SpawnPortalMesh = {}
function SpawnPortalMesh.new(portalSize)
	local self = {}
	
	local portalNode = SceneNode.new()
	local portalMesh = NodeMesh.new()
	local particleEffectPortalEdge
	local particleEffectStars
	local centerPos

	local function initPortal(PortalSize)
	
		this:addChild(portalNode)
		centerPos = Vec3(0,portalSize.y,0)
		portalNode:setLocalPosition(centerPos)

		portalMesh:setVertexType(VertexType.position3, VertexType.uvcoord, VertexType.color4)
		
		portalMesh:setRenderLevel(4)
		portalMesh:setShader(Core.getShader("portal"))
		portalMesh:setTexture(Core.getShader("portal"), Core.getTexture("portal"),0)
		portalMesh:setTexture(Core.getShader("portal"), Core.getTexture("portal"),1)
		portalMesh:setColor(Vec4(1))
		portalMesh:setCanBeSaved(false)
		portalMesh:setCollisionEnabled(false)
		
			
		portalMesh:clearMesh();
		
		local midColor = Vec4(0,1,1,1)
		local edgeColor = Vec4(1,1,0,1)
		
		local cos = math.cos
		local sin = math.sin
		local stepSize = math.pi / 24.0
		
		local index = 0
		
		
		portalMesh:addVertex(Vec3(), Vec2(0.3, 0.3), midColor)
		
		for rad = stepSize, math.pi * 2 + stepSize*0.5, stepSize do
			index = portalMesh:getNumVertex()
			portalMesh:addVertex( Vec3(cos(rad - stepSize), sin(rad - stepSize), 0) * portalSize, Vec2(1, 1), edgeColor)
			portalMesh:addVertex( Vec3(cos(rad), sin(rad), 0) * portalSize, Vec2(1, 1), edgeColor)
			
			portalMesh:addIndex(0)
			portalMesh:addIndex(index + 0)
			portalMesh:addIndex(index + 1)
		end
		
		
		
		portalMesh:compile()
		portalMesh:setBoundingSphere(Sphere( Vec3(), math.max(portalSize.x, portalSize.y,portalSize.z)))	
		portalNode:addChild(portalMesh:toSceneNode())	
		
		
		--###########################################################
		--###########################################################
		
		local function randomeRotationScale()
			return math.randomFloat() > 0.5 and 0.5 or (math.randomFloat() > 0.5 and 1.0 or 2.0 )
		end
		
		
		particleEffectPortalEdge = GraphicParticleSystem.new(300,25)
		
		local shader = Core.getShader("ParticleEffectPortal")
		particleEffectPortalEdge:setShader(shader)
		particleEffectPortalEdge:setRenderBlendMode(GL_Blend.SRC_ALPHA, GL_Blend.ONE)
		local rad = 0
		local halfMaxParticles = particleEffectPortalEdge:getMaxParticles() * 0.5
		for i=1, particleEffectPortalEdge:getMaxParticles() do 
			local position = Vec3(rad,(i > halfMaxParticles and 1 or -1),0)
			local uvCoord = Vec2(0.5,0.5) + Vec2( math.randomFloat() > 0.5 and 0.125 or 0.0, math.randomFloat() > 0.5 and 0.125 or 0.0 )
			local color = Vec4(math.randomFloat(0.6,0.7),math.randomFloat(0.25,0.3),math.randomFloat(0.6,0.7),0.7)
			local size = math.randomFloat(0.05,0.12)
			if math.randomFloat() > 0.75 then
				color = Vec4( color:toVec3(), 1 )
				uvCoord = Vec2(0.25,0.0) + Vec2( math.randomFloat() > 0.5 and 0.125 or 0.0, math.randomFloat() > 0.5 and 0.125 or 0.0 )
				size = math.randomFloat(0.2,0.35)
			end
			particleEffectPortalEdge:addparticle( position,Vec3(),uvCoord, color, color, size, size, 0 )
			rad = rad + (math.pi*2) / halfMaxParticles
		end
		particleEffectPortalEdge:compile()
		particleEffectPortalEdge:setLocalPosition(Vec3())
		particleEffectPortalEdge:setUniform(shader, "portalSize", 1)
		portalNode:addChild(particleEffectPortalEdge:toSceneNode())
		
		
		
		--###########################################################
		--###########################################################
		
		
		particleEffectStars = GraphicParticleSystem.new(80,1.0)
		particleEffectStars:setRenderBlendMode(GL_Blend.SRC_ALPHA, GL_Blend.ONE)
		local rad = 0
		local halfMaxParticles = particleEffectStars:getMaxParticles() * 0.5
		for i=1, particleEffectStars:getMaxParticles() do 
			local position = Vec3(cos(rad) * math.randomFloat(1.4,1.8) ,sin(rad) * math.randomFloat(2,2.4) , 0)
			local uvCoord = Vec2(0.25,0.25) + Vec2( math.randomFloat() > 0.5 and 0.125 or 0.0, math.randomFloat() > 0.5 and 0.125 or 0.0 )
			local color = Vec4(math.randomFloat(0.6,0.7),math.randomFloat(0.25,0.3),math.randomFloat(0.6,0.7),0.7)
			local size = math.randomFloat(0.05,0.08)
			local velocity = -position:normalizeV() / 0.4
	
			particleEffectStars:addparticle( position,velocity,uvCoord, color, color, size, math.randomFloat(0.01,0.2), math.randomFloat() )
			rad = rad + (math.pi*2) / halfMaxParticles
		end
		particleEffectStars:compile()
		particleEffectStars:setLocalPosition(Vec3())
		particleEffectStars:setUniform(shader, "portalSize", 1)
		portalNode:addChild(particleEffectStars:toSceneNode())
		
		
		--###########################################################
		--###########################################################
		
		
	
	end

	
	initPortal(portalSize)
	
	function self.update(portalSize)
		local offset = Vec3( math.cos(Core.getGameTime() * 0.5) * 0.1, (math.sin(Core.getGameTime() * 0.75) * 0.5 + 0.5) * 0.2 - 0.2, 0)
		portalNode:setLocalPosition(offset + centerPos * portalSize)
		
		local mat = Matrix()
		mat:scale(portalSize)
		portalMesh:setLocalMatrix(mat)
		particleEffectStars:setLocalMatrix(mat)
		
		particleEffectPortalEdge:setUniform(particleEffectPortalEdge:getShader(), "portalSize", portalSize)
		particleEffectStars:setUniform(particleEffectStars:getShader(), "portalSize", portalSize)
		
	end
	
	
	return self
end