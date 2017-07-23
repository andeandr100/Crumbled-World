require("Menu/MainMenu/mainMenuStyle.lua")
--this=SceneNode()


MainMenuStyle.backgroundTopColor = Vec4(0,0,0,0.8)
MainMenuStyle.backgroundDownColor = Vec4(0,0,0,0.6)

MenuStyle = {}
MenuStyle.rowHeight = 0.02

toolAndSettingMenuSize = 0.16
toolButtonSpaceing = 0.005



function split(str,sep)
	--str = string()
	--sep = string()
	local array = {}
	local reg = string.format("([^%s]+)",sep)
	local numElement = 0
	for mem in string.gmatch(str,reg) do
		table.insert(array, mem)
		numElement = numElement + 1
	end	
	return array, numElement
end

function MenuStyle.addTitel( addOnPanel, titel )
	--addOnPanel = Panel()
	--titel = string()
	local subToolMenuHeader = addOnPanel:add(Panel(PanelSize(Vec2(-1, 0.025))))
	local label = subToolMenuHeader:add(Label(PanelSize(Vec2(-1)), titel))
	label:setTextColor(MainMenuStyle.textColor)
	subToolMenuHeader:setBorder(Border(BorderSize(Vec4(0,0.001,0,0.001)),MainMenuStyle.borderColor))
	subToolMenuHeader:setPadding(BorderSize(Vec4(0.01,0,0,0)))
	subToolMenuHeader:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
end

function MenuStyle.createToolMenu(titel, panelAutoFit, numColumns, numRows)
	--titel = string()
	--panelAutoFit = boolean()
	--Header
	MenuStyle.addTitel(toolsMenu, titel)

	--body
	
	local subToolMenu = toolsMenu:add(Panel(PanelSize(Vec2(-1, -1), Vec2(4,2.5))))
	if panelAutoFit then
		subToolMenu:getPanelSize():setFitChildren(false, true)
	end
	subToolMenu:setMargin(BorderSize(Vec4(0, toolButtonSpaceing, 0, toolButtonSpaceing)))
	subToolMenu:setLayout(GridLayout( numRows, numColumns, PanelSize(Vec2(toolButtonSpaceing),Vec2(1))))
	return subToolMenu;
end

function MenuStyle.createToolMenuFromPanel(parentPanel, titel, panelAutoFit)
	--parentPanel = Panel()
	--titel = string()
	--panelAutoFit = boolean()
	--Header
	MenuStyle.addTitel(parentPanel, titel)

	--body
	local subToolMenu = parentPanel:add(Panel(PanelSize(Vec2(-1, -1))))
	if panelAutoFit then
		subToolMenu:getPanelSize():setFitChildren(false, true)
	end
	subToolMenu:setMargin(BorderSize(Vec4(0, toolButtonSpaceing, 0, toolButtonSpaceing)))
	subToolMenu:setLayout(FlowLayout( PanelSize(Vec2(toolButtonSpaceing),Vec2(1))))
	return subToolMenu;
end

function MenuStyle.addToolButton( parentPanel, minUvCoord, callbackName, toolTipText )
	--parentPanel = Panel()
	--minUvCoord = Vec2()
	--maxUvCoord = Vec2()
	--callbackName = string()
	--toolTipText = string()
	texture = Core.getTexture("GUI_MapEditor")

	local button = parentPanel:add(Button(PanelSize(Vec2(-1), Vec2(1)), ButtonStyle.SQUARE, texture, minUvCoord, minUvCoord+Vec2(0.25,0.125)))
	button:setInnerColor(Vec4(0.2,0.2,0.2,0.3),Vec4(0.4,0.4,0.4,0.4), Vec4(0.2,0.2,0.2,0.3))
	button:setInnerHoverColor(Vec4(0.4,0.4,0.4,0),Vec4(1,1,1,0.25), Vec4(1,1,1,0.25))
	button:setInnerDownColor(Vec4(0.2,0.2,0.2,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
	button:addEventCallbackExecute(callbackName)
	button:setToolTip(Text(toolTipText))

	return button
end

function MenuStyle.addButton( parentPanel, minUvCoord, maxUvCoord, callbackName, toolTipText )
	--parentPanel = Panel()
	--minUvCoord = Vec2()
	--maxUvCoord = Vec2()
	--callbackName = string()
	--toolTipText = string()
	texture = Core.getTexture("GUI_MapEditor.png")
	local numButtonsPerRow = 4
	local buttonWidth = (toolAndSettingMenuSize - toolButtonSpaceing * (numButtonsPerRow+2)) / numButtonsPerRow

	local button = parentPanel:add(Button(PanelSize(Vec2(buttonWidth,1), Vec2(1)), ButtonStyle.SQUARE, texture, minUvCoord, maxUvCoord))
	button:setInnerColor(Vec4(0,0,0,0.3),Vec4(0.4,0.4,0.4,0.7), Vec4(0.2,0.2,0.2,0.5))
	button:setInnerHoverColor(Vec4(0,0,0,0),Vec4(1,1,1,0.25), Vec4(1,1,1,0.25))
	button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
	button:addEventCallbackExecute(callbackName)
	button:setToolTip(Text(toolTipText))

	return button
end

function MenuStyle.addTitelButton( addOnPanel, titel )
	
	--addOnPanel = Panel()
	--titel = string()
	local subToolMenuHeader = addOnPanel:add(Panel(PanelSize(Vec2(-1, 0.02))))
	local button = subToolMenuHeader:add(Button(PanelSize(Vec2(-1)), titel))
	button:setTextColor(Vec3(1))
	button:setTextAnchor(Anchor.MIDDLE_LEFT)

	button:setEdgeColor(Vec4(0), Vec4(0))
	button:setEdgeHoverColor(Vec4(0), Vec4(0))
	button:setEdgeDownColor(Vec4(0), Vec4(0))

	button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
	button:setInnerHoverColor(Vec4(0), Vec4(0), Vec4(0))
	button:setInnerDownColor(Vec4(0), Vec4(0), Vec4(0))

	subToolMenuHeader:setBorder(Border(BorderSize(Vec4(0,0.001,0,0.001)),Vec4(0,0,0,1)))
	subToolMenuHeader:setBackground(Sprite(Vec4(0.12, 0.12, 0.12, 0.98)))
	
	return button
end

function MenuStyle.togleVisible(panel)
	print("togle visible tag: "..panel:getTag():toString().."\n")

	local bodyPanel = panel:getPanelById(panel:getTag():toString())
	if bodyPanel then
		bodyPanel:setVisible(not bodyPanel:getVisible())
	end
	
end

function MenuStyle.createTitleAndBody( panel, name)
	--panel = Panel()
	--name = string()
	local toolPanel = panel:add(Panel(PanelSize(Vec2(-1,0.6))))
	toolPanel:setLayout(FlowLayout())
	toolPanel:getPanelSize():setFitChildren(false, true)
	toolPanel:setVisible(false)

	local button = MenuStyle.addTitelButton(toolPanel, name)

	local toolArea = toolPanel:add(Panel(PanelSize(Vec2(toolAndSettingMenuSize,1))))
	toolArea:setLayout(FlowLayout())
	toolArea:getPanelSize():setFitChildren(false, true)
	toolArea:getLayout():setPanelSpacing(PanelSize(Vec2(0.005, 0.005)))
	toolArea:setMargin(BorderSize(Vec4(0.0025, 0.00125, 0.0025, 0.00125), false))

	button:addEventCallbackExecute(MenuStyle.togleVisible)
	button:setTag(toolArea:getPanelId())

	return toolPanel, toolArea, button
end