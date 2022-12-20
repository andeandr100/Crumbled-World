--this = SceneNode()
function create()
	local pi = math.pi
	sunRiseDirection = Vec3(math.cos(0.2*pi),math.sin(0.2*pi),math.sin(0.2*pi)):normalizeV()
	sunDirection = Vec3(math.cos(0.5*pi),math.sin(0.5*pi),math.sin(0.5*pi)):normalizeV()
	sunSetDirection = Vec3(math.cos(0.8*pi),math.sin(0.2*pi),math.sin(0.8*pi)):normalizeV()
	
	sunriseColor = Vec3(0.9,0.35,0.70) * 1.1
	sunColor = Vec3(1.05,1.05,1.05) * 1.1
	sunsetColor = Vec3(1.08,0.58,0.035) * 1.1
	
	ambientRiseColor = Vec3(0.45)
	ambientColor = Vec3(0.75)
	ambientSetColor = Vec3(0.45)
	
	ready = false
	
	--find the lighr nodes
	directionLight = Core.getDirectionalLight(this)
	ambientLight = Core.getAmbientLight(this)
	
	--set start values fast as posible
	if directionLight then
		local colorScale = 1.0 - ambientRiseColor.x
		directionLight:setColor(sunriseColor * colorScale)
		directionLight:setDirection(sunRiseDirection)
	end
	if ambientLight then
		ambientLight:setColor(ambientRiseColor)
	end
	
	--find the wave information
	statsBilboard = Core.getBillboard("stats")
	wave = statsBilboard:getInt("wave")
	maxWave = statsBilboard:getInt("maxWave")
	
	restartListener = Listener("Restart")
	restartListener:registerEvent("restart", restartMap)
	
	if not directionLight or not ambientLight or maxWave <= 1 then
		mainUpdate = update
		update = recoverUpdate
		return true
	end
	
	init()
	
	
	
	overide = false
	overideWeight = 0
	
	return true
end

function restartMap()
	wave = 1
end

function init()
	colorWeight = 0
	targetColorWeight = 0
	
	Core.setUpdateHzRealTime(10)
	stepSize = (1/10) / 10--update speed is (1/10) we update every 0.1 second and we want a full update every 10 seconds
	
	time = 0
	updateColor()
end

--update color based on light values calculated
function updateColor()
	local camera = Core.getMainCamera()
	if camera then
		ambientLight = camera:getAmbientLight() and camera:getAmbientLight() or ambientLight
		directionLight = camera:getDirectionLight() and camera:getDirectionLight() or directionLight
	end
	
	if colorWeight < 1.0 then
		ambientLight:setColor( math.interPolate( ambientRiseColor, ambientColor, colorWeight ) )
		local colorScale = 1.0 - ambientLight:getColor().x
		directionLight:setColor( math.interPolate( sunriseColor, sunColor, colorWeight ) * colorScale ) 
		directionLight:setDirection( math.interPolate( sunRiseDirection, sunDirection,  colorWeight ) )
	else
		local colorWeightTmp = math.clamp( colorWeight - 1.0, 0.0, 1.0 )
		ambientLight:setColor( math.interPolate( ambientColor, ambientSetColor, colorWeightTmp ) )
		local colorScale = 1.0 - ambientLight:getColor().x
		directionLight:setColor( math.interPolate( sunColor, sunsetColor,  colorWeightTmp ) * colorScale )
		
		directionLight:setDirection( math.interPolate( sunDirection, sunSetDirection,  colorWeightTmp ) )
	end
end

function recoverUpdate()
	--find the lighr nodes
	if directionLight == nil and Core.getDirectionalLight(this) then
		directionLight = Core.getDirectionalLight(this)
		local colorScale = 1.0 - ambientRiseColor.x
		directionLight:setColor(sunriseColor * colorScale)
		directionLight:setDirection(sunRiseDirection)
	end
	if ambientLight == nil and Core.getAmbientLight(this) then
		ambientLight = Core.getAmbientLight(this)
		ambientLight:setColor(ambientRiseColor)
	end
	
	--find the wave information
	statsBilboard = Core.getBillboard("stats")
	wave = statsBilboard:getInt("wave")
	maxWave = statsBilboard:getInt("maxWave")
	
	if directionLight and ambientLight and maxWave > 1 then
		init()
		update = mainUpdate
	end
	
	return true
end

function update()
	
--	if Core.getInput():getKeyHeld(Key.g) then
--		overideWeight = 0
--		overide = true
--	elseif Core.getInput():getKeyHeld(Key.h) then
--		overideWeight = 0.5
--		overide = true
--	elseif Core.getInput():getKeyHeld(Key.j) then
--		overideWeight = 1
--		overide = true
--	elseif Core.getInput():getKeyHeld(Key.k) then
--		overideWeight = 1.5
--		overide = true
--	elseif Core.getInput():getKeyHeld(Key.l) then
--		overideWeight = 2
--		overide = true
--	end
--	
--	if overide then
--		colorWeight = overideWeight
--	else
	--	print("\n----------------------\n")
		wave = statsBilboard:getInt("wave")
		local numNpcToSpawn = statsBilboard:getInt("NPCSpawnsThisWave")
		local numNpcSpawned = statsBilboard:getInt("NPCSpawnedThisWave")
		
		
	--	print("wave "..wave.."\n")
	--	print("maxWave "..maxWave.."\n")
	--	print("numNpcToSpawn "..numNpcToSpawn.."\n")
	--	print("numNpcSpawned "..numNpcSpawned.."\n")
		
		if (wave < 1 or numNpcToSpawn < 1) and not ready then
			--print("\n----------------------\n")
			updateColor()
			return true
		end
		ready = true
		
		local waveWeight = 1 - math.clamp((statsBilboard:getInt("aliveEnemies") + numNpcToSpawn - numNpcSpawned) / numNpcToSpawn, 0, 1 )
	
		
		
		targetColorWeight = math.clamp(( waveWeight/maxWave + (wave-1) / maxWave ) * 2.0, 0, 2.0)
		
		--update sun more smoothly over 10 second period
		colorWeight = colorWeight * (1.0-stepSize) + targetColorWeight * stepSize
	
		
	--	print("waveWeight "..waveWeight.."\n")
	--	print("targetColorWeight "..targetColorWeight.."\n")
--		print("colorWeight "..colorWeight)
--	end


	updateColor()
	
--	print("----------------------\n\n")
	return true
end