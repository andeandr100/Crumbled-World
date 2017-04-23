require("MapEditor/Tools/Tool.lua")
--this = SceneNode()

function create()
	Tool.create()
	
--	ropeBridges = {}
	currentBridgePoles = {}
	bridgePoles = {}
	for i=1, 4 do
		bridgePoles[i] = Core.getModel("bridgePole.mym")
		if bridgePoles[i] then
			print("\npoles loaded\n")
		else
			print("\nNo poles was loaded\n")
		end
		this:addChild(bridgePoles[i]:toSceneNode())
		bridgePoles[i]:setVisible(false)
	end
	
	
	
	camera = this:getRootNode():findNodeByName("MainCamera")
	--camera = Camera()
	
	
	--camera:add2DScene(
	
	return true
end

function save()
	return {}
end

function load(inTable)
	
end

function activated()
	
	
--	local ropeBridgesList = this:getRootNode():findAllNodeByTypeTowardsLeaf(NodeId.ropeBridge)
--	ropeBridges = {}
--	for i=0, ropeBridgesList:size()-1 do
--		ropeBridges[i+1] = ropeBridgesList:item(i)
--	end
	
	currentBridge = {}
	
	print("activated\n")
end

function deActivated()
	
	currentBridgePoles = {}
	for i=1, #bridgePoles do
		bridgePoles[i]:setVisible(false)
	end
		
	print("Deactivated\n")
end

function update()
	
	print("\nBridge tool\n")
	
	local node, collisionPos, collisionNormal = Tool.getCollision(false)
	--node = SceneNode()
	
	
	--Check that we we can build on the current island
--	if node and #currentBridgePoles == 1 and currentBridgePoles[1][1]:toSceneNode() ~=  node:findNodeByType(NodeId.island):toSceneNode() then
--		node = nil
--	elseif node and #currentBridgePoles == 2 and currentBridgePoles[1][1]:toSceneNode() ==  node:findNodeByType(NodeId.island):toSceneNode() then
--		node = nil
--	end
	
	if not node then
		--No collision found return
		bridgePoles[#currentBridgePoles+1]:setVisible(false)
		return true	
	end
	

	local visiblePoles = #currentBridgePoles
	
	print("Visible poles "..visiblePoles.."\n")
	
	if visiblePoles == 0 or visiblePoles == 1 then
		bridgePoles[visiblePoles+1]:setVisible(true)
		bridgePoles[visiblePoles+1]:setLocalPosition(collisionPos) 			
		
		if Core.getInput():getMouseDown( MouseKey.left ) then
			local aIsland = node:findNodeByType(NodeId.island)
			if aIsland then
				currentBridgePoles[visiblePoles+1] = {aIsland, aIsland:getGlobalMatrix():inverseM() * collisionPos }
			end
		end
		
		--add Debug line
		local color = ((collisionPos - bridgePoles[1]:getGlobalPosition()):length() < 1.8) and Vec3(1,0,0) or Vec3(0,1,0)
		Core.addDebugLine(collisionPos, bridgePoles[1]:getGlobalPosition(), 0.0, color)
	elseif visiblePoles == 2 then
		local length = (bridgePoles[1]:getGlobalPosition() - bridgePoles[2]:getGlobalPosition()):length()
		local centerPosistion = (bridgePoles[1]:getGlobalPosition() + bridgePoles[2]:getGlobalPosition()) * 0.5
		local atVec = (collisionPos-centerPosistion):normalizeV()
		local rightVec = atVec:crossProductV(Vec3(0,1,0)):normalizeV()
		
		
		bridgePoles[3]:setVisible(true)
		bridgePoles[4]:setVisible(true)
		bridgePoles[3]:setLocalPosition(collisionPos+rightVec*length*0.5) 
		bridgePoles[4]:setLocalPosition(collisionPos-rightVec*length*0.5) 
		
		
		local color = (length < 1.8) and Vec3(1,0,0) or Vec3(0,1,0)

		
		--Render debug lines
		Core.addDebugLine(bridgePoles[1]:getGlobalPosition(), bridgePoles[2]:getGlobalPosition(), 0.0, color)
		Core.addDebugLine(centerPosistion, collisionPos, 0.0, color)
	
	
		if Core.getInput():getMouseDown( MouseKey.left ) then
			local aIsland = node:findNodeByType(NodeId.island)
			if aIsland then
				currentBridgePoles[3] = {aIsland, aIsland:getGlobalMatrix():inverseM() * (collisionPos+rightVec*length*0.5) }
				currentBridgePoles[4] = {aIsland, aIsland:getGlobalMatrix():inverseM() * (collisionPos-rightVec*length*0.5) }
				
				local bridge = RopeBridge()
				for i=1, 4 do
					bridge:addIslandPole(currentBridgePoles[i][1]:toSceneNode(), currentBridgePoles[i][2])
				end
				local playerNode = this:getRootNode():findNodeByType(NodeId.playerNode)
				playerNode:addChild(bridge)
				
				currentBridgePoles = {}
			end
		end
	end
	
	
	Tool.update()
	
	return true
end