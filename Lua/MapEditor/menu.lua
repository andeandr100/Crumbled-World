require("MapEditor/menuCallback.lua")
require("MapEditor/menuStyle.lua")
require("MapEditor/Tools/Tool.lua")
require("MapEditor/createNewMap.lua")
require("MapEditor/fileDropDownMenu.lua")
require("MapEditor/Tools/editorSettings.lua")
require("menuModel.lua")

--this = SceneNode()

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

function create()
	
	CreateNewMap.newMap()
	
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)

	visible = true
	
	
	camera = this.getRootNode(this):findNodeByName("MainCamera")
	--camera = Camera()
	toolBGColor = Vec4(0.17, 0.17, 0.17, 0.97)
	
	
	comUnit = Core.getComUnit()
	comUnit:setName("EditorMenu")
	comUnit:setCanReceiveTargeted(true)
	comUnit:setCanReceiveBroadcast(false)
	
	
	comUnitTable = {}
	comUnitTable["togleMainFormVisible"] = togleTextEditor
	
	local mapEditor = Core.getBillboard("MapEditor")
	mapEditor:setString("ToolDeActivatedCallback", "deActivated")
	mapEditor:setString("ToolActivatedCallback", "activated")
	
	if camera then
		
		form = Form(ConvertToCamera(camera), PanelSize(Vec2(-1,-1)), Alignment.TOP_LEFT)
		form:setLayout(FallLayout())

		createMenuBar()
		
		createSubMenues()
		
		createToolWorldEditSettings()
	
		mapEditor:setPanel("BuildAreaPanel", mainArea)	
		mapEditor:setPanel("ToolPanel", toolsMenu)		
		mapEditor:setPanel("SettingPanel", settingsMenu)
		
		Tool.create()
		
		local toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
		toolManager:loadToolScript("MapEditor/Tools/ModelPlaceTool.lua")
		
		editorListener:registerEvent("newMap", newMap)
		editorListener:registerEvent("loadedMap", loadedMap)
	end
	
	
	return true
end

function newMap()
	
end

function loadedMap()
	EditorSettings.restoreSettings()
end

function togleMapSettings()
	editorListener:pushEvent("window", "MapSettings")
	print("show map settings\n")
end

function togleShowTextEditor()
	editorListener:pushEvent("window", "TextEditor")
	print("show text editor\n")
end

function playTheMap()
	--filePath
	local filePath = "Data/MapEditor/Debug/temp.map"
	--Save the map
	Editor.save(filePath)
	--Do some testing check if the map even can be played
	Core.startMapInDebugMode(filePath)
	--Pause the editor we do not want to update and render the editor while we test the map
	Editor.pauseEditor()
	--start the loading screen
	local worker = Worker("Menu/loadingScreen.lua", true)
	worker:start()
end

function createMenuBar()
	menuBar = MainMenuStyle.createTopMenu(form, PanelSize(Vec2(-1,0.035)))
	local fileButton = MainMenuStyle.addTopMenuButton( menuBar, Vec2(3,1), "File")
	fileMenu = FileDropDownMenu.new(fileButton)
	
	local textEditorButton = MainMenuStyle.addTopMenuButton( menuBar, Vec2(4,1), "Text editor")
	textEditorButton:addEventCallbackExecute(togleShowTextEditor)
	
	local mapSettingsButton = MainMenuStyle.addTopMenuButton( menuBar, Vec2(5,1), "Map settings")
	mapSettingsButton:addEventCallbackExecute(togleMapSettings)
	
--	local mapSettingsButton = MainMenuStyle.addTopMenuButton( menuBar, Vec2(3,1), "Play")
--	mapSettingsButton:addEventCallbackExecute(playTheMap)
--	mapSettingsButton:setVisible(false)
	
	editorListener:pushEvent("window", "hide")
	
end

function setCustomGamePanelVisible(panel)
	--optionsPanel:setVisible(false);
	--customGamePanel:setVisible(not customGamePanel:getVisible());
end

function togleVisible(panel)
	print("togle visible tag: "..panel:getTag():toString().."\n")
	for splitedStr in panel:getTag():toString():gmatch("([^;]*);") do
		print(splitedStr.."\n")
		local bodyPanel = treeViewPanel:getPanelById(splitedStr)
		if bodyPanel then
			bodyPanel:setVisible(not bodyPanel:getVisible())
		end
	end
end

function createToolPanel(panel)
	local topPanel = panel:add(Panel(PanelSize(Vec2(0.16,-1))))
	topPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
	topPanel:setLayout(FallLayout())
	
	local border = panel:add(Panel(PanelSize(Vec2(2,-1),PanelSizeType.Pixel)))
	border:setBackground(Sprite(MainMenuStyle.borderColor))
	return topPanel
end



