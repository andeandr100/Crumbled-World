--this = SceneNode()
WorldCollision = {}
function WorldCollision.new(inCamera)
	local self = {}
	local camera = inCamera
	local oldCollisionPosition = Vec3()
	
	local function planCollision(allowSpaceCollision)
		local cameraLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos());
		local collPos = Vec3()
		if Collision.lineSegmentPlaneIntersection( collPos, cameraLine, Vec3(0,1,0), oldCollisionPosition) and ( allowSpaceCollision or (collPos-oldCollisionPosition):length() < 0.45 )  then
			return true, collPos
		end
		return false, collPos
	end

	function self.mouseWorldCollision(allowSpaceCollision)
		--get collision line from camera and mouse pos
		local cameraLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos());
		--Do collision agains playerWorld and return collided mesh
		local playerNode = this:findNodeByType(NodeId.playerNode)
		collisionMesh = playerNode:collisionTree(cameraLine, {NodeId.islandMesh,NodeId.collisionMesh});
		--Check if collision occured and check that we have an island which the mesh belongs to
		if collisionMesh and collisionMesh:findNodeByType(NodeId.island) then
			local collPos = cameraLine.endPos;
			collPos.y = collPos.y * Core.getRealDeltaTime() * 0.1 + oldCollisionPosition.y * (1.0 - Core.getRealDeltaTime() * 0.1)
			oldCollisionPosition = collPos
			return planCollision(allowSpaceCollision);
		end		
		return planCollision(allowSpaceCollision);
	end
	
	
	return self
end