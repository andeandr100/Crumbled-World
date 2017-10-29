require("Menu/settings.lua")
--this = Camera()

local ZOOM_LEVEL_MIN = 9.5
local ZOOM_LEVEL_MAX = 30.0
--Achievements


local music = {}

function restore(data)
	
end


function create()
	
	--Protection in multiplayer environment where multiple instances of this script is loaded
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	if node and node:getClientId() ~= 0 then
		return false
	end
	
	
	if this:getNodeType() == NodeId.camera then
		setRestoreData(true)
		
		local musicList = {"Music/Oceanfloor.wav","Music/Forward_Assault.wav","Music/Ancient_Troops_Amassing.wav","Music/Tower-Defense.wav"}
		for i=1, #musicList do
			music[#music+1] = Sound(musicList[i],SoundType.STEREO)
		end
		music.token = 1
		
		stateBillboard = Core.getGameSessionBillboard("state")
		
		
		keyBinds = Core.getBillboard("keyBind");
		
		keyBindForward = keyBinds:getKeyBind("Forward")
		keyBindBackward = keyBinds:getKeyBind("Backward")
		keyBindLeft = keyBinds:getKeyBind("Left")
		keyBindRight = keyBinds:getKeyBind("Right")
		keyBindRotateLeft = keyBinds:getKeyBind("Rotate left")
		keyBindRotateRight = keyBinds:getKeyBind("Rotate right")
		keyBindRaise = keyBinds:getKeyBind("Camera raise")
		keyBindLower = keyBinds:getKeyBind("Camera lower")
		keyBindChangeCameraMode = keyBinds:getKeyBind("Change mode")
		
		buildingBillboard = Core.getBillboard("buildings")
		billboardStats = Core.getBillboard("stats")
		
		updatePosition = true
		
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
		
		freeRotation = Vec2(45,180)
		freePosition = Vec3(0,15,-15)
		
		--Try to find if the map have som camera start position information
		local nodeId = this:findNodeByType(NodeId.fileNode)
		local MapSettings = {}
		
		if nodeId and nodeId:contains("info.txt") then
			MapSettings = totable( nodeId:getFile("info.txt"):getContent() )
		end
		
		cameraSpeed = 20
		
		cameraLocalPos =  MapSettings.cameraLocalPos and MapSettings.cameraLocalPos or Vec3(0,13.5,-11)
		cameraCenterPos = MapSettings.cameraCenterPos and MapSettings.cameraCenterPos or Vec3()
		cameraRotation = MapSettings.cameraRotation and MapSettings.cameraRotation or 0
		if Core.getPlayerId() ~= 0 and MapSettings["camera"..Core.getPlayerId().."LocalPos"] then
			cameraLocalPos = MapSettings["camera"..Core.getPlayerId().."LocalPos"] and MapSettings["camera"..Core.getPlayerId().."LocalPos"] or cameraLocalPos
			cameraCenterPos = MapSettings["camera"..Core.getPlayerId().."CenterPos"] and MapSettings["camera"..Core.getPlayerId().."CenterPos"] or cameraCenterPos
			cameraRotation = MapSettings["camera"..Core.getPlayerId().."Rotation"] and MapSettings["camera"..Core.getPlayerId().."Rotation"] or cameraRotation
		end
		
		this:setLocalMatrix(localCameraNode:getGlobalMatrix())
		
		worldMin = rootNode:getGlobalBoundingBox():getMinPos()
		worldMax = rootNode:getGlobalBoundingBox():getMaxPos()
	
		cameraMode = 0
		
		pathBilboard = Core.getGlobalBillboard("Paths")
			

		tmpUpdate = update
		update = countDownUpdate
		resetTime = 1
		previousTargetIsland = nil
		inShiftMode = false

	
		local test1 = this
		this:loadLuaScript("Enviromental/clouds.lua")
		--Core.setMainCamera(this)
--		this:setClearColor(Vec4(Vec3(0.4),1))

		settingsListener = Listener("Settings")
		settingsListener:registerEvent("Changed", settingsChanged)
		settingsChanged()
		
		cameraOveride = Listener("cameraOveride")
		cameraOveride:registerEvent("Pause", pauseCamera)
		cameraOveride:registerEvent("Resume", resumeCamera)

	else

		local camera = this:getRootNode():addChild(Camera(Text("MainCamera"), true))
		--camera = Camera()
		camera = ConvertToCamera(camera)
		camera:setEnableUpdates(true)
	
		camera:setDirectionLight(Core.getDirectionalLight(this))
		camera:setAmbientLight(Core.getAmbientLight(this))
		camera:setDefferRenderShader(Settings.getDeferredShader())
		camera:setUseShadow(Settings.shadow.getIsEnabled())
		camera:setUseGlow(Settings.glow.getEnabled())
		camera:setUseSelectedRender(true)
		camera:createWork()
--		camera:setClearColor(Vec4(0.6,0.6,0.6,1))
	
		--add information to which camera is the main camera
		Core.setDebug2DCamera(camera)
		
		--Move this script to the camera node
		camera:loadLuaScript(this:getCurrentScript():getFileName());
		return false
	end
	
	return true
end


function pauseCamera()
	updatePosition = false
end

function resumeCamera()
	updatePosition = true
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

function getAtVec()
	local atVec = this:getGlobalMatrix():getAtVec()
	atVec.y = 0
	return -atVec:normalizeV()
end

function getRightVec()
	local rightVec = this:getGlobalMatrix():getRightVec()
	rightVec.y = 0
	return -rightVec:normalizeV()
end

function getIslandMovmentSpeed()
	if Core.isInEditor() then
		--island in editor should not move
		return Vec3()
	end
	
	local range = 15
	--find all islands within 50m
	local islands = rootNode:getAllNodeByTypeTowardsLeafWithinSphere(NodeId.island, Sphere(cameraCenterPos,range))

	local targetNormal = Vec3()
	local targetPosition = Vec3()
	local islandMovement = Vec3()

	local newWorldMin = worldMin
	local newWorldMax = worldMax

	local targetIsland = nil
	if #islands > 0 then
		--we start maxDist at 1 because we cant divide by 0
		local data = {size = 0}

		newWorldMin = islands[1]:getGlobalBoundingBox():getMinPos()
		newWorldMax = islands[1]:getGlobalBoundingBox():getMaxPos()

		for i=1, #islands do

			newWorldMin:minimize(islands[i]:getGlobalBoundingBox():getMinPos())
			newWorldMax:maximize(islands[i]:getGlobalBoundingBox():getMaxPos())
		

			local pos = Vec3(cameraCenterPos)
			local dist = islands[i]:getDistanceToIsland(pos)
			if dist < range then
				if dist < 0.001 then
					targetIsland = islands[i]
					targetPosition = pos
				end
				data.size = data.size + 1
				data[data.size] = {position = Vec3(pos), distance = math.max(dist,0.5), normal = islands[i]:getGlobalMatrix():getUpVec(), islandVelocity = islands[i]:getVelocity(), weight = 1 }
			end
		end
		
		
		if targetIsland then
			if previousTargetIsland ~= targetIsland then
				if previousTargetIsland then
					previousTargetIsland:unLockIslandMovment()
				end
				targetIsland:lockDownIslandMovment()
				previousTargetIsland = targetIsland
			end
			targetNormal = targetIsland:getGlobalMatrix():getUpVec()		
			islandMovement = Vec3()-- targetIsland:getVelocity()
		else
			--calculate the weight
			local totalWeight = 0
			local minDistance = range
			for i=1, data.size do
				if data[i].distance < minDistance then
					minDistance = data[i].distance
				end
				local weight = 0
				for j=1, data.size do
					if not i == j then
						weight = weight + data[j].distance/data[i].distance
					end
				end
				data[i].weight = weight
				if data[i].weight == 0 then
					data[i].weight = 1
				end
				totalWeight = totalWeight + weight
			end

			if totalWeight == 0 then
				totalWeight = 1
			end

			if  data.size > 0 then
				local totalWeightTest = 0;
				for i=1, data.size do
					local weight =  minDistance / data[i].distance --data[i].weight / totalWeight;
					totalWeightTest = totalWeightTest + weight;
					islandMovement = islandMovement + data[i].islandVelocity * weight
					targetPosition = targetPosition + data[i].position * weight
					targetNormal = targetNormal + data[i].normal * weight
				end
			
				targetNormal:normalize()
			
				islandMovement = islandMovement / totalWeightTest
				targetPosition = targetPosition / totalWeightTest
			end
		end
	end
	
	
	
	worldMin:minimize(newWorldMin)
	worldMax:maximize(newWorldMax)

	targetPosition = targetPosition + islandMovement

	return targetIsland and Vec3() or islandMovement
end

function countDownUpdate()
	resetTime = resetTime - Core.getRealDeltaTime()
	print("\ncamera pre update\n")
	--only render the world when it's ready to be shown, or when a a very long time has passed
	if (resetTime < 0.0 and pathBilboard and pathBilboard:exist("spawnPortals")) or resetTime < -15 then
		Core.setMainCamera(this)
		Core.setSoundCamera(nil)
		update = tmpUpdate
	end
	
	print("DeltaTime: "..Core.getRealDeltaTime())
	print("countDownUpdate: "..resetTime)
	return true
end

function update()
	if not worldNode then
		if backgroundSource then
			backgroundSource:stopFadeOut(0.5)
		end
		return false
	end

	--music
	if music.source then
		if Core.getTime()-music.timer > 300.0 then
			music.source:stopFadeOut(0.5)
			music.token = music[music.token+1] and music.token+1 or 1
			music.source = music[music.token]:playSound(0.075, true)
			music.timer = Core.getTime()
		end
	else
		music.token = 1
		music.source = music[music.token]:playSound(0.075, true)
		music.timer = Core.getTime()
	end

	if keyBindChangeCameraMode:getPressed() then
		if Core.isInEditor() or DEBUG or true then
			cameraMode = (cameraMode + 1) % 2
		else
			cameraMode = 0
		end
	end
	
	
	

	if cameraMode == 1 then

		local deltaTime = Core.getRealDeltaTime()
		local localMat = this:getLocalMatrix()
		if not Core.getPanelWithKeyboardFocus() then
			if keyBindForward:getHeld() then
				freePosition = freePosition - localMat:getAtVec() * deltaTime * 25
			end
			if keyBindBackward:getHeld() then
				freePosition = freePosition + localMat:getAtVec() * deltaTime * 25
			end
			if keyBindLeft:getHeld() then
				freePosition = freePosition - localMat:getRightVec() * deltaTime * 25
			end
			if keyBindRight:getHeld() then
				freePosition = freePosition + localMat:getRightVec() * deltaTime * 25
			end
		

			if Core.getInput():getKeyHeld(Key.space) then
				freeRotation.x = freeRotation.x + Core.getInput():getMouseDelta().y * 0.001
				freeRotation.y = freeRotation.y + Core.getInput():getMouseDelta().x * 0.001
			end
		end
		
		local qx = Quat(Vec3(1,0,0), freeRotation.x)
		local qy = Quat(Vec3(0,1,0), freeRotation.y)
		localMat = (qx * qy):getMatrix()
		localMat:setPosition(freePosition)
		this:setLocalMatrix(localMat)
		this:render()
		return true

	elseif cameraMode == 0 then
		
		--the camera should move in the same speed whatever the game speed is running at
		--clamp the time to protect from freze lag and extreme cases
		local deltaTime = math.clamp( Core.getRealDeltaTime(), 0, 0.2)
		
		if updatePosition and not stateBillboard:getBool("inMenu") then
			if not Core.getPanelWithKeyboardFocus() then
				
				if keyBindForward:getHeld() then
					cameraCenterPos = cameraCenterPos + getAtVec() * deltaTime * cameraSpeed
				end
				if keyBindBackward:getHeld() then
					cameraCenterPos = cameraCenterPos - getAtVec() * deltaTime * cameraSpeed
				end
				if keyBindLeft:getHeld() then
					cameraCenterPos = cameraCenterPos + getRightVec() * deltaTime * cameraSpeed
				end
				if keyBindRight:getHeld() then
					cameraCenterPos = cameraCenterPos - getRightVec() * deltaTime * cameraSpeed
				end
			end
			
			
			if Core.isInFullscreen() then
				local mousePos = Core.getInput():getMousePos()
				local screenSize = Core.getScreenResolution()
				if mousePos.x < 4.0 then
					cameraCenterPos = cameraCenterPos + getRightVec() * deltaTime * cameraSpeed
				elseif mousePos.x > screenSize.x - 4.0 then
					cameraCenterPos = cameraCenterPos - getRightVec() * deltaTime * cameraSpeed
				end
				if mousePos.y < 4.0 then
					cameraCenterPos = cameraCenterPos + getAtVec() * deltaTime * cameraSpeed
				elseif mousePos.y > screenSize.y - 4.0 then
					cameraCenterPos = cameraCenterPos - getAtVec() * deltaTime * cameraSpeed
				end
			end
			
			--Roation controll
			if keyBindRotateLeft:getHeld() or keyBindRotateRight:getHeld() or Core.getInput():getMouseHeld(MouseKey.middle) then
				if keyBindRotateLeft:getHeld() then
					cameraRotation = cameraRotation + deltaTime
				end
				if keyBindRotateRight:getHeld() then
					cameraRotation = cameraRotation - deltaTime
				end
	
				if Core.getInput():getMouseHeld(MouseKey.middle) then
					--support all screen resolution
					local screenResolution = Core.getScreenResolution()
					cameraRotation = cameraRotation + (Core.getInput():getMouseDelta().x/screenResolution.x) * 4 + (Core.getInput():getMouseDelta().y/screenResolution.x) * 4
				end
			end
			if Core.getInput():getKeyHeld(Key.lshift) and not Core.getInput():getMouseHeld(MouseKey.middle) then
				inShiftMode = true
				
				Core.getCursor():setRelativeMouseMode(true)
				local screenResolution = Core.getScreenResolution()
				cameraRotation = cameraRotation + (Core.getInput():getMouseDelta().x/screenResolution.x) * 4
			elseif inShiftMode then
				inShiftMode = false
				Core.getCursor():setRelativeMouseMode(false)
				Core.getCursor():warpMousePosition(Core.getScreenResolution() * 0.5)
			end
			
			
			--update camera Ypos			
			--Mouse wheel ticket is only updated, when not in editor mode, or in build mode, or mouse is howering over a panel with scrollbar.
			local mousePanel = Core.getPanelWithMouseFocus()
			if not Core.isInEditor() and not (buildingBillboard and buildingBillboard:getBool("inBuildMode") and not Core.getInput():getKeyHeld(Key.lshift)) and 
				billboardStats and billboardStats:getPanel("MainPanel") == mousePanel and not (mousePanel and mousePanel:getYScrollBar()) then
				local ticks = Core.getInput():getMouseWheelTicks()
				cameraLocalPos.y = math.clamp(cameraLocalPos.y - ticks * 0.4, ZOOM_LEVEL_MIN, ZOOM_LEVEL_MAX )
			end
			if keyBindRaise:getHeld() then
				cameraLocalPos.y = math.clamp(cameraLocalPos.y + Core.getDeltaTime() * 4, ZOOM_LEVEL_MIN, ZOOM_LEVEL_MAX )
			end
			if keyBindLower:getHeld() then
				cameraLocalPos.y = math.clamp(cameraLocalPos.y - Core.getDeltaTime() * 4, ZOOM_LEVEL_MIN, ZOOM_LEVEL_MAX )
			end

			--Keep camera close to the island
			cameraCenterPos = cameraCenterPos + getIslandMovmentSpeed() * Core.getDeltaTime()
			if not Core.isInEditor() then
				cameraCenterPos = Vec3( math.clamp( cameraCenterPos.x, worldMin.x, worldMax.x ), 0, math.clamp( cameraCenterPos.z, worldMin.z, worldMax.z ) )
			end
	--		Core.addDebugBox(Box(worldMin, worldMax),0, Vec3(1))
			
			local camMatrix = Matrix(cameraCenterPos)
			camMatrix:rotate(Vec3(0,1,0), cameraRotation)
			
			camMatrix:setPosition( camMatrix * cameraLocalPos )
			camMatrix:createMatrix( -(cameraCenterPos - camMatrix:getPosition()):normalizeV(), Vec3(0,1,0))
			
			this:setLocalMatrix(camMatrix)
		end
		
		--prepare sound matrix
		local camAtLine = Line3D( this:getGlobalPosition(), this:getAtVec(), 15 )
		local soundLine = Line3D( Vec3(camAtLine.startPos.x, 5, camAtLine.startPos.z), Vec3(camAtLine.endPos.x, 5, camAtLine.endPos.z))
		local distance, collpos = Collision.lineSegmentLineSegmentLength2(camAtLine, soundLine)
		
		local globalMatrix =this:getGlobalMatrix()
		local camMatrix = Matrix(collpos)
		camMatrix:createMatrix( -globalMatrix:getAtVec(), globalMatrix:getUpVec() )
--		Core.addDebugSphere(Sphere(collpos, 0.3),0,Vec3(1,0,0))
		--set sound matrix
		Core.setSoundCameraMatrix(camMatrix)
		
		this:render()
		return true;
	end

	this:render()	
	return true
end