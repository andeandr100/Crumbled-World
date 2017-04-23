require("MapEditor/menuStyle.lua")
require("MapEditor/iconCamera.lua")
require("MapEditor/deafultCameraPosition.lua")
require("MapEditor/listener.lua")
require("MapEditor/mapSettingsTable.lua")
--this = SceneNode()


function addFileToSceneNode(fileName)
	if playerNode then
		print("fileName: "..fileName:toString().."\n")
		local script = playerNode:loadLuaScript(fileName:toString())
		addScriptToMapSettingsMenu(script)
	else
		print("No playerNode was found\n")
	end
end

function removeScript(button)
	playerNode:removeScript(Text(button:getTag():toString()))
	scriptPanel:removePanel(button:getParent())
end

function openFileWindo(button)
	fileWindow = FileWindow( camera, Text("Open script"), Text("Data/Lua/") )
	fileWindow:setDefaultFileData(Text("function create()\n\t\nend\n\nfunction update()\n\t\n\treturn false\nend\n"))
	fileWindow:addLuaScriptCallbackExecute("addFileToSceneNode")
end


function addScriptToMapSettingsMenu(script)
	local aButton = scriptPanel:add(Button(PanelSize(Vec2(-1, 0.025)), script:getName(), ButtonStyle.SQUARE))
	aButton:setTag(script:getFileName())
	aButton:setTextAnchor(Anchor.MIDDLE_LEFT)
	aButton:setEdgeColor(Vec4())
	aButton:setEdgeHoverColor(Vec4())
	aButton:setEdgeDownColor(Vec4())
	aButton:setInnerColor(Vec4())	
	aButton:setTextColor(MainMenuStyle.textColor)
	aButton:setTextHoverColor(MainMenuStyle.textColorHighLighted)	
	aButton:setTextDownColor(MainMenuStyle.textColorHighLighted)
	aButton:setInnerHoverColor(Vec4(0.15,0.15,0.15,1))	
	aButton:setInnerDownColor(Vec4(0,0,0,1))
	aButton:addEventCallbackExecute(openAndShowScriptFile)
	
	aButton:setLayout(FlowLayout(Alignment.TOP_RIGHT))
	local xButton = aButton:add(Button(PanelSize(Vec2(-1), Vec2(1)), "X", ButtonStyle.SQUARE))
	xButton:setEdgeColor(Vec4())
	xButton:setEdgeHoverColor(Vec4())
	xButton:setEdgeDownColor(Vec4())
	xButton:setInnerColor(Vec4())	
	xButton:setTextColor(Vec3(1))	
	xButton:setInnerHoverColor(Vec4(0.15,0.15,0.15,1))	
	xButton:setInnerDownColor(Vec4(0,0,0,1))
	xButton:setTag(script:getName())
	xButton:addEventCallbackExecute(removeScript)
end


function openAndShowScriptFile(button)
	comUnit:sendTo("LuaTextEditor","showFile",button:getTag():toString())
	--comUnit:sendTo("EditorMenu","togleMainFormVisible","")
end

function showWindow(name)
	if name == "MapSettings" then
		form:setVisible( not form:getVisible() )
		if form:getVisible() then
			cameraOveride:pushEvent("Pause")
			reloadData()
		else
			cameraOveride:pushEvent("Resume")
		end
	else
		quitForm(nil)
		--form:setVisible(false)
	end
end


