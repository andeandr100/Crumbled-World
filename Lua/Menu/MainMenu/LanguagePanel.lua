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
	languagePanel:setEnableYScroll()
	languagePanel:setVisible(false)
	
	LanguagePanel.createLanguageOptions(languagePanel)

	LanguagePanel.languagePanel = languagePanel

	settingsListener = Listener("Settings")
	
	return languagePanel
end

function LanguagePanel.changeLanguageComboBox(comboBox)
	print("---- change language to "..comboBox:getText():toString().." ----")
	language:setGlobalLanguage(comboBox:getText():toString())
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
	
	local changeToLanguage = button:getText():toString()
	if LanguagePanel.editLanguage ~= changeToLanguage then
		LanguagePanel.editLanguage = changeToLanguage
		local rows = LanguagePanel.rows
		for i=1, #rows do
			local editText = LanguagePanel.language:getText( rows[i].name, LanguagePanel.editLanguage, false )
			rows[i].textField:setText(editText)
			print("Edit "..rows[i].name.." "..LanguagePanel.editLanguage..": "..editText:toString())
		end
	end
end

function LanguagePanel.saveChanges()
	local rows = LanguagePanel.rows
	for i=1, #rows do
		LanguagePanel.language:setText( rows[i].name, LanguagePanel.editLanguage, rows[i].textField:getText() )
	end
	LanguagePanel.language:save()
	settingsListener:pushEvent("LanguageChanged")
	--Call mainMenu.lua functio
	if languageChanged then
		languageChanged()
	end
	
	
	--update language list
	local allLanguageges = language:getAllLanguageges()
	languageComboBox:clearItems()
	
	for i=1, #allLanguageges do
		local itemButton = languageComboBox:addItem( MainMenuStyle.createMenuButton(Vec2(-1,0.03), Vec2(), allLanguageges[i]) )
		itemButton:setTag(allLanguageges[i])
		itemButton:addEventCallbackExecute(LanguagePanel.changeLanguage)
	end
end

function LanguagePanel.sendToDeveloper()
	language:sendToDeveloper(LanguagePanel.editLanguage)
	
	VideoPanel.questionForm = QuestionForm.new( language:getText("Language file sent"), language:getText("Language update thx"), true, false, language:getText("Ok"), "" )
	VideoPanel.questionForm.setVisible(true)
end

function toggleEditLanguagePanel()
	LanguagePanel.editPanel:setVisible( not LanguagePanel.editPanel:getVisible())
--	changePagePanelSize( PanelSize(Vec2(-0.975,-0.95) ) )
--	LanguagePanel.languagePanel:setPanelSize(PanelSize(Vec2(-0.8,-0.95)))
end

function LanguagePanel.createLanguageOptions(panel)
	local language = LanguagePanel.language
	local allLanguageges = language:getAllLanguageges()
	
	
	local label = OptionsMenuStyle.addOptionsHeader( panel, language:getText("language") )
	label:setTag("language")
	LanguagePanel.labels[8] = label
	
	rowPanel, label = OptionsMenuStyle.addRow(panel, language:getText("language") )
	label:setTag("language")
	LanguagePanel.labels[1] = label
	languageComboBox = LanguagePanel.addComboBox( rowPanel, Vec2(-0.45,-1), allLanguageges, LanguagePanel.changeLanguage)
	languageComboBox:setText(language:getGlobalLanguage())
	languageComboBox:addEventCallbackChanged(LanguagePanel.changeLanguageComboBox)
	languageComboBox:setTag(Settings.islandSmoke.configName)
	
	
	--Advanced settings
	local editText = language:getText("edit language files")
	local textScale = editText:getTextScale() 
	panel:add(Panel(PanelSize(Vec2(-1,0.02))))
	local languageButton = panel:add(MainMenuStyle.createButton(Vec2(-1,0.04), Vec2(textScale.x/2+1,1), editText))
	languageButton:addEventCallbackExecute(toggleEditLanguagePanel)
	languageButton:setTag("edit language files")
	LanguagePanel.labels[2] = languageButton
	
	
	LanguagePanel.editLanguage = language:getGlobalLanguage()
	
	editPanel = panel:add(Panel(PanelSize(Vec2(-1))))
	editPanel:setLayout(FallLayout(PanelSize(Vec2(0,0.0015))))
	editPanel:setVisible(false)
	LanguagePanel.editPanel = editPanel

	rowPanel, label = OptionsMenuStyle.addRow(editPanel, language:getText("language file"))
	label:setTag("language file")
	LanguagePanel.labels[3] = label
	editLanguageComboBox = LanguagePanel.addComboBox( rowPanel, Vec2(-0.45,-1), allLanguageges, LanguagePanel.changeEditLanguage)
	editLanguageComboBox:setText(LanguagePanel.editLanguage)
	editLanguageComboBox:setTag(Settings.islandSmoke.configName)

	
	rowPanel, label = OptionsMenuStyle.addRow(editPanel, language:getText("add new language"))
	label:setTag("add new language")
	LanguagePanel.labels[4] = label
	addLanguageTextField = rowPanel:add(MainMenuStyle.createTextField(Vec2(-0.45,-1),Vec2(), ""))
	local addNewLanguageButton = rowPanel:add(MainMenuStyle.createButton(Vec2(-1),Vec2(3,1), language:getText("add")))
	addNewLanguageButton:addEventCallbackExecute(addLanguage)
	addNewLanguageButton:setTag("add")
	LanguagePanel.labels[5] = addNewLanguageButton
	
	--add spacing
