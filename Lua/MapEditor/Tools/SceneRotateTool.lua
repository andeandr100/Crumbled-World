require("MapEditor/Tools/Tool.lua")
require("MapEditor/Tools/SceneRotateModel.lua")
--this = SceneNode()

function create()
	
	mapEditor = Core.getBillboard("MapEditor")
	
	SceneRotateModel.create()
	
	Tool.create()
	
	
	startCollpos = Vec3()
	startGlobalMatrix = Matrix()
	startRotationsMatrix = Matrix()
	rotationAxel = Vec3()
	rotationsVector = Vec3()
	upVec = Vec3()
	state = 0
	
	return true
end

--Called when the tool has been activated
function activated()
	direction = Vec3()
	localOffset = Vec3()
	SceneRotateModel.setVisible(true)
end

--Called when tool is being deactivated
function deActivated()
	direction = Vec3()
	localOffset = Vec3()
	SceneRotateModel.setVisible(false)
end


function update()
	
	local selectedNodes = Tool.getSelectedSceneNodes()
	
	if #selectedNodes ~= 0 and buildAreaPanel == getPanelFromGlobalPos( Core.getInput():getMousePos() ) then
		local globalMatrix = Tool.getSelectedNodesMatrix(selectedNodes)
		SceneRotateModel.setMatrix(globalMatrix)
		
		if Core.getInput():getMouseDown(MouseKey.left) then
			local collision, vector = SceneRotateModel.collision()
			if collision then
				rotationAxel = vector
				rotationsVector = (globalMatrix * Vec4(vector,0)):toVec3()
				
				local camera = this:getRootNode():findNodeByName("MainCamera")
				local mouseLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
				if Collision.lineSegmentPlaneIntersection(startCollpos, mouseLine, rotationsVector, globalMatrix:getPosition()) then
					startGlobalMatrix = globalMatrix
					startRotationsMatrix = globalMatrix
					upVec = rotationsVector:crossProductV((startCollpos-startRotationsMatrix:getPosition()):normalizeV()):normalizeV()
					state = 1
				else
					state = 0
				end		
			else
				state = 0
			end
		end
		
		if Core.getInput():getMouseHeld(MouseKey.left) and state ~= 0 then
			
			local camera = this:getRootNode():findNodeByName("MainCamera")
			local mouseLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
			local collPos = Vec3()
			if Collision.lineSegmentPlaneIntersection(collPos, mouseLine, rotationsVector, startGlobalMatrix:getPosition()) then
				state = 2
				local centerPos = startGlobalMatrix:getPosition()
				local angle = collPos:angle(startCollpos-centerPos, collPos-centerPos)
				startCollpos = collPos
				
				
				if upVec:dot((collPos-centerPos):normalizeV()) > 0 then
					angle = -angle
				end
				
				upVec = rotationsVector:crossProductV((collPos-startRotationsMatrix:getPosition()):normalizeV()):normalizeV()
				
--				Core.addDebugLine(centerPos, centerPos + (collPos-centerPos):normalizeV() * 5, 0.0, Vec3(0,1,0))
--				Core.addDebugLine(centerPos, centerPos + upVec * 5, 0.0, Vec3(1,0,0))
								
				local rotMatrix = Matrix()
				rotMatrix:setRotation( rotationAxel * angle )
				
				local groupInverseMatrix = startGlobalMatrix:inverseM()
				startRotationsMatrix = startRotationsMatrix * rotMatrix
				for i=1, #selectedNodes do
					local localMatrix = groupInverseMatrix * selectedNodes[i]:getGlobalMatrix()
					selectedNodes[i]:setLocalMatrix( selectedNodes[i]:getParent():getGlobalMatrix():inverseM() * ( startGlobalMatrix * rotMatrix * localMatrix ) )
				end
				
--				selectedScene:setLocalMatrix(startGlobalMatrix * rotMatrix)
			else
				state = 0
			end
		end
	end
	
	if #selectedNodes == 0 or state == 0 then
		Tool.trySelectNewScene(false)
	end
	
	if Core.getInput():getMousePressed(MouseKey.left) then
		state = 0
	end
	
	
	
	Tool.tryChangeTool()
	
	Tool.update()	
	return true
end