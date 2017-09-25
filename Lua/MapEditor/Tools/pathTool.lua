require("MapEditor/Tools/Tool.lua")
require("MapEditor/menuStyle.lua")
require("Menu/colorPicker.lua")
require("MapEditor/Tools/Models/pathModel.lua")
require("MapEditor/Tools/Models/circleModel.lua")
require("MapEditor/Tools/Models/lineModel.lua")
require("MapEditor/Tools/Models/directionalLineModel.lua")
require("MapEditor/Tools/pathGroupPanel.lua")
require("MapEditor/Tools/RailCartPathTool.lua")
--this = SceneNode()

setttings = {}
setttings.enableObjectCollision = false
setttings.enableSpaceCollision = false

state = 1

path = {}
path.spawnAreas = {}
path.pathPoints = {}
path.targetAreas = {}
path.paths = {}
path.groups = nil
path.railPaths = {}

function changeStateButton(button)
	changeState(tonumber(button:getTag():toString()))
end

function changeState(inState)	
	state = inState
	subState = 1
	
	if state ~= 1 then
		qubeModel.setVisible(false)
		qubeModelRemove.setVisible(false)
	end
	
	if state ~= 2 then
		pointModel.setVisible(false)
		pointModelRemove.setVisible(false)
	end
	
	if state ~= 3 then
		targetArea.setVisible(false)
		targetAreaRemove.setVisible(false)
	end
	
	if state ~= 5 then
		lineModel.setVisible(false)
		lineModelRemove.setVisible(false)
	end
end

function changeGroup(button)
	print("Change Group\n")
	local group = PathGroupPanel.getGroupFromId(tonumber(button:getTag():toString()))
	if group then
		print("Group Found\n")
		selectedGroupColor:setBackground(Sprite(group.color))
		groupColor = group.color
		groupId = tonumber(button:getTag():toString())
		lineModel.setColor(groupColor)
	end
end

function createMenu(panel)
	
	panel:setLayout(FallLayout())
	
	local buttonPanel = panel:add(Panel(PanelSize(Vec2(-1,1), Vec2(8,1))))
	buttonPanel:setLayout(GridLayout(1,5))
	local buttons = {}
	buttons[1] = buttonPanel:add(Button(PanelSize(Vec2(-1)), "Spawn", ButtonStyle.SIMPLE))
	buttons[2] = buttonPanel:add(Button(PanelSize(Vec2(-1)), "Point", ButtonStyle.SIMPLE))
	buttons[3] = buttonPanel:add(Button(PanelSize(Vec2(-1)), "End", ButtonStyle.SIMPLE))
	buttons[4] = buttonPanel:add(Button(PanelSize(Vec2(-1)), "Cart", ButtonStyle.SIMPLE))
	buttons[5] = buttonPanel:add(Button(PanelSize(Vec2(-1)), "Path", ButtonStyle.SIMPLE))
	
	for i=1, #buttons do
		buttons[i]:setTag(tostring(i))
		buttons[i]:addEventCallbackExecute(changeStateButton)
	end
	
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Selected group", Vec3(1)))
	
	groupColor = Vec3(0,0,0.75)
	groupId = 1
	selectedGroupColor = panel:add(Panel(PanelSize(Vec2(-1, MenuStyle.rowHeight))))
	selectedGroupColor:setBackground(Sprite(Vec3(groupColor)))
	
	PathGroupPanel.createGroupPanel(panel, nil, nil, changeGroup)
	PathGroupPanel.setGroupList({{id=1,color=groupColor}, {id=2,color=Vec3(0.75,0,0)}})
	
	path.groups = PathGroupPanel.groups
end

function createQube(sceneNode, color, position)
	local qubeModel = PathModel.new( sceneNode, color)
	qubeModel.setQubeSize( Vec3(0.5,0.75,0.5), 0.06 )
	qubeModel.setPosition(position)
	return qubeModel
end

