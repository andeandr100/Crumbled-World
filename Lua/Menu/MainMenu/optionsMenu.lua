require("Menu/MainMenu/inputPanel.lua")
require("Menu/MainMenu/videoPanel.lua")
require("Menu/MainMenu/gamePanel.lua")
require("Menu/MainMenu/audioPanel.lua")
require("Menu/MainMenu/LanguagePanel.lua")

--this = SceneNode()

OptionsMenu = {}

function OptionsMenu.destroy()
	VideoPanel.destroy()
end

function OptionsMenu.create(panel)
	--Options panel
	local optionsPanel = panel:add(Panel(PanelSize(Vec2(-1))))
	optionsPanel:setLayout(FlowLayout(Alignment.TOP_CENTER))
	--Top menu button panel
	OptionsMenu.TopMenu(optionsPanel)
	
	--Add BreakLine
	local breakLinePanel = optionsPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
	local gradient = Gradient()
	gradient:setGradientColorsHorizontal({Vec3(0.45),Vec3(0.90),Vec3(0.45)})
	breakLinePanel:setBackground(gradient)
	

	OptionsMenu.createPages(optionsPanel)
	
	togleVisibleOptionsPanel(gameButton)
	
	optionsPanel:setVisible(false)
	return optionsPanel
end

function togleVisibleOptionsPanel(button)
	if inputButton ==  button then
		InputPanel.inputPanel:setVisible(true)
		VideoPanel.videoPanel:setVisible(false)
		AudioPanel.audioPanel:setVisible(false)
		GamePanel.gamePanel:setVisible(false)
		LanguagePanel.languagePanel:setVisible(false)
	elseif videoButton == button then
		InputPanel.inputPanel:setVisible(false)
		VideoPanel.videoPanel:setVisible(true)
		AudioPanel.audioPanel:setVisible(false)
		GamePanel.gamePanel:setVisible(false)
		LanguagePanel.languagePanel:setVisible(false)
	elseif gameButton == button then
		InputPanel.inputPanel:setVisible(false)
		VideoPanel.videoPanel:setVisible(false)
		AudioPanel.audioPanel:setVisible(false)
		GamePanel.gamePanel:setVisible(true)
		LanguagePanel.languagePanel:setVisible(false)
	elseif audioButton == button then
		InputPanel.inputPanel:setVisible(false)
		VideoPanel.videoPanel:setVisible(false)
		AudioPanel.audioPanel:setVisible(true)
		GamePanel.gamePanel:setVisible(false)
		LanguagePanel.languagePanel:setVisible(false)
	else
		InputPanel.inputPanel:setVisible(false)
		VideoPanel.videoPanel:setVisible(false)
		AudioPanel.audioPanel:setVisible(false)
		GamePanel.gamePanel:setVisible(false)
		LanguagePanel.languagePanel:setVisible(true)
	end
end

function OptionsMenu.updateButton(button, textId )
	local text = language:getText(textId)
	button:setText(text)
	button:setPanelSize(PanelSize(Vec2(-1),Vec2(math.max(text:getTextScale().x/2 + 1,1), 1)))
	
	button:setTextColor(Vec3(0.7))
	button:setTextHoverColor(Vec3(0.92))
	button:setTextDownColor(Vec3(1))
end

function OptionsMenu.languageChanged()
	
	OptionsMenu.updateButton(videoButton, "video")
	OptionsMenu.updateButton(inputButton, "keybind")
	OptionsMenu.updateButton(gameButton, "game")
	OptionsMenu.updateButton(audioButton, "audio")
	OptionsMenu.updateButton(languageButton, "language")
	
	VideoPanel.languageChanged()
	GamePanel.languageChanged()
	AudioPanel.languageChanged()
	InputPanel.languageChanged()
	LanguagePanel.languageChanged()
end

function OptionsMenu.TopMenu(optionsPanel)
	
	local topPanel = optionsPanel:add(Panel(PanelSize(Vec2(-1,0.04))))
	topPanel:setLayout(FlowLayout(Alignment.TOP_CENTER))
	
	gameButton = MainMenuStyle.addTopMenuButton(topPanel, Vec2(4,1), "")
	inputButton = MainMenuStyle.addTopMenuButton(topPanel, Vec2(4,1), "")
	videoButton = MainMenuStyle.addTopMenuButton(topPanel, Vec2(4,1), "")
	audioButton = MainMenuStyle.addTopMenuButton(topPanel, Vec2(4,1), "")
	languageButton = MainMenuStyle.addTopMenuButton(topPanel, Vec2(4,1), "")
	
	OptionsMenu.updateButton(inputButton, "keybind")
	OptionsMenu.updateButton(videoButton, "video")
	OptionsMenu.updateButton(gameButton, "game")
	OptionsMenu.updateButton(audioButton, "audio")
	OptionsMenu.updateButton(languageButton, "language")
	
	inputButton:addEventCallbackExecute(togleVisibleOptionsPanel)
	videoButton:addEventCallbackExecute(togleVisibleOptionsPanel)
	gameButton:addEventCallbackExecute(togleVisibleOptionsPanel)
	audioButton:addEventCallbackExecute(togleVisibleOptionsPanel)
	languageButton:addEventCallbackExecute(togleVisibleOptionsPanel)
	
	
end

function OptionsMenu.createPages(optionsPanel)
	
	local mainArea = optionsPanel:add(Panel(PanelSize(Vec2(1,-1),PanelSizeType.ParentPercent)))
	mainArea:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
	local panelArea = mainArea:add(Panel(PanelSize(Vec2(-0.8,-1))))
	panelArea:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
	
	InputPanel.create(panelArea)	
	VideoPanel.create(panelArea)
	GamePanel.create(panelArea)
	AudioPanel.create(panelArea)
	LanguagePanel.create(panelArea)
	
	
	
end

function OptionsMenu.update()
	InputPanel.update()
	GamePanel.update()
	VideoPanel.update()
end