function create()
	editorListener:registerEvent("window", showWindow)
	
	camera = ConvertToCamera(this:getRootNode():findNodeByName("MainCamera"))
	--camera = Camera()
	
	comUnit = Core.getComUnit()
	comUnit:setName("MapSettingsMenu")
	comUnit:setCanReceiveTargeted(true)
	comUnit:setCanReceiveBroadcast(false)
	
	cameraOveride = Listener("cameraOveride")
	
	
	playerNode = this:findNodeByType(NodeId.playerNode)

	input = Core.getInput()
	if camera then
		--Set default values
		setDeafultValue("difficultyMin", 0.0)
		setDeafultValue("difficultyMax", 0.0)
		setDeafultValue("waveCount", 25)
		setDeafultValue("name", "")
		
		defaultCameraPos = DeafultCameraPosition.new()
		
		IconCamera.create()
		
		form = Form( camera, PanelSize(Vec2(0.32,0.85)), Alignment.MIDDLE_CENTER);
		form:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor));
		form:setLayout(FlowLayout());
		form:setBorder(Border(BorderSize(Vec4(0.002)), MainMenuStyle.borderColor));
		form:setPadding(BorderSize(Vec4(0.005)));
		form:getLayout():setPanelSpacing(PanelSize(Vec2(0.005)));
		form:getPanelSize():setFitChildren(false, false);
		form:setVisible(false)


		local label = form:add(Label(PanelSize(Vec2(-1,0.03)), "Map Settings", Vec3(1)))
		label:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		local quitButton = label:add(Button(PanelSize(Vec2(-1),Vec2(1)),"X", ButtonStyle.SQUARE))
		quitButton:addEventCallbackExecute(quitForm)
		
		local mainArea = form:add(Panel(PanelSize(Vec2(-1,-1))))
		mainArea:setEnableYScroll()
		mainArea:setLayout(FlowLayout())
		mainArea:getLayout():setPanelSpacing(PanelSize(Vec2(0.002, 0.002)))
		
		
		local numChars = "0123456789"
		local directionChars = "-.0123456789"
		
		--Name and icon
		MenuStyle.addTitel(mainArea, "Information")
		local informationPanel = mainArea:add(Panel(PanelSize(Vec2(-1,0.14))))
		local namePanel = informationPanel:add(Panel(PanelSize(Vec2(-0.40,-1))))
		namePanel:add(Label(PanelSize(Vec2(-1,0.025), Vec2(3.5,1)), "Name:", MainMenuStyle.textColor))
		namePanel:setLayout(FlowLayout(PanelSize(Vec2(0.002, 0.002))))
		nameField = namePanel:add(TextField(PanelSize(Vec2(-1,0.025)), MapSettings.name))
		nameField:addEventCallbackChanged(saveMapSettings)
		
		namePanel:add(Label(PanelSize(Vec2(-1,0.025), Vec2(3.5,1)), "Difficulty:", MainMenuStyle.textColor))
		difficultyFieldMin = namePanel:add(TextField(PanelSize(Vec2(-0.44,0.025)), tostring(MapSettings.difficultyMin)))
		difficultyFieldMin:setWhiteList(directionChars)
		difficultyFieldMin:addEventCallbackChanged(saveMapSettings)
		namePanel:add(Label(PanelSize(Vec2(-1,0.025), Vec2(0.21,1)), "/", MainMenuStyle.textColor))
		difficultyFieldMax = namePanel:add(TextField(PanelSize(Vec2(-1,0.025)), tostring(MapSettings.difficultyMax)))
		difficultyFieldMax:setWhiteList(directionChars)
		difficultyFieldMax:addEventCallbackChanged(saveMapSettings)
		namePanel:add(Label(PanelSize(Vec2(-1,0.025), Vec2(3.5,1)), "Wave count:", MainMenuStyle.textColor))
		waveCountField = namePanel:add(TextField(PanelSize(Vec2(-1,0.025)), tostring(MapSettings.gameMode)))
		waveCountField:addEventCallbackChanged(saveMapSettings)
		
		namePanel:add(Label(PanelSize(Vec2(-1,0.025), Vec2(3.5,1)), "Type:", MainMenuStyle.textColor))
		gameModeField = namePanel:add(TextField(PanelSize(Vec2(-1,0.025)), tostring(MapSettings.gameMode)))
		gameModeField:addEventCallbackChanged(saveMapSettings)
		
		namePanel:add(Label(PanelSize(Vec2(-1,0.025), Vec2(3.5,1)), "Players:", MainMenuStyle.textColor))
		playersField = namePanel:add(TextField(PanelSize(Vec2(-1,0.025)), tostring(MapSettings.players)))
		playersField:setWhiteList(numChars)
		playersField:addEventCallbackChanged(saveMapSettings)
		
		--default camera position
		--this is a hardcoded deafult camera position for the crumbled worlds default camera
		local cameraPanel = informationPanel:add(Panel(PanelSize(Vec2(-0.50,-1))))
		cameraPanel:setLayout(FallLayout(Alignment.TOP_LEFT))
		local cameraTopPanel = cameraPanel:add(Panel(PanelSize(Vec2(-1,0.025))))
		cameraTopPanel:setLayout(FlowLayout(Alignment.TOP_LEFT))
		cameraTopPanel:add(Label(PanelSize(Vec2(-0.5,0.025)), " Camera:", MainMenuStyle.textColor, Alignment.TOP_LEFT))
		cameraPlayerComboBox = cameraTopPanel:add(ComboBox(PanelSize(Vec2(-1,0.025)), "Default"))
		
		
		local cameraPositionImage = cameraPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), defaultCameraPos.getCameraTexture()))
		local button = cameraPositionImage:add(Button(PanelSize(Vec2(-1)),"", ButtonStyle.SQUARE))
		button:addEventCallbackExecute(setDefaultCameraPos)
		button:setToolTip(Text("Set the main cameras start position"))
		
		
		
		button:setEdgeColor(Vec4(0), Vec4(0))
		button:setEdgeHoverColor(Vec4(1,1,1,0.6), Vec4(1,1,1,0.5))
		button:setEdgeDownColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
	
		button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
		button:setInnerHoverColor(Vec4(1,1,1,0.1), Vec4(1,1,1,0.1), Vec4(1,1,1,0.1))
		button:setInnerDownColor(Vec4(1,1,1,0.05), Vec4(1,1,1,0.05), Vec4(1,1,1,0.05))
		
		--Icon camera icon	
		local iconPanel = informationPanel:add(Panel(PanelSize(Vec2(-1,-1))))
		iconPanel:setLayout(FallLayout(Alignment.TOP_LEFT))
		iconPanel:add(Label(PanelSize(Vec2(-1,0.025), Vec2(2.3,1)), " Icon:", MainMenuStyle.textColor, Alignment.TOP_LEFT))
		local iconImage = iconPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), IconCamera.camera:getTexture()))
		button = iconImage:add(Button(PanelSize(Vec2(-1)),"", ButtonStyle.SQUARE))
		button:addEventCallbackExecute(captureIconImage)
		
		button:setEdgeColor(Vec4(0), Vec4(0))
		button:setEdgeHoverColor(Vec4(1,1,1,0.6), Vec4(1,1,1,0.5))
		button:setEdgeDownColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
	
		button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
		button:setInnerHoverColor(Vec4(1,1,1,0.1), Vec4(1,1,1,0.1), Vec4(1,1,1,0.1))
		button:setInnerDownColor(Vec4(1,1,1,0.05), Vec4(1,1,1,0.05), Vec4(1,1,1,0.05))
		
		--Ambient light
		MenuStyle.addTitel(mainArea, "Ambient light")
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(3,1)), "Color", MainMenuStyle.textColor))
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(0.75,1)), "R:", MainMenuStyle.textColor))
		ambientRed = mainArea:add(TextField(PanelSize(Vec2(-1,0.025), Vec2(3, 1))))
		ambientRed:addEventCallbackChanged(updateLightValues)
		ambientRed:setWhiteList(numChars)
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(0.75,1)), "G:", MainMenuStyle.textColor))
		ambientGreen =mainArea:add(TextField(PanelSize(Vec2(-1,0.025), Vec2(3, 1))))
		ambientGreen:addEventCallbackChanged(updateLightValues)
		ambientGreen:setWhiteList(numChars)
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(0.75,1)), "B:", MainMenuStyle.textColor))
		ambientBlue = mainArea:add(TextField(PanelSize(Vec2(-1,0.025), Vec2(3, 1))))
		ambientBlue:addEventCallbackChanged(updateLightValues)
		ambientBlue:setWhiteList(numChars)
		mainArea:add(Panel(PanelSize(Vec2(-1,0.05))))
		updateAmbientLight();
		

		--Directional light
		MenuStyle.addTitel(mainArea, "Directional light")
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(3,1)), "Color", MainMenuStyle.textColor))
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(0.75,1)), "R:", MainMenuStyle.textColor))
		directionRed = mainArea:add(TextField(PanelSize(Vec2(-1,0.025), Vec2(3, 1))))
		directionRed:addEventCallbackChanged(updateLightValues)
		directionRed:setWhiteList(numChars)
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(0.75,1)), "G:", MainMenuStyle.textColor))
		directionGreen = mainArea:add(TextField(PanelSize(Vec2(-1,0.025), Vec2(3, 1))))
		directionGreen:addEventCallbackChanged(updateLightValues)
		directionGreen:setWhiteList(numChars)
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(0.75,1)), "B:", MainMenuStyle.textColor))
		directionBlue = mainArea:add(TextField(PanelSize(Vec2(-1,0.025), Vec2(3, 1))))
		directionBlue:addEventCallbackChanged(updateLightValues)
		directionBlue:setWhiteList(numChars)
	
		mainArea:add(Panel(PanelSize(Vec2(-1,0.025))))
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(3,1)), "Direction", MainMenuStyle.textColor))
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(0.75,1)), "X:", MainMenuStyle.textColor))
		directionX = mainArea:add(TextField(PanelSize(Vec2(-1,0.025), Vec2(3, 1))))
		directionX:addEventCallbackChanged(updateLightValues)
		directionX:setWhiteList(directionChars)
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(0.75,1)), "Y:", MainMenuStyle.textColor))
		directionY = mainArea:add(TextField(PanelSize(Vec2(-1,0.025), Vec2(3, 1))))
		directionY:addEventCallbackChanged(updateLightValues)
		directionY:setWhiteList(directionChars)
		mainArea:add(Label(PanelSize(Vec2(-1,0.025), Vec2(0.75,1)), "Z:", MainMenuStyle.textColor))
		directionZ = mainArea:add(TextField(PanelSize(Vec2(-1,0.025), Vec2(3, 1))))
		directionZ:addEventCallbackChanged(updateLightValues)
		directionZ:setWhiteList(directionChars)
		mainArea:add(Panel(PanelSize(Vec2(-1,0.05))))
		updateDirectionalLight()
		
		--Script
		MenuStyle.addTitel(mainArea, "Scripts")
		scriptPanel = mainArea:add(Panel(PanelSize(Vec2(-1,-1))))
		scriptPanel:getPanelSize():setFitChildren(false, true)
		scriptPanel:getPanelSize():setMinSize(PanelSize(Vec2(0,0.025)))
		scriptPanel:setBackground(Sprite(Vec4(0.2,0.2,0.2,0.8)))
		scriptPanel:setPadding(BorderSize(Vec4(0.00125)))
		scriptPanel:setBorder(Border(BorderSize(Vec4(0.00125)), Vec3(0)))
		addScriptButton = mainArea:add(Button(PanelSize(Vec2(1,0.025), Vec2(3,1)),"Add"))
		addScriptButton:addEventCallbackExecute(openFileWindo)
		

		updateLightValues()
	end
	return true
