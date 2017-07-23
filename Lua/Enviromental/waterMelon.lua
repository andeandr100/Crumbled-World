require("NPC/deathManager.lua")

--this = SceneNode()
function destroy()
	
end

function create()
	deathManagerUpdate = false
	deathManager = DeathManager.new()
	deathManager.setEnableSelfDestruct(false)
	
	--find the camera
	camera = this:getRootNode():findNodeByName("MainCamera")
	
	return true
end

function update()
	
	
	if Core.getInput():getMousePressed(MouseKey.left) and camera then	
		local cameraLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
		local collisionMesh = this:collisionTree(cameraLine)
		if collisionMesh then
			print( "collision mesh name: "..collisionMesh:getSceneName().."\n")
		end
		if collisionMesh and collisionMesh:getSceneName()=="watermelon" then
			destroyWatermelon(collisionMesh)
		end
	end
	if deathManagerUpdate then
		deathManagerUpdate = deathManager.update()
	end
	
	
	return true
end

function destroyWatermelon(watermelonNode)
	Core.getComUnit():sendTo("SteamStats","WatermelonsDestroyed",1)
	deathManagerUpdate = true
	--physic
	local model=Core.getModel("watermelonCracked.mym")
	model:setLocalMatrix(watermelonNode:getLocalMatrix())
	watermelonNode:getParent():addChild(model)
	model:setVisible(false)
	for i=1, 24 do
		--local atVec = model:getMesh("watermelon"..i):getLocalPosition():normalizeV()
		local atVec = math.randomVec3()
		atVec = Vec3(atVec.x,math.abs(atVec.y)+0.2,atVec.z)*3.0
		deathManager.addRigidBody(RigidBody(this:findNodeByType(NodeId.island),model:getMesh("watermelon"..i),atVec))
	end
	watermelonNode:getParent():removeChild(watermelonNode)
end