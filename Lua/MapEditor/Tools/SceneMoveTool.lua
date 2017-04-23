require("MapEditor/Tools/Tool.lua")
require("MapEditor/Tools/SceneMoveModel.lua")
--this = SceneNode()

function create()
	
	mapEditor = Core.getBillboard("MapEditor")
	
	SceneMoveModel.create()
	
	Tool.create()
	
	direction = Vec3()
	globalStartPosition = Vec3()
	state = 0
	
	selectedNodedsGlobalPos = Vec3()
	
	return true
end

--Called when the tool has been activated
function activated()
	direction = Vec3()
	globalStartPosition = Vec3()
	SceneMoveModel.setVisible(true)
end

--Called when tool is being deactivated
function deActivated()
	direction = Vec3()
	globalStartPosition = Vec3()
	SceneMoveModel.setVisible(false)
end

function getCollisionPointAlongTargetAxis()

	local line = Line3D( selectedNodedsGlobalPos - direction * 100, selectedNodedsGlobalPos + direction * 100)
	local buildAreaPanel = mapEditor:getPanel("BuildAreaPanel")
	
	local camera = this:getRootNode():findNodeByName("MainCamera")
	local mouseLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
--	local collpos1 = Vec3()
--	local collpos2 = Vec3()

--	print("SceneMoveModel.collision\n")
	local distance, collpos1, collpos2 = Collision.lineSegmentLineSegmentLength2(line, mouseLine)
	
--	Core.addDebugLine(line.startPos, line.endPos, 100, color)
--	Core.addDebugLine(mouseLine.startPos, mouseLine.endPos, 100, Vec3(1))
--	
--	Core.addDebugSphere(Sphere(collpos1, 1.0), 100, color)
--	Core.addDebugSphere(Sphere(collpos2, 1.0), 100, Vec3(1))
	
	return collpos1
end



function update()
	
	local selectedScenes = Tool.getSelectedSceneNodes()
	
	if #selectedScenes ~= 0 and buildAreaPanel == getPanelFromGlobalPos( Core.getInput():getMousePos() ) then
		
		local globalMatrix = Tool.getSelectedNodesMatrix(selectedScenes)
		SceneMoveModel.setMatrix(globalMatrix)
		
		if Core.getInput():getMouseDown(MouseKey.left) then
			local collision, vector = SceneMoveModel.collision()
			if collision then
				selectedNodedsGlobalPos = globalMatrix:getPosition()
				direction =  ( globalMatrix * Vec4(vector,0)):toVec3():normalizeV()
				globalStartPosition = getCollisionPointAlongTargetAxis()
				state = 1
			else
				state = 0
				direction = Vec3()
			end
		end
		
		
		if Core.getInput():getMouseHeld(MouseKey.left) and state ~= 0 then
			state = 2
			local globalCollisionPos = getCollisionPointAlongTargetAxis()
			local diff = globalCollisionPos - globalStartPosition
			globalStartPosition = globalCollisionPos
			
			for i=1, #selectedScenes do
				selectedScenes[i]:setLocalPosition(selectedScenes[i]:getParent():getGlobalMatrix():inverseM() * (selectedScenes[i]:getGlobalPosition() + diff))
			end
			

			
--			selectedScenes[1]:setLocalPosition(selectedScenes[1]:getParent():getGlobalMatrix():inverseM() * (getCollisionPointAlongTargetAxis() - localOffset))

		end
	end
	
	if #selectedScenes == 0 or state == 0 then
		Tool.trySelectNewScene(false)
	end
	if Core.getInput():getMousePressed(MouseKey.left) then
		state = 0
	end
	
	Tool.tryChangeTool()
	Tool.update()	
	return true
end