--this = SceneNode()
OptionsMenuStyle = {}
language = Language()

function OptionsMenuStyle.addOptionsHeader(panel, text)
	local label = panel:add(Label(PanelSize(Vec2(-1,0.04)), text, Vec3(0.94), Alignment.MIDDLE_LEFT))
	label:setTag(text)
	return label
end

function OptionsMenuStyle.addRow(panel, rowText)
	local rowPanel = panel:add(Panel(PanelSize(Vec2(-1,0.03))))
	rowPanel:setLayout(FlowLayout(PanelSize(Vec2(0.01,0))))
	local label = rowPanel:add(Label(PanelSize(Vec2(-0.3,-1)), rowText, Vec3(0.8), Alignment.MIDDLE_RIGHT))
	label:setTag(rowText)
	return rowPanel, label
end