require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/settings.lua")
--this = SceneNode()

language = Language()
labels = {}
toolTips = {}
toolTipTags = {}

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

function callbackOk(button)
	
	Settings.sendHighscore.setBoolValue(combobox1:getSelected())
	Settings.sendCrashRepport.setBoolValue(combobox2:getSelected())
	Settings.sendAnonymousStatistics.setBoolValue(combobox3:getSelected())
	
	form:setVisible(false)
end

function OpenConsentWindow()
	
	form:setVisible(true)
	
	for i=1, #labels do
		labels[i]:setText(language:getText(labels[i]:getTag():toString()))
	end
	for i=1, #toolTips do
		toolTips[i]:setToolTip(language:getText(toolTipTags[i]))
	end
end

function addLabel(label, toolTipTag)
	local tag = label:getText():toString()
	label:setTag(tag)
	label:setText(language:getText(tag))
	labels[#labels+1] = label
	
	if toolTipTag then
		addToolTip(label, toolTipTag)
	end
end
function addToolTip(label, toolTipTag)
	toolTips[#toolTips+1] = label
	toolTipTags[#toolTipTags+1] = toolTipTag
	label:setToolTip(language:getText(toolTipTags[#toolTipTags]))
end

function create()
	
	local camera = this:getRootNode():findNodeByName("MainCamera")
	
	settingsListener = Listener("Settings")
	settingsListener:registerEvent("OpenConsentWindow", OpenConsentWindow)
	
	if camera then
		form = Form( ConvertToCamera(camera), PanelSize(Vec2(1)), Alignment.TOP_LEFT, "DataConsentForm")
		form:setName("Data Consent")
		form:setRenderLevel(12)
		form:setVisible(true)
		form:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
		form:setBackground(Sprite(Vec4(0,0,0,0.5)))
		
		mainPanel = form:add(Panel(PanelSize(Vec2(1,0.25),Vec2(4,2))))
		mainPanel:setLayout(FallLayout( Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		mainPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
		local borderSize =  0.00135
		mainPanel:setBorder(DoubleBorder(BorderSize(Vec4(borderSize * 2)),MainMenuStyle.borderColor,BorderSize(Vec4(borderSize * 3)),Vec4(0,0,0,0.5), BorderSize(Vec4(borderSize)),MainMenuStyle.borderColor))

		backgroundPanel = mainPanel

		textPanels = mainPanel:add(Label(PanelSize(Vec2(0.17,1), Vec2(7,1)), "consent.data consent", MainMenuStyle.textColorHighLighted, Alignment.MIDDLE_CENTER ))
		addLabel(textPanels)
		
		MainMenuStyle.createBreakLine(mainPanel)
		
		local botomPanel = mainPanel:add(Panel(PanelSize(Vec2(-1,-1))))
		botomPanel:setLayout(FallLayout( Alignment.BOTTOM_CENTER, PanelSize(Vec2(0,0.01)) ))
		
		
		-- Add ok button area
		local buttonPanel = botomPanel:add(Panel(PanelSize(Vec2(-0.9,0.035))))
		buttonPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		local okButton = MainMenuStyle.createButton( Vec2(-1,-0.8),Vec2(4,1), "consent.accept")
		addLabel(okButton)
		okButton:addEventCallbackExecute(callbackOk)
		buttonPanel:add(okButton)
		
		MainMenuStyle.createBreakLine(botomPanel)
		
		
		-- Add main body area
		local textArea = botomPanel:add(Panel(PanelSize(Vec2(-0.9,-1))))
		textArea:setLayout(GridLayout(3,1, Alignment.MIDDLE_LEFT, PanelSize(Vec2(MainMenuStyle.borderSize*3),Vec2(1))))
		
		local row1 = textArea:add(Panel(PanelSize(Vec2(-1,-1))))
		local row2 = textArea:add(Panel(PanelSize(Vec2(-1,-1))))
		local row3 = textArea:add(Panel(PanelSize(Vec2(-1,-1))))
		
		-- Consent question		
		local box = row1:add(Panel(PanelSize(Vec2(-1),Vec2(1))))
		box:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		combobox1 = box:add(CheckBox(PanelSize(Vec2(-1),Vec2(1)), Settings.sendHighscore.getBoolValue() == nil or Settings.sendHighscore.getBoolValue() ))
		local aLabel = row1:add(Label(PanelSize(Vec2(-1)), "consent.send highscore", MainMenuStyle.textColorHighLighted) )
		addLabel(aLabel, "consent.send highscore tooltip")
		addToolTip(combobox1, "consent.send highscore tooltip")
		
		
		box = row2:add(Panel(PanelSize(Vec2(-1),Vec2(1))))
		box:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		combobox2 = box:add(CheckBox(PanelSize(Vec2(-1),Vec2(1)), Settings.sendCrashRepport.getBoolValue() == nil or Settings.sendCrashRepport.getBoolValue() ))
		aLabel = row2:add(Label(PanelSize(Vec2(-1)), "consent.send error report", MainMenuStyle.textColorHighLighted) )
		addLabel(aLabel, "consent.send error report tooltip")
		addToolTip(combobox2, "consent.send error report tooltip" )
		
		
		box = row3:add(Panel(PanelSize(Vec2(-1),Vec2(1))))
		box:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		combobox3 = box:add(CheckBox(PanelSize(Vec2(-1),Vec2(1)), Settings.sendAnonymousStatistics.getBoolValue() == nil or Settings.sendAnonymousStatistics.getBoolValue() ))
		aLabel = row3:add(Label(PanelSize(Vec2(-1)), "consent.send anonymous statistics", MainMenuStyle.textColorHighLighted) )
		addLabel(aLabel, "consent.send anonymous statistics tooltip")
		addToolTip(combobox3, "consent.send anonymous statistics tooltip")
	else
		return false
	end
	
	if Settings.sendHighscore.getBoolValue() ~= nil and Settings.sendCrashRepport.getBoolValue() ~= nil and Settings.sendAnonymousStatistics.getBoolValue() ~= nil then
		form:setVisible(false)
	end

	return true
end

function update()
	if form:getVisible() then
		form:update()
	end
	return true
end