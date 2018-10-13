require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/settings.lua")
--this = SceneNode()

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

function create()
	
	if Settings.sendHighscore.getBoolValue() ~= nil and Settings.sendCrashRepport.getBoolValue() ~= nil and Settings.sendAnonymousStatistics.getBoolValue() ~= nil then
		return false
	end
	
--	print("sendHighscore: ".. tostring(Settings.sendHighscore.getBoolValue() ))
--	print("sendCrashRepport: "..( Settings.sendCrashRepport.getBoolValue() == nil and "nil" or tostring(Settings.sendCrashRepport.getBoolValue() )))
--	print("sendAnonymousStatistics: "..( Settings.sendAnonymousStatistics.getBoolValue() == nil and "nil" or tostring(Settings.sendAnonymousStatistics.getBoolValue() )) )
--	print("\n")
--	print("sendHighscore: "..tostring((Settings.sendHighscore.getBoolValue() ~= nil ) and Settings.sendHighscore.getBoolValue() or true))
--	print("sendCrashRepport: "..tostring((Settings.sendCrashRepport.getBoolValue() ~= nil ) and Settings.sendCrashRepport.getBoolValue() or true))
--	print("sendAnonymousStatistics: "..tostring((Settings.sendAnonymousStatistics.getBoolValue() ~= nil ) and Settings.sendAnonymousStatistics.getBoolValue() or true))
	
	local camera = ConvertToCamera( this:getRootNode():findNodeByName("MainCamera") )
	
--	abort()
	
	if camera then
		form = Form( camera, PanelSize(Vec2(1)), Alignment.TOP_LEFT)
		form:setName("Data Consent")
		form:setRenderLevel(12)
		form:setVisible(true)
		form:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
		form:setBackground(Sprite(Vec4(0,0,0,0.5)))
		
		mainPanel = form:add(Panel(PanelSize(Vec2(1,0.25),Vec2(4,2))))
		mainPanel:setLayout(FallLayout( Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		mainPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
		--mainPanel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		local borderSize =  0.00135
		mainPanel:setBorder(DoubleBorder(BorderSize(Vec4(borderSize * 2)),MainMenuStyle.borderColor,BorderSize(Vec4(borderSize * 3)),Vec4(0,0,0,0.5), BorderSize(Vec4(borderSize)),MainMenuStyle.borderColor))

		backgroundPanel = mainPanel

		textPanels = mainPanel:add(Label(PanelSize(Vec2(0.17,1), Vec2(7,1)), "Data consent", MainMenuStyle.textColorHighLighted, Alignment.MIDDLE_CENTER ))
		textPanels:setTag("Data consent")
		
		MainMenuStyle.createBreakLine(mainPanel)
		
		local botomPanel = mainPanel:add(Panel(PanelSize(Vec2(-1,-1))))
		botomPanel:setLayout(FallLayout( Alignment.BOTTOM_CENTER, PanelSize(Vec2(0,0.01)) ))
		
		
		-- Add ok button area
		local buttonPanel = botomPanel:add(Panel(PanelSize(Vec2(-0.9,0.035))))
		buttonPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		local okButton = MainMenuStyle.createButton( Vec2(-1,-0.8),Vec2(4,1), "Accept")
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
		local aLabel = row1:add(Label(PanelSize(Vec2(-1)), " Send highscore", MainMenuStyle.textColorHighLighted) )
		local aText = Text("This allows your highscore to be shared with other on the scoreboard.\nWithout this you score won't be saved.")
		combobox1:setToolTip(aText);
		aLabel:setToolTip(aText);
		
		
		box = row2:add(Panel(PanelSize(Vec2(-1),Vec2(1))))
		box:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		combobox2 = box:add(CheckBox(PanelSize(Vec2(-1),Vec2(1)), Settings.sendCrashRepport.getBoolValue() == nil or Settings.sendCrashRepport.getBoolValue() ))
		aLabel = row2:add(Label(PanelSize(Vec2(-1)), " Send error report", MainMenuStyle.textColorHighLighted) )
		aText = Text("This allows crash dump to be sent to our servers in case of a crash or when an error ocure in Lua, c++ or in glsl.\nThis helps debugging problem that is otherwise almost impossible to find and fix.")
		combobox2:setToolTip(aText);
		aLabel:setToolTip(aText);
		
		
		box = row3:add(Panel(PanelSize(Vec2(-1),Vec2(1))))
		box:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		combobox3 = box:add(CheckBox(PanelSize(Vec2(-1),Vec2(1)), Settings.sendAnonymousStatistics.getBoolValue() == nil or Settings.sendAnonymousStatistics.getBoolValue() ))
		aLabel = row3:add(Label(PanelSize(Vec2(-1)), " Send anonymous statistics", MainMenuStyle.textColorHighLighted) )
		aText = Text("This allows anonymous statistics about game play to be send to our server.\nThis helps balance and optimize the game")
		combobox3:setToolTip(aText);
		aLabel:setToolTip(aText);
	end

	return true
end

function update()
	if form:getVisible() then
		form:update()
	end
	return true
end