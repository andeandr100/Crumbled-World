require("MapEditor/Tools/Tool.lua")
require("MapEditor/Tools/ModelPlaceToolMenu.lua")
--this = SceneNode()

local firstUpdateOfSelectedModel = false
setttings = {}

function setModel(panel)
	toolManager = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.toolManager)
	if toolManager then
		toolManager:setToolScript("MapEditor/Tools/ModelPlaceTool.lua")
		print("Model: "..panel:getTag():toString().."\n")
		nextModel = panel:getTag():toString()
		firstUpdateOfSelectedModel = true
	end
end

function updateSettings()
	selectedConfig = modelPlaceToolMenu.getSelectedConfig()
	setttings.enableObjectCollision = selectedConfig:get("objectCollision", true):getBool()
	setttings.enableSpaceCollision = selectedConfig:get("spaceCollision", true):getBool()
	setttings.enableUseObjectNormal = selectedConfig:get("useNormal", true):getBool()
	
	setttings.minRed = selectedConfig:get("minColorRed", 255):getInt()
	setttings.maxRed = selectedConfig:get("maxColorRed", 255):getInt()
	setttings.minGreen = selectedConfig:get("minColorGreen", 255):getInt()
	setttings.maxGreen = selectedConfig:get("maxColorGreen", 255):getInt()
	setttings.minBlue = selectedConfig:get("minColorBlue", 255):getInt()
	setttings.maxBlue = selectedConfig:get("maxColorBlue", 255):getInt()
	
	setttings.minRotationX = selectedConfig:get("minRotationAroundX", 0):getInt()
	setttings.maxRotationX = selectedConfig:get("maxRotationAroundX", 0):getInt()
	setttings.minRotationY = selectedConfig:get("minRotationAroundY", 0):getInt()
	setttings.maxRotationY = selectedConfig:get("maxRotationAroundY", 0):getInt()
	setttings.minRotationZ = selectedConfig:get("minRotationAroundZ", 0):getInt()
	setttings.maxRotationZ = selectedConfig:get("maxRotationAroundZ", 0):getInt()
	
	setttings.minScale = selectedConfig:get("minScale", 1.0):getDouble()
	setttings.maxScale = selectedConfig:get("maxScale", 1.0):getDouble()
	
	local numDefaultScript = selectedConfig:get("numDefaultScript", 0):getInt()
	setttings.defaultScripts = {}
	for i=1, numDefaultScript do
		setttings.defaultScripts[i] = selectedConfig:get("defaultScript"..tostring(i), ""):getString()
	end
	
	updateModelState()
end

function updateModelState()
	if currentModel then
		currentModel:setColor( Vec3( math.randomFloat(setttings.minRed, setttings.maxRed)/255, math.randomFloat(setttings.minGreen, setttings.maxGreen)/255, math.randomFloat(setttings.minBlue, setttings.maxBlue)/255 ) )
		--currentModelMatrix = currentModel:getLocalMatrix()
		if setttings.minRotationX ~= 0 or setttings.maxRotationX ~= 0 or setttings.minRotationY ~= 0 or setttings.maxRotationY ~= 0 or setttings.minRotationZ ~= 0 or setttings.maxRotationZ ~= 0 then
			local rotX = math.degToRad( math.randomFloat(setttings.minRotationX, setttings.maxRotationX) )
			local rotY = math.degToRad( math.randomFloat(setttings.minRotationY, setttings.maxRotationY) )
			local rotZ = math.degToRad( math.randomFloat(setttings.minRotationZ, setttings.maxRotationZ) )
			local cVec = currentModelMatrix:getRotation()
			--change only rotations that is set between 2 values
			if setttings.minRotationX ~= 0 or setttings.maxRotationX ~= 0 then
				cVec.x = rotX
			end
			if setttings.minRotationY ~= 0 or setttings.maxRotationY ~= 0 then
				cVec.y = rotY
			end
			if setttings.minRotationZ ~= 0 or setttings.maxRotationZ ~= 0 then
				cVec.z = rotZ
			end
			currentModelMatrix:setRotation(cVec)
		end
		--scale will be randomized every time
		currentModelMatrix:setScale(Vec3(math.randomFloat(setttings.minScale, setttings.maxScale)))
		currentModel:setLocalMatrix(currentModelMatrix)
		
		
	end
end

