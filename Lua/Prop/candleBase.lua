--this = SceneNode()
local CandleFlame =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 0.005, g = 0.5, b = 1.4, a = 0.3, size = 0.01, per = 0.00},	--0.005,0.5,1.4,0.30,0.01,0.0
			color2 =  {r = 0.005, g = 0.5, b = 1.0, a = 0.3, size = 0.022, per = 0.15},--0.005,0.5,1.0,0.30,0.022,0.15
			color3 =  {r = 1.0, g = 0.9, b = 0.6, a = 0.45, size = 0.025, per = 0.20},--1.0,0.9,0.6,0.45,0.025,0.20
			color4 =  {r = 1.5, g = 1.0, b = 1.0, a = 0.45, size = 0.017, per = 0.35},--1.5,1.0,1.0,0.45,0.017,0.35
			color5 =  {r = 1.2, g = 0.9, b = 0.9, a = 0.45, size = 0.010, per = 0.75},--1.2,0.9,0.9,0.45,0.010,0.75
			color6 =  {r = 1.2, g = 0.85, b = 0.7, a = 0.05, size = 0.0, per = 1.0},--1.2,0.85,0.70,0.05,0.0,1.0
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
			--renderPhase = {770, 771}
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 40,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {min=0.9, max=1.0},
			spawnDuration = math.maxNumber(),
			spawnRadius = 0.01,
			spawnRadiusRange = {min=1.0, max=1.0},
			spawnRate = 30,
			spawnSpeed = 0.12--<SpawnSpeedYMulit>		20.0</SpawnSpeedYMulit>
		},
		texture =  {
			countX = 1,
			countY = 1,
			startX = 0.0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125,
			lengthEqlWidthMul = 1
		},
		airResistance = 1.0,
		emitterSpeedMultiplyer = 1,
		gravity = -0.25,
		lifeTime =  {min=0.5, max=1.6}
	}
local CandleFlameRed =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 0.005, g = 0.5, b = 1.4, a = 0.15, size = 0.01, per = 0.00},	--0.005,0.5,1.4,0.15,0.01,0.0
			color2 =  {r = 0.005, g = 0.5, b = 1.0, a = 0.15, size = 0.013, per = 0.15},--0.005,0.5,1.0,0.15,0.013,0.15
			color3 =  {r = 1.0, g = 0.6, b = 0.5, a = 0.125, size = 0.05, per = 0.20},--1.0,0.6,0.5,0.125,0.05,0.20
			color4 =  {r = 1.5, g = 0.7, b = 0.7, a = 0.125, size = 0.04, per = 0.35},--1.5,0.7,0.7,0.125,0.04,0.35
			color5 =  {r = 1.2, g = 0.9, b = 0.9, a = 0.225, size = 0.025, per = 0.75},--1.2,0.9,0.9,0.225,0.025,0.75
			color6 =  {r = 1.2, g = 0.85, b = 0.7, a = 0.025, size = 0.0, per = 1.0},--1.2,0.85,0.70,0.025,0.0,1.0
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 40,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {min=1.0, max=1.0},
			spawnDuration = math.maxNumber(),
			spawnRadius = 0.01,
			spawnRadiusRange = {min=1.0, max=1.0},
			spawnRate = 13,
			spawnSpeed = 0.12
		},
		texture =  {
			countX = 1,
			countY = 1,
			startX = 0.0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125,
			lengthEqlWidthMul = 1
		},
		airResistance = 1.0,
		emitterSpeedMultiplyer = 1,
		gravity = -0.35,
		lifeTime =  {min=0.8, max=1.9}
	}
function initCandle(node,position)
	local candle1 = ParticleSystem.new(CandleFlame)
	local candle2 = ParticleSystem.new(CandleFlameRed)
	node:addChild(candle1:toSceneNode())
	node:addChild(candle2:toSceneNode())
	candle1:setScale(1.25)
	candle2:setScale(1.25)
	candle1:activate(position)
	candle2:activate(position)

	local colorVariations = Vec3(0.2,0.15,0.05)
	local color = Vec3(1.75,1.35,0.5)
	local pLight = PointLight.new(Vec3(-0.02,0.35,0.0),color,1.5)
	node:addChild(pLight:toSceneNode())
	pLight:addFlicker(colorVariations*0.75,0.05,0.1)
	pLight:addSinCurve(colorVariations,1.0)
end