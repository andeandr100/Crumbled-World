require("Menu/MainMenu/optionsMenuStyle.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/settingsCombobox.lua")
require("Menu/settings.lua")
--this = SceneNode()

VideoPanel = {}

function VideoPanel.destroy()

end


function VideoPanel.create(mainPanel)
	local videoPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.8,-0.95))))
	videoPanel:setLayout(FallLayout(PanelSize(Vec2(0,0.0015))))
	videoPanel:setEnableScroll()
	videoPanel:setVisible(false)
	
	
	VideoPanel.createResolutionOptions(videoPanel)
	VideoPanel.createGraphicOptions(videoPanel)
	
	
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
	

	OptionsMenuStyle.addOptionsHeader( panel, "options.screen" )
	
	local rowPanel
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.window mode")
	conf = Settings.fullscreen
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.render scale")
	conf = Settings.renderScale
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.vsync")
	conf = Settings.vsync
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changeVSync )

	
	Core.setVsync(Settings.vsync.getValue())
end

function VideoPanel.createGraphicOptions(panel)
	
	OptionsMenuStyle.addOptionsHeader( panel, "options.graphic" )
	
	local rowPanel
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.island smoke")
	conf = Settings.islandSmoke
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsBool )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.floating stones")
	conf = Settings.floatingStones
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsBool )
	
	
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.shadow")
	conf = Settings.shadow
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.shadow Resolution")
	conf = Settings.shadowResolution
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.ambient occlusion")
	conf = Settings.ambientOcclusion
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.antialiasing")
	conf = Settings.Antialiasing
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.glow")
	conf = Settings.glow
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.dynamic lights")
	conf = Settings.dynamicLights
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.model density")
	conf = Settings.modelDensity
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
end

function VideoPanel.update()
	
end