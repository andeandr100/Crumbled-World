require("Menu/MainMenu/optionsMenu.lua")
require("Menu/MainMenu/creditsMenu.lua")
require("Menu/MainMenu/customeGameMenu.lua")
require("Menu/MainMenu/mapEditorMenu.lua")
require("Menu/Campaign/campaignGameMenu.lua")
require("Menu/MainMenu/multiplayerMenuServerList.lua")
--this = SceneNode()

function restore(data)
	if data.form then
		data.form:setVisible(false)
		data.form:destroy()
		data.form = nil
	end
end

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
	end
	
	buttons = nil
	
	OptionsMenu.destroy()
end

function languageChanged()
	
	print("---- languageChanged ----")
	
	buttons[1].text = language:getText("exit")
	buttons[2].text = language:getText("campaign")
	buttons[3].text = language:getText("custome game")
	buttons[4].text = language:getText("multiplayer")
	buttons[5].text = language:getText("map editor")
	buttons[6].text = language:getText("options")
	buttons[7].text = language:getText("credits")
	
	for i=1, 7 do
		buttons[i].button:setText(buttons[i].text)
		buttons[i].button:setPanelSize(PanelSize(Vec2(-1), Vec2(math.max(buttons[i].text:getTextScale().x/2 + 1,1), 1)))
	end
	
	OptionsMenu.languageChanged()
	buttons[3].panel.languageChanged()
	MapEditorMenu.languageChanged()
	buttons[4].panel.languageChanged()
	buttons[2].panel.languageChanged()
end

function create()
	restoreData = {}
	setRestoreData(restoreData)
	
	local frame = 0
	
	
	
	local camera = this:getRootNode():findNodeByName("MainCamera")
	--camera = Camera()

	if camera then
		this:loadLuaScript("settings.lua")
		
		form = Form(camera, PanelSize(Vec2(-1,-1)), Alignment.TOP_LEFT);
		form:setLayout(FlowLayout(PanelSize(Vec2(0.01,0))));
		form:setRenderLevel(7)
		
		print("\n\n\n\n")
		print("createTopMenu\n")
		--Top Panel
		createTopMenu()
		print("Done\n")
		
		print("\n\n\n\n")
		--Main Area
		print("createMainArea\n")
		createMainArea()
		print("Done\n")
		
		restoreData.form = form
	else
		if loopUpdate == nil then
			error("nil update")
		end
		tmpUpdate = update;
		update = loopUpdate;
	end
	
	setRestoreData(restoreData)
	
	if settingsListener == nil then
		settingsListener = Listener("Settings")
	end
	settingsListener:registerEvent("LanguageChanged",languageChanged)

	return true
end

function loopUpdate()
	if this:getRootNode():findNodeByName("MainCamera") ~= nil then
		if tmpUpdate == nil then
			error("nil update")
		end
		update = tmpUpdate;
		create()
	end
	return true
end

function update()
	
	OptionsMenu.update()
	
	if form then
		form:update()
	end
	MapEditorMenu.update()
		
	--multiplayerPanel always update
	buttons[4].panel.update()
	--Campaign
	buttons[2].panel.update()
	
	if Core.getInput():getKeyDown(Key.escape) then
		for i=2, #buttons do
			if buttons[i].panel then
				buttons[i].panel:setVisible( false )
			end
		end
		pagePanel:setVisible( false )
	end
	
	return true
end

function toglePanelVisible(button,param)
	if frame == Core.getFrameNumber() then
		return
	end
	frame = Core.getFrameNumber()
	
	print("\n\n\nTogle visible")
	for i=2, #buttons do
		print("Button "..i)
		if buttons[i].panel then
			if buttons[i].button == button then
				print("set visible panel "..i)
				local childVisible = buttons[i].panel.getChildVisible and buttons[i].panel.getChildVisible()
				local visible = (not buttons[i].panel:getVisible()) or (childVisible ~= nil and childVisible or false)
				
				if not param then
					print("set visibility "..tostring( visible))
					buttons[i].panel:setVisible( visible )
				else
					print("set visibility "..tostring( visible)..", param")
					buttons[i].panel:setVisible( visible, param )
				end
				pagePanel:setVisible( visible )
			else
				buttons[i].panel:setVisible( false )
			end
		end
	end
	
	print("\n---------------------------\n")
	--needed
	--CustomeGameMenu.isVisible()
end

function quitGame()
	Core.quitMainMenu()
end

