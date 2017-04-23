

function addBreakLine(panel)
	local line = panel:add(Panel(PanelSize(Vec2(0.8,0.0025), PanelSizeType.ParentPercent)))
	line:setBackground(Sprite(Vec4(1,1,1,0.75)));
end

function create()

	--this:setBackground(Sprite(Vec4(1.0, 1.0, 1.0, 0.6)));

	--this:setPadding(BorderSize(Vec4(0.05)));
	this:setLayout(FlowLayout(PanelSize(Vec2(0.01))));
	
	this:add(Label(PanelSize(Vec2(-1,0.1)),Text("<b>Graphic"), Alignment.MIDDLE_CENTER));

	addBreakLine(this);

	local textSize = PanelSize(Vec2(0.5,0.06), PanelSizeType.ParentPercent);
	local editSize = PanelSize(Vec2(0.5,0.06), Vec2(4,1), PanelSizeType.ParentPercent);

	this:add(Label(textSize, Text("<b>Show error models")));
	this:add(Button(editSize, Text("True")));

	this:add(Label(textSize, Text("<b>Enimes death render time")));
	this:add(Button(editSize, Text("True")));

	addBreakLine(this);

	this:add(Label(textSize, Text("<b>Cloter lvl")));
	this:add(Button(editSize, Text("True")));

	this:add(Label(textSize, Text("<b>Particle effect densitet")));
	this:add(Button(editSize, Text("True")));

	addBreakLine(this);

	this:add(Label(textSize, Text("<b>enable Shadow")));
	this:add(Button(editSize, Text("True")));

	this:add(Label(textSize, Text("<b>Shadow Render lvl")));
	this:add(Button(editSize, Text("True")));

	addBreakLine(this);

	this:add(Label(textSize, Text("<b>Enable glow")));
	this:add(Button(editSize, Text("True")));
	return true
end
