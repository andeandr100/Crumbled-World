--require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()
PreSetPanel = {}

function PreSetPanel.removePreSet(button)
	
	if PreSetPanel.functionRemoveCallback then
		PreSetPanel.functionRemoveCallback(button:getParent():getTag():toString())
	end
	
	PreSetPanel.presetPanel:removePanel(button:getParent())
end

function PreSetPanel.addPreset(button)
	
	if PreSetPanel.functionAddCallback then
		PreSetPanel.functionAddCallback(presetAddName:getText())
	end
end

function PreSetPanel.changePreset(button)
	if PreSetPanel.functionChangePreset then
		PreSetPanel.functionChangePreset(button:getTag():toString())
	end
end


function PreSetPanel.createPreSetPanel( panel, functionAddCallback, functionRemoveCallback, functionChangePreset )
	
	panel:add(Label(PanelSize(Vec2(-1, 0.025)), "Presets:", Vec3(1)))
	PreSetPanel.presetPanel = panel:add(Panel(PanelSize(Vec2(-1,1))))
	PreSetPanel.presetPanel:getPanelSize():setFitChildren(false, true)
	PreSetPanel.presetPanel:setBackground(Sprite(Vec4(0.3)))
	PreSetPanel.presetPanel:setPadding(BorderSize(Vec4(0.00125)))
	PreSetPanel.presetPanel:setBorder(Border(BorderSize(Vec4(0.00125)), Vec3(0)))
	
	
	presetAddName = panel:add(TextField(PanelSize(Vec2(-0.6,0.025)),"Preset name"))
	addScriptButton = panel:add(Button(PanelSize(Vec2(-0.9,0.025), Vec2(3,1)),"Add"))
	panel:add(Panel(PanelSize(Vec2(-1,0.025))))
	
	PreSetPanel.functionAddCallback = functionAddCallback
	PreSetPanel.functionRemoveCallback = functionRemoveCallback
	PreSetPanel.functionChangePreset = functionChangePreset

	addScriptButton:addEventCallbackExecute(PreSetPanel.addPreset)
end

function PreSetPanel.setPreSetList(preSetList)
	local presetPanel = PreSetPanel.presetPanel
	print("Set script list, size: "..tostring(#preSetList).."\n")
	for i=1, #preSetList do
		print("Preset: "..preSetList[i].."\n")
		local panelIndex = i-1
		if presetPanel:getNumPanel() > panelIndex then
			presetPanel:getPanel(panelIndex):setText(preSetList[i])
			presetPanel:getPanel(panelIndex):setTag(preSetList[i])
		else
			PreSetPanel.addPreSet(preSetList[i])
		end
	end
	for i=presetPanel:getNumPanel()-1, #preSetList, -1 do
		print("remove script text row\n")
		presetPanel:removePanel(presetPanel:getPanel(i))
	end
end

function PreSetPanel.addPreSet(name)

	local aButton = PreSetPanel.presetPanel:add(Button(PanelSize(Vec2(-1, 0.025)), name, ButtonStyle.SQUARE))
	aButton:setTag(name)
	aButton:setTextAnchor(Anchor.MIDDLE_LEFT)
	aButton:setEdgeColor(Vec4())
	aButton:setEdgeHoverColor(Vec4())
	aButton:setEdgeDownColor(Vec4())
	aButton:setInnerColor(Vec4())
	aButton:setTextColor(MainMenuStyle.textColor)
	aButton:setTextHoverColor(MainMenuStyle.textColorHighLighted)
	aButton:setTextDownColor(MainMenuStyle.textColorHighLighted)
	aButton:setInnerHoverColor(Vec4(0,0,0,0.5))	
	aButton:setInnerDownColor(Vec4(0,0,0,1))
	aButton:addEventCallbackExecute(PreSetPanel.changePreset)
	
	
	aButton:setLayout(FlowLayout(Alignment.TOP_RIGHT))
	local xButton = aButton:add(Button(PanelSize(Vec2(-1), Vec2(1)), "X", ButtonStyle.SQUARE))
	xButton:setEdgeColor(Vec4())
	xButton:setEdgeHoverColor(Vec4())
	xButton:setEdgeDownColor(Vec4())
	xButton:setInnerColor(Vec4())	
	xButton:setTextColor(Vec3(1))	
	xButton:setInnerHoverColor(Vec4(0.35,0.35,0.35,1))	
	xButton:setInnerDownColor(Vec4(0,0,0,1))
	if PreSetPanel.removePreSet then
		xButton:addEventCallbackExecute(PreSetPanel.removePreSet)	
	end
end