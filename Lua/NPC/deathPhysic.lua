require("Menu/settings.lua")
--this = SceneNode()
DeathPhysic = {}
function DeathPhysic.new()
	local self = {}
	
	local deadBodyDecayTime =		15
	local deadBodyStartTime =		20 + deadBodyDecayTime
	local useSubMeshMovment = false--CAn be used by Stone sperit
	
	local function getDeadBodyDecayTime()
		return deadBodyDecayTime*Settings.corpseTimer.getInt()*0.25
	end
	local function getDeadBodyStartTime()
		return deadBodyStartTime*Settings.corpseTimer.getInt()*0.25
	end
	
	function self.closestTo(startFrame,endFrame,currentFrame,targets)
		local closest = 1
		local dist = endFrame-startFrame+1.0
		for index=1, #targets, 1 do
			local currentDistUp = endFrame
			local currentDistDown = endFrame
			if currentFrame>targets[index] then
				--10>5 (we are above it) dist = (0->targets[index]) + (currentFrame->endFrame)
				currentDistUp = targets[index] + (endFrame-currentFrame)
				currentDistDown = currentFrame-targets[index]
			else
				--5>10 (we are bellow it) dist = (0->currentFrame) + (endFrame->targets[index])
				currentDistDown = currentFrame + (endFrame-targets[index])
				currentDistUp = targets[index]-currentFrame
			end
			if currentDistDown<dist or currentDistUp<dist then
				dist = math.min(currentDistDown,currentDistUp)
				closest = index
			end
		end
		return closest
	end
	
	local function collisionAginstTheWorldGlobal(globalPosition)
		local localPosition = Vec3()
		local parent = this:getParent()
		local globalMatrix = parent:getGlobalMatrix()
		local line = Line3D(globalPosition + globalMatrix:getUpVec(), globalPosition -  globalMatrix:getUpVec() )
		--Core.addDebugLine(line.startPos, line.endPos, 0.01, Vec3(1,1,0))
		local collisionNode = this:getPlayerNode():collisionTree(line, {NodeId.islandMesh, NodeId.collisionMesh})
		--Core.addDebugSphere(Sphere( line.endPos, 0.3), 0.01, Vec3(1,0,0))
		if collisionNode then
			localPosition = parent:getGlobalMatrix():inverseM() * line.endPos
		end
		return collisionNode, localPosition 
	end
	--send in a local position, and a sceneNode is returned if collision was found
	function self.collisionAginstTheWorldLocal(localPosition)
		local parent = this:getParent()
		local globalPos = parent:getGlobalMatrix() * localPosition
		return collisionAginstTheWorldGlobal(globalPos)
	end
	
	function self.rigidBodyExplosion(model, deathPos, centerOffset)
		local meshSplitter = MeshSplitter()
		local subMeshList = meshSplitter:splitMesh(model:getMesh(0))
		local physicNode = this:getPlayerNode():getPhysicNode()--findAllNodeByTypeTowardsLeaf({NodeId.PhysicNode})
		if not physicNode then
			abort("physicNode")
		end
		--local playerNode = this:getPlayerNode()
		local npcCenterPos = this:getGlobalPosition()+centerOffset
		for i=0, subMeshList:size()-1, 1 do
			local rVec = math.randomVec3()
			rVec = ((npcCenterPos-deathPos):normalizeV() + rVec * 0.5):normalizeV()
			rVec = Vec3(rVec.x*5.25,math.abs(rVec.y)*8,rVec.z*5.25)
			local rotation = Vec3(math.randomFloat() * 0.2, 0.7 + math.randomFloat() * 0.3, math.randomFloat() * 0.2):normalizeV()
			local rotationSpeed = math.randomFloat(5,15)
			
			local mesh = Mesh.new(subMeshList:item(i))
			physicNode:addRigidBody(mesh:toSceneNode(), rVec, rotation, rotationSpeed, getDeadBodyStartTime() )
		end
	end
	
	
	function self.rigidBody(model, modelVelocity)
		local physicNode = this:getPlayerNode():getPhysicNode()
		if not physicNode then
			abort("no physicNode")
		end
		local meshSplitter = MeshSplitter()
		local subMeshList = meshSplitter:splitMesh(model:getMesh(0))
		if useSubMeshMovment then
			model:getAnimation():update(0.05)
			meshSplitter:calculateSubMeshMovement(0.05)	
		end
		for i=0, subMeshList:size()-1, 1 do
			local subMesh = subMeshList:item(i)
			local rotation = Vec3(math.randomFloat() * 0.2, 0.7 + math.randomFloat() * 0.3, math.randomFloat() * 0.2):normalizeV()
			local rotationSpeed = math.randomFloat(1,7)
			local velocity = Vec3()
			if useSubMeshMovment then
				velocity = subMesh:getVelocity():normalizeV() * 3-- + mover:getCurrentVelocity()*0.5 + math.randomVec3() * 0.1 + Vec3(0,0.8,0)
			else 
				velocity = modelVelocity * 1.5 + math.randomVec3() * 0.5 + Vec3(0,0.8,0)
			end
			local mesh = Mesh.new(subMesh)
			physicNode:addRigidBody(mesh:toSceneNode(), velocity, rotation, rotationSpeed, getDeadBodyStartTime() )
		end
	end
	
	return self
end