function createTopMenu()
	local topPanel = MainMenuStyle.createTopMenu(form, PanelSize(Vec2(1,0.027),PanelSizeType.WindowPercentBasedOnX))
	
	buttons = {}
	buttons[1] = {text = language:getText("exit")}
	buttons[2] = {text = language:getText("campaign")}
	buttons[3] = {text = language:getText("custome game")}--Singleplayer
	buttons[4] = {text = language:getText("multiplayer")}
	buttons[5] = {text = language:getText("map editor")}
	buttons[6] = {text = language:getText("options")}
	buttons[7] = {text = language:getText("credits")}

	
	print("button 1\n")
	buttons[1].button = MainMenuStyle.addTopMenuButton(topPanel, Vec2(buttons[1].text:getTextScale().x/2+1,1), buttons[1].text)
	buttons[1].button:addEventCallbackExecute(quitGame)
	
	local leftTopMenuPanel = topPanel:add(Panel(PanelSize(Vec2(-1))))
	leftTopMenuPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
	print("button 7\n")
	buttons[7].button = MainMenuStyle.addTopMenuButton(leftTopMenuPanel, Vec2(buttons[7].text:getTextScale().x/2+1,1), buttons[7].text)
	buttons[7].button:addEventCallbackExecute(toglePanelVisible)
	
	local centerTopPanel = leftTopMenuPanel:add(Panel(PanelSize(Vec2(-1))))
	centerTopPanel:setLayout(FlowLayout(Alignment.TOP_CENTER))
	
	
	for i=2, 6 do
		print("button "..i.."\n")
		buttons[i].button = MainMenuStyle.addTopMenuButton(centerTopPanel, Vec2(buttons[i].text:getTextScale().x/2+1,1), buttons[i].text)
		buttons[i].button:addEventCallbackExecute(toglePanelVisible)
	end
	
	local button = centerTopPanel:add(Button(PanelSize(Vec2(-1),Vec2(4,1)), "Gjame",ButtonStyle.SQUARE_LIGHT) )
	local edgeColor = MainMenuStyle.borderColor
	button:setEdgeColor(edgeColor)
	button:setEdgeHoverColor(edgeColor)
	button:setEdgeDownColor(Vec4(edgeColor:toVec3() * 0.8, edgeColor.w))
	
	button:setInnerColor(Vec4(0.18,0.18,0.18,1),Vec4(),Vec4(0,0,0,1))
	button:setInnerHoverColor(Vec4(0.08,0.08,0.08,1),Vec4(0.5,0.5,0.5,1),Vec4(0,0,0,1))
	button:setInnerDownColor(Vec4(0.08,0.08,0.08,1),Vec4(0.4,0.4,0.4,1),Vec4(0,0,0,1))
	button:setTextColor(MainMenuStyle.textColor)
	button:setTextHoverColor(Vec4(1))
	button:setTextDownColor(Vec4(1))
	
--	local testPanel = centerTopPanel:add(Panel(PanelSize(Vec2(-1),Vec2(4,1))))
--	local aGradient = Gradient()
--	aGradient:setGradientColorsVertical({Vec3(1.0), Vec3(1,1,0), Vec3(0,1,0), Vec3(0,0,1)})
--	testPanel:setBackground(aGradient)
	
--	local progresbar = centerTopPanel:add(ProgressBar(PanelSize(Vec2(-1),Vec2(4,1))))
--	progresbar:setColor({Vec3(0,1,0), Vec3(0,0.35,0), Vec3(1,1,0), Vec3(1,1,0),Vec3(0,1,1), Vec3(0,1,1)})
--	progresbar:setValue({0.4,0.2,0.4})
--	centerTopPanel:add(TextField(PanelSize(Vec2(-1),Vec2(4,1))))

end

function changePagePanelSize(panelSize)
	pagePanel:setPanelSize(panelSize)
end

function createMainArea()
	local mainAreaPanel = form:add(Panel(PanelSize(Vec2(-1))))
	mainAreaPanel:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
	pagePanel = mainAreaPanel:add(Panel(PanelSize(Vec2(-1,-0.95), Vec2(4,4))))
	pagePanel:setVisible(false)
	
	
	local borderSize =  0.00135
	pagePanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
	pagePanel:setBorder(DoubleBorder(BorderSize(Vec4(borderSize * 2)),MainMenuStyle.borderColor,BorderSize(Vec4(borderSize * 3)),Vec4(0,0,0,0.5), BorderSize(Vec4(borderSize)),MainMenuStyle.borderColor))
	
	print("CustomeGameMenu\n")
	buttons[3].panel = CustomeGameMenu.new(pagePanel)
	print("Multiplayer\n")
	buttons[4].panel = MultiplayerMenuServerList.new(pagePanel)
	print("CustomeGameMenu\n")
	buttons[2].panel = CampaignGameMenu.new(pagePanel)
	print("MapEditorMenu\n")
	buttons[5].panel = MapEditorMenu.create(pagePanel)
	print("OptionsMenu\n")
	buttons[6].panel = OptionsMenu.create(pagePanel)
	print("CreditsMenu\n")
	buttons[7].panel = CreditsMenu.create(pagePanel)

	--
	
	buttons[2].button:addEventCallbackExecute(buttons[2].panel.changedVisibility)
	buttons[3].button:addEventCallbackExecute(buttons[3].panel.changedVisibility)
	
	
	
	
	
	buttons[4].panel.setSingleCampaignButtons(buttons[3].button, buttons[2].button, buttons[5].button)
end