--	editPanel:add(Panel(PanelSize(Vec2(-1,0.04))))
	
	local langaugeBottomPanel = editPanel:add(Panel(PanelSize(Vec2(-1))))
	langaugeBottomPanel:setLayout(FallLayout(Alignment.BOTTOM_RIGHT))
	local buttonPanel = langaugeBottomPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
	
	
	local saveButton = buttonPanel:add( MainMenuStyle.createButton(Vec2(-1),Vec2(3,1), language:getText("save")) )
	saveButton:addEventCallbackExecute(LanguagePanel.saveChanges)
	saveButton:setTag("save")
	LanguagePanel.labels[6] = saveButton
	
	local saveButton = buttonPanel:add( MainMenuStyle.createButton(Vec2(-1),Vec2(5,1), language:getText("send to developer")) )
	saveButton:addEventCallbackExecute(LanguagePanel.sendToDeveloper)
	saveButton:setTag("send to developer")
	LanguagePanel.labels[7] = saveButton
	
	LanguagePanel.panel = langaugeBottomPanel:add(Panel(PanelSize(Vec2(-1))))
	LanguagePanel.panel:setPadding(BorderSize(Vec4(0.005,0,0.005,0),true))
	LanguagePanel.panel:setEnableYScroll()
	LanguagePanel.panel:setBackground(Sprite(Vec4(0,0,0,0.6)))
	LanguagePanel.panel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)),MainMenuStyle.borderColor))
	
	LanguagePanel.rows = {}
	
	--menu bar
	addLanguageHeader("Menu bar")
	addLanguageRow("custome game")
	addLanguageRow("campaign")
	addLanguageRow("multiplayer")
	addLanguageRow("map editor")
	addLanguageRow("options")
	addLanguageRow("exit")
	addLanguageRow("credits")
	
	--menu bar
	addLanguageHeader("Menu")
	addLanguageRow("menu")
	addLanguageRow("continue")
	addLanguageRow("next map")
	addLanguageRow("tutorial")
	addLanguageRow("launch waves")
	addLanguageRow("restart")
	addLanguageRow("restart last wave")
	addLanguageRow("restart map")
	addLanguageRow("victory")
	addLanguageRow("defeated")
	addLanguageRow("quit to menu")
	addLanguageRow("quit to desktop")
	addLanguageRow("quit to map editor")
			
	--in game menu
	addLanguageHeader("Menu")	
	addLanguageRow("current wave")
	addLanguageRow("game speed")
	addLanguageRow("enemies remaining")
	addLanguageRow("money")
	addLanguageRow("life remaining")
	addLanguageRow("score")
	
	--stats menu
	addLanguageRow("Total gold earned")
	addLanguageRow("From kills")
	addLanguageRow("From interest")
	addLanguageRow("From waves")
	addLanguageRow("From towers")
	addLanguageRow("Spent in towers")
	addLanguageRow("Lost from selling")
	addLanguageRow("Gold left")
	addLanguageRow("Interest rate")
	
	--map informatio
	addSpace()
	addLanguageHeader("Map information")
	addLanguageRow("name")
	addLanguageRow("type")
	addLanguageRow("wave")
	addLanguageRow("difficulty")
	addLanguageRow("game mode")
	addLanguageRow("start game")
	addLanguageRow("shop")
	
	--map difficulty
	addLanguageHeader("Map difficulty")
	addLanguageRow("easy")
	addLanguageRow("normal")
	addLanguageRow("hard")
	addLanguageRow("extreme")
	addLanguageRow("insane")
	addLanguageRow("impossible")
	
	--map gamemodes
	addLanguageHeader("Map game modes")
	addLanguageRow("default")
	addLanguageRow("survival")
	addLanguageRow("rush")
	addLanguageRow("training")
	addLanguageRow("leveler")
	addLanguageRow("default tooltip")
	addLanguageRow("survival tooltip")
	addLanguageRow("rush tooltip")
	addLanguageRow("training tooltip")
	addLanguageRow("leveler tooltip")


	--map gamemodes
	addSpace()
	addLanguageHeader("Multiplayer information")
	addLanguageRow("servers")
	addLanguageRow("server browser")
	addLanguageRow("server name")
	addLanguageRow("back")
	addLanguageRow("players")
	addLanguageRow("map name")
	addLanguageRow("join server")
	addLanguageRow("create server")
	addLanguageRow("start server")
	addLanguageRow("save settings")
	addLanguageRow("direct connect")
	addLanguageRow("edit settings")
	addLanguageRow("ready")
	addLanguageRow("not ready")
	addLanguageRow("start")
	addLanguageRow("quit")
	addLanguageRow("leave")
	addLanguageRow("kick")
	addLanguageRow("ban")
	addLanguageRow("spectator")
	addLanguageRow("spectators")
	addLanguageRow("lobby")
	addLanguageRow("port forward")
	
	--map gamemodes
	addSpace()
	addLanguageHeader("Options bar")
	addLanguageRow("keybind")
	addLanguageRow("video")
	addLanguageRow("game")
	addLanguageRow("audio")
	addLanguageRow("language")

	--keybinds
	addLanguageHeader("Keybinds")
	addLanguageRow("press key")
	addLanguageRow("camera")
	addLanguageRow("camera lower")
	addLanguageRow("camera raise")
	addLanguageRow("change mode")
	addLanguageRow("backward")
	addLanguageRow("forward")
	addLanguageRow("left")
	addLanguageRow("right")
	addLanguageRow("speed")
	addLanguageRow("rotate left")
	addLanguageRow("rotate right")
	addLanguageRow("buildheader")
	addLanguageRow("deselect")
	addLanguageRow("locked rotation")
	addLanguageRow("place")
	addLanguageRow("sell")
	addLanguageRow("boost")
	addLanguageRow("upgrade")
	addLanguageRow("info screen")
	addLanguageRow("building 1")
	addLanguageRow("building 2")
	addLanguageRow("building 3")
	addLanguageRow("building 4")
	addLanguageRow("building 5")
	addLanguageRow("building 6")
	addLanguageRow("building 7")
	addLanguageRow("building 8")
	addLanguageRow("building 9")
	addLanguageRow("export")
	addLanguageRow("load")
	addLanguageRow("save")
	addLanguageRow("save as")
	addLanguageRow("npc input")
	addLanguageRow("ignore target")
	addLanguageRow("high priority")
	addLanguageRow("revert wave")
	addLanguageRow("waveheader")
	
	--video settings
	addLanguageHeader("Video settings")
	addLanguageRow("enabled")
	addLanguageRow("disabled")
	addLanguageRow("windowed")
	addLanguageRow("fullscreen")
	addLanguageRow("soft shadow")
	addLanguageRow("hard shadow")
	addLanguageRow("visible")
	addLanguageRow("hidden")
	addLanguageRow("Ok")
	addLanguageRow("fast")
	addLanguageRow("long")
	addLanguageRow("medium")
	addLanguageRow("short")
	addLanguageRow("none")
	addLanguageRow("highest")
	addLanguageRow("high")
	addLanguageRow("low")
	addLanguageRow("lowest")
	addLanguageRow("always")
	addLanguageRow("when damaged")
	addLanguageRow("need restart")
	addLanguageRow("need restart long")

	
	--video
	addLanguageHeader("Video")
	addLanguageRow("screen")
	addLanguageRow("window mode")
	addLanguageRow("resolution")
	addLanguageRow("render scale")
	addLanguageRow("vsync")
	
	--video
	addLanguageHeader("Graphic")
	addLanguageRow("graphic")
	addLanguageRow("shadow")
	addLanguageRow("shadow resolution")
	addLanguageRow("ambient occlusion")
	addLanguageRow("antialiasing")
	addLanguageRow("glow")
	addLanguageRow("dynamic lights")
	addLanguageRow("model density")
	
	--game
	addLanguageHeader("Game")
	addLanguageRow("game")
	addLanguageRow("island smoke")
	addLanguageRow("floating stones")
	addLanguageRow("health bar")
	addLanguageRow("death animation")
	addLanguageRow("corpse timer")
	addLanguageRow("monster path")
	addLanguageRow("tower menu")
	addLanguageRow("player")
	addLanguageRow("username")
	
	

	--audio
	addLanguageHeader("Volume")
	addLanguageRow("volume")
	addLanguageRow("master volume")
	addLanguageRow("effect volume")
	addLanguageRow("music volume")
	
	--audio
	addLanguageHeader("Language")
	addLanguageRow("add")
	addLanguageRow("add new language")
	addLanguageRow("language file")
	addLanguageRow("edit language files")
	addLanguageRow("send to developer")
	addLanguageRow("Language file sent")
	addLanguageRow("Language update thx")
	
	--Shop
	addSpace()
	addLanguageHeader("Shop panel")
	addLanguageRow("locked")
	addLanguageRow("unlocked")
	addLanguageRow("upgraded")
	addLanguageRow("activated in game")
	addLanguageRow("crystals to activate(enough crystals)")
	addLanguageRow("crystals to activate(no crystals)")
	addLanguageRow("crystals to unlock(enough crystals)")
	addLanguageRow("crystals to unlock(no crystals)")
	addLanguageRow("Level x is not unlocked")
	addLanguageRow("Max permenant upgrades")

	--NPC name
	addLanguageHeader("Enemy names")
	addLanguageRow("rat")
	addLanguageRow("rat_tank")
	addLanguageRow("reaper")
	addLanguageRow("scorpion")
	addLanguageRow("skeleton")
	addLanguageRow("skeleton_champion_back")
	addLanguageRow("skeleton_champion_front")
	addLanguageRow("stoneSpirit")
	addLanguageRow("turtle")
	addLanguageRow("hydra1")
	addLanguageRow("hydra2")
	addLanguageRow("hydra3")
	addLanguageRow("hydra4")
	addLanguageRow("hydra5")
	addLanguageRow("dino")
	addLanguageRow("electroSpirit")
	addLanguageRow("fireSpirit")
	
	addLanguageHeader("Tower names")
	addLanguageRow("arrow tower")
	addLanguageRow("blade tower")
	addLanguageRow("electric tower")
	addLanguageRow("minigun tower")
	addLanguageRow("swarm tower")
	addLanguageRow("wall tower")
	addLanguageRow("missile tower")
	addLanguageRow("quake tower")
	addLanguageRow("support tower")
	
	--Tower information
	addLanguageHeader("Tower info")
	addLanguageRow("tower level")
	addLanguageRow("lvl")
	addLanguageRow("req wave")
	addLanguageRow("shop required")
	addLanguageRow("not your tower")
	addLanguageRow("conflicting upgrade")
	addLanguageRow("w")
	addLanguageRow("damage")
	addLanguageRow("attack per second")
	addLanguageRow("charges per second")
	addLanguageRow("target range")
	addLanguageRow("burn damage per second")
	addLanguageRow("burn time")
	addLanguageRow("slow")
	addLanguageRow("blade speed")
	addLanguageRow("damage range")
	addLanguageRow("ignore this NPC")
	addLanguageRow("high priority")
	
	
	addLanguageRow("damage delt to enemies")
	addLanguageRow("damage per gold")
	addLanguageRow("gold earned")
	addLanguageRow("gold earned previous wave")
	
	
	addLanguageRow("attackClosestToExit")
	addLanguageRow("attackPriorityTarget")
	addLanguageRow("attackWeakestTarget")
	addLanguageRow("attackStrongestTarget")
	addLanguageRow("attackHighDensity")
	addLanguageRow("attackNoneBurningTarget")
	addLanguageRow("attackVariedTargets")
	
	--tutorial
	addLanguageHeader("Tutorial")
	for i=1, 11 do
		addLanguageRow("tutorial "..i)
	end
	
	
	
	addLanguageHeader("Arrow tower")
	addLanguageRow("Arrow tower level")
	addLanguageRow("Arrow tower boost")
	addLanguageRow("Arrow tower range")
	addLanguageRow("Arrow tower hardArrow")
	addLanguageRow("Arrow tower mark of death")
	addLanguageRow("Arrow tower smart targeting")
	addLanguageRow("Arrow tower rotate")
	
	addLanguageHeader("Minigun tower")
	addLanguageRow("minigun tower level")
	addLanguageRow("minigun tower boost")
	addLanguageRow("minigun tower range")
	addLanguageRow("minigun tower overcharge")
	addLanguageRow("minigun tower firecrit")
	addLanguageRow("minigun tower smart targeting")	
	
	addLanguageHeader("Blade tower")
	addLanguageRow("blade tower level")
	addLanguageRow("blade tower boost")
	addLanguageRow("blade tower attackSpeed")
	addLanguageRow("blade tower firecrit")
	addLanguageRow("blade tower slow")
	addLanguageRow("blade tower shield")
	
	addLanguageHeader("Electric tower")
	addLanguageRow("electric tower level")
	addLanguageRow("electric tower boost")
	addLanguageRow("electric tower range")
	addLanguageRow("electric tower slow")
	addLanguageRow("electric tower energy pool")
	addLanguageRow("electric tower energy regen")
	
	addLanguageHeader("Missile tower")
	addLanguageRow("missile tower level")
	addLanguageRow("missile tower boost")
	addLanguageRow("missile tower range")
	addLanguageRow("missile tower explosion")
	addLanguageRow("missile tower fire")
	addLanguageRow("missile tower shield destroyer")
	
	addLanguageHeader("Swarm tower")
	addLanguageRow("swarm tower level")
	addLanguageRow("swarm tower boost")
	addLanguageRow("swarm tower range")
	addLanguageRow("swarm tower damage")
	addLanguageRow("swarm tower fire")
	
	addLanguageHeader("Quake tower")
	addLanguageRow("quak tower level")
	addLanguageRow("quak tower boost")
	addLanguageRow("quak tower firecrit")
	addLanguageRow("quak tower fire")
	addLanguageRow("quak tower electric")
	
	addLanguageHeader("Support tower")
	addLanguageRow("support tower level")
	addLanguageRow("support tower boost")
	addLanguageRow("support tower range")
	addLanguageRow("support manager range")
	addLanguageRow("support tower damage")
	addLanguageRow("support manager damage")
	addLanguageRow("support tower weaken")
	addLanguageRow("support tower gold")
	
	
	addLanguageHeader("Default tower")
	addLanguageRow("free sub upgrade")
	addLanguageRow("sell tower")
	
	
	--map editor panel
	addLanguageHeader("Map editor")
	addLanguageRow("create a new map")
	addLanguageRow("edit map")
			
	--save and commit
	addSpace()

	
