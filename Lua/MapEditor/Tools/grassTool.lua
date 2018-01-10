require("MapEditor/Tools/Tool.lua")
require("MapEditor/menuStyle.lua")
require("MapEditor/Tools/circleModel.lua")
require("MapEditor/preSetPanel.lua")
require("Menu/colorPicker.lua")

--this = SceneNode()

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function textChanged(textField)
	grassConfig[textField:getTag():toString()] = tonumber( textField:getText() )
	
	
	
	if textField:getTag():toString() == "strawGravity" then
		grassConfig.strawGravity = tonumber( textField:getText() )
	elseif textField:getTag():toString() == "radius" then
		grassConfig.radius = tonumber( textField:getText() )
		CircleModel.create(grassConfig.radius)
	elseif textField:getTag():toString() == "strawsPerSecond" then
		grassConfig.strawsPerSecond = tonumber( textField:getText() )
	elseif textField:getTag():toString() == "width" then
		grassConfig.width = tonumber( textField:getText() )
	elseif textField:getTag():toString() == "length" then
		grassConfig.length = tonumber( textField:getText() )
	elseif textField:getTag():toString() == "bendScale" then
		grassConfig.bendScale = math.clamp( tonumber( textField:getText() ), 0, 1)
		if grassConfig.bendScale == 0 or grassConfig.bendScale == 1 then
			textField:setText(tostring(grassConfig.bendScale))
		end
	end
	
	toolConfig:get("grassTool"):setTable(grassConfig)
	toolConfig:save()
end

function toogleClearStraws(button)
	grassConfig.clearStraws = (button:getTag():toString() == "False")
	button:setText(grassConfig.clearStraws and "True" or "False")
	
	toolConfig:get("grassTool"):setTable(grassConfig)
	toolConfig:save()
	button:setTag(grassConfig.clearStraws and "True" or "False")
end

function toogleEnableDisabledButton(button)
	local name, value = string.match(button:getTag():toString(), "(.*):(.*)")
	if value == "True" then
		button:setText("Disabled")
		grassConfig[name] = false
	else
		button:setText("Enabled")
		grassConfig[name] = true
	end
	
	toolConfig:get("grassTool"):setTable(grassConfig)
	toolConfig:save()

	button:setTag(name..":"..(grassConfig[name] and "True" or "False"))
end

function Loaded(inGrassData)
	
	grassData = {}	
	islandData = nil
	toCompile = {}
	
	
	grassData = inGrassData	
	
	deActivated()
end

function addPreSet(name)
	print("\n\nname: "..name.."\n\n\n")
	if not presetData[name] then
		PreSetPanel.addPreSet(name)
		
		presetData[name] = {}
		for orig_key, orig_value in pairs(grassConfig) do
			if orig_key ~= "preset" then
				presetData[name][orig_key] = orig_value
			end
		end
		
		toolConfig:get("grassTool"):setTable(grassConfig)
		toolConfig:save()
	end
end

function removePreSet(name)
	if presetData[name] then
		presetData[name] = nil
		
		toolConfig:get("grassTool"):setTable(grassConfig)
		toolConfig:save()
	end
end

function topColorChanged(colorPicker)
	grassConfig.topColor = endStrawColor.getColor()
end

function bottomColorChanged(colorPicker)
	grassConfig.bottomColor = startStrawColor.getColor()
end

function changePreset(name)
	
	local newConfig = presetData[name]
	
	print("\n\n change preset\n\n\n")
	
	if newConfig.strawGravity then
		textFieldGravity:setText(tostring(round(newConfig.strawGravity,3)))
		grassConfig.strawGravity = newConfig.strawGravity
	end
	if newConfig.radius then
		textFieldRadius:setText(tostring(round(newConfig.radius,3)))
		grassConfig.radius = newConfig.radius
	end
	if newConfig.strawsPerSecond  then
		textFieldDensity:setText(tostring(round(newConfig.strawsPerSecond,3)))
		grassConfig.strawsPerSecond = newConfig.strawsPerSecond
	end
	if newConfig.width  then
		textFieldWidth:setText(tostring(round(newConfig.width,3)))
		grassConfig.width = newConfig.width
	end
	if newConfig.length  then
		textFieldLength:setText(tostring(round(newConfig.length,3)))
		grassConfig.length = newConfig.length
	end
	if newConfig.bendScale  then
		textFieldBend:setText(tostring(round(newConfig.bendScale,3)))
		grassConfig.bendScale = newConfig.bendScale
	end
	if newConfig.objectCollision  then
		buttonObjectCollision:setText( newConfig.objectCollision and "Enabled" or "Disabled")
		grassConfig.objectCollision = newConfig.objectCollision
	end
	if newConfig.useNormal  then
		buttonUseNormal:setText( newConfig.useNormal  and "Enabled" or "Disabled")
		grassConfig.useNormal = newConfig.useNormal
	end
	if newConfig.topColor then
		endStrawColor.setColor(newConfig.topColor)
		grassConfig.topColor = newConfig.topColor
	end
	if newConfig.bottomColor then
		startStrawColor.setColor(newConfig.bottomColor)
		grassConfig.bottomColor = newConfig.bottomColor
	end
	
	
	toolConfig:get("grassTool"):setTable(grassConfig)
	toolConfig:save()