function create()
	
	mapEditorListener = Listener("mapeditor")
	mapEditorListener:registerEvent("islandDestroyed", islandDestroyed)

	Tool.create()
	Tool.enableChangeOfSelectedScene = false
	
	pointId = 1
	subState = 1
	
	nextModel = nil
	currentModel = nil
	currentModelMatrix = Matrix()
	
	useObjectCollision = true
	
	pathListener = Listener("Path node")
	pathListener:registerEvent("Loaded", Loaded)
	
	--Get billboard for the map editor
	local mapEditor = Core.getBillboard("MapEditor")
	--Get the Tool panel
	local toolPanel = mapEditor:getPanel("ToolPanel")
	--Get the setting panel
	local settingsPanel = mapEditor:getPanel("SettingPanel")
	
	camera = this:getRootNode():findNodeByType(NodeId.camera)
		
	railCartPathTool = RailCartPathTool.new(path.railPaths)
	
	if toolPanel then
		--toolPanel
	end
	if settingsPanel then
		titlePanel, bodyPanel =  MenuStyle.createTitleAndBody(settingsPanel, "Path tool")
		
		--body = Panel()
		titlePanel:setVisible(false)
		createMenu(bodyPanel)
	end
	
--############# State 1 #############
	
	qubeModel = createQube(this:getRootNode(), Vec3(0,1,0), Vec3())
	qubeModel.setVisible(false)
	
	qubeModelRemove = PathModel.new( this:getRootNode(), Vec3(1,0,0))
	qubeModelRemove.setQubeSize( Vec3(0.5,0.75,0.5), 0.08 )
	qubeModelRemove.setVisible(false)
	
--############# State 2 #############
	
	pointModel = CircleModel.new( this:getRootNode(), 1, 0.05, Vec3(0.8) )
	pointModel.setVisible(false)
	
	pointModelRemove = CircleModel.new( this:getRootNode(), 1, 0.06, Vec3(1,0,0) )
	pointModelRemove.setVisible(false)
	
--############# State 3 #############
	
	targetArea = createQube(this:getRootNode(), Vec3(1,0.5,0), Vec3(1,0.5,0))
	targetArea.setVisible(false)
	
	targetAreaRemove = PathModel.new( this:getRootNode(), Vec3(1,0,0))
	targetAreaRemove.setQubeSize( Vec3(0.5,0.75,0.5), 0.08 )
	targetAreaRemove.setVisible(false)
	
--############# State 4 #############
	
	lineModel = DirectionalLineModel.new(this:getRootNode(), groupColor,0.075)
	lineModel.setVisible(false)
	
	lineModelRemove = DirectionalLineModel.new(this:getRootNode(), Vec3(1,0,0), 0.1)
	lineModelRemove.setVisible(false)
	
	editorListener = Listener("Editor")
	editorListener:registerEvent("newMap", newMap)
	editorListener:registerEvent("loadedMap", loadedMap)
	return true
end

function newMap()
	
	print("########################################################################################################\n")
	
	print("\n\nPath tool New World\n\n\n")
	state = 1
	pointId = 1

	
	path = {}
	path.spawnAreas = {}
	path.pathPoints = {}
	path.targetAreas = {}
	path.paths = {}
	path.railPaths = {}
	
	
	
	railCartPathTool.newMap(path.railPaths)
	
	PathGroupPanel.setGroupList({{id=1,color=groupColor}, {id=2,color=Vec3(0.75,0,0)}})
end

function loadedMap()
	local playerNode = this:getRootNode():findNodeByType(NodeId.playerNode) 
	local pathNodes = playerNode:findAllNodeByNameTowardsLeaf("Path node")
	if #pathNodes == 0 then
		local pathNode = playerNode:addChild(SceneNode("Path node"))
		local script = pathNode:loadLuaScript("MapEditor/pathNode.lua")
		script:update()
	elseif #pathNodes > 1 then
		for i=2, #pathNodes do
			pathNodes[i]:destroy()
			error("double path node")
		end
	end
	
	railCartPathTool.loadedMap()
end

function getIslandFromId(islandList, islandId)
	for i=1, #islandList do
		if islandList[i]:getIslandId() == islandId then
			return islandList[i]
		end
	end
	return nil
end

