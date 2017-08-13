require("Menu/MainMenu/optionsMenuStyle.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()

InputPanel = {}
InputPanel.rebindKey = nil
InputPanel.rebindKeyId = 0
InputPanel.rebindKeyButton = nil
InputPanel.labels = {}

function InputPanel.getKeyBindName(name)
	return language:getText( string.lower(name) )
end

function InputPanel.languageChanged()
	for i=1, #InputPanel.labels do
		InputPanel.labels[i]:setText(InputPanel.getKeyBindName(InputPanel.labels[i]:getTag():toString()))
	end
end


function InputPanel.create(mainPanel)
	
	InputPanel.form = Form(this:getRootNode():findNodeByName("MainCamera"), PanelSize(Vec2(-1)));
	InputPanel.form:setRenderLevel(10)
	InputPanel.form:setVisible(false)
	
	--mainPanel = Panel()
	local inputPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9,-0.95))))
	inputPanel:setLayout(FallLayout(PanelSize(Vec2(0,0.0015))))
	inputPanel:setEnableYScroll()
	
	InputPanel.keyBinds = Core.getBillboard("keyBind");
	
	local keys = InputPanel.keyBinds:getKeys()
	
	local groupedKeys = {}
	print("Sort goups\n")
	--Group keyBinds by group and name
	for i=1, #keys do
		print("Key: "..keys[i].."\n")
		local keyBind = InputPanel.keyBinds:getKeyBind(keys[i])
		local groupName = keyBind:getGroupName()
		local subGroupName = keyBind:getSubGroupName()
		local name = keyBind:getName()
		
		if groupedKeys[groupName] == nil then
			groupedKeys[groupName] = {}
		end
		if groupedKeys[groupName][subGroupName] == nil then
			groupedKeys[groupName][subGroupName] = {}
		end
		
		groupedKeys[groupName][subGroupName][name] = keyBind
	end
	local count = 1
	local function addInputGroup(groupName, group)
		print("Goup: "..groupName.."\n")
		InputPanel.labels[count] = OptionsMenuStyle.addOptionsHeader( inputPanel, language:getText( string.lower(groupName)) )
		InputPanel.labels[count]:setTag( string.lower(groupName) )
		count = count + 1
		for subGroupName, subGroup in pairs(group) do
			local nameList = {}
			for name in pairs(subGroup) do table.insert(nameList, name)  end
			table.sort(nameList)
			local rowPanel
			for i=1, #nameList do
				local name = nameList[i]
				local keyBind = subGroup[name]
				
				print("name: "..name.."\n")
				rowPanel, InputPanel.labels[count] = OptionsMenuStyle.addRow(inputPanel, InputPanel.getKeyBindName(name) )
				InputPanel.labels[count]:setTag( name )
				InputPanel.addKeyBindButton( rowPanel, Vec2(-0.45,-1), keyBind:getKeyBindName(0), name, 0)
				InputPanel.addKeyBindButton( rowPanel, Vec2(-0.9,-1), keyBind:getKeyBindName(1), name, 1)
				count = count + 1				
			end
		end
	end
	local displayOrder = {"Camera", "WaveHeader", "BuildHeader"}
	for key, groupName in pairs(displayOrder) do
		addInputGroup(groupName,groupedKeys[groupName])
	end
	for groupName, group in pairs(groupedKeys) do
		local alreadyDisplayed = false
		for key, groupNameSearch in pairs(displayOrder) do
			if groupNameSearch==groupName then
				alreadyDisplayed = true
				break
			end
		end
		if not alreadyDisplayed then
			addInputGroup(groupName, group)
		end
	end
	InputPanel.inputPanel = inputPanel
	InputPanel.keyDownTime = 0
	return inputPanel
end

function InputPanel.addKeyBindButton(panel, size, text, tag, id)
	local button = panel:add(Button(PanelSize(size), text, ButtonStyle.SIMPLE))
	
	button:setTextColor(Vec3(0.7))
	button:setTextHoverColor(Vec3(0.92))
	button:setTextDownColor(Vec3(1))
	
	button:setEdgeColor(Vec4(0.7), Vec4(0.7))
	button:setEdgeHoverColor(Vec4(0.7), Vec4(0.7))
	button:setEdgeDownColor(Vec4(0.7), Vec4(0.7))

	button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
	button:setInnerHoverColor(Vec4(0), Vec4(1,1,1,0.4), Vec4(1,1,1,0.5))
	button:setInnerDownColor(Vec4(0), Vec4(1,1,1,0.3), Vec4(1,1,1,0.4))
	
	button:setTag(tag..";"..tostring(id))
	button:addEventCallbackExecute(bindNewKey)
	
	return button
end

function bindNewKey(button)
	local keyBindName,id = string.match(button:getTag():toString(),"([^,]+);([^,]+)")
	InputPanel.rebindKey = InputPanel.keyBinds:getKeyBind(keyBindName)
	print("\nKeyName: "..keyBindName.."\n\n")
	InputPanel.form:setVisible(true)
	if InputPanel.rebindKey then
		InputPanel.rebindKeyId = tonumber(id)
		InputPanel.rebindKeyButton = button
		button:setText( language:getText("press key"))
	end
end

function InputPanel.update()
	if InputPanel.form then
		InputPanel.form:update()
	end
	if InputPanel.rebindKey then
		if Core.getInput():getKeyDown(Key.escape) then
			InputPanel.keyDownTime = Core.getTime()
		end
		
		if Core.getInput():getKeyHeld(Key.escape) and Core.getTime() - InputPanel.keyDownTime > 0.6 then
			--clear key
			InputPanel.rebindKey:setKeyBindKeyboard(InputPanel.rebindKeyId, -1)
			InputPanel.rebindKeyButton:setText(	InputPanel.rebindKey:getKeyBindName(InputPanel.rebindKeyId) )
		end
		if Core.getInput():getKeyPressed(Key.escape) then
			--binding of key has been stoped
			InputPanel.rebindKey:clearKeyBind(InputPanel.rebindKeyId)
			InputPanel.rebindKeyButton:setText(	InputPanel.rebindKey:getKeyBindName(InputPanel.rebindKeyId) )
			InputPanel.rebindKey:save()
			InputPanel.form:setVisible(false)
			InputPanel.rebindKey = nil
		elseif InputPanel.rebindKey:bindKey(InputPanel.rebindKeyId) then
			InputPanel.rebindKeyButton:setText(	InputPanel.rebindKey:getKeyBindName(InputPanel.rebindKeyId) )
			InputPanel.rebindKey:save()
			InputPanel.form:setVisible(false)
			InputPanel.rebindKey = nil
		end
	end
end