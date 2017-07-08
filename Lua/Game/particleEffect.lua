ParticleEffect = {
	BloodSplatterSphere =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 0.35, g = 0.0, b = 0.0, a = 0.3, size = 0.3, per = 0.0},
			color2 =  {r = 0.2 , g = 0.0, b=0.0, a = 0.0, size = 0.5, per = 1.0},
			renderPhase = {768, 771}
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 30,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {max = 1, min = -0.2},
			spawnDuration = 0.05,
			spawnRadius = 0.15,
			spawnRate = 200,
			spawnSpeed = 1
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.5,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		},
		lifeTime =  {max = 0.6, min = 0.2},
		airResistance = 0.25,
		emitterSpeedMultiplyer = 1,
		gravity = 0.2,
	},
	BoneSplatterSphere =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 0.82, g = 0.72, b = 0.68, a = 0.30, size = 0.30, per = 0},
			color2 =  {r = 0.05, g = 0.05, b = 0.04, a = 0, size = 0.5, per = 1},
			renderPhase = {768, 771}
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 30,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {max = 1, min = -0.2},
			spawnDuration = 0.05,
			spawnRadius = 0.15,
			spawnRate = 100,
			spawnSpeed = 1
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.5,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		},
		lifeTime =  {max = 0.6, min = 0.2},
		airResistance = 0.25,
		emitterSpeedMultiplyer = 1,
		gravity = 0.2
	},
	Explosion =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 0.60, g = 0.10, b = 0.05, a = 0.30, size = 0.60, per = 0.0},
			color2 =  {r = 1.20, g = 0.60, b = 0.10, a = 0.35, size = 0.80, per = 0.15},
			color3 =  {r = 1.40, g = 0.80, b = 0.15, a = 0.375, size = 1.10, per = 0.30},
			color4 =  {r = 0.90, g = 0.10, b = 0.10, a = 0.35, size = 1.20, per = 0.40},
			color5 =  {r = 0.45, g = 0.10, b = 0.05, a = 0.25, size = 1.25, per = 0.45},
			color6 =  {r = 0.10, g = 0.05, b = 0.05, a = 0.375, size = 1.40, per = 0.55},
			color7 =  {r = 0.05, g = 0.05, b = 0.05, a = 0, size = 1.70, per = 1.0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 15,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = 0
			},
			spawnDuration = 0.20000000298023224,
			spawnRadius = 0.5,
			spawnRate = 75,
			spawnSpeed = 0.40000000596046448
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		},
		airResistance = 0.40,
		emitterSpeedMultiplyer = 1,
		gravity = -1,
		lifeTime =  {max = 0.60, min = 0.40}
	},
	ExplosionFireBall =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 1.10, g = 0.40, b = 0.15, a = 0.55, size = 0.135, per = 0.0},
			color2 =  {r = 1.20, g = 0.60, b = 0.10, a = 0.35, size = 0.14, per = 0.15},
			color3 =  {r = 1.40, g = 0.80, b = 0.15, a = 0.375, size = 0.15, per = 0.30},
			color4 =  {r = 0.90, g = 0.10, b = 0.10, a = 0.35, size = 0.17, per = 0.40},
			color5 =  {r = 0.45, g = 0.10, b = 0.05, a = 0.25, size = 0.175, per = 0.45},
			color6 =  {r = 0.10, g = 0.05, b = 0.05, a = 0.375, size = 0.20, per = 0.55},
			color7 =  {r = 0.05, g = 0.05, b = 0.05, a = 0.0, size = 0.25, per = 1.0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		lifeTime =  { min = 0.40, max = 0.60},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 13,
			minParticles = 0,
			pattern = "atVector",
			patternData =  {
				max = 0.1,
				min = -0.1
			},
			spawnDuration = 0.1,
			spawnRadius = 0.1,
			spawnRate = 2000,
			spawnSpeed = 5
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		},
		airResistance = 2.0,
		emitterSpeedMultiplyer = 1.0,
		gravity = -1.0,
	},
	ExplosionFireBallOnHitt =  {
		WallboardParticle = true,
		airResistance = 2,
		color =  {
			color1 =  {
				a = 0.34999999403953552,
				b = 0.05000000074505806,
				g = 0.10000000149011612,
				per = 0,
				r = 0.60000002384185791,
				size = 0.10000000149011612
			},
			color2 =  {
				a = 0.15000000596046448,
				b = 0.10000000149011612,
				g = 0.60000002384185791,
				per = 0.15000000596046448,
				r = 1.2999999523162842,
				size = 0.15000000596046448
			},
			color3 =  {
				a = 0.34999999403953552,
				b = 0.20000000298023224,
				g = 0.80000001192092896,
				per = 0.20000000298023224,
				r = 1.2000000476837158,
				size = 0.20000000298023224
			},
			color4 =  {
				a = 0.34999999403953552,
				b = 0.10000000149011612,
				g = 0.60000002384185791,
				per = 0.34999999403953552,
				r = 1.2000000476837158,
				size = 0.25
			},
			color5 =  {
				a = 0.25,
				b = 0.30000001192092896,
				g = 0.80000001192092896,
				per = 0.75,
				r = 1.2000000476837158,
				size = 0.34999999403953552
			},
			color6 =  {
				a = 0.05000000074505806,
				b = 0.05000000074505806,
				g = 0.25,
				per = 1,
				r = 0.80000001192092896,
				size = 0
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = -1,
		lifeTime =  {
			max = 0.30000001192092896,
			min = 0.15000000596046448
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 15,
			minParticles = 0,
			pattern = "atVector",
			patternData =  {
				max = 0.10000000149011612,
				min = -0.10000000149011612
			},
			spawnDuration = 0.10000000149011612,
			spawnRadius = 0.20000000298023224,
			spawnRate = 2000,
			spawnSpeed = 2
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	ExplosionMediumBlue =  {
		WallboardParticle = true,
		airResistance = 0.4,
		color =  {
			color1 =  {r = 1.0,g = 1.00,b = 0.00,a = 0.65,per = 0,size = 0.4},
			color2 =  {r = 0.0,g = 0.70,b = 1.00,a = 0.80,per = 0.15,size = 0.5},
			color3 =  {r = 0.0,g = 0.25,b = 0.75,a = 0.75,per = 0.4,size = 0.5},
			color4 =  {r = 0.0,g = 0.05,b = 0.50,a = 0.50,per = 0.45,size = 0.5},
			color5 =  {r = 0.0,g = 0.00,b = 0.00,a = 0.35,per = 0.5,size = 0.5},
			color6 =  {r = 0.0,g = 0.00,b = 0.00,a = 0.00,per = 1,size = 0.5},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = -1,
		lifeTime =  {
			max = 0.6,
			min = 0.5
		},
		spawn =  {
			OffsetFromGroundPer = 0.25,
			maxParticles = 20,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = 0.05,
			spawnRadius = 0.25,
			spawnRate = 500000,
			spawnSpeed = 1
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	ExplosionMedium =  {
		WallboardParticle = true,
		airResistance = 0.4,
		color =  {
			color1 =  {r = 1.10,g = 1,b = 1,a = 0.65,per = 0,size = 0.4},
			color2 =  {r = 1.25,g = 0.7,b = 0,a = 0.8,per = 0.15,size = 0.5},
			color3 =  {r = 1,g = 0.25,b = 0,a = 0.75,per = 0.4,size = 0.5},
			color4 =  {r = 0.5,g = 0.05,b = 0,a = 0.50,per = 0.45,size = 0.5},
			color5 =  {r = 0.0,g = 0.00,b = 0,a = 0.35,per = 0.5,size = 0.5},
			color6 =  {r = 0.0,g = 0.00,b = 0,a = 0.00,per = 1,size = 0.5},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = -1,
		lifeTime =  {
			max = 0.6,
			min = 0.5
		},
		spawn =  {
			OffsetFromGroundPer = 0.25,
			maxParticles = 30,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = 0.05,
			spawnRadius = 0.25,
			spawnRate = 500000,
			spawnSpeed = 1
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	fireStormFire =  {
		WallboardParticle = true,
		airResistance = 0.5,
		color =  {
			color1 =  {r = 0.60,g = 0.10,b = 0.05,per = 0,		a = 0.35,	size = 0.20},
			color2 =  {r = 1.20,g = 0.60,b = 0.10,per = 0.05,	a = 0.5,	size = 0.20},
			color3 =  {r = 1.30,g = 0.90,b = 0.15,per = 0.10,	a = 0.60,	size = 0.25},
			color4 =  {r = 1.20,g = 0.60,b = 0.10,per = 0.20,	a = 0.5,	size = 0.30},
			color5 =  {r = 0.60,g = 0.10,b = 0.05,per = 0.25,	a = 0.40,	size = 0.35},
			color6 =  {r = 0.05,g = 0.05,b = 0.05,per = 0.5,	a = 0.5,	size = 0.45},
			color7 =  {r = 0.05,g = 0.05,b = 0.05,per = 0.80,	a = 0.35,	size = 0.60},
			color8 =  {r = 0.05,g = 0.05,b = 0.05,per = 1,		a = 0,		size = 0.70},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = -3,
		lifeTime =  {
			max = 1.25,
			min = 2.0
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 4000,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 0.0,
				min = 0.0
			},
			spawnDuration = 3.5,
			spawnRadius = 1.0,
			spawnRate = 60,
			spawnSpeed = 0
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.25,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	fireStormFlame =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 0.60,g = 0.10,b = 0.025,a = 0.05,per = 0,	size = 0.20},
			color2 =  {r = 1.30,g = 0.60,b = 0.05,a = 0.08,per = 0.15,	size = 0.35},
			color3 =  {r = 1.20,g = 0.80,b = 0.10,a = 0.18,per = 0.20,	size = 0.42},
			color4 =  {r = 1.20,g = 0.60,b = 0.05,a = 0.18,per = 0.35,	size = 0.40},
			color5 =  {r = 1.20,g = 0.80,b = 0.15,a = 0.12,per = 0.75,	size = 0.20},
			color6 =  {r = 0.80,g = 0.25,b = 0.025,a = 0.02,per = 1,	size = 0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
			--renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA}
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 500,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {min=0, max=0},
			spawnDuration = 3.5,
			spawnRadius = 1.0,
			spawnRate = 60,
			spawnSpeed = 0.0
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
		airResistance = 0.0,
		emitterSpeedMultiplyer = 1,
		gravity = -1,
		lifeTime =  {min=1.5, max=2.5}
	},
	fireStormSparks =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 1.4, g = 0.5, b = 0.1, a = 0.15, size = 0.05, per = 0.00},
			color2 =  {r = 1.0, g = 0.5, b = 0.1, a = 0.15, size = 0.11, per = 0.15},
			color3 =  {r = 1.0, g = 0.9, b = 0.6, a = 0.25, size = 0.12, per = 0.20},
			color4 =  {r = 1.5, g = 1.0, b = 1.0, a = 0.25, size = 0.09, per = 0.35},
			color5 =  {r = 1.2, g = 0.9, b = 0.9, a = 0.25, size = 0.05, per = 0.75},
			color6 =  {r = 1.2, g = 0.85, b = 0.7, a = 0.05, size = 0.0, per = 1.0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
			--renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA}
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 500,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {min=0, max=0},
			spawnDuration = 3.5,
			spawnRadius = 1.0,
			spawnRate = 20,
			spawnSpeed = 0.0
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
		airResistance = 0.0,
		emitterSpeedMultiplyer = 1,
		gravity = -1,
		lifeTime =  {min=1.5, max=2.5}
	},
	FireBallBlue =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {r = 0.10,g = 0.3,b = 1.1,a = 0.500,per = 0.0,size = 0.13},
			color2 =  {r = 0.15,g = 0.4,b = 1.1,a = 0.375,per = 0.5,size = 0.16},
			color3 =  {r = 0.20,g = 0.6,b = 1.1,a = 0.250,per = 1.0,size = 0.12},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0,
		gravity = 0,
		lifeTime =  {
			max = 1.5,
			min = 0.75
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 8,
			minParticles = 6,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.04,
			spawnRate = 6,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	FireBall =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {r = 1.10,g = 0.30,b = 0.10,a = 0.500,per = 0.0,size = 0.095},
			color2 =  {r = 1.10,g = 0.40,b = 0.15,a = 0.375,per = 0.5,size = 0.14},
			color3 =  {r = 1.10,g = 0.60,b = 0.20,a = 0.250,per = 1.0,size = 0.055},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0,
		gravity = 0,
		lifeTime =  {
			max = 1.5,
			min = 0.75
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 6,
			minParticles = 4,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.0375,
			spawnRate = 6,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	FireBallTale18 =  {
		WallboardParticle = true,
		airResistance = 0.5,
		color =  {
			color1 =  {
				a = 0.25,
				b = 0.10000000149011612,
				g = 0.30000001192092896,
				per = 0,
				r = 1.1000000238418579,
				size = 0.079999998211860657
			},
			color2 =  {
				a = 0.64999997615814209,
				b = 0.15000000596046448,
				g = 0.40000000596046448,
				per = 0.5,
				r = 1.1000000238418579,
				size = 0.064999997615814209
			},
			color3 =  {
				a = 0.25,
				b = 0.20000000298023224,
				g = 0.60000002384185791,
				per = 1,
				r = 1.1000000238418579,
				size = 0
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0.80000001192092896,
		gravity = 0,
		lifeTime =  {
			max = 0.20000000298023224,
			min = 0.10000000149011612
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 150,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = 1000000,
			spawnRadius = 0.059999998658895493,
			spawnRate = 190,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	FlamerBlue =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {a = 0.15,b = 0.005,g = 0.5,per = 0,r = 1.40,size = 0.02},
			color2 =  {a = 0.15,b = 0.80,g = 0.50,per = 0.15,r = 0.40,size = 0.025},
			color3 =  {a = 0.125,b = 0.80,g = 0.15,per = 0.20,r = 0.15,size = 0.10},
			color4 =  {a = 0.125,b = 1.10,g = 0.30,per = 0.35,r = 0.30,size = 0.08},
			color5 =  {a = 1.20,b = 0.60,g = 0.60,per = 0.75,r = 0.225,size = 0.05},
			color6 =  {a = 0.025,b = 1.0,g = 0.85,per = 1.0,r = 0.70,size = 0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = -0.5,
		lifeTime =  {
			max = 1.9,
			min = 0.8
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 60,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = 1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.01,
			spawnRate = 13,
			spawnSpeed = 0.12
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	FlamerRed =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {a = 0.15,b = 1.40,g = 0.5,per = 0,r = 0.005,size = 0.02},
			color2 =  {a = 0.15,b = 0.40,g = 0.50,per = 0.15,r = 0.80,size = 0.025},
			color3 =  {a = 0.125,b = 0.15,g = 0.15,per = 0.20,r = 0.80,size = 0.10},
			color4 =  {a = 0.125,b = 0.30,g = 0.30,per = 0.35,r = 1.10,size = 0.08},
			color5 =  {a = 0.225,b = 0.60,g = 0.60,per = 0.75,r = 1.20,size = 0.05},
			color6 =  {a = 0.025,b = 0.70,	g = 0.85,per = 1,r = 1,size = 0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = -0.5,
		lifeTime =  {
			max = 1.9,
			min = 0.8
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 40,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = 1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.01,
			spawnRate = 13,
			spawnSpeed = 0.12
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	FlamerYellow =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {a = 0.15,b = 1.40,g = 0.5,per = 0.0,r = 0.005,size = 0.02},
			color2 =  {a = 0.15,b = 0.40,g = 0.80,per = 0.15,r = 0.80,size = 0.025},
			color3 =  {a = 0.125,b = 0.15,g = 0.80,per = 0.20,r = 0.80,size = 0.10},
			color4 =  {a = 0.125,b = 0.30,g = 1.10,per = 0.35,r = 1.10,size = 0.08},
			color5 =  {a = 0.225,b = 0.60,g = 1.20,per = 0.75,r = 1.20,size = 0.05},
			color6 =  {a = 0.025,b = 0.70,g = 1.0,per = 1.0,r = 1.0,size = 0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = -0.5,
		lifeTime =  {
			max = 1.9,
			min = 0.8
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 26,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = 1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.01,
			spawnRate = 13,
			spawnSpeed = 0.12
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	LaserBullet =  {
		WallboardParticle = false,
		airResistance = 0,
		color =  {
			color1 =  {
				a = 1,
				b = 1,
				g = 1,
				per = 0,
				r = 1,
				size = 0.075000002980232239
			},
			color2 =  {
				a = 1,
				b = 1,
				g = 1,
				per = 1,
				r = 1,
				size = 0.075000002980232239
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = math.huge,
			min = math.huge
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 1,
			minParticles = 1,
			pattern = "atVector",
			patternData =  {
				max = 0,
				min = 0
			},
			spawnDuration = 0.0099999997764825821,
			spawnRadius = 0,
			spawnRate = math.huge,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 3,
			startX = 0.25,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.0625
		}
	},
	LaserBulletShine =  {
		WallboardParticle = false,
		airResistance = 0,
		color =  {
			color1 =  {
				a = 0.33000001311302185,
				b = 1,
				g = 1,
				per = 0,
				r = 1,
				size = 0.125
			},
			color2 =  {
				a = 0.33000001311302185,
				b = 1,
				g = 1,
				per = 1,
				r = 1,
				size = 0.125
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = math.huge,
			min = math.huge
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 1,
			minParticles = 1,
			pattern = "atVector",
			patternData =  {
				max = 0,
				min = 0
			},
			spawnDuration = 0.0099999997764825821,
			spawnRadius = 0,
			spawnRate = math.huge,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 3,
			startX = 0.25,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.0625
		}
	},
	LaserBulletcenter =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {
				a = 0.64999997615814209,
				b = 1.3999999761581421,
				g = 0.80000001192092896,
				per = 0,
				r = 0.34999999403953552,
				size = 0.10000000149011612
			},
			color2 =  {
				a = 0.25,
				b = 1,
				g = 0.60000002384185791,
				per = 1,
				r = 0,
				size = 0.10000000149011612
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = math.huge,
			min = math.huge
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 1,
			minParticles = 1,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = 0.0099999997764825821,
			spawnRadius = 0,
			spawnRate = math.huge,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	LaserSight1 =  {
		WallboardParticle = false,
		airResistance = 0,
		color =  {
			color1 =  {a = 0.1,b = 0.5,g = 0.5,per = 0,r = 1,size = 0.0099999997764825821},
			color2 =  {a = 0.3,b = 0.01,g = 0.2,per = 0.2,r = 1,size = 0.025},
			color3 =  {a = 0.4,b = 0,g = 0,per = 0.4,r = 0.8,size = 0.05},
			color4 =  {a = 0.2,b = 0,g = 0,per = 0.75,r = 1,size = 0.05},
			color5 =  {a = 0.005,b = 0,g = 0,per = 1,r = 1,size = 0.01},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 1.90,
			min = 0.8
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 40,
			minParticles = 0,
			pattern = "atVector",
			patternData =  {
				max = 0.01,
				min = -0.01
			},
			spawnDuration = math.huge,
			spawnRadius = 1,
			spawnRate = 20,
			spawnSpeed = 0.05
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 3,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	MinigunFire2 =  {
		WallboardParticle = true,
		airResistance = 1,
		color =  {
			color1 =  {r = 0.60,g = 0.10,b = 0.05,per = 0,		a = 0.35,	size = 0.10},
			color2 =  {r = 1.20,g = 0.60,b = 0.10,per = 0.05,	a = 0.5,	size = 0.10},
			color3 =  {r = 1.30,g = 0.90,b = 0.15,per = 0.10,	a = 0.60,	size = 0.125},
			color4 =  {r = 1.20,g = 0.60,b = 0.10,per = 0.20,	a = 0.5,	size = 0.15},
			color5 =  {r = 0.60,g = 0.10,b = 0.05,per = 0.25,	a = 0.40,	size = 0.175},
			color6 =  {r = 0.05,g = 0.05,b = 0.05,per = 0.5,	a = 0.5,	size = 0.225},
			color7 =  {r = 0.05,g = 0.05,b = 0.05,per = 0.80,	a = 0.35,	size = 0.30},
			color8 =  {r = 0.05,g = 0.05,b = 0.05,per = 1,		a = 0,		size = 0.35},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 0.20,
			min = 0.10
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 40,
			minParticles = 0,
			pattern = "atVector",
			patternData =  {
				max = 0.15,
				min = -0.15
			},
			spawnDuration = 0.065,
			spawnRadius = 0.20,
			spawnRate = 175,
			spawnSpeed = 5
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.25,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	MinigunLaserBlast =  {
		WallboardParticle = true,
		airResistance = 1,
		color =  {
			color1 =  {r = 0.05,g = 0.10,b = 0.60,per = 0,		a = 0.35,	size = 0.10},
			color2 =  {r = 0.10,g = 0.60,b = 1.20,per = 0.05,	a = 0.5,	size = 0.10},
			color3 =  {r = 0.15,g = 0.90,b = 1.30,per = 0.10,	a = 0.60,	size = 0.125},
			color4 =  {r = 0.10,g = 0.60,b = 1.20,per = 0.20,	a = 0.5,	size = 0.15},
			color5 =  {r = 0.05,g = 0.10,b = 0.60,per = 0.25,	a = 0.40,	size = 0.175},
			color6 =  {r = 0.05,g = 0.05,b = 0.05,per = 0.5,	a = 0.5,	size = 0.225},
			color7 =  {r = 0.05,g = 0.05,b = 0.05,per = 0.80,	a = 0.35,	size = 0.30},
			color8 =  {r = 0.05,g = 0.05,b = 0.05,per = 1,		a = 0,		size = 0.35},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 0.20,
			min = 0.10
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 40,
			minParticles = 0,
			pattern = "atVector",
			patternData =  {
				max = 0.15,
				min = -0.15
			},
			spawnDuration = 0.065,
			spawnRadius = 0.20,
			spawnRate = 175,
			spawnSpeed = 5
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.25,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	MinigunOverheatSmoke =  {
		WallboardParticle = true,
		airResistance = 1,
		color =  {
			color1 =  {r = 0.2,g = 0.2,b = 0.2,a = 0,	per = 0,	size = 0.3},
			color2 =  {r = 0.2,g = 0.2,b = 0.2,a = 0.3,	per = 0.2,	size = 0.3},
			color3 =  {r = 0.2,g = 0.2,b = 0.2,a = 0.5,	per = 0.75,	size = 0.4},
			color4 =  {r = 0.2,g = 0.2,b = 0.2,a = 0,	per = 1,	size = 0.5},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA}
		},
		emitterSpeedMultiplyer = 1,
		gravity = -2,
		lifeTime =  {
			max = 1.5,
			min = 1
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 90,
			minParticles = 0,
			pattern = "atVector",
			patternData =  {
				max = 0.33,
				min = -0.33
			},
			spawnDuration = math.huge,
			spawnRadius = 0.10,
			spawnRate = 50,
			spawnSpeed = 0.25
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.25,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	NPCElectric =  {
		WallboardParticle = true,
		airResistance = 0.25,
		color =  {
			color1 =  {
				a = 0.25,
				b = 2,
				g = 1.2000000476837158,
				per = 0,
				r = 0.80000001192092896,
				size = 0.15000000596046448
			},
			color2 =  {
				a = 0.25,
				b = 1,
				g = 0.64999997615814209,
				per = 0.10000000149011612,
				r = 0.41999998688697815,
				size = 0.34999999403953552
			},
			color3 =  {
				a = 0,
				b = 1,
				g = 0.64999997615814209,
				per = 1,
				r = 0.41999998688697815,
				size = 0.75
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 1,
			min = 0.5
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 7,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = 5000000,
			spawnRadius = 0.40000000596046448,
			spawnRate = 7,
			spawnSpeed = 0.10000000149011612
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.75,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	NPCFlame =  {
		WallboardParticle = true,
		airResistance = 1,
		color =  {
			color1 =  {r = 0.60,g = 0.10,b = 0.05,a = 0.35,per = 0,		size = 0.30},
			color2 =  {r = 1.30,g = 0.60,b = 0.10,a = 0.15,per = 0.15,	size = 0.66},
			color3 =  {r = 1.20,g = 0.80,b = 0.20,a = 0.35,per = 0.20,	size = 0.75},
			color4 =  {r = 1.20,g = 0.60,b = 0.10,a = 0.35,per = 0.35,	size = 0.50},
			color5 =  {r = 1.20,g = 0.80,b = 0.30,a = 0.25,per = 0.75,	size = 0.30},
			color6 =  {r = 0.80,g = 0.25,b = 0.05,a = 0.05,per = 1,		size = 0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0.75,
		gravity = -0.80,
		lifeTime =  {
			max = 0.95,
			min = 0.5
		},
		spawn =  {
			OffsetFromGroundPer = 0.35,
			maxParticles = 10,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = 0.90
			},
			spawnDuration = 1000000,
			spawnRadius = 0.85,
			spawnRate = 10,
			spawnSpeed = 1
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	NPCSpirit =  {
		WallboardParticle = true,
		airResistance = 0.5,
		color =  {
			color1 =  {
				a = 0.75,
				b = 0.10000000149011612,
				g = 0.80000001192092896,
				per = 0,
				r = 1.6000000238418579,
				size = 0.20000000298023224
			},
			color2 =  {
				a = 0.60000002384185791,
				b = 0.20000000298023224,
				g = 0.69999998807907104,
				per = 0.10000000149011612,
				r = 1.3999999761581421,
				size = 0.28999999165534973
			},
			color3 =  {
				a = 0.44999998807907104,
				b = 0.30000001192092896,
				g = 0.80000001192092896,
				per = 0.64999997615814209,
				r = 1.2000000476837158,
				size = 0.46000000834465027
			},
			color4 =  {
				a = 0,
				b = 0.5,
				g = 0.89999997615814209,
				per = 1,
				r = 1,
				size = 0.40000000596046448
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 1,
			min = 0.44999998807907104
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 75,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.10000000149011612,
			spawnRate = 10,
			spawnSpeed = 0.05000000074505806
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.5,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	RockDust =  {
		WallboardParticle = true,
		airResistance = 0.05,
		color =  {
			color1 =  {r = 0.32,b = 0.27,g = 0.27,a = 0.00,per = 0.00,size = 0.55},
			color2 =  {r = 0.32,b = 0.30,g = 0.27,a = 0.45,per = 0.33,size = 0.75},
			color3 =  {r = 0.32,b = 0.27,g = 0.27,a = 0.35,per = 0.75,size = 0.75},
			color4 =  {r = 0.32,b = 0.27,g = 0.27,a = 0.05,per = 1.00,size = 0.00},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0.065,
		lifeTime =  {
			max = 24,
			min = 10
		},
		spawn =  {
			OffsetFromGroundPer = 0.5,
			maxParticles = 75,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 0.5,
				min = -0.5
			},
			spawnDuration = math.huge,
			spawnRadius = 1,
			spawnRate = 2.75,
			spawnSpeed = 0
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.5,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	ShellTrail =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {
				a = 0.25,
				b = 0.5,
				g = 0.5,
				per = 0,
				r = 0.5,
				size = 0.0099999997764825821
			},
			color2 =  {
				a = 0.25,
				b = 0.5,
				g = 0.5,
				per = 0.25,
				r = 0.5,
				size = 0.40000000596046448
			},
			color3 =  {
				a = 0,
				b = 0.5,
				g = 0.5,
				per = 1,
				r = 0.5,
				size = 0
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 2.5,
			min = 0.89999997615814209
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 150,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 0,
				min = 0
			},
			spawnDuration = math.huge,
			spawnRadius = 0.15000000596046448,
			spawnRate = 25,
			spawnSpeed = 0
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.25,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	SparkSpirit =  {
		WallboardParticle = true,
		airResistance = 0.25,
		color =  {
			color1 =  {r = 0.80,g = 1.20,b = 2.00,a = 0.75,per = 0.00,size = 0.14},
			color2 =  {r = 0.42,g = 0.65,b = 1.00,a = 0.75,per = 0.10,size = 0.22},
			color3 =  {r = 0.42,g = 0.65,b = 1.00,a = 0.00,per = 1.00,size = 0.52},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 1,
			min = 0.45
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 75,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.20,
			spawnRate = 50,
			spawnSpeed = 0.10
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.75,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	weakening =  {
		WallboardParticle = true,
		airResistance = 0.25,
		color =  {
			color1 =  {r = 1.20,g = 1.20,b = 0.20,a = 0.45,per = 0.00,size = 0.07},
			color2 =  {r = 1.20,g = 0.90,b = 0.10,a = 0.40,per = 0.20,size = 0.11},
			color3 =  {r = 1.0,g = 0.10,b = 0.10,a = 0.00,per = 1.00,size = 0.25},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 2,
			min = 1.5
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 20,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.05,
			spawnRate = 10,
			spawnSpeed = 0.0
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.0,
			startY = 0.625,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	weakeningArea =  {
		WallboardParticle = true,
		airResistance = 0.25,
		color =  {
			color1 =  {r = 1.20,g = 1.20,b = 0.20,a = 0.0,per = 0.00,size = 0.15},
			color2 =  {r = 1.20,g = 0.90,b = 0.10,a = 0.075,per = 0.30,size = 0.6},
			color3 =  {r = 1.0,g = 0.10,b = 0.10,a = 0.00,per = 1.00,size = 0.30},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 12,
			min = 10
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 300,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 0,
				min = -0
			},
			spawnDuration = math.huge,
			spawnRadius = 2.1,
			spawnRate = 25,
			spawnSpeed = 0.0
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.0,
			startY = 0.625,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	upgradeAvailable =  {
		WallboardParticle = true,
		airResistance = 1.5,
		color =  {
			color1 =  {r = 0.10,g = 0.05,b = 0.20,a = 0.15,size = 0.15,per = 0.00},
			color2 =  {r = 0.40,g = 0.10,b = 0.85,a = 0.25,size = 0.30,per = 0.15},
			color3 =  {r = 1.10,g = 0.35,b = 1.10,a = 0.35,size = 0.30,per = 0.35},
			color4 =  {r = 0.40,g = 0.25,b = 0.40,a = 0.05,size = 0.00,per = 1.00},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0.75,
		gravity = -2.75,
		lifeTime =  {
			max = 3.5,
			min = 2.5
		},
		spawn =  {
			OffsetFromGroundPer = 0.35,
			maxParticles = 60,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 0.01,
				min = -0.01
			},
			spawnDuration = math.huge,
			spawnRadius = 0.35,
			spawnRate = 15,
			spawnSpeed = 0.30
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	towerUpgraded =  {
		WallboardParticle = true,
		airResistance = 1.5,
		color =  {
			color1 =  {r = 0.10,g = 0.20,b = 0.20,a = 0.15,size = 0.15,per = 0.00},
			color2 =  {r = 0.20,g = 0.60,b = 0.60,a = 0.25,size = 0.30,per = 0.15},
			color3 =  {r = 0.33,g = 1.10,b = 1.10,a = 0.35,size = 0.30,per = 0.35},
			color4 =  {r = 0.33,g = 0.65,b = 0.65,a = 0.05,size = 0.00,per = 1.00},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0.75,
		gravity = -2.75,
		lifeTime =  {
			max = 3.5,
			min = 2.5
		},
		spawn =  {
			OffsetFromGroundPer = 0.35,
			maxParticles = 60,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 0.01,
				min = -0.01
			},
			spawnDuration = 2.0,
			spawnRadius = 0.35,
			spawnRate = 15,
			spawnSpeed = 0.30
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	SwarmTowerFlame =  {
		WallboardParticle = true,
		airResistance = 1.5,
		color =  {
			color1 =  {r = 0.60,g = 0.10,b = 0.05,a = 0.35,per = 0,size = 0.15},
			color2 =  {r = 1.30,g = 0.5,b = 0.10,a = 0.15,per = 0.15,size = 0.30},
			color3 =  {r = 1.20,g = 0.70,b = 0.20,a = 0.35,per = 0.20,size = 0.35},
			color4 =  {r = 1.20,g = 0.5,b = 0.10,a = 0.35,per = 0.35,size = 0.25},
			color5 =  {r = 1.20,g = 0.80,b = 0.30,a = 0.20,per = 0.75,size = 0.15},
			color6 =  {r = 0.80,g = 0.25,b = 0.05,a = 0.05,per = 1,size = 0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0.75,
		gravity = -1.5,
		lifeTime =  {
			max = 2,
			min = 1
		},
		spawn =  {
			OffsetFromGroundPer = 0.35,
			maxParticles = 30,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = 0.90
			},
			spawnDuration = math.huge,
			spawnRadius = 0.20,
			spawnRate = 15,
			spawnSpeed = 0.30
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	quakeBlaster =  {
		WallboardParticle = true,
		airResistance = 1.5,
		color =  {
			color1 =  {r = 0.60,g = 0.10,b = 0.05,a = 0.35,per = 0,size = 0.07},
			color2 =  {r = 1.30,g = 0.5,b = 0.10,a = 0.15,per = 0.15,size = 0.1},
			color3 =  {r = 1.20,g = 0.70,b = 0.20,a = 0.35,per = 0.20,size = 0.1},
			color4 =  {r = 1.20,g = 0.5,b = 0.10,a = 0.35,per = 0.35,size = 0.1},
			color5 =  {r = 1.20,g = 0.80,b = 0.30,a = 0.20,per = 0.75,size = 0.07},
			color6 =  {r = 0.80,g = 0.25,b = 0.05,a = 0.05,per = 1,size = 0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0.75,
		gravity = -5,
		lifeTime =  { min = 0.4, max = 0.5 },
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 30,
			minParticles = 5,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = 0.5,
			spawnRadius = 0.05,
			spawnRate = 60,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	QuakeDustEffect =  {
		WallboardParticle = true,
		airResistance = 0.2,
		color =  {
			color1 =  {r = 0.30, g = 0.30, b = 0.30, a = 0.35,	per=0, 		size=0.20},
			color2 =  {r = 0.30, g = 0.30, b = 0.30, a = 0.75,	per=0.6,	size=0.25},
			color3 =  {r = 0.30, g = 0.30, b = 0.30, a = 0, 	per=1,		size=0.5},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA}
		},
		emitterSpeedMultiplyer = 0,
		gravity = 0,
		lifeTime =  {
			max = 2.0,
			min = 1.5
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 100,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 0,
				min = 0
			},
			spawnDuration = 0.1,
			spawnRadius = 0.75,
			spawnRate = math.huge,
			spawnSpeed = 1.5
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.25,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	QuakeDustLingeringEffect =  {
		WallboardParticle = true,
		airResistance = 0.2,
		color =  {
			color1 =  {r = 0.20, g = 0.20, b = 0.20, a = 0.75,	per=0, 		size=0.30},
			color2 =  {r = 0.20, g = 0.20, b = 0.20, a = 0.65,	per=0.6,	size=0.4},
			color3 =  {r = 0.20, g = 0.20, b = 0.20, a = 0, 	per=1,		size=0.5},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA}
		},
		emitterSpeedMultiplyer = 0,
		gravity = 0,
		lifeTime =  { min = 1.5, max = 2.0 },
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 120,
			minParticles = 0,
			pattern = "sphere",
			patternData =  { min = 0, max = 0 },
			spawnDuration = 0.1,
			spawnRadius = 2.25,
			spawnRate = math.huge,
			spawnSpeed = 0.0
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.25,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	qukeFireBlast =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 1.10, g = 0.40, b = 0.15, a = 0.55, size = 0.27, per = 0.0},
			color2 =  {r = 1.20, g = 0.60, b = 0.10, a = 0.35, size = 0.28, per = 0.15},
			color3 =  {r = 1.40, g = 0.80, b = 0.15, a = 0.375, size = 0.30, per = 0.30},
			color4 =  {r = 0.90, g = 0.10, b = 0.10, a = 0.35, size = 0.34, per = 0.40},
			color5 =  {r = 0.45, g = 0.10, b = 0.05, a = 0.25, size = 0.35, per = 0.45},
			color6 =  {r = 0.10, g = 0.05, b = 0.05, a = 0.375, size = 0.40, per = 0.55},
			color7 =  {r = 0.05, g = 0.05, b = 0.05, a = 0.0, size = 0.5, per = 1.0},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 100,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {min=0, max=0},
			spawnDuration = 0.1,
			spawnRadius = 0.75,
			spawnRate = math.huge,
			spawnSpeed = 1.5
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		},
		airResistance = 0.0,
		emitterSpeedMultiplyer = 0,
		gravity = 0,
		lifeTime =  {min=1.5, max=2.5}
	},
	quakeFireBall =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {r = 1.10,g = 0.30,b = 0.10,a = 0.000,per = 0.0,size = 0.12},
			color2 =  {r = 1.10,g = 0.40,b = 0.15,a = 0.375,per = 0.5,size = 0.22},
			color3 =  {r = 1.10,g = 0.50,b = 0.20,a = 0.250,per = 0.75,size = 0.17},
			color3 =  {r = 1.10,g = 0.60,b = 0.20,a = 0.000,per = 1.0,size = 0.12},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0,
		gravity = 0,
		lifeTime =  {
			max = 1.5,
			min = 1.0
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 15,
			minParticles = 5,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.0375,
			spawnRate = 10,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	TracerLine =  {
		WallboardParticle = false,
		airResistance = 0,
		color =  {
			color1 =  {
				a = 1,
				b = 0.05000000074505806,
				g = 0.60000002384185791,
				per = 0,
				r = 0.69999998807907104,
				size = 0.05000000074505806
			},
			color2 =  {
				a = 0.40000000596046448,
				b = 0.05000000074505806,
				g = 0.10000000149011612,
				per = 1,
				r = 0.60000002384185791,
				size = 0.02500000037252903
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 0.079999998211860657,
			min = 0.029999999329447746
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 1,
			minParticles = 0,
			pattern = "atVector",
			patternData =  {
				max = 0.0099999997764825821,
				min = -0.0099999997764825821
			},
			spawnDuration = 0.02500000037252903,
			spawnRadius = 1,
			spawnRate = 500000,
			spawnSpeed = 5
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 32,
			startX = 0,
			startY = 0.4375,
			widthX = 0.25,
			widthY = 0.0078125
		}
	},
	endCrystalSpirit =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {r = 0.65,g = 0.33,b = 0.05,a = 0.25,per = 0,size = 0.025},
			color2 =  {r = 1.20,g = 1.20,b = 0.15,a = 0.65,per = 0.25,size = 0.05},
			color3 =  {r = 0.80,g = 0.80,b = 0.80,a = 0.25,per = 1,size = 0.015},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 2,
			min = 1
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 12,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.015,
			spawnRate = 6,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	endCrystalSpiritExplosion =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {
				a = 0.25,
				b = 0.05000000074505806,
				g = 0.33000001311302185,
				per = 0,
				r = 0.64999997615814209,
				size = 0.02500000037252903
			},
			color2 =  {
				a = 0.64999997615814209,
				b = 0.15000000596046448,
				g = 1.2000000476837158,
				per = 0.25,
				r = 1.2000000476837158,
				size = 0.15000000596046448
			},
			color3 =  {
				a = 0.44999998807907104,
				b = 0.60000002384185791,
				g = 0.60000002384185791,
				per = 1,
				r = 0.60000002384185791,
				size = 0
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 0.44999998807907104,
			min = 0.30000001192092896
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 6,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = 0.10000000149011612,
			spawnRadius = 0.014999999664723873,
			spawnRate = 1000,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	missileTale =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {
				a = 0.30000001192092896,
				b = 1.3999999761581421,
				g = 0.5,
				per = 0,
				r = 0.004999999888241291,
				size = 0.05000000074505806
			},
			color2 =  {
				a = 0.30000001192092896,
				b = 1,
				g = 0.5,
				per = 0.15000000596046448,
				r = 0.004999999888241291,
				size = 0.15000000596046448
			},
			color3 =  {
				a = 0.44999998807907104,
				b = 0.60000002384185791,
				g = 0.89999997615814209,
				per = 0.20000000298023224,
				r = 1,
				size = 0.20000000298023224
			},
			color4 =  {
				a = 0.44999998807907104,
				b = 1,
				g = 1,
				per = 0.34999999403953552,
				r = 1.5,
				size = 0.17000000178813934
			},
			color5 =  {
				a = 0.44999998807907104,
				b = 0.89999997615814209,
				g = 0.89999997615814209,
				per = 0.75,
				r = 1.2000000476837158,
				size = 0.10000000149011612
			},
			color6 =  {
				a = 0.05000000074505806,
				b = 0.69999998807907104,
				g = 0.85000002384185791,
				per = 1,
				r = 1.2000000476837158,
				size = 0
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0,
		gravity = 0,
		lifeTime =  {
			max = 0.25,
			min = 0.20000000298023224
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 150,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.10000000149011612,
			spawnRate = 20,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	missileTaleBlue =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {
				a = 0.34999999403953552,
				b = 0.05000000074505806,
				g = 0.10000000149011612,
				per = 0,
				r = 0.60000002384185791,
				size = 0.05000000074505806
			},
			color2 =  {
				a = 0.15000000596046448,
				b = 0.10000000149011612,
				g = 0.5,
				per = 0.15000000596046448,
				r = 1.2999999523162842,
				size = 0.15000000596046448
			},
			color3 =  {
				a = 0.34999999403953552,
				b = 0.20000000298023224,
				g = 0.69999998807907104,
				per = 0.20000000298023224,
				r = 1.2000000476837158,
				size = 0.25
			},
			color4 =  {
				a = 0.34999999403953552,
				b = 0.10000000149011612,
				g = 0.5,
				per = 0.34999999403953552,
				r = 1.2000000476837158,
				size = 0.2199999988079071
			},
			color5 =  {
				a = 0.20000000298023224,
				b = 0.30000001192092896,
				g = 0.80000001192092896,
				per = 0.75,
				r = 1.2000000476837158,
				size = 0.10000000149011612
			},
			color6 =  {
				a = 0.05000000074505806,
				b = 0.05000000074505806,
				g = 0.25,
				per = 1,
				r = 0.80000001192092896,
				size = 0
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0,
		gravity = 0,
		lifeTime =  {
			max = 0.25,
			min = 0.20000000298023224
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 150,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.10000000149011612,
			spawnRate = 25,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	reaperCloud =  {
		WallboardParticle = true,
		airResistance = -0.20000000298023224,
		color =  {
			color1 =  {
				a = 0,
				b = 0.075000002980232239,
				g = 0.075000002980232239,
				per = 0,
				r = 0.075000002980232239,
				size = 0.44999998807907104
			},
			color2 =  {
				a = 0.5,
				b = 0.075000002980232239,
				g = 0.075000002980232239,
				per = 0.20000000298023224,
				r = 0.075000002980232239,
				size = 0.44999998807907104
			},
			color3 =  {
				a = 0,
				b = 0.02500000037252903,
				g = 0.02500000037252903,
				per = 1,
				r = 0.02500000037252903,
				size = 0.44999998807907104
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA}
		},
		emitterSpeedMultiplyer = 0,
		gravity = 0.10000000149011612,
		lifeTime =  {
			max = 1.25,
			min = 0.75
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 100,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 0,
				min = 0
			},
			spawnDuration = math.huge,
			spawnRadius = 0.5,
			spawnRate = 65,
			spawnSpeed = 0.10000000149011612
		},
		texture =  {
			countX = 2,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0.25,
			startY = 0,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	reaperSpawn =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {
				a = 0.25,
				b = 0.64999997615814209,
				g = 0.57999998331069946,
				per = 0,
				r = 0.30000001192092896,
				size = 0.075000002980232239
			},
			color2 =  {
				a = 0.64999997615814209,
				b = 1.3999999761581421,
				g = 0.80000001192092896,
				per = 0.25,
				r = 0.34999999403953552,
				size = 0.15000000596046448
			},
			color3 =  {
				a = 0.25,
				b = 1,
				g = 0.60000002384185791,
				per = 1,
				r = 0,
				size = 0.02500000037252903
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 0.30000001192092896,
			min = 0.20000000298023224
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 15,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.075000002980232239,
			spawnRate = 40,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	MidPointColorBlueShort =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {
				a = 0.25,
				b = 0.64999997615814209,
				g = 0.57999998331069946,
				per = 0,
				r = 0.30000001192092896,
				size = 0.05000000074505806
			},
			color2 =  {
				a = 0.64999997615814209,
				b = 1.3999999761581421,
				g = 0.80000001192092896,
				per = 0.25,
				r = 0.34999999403953552,
				size = 0.17499999701976776
			},
			color3 =  {
				a = 0.25,
				b = 1,
				g = 0.60000002384185791,
				per = 1,
				r = 0,
				size = 0.05000000074505806
			},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = -1,
		lifeTime =  {
			max = 1.5,
			min = 1
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 30,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = math.huge,
			spawnRadius = 0.05000000074505806,
			spawnRate = 14,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	SpiritStone =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {r = 0.30,g = 0.58,b = 0.65,	a = 0.25,	per = 0,	size = 0.15},
			color2 =  {r = 0.35,g = 0.80,b = 1.40,	a = 0.40,	per = 0.25,	size = 0.20},
			color3 =  {r = 0,	g = 0.60,b = 1,		a = 0,		per = 1,	size = 0.05},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0,
		gravity = 0,
		lifeTime =  {
			max = 2,
			min = 0.75
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 40,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = 100000,
			spawnRadius = 0.5,
			spawnRate = 20,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	EndCrystal =  {
		WallboardParticle = true,
		airResistance = 0,
		color =  {
			color1 =  {r = 0.85,g = 0.45,b = 0.30,	a = 0.00,	per = 0.00,	size = 0.30},
			color2 =  {r = 1.40,g = 0.60,b = 0.35,	a = 0.10,	per = 0.45,	size = 0.50},
			color3 =  {r = 1.00,g = 0.40,b = 0.00,	a = 0.00,	per = 1.00,	size = 0.1},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 0,
		gravity = 0,
		lifeTime =  {
			max = 2.00,
			min = 1.00
		},
		spawn =  {
			OffsetFromGroundPer = 0.0,
			maxParticles = 60,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = 100000,
			spawnRadius = 0.45,
			spawnRate = 30,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	SparksWhenBlocking =  {
		WallboardParticle = true,
		airResistance = 0.5,
		color =  {
			color1 =  {r = 0.60,g = 0.10,b = 0.05,a = 0.5,	per = 0.00,size = 0.040},
			color2 =  {r = 1.20,g = 0.60,b = 0.10,a = 0.70,	per = 0.15,size = 0.038},
			color3 =  {r = 1.30,g = 0.90,b = 0.15,a = 0.75,	per = 0.20,size = 0.037},
			color4 =  {r = 1.20,g = 0.60,b = 0.10,a = 0.70,	per = 0.25,size = 0.036},
			color5 =  {r = 0.60,g = 0.10,b = 0.05,a = 0.5,	per = 0.35,size = 0.034},
			color6 =  {r = 0.05,g = 0.05,b = 0.05,a = 0.75,	per = 0.36,size = 0.033},
			color7 =  {r = 0.05,g = 0.05,b = 0.05,a = 0,	per = 1.00,size = 0.030},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		emitterSpeedMultiplyer = 1,
		gravity = 0,
		lifeTime =  {
			max = 0.5,
			min = 0.25
		},
		spawn =  {
			OffsetFromGroundPer = 0,
			maxParticles = 40,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {
				max = 1,
				min = -1
			},
			spawnDuration = 0.02,
			spawnRadius = 0.20,
			spawnRate = 1000,
			spawnSpeed = 3.0
		},
		texture =  {
			countX = 1,
			countY = 1,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.875,
			widthX = 0.125,
			widthY = 0.125
		}
	},
	endCrystalExplosion =  {
		WallboardParticle = true,
		color =  {
			color1 =  {r = 0.65, g = 0.33, b = 0.05, a = 0.25, size = 0.15, per = 0.0},
			color2 =  {r = 1.20, g = 1.20, b = 0.15, a = 0.65, size = 0.25, per = 0.25},
			color3 =  {r = 0.60, g = 0.60, b = 0.60, a = 0.15, size = 0, per = 1},
			renderPhase = {GL_Blend.SRC_ALPHA, GL_Blend.ONE_MINUS_SRC_ALPHA, GL_Blend.SRC_ALPHA, GL_Blend.ONE}
		},
		spawn =  {
			OffsetFromGroundPer = 0.75,
			maxParticles = 10,
			minParticles = 0,
			pattern = "sphere",
			patternData =  {min = -1, max = 1},
			spawnDuration = 0.1,
			spawnRadius = 0.1,
			spawnRate = 1000,
			spawnSpeed = 0
		},
		texture =  {
			countX = 1,
			countY = 2,
			lengthEqlWidthMul = 1,
			startX = 0,
			startY = 0.75,
			widthX = 0.125,
			widthY = 0.125
		},
		lifeTime =  {min = 0.30, max = 0.45},
		airResistance = 0,
		emitterSpeedMultiplyer = 1,
		gravity = 0
	}
}