function createSubMenues()
	mainArea = form:add(Panel(PanelSize(Vec2(-1,-1))))
	Editor.setMainAreaPanel(mainArea)

	toolsMenu = createToolPanel(mainArea)
	--set map area to fit the bounds bettwen the tools and settings menu
	rightMainArea = mainArea:add(Panel(PanelSize(Vec2(-1,-1))))
	rightMainArea:setLayout(FlowLayout(Alignment.TOP_RIGHT))
	rightMainArea:setCanHandleInput(false)
	
	
	settingsMenu = createToolPanel(rightMainArea)
	
	EditorSettings.createMenu(settingsMenu)

	--Tools menu
	texture = Core.getTexture("GUI_MapEditor.png")
	local islandTool = MenuStyle.createToolMenu("Island tool", true, 4, 2)
	
	islandBuilderButton = MenuStyle.addToolButton(islandTool,Vec2(0,0.875), setToolIslandBuilder, "Island builder")
	MenuStyle.addToolButton(islandTool,Vec2(0.25,0.875), setIslandRiseTool, "Island rise vertex points")
	MenuStyle.addToolButton(islandTool,Vec2(0.5,0.875), setIslandLowerTool, "Island lower vertex points")
	MenuStyle.addToolButton(islandTool,Vec2(0.75,0.875), setIslandSmothTool, "Island smoth vertex points")
	MenuStyle.addToolButton(islandTool,Vec2(0.0,0.75), setIslandElevateTool, "Island elevate vertex points")
	--MenuStyle.addToolButton(islandTool,Vec2(0,0.875), Vec2(0.25, 1), setIslandColorTool, "Island color vertex")
	islandPaintbrushTool = MenuStyle.addToolButton(islandTool,Vec2(0.25,0.75), setIslandPaintbrushTool, "Island paint tool")
	islandEdgeBuilderButton = MenuStyle.addToolButton(islandTool,Vec2(0.5,0.75), createIslandEdge, "Create island edge")
	islandEdgeBuilderButton = MenuStyle.addToolButton(islandTool,Vec2(0.75,0.75), createIslandEdgeFlora, "Generate flora on the existing edge, based on how much nature is close by")
	
	
	local textureToolPanel = MenuStyle.createToolMenu("Tools", true, 4, 2)	

	bridgeBuilderButton = MenuStyle.addToolButton(textureToolPanel,Vec2(0.25,0.5), setBridgeBuilderTool, "Brigdge tool")
	MenuStyle.addToolButton(textureToolPanel,Vec2(0,0.5), setLightBuilderToool, "Light tool")
	MenuStyle.addToolButton(textureToolPanel,Vec2(0.5,0.5), setNavMeshBuilderTool, "Nav mesh builder tool")
	MenuStyle.addToolButton(textureToolPanel,Vec2(0.75,0.5), setGrassTool, "Grass tool")
	MenuStyle.addToolButton(textureToolPanel,Vec2(0.0,0.375), setRailroadTool, "Railroad tool")
	MenuStyle.addToolButton(textureToolPanel,Vec2(0.25,0.375), setPathTool, "Path tool")
end

function addSceneNodeToTreeView( treeViewPanel, sceneNode )
	local childSize = sceneNode:getChildSize();

	local header = treeViewPanel:add(Panel(PanelSize(Vec2(-1, 0.02))))
	local body = nil
	if childSize > 0 then
		button = header:add(Button(PanelSize(Vec2(-1),Vec2(1)),"+", ButtonStyle.SQUARE))
		--xButton:addEventCallbackExecute(removeScript)	
		button:addEventCallbackExecute(togleVisible)

		body = treeViewPanel:add(Panel(PanelSize(Vec2(-1, 100))))
		body:getPanelSize():setFitChildren(false, true)
		body:setLayout(FallLayout())
		body:setMargin(BorderSize(Vec4(0.02,0,0,0)))
		body:setVisible(false)
		--body:setBackground(Sprite(Vec4(0.3, 0.3, 0.3, 0.98)))
		
		button:setTag(body:getPanelId() .. ";" )

		button:setEdgeColor(Vec4(0,0,0,1), Vec4(0,0,0,1))
		button:setEdgeHoverColor(Vec4(0,0,0,1), Vec4(0,0,0,1))
		button:setEdgeDownColor(Vec4(0,0,0,1), Vec4(0,0,0,1))

		button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
		button:setInnerHoverColor(toolBGColor, Vec4(0,0,0,0.975),toolBGColor)
		button:setInnerDownColor(toolBGColor, Vec4(0,0,0,0.99),toolBGColor)
	end

	data[sceneNode:getId()] = {header=header, body=body}

	
	local name = sceneNode:getSceneName()
	if name == "" then
		name = ""..sceneNode:getNodeType()
	end
	local label = header:add(Label(PanelSize(Vec2(-1)), name))
	label:setTextColor(Vec3(1))
	

	--Add nodes with children first
	for i=0, childSize-1 do
		if sceneNode:getChildNode(i):getChildSize() > 0 then
			addSceneNodeToTreeView(body, sceneNode:getChildNode(i))
		end
	end
	--last we add nodes with no children
	for i=0, childSize-1 do
		if sceneNode:getChildNode(i):getChildSize() == 0 then
			addSceneNodeToTreeView(body, sceneNode:getChildNode(i))
		end
	end