function Loaded(inTable)
	
	print("Loaded"..tostring(inTable).."\n")
	
	pointId = 1
	path = inTable
	
	local islandList = this:getRootNode():findAllNodeByTypeTowardsLeaf(NodeId.island)
	
	local data = {path.spawnAreas, path.pathPoints, path.targetAreas}
	
	for i=1, #data  do
		local pathData = data[i]
		for n=1, #pathData do
			local island = getIslandFromId(islandList, pathData[n].islandId)
			if not island then
				--somthinge is realy wrong reset data and stop function
				print("WARNING: island was not found.\nPath tool data is reseted\n")
				newMap()
				return
			end
			pathData[n].island = island
			if i == 1 then
				pathData[n].mesh = createQube(island, Vec3(0,1,0), pathData[n].position)
			elseif i == 2 then
				pathData[n].mesh = CircleModel.new( island, 1, 0.05, Vec3(0.8) )
				pathData[n].mesh.setPosition(pathData[n].position)
			else
				pathData[n].mesh = createQube(island, Vec3(1,0.5,0), pathData[n].position)
			end
		end
	end
	
	path.targetAreas = path.targetAreas or {}
	path.pathPoints = path.pathPoints or {}
	path.spawnAreas = path.spawnAreas or {}
	path.paths = path.paths or {}
	
	for i=1, #path.paths do
		local aPath = path.paths[i]
		aPath[1].island = getIslandFromId(islandList, aPath[1].islandId)
		aPath[2].island = getIslandFromId(islandList, aPath[2].islandId)
		
		local offset = Vec3(0,0.2 * aPath.groupId,0)
		aPath.mesh = DirectionalLineModel.new(aPath[1].island, aPath.groupColor, 0.075)
		aPath.mesh.setlinePath(aPath[1].position + offset, aPath[1].island:getGlobalMatrix():inverseM() *(aPath[2].island:getGlobalMatrix() * aPath[2].position + offset))
	end
	
	path.groups = path.groups or {{id=1,color=groupColor}, {id=2,color=Vec3(0.75,0,0)}}
	
	PathGroupPanel.setGroupList(path.groups)
		
	
	if not path.railPaths then
		path.railPaths = {}
	end
	railCartPathTool.loaded(path.railPaths)
		
	deActivated()
end

function updatePathLines()
	for i=1, #path.paths do
		local pathLine = path.paths[i]
		local offset = Vec3(0,0.2 * path.paths[i].groupId,0)
		pathLine.mesh.setlinePath(pathLine[1].position + offset, pathLine[1].island:getGlobalMatrix():inverseM() *(pathLine[2].island:getGlobalMatrix() * pathLine[2].position + offset))
	end
end

--Called when the tool has been activated
function activated()
	titlePanel:setVisible(true)
	changeState(1)
	print("activated\n")
	subState = 1

	railCartPathTool.activated()

	updatePathLines()
	--currentFrae = Core.get
end

--Called when tool is being deactivated
function deActivated()
	titlePanel:setVisible(false)
	
	railCartPathTool.deActivated()
	
	changeState(0)
	print("Deactivated\n")
end

function collisionAgainstSpawn()
	local globalLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
	local spawnArea = nil
	local index = nil
	local minDistance = math.huge
	
	for i=1, #path.spawnAreas do
		local collision, position = path.spawnAreas[i].mesh.collision(globalLine)
		if collision then
			if collision and minDistance > (position - globalLine.startPos):length() then
				minDistance = (position - globalLine.startPos):length()
				spawnArea = path.spawnAreas[i]
				index = i
			end
		end
	end
	return spawnArea, index, minDistance
end

function collisionAgainstTargetArea()
	local globalLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
	local spawnArea = nil
	local index = nil
	local minDistance = math.huge
	
	for i=1, #path.targetAreas do
		local collision, position = path.targetAreas[i].mesh.collision(globalLine)
		if collision then
			if collision and minDistance > (position - globalLine.startPos):length() then
				minDistance = (position - globalLine.startPos):length()
				spawnArea = path.targetAreas[i]
				index = i
			end
		end
	end
	return spawnArea, index, minDistance
end

function collisionAgainsPoints()
	local spawnArea = nil
	local index = nil
	local minDistance = math.huge
	local globalLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
	for i=1, #path.pathPoints do
		local collision, position = path.pathPoints[i].mesh.collision(globalLine)
		if collision then
			minDistance = (position - globalLine.startPos):length()
			spawnArea = path.pathPoints[i]
			index = i
		end
	end
	return spawnArea, index, minDistance
