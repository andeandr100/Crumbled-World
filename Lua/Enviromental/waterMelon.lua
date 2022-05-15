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
	if not deathManagerUpdate then
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
	else
		deathManagerUpdate = deathManager.update()
	end
	
	
	return true
end

function destroyWatermelon(watermelonNode)
	Core.getComUnit():sendTo("SteamStats","WatermelonsDestroyed",1)
	deathManagerUpdate = true
	--physic
	local watermelonModel=Core.getModel("watermelonCracked.mym")
	watermelonModel:setLocalMatrix(watermelonNode:getLocalMatrix())
	watermelonNode:getParent():addChild(watermelonModel:toSceneNode())
	--model:setVisible(false)
	for i=1, 24 do
		--local atVec = model:getMesh("watermelon"..i):getLocalPosition():normalizeV()
		local atVec = Vec3(math.randomFloat(-1,1),math.randomFloat(0.2,1.2),math.randomFloat(-1,1))*3.0
		local rigidBody = RigidBody.new(this:findNodeByType(NodeId.island):toSceneNode(),watermelonModel:getMesh("watermelon"..i),atVec)
		deathManager.addRigidBody(rigidBody)
	end
	watermelonNode:getParent():removeChild(watermelonNode)
end