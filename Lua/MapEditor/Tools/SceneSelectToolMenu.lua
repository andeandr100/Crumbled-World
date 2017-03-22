require("MapEditor/Tools/Tool.lua")
require("MapEditor/menuStyle.lua")
require("MapEditor/menuScriptPanel.lua")
require("Menu/colorPicker.lua")
--this = SceneNode()

function destroy()
	Tool.saveSelectedScene({})
end

function scriptAddCallback(scriptName)
	
	local sceneNodes = Tool.getSelectedSceneNodes()
	for i=1, #sceneNodes do
		sceneNodes[i]:loadLuaScript(scriptName)
	end
end

function scriptRemoveCallback(scriptName)
	print("scriptRemoveCallback\n")
	local sceneNodes = Tool.getSelectedSceneNodes()
	for i=1, #sceneNodes do
		sceneNodes[i]:removeScript(scriptName)
	end
end

function updateScriptList()
	
	local sceneNodes = Tool.getSelectedSceneNodes()
	if #sceneNodes == 1 and sceneNodes[1] then
		luaScripts = sceneNodes[1]:getAllScript()
		print("Num Script: "..#luaScripts.."\n")
		local scriptList = {}
		for i=1, #luaScripts do
			print("add a Script at index "..tostring(i).."\n")
			scriptList[i] = luaScripts[i]
		end
		print("size: "..#scriptList.."\n")
		MenuScriptPanel.setScriptList(scriptList)
	else
		MenuScriptPanel.setScriptList({})
	end
end

function modelChangeColor(colorPicker)
	print("Color change callback\n")
	for i=1, #selectedNodes do
		local meshList = selectedNodes[i]:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
		for n=1, #meshList do
			meshList[n]:setColor(startStrawColor.getColor())
		end
	end
end

function changeName(textField)
	if #selectedNodes == 1 then
		selectedNodes[1]:setSceneName(textField:getText():toString())
	end
end

function changeIslandPlayer(textField)
	if #selectedNodes == 1 and selectedNodes[1]:getNodeType() == NodeId.island then
		local island = selectedNodes[1]
		--island = Island()
		island:setPlayerId(textField:getInt())
	end
end

function create()
	
	selectedNodes = {}
	selectedNodeLastMatrix = Matrix()
	
	--init Tool
	Tool.create()
	Tool.enableChangeOfSelectedScene = false
	
	--Get billboard for the map editor
	local mapEditor = Core.getBillboard("MapEditor")
	--Get the Tool panel
	local toolPanel = mapEditor:getPanel("ToolPanel")
	--Get the setting panel
	local settingsPanel = mapEditor:getPanel("SettingPanel")
	
	camera = this:getRootNode():findNodeByType(NodeId.camera)
		

	if settingsPanel then
		titlePanel, bodyPanel =  MenuStyle.createTitleAndBody(settingsPanel, "Selected scene nodes")
		
		--body = Panel()
		titlePanel:setVisible(false)
		createMenu(bodyPanel)
	end
	
	return true
end

function createMenu(sceneSettings)
	
	--Scnene name
	sceneNamePanel = sceneSettings:add(Panel(PanelSize(Vec2(-1, MenuStyle.rowHeight))))
	sceneNamePanel:add(Label(PanelSize(Vec2(-0.5, MenuStyle.rowHeight)),"Scene name", Vec3(1)))
	sceneNameTextField = sceneNamePanel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), ""))
	sceneNameTextField:addEventCallbackChanged(changeName)

	--Multiplayer owner
	
	multiplayerOwnerPanel = sceneSettings:add(Panel(PanelSize(Vec2(-1, MenuStyle.rowHeight))))
	multiplayerOwnerPanel:add(Label(PanelSize(Vec2(-0.5, MenuStyle.rowHeight)),"Player owner", Vec3(1)))
	multiplayerOwnerPanel:setToolTip(Text("Used to identify who owns right to build on the selected island.\nDefault value is 0 or empty string. numbers [1,n] represent a player id."))
	multiplayerOwnerTextField = multiplayerOwnerPanel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), ""))
	multiplayerOwnerTextField:setWhiteList("0123456789")
	multiplayerOwnerTextField:addEventCallbackChanged(changeIslandPlayer)


	local sceneMatrixPanel = sceneSettings:add(Panel(PanelSize(Vec2(-1,(MenuStyle.rowHeight+0.005) * 4))))
	sceneMatrixPanel:setLayout(GridLayout(4,3))
	sceneMatrixPanel:getLayout():setPanelSpacing(PanelSize(Vec2(0.005, 0.005)))

	

	--toolAndSettingMenuSize
	local panelWidth = (toolAndSettingMenuSize - 0.0052 * (2 + 2))/3

	sceneMatrixPanel:setMargin(BorderSize(Vec4(0.0025, 0.00125, 0.0025, 0.00125), false))
	
	sceneMatrixPanel:add(Label(PanelSize(Vec2(-1)), "Position", Vec3(1)))
	sceneMatrixPanel:add(Label(PanelSize(Vec2(-1)), "Rotation", Vec3(1)))
	sceneMatrixPanel:add(Label(PanelSize(Vec2(-1)), "Scale", Vec3(1)))
	
	panelList = {}
	
	for x=0,2 do
		for y=0,2 do
			panelList[1+x+y*3] = sceneMatrixPanel:add(TextField(PanelSize(Vec2(-1))))
		end
	end
	
	for i=1, 9 do
		panelList[i]:setWhiteList("-.0123456789")
		panelList[i]:addEventCallbackExecute( updateSceneMatrix);
	
	end
	
	--Color picker
	colorPanel = sceneSettings:add(Panel(PanelSize(Vec2(-1, MenuStyle.rowHeight))))
	colorPanel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Model color", Vec3(1)))
	startStrawColor = ColorPickerForm.new(colorPanel, PanelSize(Vec2(-1, MenuStyle.rowHeight)), Vec3(0.525,0.675,0.225))
	startStrawColor.setColor(Vec3(1))
	startStrawColor.setChangeCallback(modelChangeColor)
	
	--create script panel
	MenuScriptPanel.createScriptPanel(sceneSettings, scriptAddCallback, scriptRemoveCallback)
	
