require("MapEditor/Tools/Tool.lua")
require("MapEditor/Tools/SceneScaleModel.lua")
--this = SceneNode()

function create()
	
	mapEditor = Core.getBillboard("MapEditor")
	
	SceneScaleModel.create()
	
	Tool.create()
	
	direction = Vec3()
	localOffset = Vec3()
	startGlobalPosition = Vec3()
	oldScale = Vec3(1)
	state = 0
	
	return true
end

--Called when the tool has been activated
function activated()
	direction = Vec3()
	localOffset = Vec3()
	SceneScaleModel.setVisible(true)
end

--Called when tool is being deactivated
function deActivated()
	direction = Vec3()
	localOffset = Vec3()
	SceneScaleModel.setVisible(false)
end

function getCollisionPointAlongTargetAxis()

	local line = Line3D( startGlobalPosition - direction * 100, startGlobalPosition + direction * 100)
	local buildAreaPanel = mapEditor:getPanel("BuildAreaPanel")
	
	local camera = this:getRootNode():findNodeByName("MainCamera")
	local mouseLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())

--	print("ToolModel.collision\n")
	local distance, collpos1, collpos2 = Collision.lineSegmentLineSegmentLength2(line, mouseLine)
	
--	Core.addDebugLine(line.startPos, line.endPos, 100, color)
--	Core.addDebugLine(mouseLine.startPos, mouseLine.endPos, 100, Vec3(1))
--	
--	Core.addDebugSphere(Sphere(collpos1, 1.0), 100, color)
--	Core.addDebugSphere(Sphere(collpos2, 1.0), 100, Vec3(1))
	
	return collpos1
end

function update()
	
	local selectedScene = Tool.getSelectedSceneNodes()
	
	if #selectedScene ~= 0 and buildAreaPanel == getPanelFromGlobalPos( Core.getInput():getMousePos() ) then
		local globalMatrix = Tool.getSelectedNodesMatrix(selectedScene)
		SceneScaleModel.setMatrix(globalMatrix)
		
		if Core.getInput():getMouseDown(MouseKey.left) then
			startGlobalPosition = globalMatrix:getPosition()
			local collision, vector = SceneScaleModel.collision()
			if collision then
				direction =  ( globalMatrix * Vec4(vector,0)):toVec3():normalizeV()
				startCollpos = getCollisionPointAlongTargetAxis()
				startScale = globalMatrix:getScale()
				oldScale = startScale
				scaleVector = vector
				
				state = 1
			else
				state = 0
			end
		end
		
		if Core.getInput():getMouseHeld(MouseKey.left) and state ~= 0 then
			--mouse presed use default
			state = 2
			
			local collPos = getCollisionPointAlongTargetAxis()
			local dist = (collPos - startCollpos):length()
			
			local scale = 1
			
			if dist > 0.05 then
				scale = ((collPos - startCollpos):normalizeV():dot(direction) > 0) and 0.5 or -0.1
			end
			
			
			local scaleMatrix = Matrix()
			local newScale = startScale + scaleVector * (dist * scale)
			newScale:maximize(Vec3(0.01))
			scaleMatrix:setScale(Vec3(1)+(newScale-oldScale))
			oldScale = newScale
			
			local groupInverseMatrix = globalMatrix:inverseM()
			for i=1, #selectedScene do
				local localMatrix = groupInverseMatrix * selectedScene[i]:getGlobalMatrix()
				selectedScene[i]:setLocalMatrix( selectedScene[i]:getParent():getGlobalMatrix():inverseM() * ( globalMatrix * scaleMatrix * localMatrix ) )
			end
			

		else
			--
		end
	end
	
	if #selectedScene == 0 or state == 0 then
		Tool.trySelectNewScene(false)
	end
	
	if Core.getInput():getMousePressed(MouseKey.left) then
		state = 0
	end
	
	
	
	Tool.tryChangeTool()
	
	Tool.update()	
	return true
end