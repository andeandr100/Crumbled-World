require("Menu/MainMenu/optionsMenuStyle.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/settings.lua")
require("Menu/questionForm.lua")

--this = SceneNode()

LanguagePanel = {}
LanguagePanel.comboBoxList = {}
LanguagePanel.language = Language()
LanguagePanel.panel = nil
LanguagePanel.editLanguage = ""
LanguagePanel.labels = {}

function LanguagePanel.languageChanged()
	for i=1, #LanguagePanel.labels do
		LanguagePanel.labels[i]:setText( language:getText( LanguagePanel.labels[i]:getTag():toString() ) )
	end
end

function LanguagePanel.create(mainPanel)
	local languagePanel = mainPanel:add(Panel(PanelSize(Vec2(-0.8,-0.95))))
	languagePanel:setLayout(FallLayout(PanelSize(Vec2(0,0.0015))))
	languagePanel:setEnableScroll()
	languagePanel:setVisible(false)
	
	LanguagePanel.createLanguageOptions(languagePanel)

	LanguagePanel.languagePanel = languagePanel

	settingsListener = Listener("Settings")
	
	return languagePanel
end

function LanguagePanel.changeLanguageComboBox(comboBox)
	print("---- change language to "..comboBox:getText():toString().." ----")
	language:setLanguage(comboBox:getText():toString())
	settingsListener:pushEvent("LanguageChanged")
	--Call mainMenu.lua functio
	if languageChanged then
		languageChanged()
	end
	
	Settings.config:get(Settings.Language.configName):setString(comboBox:getText():toString())
	Settings.config:save()	
end

function addLanguage(button)
	--addLanguageTextField = TextField()
	if addLanguageTextField:getText() ~= "" then
		local newLanguage = addLanguageTextField:getText()
		addLanguageTextField:setText("")
		local itemButton = editLanguageComboBox:addItem( MainMenuStyle.createMenuButton(Vec2(-1,0.03), Vec2(), newLanguage) )
		itemButton:setTag(newLanguage)
		itemButton:addEventCallbackExecute(LanguagePanel.changeEditLanguage)
		LanguagePanel.changeEditLanguage(itemButton)
	end
end

function LanguagePanel.changeEditLanguage(button)
	editLanguageComboBox:setText(button:getText())
end


function toggleEditLanguagePanel()
	LanguagePanel.editPanel:setVisible( not LanguagePanel.editPanel:getVisible())
end

function LanguagePanel.createLanguageOptions(panel)
	local language = LanguagePanel.language
	local allLanguageges = language:getAllLanguageges()
	
	
	local label = OptionsMenuStyle.addOptionsHeader( panel, language:getText("general.language") )
	label:setTag("general.language")
	LanguagePanel.labels[8] = label
	
	rowPanel, label = OptionsMenuStyle.addRow(panel, language:getText("general.language") )
	label:setTag("general.language")
	LanguagePanel.labels[1] = label
	languageComboBox = LanguagePanel.addComboBox( rowPanel, Vec2(-0.45,-1), allLanguageges, LanguagePanel.changeLanguage)
	languageComboBox:setText(language:getLanguage())
	languageComboBox:addEventCallbackChanged(LanguagePanel.changeLanguageComboBox)
	languageComboBox:setTag(Settings.islandSmoke.configName)
	
	
end


function LanguagePanel.updateClientName()
	Core.getNetworkClient():setUserName(Settings.multiplayerName.getSettings())
end

function LanguagePanel.addComboBox(panel, size, items, callback)
	local button = panel:add(ComboBox(PanelSize(size), items[1]))
	LanguagePanel.comboBoxList[#LanguagePanel.comboBoxList+1] = button
	
	for i=1, #items do
		local itemButton = button:addItem( MainMenuStyle.createMenuButton(Vec2(-1,0.03), Vec2(), items[i]) )
		itemButton:setTag(items[i])
		itemButton:addEventCallbackExecute(callback)
	end
	
	return button
end

function LanguagePanel.changeLanguage(button)
	--Split string
	languageComboBox:setText(button:getTag())
end

function LanguagePanel.update()
	
end