end

function updateSceneMatrix(panel)

	if #selectedNodes == 1 then
		localPosition = Vec3(tonumber(panelList[1]:getText()), tonumber(panelList[2]:getText()), tonumber(panelList[3]:getText()))
		localRotation = Vec3(math.rad(tonumber(panelList[4]:getText())), math.rad(tonumber(panelList[5]:getText())), math.rad(tonumber(panelList[6]:getText())))
		localScale = Vec3(tonumber(panelList[7]:getText()), tonumber(panelList[8]:getText()), tonumber(panelList[9]:getText()))

		local matrix = Matrix()
		
		scenePosition = localPosition
		matrix:setPosition(scenePosition)
		
		sceneRotation = localRotation 
		matrix:setRotation(localRotation)
		
		sceneScale = localScale 
		matrix:setScale(localScale)
		
		selectedNodes[1]:setLocalMatrix(matrix)
	end
end

function getMatrix()
	
end

function updateMatrixData()
	local localMatrix = selectedNodes[1]:getLocalMatrix()

	if scenePosition ~= localMatrix:getPosition() then
		scenePosition = localMatrix:getPosition()
		panelList[1]:setText(string.format ("%.3f", scenePosition.x))
		panelList[2]:setText(string.format ("%.3f", scenePosition.y))
		panelList[3]:setText(string.format ("%.3f", scenePosition.z))
	end
	if sceneRotation ~= localMatrix:getRotation() then
		sceneRotation = localMatrix:getRotation()
		panelList[4]:setText(string.format ("%.3f", math.deg(sceneRotation.x)))
		panelList[5]:setText(string.format ("%.3f", math.deg(sceneRotation.y)))
		panelList[6]:setText(string.format ("%.3f", math.deg(sceneRotation.z)))
	end
	if sceneScale ~= localMatrix:getScale() then
		sceneScale = localMatrix:getScale()
		panelList[7]:setText(string.format ("%.3f", sceneScale.x))
		panelList[8]:setText(string.format ("%.3f", sceneScale.y))
		panelList[9]:setText(string.format ("%.3f", sceneScale.z))
	end
end

function updateScelectedNodes()
	local newSelectedNodes = Tool.getSelectedSceneNodes()
	
	local sameNodes = (#selectedNodes ==  #newSelectedNodes)
	for i=(sameNodes and 1 or #selectedNodes+1), #selectedNodes do
		if newSelectedNodes[i] ~= selectedNodes[i] then
			i = #selectedNodes+1
			sameNodes = false
		end
	end
	
	if not sameNodes then
		updateScriptList()
		
		selectedNodes = newSelectedNodes
		if #selectedNodes == 1 then
			
			local isAnIsland = selectedNodes[1]:getNodeType() == NodeId.island
			multiplayerOwnerPanel:setVisible(isAnIsland)
			
			sceneNameTextField:setText(selectedNodes[1]:getSceneName())
			if isAnIsland then
				local island = selectedNodes[1]
				--island = Island()
				multiplayerOwnerTextField:setText(tostring(island:getPlayerId()))
			end
			
			updateMatrixData()
			
			local meshList = selectedNodes[1]:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
			
			if not isAnIsland and #meshList > 0 then
				colorPanel:setVisible(true)
				local color = meshList[1]:getColor()
				for i=2, #meshList do
					color = color + meshList[i]:getColor()
				end
				color = color / #meshList
				
				print("nil\n")
				startStrawColor.setChangeCallback(nil)
				print("set Color\n")
				startStrawColor.setColor(color)
				print("modelChangeColor callback set\n")
				startStrawColor.setChangeCallback(modelChangeColor)
			else
				colorPanel:setVisible(false)
			end
		else
			multiplayerOwnerPanel:setVisible(false)
		end
	elseif #selectedNodes == 1 and selectedNodeLastMatrix ~= selectedNodes[1]:getLocalMatrix() then
		updateMatrixData()
	end
	
end

--This function is called from scrpt Move, rotatem scale and select nodes
function update()
	
	updateScelectedNodes()

	if #selectedNodes ~= 1 then
		titlePanel:setVisible(false)
	else
		titlePanel:setVisible(true)
		
		startStrawColor.update()
		
		Core.getComUnit():sendTo("EditorMenu","updateScript","")
	end
	return true
end