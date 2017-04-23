--this = Panel()

OptionsPanel = {} 

function OptionsPanel.hideAllPanels()
	OptionsPanel.gamePanel:setVisible(false);
	OptionsPanel.grapicPanel:setVisible(false);
	OptionsPanel.KeyBindsPanel:setVisible(false);
end

function OptionsPanel.showGamePanel(panel)
	OptionsPanel.hideAllPanels()
	OptionsPanel.gamePanel:setVisible(true);
	print("game\n");
end
function OptionsPanel.showGraphicPanel(panel)
	OptionsPanel.hideAllPanels()
	OptionsPanel.grapicPanel:setVisible(true);
	print("Graphic\n");
end
function OptionsPanel.showKeyBindsPanel(panel)
	OptionsPanel.hideAllPanels()
	OptionsPanel.KeyBindsPanel:setVisible(true);
	print("KeyBinds\n");
end

function OptionsPanel.togleVisible(panel)
	OptionsPanel.optionPanel:setVisible(not OptionsPanel.optionPanel:getVisible());
end

function OptionsPanel.addBreakLine(panel)
	local line = panel:add(Panel(PanelSize(Vec2(1,0.0025), PanelSizeType.ParentPercent)))
	line:setBackground(Sprite(Vec4(1,1,1,0.75)));
end

function OptionsPanel.create(optionPanel)
	--optionPanel = Panel()

	OptionsPanel.optionPanel = optionPanel
	optionPanel:setBackground(Sprite(Vec4(1.0, 1.0, 1.0, 0.6)))

	optionPanel:setPadding(BorderSize(Vec4(0.05)))
	optionPanel:setLayout(FlowLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0.01))))
	
	optionPanel:add(Label(PanelSize(Vec2(-1,0.1)),"<b>Options", Alignment.MIDDLE_CENTER))

	OptionsPanel.addBreakLine(optionPanel)

	local gameButton = optionPanel:add(Button(PanelSize(Vec2(0.3,0.1),Vec2(4,1), PanelSizeType.ParentPercent), "Game"))
	local graphicButton = optionPanel:add(Button(PanelSize(Vec2(0.3,0.1),Vec2(4,1), PanelSizeType.ParentPercent), "Graphic"))
	local keyBindsButton = optionPanel:add(Button(PanelSize(Vec2(0.3,0.1),Vec2(4,1), PanelSizeType.ParentPercent), "Key binds"))

	gameButton:addEventCallbackExecute("OptionsPanel.showGamePanel")
	graphicButton:addEventCallbackExecute("OptionsPanel.showGraphicPanel")
	keyBindsButton:addEventCallbackExecute("OptionsPanel.showKeyBindsPanel")

	OptionsPanel.addBreakLine(optionPanel)

	OptionsPanel.gamePanel = optionPanel:add(Panel(PanelSize(Vec2(1,-0.9), PanelSizeType.ParentPercent)))
	OptionsPanel.gamePanel:setBackground(Sprite(Vec4(1,1,1,0.75)))
	--OptionsPanel.gamePanel:loadLua(Text("optionsGamePanel.lua"))

	OptionsPanel.grapicPanel = optionPanel:add(Panel(PanelSize(Vec2(1,-0.9), PanelSizeType.ParentPercent)))
	OptionsPanel.grapicPanel:setBackground(Sprite(Vec4(1,1,1,0.75)))
	OptionsPanel.grapicPanel:setVisible(false)
	--OptionsPanel.grapicPanel:loadLua(Text("optionsGraphicPanel.lua"))

	OptionsPanel.KeyBindsPanel = optionPanel:add(Panel(PanelSize(Vec2(1,-0.9), PanelSizeType.ParentPercent)))
	OptionsPanel.KeyBindsPanel:setBackground(Sprite(Vec4(1,1,1,0.75)))
	OptionsPanel.KeyBindsPanel:setVisible(false)

	OptionsPanel.addBreakLine(optionPanel)

	local closeButton = optionPanel:add(Button(PanelSize(Vec2(0.3,-1),Vec2(4,1), PanelSizeType.ParentPercent), "Close"))
	closeButton:addEventCallbackExecute("togleVisible")
end