

function addBreakLine(panel)
	local line = panel:add(Panel(PanelSize(Vec2(1,0.0025), PanelSizeType.ParentPercent)))
	line:setBackground(Sprite(Vec4(1,1,1,0.75)));
end

function create()

	--this:setBackground(Sprite(Vec4(1.0, 1.0, 1.0, 0.6)));

	--this:setPadding(BorderSize(Vec4(0.05)));
	this:setLayout(FlowLayout(PanelSize(Vec2(0.01))));
	
	this:add(Label(PanelSize(Vec2(-1,0.1)),Text("<b>Options"), Alignment.MIDDLE_CENTER));

	addBreakLine(this);

	local textSize = PanelSize(Vec2(0.5,0.06), PanelSizeType.ParentPercent);
	local editSize = PanelSize(Vec2(0.5,0.06), Vec2(4,1), PanelSizeType.ParentPercent);

	this:add(Label(textSize, Text("<b>Show enimis path")));
	this:add(Button(editSize, Text("True")));

	this:add(Label(textSize, Text("<b>Show enimis helth")));
	this:add(Button(editSize, Text("True")));

	this:add(Label(textSize, Text("<b>Show tower xp")));
	this:add(Button(editSize, Text("True")));

	this:add(Label(textSize, Text("<b>Enable Enemies soft body")));
	this:add(Button(editSize, Text("True")));

	this:add(Label(textSize, Text("<b>Show build menu")));
	this:add(Button(editSize, Text("True")));

	this:add(Label(textSize, Text("<b>Show stats menu")));
	this:add(Button(editSize, Text("True")));

	return true
end