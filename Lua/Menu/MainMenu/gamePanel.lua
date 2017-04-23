require("Menu/MainMenu/optionsMenuStyle.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/settingsCombobox.lua")
require("Menu/settings.lua")
require("Config/resolutions.lua")
--this = SceneNode()

GamePanel = {}
GamePanel.labels = {}
GamePanel.labelsText =  { "game", "island smoke", "floating stones", "health bar", "death animation", "corpse timer", "multiplayer", "name"}
GamePanel.optionsBoxes = {}

function GamePanel.create(mainPanel)
	local gamePanel = mainPanel:add(Panel(PanelSize(Vec2(-0.8,-0.95))))
	gamePanel:setLayout(FallLayout(PanelSize(Vec2(0,0.0015))))
	gamePanel:setEnableYScroll()
	gamePanel:setVisible(false)
	
	
	GamePanel.createGameOptions(gamePanel)
	GamePanel.createMultiplayerOptions(gamePanel)
	
	GamePanel.gamePanel = gamePanel

	settingsListener = Listener("Settings")
	
	--update text
	GamePanel.languageChanged()
	
	return gamePanel
end

function GamePanel.languageChanged()
	--update language
	local labels = GamePanel.labels	
	for i=1, #labels do
		labels[i]:setText(language:getText(GamePanel.labelsText[i]))
	end
	
	--update comboboxes
	for i=1, #GamePanel.optionsBoxes do
		GamePanel.optionsBoxes[i].updateLanguage()
	end
end

function GamePanel.changedSettingsBool(tag, index)
	Settings.config:get(tag):setBool(index == 1)
	Settings.config:save()	
	settingsListener:pushEvent("Changed")
end

function GamePanel.changedSettingsInt(tag, index, items)
	Settings.config:get(tag):setString(items[index])
	Settings.config:save()
	settingsListener:pushEvent("Changed")
end

function GamePanel.changedSettingsString(textField)
	
	local value = textField:getText():toString()
	Settings.config:get(textField:getTag():toString()):setString(value)
	Settings.config:save()
	
	settingsListener:pushEvent("Changed")
end

function GamePanel.createGameOptions(panel)
	
	local labels = GamePanel.labels
	local conf
	
	labels[1] = OptionsMenuStyle.addOptionsHeader( panel, "Game" )
		
	rowPanel, labels[2] = OptionsMenuStyle.addRow(panel, "Island smoke")
	conf = Settings.islandSmoke
	GamePanel.optionsBoxes[1] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsBool )
	
	rowPanel, labels[3] = OptionsMenuStyle.addRow(panel, "Floating stones")
	conf = Settings.floatingStones
	GamePanel.optionsBoxes[2] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsBool )
	
	rowPanel, labels[4] = OptionsMenuStyle.addRow(panel, "Health bar")
	conf = Settings.healthBar
	GamePanel.optionsBoxes[3] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsInt )
	
	rowPanel, labels[5] = OptionsMenuStyle.addRow(panel, "Death animation")
	conf = Settings.DeathAnimation
	GamePanel.optionsBoxes[4] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsInt )

	rowPanel, labels[6] = OptionsMenuStyle.addRow(panel, "corpse timer")
	conf = Settings.corpseTimer
	GamePanel.optionsBoxes[5] = SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsInt )

end

function GamePanel.createMultiplayerOptions(panel)
	local labels = GamePanel.labels
	labels[7] = OptionsMenuStyle.addOptionsHeader( panel, "Multiplayer" )
	
	rowPanel, labels[8] = OptionsMenuStyle.addRow(panel, "Name")
	local textField = rowPanel:add(MainMenuStyle.createTextField(Vec2(-0.45,-1), Vec2(),Settings.multiplayerName.getSettings()))
	textField:addEventCallbackChanged(GamePanel.changedSettingsString)
	textField:addEventCallbackExecute(GamePanel.updateClientName)
	textField:setTag(Settings.multiplayerName.configName)
	textField:setWhiteList("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ _-[]()=1234567890/.,")--< > \\ \" removed characters because of issues with totable() and <font ...>
	
	--set user name
	--Settings.multiplayerName.getSettings()
end

function GamePanel.updateClientName()
	Core.getNetworkClient():setUserName(Settings.multiplayerName.getSettings())
end


function GamePanel.update()
	
end