end

function setDefaultCameraPos()
	defaultCameraPos.captureIconImage()
end

function reloadData()
	
	local nodeId = this:findNodeByType(NodeId.fileNode)
	if nodeId and nodeId:contains("info.txt") then
		print(nodeId:getFile("info.txt"):getContent())
		print("\n\n")
		MapSettings = totable( nodeId:getFile("info.txt"):getContent() )
	end
	
	--Set default values
	setDeafultValue("difficultyMin", 0.0)
	setDeafultValue("difficultyMax", 0.0)
	setDeafultValue("waveCount", 25)
	setDeafultValue("name", "")
	setDeafultValue("gameMode", "Point")
	setDeafultValue("mapSize", "8x8")
	setDeafultValue("players", 1)
	
	local mapSize = getMapSize()
	MapSettings.mapSize = tostring(mapSize.x).."x"..tostring(mapSize.y)
	
	nameField:setText(MapSettings.name)
	difficultyFieldMin:setText(tostring(MapSettings.difficultyMin))
	difficultyFieldMax:setText(tostring(MapSettings.difficultyMax))
	waveCountField:setText(tostring(MapSettings.waveCount))
	gameModeField:setText(MapSettings.gameMode)
	playersField:setText(tostring(MapSettings.players))
	currentCameraToChange = 0
	
	defaultCameraPos.reloadData()
	IconCamera.reloadData()
	reloadAllScripts()
	
	updateCameraPlayerComboBox()
