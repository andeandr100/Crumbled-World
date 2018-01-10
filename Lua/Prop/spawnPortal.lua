require("Prop/spawnPortalMesh.lua")

--this = Model()
function create()
	this:setColor(Vec3(0.8,0.0,0.78))
	local portalEffectData =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 0.32, g = 0.3, b = 0.03, a = 0.35, size = 0.25, per = 0.00},
			color2 =  {r = 0.95, g = 0.90, b = 0.20, a = 0.25, size = 0.20, per = 0.75},
			color3 =  {r = 1.15, g = 1.10, b = 1.10, a = 0.00, size = 0.10, per = 1.00},
			renderPhase = {770, 771, 770, 1}
			--renderPhase = {770, 771}
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 240,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {min=-0.3, max=0.3},
			spawnDuration = math.maxNumber(),
			spawnRadius = 1,
			spawnRadiusRange = {min=1.0, max=1.0},
			spawnRate = 100,
			spawnSpeed = 0.0
		},
		texture =  {
			countX = 2,
			countY = 2,
			startX = 0.0,
			startY = 0.625,
			widthX = 0.125,
			widthY = 0.125,
			lengthEqlWidthMul = 1
		},
		airResistance = 0.40,
		emitterSpeedMultiplyer = 1,
		gravity = -1,
		lifeTime =  {min=1.0, max=1.5}
	}
	
	local portalSize = Vec3(0.85, 1.25, 1)
	
	portalEffect = ParticleSystem.new( portalEffectData )
	local mat = portalEffect:getLocalMatrix()
	mat:rotate(Vec3(1,0,0),math.pi*0.5)
	mat:scale(Vec3(portalSize.x, 0.1, portalSize.y))
	mat:setPosition(Vec3(0,0.3,0))
	portalEffect:setLocalMatrix(mat)
	this:addChild(portalEffect:toSceneNode())
	portalEffect:activate(Vec3(0,0.0,0.6))
	--sound
	local soundPortal = SoundNode.new("spawnPortal")
	soundPortal:setSoundRolloff(2)
	this:addChild(soundPortal:toSceneNode())
	soundPortal:play(0.5,true)
	
	local meshList = this:findAllNodeByTypeTowardsLeaf(NodeId.mesh)	
	for i=1, #meshList do
		meshList[i]:destroy()
	end
	
	portal, portalEdge = SpawnPortalMesh.create(portalSize)
	--
	local pLight = PointLight.new(Vec3(0.0,1.25,0.0),Vec3(1.75,1.75,0.0),4.0)
	pLight:setCutOff(0.25)
	pLight:addFlicker(Vec3(0.075,0.075,0.0),0.1,0.2)
	pLight:addSinCurve(Vec3(0.4,0.4,0.0),2.0)
	this:addChild(pLight:toSceneNode())
	--
	return true
end

function update()
	
	local offset = Vec3( math.cos(Core.getGameTime() * 0.5) * 0.1, (math.sin(Core.getGameTime() * 0.75) * 0.5 + 0.5) * 0.2 - 0.2, 0)
	portal:setLocalPosition(offset)
	portalEdge:setLocalPosition(offset)
	portalEffect:setLocalPosition(Vec3(0,0.3,0) + offset)
	
	
	return true
end