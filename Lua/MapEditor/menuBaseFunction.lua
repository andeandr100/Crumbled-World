--this=SceneNode()



function split(str,sep)
	local array = {}
	local reg = string.format("([^%s]+)",sep)
	local numElement = 0
	for mem in string.gmatch(str,reg) do
		table.insert(array, mem)
		numElement = numElement + 1
	end	
	return array, numElement
end

function addTitel( addOnPanel, titel )
	local subToolMenuHeader = addOnPanel:add(Panel(PanelSize(Vec2(-1, 0.025))))
	local label = subToolMenuHeader:add(Label(PanelSize(Vec2(-1)), titel))
	label:setTextColor(Vec3(1))
	subToolMenuHeader:setBorder(Border(BorderSize(Vec4(0,0.001,0,0.001)),Vec4(0,0,0,1)))
	subToolMenuHeader:setPadding(BorderSize(Vec4(0.01,0,0,0)))
	subToolMenuHeader:setBackground(Sprite(Vec4(0.12, 0.12, 0.12, 0.98)))
end

function createToolMenu(titel, panelAutoFit)
	--Header
	addTitel(toolsMenu, titel)

	--body
	local subToolMenu = toolsMenu:add(Panel(PanelSize(Vec2(-1, -1))))
	if panelAutoFit then
		subToolMenu:getPanelSize():setFitChildren(false, true)
	end
	subToolMenu:setMargin(BorderSize(Vec4(0, toolButtonSpaceing, 0, toolButtonSpaceing)))
	subToolMenu:setLayout(FlowLayout( PanelSize(Vec2(toolButtonSpaceing),Vec2(1))))
	return subToolMenu;
end

function addButton( parentPanel, minUvCoord, maxUvCoord, callbackName, toolTipText )

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

function addTitelButton( addOnPanel, titel )
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

function createTitleAndBody( panel, name)
	local toolPanel = panel:add(Panel(PanelSize(Vec2(-1,0.6))))
	toolPanel:setLayout(FlowLayout())
	toolPanel:getPanelSize():setFitChildren(false, true)
	toolPanel:setVisible(false)

	local button = addTitelButton(toolPanel, name)

	local toolArea = toolPanel:add(Panel(PanelSize(Vec2(toolAndSettingMenuSize,1))))
	toolArea:setLayout(FlowLayout())
	toolArea:getPanelSize():setFitChildren(false, true)
	toolArea:getLayout():setPanelSpacing(PanelSize(Vec2(0.005, 0.005)))
	toolArea:setMargin(BorderSize(Vec4(0.0025, 0.00125, 0.0025, 0.00125), false))

	button:addEventCallbackExecute("togleVisible")
	button:setTag(toolArea:getPanelId() .. ";" )

	return toolPanel, toolArea, button
end