end

function updateTreeView(sceneNode)

	subData = data[sceneNode:getParent():getId()]
	if subData then
		if subData["body"] then
			addSceneNodeToTreeView(subData["body"], sceneNode)
		end
	end
end

function createTreeView()

	data = {}
	
	treeViewPanel = settingsMenu:add(Panel(PanelSize(Vec2(-1,0.3))))
	treeViewPanel:setBorder(Border(BorderSize(Vec4(0.002)), Vec4(0,0,0,1)))
	treeViewPanel:setMargin(BorderSize(Vec4(0.005)))
	treeViewPanel:setPadding(BorderSize(Vec4(0.01)))
	treeViewPanel:setLayout(FallLayout())
	treeViewPanel:setEnableYScroll()
	treeViewPanel:setBackground(Sprite(Vec4(0.15, 0.15, 0.15, 0.98)))

	local sceneNode = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.playerNode)

	addSceneNodeToTreeView( treeViewPanel, sceneNode)

end

function updateAndSaveToolConfig(textField)
	selectedConfig:get(textField:getTag():toString()):setDouble(tonumber(textField:getText()))
	selectedRootConfig:save()
	toolManager:toolSettingsChanged()
end



function createToolWorldEditSettings()
	
	toolWorldSettingsPanel, toolArea, configToolHeaderButton = MenuStyle.createTitleAndBody(settingsMenu, "World tool settings")

	local panelWidthFor3 = toolAndSettingMenuSize - 0.005 * 3 - 0.005
	local panelWidthFor2 = toolAndSettingMenuSize - 0.005 * 2 - 0.005
	local labelWidth = panelWidthFor3 * 0.333
	local secondColumWidth = panelWidthFor2 - labelWidth

	configRows = {}

	for i=1, 3 do
		local row = toolArea:add(Panel(PanelSize(Vec2(panelWidthFor2, 0.025))))
		local label = row:add(Label(PanelSize(Vec2(labelWidth, 0.025)),"Area", Vec3(1)))
		local textField = row:add(TextField(PanelSize(Vec2(secondColumWidth, 0.025))))
		textField:addEventCallbackExecute(updateAndSaveToolConfig)
		textField:setWhiteList("-.0123456789")
		configRows[i] = {row, label, textField}
	end
end

function showWorldTool(toolName)
	--toolName = string()
	configToolHeaderButton:setText("Tool " .. toolName .. " settings")
	toolWorldSettingsPanel:setVisible(true)

	selectedRootConfig = Config("ToolsSettings")
	selectedConfig = selectedRootConfig:get(toolName)

	for i=1, 3 do
		if selectedConfig:exist(tostring(i)) then
			local name = selectedConfig:get(tostring(i)):getString()
			configRows[i][1]:setVisible(true)
			configRows[i][2]:setText(name)
			configRows[i][3]:setTag(name)
			configRows[i][3]:setText(tostring(selectedConfig:get(name):getDouble()))
		else
			configRows[i][1]:setVisible(false)
		end
	end
	selectedRootConfig:save()
end


function updateEditScene(scene)
	currentEditScene = scene
	if scene then
		if not scene:findNodeByTypeTowardsRoot(NodeId.island) then
			islandBuilderButton:setEnabled(true)
			bridgeBuilderButton:setEnabled(true)
--			islandPaintButton:setEnabled(false)
		else
			islandBuilderButton:setEnabled(false)
			bridgeBuilderButton:setEnabled(false)
--			islandPaintButton:setEnabled(true)
		end
	end
end

function updateTool(toolName)
	hideAllSettingsPanel()

	if toolName == "worldChoper" then
		print("worldChoper")
	elseif toolName == "worldRise" then
		showWorldTool(toolName)
	elseif toolName == "worldSmoth" then 
		showWorldTool(toolName)
	elseif toolName == "worldSink" then
		showWorldTool(toolName)
	elseif toolName == "worldElevate" then
		showWorldTool(toolName)
	elseif toolName == "WorldColor" then
		showWorldTool(toolName)
	elseif toolName == "lightPlacer" then
		print("lightPlacer")
	elseif toolName == "bridgeBuilder" then
		print("bridgeBuilder")
	elseif toolName == "sceneSelect" then
		print("sceneSelect")
	elseif toolName == "sceneMove" then
		print("sceneMove")
	elseif toolName == "sceneRotate" then
		print("sceneRotate")
	elseif toolName == "sceneScale" then
		print("sceneScale")
	elseif toolName == "scenePlacer" then
		print("scenePlacer")
	end
end

function togleTextEditor(panel)
	--visible = not visible;
	--if not visible then
	--	form:setKeyboardOwner()
	--end
end

function update()
	
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message]~=nil then
			comUnitTable[msg.message](msg.parameter)
		end
	end
	
	if Core.getInput():getKeyDown(Key.F3) then
		togleTextEditor(nil)
	end

	if visible then
		form:update()
		fileMenu.update()
	end
	
	
	return true;
end