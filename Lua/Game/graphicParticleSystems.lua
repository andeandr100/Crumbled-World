
GraphicParticleSystems = {}
function GraphicParticleSystems.new(portalSize)
	local self = {}
	local bilboardParticleEffects = Core.getGameSessionBillboard("ParticleEffectStorage")
	
	function self.createTowerElectricEffect()
		local particleEffect = bilboardParticleEffects:getSceneNode("TowerElectricCenter")
		if particleEffect ~= nil then
			particleEffect = GraphicParticleSystem.new(particleEffect)		
		else
			particleEffect = GraphicParticleSystem.new(25,1)
			particleEffect:setRenderBlendMode(GL_Blend.SRC_ALPHA, GL_Blend.ONE)
			
	
			for i=1, particleEffect:getMaxParticles() do 
				local position = math.randomVec3():normalizeV() * math.randomFloat(-0.24,0.24)
				local uvCoord = Vec2(0.75,0.0) + Vec2( math.randomFloat() > 0.5 and 0.125 or 0.0, math.randomFloat() > 0.5 and 0.125 or 0.0 )
				local startColor = Vec4(0.8, 1.2, 2.0, 0.75)
				local finalColor = Vec4(0.35, 0.50, 1.2, 0.0)
				local startSize = math.randomFloat(0.12,0.16)
				local finalSize = math.randomFloat(0.5,0.65)
				local velocity = position:normalizeV() * math.randomFloat(0.0,0.1)
		
				particleEffect:addparticle( position,velocity,uvCoord, startColor, finalColor, startSize, finalSize, (i-1)/particleEffect:getMaxParticles() )
	
			end
			particleEffect:compile()
			particleEffect:setLocalPosition(Vec3())
			
			bilboardParticleEffects:setSceneNode("TowerElectricCenter", particleEffect:toSceneNode() )
		end
		return particleEffect
	end
	
	function self.createTowerFireCenter()		
		local particleEffect = bilboardParticleEffects:getSceneNode("TowerFlameCenter")
		if particleEffect ~= nil then
			particleEffect = GraphicParticleSystem.new(particleEffect)		
		else
			particleEffect = GraphicParticleSystem.new(30,1.5)
			particleEffect:setRenderBlendMode(GL_Blend.SRC_ALPHA, GL_Blend.ONE)
			
	
			for i=1, particleEffect:getMaxParticles() do 
				local position = Vec3(math.randomFloat(-1.0,1.0),0,math.randomFloat(-1.0,1.0)):normalizeV() * math.randomFloat(-0.1,0.1)
				local uvCoord = Vec2(0.0,0.875)
				local startColor = Vec4(1.30, 0.5, 0.1, 0.4)
				local finalColor = Vec4(1.20, 0.25, 0.3, 0.05)
				local startSize = math.randomFloat(0.25,0.3)
				local finalSize = math.randomFloat(0.15,0.17)
				local velocity = Vec3(math.randomFloat(-0.5,0.5),math.randomFloat(3,4),math.randomFloat(-0.5,0.5)):normalizeV() * math.randomFloat(0.3,0.6)
		
				particleEffect:addparticle( position,velocity,uvCoord, startColor, finalColor, startSize, finalSize, (i-1)/particleEffect:getMaxParticles() )
	
			end
			particleEffect:compile()
			particleEffect:setLocalPosition(Vec3())
			
			bilboardParticleEffects:setSceneNode("TowerFlameCenter", particleEffect:toSceneNode() )
		end
		return particleEffect
	end
	
	function self.createSwarmBall()		
		local particleEffect = bilboardParticleEffects:getSceneNode("SwarmBall")
		if particleEffect ~= nil then
			particleEffect = GraphicParticleSystem.new(particleEffect)		
		else
			particleEffect = GraphicParticleSystem.new(7,1)
			particleEffect:setRenderBlendMode(GL_Blend.SRC_ALPHA, GL_Blend.ONE)
			
	
			for i=1, particleEffect:getMaxParticles() do 
				local position = Vec3(math.randomFloat(-1.0,1.0),0,math.randomFloat(-1.0,1.0)):normalizeV() * math.randomFloat(-0.0375,0.0375)
				local uvCoord = Vec2(0.0,0.75) + Vec2(0, math.randomFloat() > 0.5 and 0.125 or 0.0 )
				local startColor = Vec4(1.1, 0.3, 0.1, 0.5)
				local finalColor = Vec4(1.1, 0.6, 0.2, 0.3)
				local startSize = math.randomFloat(0.09,0.098)
				local finalSize = math.randomFloat(0.13,0.15)
				local velocity = Vec3()
		
				particleEffect:addparticle( position, velocity, uvCoord, startColor, finalColor, startSize, finalSize, (i-1)/particleEffect:getMaxParticles() )
	
			end
			particleEffect:compile()
			particleEffect:setLocalPosition(Vec3())
			
			bilboardParticleEffects:setSceneNode("SwarmBall", particleEffect:toSceneNode() )
		end
		return particleEffect
	end
	
	
	return self
end