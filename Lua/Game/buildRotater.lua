require("Game/targetArea.lua")
--this = SceneNode()

function destroy()
	targetArea.destroyTargetMesh()
end

function worldCollision()
	--get collision line from camera and mouse pos
	local cameraLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos());
	--Do collision agains playerWorld and return collided mesh
	collisionMesh = playerNode:collisionTree(cameraLine, NodeId.islandMesh);
	--Check if collision occured and check that we have an island which the mesh belongs to
	if collisionMesh and collisionMesh:findNodeByType(NodeId.island) then
		collPos = cameraLine.endPos;
		return true;
	end		
	--Do plane intersection for space collision
	local mouseLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
	return Collision.lineSegmentPlaneIntersection(collPos,mouseLine, Vec3(0,1,0), this:getGlobalPosition())
end

function create()
	
	buildingBillboard = Core.getBillboard("buildings")
	buildingBillboard:setBool("canBuildAndSelect", false)
	
	camera = ConvertToCamera( this:getRootNode():findNodeByName("MainCamera") );
	
	comUnit = Core.getComUnit()
	script = this:getScriptByName("tower")
	towerBilboard = script:getBillboard()
	targetAreaName = towerBilboard:getString("TargetArea")
	
	if towerBilboard:exist("HasBeenSuccessfullyPlaced") then
		towerBilboard:setBool("HasBeenSuccessfullyPlaced", false)
	end
	
	buildingNodeBillboard = Core.getBillboard("buildings")
	
	playerNode = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	
	collPos = this:getGlobalPosition();
	
	--init target area mesh
	targetArea = TargetArea.new()
	return true
end

function getTowerDefaultRange()
	local towerNode = buildingNodeBillboard:getSceneNode("3Node")
	--print("\n\n\nShow Node\n")
	if towerNode then
		local buildingScript = towerNode:getScriptByName("tower")
		--get the cost of the new tower
		return buildingScript:getBillboard():getFloat("range")
	end
	return 0
end

function getTowerCost(towerId)
	local buildingNodeBillboard = Core.getBillboard("buildings")
	local towerNode = buildingNodeBillboard:getSceneNode(tostring(towerId).."Node")
	--print("\n\n\nShow Node\n")
	if towerNode then
		local buildingScript = towerNode:getScriptByName("tower")
		--get the cost of the new tower
		return buildingScript:getBillboard():getFloat("cost")
	end
	return 0
end

function update()
	--stop action
	if Core.getInput():getMouseDown(MouseKey.right) or Core.getInput():getKeyDown(Key.escape) or Core.getInput():getKeyDown(Key.lshift) then
		targetArea.destroyTargetMesh()
		buildingBillboard:setBool("canBuildAndSelect", true)
		if towerBilboard:getBool("HasBeenSuccessfullyPlaced") == false then
			
			local buildingScript = this:getScriptByName("tower")	
			local netName = buildingScript:getNetworkName()	
			
			if towerBilboard:exist("IsBuildOnAWallTower") and towerBilboard:getBool("IsBuildOnAWallTower") then
				towerBilboard:setSceneNode("TowerNode", this)
				comUnit:sendTo("SelectedMenu", "downGradeTowerBynetId", netName)
			else
				comUnit:sendTo("SelectedMenu", "sellTowerBynetId", netName)
			end
		end
		return false
	end
		
	if worldCollision() then
		local direction = collPos-this:getGlobalPosition()
		local length = direction:normalize()
		if length > 0.1 then
			
			if targetAreaName == "capsule" or targetAreaName =="cone" then
				
				local targetMatrix = Matrix()
				targetMatrix:createMatrix(direction, Vec3(0,1,0))
				
				targetMatrix:setPosition((this:getGlobalMatrix() * towerBilboard:getMatrix("TargetAreaOffset")):getPosition())
				towerBilboard:setMatrix("TargetAreaOffset", this:getGlobalMatrix():inverseM() * targetMatrix)
								
				targetMatrix:setPosition(this:getGlobalPosition())
				
				
				if targetAreaName == "capsule" then
					targetArea.setExtraRangeInfo( 0, {}, {} )
					targetArea.changeModel("capsule", towerBilboard:getFloat("range"), 0, targetMatrix)
				elseif targetAreaName == "cone" then
					local addedRange = towerBilboard:getFloat("rangePerUpgrade")
					local rangeLevel =  math.round((towerBilboard:getFloat("range")-getTowerDefaultRange()) / addedRange) + 1
					--print("\n\n\n\nShow num ranges: "..(4-rangeLevel))
					--print("RangeDist: "..addedRange)
					targetArea.setExtraRangeInfo( math.max(0,4-rangeLevel), {addedRange,addedRange,addedRange}, {Vec4(0,0,0,0.45),Vec4(0,0,0,0.45),Vec4(0,0,0,0.45)} )
					targetArea.changeModel("cone", towerBilboard:getFloat("range"), towerBilboard:getFloat("targetAngle"), targetMatrix)
				end
				
				
				--mesh:render()
			end
			
			if Core.getInput():getMouseDown(MouseKey.left) then
				comUnit:sendTo(script:getIndex(), "setRotateTarget", ""..direction.x..","..direction.y..","..direction.z)
				local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
				comUnit:sendTo("builder"..node:getClientId(), "setBuildingTargetVec", tabToStrMinimal({netName=script:getNetworkName(),para=tostring(direction.x)..","..direction.y..","..direction.z}))
				targetArea.destroyTargetMesh()
				buildingBillboard:setBool("canBuildAndSelect", true)
				towerBilboard:setBool("HasBeenSuccessfullyPlaced", true)
				return false
			else
				comUnit:sendTo(script:getIndex(), "setRotateTarget", ""..direction.x..","..direction.y..","..direction.z)
			end
		end
	end
	
	
	return true
end