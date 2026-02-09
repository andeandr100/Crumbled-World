local camera = nil

--this = SceneNode()
--camera = Camera()

function destroy()
	
end

function create()
	--find the camera
	camera = this:getRootNode():findNodeByName("MainCamera")
	
	currentSelected = false
	model = this:findNodeByName("watermelon")
	
	if model == nil then
		return false
	end
	--model = Model()
	mesh = model:getMesh(0)
	
	bSphere = mesh:getGlobalBoundingSphere()
	defaultShader = model:getMesh(0):getShader()
	SelectedShader = Core.getShader(defaultShader:getName(),"SELECTED")
	return true
end

function update()
	
	local cameraLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
	
	
	local collisionMesh = mesh:collision(cameraLine)
	if collisionMesh then
		if not currentSelected then
			mesh:setShader(SelectedShader)
			currentSelected = true
		end

		if Core.getInput():getMousePressed(MouseKey.left) then	
			destroyWatermelon(collisionMesh)
		end
	elseif currentSelected then
		currentSelected = false
		mesh:setShader(defaultShader)
	end
	
	return true
end

function destroyWatermelon(watermelonNode)
	Core.getComUnit():sendTo("SteamStats","WatermelonsDestroyed",1)
	--physic
	local watermelonModel=Core.getModel("watermelonCracked.mym")
	local island = this:findNodeByType(NodeId.island)
	
	
	
	
	watermelonModel:setLocalMatrix( island:getGlobalMatrix():inverseM() * watermelonNode:getGlobalMatrix())
	island:addChild(watermelonModel:toSceneNode())
	
	local physicNode = this:getPlayerNode():getPhysicNode()
	for i=1, 24 do
		local mesh = watermelonModel:getMesh("watermelon"..i)
		local rotation = Vec3(math.randomFloat() * 0.2, 0.7 + math.randomFloat() * 0.3, math.randomFloat() * 0.2):normalizeV()
		local rotationSpeed = math.randomFloat(1,7)
		local velocity = Vec3(math.randomFloat(-1,1),math.randomFloat(0.2,1.2),math.randomFloat(-1,1))*3.0
		physicNode:addRigidBody(mesh:toSceneNode(), velocity, rotation, rotationSpeed, 20)
	end
	watermelonNode:getParent():removeChild(watermelonNode)
end