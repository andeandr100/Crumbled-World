--this = SceneNode()

SpawnIconNpcTexture = {}

function SpawnIconNpcTexture.getTexture(scriptName)
	--scriptName = string()
	if SpawnIconNpcTexture[scriptName] then
		--This npc has allready been loaded
		return SpawnIconNpcTexture[scriptName].camera:getTexture()
	else
		SpawnIconNpcTexture[scriptName] = {}
		
		--Create a root node
		local worldNode = RootNode()
		--Many NPC script require a soulmanager
		worldNode:addChild(SoulManager())
		
		--Create camera. Set the Spawn icon as 10% of the screen resolution
		local screenSize = Core.getScreenResolution()
		local camera = Camera("SpawnIcon camera", true, screenSize.x * 0.1, screenSize.x * 0.1)
		camera:setClearColor(Vec4(0))
		worldNode:addChild(camera)
		
		
		--Load npc script onto this node
		local luaScript = worldNode:loadLuaScript(scriptName)
		luaScript:callFunction("soulSetCantDie")
		luaScript:update()
		
		--find the model
		local model = worldNode:findNodeByTypeTowardsLeafe(NodeId.model)
		
		local minPos = Vec3(-1,0,-1)
		local maxPos = Vec3(1,3,1)
		local masCenter = Vec3(0,1,0)
		if model then	
			--Model was found calculate bounding areas	
			minPos = Vec3(500)
			maxPos = Vec3(-500)
			masCenter = Vec3(0)
			local vertexCounter = 0
			for i=0, model:getNumMesh()-1 do
				local mesh = model:getMesh(i)
				local globalMat = mesh:getGlobalMatrix()
				for n=0, mesh:getNumVertex()-1 do
					local vertex = globalMat * mesh:getVertex(n)
					minPos:minimize(vertex)
					maxPos:maximize(vertex)
					masCenter = masCenter + vertex
				end
				vertexCounter = vertexCounter + mesh:getNumVertex()
			end
			--Calculate the vertex mass area. This will be used as the center point
			masCenter = masCenter / vertexCounter
		end
		
		--Set camera settings
		local directionLight = DirectionalLight(Vec3(0.5, 0.8, 0.5), Vec3(0.5))
		local ambientLight = AmbientLight(Vec3(0.5))
		camera:setDirectionLight(directionLight)
		camera:setAmbientLight(ambientLight)
		camera:setUseShadow(false)
		camera:setUseGlow(false)
		
		--Calculate the camera matrix
		local camAt = Vec3(0.3,1,1):normalizeV()
		local camMat = Matrix()
		camMat:createMatrix(camAt, Vec3(0,1,0))
		camMat:setPosition(camAt * (minPos-maxPos):length() * 1.1 +   masCenter)
		camera:setLocalMatrix(camMat)
		
		--Save the script and the camera
		SpawnIconNpcTexture[scriptName].camera = camera
		SpawnIconNpcTexture[scriptName].worldNode = worldNode
		
		--Update and render the first frame
		worldNode:update();
		camera:render();
		
		--Return the frambebuffer
		return camera:getTexture()
	end
end

function SpawnIconNpcTexture.update(scriptName)
	--scriptName = string()
	if SpawnIconNpcTexture[scriptName] then
		--update and render the npc
		SpawnIconNpcTexture[scriptName].worldNode:update()
		SpawnIconNpcTexture[scriptName].camera:render()
	end
end