function create()
	Tool.create()
	Tool.enableChangeOfSelectedScene = false
	
	nextModel = nil
	currentModel = nil
	currentModelMatrix = Matrix()
	
	useObjectCollision = true
	
	--Get billboard for the map editor
	local mapEditor = Core.getBillboard("MapEditor")
	--Get the Tool panel
	local toolPanel = mapEditor:getPanel("ToolPanel")
	--Get the setting panel
	local settingPanel = mapEditor:getPanel("SettingPanel")
	
	--Load config
	rootConfig = Config("ToolsSettings")
	--Get the ligt tool config settings
	modelInfoConfig = rootConfig:get("ModelInfo")
	
	
	modelPlaceToolMenu = ModelPlaceToolMenu.new(toolPanel, setModel, settingPanel, updateSettings)
	
	
	return true
end

function changeModel()
	if nextModel then
		currentModel = Core.getModel(nextModel)
		--currentModel = Model()
		if currentModel then
			if this:getRootNode() then
				this:getRootNode():addChild(currentModel:toSceneNode())
			else
				currentModel = nil
			end
		end
		--Update settings panel, update model rotation and scale
		modelPlaceToolMenu.setToolSettingsForModel(nextModel)
		nextModel = nil
	end
end

--Called when the tool has been activated
function activated()
	changeModel()
	currentModelMatrix = Matrix()
	toolModelSettingsPanel:setVisible(true)
	Tool.clearSelectedNodes()
	print("activated\n")
	
	--currentFrae = Core.get
end

--Called when tool is being deactivated
function deActivated()
	if currentModel then
		if currentModel:getParent() then
			currentModel:getParent():removeChild(currentModel:toSceneNode())
		end
		currentModel = nil
	end
	toolModelSettingsPanel:setVisible(false)
	print("Deactivated\n")
end

--As long as the tool is active update is caled
function update()
	--Check if new model has been requested
	if nextModel then
		changeModel()
	end
	
	--Check if there is a selected model
	if not currentModel then
		return true
	end
	
	
	
	--Do collision check
	local node, collisionPos, collisionNormal = Tool.getCollision(setttings.enableObjectCollision, setttings.enableSpaceCollision)
	if node then
		if firstUpdateOfSelectedModel then
			firstUpdateOfSelectedModel = false
			updateModelState()
		end	
		local ticks = Core.getInput():getMouseWheelTicks()
		--linux only ticks=={-50,0,50}
		local rotation = 0
		if ticks~=0 then
			rotation = (ticks>0) and -math.pi/36 or math.pi/36
		end
		
		
		--Rotate around local parent y axist
		local rotMat = Matrix()
		rotMat:setRotation(Vec3(0,rotation,0))
		currentModelMatrix = rotMat * currentModelMatrix
		
		if setttings.enableUseObjectNormal then
			local normalMat = Matrix()
			local normal = collisionNormal
			if normal:length() < 0.01 then
				normal = Vec3(0,1,0)
			end
			if math.abs(normal:normalizeV():dot(currentModelMatrix:getRightVec())) > 0.9 then
				normalMat:createMatrixUp(normal, currentModelMatrix:getAtVec())
			else
				normalMat:createMatrixUp(normal, currentModelMatrix:getRightVec())
			end
			local localMatrix = normalMat * currentModelMatrix
			localMatrix:setPosition(collisionPos)
			currentModel:setLocalMatrix(localMatrix )
		else
			local localMatrix = currentModelMatrix
			localMatrix:setPosition(collisionPos)
			currentModel:setLocalMatrix(localMatrix )
		end
		--Collision was found show the model
		currentModel:setVisible(true)
		--Set the local position to the global position
		--currentModel:setLocalPosition(collisionPos)	
		
		if collisionPos:length() < 0.1 then
			print("No position")
		end
		
		if Core.getInput():getMouseDown(MouseKey.left) then
			--Create a copy of the model
			local model = Model(currentModel)
			--Set script
			for i=1, #setttings.defaultScripts do
				model:loadLuaScript(setttings.defaultScripts[i])
			end
			--Convert from global space to local space
			model:setLocalMatrix( node:getGlobalMatrix():inverseM() * currentModel:getGlobalMatrix() )
			--Add model to collision sceneNode
			node:addChild( model:toSceneNode() )
			--update model, color, rotation and scale
			updateModelState()
		end
		--print("Colision\n")
	else
		--No collision was found, hidde the model
		currentModel:setVisible(false)
	end
	
	--Update basic tool
	Tool.update()
	
	return true
end