end

function getMapSize()
	local islands = this:getRootNode():findAllNodeByTypeTowardsLeaf({NodeId.island})
	--mapBox = Box()
	local mapBox = #islands > 0 and islands[1]:getGlobalBoundingBox() or Box()
	
	for i=2, #islands do
		mapBox:expand(islands[i]:getGlobalBoundingBox())
	end
	
	local size = mapBox:getMaxPos()-mapBox:getMinPos()
	return Vec2(math.round( size.x ), math.round(size.z))
end

function reloadAllScripts()
	--Remove all previously loaded script
	scriptPanel:clear()
	--Get the player node
	playerNode = this:findNodeByType(NodeId.playerNode)
	--Load all scirpts
	if playerNode then
		luaScript = playerNode:getAllScript()
		for i=1, #luaScript do
			addScriptToMapSettingsMenu(luaScript[i])
		end
	end
end

function updateLightValues()
	local ambientLight = camera:getAmbientLight()
	ambientLight:setColor(Vec3(ambientRed:getFloat()/255, ambientGreen:getFloat()/255, ambientBlue:getFloat()/255))

	local directionLight = camera:getDirectionLight()
	directionLight:setColor(Vec3(directionRed:getFloat()/255, directionGreen:getFloat()/255, directionBlue:getFloat()/255))
	local direction = Vec3(directionX:getFloat(), directionY:getFloat(), directionZ:getFloat());
	--The game system can't handle a directionlight without direction
	if direction:length() > 0.001 then
		directionLight:setDirection(direction)
	else
		directionLight:setDirection(Vec3(0,1,0))
	end