end

function addSpace()
	LanguagePanel.panel:add(Panel(PanelSize(Vec2(-1,0.035))))
end

function addLanguageHeader(text)
	LanguagePanel.panel:add(Label(PanelSize(Vec2(-1,0.035)), text, Vec3(0.94), Alignment.MIDDLE_LEFT))
end

function addLanguageRow(name)
	
	local englishText = LanguagePanel.language:getText( name, "English" )
	local editText = LanguagePanel.language:getText( name, LanguagePanel.editLanguage, false )
	local finalEnglishText = (englishText == Text("")) and name or englishText
	
	
	
	local textScale = Text(finalEnglishText):getTextScale(false).x/2
	local textField = nil
	
	if textScale > 6 then
		local label = LanguagePanel.panel:add(Label(PanelSize(Vec2(-1,0.025 * (1 + math.floor(textScale / 18.5)))),finalEnglishText, Vec3(0.8), Alignment.MIDDLE_LEFT))
		label:setTextHeight(0.0125)
		label:setParseTags(false)
		textField = LanguagePanel.panel:add( MainMenuStyle.createTextField(Vec2(-1,0.025),Vec2(), editText ) )
	else
		local rowPanel = LanguagePanel.panel:add(Panel(PanelSize(Vec2(-1,0.025))))
		rowPanel:setLayout(FlowLayout(PanelSize(Vec2(0.01,0))))
		local label = rowPanel:add(Label(PanelSize(Vec2(-1,-1), Vec2(6,1)), finalEnglishText, Vec3(0.8), Alignment.MIDDLE_RIGHT))
		label:setParseTags(false)
		
		textField = rowPanel:add(MainMenuStyle.createTextField(Vec2(-1,-1),Vec2(), editText ) )
	end
	

	LanguagePanel.rows[#LanguagePanel.rows + 1] = {name=name, textField=textField}
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