end

function collisionAginstPathLines()
	local spawnArea = nil
	local index = nil
	local minDistance = math.huge
	local globalLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
	for i=1, #path.paths do
		local collision, position = path.paths[i].mesh.collision(globalLine)
		if collision then
			minDistance = (position - globalLine.startPos):length()
			spawnArea = path.paths[i]
			index = i
		end
	end
	return spawnArea, index, minDistance	
end

function getId()
	local id = pointId
	pointId = pointId + 1
	
	--check if the id is allready in use
	local points = {path.spawnAreas, path.pathPoints, path.targetAreas}
	for i=1, #points do
		for n=1, #points[i] do
			if points[i][n] == id then
				--id in use try next id
				return getId()
			end
		end
	end
	
	return id
end

function getPathPoint()

	local pathPoint = nil
	local minDist = math.huge
	
	local functions = {collisionAgainstSpawn, collisionAgainstTargetArea, collisionAgainsPoints, railCartPathTool.collisionAginstMinecartLines}
	
	for i=1, #functions do
		local spawnArea, index, distance = functions[i]()
		if minDist > distance then
			pathPoint = spawnArea
			minDist = distance
		end
	end
	return pathPoint
end

function collisionAgainsPath()
	local pathPoint = getPathPoint()

	if pathPoint then
		return pathPoint.id, pathPoint.position, pathPoint.island
	end
	
	return nil, nil, nil
end

function islandDestroyed(inIslandId)
	local islandId = tonumber(inIslandId)
	
	for i=#path.paths, 1, -1 do
		if path.paths[i][1].islandId == islandId or path.paths[i][2].islandId == islandId then
			path.paths[i].mesh.destroy()
			table.remove( path.paths, i)
		end
	end
	
	
	local data = {path.spawnAreas, path.pathPoints, path.targetAreas}
	
	for i=1, #data  do
		local pathData = data[i]
		for n=1, #pathData do
			if pathData[n].islandId == islandId then
				if pathData.mesh then
					pathData.mesh.destroy()
				end
				table.remove( pathData, n)
			end
		end
	end
	
end