end

function createMenu(panel)
	
	local text = grassConfig.objectCollision and "Enabled" or "Disabled"
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Object collision", Vec3(1)))
	buttonObjectCollision = panel:add(Button(PanelSize(Vec2(-1, MenuStyle.rowHeight)), text))
	buttonObjectCollision:addEventCallbackExecute(toogleEnableDisabledButton)
	buttonObjectCollision:setTag("objectCollision:"..(grassConfig.objectCollision and "True" or "False"))

	text = grassConfig.useNormal and "Enabled" or "Disabled"
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Use collision normal", Vec3(1)))
	buttonUseNormal = panel:add(Button(PanelSize(Vec2(-1, MenuStyle.rowHeight)), text))
	buttonUseNormal:addEventCallbackExecute(toogleEnableDisabledButton)
	buttonUseNormal:setTag("useNormal:"..(grassConfig.useNormal and "True" or "False"))
	
	--###################################################
	
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"straw gravity", Vec3(1)))
	textFieldGravity = panel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), tostring(round(grassConfig.strawGravity,3))))
	textFieldGravity:setWhiteList(".-0123456789")
	textFieldGravity:addEventCallbackExecute(textChanged)
	textFieldGravity:setTag("strawGravity")
	
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"straw length", Vec3(1)))
	textFieldLength = panel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), tostring(round(grassConfig.length,3))))
	textFieldLength:setWhiteList(".-0123456789")
	textFieldLength:addEventCallbackExecute(textChanged)
	textFieldLength:setTag("length")
	
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"straw width", Vec3(1)))
	textFieldWidth = panel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), tostring(round(grassConfig.width,3))))
	textFieldWidth:setWhiteList(".-0123456789")
	textFieldWidth:addEventCallbackExecute(textChanged)
	textFieldWidth:setTag("width")
	
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"straw density", Vec3(1)))
	textFieldDensity = panel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), tostring(round(grassConfig.strawsPerSecond,3))))
	textFieldDensity:setWhiteList(".-0123456789")
	textFieldDensity:addEventCallbackExecute(textChanged)
	textFieldDensity:setTag("strawsPerSecond")
	
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"straw bend", Vec3(1)))
	textFieldBend = panel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), tostring(round(grassConfig.bendScale,3))))
	textFieldBend:setWhiteList(".-0123456789")
	textFieldBend:addEventCallbackExecute(textChanged)
	textFieldBend:setTag("bendScale")
	
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"place radius", Vec3(1)))
	textFieldRadius = panel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), tostring(round(grassConfig.radius,3))))
	textFieldRadius:setWhiteList(".-0123456789")
	textFieldRadius:addEventCallbackExecute(textChanged)
	textFieldRadius:setTag("radius")
	
	--###################################################
	
	--toolAndSettingMenuSize
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Straw bottom color", Vec3(1)))
	startStrawColor = ColorPickerForm.new(panel, PanelSize(Vec2(-1, MenuStyle.rowHeight)), Vec3(0.525,0.675,0.225))
	startStrawColor.setChangeCallback(bottomColorChanged)
	startStrawColor.setColor(grassConfig.bottomColor)
	
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Straw top color", Vec3(1)))
	endStrawColor = ColorPickerForm.new(panel, PanelSize(Vec2(-1, MenuStyle.rowHeight)), Vec3(0.675,0.975,0.09))
	endStrawColor.setChangeCallback(topColorChanged)
	endStrawColor.setColor(grassConfig.topColor)
		
	--###################################################
		
	panel:add(Panel(PanelSize(Vec2(-1, MenuStyle.rowHeight))))
	

	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Clear straws", Vec3(1)))
	local button = panel:add(Button(PanelSize(Vec2(-1, MenuStyle.rowHeight)), grassConfig.clearStraws and "True" or "False"))
	button:addEventCallbackExecute(toogleClearStraws)
	button:setTag(grassConfig.clearStraws and "True" or "False")
	
	--###################################################
	
	panel:add(Panel(PanelSize(Vec2(-1, MenuStyle.rowHeight))))
	
	PreSetPanel.createPreSetPanel( panel, addPreSet, removePreSet, changePreset)
	
