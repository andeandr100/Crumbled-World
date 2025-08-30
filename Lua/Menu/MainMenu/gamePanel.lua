require("Menu/MainMenu/optionsMenuStyle.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/settingsCombobox.lua")
require("Menu/settings.lua")
--this = SceneNode()
--languageChanged = Func()

GamePanel = {}
GamePanel.languageComboBox = nil
GamePanel.language = Language()

function GamePanel.create(mainPanel)
	local gamePanel = mainPanel:add(Panel(PanelSize(Vec2(-0.8,-0.95))))
	gamePanel:setLayout(FallLayout(PanelSize(Vec2(0,0.0015))))
	gamePanel:setEnableScroll()
	gamePanel:setVisible(false)
	
	
	GamePanel.createGameOptions(gamePanel)
	GamePanel.gamePanel = gamePanel

	settingsGamePanelListener = Listener("Settings")
	
	return gamePanel
end

function GamePanel.changeLanguageComboBox(comboBox)
	language:setLanguage(comboBox:getText():toString())
	settingsGamePanelListener:pushEvent("LanguageChanged")
	--Call mainMenu.lua functio
	
	Settings.config:get(Settings.Language.configName):setString(comboBox:getText():toString())
	Settings.config:save()	
end

function GamePanel.addLanguageComboBox(panel, size, items, callback)
	local button = panel:add(ComboBox(PanelSize(size), items[1]))
	
	for i=1, #items do
		local itemButton = button:addItem( MainMenuStyle.createMenuButton(Vec2(-1,0.03), Vec2(), items[i]) )
		itemButton:setTag(items[i])
		itemButton:addEventCallbackExecute(callback)
	end
	
	return button
end

function GamePanel.changeLanguage(button)
	--Split string
	GamePanel.languageComboBox:setText(button:getTag())
end

function GamePanel.changedSettingsBool(tag, index)
	Settings.config:get(tag):setBool(index == 1)
	Settings.config:save()	
	settingsGamePanelListener:pushEvent("Changed")
end

function GamePanel.changedSettingsInt(tag, index, items)
	Settings.config:get(tag):setString(items[index])
	Settings.config:save()
	settingsGamePanelListener:pushEvent("Changed")
end

function GamePanel.changedCursor(tag, index, items)
	
	if index == 1 then
		Core.setCursor("")
	elseif index == 2 then
		Core.setCursor("Data/Images/cursor16x16.bmp")
	elseif index == 3 then
		Core.setCursor("Data/Images/cursor24x24.bmp")
	elseif index == 4 then
		Core.setCursor("Data/Images/cursor32x32.bmp")
	elseif index == 5 then
		Core.setCursor("Data/Images/cursor48x48.bmp")
	else
		Core.setCursor("Data/Images/cursor64x64.bmp")
	end
	
	Settings.cursor.setValue(items[index])
end

function GamePanel.changedSettingsString(textField)
	
	local value = textField:getText():toString()
	Settings.config:get(textField:getTag():toString()):setString(value)
	Settings.config:save()
	
	settingsGamePanelListener:pushEvent("Changed")
end

function GamePanel.openConsnetMenu(button)
	
	settingsGamePanelListener:pushEvent("OpenConsentWindow")
	
end

function GamePanel.createGameOptions(panel)
	
	local conf
	
	OptionsMenuStyle.addOptionsHeader( panel, "general.game" )
		
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.cursor")
	conf = Settings.cursor
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedCursor )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.health bar")
	conf = Settings.healthBar
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsInt )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.death animation")
	conf = Settings.DeathAnimation
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsInt )

	rowPanel = OptionsMenuStyle.addRow(panel, "options.corpse timer")
	conf = Settings.corpseTimer
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsInt )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "options.tower menu")
	conf = Settings.towerMenu
	SettingsComboBox.new(rowPanel, PanelSize(Vec2(-0.45, -1)), conf.options, conf.configName, conf.getSettings(), GamePanel.changedSettingsBool )
	
	--Consent Options
	OptionsMenuStyle.addOptionsHeader( panel, "consent.user consent" )
	rowPanel = OptionsMenuStyle.addRow(panel, "consent.consent")
	local button = MainMenuStyle.createButton( Vec2(-0.45,-1), nil, "consent.change consent")	
	rowPanel:add(button)
	button:addEventCallbackExecute(GamePanel.openConsnetMenu)
	--Language
	
	language = GamePanel.language
	local allLanguageges = language:getAllLanguageges()
	
	
	OptionsMenuStyle.addOptionsHeader( panel, "general.language" )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "general.language" )
	GamePanel.languageComboBox = GamePanel.addLanguageComboBox( rowPanel, Vec2(-0.45,-1), allLanguageges, GamePanel.changeLanguage)
	GamePanel.languageComboBox:setText(language:getLanguage())
	GamePanel.languageComboBox:addEventCallbackChanged(GamePanel.changeLanguageComboBox)
	GamePanel.languageComboBox:setTag(Settings.islandSmoke.configName)

	
	--userName
	OptionsMenuStyle.addOptionsHeader( panel, "options.player" )
	
	rowPanel = OptionsMenuStyle.addRow(panel, "general.name")
	local textField = rowPanel:add(MainMenuStyle.createTextField(Vec2(-0.45,-1), Vec2(),Settings.multiplayerName.getSettings()))
	--textField = TextField()
	textField:addEventCallbackChanged(GamePanel.changedSettingsString)
	textField:addEventCallbackExecute(GamePanel.updateClientName)
	textField:setTag(Settings.multiplayerName.configName)
	textField:setWhiteList("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ _-[]()=1234567890/.,")--< > \\ \" removed characters because of issues with totable() and <font ...>
end

function GamePanel.updateClientName()
	Core.getNetworkClient():setUserName(Settings.multiplayerName.getSettings())
end

function GamePanel.update()
	
end