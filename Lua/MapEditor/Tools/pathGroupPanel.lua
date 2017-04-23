require("Menu/colorPicker.lua")
--this = SceneNode()

PathGroupPanel = {}
PathGroupPanel.groupsPanel = nil
PathGroupPanel.groups = {}

function PathGroupPanel.getGroupId()
	local id = 1
	local run = true
	while run do
		run = false
		for i=1, #PathGroupPanel.groups do
			if PathGroupPanel.groups[i].id == id then
				id = id + 1
				run = true
			end
		end
	end
	
	print("New Id: "..id.."\n")
	return id
end

function PathGroupPanel.createNewGroup(button)
	--fileName = Text()
	
	local id = PathGroupPanel.getGroupId()
	local color = PathGroupPanel.colorPicker.getColor()
	PathGroupPanel.addGroup( id, color)
	if PathGroupPanel.functionAddCallback ~= nil then
		PathGroupPanel.functionAddCallback(id, color)
	end
	
	print("\nGroups: "..tostring(PathGroupPanel.groups).."\n")
end

function PathGroupPanel.removeGroup(panel)
	
	if PathGroupPanel.functionRemoveCallback ~= nil then
		PathGroupPanel.functionRemoveCallback(tonumber(panel:getParent():getTag():toString()))
	end
	
	PathGroupPanel.groupsPanel:removePanel(panel:getParent())
end

function PathGroupPanel.createGroupPanel( panel, functionAddCallback, functionRemoveCallback, functionChangeGroup )
	panel:add(Label(PanelSize(Vec2(-1, 0.025)), "Groups:", Vec3(1)))
	local groupsPanel = panel:add(Panel(PanelSize(Vec2(-1,1))))
	groupsPanel:getPanelSize():setFitChildren(false, true)
	groupsPanel:setBackground(Sprite(Vec4(0.3)))
	groupsPanel:setPadding(BorderSize(Vec4(0.00125)))
	groupsPanel:setBorder(Border(BorderSize(Vec4(0.00125)), Vec3(0)))
	
	
	local createPanel = panel:add(Panel(PanelSize(Vec2(-1,0.025))))
	
	PathGroupPanel.colorPicker = ColorPickerForm.new(createPanel,PanelSize(Vec2(-0.4, -1)), Vec3(0.3,0.3,1))
	addGroupButton = createPanel:add(Button(PanelSize(Vec2(1,-1), Vec2(4,1)),"New group"))
	
	PathGroupPanel.functionAddCallback = functionAddCallback
	PathGroupPanel.functionRemoveCallback = functionRemoveCallback
	PathGroupPanel.functionChangeGroup = functionChangeGroup
	addGroupButton:addEventCallbackExecute(PathGroupPanel.createNewGroup)

	PathGroupPanel.groupsPanel = groupsPanel
end

function PathGroupPanel.getGroupFromId(id)
	for i=1, #PathGroupPanel.groups do
		if PathGroupPanel.groups[i].id == id then
			print("Group Found return data\n")
			return PathGroupPanel.groups[i]
		end
	end
	print("nil\n")
	return nil
end

function PathGroupPanel.setGroupList(groupList)

	local groupsPanel = PathGroupPanel.groupsPanel
	print("\nSet group list, size: "..tostring(#groupList).."\n")
	
	groupsPanel:clear();
	
	for i=1, #groupList do
		PathGroupPanel.addGroup(groupList[i].id, groupList[i].color)
	end

	print("\nGroups: "..tostring(PathGroupPanel.groups).."\n")
end

function PathGroupPanel.addGroup(id, color)
	
--	local groupPanel = PathGroupPanel.groupsPanel:add(Panel(Vec2(-1,0.025)))
	
	
	local aButton = PathGroupPanel.groupsPanel:add(Button(PanelSize(Vec2(-1, 0.025)),"", ButtonStyle.SQUARE))
	aButton:setTextAnchor(Anchor.MIDDLE_LEFT)
	aButton:setEdgeColor(Vec4())
	aButton:setEdgeHoverColor(Vec4(Vec3(1),0.4))
	aButton:setEdgeDownColor(Vec4(Vec3(0),0.2))
	aButton:setInnerColor(Vec4())
	aButton:setTextColor(Vec3(1))
	aButton:setInnerHoverColor(Vec4(1,1,1,0.5))	
	aButton:setInnerDownColor(Vec4(0,0,0,1))
	aButton:setTag(tostring(id))
	print("id: "..id.."\n")
	aButton:setLayout(FlowLayout(Alignment.BOTTOM_RIGHT))
	aButton:setBackground(Sprite(color), PanelSize(Vec2(0.975, 0.75), PanelSizeType.ParentPercent))
	if PathGroupPanel.functionChangeGroup then
		aButton:addEventCallbackExecute(PathGroupPanel.functionChangeGroup)
	end
	
	
	local xButton = aButton:add(Button(PanelSize(Vec2(-1), Vec2(1)), "X", ButtonStyle.SQUARE))
	xButton:setEdgeColor(Vec4())
	xButton:setEdgeHoverColor(Vec4())
	xButton:setEdgeDownColor(Vec4())
	xButton:setInnerColor(Vec4())	
	xButton:setTextColor(Vec3(1))	
	xButton:setInnerHoverColor(Vec4(0.35,0.35,0.35,1))	
	xButton:setInnerDownColor(Vec4(0,0,0,1))
	xButton:addEventCallbackExecute(PathGroupPanel.removeGroup)	
	

	PathGroupPanel.groups[#PathGroupPanel.groups+1] = {id=id, color=color}
end

function PathGroupPanel.update()

	PathGroupPanel.colorPicker.update()
end