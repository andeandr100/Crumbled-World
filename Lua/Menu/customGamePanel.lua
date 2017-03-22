--this = SceneNode()

CustomGamePanel = {}

function CustomGamePanel.togleVisible(panel)
	CustomGamePanel.customPanel:setVisible(not CustomGamePanel.customPanel:getVisible());
end

function CustomGamePanel.addBreakLine(panel)
	local line = panel:add(Panel(PanelSize(Vec2(1,0.0025), PanelSizeType.ParentPercent)))
	line:setBackground(Sprite(Vec4(1,1,1,0.75)));
end

function CustomGamePanel.create(customPanel)
	--customPanel = Panel()
	CustomGamePanel.customPanel = customPanel
	customPanel:setBackground(Sprite(Vec4(1.0, 1.0, 1.0, 0.6)));

	customPanel:setPadding(BorderSize(Vec4(0.05)));
	customPanel:setLayout(FlowLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0.01))));
	
	customPanel:add(Label(PanelSize(Vec2(-1,0.1)),"<b>Custom Game", Alignment.MIDDLE_CENTER));


	CustomGamePanel.addBreakLine(customPanel);

	local gamePanel = customPanel:add(Panel(PanelSize(Vec2(1,-0.9), PanelSizeType.ParentPercent)))
	gamePanel:setBackground(Sprite(Vec4(1,1,1,0.75)));
	

	CustomGamePanel.addBreakLine(customPanel);

	local closeButton = customPanel:add(Button(PanelSize(Vec2(0.3,0.1),Vec2(4,1), PanelSizeType.ParentPercent), "Close"));
	closeButton:addEventCallbackExecute(togleVisible);

end