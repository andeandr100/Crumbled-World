require("Menu/settings.lua")

local ZOOM_LEVEL_MIN = 9.5
local ZOOM_LEVEL_MAX = 30.0
--Achievements
local start_time = 0

function restore(data)
	
end

function create()
	return false
--	
--	--Protection in multiplayer environment where multiple instances of this script is loaded
--	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
--	if node and node:getClientId() ~= 0 then
--		return false
--	end
--	
--	start_time = Core.getGameTime()
--	if this:getNodeType() == NodeId.camera then
--		setRestoreData(true)
--		
--		rootNode = this:getRootNode()
--		worldNode = SceneNode()
--		localCameraNode = SceneNode()
--		rootNode:addChild(worldNode)
--		worldNode:addChild(localCameraNode)
--		
--		local localCameraPosition = Vec3(0,13.5,-11)
--		localCameraMatrix = Matrix()
--	
--		localCameraMatrix:createMatrix( localCameraPosition:normalizeV(), Vec3(0,1,0))
--		localCameraMatrix:setPosition(localCameraPosition)
--		localCameraNode:setLocalMatrix(localCameraMatrix)
--		
--		freeRotation = Vec2(45,180)
--		freePosition = Vec3(0,15,-15)
--		
--		--Try to find if the map have som camera start position information
--		local nodeId = this:findNodeByType(NodeId.fileNode)
--		local MapSettings = {}
--		
--		if nodeId and nodeId:contains("info.txt") then
--			MapSettings = totable( nodeId:getFile("info.txt"):getContent() )
--		end
--		
--		cameraSpeed = 20
--		
--		cameraLocalPos =  MapSettings.cameraLocalPos and MapSettings.cameraLocalPos or Vec3(0,13.5,-11)
--		cameraCenterPos = Vec3()
--		cameraRotation = 0
--		if Core.getPlayerId() ~= 0 and MapSettings["camera"..Core.getPlayerId().."LocalPos"] then
--			cameraLocalPos = MapSettings["camera"..Core.getPlayerId().."LocalPos"] and MapSettings["camera"..Core.getPlayerId().."LocalPos"] or cameraLocalPos
--			cameraCenterPos = MapSettings["camera"..Core.getPlayerId().."CenterPos"] and MapSettings["camera"..Core.getPlayerId().."CenterPos"] or cameraCenterPos
--			cameraRotation = MapSettings["camera"..Core.getPlayerId().."Rotation"] and MapSettings["camera"..Core.getPlayerId().."Rotation"] or cameraRotation
--		end
--		
--		this:setLocalMatrix(localCameraNode:getGlobalMatrix())
--		
--		worldMin = rootNode:getGlobalBoundingBox():getMinPos()
--		worldMax = rootNode:getGlobalBoundingBox():getMaxPos()
--	
--		cameraMode = 0
--		
--		pathBilboard = Core.getGlobalBillboard("Paths")
--			
--
--		tmpUpdate = update
--		update = countDownUpdate
--		resetTime = 1
--		previousTargetIsland = nil
--		inShiftMode = false
--
--	
--		local test1 = this
--		this:loadLuaScript("Enviromental/clouds.lua")
--		--Core.setMainCamera(this)
----		this:setClearColor(Vec4(Vec3(0.4),1))
--
--		settingsListener = Listener("Settings")
--		settingsListener:registerEvent("Changed", settingsChanged)
--		settingsChanged()
--
--	else
--
--		local camera = this:getRootNode():addChild(Camera(Text("MainCamera"), true))
--		--camera = Camera()
--		camera = ConvertToCamera(camera)
--		camera:setEnableUpdates(true)
--	
--		camera:setDirectionLight(Core.getDirectionalLight(this))
--		camera:setAmbientLight(Core.getAmbientLight(this))
--		camera:setDefferRenderShader(Settings.getDeferredShader())
--		camera:setUseShadow(Settings.shadow.getIsEnabled())
--		camera:setUseGlow(Settings.glow.getEnabled())
--		camera:setUseSelectedRender(true)
--		camera:createWork()
----		camera:setClearColor(Vec4(0.6,0.6,0.6,1))
--	
--		--add information to which camera is the main camera
--		Core.setDebug2DCamera(camera)
--		
--		--Move this script to the camera node
--		camera:loadLuaScript(this:getCurrentScript():getFileName());
--		return false
--	end
--	
--	return true
end

function settingsChanged()
	print("\n\n\n\n")
	Core.setRenderScale(Settings.renderScale.getValue())
--	Core.setRenderResolution(Settings.resolution.getResolution())
	this:setDefferRenderShader(Settings.getDeferredShader())
	this:setUseShadow(Settings.shadow.getIsEnabled())
	this:setShadowScale(Settings.shadowResolution.getValue())
	this:setDynamicLightsEnable(Settings.dynamicLights.getEnabled())
	this:setUseGlow(Settings.glow.getEnabled())
	this:setUseAntiAliasing(Settings.Antialiasing.getEnabled())
	--Settings.resolution.getResolution()
	print("\n\n")
end

function countDownUpdate()
	resetTime = resetTime - Core.getRealDeltaTime()
	print("\ncamera pre update\n")
	--only render the world when it's ready to be shown, or when a a very long time has passed
	if resetTime < 0.0 or resetTime < -10 then
		Core.setMainCamera(this)
		Core.setSoundCamera(nil)
		update = tmpUpdate
	end
	
	print("DeltaTime: "..Core.getRealDeltaTime())
	print("countDownUpdate: "..resetTime)
	return true
end

function update()
	--Achievements
	if gameSpeed==3.0 and Core.getGameTime()-start_time>300.0 and Core.isInMultiplayer()==false then
		start_time = Core.getGameTime()
		local comUnit = Core.getComUnit()
		comUnit:sendTo("SteamAchievement","Speed","")
	end
	

	local deltaTime = Core.getRealDeltaTime()
	local localMat = this:getLocalMatrix()
	
	local qx = Quat(Vec3(1,0,0), freeRotation.x)
	local qy = Quat(Vec3(0,1,0), freeRotation.y)
	localMat = (qx * qy):getMatrix()
	localMat:setPosition(freePosition)
	this:setLocalMatrix(localMat)
	this:render()
	return true
end