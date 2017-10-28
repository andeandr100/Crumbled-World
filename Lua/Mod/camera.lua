require("Menu/settings.lua")

NodeCamera = {}
function NodeCamera.new(node)
	local self = {}
	local camera
	local defaultCameraPosition = Vec3(0,20,-5)
	local localCameraMatrix = Matrix()

	local function settingsChanged()
		Core.setRenderScale(Settings.renderScale.getValue())
		camera:setDefferRenderShader(Settings.getDeferredShader())
		camera:setUseShadow(Settings.shadow.getIsEnabled())
		camera:setShadowScale(Settings.shadowResolution.getValue())
		camera:setDynamicLightsEnable(Settings.dynamicLights.getEnabled())
		camera:setUseGlow(Settings.glow.getEnabled())
		camera:setUseAntiAliasing(Settings.Antialiasing.getEnabled())
	end
	
	local function init()
		camera = node:addChild(Camera(Text("MainCamera"), true))
		camera = ConvertToCamera(camera)
		camera:setEnableUpdates(true)
		camera:setDirectionLight(Core.getDirectionalLight(this))
		camera:setAmbientLight(Core.getAmbientLight(this))
		camera:setDefferRenderShader(Settings.getDeferredShader())
		camera:setUseShadow(Settings.shadow.getIsEnabled())
		camera:setUseGlow(Settings.glow.getEnabled())
		camera:setUseSelectedRender(true)
		camera:createWork()
		--add information to which camera is the main camera
		Core.setDebug2DCamera(camera)
		
		--
		--
		--
		
		localCameraMatrix:createMatrix( defaultCameraPosition:normalizeV(), Vec3(0,1,0))
		localCameraMatrix:setPosition(defaultCameraPosition)
		camera:setLocalMatrix(localCameraMatrix)
		
		--
		--
		--
		
		settingsListener = Listener("Settings")
		settingsListener:registerEvent("Changed", settingsChanged)
		settingsChanged()
		
		--
		--
		--
		
		Core.setMainCamera(camera)
		Core.setSoundCamera(nil)
	end
	init()
	
	function self.setLocalPosition(newCameraPosition)
		localCameraMatrix:setPosition(newCameraPosition+defaultCameraPosition)
		camera:setLocalMatrix(localCameraMatrix)
	end
	
	function self.getWorldLineFromScreen()
		return camera:getWorldLineFromScreen(Core.getInput():getMousePos())
	end
	
	function self.update()
		camera:render()
		return true
	end
	
	return self
end
