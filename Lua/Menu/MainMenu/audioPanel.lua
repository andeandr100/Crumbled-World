require("Menu/MainMenu/optionsMenuStyle.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/settings.lua")
--this = SceneNode()
AudioPanel = {}

function AudioPanel.create(mainPanel)
	local audioPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.8,-0.95))))
	audioPanel:setLayout(FallLayout(PanelSize(Vec2(0,0.0015))))
	audioPanel:setEnableYScroll()
	audioPanel:setVisible(false)
	
	
	AudioPanel.createAudioSettings(audioPanel)
	
	AudioPanel.audioPanel = audioPanel
	return audioPanel
	
end

function AudioPanel.languageChanged()
	VolumeLabel:setText(language:getText("volume"))
	masterVolumeLabel:setText(language:getText("master volume"))
	effectVolume:setText(language:getText("effect volume"))
	musicVolume:setText(language:getText("music volume"))
end

function AudioPanel.changeGain(slider)
	if slider:getTag():toString() == "Master" then
		Settings.soundMasterGain.setGain(slider:getValue()/100.0)
		Core.setSounMasterGain(slider:getValue()/100.0)
	elseif slider:getTag():toString() == "Effect" then
		Settings.soundEffectGain.setGain(slider:getValue()/100.0)
		Core.setSounEffectGain(slider:getValue()/100.0)
	elseif slider:getTag():toString() == "Music" then
		Settings.soundMusicGain.setGain(slider:getValue()/100.0)
		Core.setSoundMusicGain((slider:getValue()/100.0)*0.4)
	end
end

function AudioPanel.createAudioSettings(panel)
	
	VolumeLabel = OptionsMenuStyle.addOptionsHeader( panel, "Volume" )
	
	local rowPanel
	rowPanel, masterVolumeLabel = OptionsMenuStyle.addRow(panel, "Master volume")
	local slider = rowPanel:add(Slider(PanelSize(Vec2(-0.45,-1)), 0, 100, Settings.soundMasterGain.getGain() * 100, "%"))
	slider:setTag(Text("Master"))
	slider:addEventCallbackExecute(AudioPanel.changeGain)
	slider:addEventCallbackChanged(AudioPanel.changeGain)
	
	rowPanel, effectVolume = OptionsMenuStyle.addRow(panel, "Effect volume")
	slider = rowPanel:add(Slider(PanelSize(Vec2(-0.45,-1)), 0, 100, Settings.soundEffectGain.getGain() * 100, "%"))
	slider:setTag(Text("Effect"))
	slider:addEventCallbackExecute(AudioPanel.changeGain)
	slider:addEventCallbackChanged(AudioPanel.changeGain)
	
	rowPanel, musicVolume = OptionsMenuStyle.addRow(panel, "Music volume")
	slider = rowPanel:add(Slider(PanelSize(Vec2(-0.45,-1)), 0, 100, Settings.soundMusicGain.getGain() * 100, "%"))
	slider:setTag(Text("Music"))
	slider:addEventCallbackExecute(AudioPanel.changeGain)
	slider:addEventCallbackChanged(AudioPanel.changeGain)
end