--As long as the tool is active update is caled
function update()

	--Do collision check
	local node, collisionPos, collisionNormal = Tool.getCollision(setttings.enableObjectCollision, setttings.enableSpaceCollision)
	local save = false
	if node then
		local island = node:findNodeByTypeTowardsRoot(NodeId.island)
		if state == 1 or state == 2 or state == 3 then
			local createModel, removeModel, collisionFunction, pathTable
			if state == 1 then
				createModel = qubeModel
				removeModel = qubeModelRemove
				collisionFunction = collisionAgainstSpawn
				pathTable = path.spawnAreas
			elseif state == 2 then
				createModel = pointModel
				removeModel = pointModelRemove
				collisionFunction = collisionAgainsPoints
				pathTable = path.pathPoints
			else
				createModel = targetArea
				removeModel = targetAreaRemove
				collisionFunction = collisionAgainstTargetArea
				pathTable = path.targetAreas
			end
			
			local spawnPath, spawnIndex = collisionFunction()
			if spawnPath then
				createModel.setVisible(false)
				removeModel.setVisible(true)
				removeModel.setPosition( spawnPath.island:getGlobalMatrix() * spawnPath.position )
				
				if Core.getInput():getMouseDown(MouseKey.left) then
					--remove model from island
					spawnPath.mesh.destroy()
					--remove information from table
					table.remove(pathTable, spawnIndex)
					save = true
				end
			else
				removeModel.setVisible(false)
				createModel.setVisible(true)
				createModel.setPosition( collisionPos )
			
				if Core.getInput():getMouseDown(MouseKey.left) then
					local newpath = {}
					local localPosition = island:getGlobalMatrix():inverseM() * collisionPos
					if state == 1 then
						newpath.mesh = createQube(island, Vec3(0,1,0), localPosition)
					elseif state == 2 then
						newpath.mesh = CircleModel.new( island, 1, 0.05, Vec3(0.8) )
						newpath.mesh.setPosition(localPosition)
					else
						newpath.mesh = createQube(island, Vec3(1,0.5,0), localPosition)
					end
					newpath.island = island
					newpath.islandId = island:getIslandId()
					newpath.position = localPosition
					newpath.id = getId()
					pathTable[#pathTable+1] = newpath
					save = true
				end
			end
		elseif state == 4 then
			if railCartPathTool.update() then
				save = true
			end
		elseif state == 5 then
			
			local spawnPath, spawnIndex = collisionAginstPathLines()
			local id, position, island = collisionAgainsPath()
			if subState == 1 and not id and not island and spawnPath then
				lineModel.setVisible(false)
				
				if Core.getInput():getMouseDown(MouseKey.left) then
					--remove model from island
					spawnPath.mesh.destroy()
					--remove information from table
					
					
					table.remove(path.paths, spawnIndex)
					subState = 0
					lineModelRemove.setVisible(false)
					save = true
				else
					local offset = Vec3(0,0.2 * path.paths[spawnIndex].groupId,0)
					lineModelRemove.setVisible(true)
					lineModelRemove.setlinePath(spawnPath[1].island:getGlobalMatrix() * spawnPath[1].position + offset, spawnPath[2].island:getGlobalMatrix() * spawnPath[2].position + offset)
				end
			elseif subState == 1 then
				lineModelRemove.setVisible(false)
			end
					
			if subState == 1 and Core.getInput():getMouseDown(MouseKey.left) then
				if id and position and island then
					startId = id
					startPosition = position
					startIsland = island
					subState = 2
				end
			elseif subState == 2 and ( Core.getInput():getMouseHeld(MouseKey.left) or Core.getInput():getMousePressed(MouseKey.left) ) then
				local id, position, island = collisionAgainsPath()
				if id and position and island then
					
					local offset = Vec3(0,0.2 * groupId,0)
					lineModel.setlinePath(startIsland:getGlobalMatrix() * startPosition + offset, island:getGlobalMatrix() * position + offset)
					lineModel.setVisible(true)
					lineModelRemove.setVisible(false)
					
					if Core.getInput():getMousePressed(MouseKey.left) and startId ~= id then
						lineModel.setVisible(false)
						subState = 1
						--add line
						local tmpPath = {}
						tmpPath[1] = {id = startId, island = startIsland, islandId = startIsland:getIslandId(), position = startPosition}
						tmpPath[2] = {id = id, island = island, islandId = island:getIslandId(), position = position}
						tmpPath.groupColor = groupColor
						tmpPath.groupId = groupId
						tmpPath.mesh = DirectionalLineModel.new(startIsland, groupColor, 0.075)
						tmpPath.mesh.setlinePath(startPosition + offset, startIsland:getGlobalMatrix():inverseM() *(island:getGlobalMatrix() * position + offset))
						path.paths[#path.paths+1] = tmpPath
						save = true
					end
				elseif startIsland and startPosition then
					if Core.getInput():getMousePressed(MouseKey.left) then
						lineModel.setVisible(false)
						lineModelRemove.setVisible(false)
						subState = 1
					else
						lineModel.setVisible(false)
						local offset = Vec3(0,0.2 * groupId,0)
						lineModelRemove.setlinePath(startIsland:getGlobalMatrix() * startPosition + offset, collisionPos + offset)
						lineModelRemove.setVisible(true)
					end
					
				end
			elseif subState == 1 then

				local pathPoint = getPathPoint()
				
				if pathPoint then
					local pathPosition = pathPoint.island:getGlobalMatrix() * pathPoint.position + Vec3(0,1,0)
					lineModel.setlinePath( pathPosition, pathPosition + Vec3(0.1,0,0))
					lineModel.setVisible(true)
				else
					lineModel.setVisible(false)
				end
				
			end
			if subState == 0 then
				subState = 1
			end
		end
	else
		qubeModel.setVisible(false)
	end
	
	if save then
		print("Push path tool event\n")
		pathListener:pushEvent("Change", path)
	end
	
	PathGroupPanel.update()
	
	--Update basic tool
	Tool.update()
		
	return true
end