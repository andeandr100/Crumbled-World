require("Menu/MainMenu/optionsMenuStyle.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/settingsCombobox.lua")
require("Menu/settings.lua")
--this = SceneNode()

VideoPanel = {}
VideoPanel.labels = {}
VideoPanel.labelsText =  { "options.screen", "options.window mode", "options.resolution", "options.render scale", "options.vsync", "options.graphic", "options.shadow", "options.shadow resolution", "options.ambient occlusion", "options.antialiasing", "options.glow", "options.dynamic lights", "options.model density", "options.island smoke", "options.floating stones" }
VideoPanel.optionsBoxes = {}

function VideoPanel.destroy()

end

function VideoPanel.languageChanged()

	local labels = VideoPanel.labels	
	for i=1, #labels do
		if labels[i] then
			labels[i]:setText(language:getText(VideoPanel.labelsText[i]))
		end
	end
	
	--update comboboxes
	for i=1, #VideoPanel.optionsBoxes do
		if VideoPanel.optionsBoxes[i] then
			VideoPanel.optionsBoxes[i].updateLanguage()
		end
	end
end

function VideoPanel.create(mainPanel)
	local videoPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.8,-0.95))))
	videoPanel:setLayout(FallLayout(PanelSize(Vec2(0,0.0015))))
	videoPanel:setEnableScroll()
	videoPanel:setVisible(false)
	
	
	VideoPanel.createResolutionOptions(videoPanel)
	VideoPanel.createGraphicOptions(videoPanel)
	
	--set text
	local labels = VideoPanel.labels	
	for i=1, #labels do
		if labels[i] then
			--print("")
			--print("index: "..i)
			--print("value: "..VideoPanel.labelsText[i])
			labels[i]:setText(language:getText(VideoPanel.labelsText[i]))
		end
	end
	
	VideoPanel.videoPanel = videoPanel

	if settingsListener == nil then
		settingsListener = Listener("Settings")
	end
	
	if Settings.config:get("machineId","0-0"):getString() ~= Core.getMachineId() then
		Settings.config:get("machineId"):setString(Core.getMachineId())
		Settings.config:get(Settings.fullscreen.configName):setBool(true)
	end
	
	return videoPanel
end

function settingsChanged()
	print("Settings changed\n")
end

function VideoPanel.changedSettingsBool(tag, index, items)
	local value = (index == 1)
	
	if tag == Settings.fullscreen.configName then
		Core.setFullscreen(value)
	end
	
	Settings.config:get(tag):setBool(value)
	Settings.config:save()	
	
	settingsListener:pushEvent("Changed")
end


function VideoPanel.changedSettingsInt(tag, index, items)
	
	Settings.config:get(tag):setString(items[index])
	Settings.config:save()
	
	settingsListener:pushEvent("Changed")
end


function VideoPanel.changeVSync(tag, index)
	
	Settings.config:get(tag):setBool(index == 1)
	Settings.config:save()	
	
	Core.setVsync(index == 1)
end

function changedSettingsString(textField)
	
	local value = textField:getText()
	Settings.config:get(textField:getTag():toString()):setString(value)
	Settings.config:save()
	
	settingsListener:pushEvent("Changed")
end

function VideoPanel.createResolutionOptions(panel)
	
	local labels = VideoPanel.labels
	
	labels[1] = OptionsMenuStyle.addOptionsHeader( panel, "options.screen" )
	
	local rowPanel
	
	rowPanel, labels[2] = OptionsMenuStyle.addRow(panel, "options.window mode")
	conf = Settings.fullscreen
	VideoPanel.optionsBoxes[1] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	

	labels[3] = nil
	VideoPanel.optionsBoxes[2] = nil
	
	rowPanel, labels[4] = OptionsMenuStyle.addRow(panel, "options.render scale")
	conf = Settings.renderScale
	VideoPanel.optionsBoxes[3] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
	rowPanel, labels[5] = OptionsMenuStyle.addRow(panel, "options.vsync")
	conf = Settings.vsync
	VideoPanel.optionsBoxes[4] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changeVSync )

	
	Core.setVsync(Settings.vsync.getValue())
end

function VideoPanel.createGraphicOptions(panel)
	local labels = VideoPanel.labels
	labels[6] = OptionsMenuStyle.addOptionsHeader( panel, "options.graphic" )
	
	local rowPanel
	
	rowPanel, labels[14] = OptionsMenuStyle.addRow(panel, "options.island smoke")
	conf = Settings.islandSmoke
	GamePanel.optionsBoxes[12] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsBool )
	
	rowPanel, labels[15] = OptionsMenuStyle.addRow(panel, "options.floating stones")
	conf = Settings.floatingStones
	GamePanel.optionsBoxes[13] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsBool )
	
	
	
	rowPanel, labels[7] = OptionsMenuStyle.addRow(panel, "options.shadow")
	conf = Settings.shadow
	VideoPanel.optionsBoxes[5] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
	rowPanel, labels[8] = OptionsMenuStyle.addRow(panel, "options.shadow Resolution")
	conf = Settings.shadowResolution
	VideoPanel.optionsBoxes[6] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
	rowPanel, labels[9] = OptionsMenuStyle.addRow(panel, "options.ambient occlusion")
	conf = Settings.ambientOcclusion
	VideoPanel.optionsBoxes[7] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel, labels[10] = OptionsMenuStyle.addRow(panel, "options.antialiasing")
	conf = Settings.Antialiasing
	VideoPanel.optionsBoxes[8] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel, labels[11] = OptionsMenuStyle.addRow(panel, "options.glow")
	conf = Settings.glow
	VideoPanel.optionsBoxes[9] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel, labels[12] = OptionsMenuStyle.addRow(panel, "options.dynamic lights")
	conf = Settings.dynamicLights
	VideoPanel.optionsBoxes[10] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel, labels[13] = OptionsMenuStyle.addRow(panel, "options.model density")
	conf = Settings.modelDensity
	VideoPanel.optionsBoxes[11] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
end

function VideoPanel.update()
	
end