end

function updateAmbientLight()
	local ambientLight = camera:getAmbientLight()
	if ambientLight then
		print("Ambient light exit\n")
	else
		print("No no no ambient light\n")
	end
	
	ambientRed:setText( string.format ("%.0f", tostring( ambientLight:getColor().x * 255 )) )
	ambientGreen:setText( string.format ("%.0f", tostring( ambientLight:getColor().y * 255)) )
	ambientBlue:setText( string.format ("%.0f", tostring( ambientLight:getColor().z * 255)) )
end

function updateDirectionalLight()
	local directionLight = camera:getDirectionLight();
	directionRed:setText( string.format ("%.0f", tostring( directionLight:getColor().x * 255 ) ) )
	directionGreen:setText( string.format ("%.0f", tostring( directionLight:getColor().y * 255 ) ) )
	directionBlue:setText( string.format ("%.0f", tostring( directionLight:getColor().z * 255 ) ) )

	directionX:setText( string.format ("%.3f", tostring( directionLight:getDirection().x ) ) )
	directionY:setText( string.format ("%.3f", tostring( directionLight:getDirection().y ) ) )
	directionZ:setText( string.format ("%.3f", tostring( directionLight:getDirection().z ) ) )
end

function quitForm(button)
	if IconCamera.isVisible() then
		IconCamera.saveAndQuit()
	elseif defaultCameraPos.isVisible() then
		defaultCameraPos.saveAndQuit()
	else
		form:setVisible(false)
		cameraOveride:pushEvent("Resume")
	end
end

function update()
	
	
	
	if not IconCamera.form:getVisible() and not defaultCameraPos.isVisible() then
		--we cant toogle visibility when icon camera is visible
		
		if input:getKeyDown(Key.F4) then
			editorListener:pushEvent("window","MapSettings")
		end
	end
	
	
	if form:getVisible() then
		--only update when form is visible
		form:update()
		defaultCameraPos.update()
		IconCamera.update()	
	end
	
	return true
end