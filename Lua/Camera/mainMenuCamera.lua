require("Menu/settings.lua")
--this = Camera()
function create()
	if this:getNodeType() == NodeId.camera then
		rootNode = this:getRootNode()
		worldNode = SceneNode()
		localCameraNode = SceneNode()
		rootNode:addChild(worldNode)
		worldNode:addChild(localCameraNode)
		
		local localCameraPosition = Vec3(0,13.5,-11)
		localCameraMatrix = Matrix()
	
		localCameraMatrix:createMatrix( localCameraPosition:normalizeV(), Vec3(0,1,0))
		localCameraMatrix:setPosition(localCameraPosition)
		localCameraNode:setLocalMatrix(localCameraMatrix)
		
		freeRotation = Vec2(0.8,3.14)
		freePosition = Vec3(0,15,-15)
		
		this:setLocalMatrix(localCameraNode:getGlobalMatrix())
		
		worlMin = rootNode:getGlobalBoundingBox():getMinPos()
		worlMax = rootNode:getGlobalBoundingBox():getMaxPos()
	
		cameraMode = 1
	
		this:loadLuaScript("Enviromental/clouds.lua")
		
		
		rotation = math.pi*0.75
		rotate = true
		
		settingsListener = Listener("Settings")
		settingsListener:registerEvent("Changed", settingsChanged)
		settingsChanged()
		
		mainMenuListener = Listener("MainMenu")
		mainMenuListener:registerEvent("EnterCampaign", enterCampaign)
		mainMenuListener:registerEvent("LeaveCampaign", leaveCampaign)
		
		
		
		updateCount = 10
		
		mainUpdate = update
		update = waitUpdate
	else
		
		local camera = this:getRootNode():addChild(Camera(Text("MainCamera"), true))
		--camera = Camera()
		camera:setRenderScript("Game/render.lua")
		camera = ConvertToCamera(camera)
		camera:setEnableUpdates(true)
	
		camera:setDirectionLight(Core.getDirectionalLight(this))
		camera:setAmbientLight(Core.getAmbientLight(this))
		camera:setUseShadow(Settings.shadow.getIsEnabled())
		camera:setUseGlow(Settings.glow.getEnabled())
		camera:createWork()
	
		--add information to which camera is the main camera
		Core.setDebug2DCamera(camera)
		Core.setSoundCamera(camera)
		
		--Move this script to the camera node
		--this:removeScript(this:getCurrentScript():getName());
		camera:loadLuaScript(this:getCurrentScript():getFileName());
		
		return false
	end
	
	return true
end

function enterCampaign()
	rotate = false
end

function leaveCampaign()
	rotate = true
end

function settingsChanged()
	local value = Settings.renderScale.getValue()
	print("value: "..value.."\n")
	Core.setRenderScale(value)
--	Core.setRenderResolution(Settings.resolution.getResolution())
	this:setDefferRenderShader(Settings.getDeferredShader())
	this:setUseShadow(Settings.shadow.getIsEnabled())
	this:setDynamicLightsEnable(Settings.dynamicLights.getEnabled())
	this:setUseGlow(Settings.glow.getEnabled())
	this:setUseAntiAliasing(Settings.Antialiasing.getEnabled())
end

function getAtVec()
	local atVec = worldNode:getLocalMatrix():getAtVec()
	atVec.y = 0
	return atVec:normalizeV()
end

function getRightVec()
	local rightVec = worldNode:getLocalMatrix():getRightVec()
	rightVec.y = 0
	return rightVec:normalizeV()
end

function waitUpdate()
	updateCount = updateCount - 1
	if updateCount == 0 then
		backgroundSound = Sound("Music/Virtutes Instrumenti.sound",SoundType.STEREO)
		
		soundSource = backgroundSound:playSound(0.05, true)
		
		
		
		
		Core.setMainCamera(this)
		
		update = mainUpdate
	end
	return true
end

function update()

	if not worldNode then
		return false
	end
	
	if rotate then
		rotation = rotation + Core.getDeltaTime()*math.pi*2 * 1/220
	end
	local atVec = Vec3(math.cos(rotation), -0.60, math.sin(rotation)):normalizeV()
	local mat = Matrix()
	mat:createMatrix(-atVec, Vec3(0,1,0))
	mat:setPosition(-atVec * 30)	
	
	this:setLocalMatrix(mat)
	this:render()
	return true
end