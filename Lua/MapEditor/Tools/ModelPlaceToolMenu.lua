require("MapEditor/menuStyle.lua")
require("MapEditor/menuScriptPanel.lua")
--this = SceneNode()

ModelPlaceToolMenu = {}
function ModelPlaceToolMenu.new(toolPanel, changeModelCallbackString, settingPanel, updateSettings)
	local self = {}
	--Load config
	local rootConfig = Config("ToolsSettings")
	--Get the Model tool config settings
	local modelInfoConfig = rootConfig:get("ModelInfo")
	local selectedConfig = nil
	--selectedConfig = ConfigItem()
	
	function self.getSelectedConfig()
		return selectedConfig 
	end

	local function togleVisible(panel)
		print("togle visible tag: "..panel:getTag():toString().."\n")
		for splitedStr in panel:getTag():toString():gmatch("([^;]*);") do
			print(splitedStr.."\n")
			local bodyPanel = ModelPlaceToolMenu.toolPanel:getPanelById(splitedStr)
			if bodyPanel then
				bodyPanel:setVisible(not bodyPanel:getVisible())
			end
		end
	end
	

	--##########################################################################################################################
	--##########################################################################################################################
	--##########################################################################################################################
	
	
	local function setEnableButton(button, isEnabled)
		if isEnabled then
			button:setText("enabled")
		else
			button:setText("disabled")
		end
	end
	
	local function toogleEnableDisabledButton(button)
		local name, value = string.match(button:getTag():toString(), "(.*):(.*)")
		if value == "True" then
			button:setText("disabled")
			selectedConfig:get(name):setBool(false)
		else
			button:setText("enabled")
			selectedConfig:get(name):setBool(true)
		end
		rootConfig:save()
		ModelPlaceToolMenu.updateSettings()
		button:setTag(name..":"..(selectedConfig:get(name):getBool() and "True" or "False"))
	end
	
	
	local function saveDefaultScript()
		print("Save "..tostring(#ModelPlaceToolMenu.defaultScripts).." scripts\n")
		selectedConfig:get("numDefaultScript"):setInt(#ModelPlaceToolMenu.defaultScripts)
		for i=1, #ModelPlaceToolMenu.defaultScripts do
			selectedConfig:get("defaultScript"..tostring(i)):setString(ModelPlaceToolMenu.defaultScripts[i])
		end
		rootConfig:save()
	end
	
	local function addDefaultScript(scriptFileName)
		print("add default script: "..scriptFileName.."\n")
		ModelPlaceToolMenu.defaultScripts[#ModelPlaceToolMenu.defaultScripts+1] = scriptFileName
		saveDefaultScript()
		ModelPlaceToolMenu.updateSettings()
	end
	
	local function removeDeafultScript(scriptFileName)
		print("remove default script: "..scriptFileName.."\n")
		for i=1, #ModelPlaceToolMenu.defaultScripts do
			if ModelPlaceToolMenu.defaultScripts[i] == scriptFileName then
				ModelPlaceToolMenu.defaultScripts[i] = ModelPlaceToolMenu.defaultScripts[#ModelPlaceToolMenu.defaultScripts]
				table.remove(ModelPlaceToolMenu.defaultScripts, #ModelPlaceToolMenu.defaultScripts)
			end
		end
		saveDefaultScript()
		ModelPlaceToolMenu.updateSettings()
	end
	
	
	
	local function updateAndSaveToolConfig(textField)
		selectedConfig:get(textField:getTag():toString()):setDouble(tonumber(textField:getText()))
		rootConfig:save()
		ModelPlaceToolMenu.updateSettings()
	end
	
	function self.setToolSettingsForModel(modelPath)
		--modelPath = string
		selectedConfig = modelInfoConfig:get(modelPath)
				
		ModelPlaceToolMenu.updateSettings();
		
		setEnableButton( buttonObjectCollision, selectedConfig:get("objectCollision", true):getBool() )
		setEnableButton( buttonSpaceCollision, selectedConfig:get("spaceCollision", true):getBool() )
		setEnableButton( buttonUseNormal, selectedConfig:get("useNormal", true):getBool() )
		
		buttonObjectCollision:setTag("objectCollision:"..(selectedConfig:get("objectCollision"):getBool() and "True" or "False"))
		buttonSpaceCollision:setTag("spaceCollision:"..(selectedConfig:get("spaceCollision"):getBool() and "True" or "False"))
		buttonUseNormal:setTag("useNormal:"..(selectedConfig:get("useNormal"):getBool() and "True" or "False"))
	
		print("num: "..tostring(#modelSettings).."\n")
		for i=1,8 do
			print("Index "..tostring(i).." Tag"..modelSettings[i]:getTag():toString())
			modelSettings[i]:setText(tostring(selectedConfig:get(modelSettings[i]:getTag():toString(),1.0):getDouble()))
		end
		for i=9,14 do
			print("Index "..tostring(i).." Tag"..modelSettings[i]:getTag():toString())
			modelSettings[i]:setText(tostring(selectedConfig:get(modelSettings[i]:getTag():toString(), 0.0):getDouble()))
		end
		
		local numDefaultScript = selectedConfig:get("numDefaultScript",0):getInt()
		print("num default scripts: "..tostring(numDefaultScript))
		ModelPlaceToolMenu.defaultScripts = {}
		for i=1, numDefaultScript do
			ModelPlaceToolMenu.defaultScripts[i] = selectedConfig:get("defaultScript"..tostring(i),""):getString()
			print("default script: "..ModelPlaceToolMenu.defaultScripts[i])
		end
		MenuScriptPanel.setScriptListString(ModelPlaceToolMenu.defaultScripts)
		
		rootConfig:save()
	end
	
	
	
	local function addModelsToMenu(panel, file, spaces, changeModelCallbackString)
		local subFiles = file:getFiles()
		local toolBGColor = Vec4(0.17, 0.17, 0.17, 0.97)
		--add models
		for i=1, #subFiles do
			if subFiles[i]:isFile() then
				print(spaces.."	"..subFiles[i]:getName().."\n")
				local button = panel:add(Button(PanelSize(Vec2(-1.0, 0.02)), spaces .. subFiles[i]:getName(), ButtonStyle.SQUARE))
				button:setTextColor(Vec3(1))
				button:setEdgeColor(Vec4(0), Vec4(0))
				button:setEdgeHoverColor(Vec4(0), Vec4(0))
				button:setEdgeDownColor(Vec4(0), Vec4(0))
	
				button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
				button:setInnerHoverColor(toolBGColor, Vec4(0,0,0,0.975),toolBGColor)
				button:setInnerDownColor(toolBGColor, Vec4(0,0,0,0.99),toolBGColor)
				button:setTag(subFiles[i]:getPath())
				button:addEventCallbackExecute(changeModelCallbackString)
				button:setTextAnchor(Anchor.MIDDLE_LEFT)
				if i%2==1 then
					button:setBackground(Sprite(Vec4(1, 1, 1, 0.1)))
				end
			end
		end
	
		local i
		for i=1, #subFiles do
			if subFiles[i]:isDirectory() then
	
				print(spaces..subFiles[i]:getName().."\n")
	
				local button = MenuStyle.addTitelButton(panel, spaces .. subFiles[i]:getName())
	
				local dotDotPanel = panel:add(Label(PanelSize(Vec2(-1, 0.02)), "..."))
				dotDotPanel:setTextColor(Vec4(1))
				dotDotPanel:setVisible(true)
	
				local subFolderPanel = panel:add(Panel(PanelSize(Vec2(-1, 100))))
				subFolderPanel:setLayout(FallLayout())
				subFolderPanel:getPanelSize():setFitChildren(false, true)
				subFolderPanel:setVisible(false)
				
				button:addEventCallbackExecute(togleVisible)
				button:setTag(subFolderPanel:getPanelId() .. ";" .. dotDotPanel:getPanelId() .. ";")
	
				addModelsToMenu(subFolderPanel, subFiles[i], spaces.."	", changeModelCallbackString)
			end
		end
	end
	
	
	local function init()
		--init left menu with all models
		ModelPlaceToolMenu.toolPanel = toolPanel
		local ModelPanel = MenuStyle.createToolMenuFromPanel(toolPanel,"Models", false)
	
		modelFolder = Core.getDataFolder("Models")
		ModelPanel:setEnableYScroll()
		ModelPanel:setLayout(FallLayout())
	
		addModelsToMenu( ModelPanel, modelFolder, "", changeModelCallbackString )
		
		
		
		
		
		--create setting panel
		ModelPlaceToolMenu.updateSettings = updateSettings
		toolModelSettingsPanel, toolArea = MenuStyle.createTitleAndBody(settingPanel, "Model settings")
	
		local panelWidthFor3 = toolAndSettingMenuSize - 0.005 * 3 - 0.005
		local panelWidthFor2 = toolAndSettingMenuSize - 0.005 * 2 - 0.005
		local labelWidth = panelWidthFor3 * 0.333
		local minWidth = (panelWidthFor3 - labelWidth) * 0.5
		local maxWidth = panelWidthFor3 - labelWidth - minWidth
		local widths = {minWidth, maxWidth}
	
		toolArea:add(Label(PanelSize(Vec2(panelWidthFor2 * 0.7, 0.025)),"Object collision", Vec3(1)))
		buttonObjectCollision = toolArea:add(Button(PanelSize(Vec2(-1, 0.025)), "Enabled"))
		buttonObjectCollision:addEventCallbackExecute(toogleEnableDisabledButton)
	
		toolArea:add(Label(PanelSize(Vec2(panelWidthFor2 * 0.7, 0.025)),"Use collision normal", Vec3(1)))
		buttonUseNormal = toolArea:add(Button(PanelSize(Vec2(-1, 0.025)), "Enabled"))
		buttonUseNormal:addEventCallbackExecute(toogleEnableDisabledButton)
	
		toolArea:add(Label(PanelSize(Vec2(panelWidthFor2 * 0.7, 0.025)),"collision against space", Vec3(1)))
		buttonSpaceCollision = toolArea:add(Button(PanelSize(Vec2(-1, 0.025)), "Enabled"))
		buttonSpaceCollision:addEventCallbackExecute(toogleEnableDisabledButton)
	
		
		local textString = {"Red", "Green", "Blue", "Scale", "Rotation X", "Rotation Y", "Rotation Z"}
		
		modelSettings = {}
	
		for i=0,#textString-1 do
			toolArea:add(Label(PanelSize(Vec2(labelWidth, 0.025)),textString[i+1], Vec3(1)))
			for n=0,1 do
				local textField = toolArea:add(TextField(PanelSize(Vec2(widths[n+1], 0.025))))
				modelSettings[1+i*2+n] = textField
				if i < 3 then
					textField:setWhiteList("0123456789")
				else
					textField:setWhiteList("-.0123456789")
				end
			end
		end
		
		local settingsTag = {"ColorRed", "ColorGreen", "ColorBlue", "Scale", "RotationAroundX", "RotationAroundY", "RotationAroundZ"}
		local settingsSubTag = {"min", "max"}
		for i=0,#textString-1 do
			for n=0,1 do
				modelSettings[1+i*2+n]:setTag(settingsSubTag[n+1]..settingsTag[i+1])
				modelSettings[1+i*2+n]:addEventCallbackExecute(updateAndSaveToolConfig)
			end
		end
	
		buttonObjectCollision:setTag("objectCollision:True")--Dummy
		buttonSpaceCollision:setTag("spaceCollision:True")--Dummy
		buttonUseNormal:setTag("useNormal:True")--Dummy
		
		MenuScriptPanel.createScriptPanel(toolArea, addDefaultScript, removeDeafultScript)
	end
	
	init()
	
	return self
end