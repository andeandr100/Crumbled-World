require("Menu/MainMenu/optionsMenuStyle.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/settingsCombobox.lua")
require("Menu/settings.lua")
require("Menu/questionForm.lua")
--this = SceneNode()

VideoPanel = {}
VideoPanel.questionForm = nil
VideoPanel.labels = {}
VideoPanel.labelsText =  { "screen", "window mode", "resolution", "render scale", "vsync", "graphic", "shadow", "shadow resolution", "ambient occlusion", "antialiasing", "glow", "dynamic lights", "model density" }
VideoPanel.optionsBoxes = {}

function VideoPanel.destroy()
	VideoPanel.questionForm.destroy()
end

function VideoPanel.languageChanged()
	VideoPanel.questionForm.destroy()
	VideoPanel.questionForm = QuestionForm.new( language:getText("need restart"), language:getText("need restart long"), true, false, language:getText("Ok"), language:getText("Cancel") )
	
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
	videoPanel:setEnableYScroll()
	videoPanel:setVisible(false)
	
	
	VideoPanel.createResolutionOptions(videoPanel)
	VideoPanel.createGraphicOptions(videoPanel)
	
	--set text
	local labels = VideoPanel.labels	
	for i=1, #labels do
		if labels[i] then
			labels[i]:setText(language:getText(VideoPanel.labelsText[i]))
		end
	end
	
	VideoPanel.videoPanel = videoPanel
	VideoPanel.questionForm = QuestionForm.new( language:getText("need restart"), language:getText("need restart long"), true, false, language:getText("Ok"), language:getText("Cancel") )
	
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
	
	labels[1] = OptionsMenuStyle.addOptionsHeader( panel, "Screen" )
	
	local rowPanel
	
	rowPanel, labels[2] = OptionsMenuStyle.addRow(panel, "Window mode")
	conf = Settings.fullscreen
	VideoPanel.optionsBoxes[1] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	

	labels[3] = nil
	VideoPanel.optionsBoxes[2] = nil
	
	rowPanel, labels[4] = OptionsMenuStyle.addRow(panel, "Render scale")
	conf = Settings.renderScale
	VideoPanel.optionsBoxes[3] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
	rowPanel, labels[5] = OptionsMenuStyle.addRow(panel, "Vsync")
	conf = Settings.vsync
	VideoPanel.optionsBoxes[4] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changeVSync )

	
	Core.setVsync(Settings.vsync.getValue())
end

function VideoPanel.createGraphicOptions(panel)
	local labels = VideoPanel.labels
	labels[6] = OptionsMenuStyle.addOptionsHeader( panel, "Graphic" )
	
	local rowPanel
	
	rowPanel, labels[7] = OptionsMenuStyle.addRow(panel, "Shadow")
	conf = Settings.shadow
	VideoPanel.optionsBoxes[5] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
	rowPanel, labels[8] = OptionsMenuStyle.addRow(panel, "Shadow Resolution")
	conf = Settings.shadowResolution
	VideoPanel.optionsBoxes[6] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
	rowPanel, labels[9] = OptionsMenuStyle.addRow(panel, "Ambient occlusion")
	conf = Settings.ambientOcclusion
	VideoPanel.optionsBoxes[7] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel, labels[10] = OptionsMenuStyle.addRow(panel, "Antialiasing")
	conf = Settings.Antialiasing
	VideoPanel.optionsBoxes[8] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel, labels[11] = OptionsMenuStyle.addRow(panel, "Glow")
	conf = Settings.glow
	VideoPanel.optionsBoxes[9] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel, labels[12] = OptionsMenuStyle.addRow(panel, "Dynamic lights")
	conf = Settings.dynamicLights
	VideoPanel.optionsBoxes[10] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsBool )
	
	rowPanel, labels[13] = OptionsMenuStyle.addRow(panel, "Model density")
	conf = Settings.modelDensity
	VideoPanel.optionsBoxes[11] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), VideoPanel.changedSettingsInt )
	
end

function VideoPanel.update()
	if VideoPanel.questionForm then
		VideoPanel.questionForm.update()
	end
end