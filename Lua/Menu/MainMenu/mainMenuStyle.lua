--this = SceneNode()
MainMenuStyle = {}

MainMenuStyle.borderColor = Vec4(Vec3(0.45), 1.0)
MainMenuStyle.borderSize = 0.00135
MainMenuStyle.backgroundTopColor = Vec4(0,0,0,0.7)
MainMenuStyle.backgroundDownColor = Vec4(0,0,0,0.5)
MainMenuStyle.textColor = Vec3(0.7)
MainMenuStyle.textColorHighLighted = Vec3(0.92)
language = Language()

function MainMenuStyle.createPagePanel(panel)
	panel:add(Panel(PanelSize(Vec2())))
end

--Create main menu
-- Panel = parrent panel
-- panelSize = Panelsize()
function MainMenuStyle.createTopMenu(panel, panelSize)
	local topPanel = panel:add(Panel(panelSize))
	topPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
	topPanel:setLayout(FlowLayout(Alignment.TOP_LEFT))
	
	local border = panel:add(Panel(PanelSize(Vec2(-1,2),PanelSizeType.Pixel)))
	border:setBackground(Sprite(MainMenuStyle.borderColor))
	
	return topPanel
end

function MainMenuStyle.addTopMenuButton(panel, scale, text)
	return panel:add(MainMenuStyle.createMenuButton( Vec2(-1), scale, text))	
end

function MainMenuStyle.createMenuButton(size, scale, text)
	local button = Button(PanelSize(size, scale), text, ButtonStyle.RADIENT)
	button:setTextColor(Vec3(0.7))
	button:setTextHoverColor(Vec3(0.92))
	button:setTextDownColor(Vec3(1))
	
	button:setEdgeColor(Vec4(0), Vec4(0))
	button:setEdgeHoverColor(Vec4(0), Vec4(0))
	button:setEdgeDownColor(Vec4(0), Vec4(0))

	button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
	button:setInnerHoverColor(Vec4(0), Vec4(1,1,1,0.4), Vec4(0))
	button:setInnerDownColor(Vec4(0), Vec4(1,1,1,0.3), Vec4(0))
	
	return button
end

function MainMenuStyle.createButton(size, scale, text)
	local button = Button(PanelSize(size, scale), text, ButtonStyle.SQUARE_LIGHT)
	
	
	button:setEdgeColor(MainMenuStyle.borderColor)
	button:setEdgeHoverColor(MainMenuStyle.borderColor)
	button:setEdgeDownColor(Vec4(MainMenuStyle.borderColor:toVec3() * 0.8, MainMenuStyle.borderColor.w))
	
	button:setInnerColor(Vec4(0.18,0.18,0.18,1),Vec4(),Vec4(0,0,0,1))
	button:setInnerHoverColor(Vec4(0.08,0.08,0.08,1),Vec4(0.5,0.5,0.5,1),Vec4(0,0,0,1))
	button:setInnerDownColor(Vec4(0.08,0.08,0.08,1),Vec4(0.4,0.4,0.4,1),Vec4(0,0,0,1))
	
	button:setTextColor(MainMenuStyle.textColor)
	button:setTextHoverColor(Vec4(1))
	button:setTextDownColor(Vec4(1))
	
	
--	button:setTextColor(Vec3(0.7))
--	button:setTextHoverColor(Vec3(0.92))
--	button:setTextDownColor(Vec3(1))
--	
--	button:setEdgeColor(MainMenuStyle.borderColor)
--	button:setEdgeHoverColor(MainMenuStyle.borderColor)
--	button:setEdgeDownColor(MainMenuStyle.borderColor)
--
--	button:setInnerColor(Vec4(0))
--	button:setInnerHoverColor(Vec4(1,1,1,0.2))
--	button:setInnerDownColor(Vec4(1,1,1,0.1))
	
	return button
end

function MainMenuStyle.createTextField(size, scale, text)
	local textField = TextField(PanelSize(size, scale), text)
	
	textField:setTextColor(MainMenuStyle.textColorHighLighted)
	textField:setBackgroundColor(Vec4(0,0,0,0.8))
	
	textField:setBorderBottomInternalColor(Vec4(0,0,0,0.9))
	textField:setBorderBottomEdgeColor(MainMenuStyle.borderColor)
	
	return textField	
end

function MainMenuStyle.createBreakLine(panel,length)
	local breakLinePanel = panel:add(Panel(PanelSize(Vec2(length or -0.9,0.002))))
	breakLinePanel:setBackground(Sprite(MainMenuStyle.borderColor))
end