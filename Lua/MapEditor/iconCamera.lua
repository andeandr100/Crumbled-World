require("Menu/settings.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("MapEditor/mapSettingsTable.lua")
require("MapEditor/Tools/editorSettings.lua")
--this = SceneNode()
IconCamera = {}
IconCamera.hasBeenUpdated = false


function IconCamera.create()

	--Key binds
	IconCamera.stopKeyBind = KeyBind("Menu", "control", "toogle menu")
	IconCamera.stopKeyBind:setKeyBindKeyboard(0, Key.escape)
	
	local keyBinds = Core.getBillboard("keyBind");
		
	IconCamera.keyBindForward = keyBinds:getKeyBind("Forward");
	IconCamera.keyBindBackward = keyBinds:getKeyBind("Backward");
	IconCamera.keyBindLeft = keyBinds:getKeyBind("Left");
	IconCamera.keyBindRight = keyBinds:getKeyBind("Right");
	
	
	--Create the camera
	--this icon should at least support 4k screen and 2016-01-14 icon size in the menu was approximately 750px for 4k screen for my 2560x1440 resolution was 450px
	IconCamera.camera = Camera("icon camera", true, 1024, 1024)
	--IconCamera.camera:setClearColor(Vec4(0,0,0,1))
	this:getRootNode():addChild( IconCamera.camera )
	
	IconCamera.camera:setDirectionLight(Core.getDirectionalLight(this))
	IconCamera.camera:setAmbientLight(Core.getAmbientLight(this))
	IconCamera.camera:setRenderScript("MapEditor/iconCameraRender.lua")
	
	--get main camera
	local camera = ConvertToCamera(this:getRootNode():findNodeByName("MainCamera"))
	
	--create form
	local form = Form( camera, PanelSize(Vec2(-1)), Alignment.TOP_LEFT);
	form:setBackground(Gradient(Vec4(0,0,0,0.8), Vec4(0,0,0,0.95)));
	form:setVisible(false)
	form:setRenderLevel(99)--render below notification render level
	
	local imagePanel = form:add(Image(PanelSize(Vec2(-1)),IconCamera.camera:getTexture()))
	
	local textPanel = imagePanel:add(Panel(PanelSize(Vec2(-1,0.2))))
	textPanel:add(Label(PanelSize(Vec2(-1,0.03)), "Save and exit by pressing down <b>"..IconCamera.stopKeyBind:getKeyBindName(0), MainMenuStyle.textColor, Alignment.MIDDLE_CENTER))
	
	--Camera settings

	IconCamera.form = form
	
	setDeafultValue("camPosition", Vec3(0,15,-15))
	setDeafultValue("camRotation", Vec2(0.8,3.2))
	
	settingsListener = Listener("Settings")
	settingsListener:registerEvent("Changed", settingsChanged)
	settingsChanged()
	
end

function settingsChanged()
	
	IconCamera.camera:setDefferRenderShader(Settings.getDeferredShader())
	IconCamera.camera:setUseShadow(Settings.shadow.getIsEnabled())
	IconCamera.camera:setDynamicLightsEnable(Settings.dynamicLights.getEnabled())
	IconCamera.camera:setUseGlow(Settings.glow.getEnabled())
	--Settings.resolution.getResolution()
end

function captureIconImage()

	IconCamera.form:setVisible(true)

	Core.getCursor():setRelativeMouseMode(true)
	
	EditorSettings.hideAllDebugModels()
end

function IconCamera.reloadData()
	setDeafultValue("camPosition", Vec3(0,15,-15))
	setDeafultValue("camRotation", Vec2(0.8,3.2))
	IconCamera.hasBeenUpdated = false
	
	MapSettings.camPosition = MapSettings["camPosition"]
	MapSettings.camRotation = MapSettings["camRotation"]
	
	
end

function IconCamera.saveAndQuit()
	
	IconCamera.form:setVisible(false)
	EditorSettings.restoreSettings()
	IconCamera.camera:saveScreenshot("Data/Images/tmpImage")
	Core.getCursor():setRelativeMouseMode(false)
	local nodeId = this:findNodeByType(NodeId.fileNode)
	if nodeId then
		nodeId:addFile("icon.jpg", "Data/Images/tmpImage.jpg")
	end
	
	MapSettings["camPosition"] = MapSettings.camPosition 
	MapSettings["camRotation"] = MapSettings.camRotation
	
	saveMapSettings()
	
end

function IconCamera.isVisible()
	return IconCamera.form:getVisible()
end

function IconCamera.update()
	
	if not IconCamera.form:getVisible() and not IconCamera.hasBeenUpdated then
		EditorSettings.hideAllDebugModels()	
	end
	
	if IconCamera.form:getVisible() or not IconCamera.hasBeenUpdated then
		--First time the map settings is opened a default image is taken
		IconCamera.hasBeenUpdated = true
		IconCamera.form:update()
		
		--Camera update
		
		local deltaTime = Core.getRealDeltaTime()
		local localMatrix = IconCamera.camera:getGlobalMatrix()
		if not Core.getPanelWithKeyboardFocus() then
			if IconCamera.keyBindForward:getHeld() then
				MapSettings.camPosition = MapSettings.camPosition - localMatrix:getAtVec() * deltaTime * 25
			end
			if IconCamera.keyBindBackward:getHeld() then
				MapSettings.camPosition = MapSettings.camPosition + localMatrix:getAtVec() * deltaTime * 25
			end
			if IconCamera.keyBindLeft:getHeld() then
				MapSettings.camPosition = MapSettings.camPosition - localMatrix:getRightVec() * deltaTime * 25
			end
			if IconCamera.keyBindRight:getHeld() then
				MapSettings.camPosition = MapSettings.camPosition + localMatrix:getRightVec() * deltaTime * 25
			end
		
			MapSettings.camRotation.x = MapSettings.camRotation.x + Core.getInput():getMouseDelta().y * 0.001
			MapSettings.camRotation.y = MapSettings.camRotation.y + Core.getInput():getMouseDelta().x * 0.001
		end
		 
		local qx = Quat(Vec3(1,0,0), MapSettings.camRotation.x)
		local qy = Quat(Vec3(0,1,0), MapSettings.camRotation.y)
		
		localMatrix = (qx * qy):getMatrix()
		localMatrix:setPosition(MapSettings.camPosition)
	
		IconCamera.camera:setLocalMatrix(localMatrix)	
		
		IconCamera.camera:render()
	end
	
	if not IconCamera.form:getVisible() and IconCamera.hasBeenUpdated then
		EditorSettings.restoreSettings()
	end
end