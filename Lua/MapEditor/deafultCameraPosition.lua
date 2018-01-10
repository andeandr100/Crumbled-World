require("Menu/settings.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("MapEditor/mapSettingsTable.lua")
--this = SceneNode()
DeafultCameraPosition = {}
function DeafultCameraPosition.new()
	local self = {}
	
	local camera = nil
	local form = nil
	local keyBinds = Core.getBillboard("keyBind");
			
	local keyBindForward = keyBinds:getKeyBind("Forward");
	local keyBindBackward = keyBinds:getKeyBind("Backward");
	local keyBindLeft = keyBinds:getKeyBind("Left");
	local keyBindRight = keyBinds:getKeyBind("Right");
	local keyBindRotateLeft = keyBinds:getKeyBind("Rotate left")
	local keyBindRotateRight = keyBinds:getKeyBind("Rotate right")
	local keyBindRaise = keyBinds:getKeyBind("Camera raise")
	local keyBindLower = keyBinds:getKeyBind("Camera lower")
	local keyBindChangeCameraMode = keyBinds:getKeyBind("Change mode")
	
	local stopKeyBind = KeyBind("Menu", "Control", "toogle menu")
	
	local cameraSpeed = 20
	local cameraLocalPos = Vec3(0,13.5,-11)
	local cameraCenterPos = Vec3()
	local cameraRotation = 0
	
	
		
	
	
	local hasBeenUpdated = false

	
	local function settingsChanged()
--		
		camera:setDefferRenderShader(Settings.getDeferredShader())
		camera:setUseShadow(Settings.shadow.getIsEnabled())
		camera:setDynamicLightsEnable(Settings.dynamicLights.getEnabled())
		camera:setUseGlow(Settings.glow.getEnabled())
		--Settings.resolution.getResolution()
	end
	
	function self.getCameraTexture()
		return camera:getTexture()
	end
	
	local function init()
	
		--Key binds
		stopKeyBind:setKeyBindKeyboard(0, Key.escape)
		
		
		local minSize = math.min( Core.getScreenResolution().x, Core.getScreenResolution().y )
		
		--Create the camera
		camera = Camera.new("icon camera", true, minSize, minSize)
		this:getRootNode():addChild( camera:toSceneNode() )
		
		camera:setDirectionLight(Core.getDirectionalLight(this))
		camera:setAmbientLight(Core.getAmbientLight(this))
		camera:setRenderScript("Game/render.lua")
		
		
		--get main camera
		local mainCamera = ConvertToCamera(this:getRootNode():findNodeByName("MainCamera"))
		
		--create form
		form = Form( mainCamera, PanelSize(Vec2(-1)), Alignment.TOP_LEFT);
		form:setBackground(Gradient(Vec4(0,0,0,0.8), Vec4(0,0,0,0.95)));
		form:setVisible(false)
		form:setRenderLevel(99)--render below notification render level
		
		local imagePanel = form:add(Image(PanelSize(Vec2(-1)),camera:getTexture()))
		
		local textPanel = imagePanel:add(Panel(PanelSize(Vec2(-1,0.2))))
		textPanel:add(Label(PanelSize(Vec2(-1,0.03)), "Save and exit by pressing down <b>"..stopKeyBind:getKeyBindName(0), MainMenuStyle.textColor, Alignment.MIDDLE_CENTER))
		
		--Camera settings
		setDeafultValue("camPosition", Vec3(0,15,-15))
		setDeafultValue("camRotation", Vec2(0.8,3.2))
		
		settingsListener = Listener("Settings")
		settingsListener:registerEvent("Changed", settingsChanged)
		settingsChanged()
		
	end
	

	
	function self.captureIconImage()
	
		form:setVisible(true)
		
		--set curent camera from data set
		if MapSettings["camera"..currentCameraToChange.."LocalPos"] then
			cameraLocalPos = MapSettings["camera"..currentCameraToChange.."LocalPos"]
			cameraCenterPos = MapSettings["camera"..currentCameraToChange.."CenterPos"]
			cameraRotation = MapSettings["camera"..currentCameraToChange.."Rotation"]	
		end
	
		--Core.getCursor():setRelativeMouseMode(true)
	end
	
	--repaint the camera texture
	function self.changeCamera(playerId)
		if MapSettings["camera"..playerId.."LocalPos"] then
			cameraLocalPos = MapSettings["camera"..playerId.."LocalPos"]
			cameraCenterPos = MapSettings["camera"..playerId.."CenterPos"]
			cameraRotation = MapSettings["camera"..playerId.."Rotation"]	
			hasBeenUpdated = false	
		elseif MapSettings["cameraLocalPos"] then
			cameraLocalPos = MapSettings["cameraLocalPos"]
			cameraCenterPos = MapSettings["cameraCenterPos"]
			cameraRotation = MapSettings["cameraRotation"]
			hasBeenUpdated = false	
		end
	end
	
	function self.reloadData()
		setDeafultValue("cameraLocalPos", Vec3(0,13.5,-11))
		setDeafultValue("cameraCenterPos", Vec3())
		setDeafultValue("cameraRotation", 0)
		
		cameraLocalPos = MapSettings["cameraLocalPos"]
		cameraCenterPos = MapSettings["cameraCenterPos"]
		cameraRotation = MapSettings["cameraRotation"]
		
		hasBeenUpdated = false		
	end
	
	function self.saveAndQuit()
		form:setVisible(false)
		
		


		--Core.getCursor():setRelativeMouseMode(false)
		if currentCameraToChange == 0 then
			MapSettings["cameraLocalPos"] = cameraLocalPos
			MapSettings["cameraCenterPos"] = cameraCenterPos
			MapSettings["cameraRotation"] = cameraRotation
		end
				
		MapSettings["camera"..currentCameraToChange.."LocalPos"] = cameraLocalPos
		MapSettings["camera"..currentCameraToChange.."CenterPos"] = cameraCenterPos
		MapSettings["camera"..currentCameraToChange.."Rotation"] = cameraRotation
		
		
		saveMapSettings()
	end
	
	function self.isVisible()
		return form:getVisible()
	end
	
	local function getAtVec()
		local atVec = camera:getGlobalMatrix():getAtVec()
		atVec.y = 0
		return -atVec:normalizeV()
	end
	
	local function getRightVec()
		local rightVec = camera:getGlobalMatrix():getRightVec()
		rightVec.y = 0
		return -rightVec:normalizeV()
	end
	
	function self.update()
	
		if form:getVisible() or not hasBeenUpdated then
			
			--First time the map settings is opened a default image is taken
			hasBeenUpdated = true
			form:update()
			
			--Camera update
			--the camera should move in the same speed whatever the game speed is running at
			--clamp the time to protect from freze lag and extreme cases
			local deltaTime = math.clamp( Core.getRealDeltaTime(), 0, 0.2)
			
			
					
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
					cameraRotation = cameraRotation + (Core.getInput():getMouseDelta().x/screenResolution.x) * 5 + (Core.getInput():getMouseDelta().y/screenResolution.x) * 5
				end
			end
			
			
			--Ypos
			cameraLocalPos.y = math.clamp(cameraLocalPos.y - Core.getInput():getMouseWheelTicks() * 0.4, 7.0, 20.0 )
			
			--Keep camera close to the island
			--cameraCenterPos = Vec3( math.clamp( cameraCenterPos.x, worldMin.x, worldMax.x ), 0, math.clamp( cameraCenterPos.z, worldMin.z, worldMax.z ) )

			local camMatrix = Matrix(cameraCenterPos)
			camMatrix:rotate(Vec3(0,1,0), cameraRotation)
			
			camMatrix:setPosition( camMatrix * cameraLocalPos )
			camMatrix:createMatrix( -(cameraCenterPos - camMatrix:getPosition()):normalizeV(), Vec3(0,1,0))
			
			camera:setLocalMatrix(camMatrix)
			camera:render()
		end
	end
	
	init()
	
	return self	
end