--this = SceneNode()
OptionsMenuStyle = {}

function OptionsMenuStyle.addOptionsHeader(panel, text)
	return panel:add(Label(PanelSize(Vec2(-1,0.04)), text, Vec3(0.94), Alignment.MIDDLE_LEFT))
end

function OptionsMenuStyle.addRow(panel, rowText)
	local rowPanel = panel:add(Panel(PanelSize(Vec2(-1,0.03))))
	rowPanel:setLayout(FlowLayout(PanelSize(Vec2(0.01,0))))
	local label = rowPanel:add(Label(PanelSize(Vec2(-0.3,-1)), rowText, Vec3(0.8), Alignment.MIDDLE_RIGHT))
	return rowPanel, label
end