end

function setDefaultValue(name, value)
	if not grassConfig[name] then
		grassConfig[name] = value
	end
end

function create()
	
	print("\n\n---------------- Grass Tool ---------------\n\n\n")
	
	Tool.create()
	

	grassData = {}	
	islandData = nil
	toCompile = {}
	dataChanged = false
	
	--register listener
	grassListener = Listener("Grass node")
	grassListener:registerEvent("Loaded", Loaded)
	
	--Get billboard for the map editor
	mapEditor = Core.getBillboard("MapEditor")
	--Get the setting panel
	settingsPanel = mapEditor:getPanel("SettingPanel")
	
	camera = this:getRootNode():findNodeByType(NodeId.camera)
	
	--Load config
	toolConfig = Config("ToolsSettings")
	--Get the ligt tool config settings
	grassConfig = toolConfig:get("grassTool"):getTable()
	
	--check that preset exist or creat a new dataset
	local presetNameList = {}
	if not grassConfig["preset"] then
		presetData = {}
		grassConfig["preset"] = presetData
	else
		presetData = grassConfig["preset"]
		for orig_key, orig_value in pairs(presetData) do
			presetNameList[#presetNameList+1] = orig_key
		end	
	end
	
	--set default values for the config
	setDefaultValue("objectCollision", true)
	setDefaultValue("useNormal", true)
	setDefaultValue("strawGravity", 0.5)
	setDefaultValue("length", 0.4)
	setDefaultValue("width", 0.035)
	setDefaultValue("radius", 1.0)
	setDefaultValue("bendScale", 0.5)
	setDefaultValue("strawsPerSecond", 250)
	setDefaultValue("clearStraws", false)
	setDefaultValue("topColor", Vec3(0.675,0.975,0.09))
	setDefaultValue("bottomColor", Vec3(0.525,0.675,0.225))
	
	
	CircleModel.init()
	CircleModel.create( grassConfig.radius )
	CircleModel.mesh:setVisible(false)
	
	if settingsPanel then
		titlePanel, bodyPanel =  MenuStyle.createTitleAndBody(settingsPanel, "Grass tool")
		
		--body = Panel()
		titlePanel:setVisible(false)
		createMenu(bodyPanel)
		
		PreSetPanel.setPreSetList(presetNameList)
	else
		print("\nno settingsPanel\n\n")
		return false
	end
	
	editorListener = Listener("Editor")
	editorListener:registerEvent("newMap", newMap)
	editorListener:registerEvent("loadedMap", loadedMap)
	return true
end

function newMap()
	
	print("\n\nGrass tool New World\n\n\n")

	grassData = {}	
	islandData = nil
	toCompile = {}
end

function loadedMap()
	
	local playerNode = this:getRootNode():findNodeByType(NodeId.playerNode) 
	local grassNode = playerNode:findNodeByName("Grass node")
	if not grassNode then
		local grassNode = playerNode:addChild(SceneNode("Grass node"))
		local script = grassNode:loadLuaScript("Enviromental/grass.lua")
		script:update()
	end
end

function activated()
	titlePanel:setVisible(true)
	CircleModel.mesh:setVisible(true)
	Tool.clearSelectedNodes()
	dataChanged = false
	
	--check if there exist data to init
	print("activated\n")
end

function deActivated()
	titlePanel:setVisible(false)
	CircleModel.mesh:setVisible(false)
	
	startStrawColor.setVisible(false)
	endStrawColor.setVisible(false)
	
	if dataChanged then
		dataChanged = false
		grassListener:pushEvent("Change", grassData)
	end
	print("Deactivated\n")
end

function mouseCollision(offset)
	local selectedScene =  mapEditor:getSceneNode("editScene")
	local screenPos = Core.getInput():getMousePos() + offset
	
	if selectedScene and buildAreaPanel == Form.getPanelFromGlobalPos( screenPos ) then
		local mouseLine = camera:getWorldLineFromScreen(screenPos)
		local outNormal = Vec3()
		local collisionNode = nil
		
		if grassConfig.objectCollision then
			collisionNode = selectedScene:collisionTree( mouseLine, outNormal)
		else
			collisionNode = selectedScene:collisionTree( mouseLine, outNormal, {NodeId.islandMesh} )
		end
		
		return collisionNode, outNormal, mouseLine.endPos
	end
	
	return nil, nil, nil
end

function smothNormal(normal)
	local totalNormal = normal
	
	local offsets = {Vec2(10,10), Vec2(-10, 10), Vec2(-10, -10), Vec2(10, -10)}
	
	for i=1, #offsets do
		local node, collNormal, collPos = mouseCollision(offsets[i])
		if node then
			totalNormal = totalNormal + collNormal
		end
	end
	
	return totalNormal:normalizeV()
end

function prepareIsland(island)
	local meshes = island:findAllNodeByNameTowardsLeaf("grassMesh")
	meshList = meshes
	
	islandData = grassData[island:getIslandId()]
	
	if not islandData then
		islandData = {}
		islandData.island = island
		grassData[island:getIslandId()] = islandData
		print("Island added to grassData\n")
	end
end

function collision(island, line)

	local outNormal = Vec3()
	if grassConfig.objectCollision then
		collisionNode = island:collisionTree( line, outNormal)
	else
		collisionNode = island:collisionTree( line, outNormal, {NodeId.islandMesh} )
	end
	
	return collisionNode, line.endPos

end

function update()
	local node, collisionPos, collisionNormal = Tool.getCollision(grassConfig.objectCollision)
	--node = SceneNode.new()
	if node then
		
		local weight = 1
		local smothedNormal = smothNormal(collisionNormal)
		
		if grassConfig.useNormal then
			CircleModel.setPosition(collisionPos + smothedNormal * 0.2, smothedNormal)
		else
			CircleModel.setPosition(collisionPos, Vec3(0,1,0))
		end
		
		local aIsland = node:findNodeByType(NodeId.island)
		prepareIsland(aIsland)
	
		if aIsland and Core.getInput():getMouseHeld( MouseKey.left ) then
			dataChanged = true
			local islandInvMatrix = aIsland:getGlobalMatrix():inverseM()
			local leafToSpawn = Core.getDeltaTime() * grassConfig.strawsPerSecond
			toCompile = {}
			
			if not grassConfig.clearStraws then
			
				for i=1, leafToSpawn do
					
					local r = math.randomFloat(-math.pi,math.pi)
					local atVec = Vec3(math.cos(r),0,math.sin(r))
					--make sure that the atVec is not the same as the collisionNormal
					atVec = collisionNormal:dot(atVec) > 0.7 and Vec3(math.cos(r+math.pi*0.5),0,math.sin(r+math.pi*0.5)) or atVec
					--create the right vector
					local rightVec = collisionNormal:crossProductV(atVec)
					--cretate an at vec 90 degres to the at vec and nollision normal
					atVec = collisionNormal:crossProductV(rightVec)
					
	
					local collPos = collisionPos + (atVec * math.randomFloat(-1,1) + rightVec * math.randomFloat(-1,1)):normalizeV() * math.randomFloat(-grassConfig.radius,grassConfig.radius)
							
					local coll, position = collision(aIsland, Line3D( collPos + collisionNormal * 0.2, collPos - collisionNormal * 0.2))
					if coll then
						local bottomColor = startStrawColor.getColor() * Vec3(math.randomFloat(0.9,1.1),math.randomFloat(0.9,1.1),math.randomFloat(0.9,1.1))
						local topColor = endStrawColor.getColor() * Vec3(math.randomFloat(0.9,1.1),math.randomFloat(0.9,1.1),math.randomFloat(0.9,1.1))
						createStraw(islandInvMatrix * position, rightVec:normalizeV()*grassConfig.width, (collisionNormal+atVec*0.3):normalizeV(), Vec2(0.123,0.0),math.floor(math.randomFloat(2.01,4.99)),bottomColor,topColor)
					end
					
				end
			else
				removeStraw(islandInvMatrix * collisionPos)
			end

			for key,value in pairs(toCompile) do
				value:compile()
			end
			toCompile = {}
		elseif dataChanged and Core.getInput():getMousePressed( MouseKey.left ) then
			dataChanged = false
			grassListener:pushEvent("Change", grassData)
		end
		
	end
	
	startStrawColor.update()
	endStrawColor.update()
	
	Tool.update()
	
	return true
end

function convertToIndex(value)
	local outValue = math.round(value/5.0)
	if outValue == -0.0 then
		outValue = 0.0
	end
	return outValue
end

function removeStraw(localIslandPos)
	
	local radius = grassConfig.radius
	local removeRadius = radius
	for x = convertToIndex(localIslandPos.x-radius), convertToIndex(localIslandPos.x+radius) do
		for z = convertToIndex(localIslandPos.z-radius), convertToIndex(localIslandPos.z+radius) do
			
			local islandDataId = getMeshIdFromPos(Vec3(x*5,0,z*5))
			
			local data = islandData[islandDataId]
			local nodeMesh = nil
			if data then
				local localPosition = data.mesh:getLocalMatrix():inverseM() * localIslandPos
				for i=#data.straw, 1, -1 do
					
					local diff = (	data.mesh:getVertex(data.straw[i][1]):toVec3() - localPosition)
					if diff:length() < removeRadius then
						removeStrawFromMesh(data, i)	
						toCompile[islandDataId] = data.mesh				
					end
				end
			end
		end	
	end
end

function removeStrawFromMesh(data, strawIndex)
	local nodeMesh = data.mesh
	local index = data.straw[strawIndex][1]
	local strawSize = data.straw[strawIndex][2]
	
	--Remove straw from mesh
	nodeMesh:removeVertex(index, strawSize)
	
	print("remove straw\n")

	table.remove(data.straw, strawIndex)
	
	--decrease straw index that is above the removed straw index	
	for i=1, #data.straw do
		if data.straw[i][1] > index then
			data.straw[i][1] = data.straw[i][1] - strawSize
		end
	end
	
end

function createNodeMesh(island, localPosition)
	nodeMesh = NodeMesh.new()
		
	nodeMesh:setCollisionEnabled(false)
	nodeMesh:setLocalPosition(localPosition)
	local grassShader = Core.getShader("grassSway")
	local grassShaderShadow = Core.getShader("grassSwayShadow")
	local texture = Core.getTexture("grass.tga")

	nodeMesh:setBoundingSphere(Sphere(Vec3(), 17.0))
	nodeMesh:setShader(grassShader)
	nodeMesh:setTexture(grassShader,texture,0)
	nodeMesh:setShadowShader(grassShaderShadow)
	nodeMesh:setTexture(grassShaderShadow,texture,0)
	nodeMesh:setColor(Vec4(1))
	nodeMesh:setRenderLevel(3)
	nodeMesh:setCanBeSaved(false)
	
	
	island:addChild(nodeMesh:toSceneNode())
	return nodeMesh
end

function getMeshIdFromPos(position)
	return tostring(convertToIndex(position.x)).."x"..tostring(convertToIndex(position.z))
end

function createStraw(pos,rightVec,atVec,uvCenter,sections,colorStart,colorEnd)
	
	local localPosition = Vec3( convertToIndex(pos.x) * 5, 0, convertToIndex(pos.z) * 5)
	local islandDataId = getMeshIdFromPos(pos)
	pos = pos - localPosition
	
	local data = islandData[islandDataId]
	local nodeMesh = nil
	
	if not data then
		data = {}
		data.straw = {}

		
		
		data.mesh = createNodeMesh(islandData.island, localPosition)
		nodeMesh = data.mesh
		islandData[islandDataId] = data
	else
		nodeMesh = data.mesh
	end
	
	toCompile[islandDataId] = nodeMesh
	
	
	sections = math.max(2,math.min(3,sections))
	local sectionLength = grassConfig.length * 0.333 *(0.5+math.randomFloat())--the length of the straw [length==sectionLength*sections]
	local aVec = atVec*sectionLength			--grass direction for growth
	local gravity = atVec.y * grassConfig.bendScale * math.randomFloat(0.6,1)	--how fast it will bend
	
	local vertex = {}
	local mul = {}
	if sections==4 then
		mul = {	[0] = 1.0,
				[1] = 1.2,
				[2] = 1.0,
				[3] = 0.6 }
--		mesh:addUvCoord(uvCenter + Vec2(-0.094,0.0))
--		mesh:addUvCoord(uvCenter + Vec2(0.094,0.0))
--		mesh:addUvCoord(uvCenter + Vec2(-0.088,0.25))
--		mesh:addUvCoord(uvCenter + Vec2(0.088,0.25))
--		mesh:addUvCoord(uvCenter + Vec2(-0.077,0.50))
--		mesh:addUvCoord(uvCenter + Vec2(0.077,0.50))
--		mesh:addUvCoord(uvCenter + Vec2(-0.077,0.75))
--		mesh:addUvCoord(uvCenter + Vec2(0.077,0.75))
--		mesh:addUvCoord(uvCenter + Vec2(0.0,1.0))
	elseif sections==3 then
		mul = {	[0] = 1.4,
				[1] = 1.1,
				[2] = 0.6 }
		nodeMesh:addUvCoord(uvCenter + Vec2(-0.094,0.0))
		nodeMesh:addUvCoord(uvCenter + Vec2(0.094,0.0))
		nodeMesh:addUvCoord(uvCenter + Vec2(-0.086,0.33))
		nodeMesh:addUvCoord(uvCenter + Vec2(0.086,0.33))
		nodeMesh:addUvCoord(uvCenter + Vec2(-0.064,0.66))
		nodeMesh:addUvCoord(uvCenter + Vec2(0.064,0.66))
		nodeMesh:addUvCoord(uvCenter + Vec2(0.0,1.0))
		

		local color1 = colorStart*0.67+colorEnd*0.33
		local color2 = colorStart*0.33+colorEnd*0.67
		
		nodeMesh:addColor(colorStart)
		nodeMesh:addColor(colorStart)
		nodeMesh:addColor( color1 )
		nodeMesh:addColor( color1 )
		nodeMesh:addColor( color2 )
		nodeMesh:addColor( color2 )
		nodeMesh:addColor(colorEnd)
		
	elseif sections==2 then
		mul = {	[0] = 1.4,
				[1] = 0.8 }
		nodeMesh:addUvCoord(uvCenter + Vec2(-0.094,0.0))
		nodeMesh:addUvCoord(uvCenter + Vec2(0.094,0.0))
		nodeMesh:addUvCoord(uvCenter + Vec2(-0.077,0.50))
		nodeMesh:addUvCoord(uvCenter + Vec2(0.077,0.50))
		nodeMesh:addUvCoord(uvCenter + Vec2(0.0,1.0))
		
		
		nodeMesh:addColor(colorStart)
		nodeMesh:addColor(colorStart)
		nodeMesh:addColor( (colorStart+colorEnd)*0.5 )
		nodeMesh:addColor( (colorStart+colorEnd)*0.5 )
		nodeMesh:addColor(colorEnd)
		
	end
	for i=0, sections-1 do
		local cVec = i==0 and Vec3() or aVec
		vertex[(i*2)] = nodeMesh:getNumVertex()
		vertex[(i*2)+1] = nodeMesh:getNumVertex() + 1
		nodeMesh:addPosition( Vec4( pos + rightVec*mul[i] + cVec, i*0.25))
		nodeMesh:addPosition( Vec4( pos - rightVec*mul[i] + cVec, i*0.25))
		
		local normal = aVec:crossProductV(rightVec):normalizeV()
		if normal.y < 0 then
			normal = -normal
		end
		nodeMesh:addNormal( normal )
		nodeMesh:addNormal( normal )
		

		--addColor(mesh,i*2,pos.y+cVec.y,density)
		--addColor(mesh,i*2,pos.y+cVec.y,density)
		pos = pos + aVec
		atVec.y = atVec.y - gravity
		atVec:normalize()
		aVec = atVec*sectionLength
	end
	vertex[sections*2] = nodeMesh:getNumVertex()
	nodeMesh:addPosition( Vec4( pos + aVec, sections*0.25))
	local normal = aVec:crossProductV(rightVec):normalizeV()
	if normal.y < 0 then
		normal = -normal
	end
	nodeMesh:addNormal( normal )
	--addColor(mesh,sections*2,pos.y+aVec.y,density)
	

	table.insert(data.straw, {vertex[0], vertex[sections*2]-vertex[0] + 1})
	
	local startIndex = nodeMesh:getNumIndex()

	
	for i=0, sections-1 do
		nodeMesh:addTriangleIndex(vertex[0+(i*2)], vertex[1+(i*2)], vertex[2+(i*2)])
	end
	for i=0, sections-2 do
		nodeMesh:addTriangleIndex(vertex[1+(i*2)], vertex[3+(i*2)], vertex[2+(i*2)])
	end
	
end