--this = SceneNode()

local tutorial = nil
local mesh = Node2DMesh()
local textNode = TextNode()
local xButtonMesh = Node2DMesh()
local arrowMesh = Node2DMesh()
local tutorialCounter = TextNode()
local black = Vec4(0,0,0,0.6)
local renderSize = Core.getRenderResolution()
local buttonPosition = Vec2()
local buttonRadius = 0
local buttonState = 1
local tutorialBillboard = Core.getGameSessionBillboard("tutorial")
local comUnit = Core.getComUnit()



--  P1  -  p2
--  |		|
--  |		|
--  p3  -  p3  
local function addQuad(node2DMesh, p1, p2, p3, p4, color)
	node2DMesh:addVertex(Vec2(renderSize.x * p1.x, renderSize.y * p1.y), color )
	node2DMesh:addVertex(Vec2(renderSize.x * p2.x, renderSize.y * p2.y), color )
	node2DMesh:addVertex(Vec2(renderSize.x * p3.x, renderSize.y * p3.y), color )
	
	node2DMesh:addVertex(Vec2(renderSize.x * p2.x, renderSize.y * p2.y), color )
	node2DMesh:addVertex(Vec2(renderSize.x * p3.x, renderSize.y * p3.y), color )
	node2DMesh:addVertex(Vec2(renderSize.x * p4.x, renderSize.y * p4.y), color )
end

local function addTriangle(node2DMesh, p1, p2, p3, color)
	node2DMesh:addVertex(Vec2(renderSize.x * p1.x, renderSize.y * p1.y), color )
	node2DMesh:addVertex(Vec2(renderSize.x * p2.x, renderSize.y * p2.y), color )
	node2DMesh:addVertex(Vec2(renderSize.x * p3.x, renderSize.y * p3.y), color )
end


local function createArrow( node2DMesh, p1, p2, a1, a2, lineWidth, arrowWidth)
	--p1 = Vec2()
	--p2 = Vec2()
	--a1 = float()
	--a2 = float()
	--lineWidth = float()
	
	p1 = p1 * renderSize
	p2 = p2 * renderSize
	a1 = a1 * renderSize.y
	a2 = a2 * renderSize.y
	lineWidth = lineWidth * renderSize.y
	arrowWidth = arrowWidth * renderSize.y
		
	node2DMesh:clearMesh()
	
	local color = Vec4(1, 0, 0, 1)
	local atVec = (p2-p1):normalizeV()
	local rightVec = Vec3(atVec, 0):crossProductV(Vec3(0,0,1)):normalizeV():toVec2()

	local p3 = (p2 - atVec * a2 - rightVec * arrowWidth ) / renderSize
	local p4 = (p2 - atVec * a1 - rightVec * lineWidth ) / renderSize
	local p5 = (p2 - atVec * a1 + rightVec * lineWidth ) / renderSize
	local p6 = (p2 - atVec * a2 + rightVec * arrowWidth ) / renderSize
	local p7 = (p1 - rightVec * lineWidth ) / renderSize
	local p8 = (p1 + rightVec * lineWidth ) / renderSize
	p2 = p2 / renderSize
	
	addQuad( node2DMesh, p4, p5, p7, p8, color )
				
	addTriangle( node2DMesh, p3, p2, p4, color )
	addTriangle( node2DMesh, p4, p2, p5, color )
	addTriangle( node2DMesh, p5, p2, p6, color )		 
	
	node2DMesh:compile()
	
end

local function xButtonCreate( node2DMesh, height, centerPos, color )
	
	buttonRadius = renderSize.y * height
	buttonPosition = centerPos
	node2DMesh:clearMesh()
	local cos = math.cos
	local sin = math.sin
	local radOffset = math.pi / 16.0
	local lineWidth = renderSize.y * 0.075 * height
	local rad2 = renderSize.y * height
	local rad1 = rad2 - renderSize.y * 0.1 * height
	local rad0 = rad1 - (rad2-rad1) * 2
	local r = 0.0
	while r < ( math.pi * 2.0 - radOffset * 0.5 ) do
		local p1 = centerPos + Vec2(cos(r), sin(r)) * rad2
		local p2 = centerPos + Vec2(cos(r), sin(r)) * rad1
		local p3 = centerPos + Vec2(cos(r+radOffset), sin(r+radOffset)) * rad2
		local p4 = centerPos + Vec2(cos(r+radOffset), sin(r+radOffset)) * rad1
		
		node2DMesh:addVertex(p1, color )
		node2DMesh:addVertex(p2, color )
		node2DMesh:addVertex(p3, color )
		
		node2DMesh:addVertex(p2, color )
		node2DMesh:addVertex(p3, color )
		node2DMesh:addVertex(p4, color )
		
		r = r + radOffset
	end
	
	
	--add the x
	
	
	local atVec = Vec2(cos(math.pi * 0.25), sin(math.pi * 0.25))
	local rightVec = Vec2(cos(math.pi * 0.75), sin(math.pi * 0.75))
	
	local p1 = centerPos + atVec * rad0 + rightVec * lineWidth
	local p2 = centerPos + atVec * rad0 - rightVec * lineWidth
	local p3 = centerPos - atVec * rad0 + rightVec * lineWidth
	local p4 = centerPos - atVec * rad0 - rightVec * lineWidth
	
	node2DMesh:addVertex(p1, color )
	node2DMesh:addVertex(p2, color )
	node2DMesh:addVertex(p3, color )
	
	node2DMesh:addVertex(p2, color )
	node2DMesh:addVertex(p3, color )
	node2DMesh:addVertex(p4, color )
	
	
	
	local p1 = centerPos + rightVec * rad0 + atVec * lineWidth
	local p2 = centerPos + rightVec * rad0 - atVec * lineWidth
	local p3 = centerPos - rightVec * rad0 + atVec * lineWidth
	local p4 = centerPos - rightVec * rad0 - atVec * lineWidth
	
	node2DMesh:addVertex(p1, color )
	node2DMesh:addVertex(p2, color )
	node2DMesh:addVertex(p3, color )
	
	node2DMesh:addVertex(p2, color )
	node2DMesh:addVertex(p3, color )
	node2DMesh:addVertex(p4, color )
		
		
	

	node2DMesh:compile()
end

local function selectArea(renderData)
	
	local min = renderData.min
	local max = renderData.max
	
	if renderData.panelMin then
		local minPanel = tutorialBillboard:getPanel(renderData.panelMin)
		local maxPanel = tutorialBillboard:getPanel(renderData.panelMax)
		min = Vec2()
		max = Vec2()
		minPanel:getPanelGlobalMinMaxPosition(min, max)
		local tmpMin = Vec2()
		local tmpMax = Vec2() 
		maxPanel:getPanelGlobalMinMaxPosition(tmpMin, tmpMax)
		min:minimize(tmpMin)
		min:minimize(tmpMax)
		max:maximize(tmpMin)
		max:maximize(tmpMax)
		
		min = (min - Vec2(renderSize.y * 0.006)) / renderSize
		max = (max + Vec2(renderSize.y * 0.006)) / renderSize
		renderData.min = Vec2(min)
		renderData.max = Vec2(max)
	elseif renderData.panel then
		min = Vec2()
		max = Vec2()
		local panel = tutorialBillboard:getPanel(renderData.panel)
		panel:getPanelGlobalMinMaxPosition(min, max)
		
		min = (min - Vec2(renderSize.y * 0.006)) / renderSize
		max = (max + Vec2(renderSize.y * 0.006)) / renderSize
		renderData.min = Vec2(min)
		renderData.max = Vec2(max)
	end
	
	--		  TOP
	----------------------------
	--		 |		|
	--  LEFT |		| RIGHT
	--		 |		|
	----------------------------
	--		 BOTTOM
	
	--top quad
	addQuad( mesh, Vec2(0,0), Vec2(1, 0), Vec2(0, min.y), Vec2(1, min.y), black)
	--left quad
	addQuad( mesh, Vec2(0,min.y), Vec2(min.x, min.y), Vec2(0, max.y), Vec2(min.x, max.y), black)
	--right quad
	addQuad( mesh, Vec2(max.x,min.y), Vec2(1, min.y), Vec2(max.x, max.y), Vec2(1, max.y), black)
	--bottom quad
	addQuad( mesh, Vec2(0, max.y), Vec2(1, max.y), Vec2(0, 1), Vec2(1), black)
	
	
	local borderSize = Vec2((renderSize.y * 0.00138) / renderSize.x,0.00138)
	local borderColor = Vec4(Vec3(0.9),1)
	--top quad
	addQuad( mesh, Vec2(min.x,min.y), Vec2(max.x, min.y), Vec2(min.x, min.y+borderSize.y), Vec2(max.x, min.y+borderSize.y), borderColor)
	--left quad
	addQuad( mesh, Vec2(min.x,min.y), Vec2(min.x+borderSize.x, min.y), Vec2(min.x, max.y), Vec2(min.x+borderSize.x, max.y), borderColor)
	--right quad
	addQuad( mesh, Vec2(max.x-borderSize.x,min.y), Vec2(max.x, min.y), Vec2(max.x-borderSize.x, max.y), Vec2(max.x, max.y), borderColor)
	--bottom quad
	addQuad( mesh, Vec2(min.x, max.y-borderSize.y), Vec2(max.x, max.y-borderSize.y), Vec2(min.x, max.y), Vec2(max.x,max.y), borderColor)
	
	
	
	form:clear()
	form:add(Panel(PanelSize(Vec2(-1, min.y))))
	
	form:add(Panel(PanelSize(Vec2(min.x, max.y-min.y))))
	form:add(Panel(PanelSize(Vec2(max.x-min.x, max.y-min.y)))):setCanHandleInput(false)
	form:add(Panel(PanelSize(Vec2(-1, max.y-min.y))))
	
	form:add(Panel(PanelSize(Vec2(-1, -1))))
	
end

local function collisionAgainstBox(minPos, maxPos, lineStartPos)
	--minPos = Vec2()
	--maxPos = Vec2()
	--collisionLine = Line2D()
	
	local tmpMin = minPos
	minPos:minimize(maxPos)
	maxPos:maximize(tmpMin)
	
	minPos = (minPos - Vec2(0.02)) * renderSize
	maxPos = (maxPos + Vec2(0.02)) * renderSize
	
	local collisionLine = Line2D( (minPos + maxPos) * 0.5, lineStartPos * renderSize )
	local collision, collPos
	collision, collPos = Collision.lineSegmentLineSegmentIntersection(Line2D(minPos, Vec2(maxPos.x, minPos.y)), collisionLine )
	if collision then 
		return collPos / renderSize 
	end
	collision, collPos = Collision.lineSegmentLineSegmentIntersection(Line2D(minPos, Vec2(minPos.x, maxPos.y)), collisionLine )
	if collision then 
		return collPos / renderSize 
	end
	collision, collPos = Collision.lineSegmentLineSegmentIntersection(Line2D(maxPos, Vec2(maxPos.x, minPos.y)), collisionLine )
	if collision then 
		return collPos / renderSize 
	end
	collision, collPos = Collision.lineSegmentLineSegmentIntersection(Line2D(maxPos, Vec2(minPos.x, maxPos.y)), collisionLine )
	if collision then 
		return collPos / renderSize 
	end
	--all failed return center pos of the box
	return (minPos + maxPos) / renderSize
end

local function updateTutorialRenderObject()
	
	mesh:setVisible(false)
	textNode:setVisible(false)
	tutorialCounter:setVisible(false)
	arrowMesh:setVisible(false)
	
	if tutorial.index <= #tutorial then
		local lesson = tutorial[tutorial.index]
		
		--build render quad
		if lesson.renderMode == "full" or lesson.sleep then
			mesh:clearMesh()
			addQuad(mesh, Vec2(), Vec2(1,0), Vec2(0,1), Vec2(1), black)
			mesh:compile()
			mesh:setVisible(true)
			
			form:clear()
			form:add(Panel(PanelSize(Vec2(-1))))
			
		elseif lesson.renderMode == "quad" then
			
			
			
			mesh:clearMesh()
			selectArea(lesson.renderData)
			mesh:compile()
			mesh:setVisible(true)
		end
		
		if not lesson.sleep then
			local arrowStartPos = Vec2(0.5)
			
			--Text
			if lesson.textAlign and lesson.text then
				
				if lesson.textAlign == "auto-down" or lesson.textAlign == "auto-right" or lesson.textAlign == "auto-up" or lesson.textAlign == "auto-left" then
					local textMargin = renderSize.y * 0.01
					local textOffset = Vec2(0.5)
					local centerPos = Vec2()
					
					if lesson.textAlign == "auto-down" then
						
						local yOffset = lesson.arrow == nil and 0.03 or 0.15
						textOffset = Vec2(0.5, 0)
						arrowStartPos = Vec2( (lesson.renderData.min.x + lesson.renderData.max.x) * 0.5, lesson.renderData.max.y + 0.15)
						centerPos = arrowStartPos * renderSize
						local halfSize = textNode:getTextSize() * 0.5
						
						--make sure text is not outside the text screen
						if centerPos.x + halfSize.x + textMargin  > renderSize.x then
							centerPos.x = renderSize.x - halfSize.x - textMargin
						elseif centerPos.x + halfSize.x + textMargin < 0 then
							centerPos.x = halfSize.x + textMargin
						end
					elseif lesson.textAlign == "auto-up" then
						
						local yOffset = lesson.arrow == nil and 0.03 or 0.15
						textOffset = Vec2(0.5, 1)
						arrowStartPos = Vec2( (lesson.renderData.min.x + lesson.renderData.max.x) * 0.5, lesson.renderData.min.y - yOffset)
						centerPos = arrowStartPos * renderSize
						local halfSize = textNode:getTextSize() * 0.5
						
						--make sure text is not outside the text screen
						if centerPos.x + halfSize.x + textMargin  > renderSize.x then
							centerPos.x = renderSize.x - halfSize.x - textMargin
						elseif centerPos.x + halfSize.x + textMargin < 0 then
							centerPos.x = halfSize.x + textMargin
						end
					elseif  lesson.textAlign == "auto-right" then
						
						arrowStartPos = Vec2( lesson.renderData.max.x, (lesson.renderData.min.y + lesson.renderData.max.y) * 0.5 ) + Vec2(0.15,0)
						textOffset = Vec2( 0, 0.5 )
						centerPos = arrowStartPos * renderSize
						
					elseif  lesson.textAlign == "auto-left" then
						
						arrowStartPos = Vec2( lesson.renderData.min.x, (lesson.renderData.min.y + lesson.renderData.max.y) * 0.5 ) - Vec2(0.15,0)
						textOffset = Vec2( 1.0, 0.5 )
						centerPos = arrowStartPos * renderSize
						
					end
					
					textNode:setText(lesson.text)
					textNode:setVisible(true)
					textNode:setSize(textNode:getTextSize())
					textNode:setLocalPosition(centerPos -  textNode:getTextSize() * textOffset)
					
					print("\n")
					print("-------------------------")
					print("CenterPos: "..tostring(centerPos.x)..", "..tostring(centerPos.y))
					print("TextPosition: "..tostring(centerPos.x-textNode:getTextSize().x * textOffset.x)..", "..tostring(centerPos.y-textNode:getTextSize().y * textOffset.y))
					print("TextSize: "..tostring(textNode:getTextSize().x)..", "..tostring(textNode:getTextSize().y))
					print("-------------------------")
					
				elseif lesson.textAlign == "center" then
					textNode:setText(lesson.text)
					textNode:setVisible(true)
					textNode:setSize(textNode:getTextSize())
					textNode:setLocalPosition(Vec2(renderSize.x * lesson.textPos.x, renderSize.y * lesson.textPos.y) - textNode:getTextSize() * 0.5)
					arrowStartPos = lesson.textPos
				elseif lesson.textAlign == "left" then
					textNode:setText(lesson.text)
					textNode:setVisible(true)
					textNode:setSize(textNode:getTextSize())
					textNode:setLocalPosition(Vec2(renderSize.x * lesson.textPos.x, renderSize.y * lesson.textPos.y - textNode:getTextSize().y * 0.5))
					arrowStartPos = lesson.textPos
				end
			end
			
			if lesson.arrow then
				if lesson.arrow == "renderData" then
					
					local arrowEndPos = collisionAgainstBox( lesson.renderData.min, lesson.renderData.max, arrowStartPos )
					local arrowStart = arrowEndPos + (arrowStartPos - arrowEndPos):normalizeV() * 0.09
					arrowMesh:setVisible(true)
					createArrow( arrowMesh, arrowStart, arrowEndPos, 0.03, 0.035, 0.0075, 0.025 )
				end
				
			end
		end
		
		tutorialCounter:setText(tutorial.index.."/"..#tutorial)
		tutorialCounter:setVisible(true)
		tutorialCounter:setSize(tutorialCounter:getTextSize())
		tutorialCounter:setLocalPosition(Vec2(renderSize.x * 0.95 - tutorialCounter:getTextSize().x, renderSize.y * 0.07 - tutorialCounter:getTextSize().y * 0.5))
	else
		form:setVisible(false)
	end

end

local function anyButtonPressed()
	return Core.getInput():getMouseDown(MouseKey.left) or Core.getInput():getMouseDown(MouseKey.right)
end

local function goBackInTime()
	local lesson = tutorial[tutorial.index]
	return lesson.restarted
end

local function saveWave()
	local lesson = tutorial[tutorial.index]
	lesson.restarted = false
end

local function moveCamera()
	tutorialListener = Listener("tutorial")
	tutorialListener:pushEvent("moveCamera", tabToStrMinimal({centerPos=Vec3(-0.393641591,0,7.32058239), localYPos=22.699991226196}))
end

local function restoreCamera()
	tutorialListener = Listener("tutorial")
	tutorialListener:pushEvent("restoreCameraPosition")
end

local function findrenderNode()
	local lesson = tutorial[tutorial.index]
	
	local name = lesson.renderData.name
	if name == "spawn" or name == "waypoint" or name == "endcrystall" then
		local point = nil
		local bilboard = Core.getGlobalBillboard("Paths")
		if name == "spawn" then
			point = bilboard:getTable("spawns")[1]
		elseif name == "waypoint" then 
			--points include spawn and end points,
			point = bilboard:getTable("points")[3]
		elseif name == "endcrystall" then 
			point = bilboard:getTable("ends")[1]
		end
		
		
		
		if point then
			local globalPos = point.island:getGlobalMatrix() * point.position
			
			local camera = this:getRootNode():findAllNodeByNameTowardsLeaf("MainCamera")[1]
			
			local minPos = camera:getScreenCoordFromglobalPos(globalPos)
			local maxPos = Vec2(minPos)
			local testPos = {Vec3( 1,0, 1),Vec3(-1,0, 1),Vec3( 1,0,-1),Vec3(-1,0,-1)}
			for y=1, 2 do
				for n=1, #testPos do
					local screenpos = camera:getScreenCoordFromglobalPos(globalPos + testPos[n] + Vec3(0,(y-1)*2.0,0))
					minPos:minimize( screenpos )
					maxPos:maximize( screenpos )
				end				
			end
			
			lesson.renderData.min = minPos / renderSize
			lesson.renderData.max = maxPos / renderSize

		end
	elseif name == "qube" then
		local box = lesson.renderData.area
		--box = Box()
		
		local camera = this:getRootNode():findAllNodeByNameTowardsLeaf("MainCamera")[1]
		
		local minPos = camera:getScreenCoordFromglobalPos(box:getCenterPosition())
		local maxPos = Vec2(minPos)
		local testPos = {Vec3(box:getMaxPos().x,0,box:getMaxPos().z),Vec3(box:getMinPos().x,0, box:getMaxPos().z),Vec3( box:getMaxPos().x,0,box:getMinPos().z),Vec3(box:getMinPos().x, 0, box:getMinPos().z)}
		for y=1, 2 do
			for n=1, #testPos do
				local screenpos = camera:getScreenCoordFromglobalPos(testPos[n] + Vec3(0,(y==1 and box:getMinPos().y or box:getMaxPos().y),0))
				minPos:minimize( screenpos )
				maxPos:maximize( screenpos )
			end				
		end
		
		lesson.renderData.min = minPos / renderSize
		lesson.renderData.max = maxPos / renderSize
	end
end

local function towerUpgraded()
	local buildingBillboard = Core.getBillboard("buildings")
	return (Core.getFrameNumber() - buildingBillboard:getInt("towerUpgradedFrame")) < 3

end

local function getTowerMenuActive()
	local buildingBillboard = Core.getBillboard("buildings")
	return buildingBillboard:getBool("isTowerSelected")

end

local function towerSelected()
	local lesson = tutorial[tutorial.index]
	local buildingBillboard = Core.getBillboard("buildings")
	return buildingBillboard:getInt("towerIndex") == lesson.towerIndex
end

local function twoTowersBuilt()
	local buildingBillboard = Core.getBillboard("buildings")
	return buildingBillboard:getInt("NumBuildingBuilt") >= 2
end

local function fiveTowersBuilt()
	local buildingBillboard = Core.getBillboard("buildings")
	return buildingBillboard:getInt("NumBuildingBuilt") >= 5
end

local function towerRotated()
	local buildingBillboard = Core.getBillboard("buildings")
	local lesson = tutorial[tutorial.index]
	
	
	print("")
	print("CurrentRotation: "..buildingBillboard:getInt( "buildingRotation"))
	print("Start Rotation:  "..lesson.rotation)
	
	if buildingBillboard:getInt( "buildingRotation") ~= lesson.rotation then
		lesson.timer = lesson.timer - Core.getRealDeltaTime()
		print("time: "..lesson.timer)
		return lesson.timer <= 0
	end
	return false
end

local function speedIncrease()
	return Core.getTimeSpeed() > 1.5
end

local function towerBuilt()
	local buildingBillboard = Core.getBillboard("buildings")
	local lesson = tutorial[tutorial.index]	
	
	print("Tower"..lesson.towerIndex..": ".. buildingBillboard:getInt("tower"..lesson.towerIndex) .. " > "..lesson.numTowers)
	
	return buildingBillboard:getInt("tower"..lesson.towerIndex) > lesson.numTowers
end

local function deselectTower()
	local buildingBillboard = Core.getBillboard("buildings")
	return buildingBillboard:getInt("towerIndex") == -1
end

local function saveRotationValue()
	
	local buildingBillboard = Core.getBillboard("buildings")
	local lesson = tutorial[tutorial.index]
	lesson.rotation = buildingBillboard:getInt( "buildingRotation")
end

local function clearGhostTower()
	local clientId = this:getPlayerNode():getClientId()
	comUnit:sendTo("builder"..clientId, "clearGhostTower", "" )
end

local function getFirstTowerPlacment()
	local lesson = tutorial[tutorial.index]
	
	local islands = this:getRootNode():findAllNodeByTypeTowardsLeaf(NodeId.island)
	local island = nil
	for i=1, #islands do
		if islands[i]:getIslandId() == 1 then
			island = islands[i]
		end
	end
	
	if island then		
		local box = Box(Sphere(island:getGlobalMatrix() * Vec3(-0.697304666,0,-0.663576126),2))
		box:expand( Box(Sphere(island:getGlobalMatrix() * Vec3(0.882695198,0,-0.74357605),2)) )
		box:setMinPos(box:getMinPos() + Vec3(0,1,0))
		lesson.renderData.area = box	
	else
		lesson.renderData.area = Box(Sphere(Vec3(0),5))
	end
	
	findrenderNode()
	
	local clientId = this:getPlayerNode():getClientId()
	comUnit:sendTo("builder"..clientId, "addGhostTower", tabToStrMinimal({modelName="tower_wall.mym",islandID=1,lifespan=5000000,localMatrix=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,-0.737303734,0,-0.923574448,1}) }))
	comUnit:sendTo("builder"..clientId, "addGhostTower", tabToStrMinimal({modelName="tower_wall.mym",islandID=1,lifespan=5000000,localMatrix=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,0.862696648,0,-0.983575821,1}) }))
end

local function getSecondTowerPlacment()
	local lesson = tutorial[tutorial.index]
	
	local islands = this:getRootNode():findAllNodeByTypeTowardsLeaf(NodeId.island)
	local island = nil
	for i=1, #islands do
		if islands[i]:getIslandId() == 1 then
			island = islands[i]
		end
	end
	
	if island then		
		local box = Box(Sphere(island:getGlobalMatrix() * Vec3(3.5626955,0,2.87642479),2))
		box:expand( Box(Sphere(island:getGlobalMatrix() * Vec3(4.28269672,0,1.21642494),2)) )
		box:expand( Box(Sphere(island:getGlobalMatrix() * Vec3(4.5626955,0,-0.443574905),2)) )
		box:setMinPos(box:getMinPos() + Vec3(0,1,0))
		lesson.renderData.area = box
	else
		lesson.renderData.area = Box(Sphere(Vec3(0),5))
	end
	
	saveRotationValue()
	
	findrenderNode()
	
	local clientId = this:getPlayerNode():getClientId()
	comUnit:sendTo("builder"..clientId, "addGhostTower", tabToStrMinimal({modelName="tower_wall.mym",islandID=1,lifespan=5000000,localMatrix=createMatrixFromTable({0.866025388,0,0.5,0,0,1,0,0,-0.5,0,0.866025388,0,3.5626955,0,2.71642494,1}) }))
	comUnit:sendTo("builder"..clientId, "addGhostTower", tabToStrMinimal({modelName="tower_wall.mym",islandID=1,lifespan=5000000,localMatrix=createMatrixFromTable({0.95105654,0,0.309017062,0,0,1,0,0,-0.309017062,0,0.95105654,0,4.26269627,0,1.13642502,1}) }))
	comUnit:sendTo("builder"..clientId, "addGhostTower", tabToStrMinimal({modelName="tower_wall.mym",islandID=1,lifespan=5000000,localMatrix=createMatrixFromTable({1,0,0,0,0,1,0,0,0,0,1,0,4.3826952,0,-0.623575211,1}) }))
	
	
end

function selectTower()
	local lesson = tutorial[tutorial.index]
	local builderNode = this:getPlayerNode():findNodeByTypeTowardsLeafe(NodeId.buildNode)
	local builings = builderNode:getBuildingList()
	
	--make sure the tower we want to select exist, user can have sold of a few tower
	local towerId = lesson.renderData.towerId
	while #builings < towerId and towerId > 0 do
		towerId = towerId - 1
	end
	
	local building = builings[towerId]
	local buildingBillboard = Core.getBillboard("buildings")

	lesson.renderData.area = Box(Sphere(building:getGlobalPosition(),2))
	lesson.numTowers = buildingBillboard:getInt("tower"..(lesson.towerIndex and lesson.towerIndex or 1))
	
	findrenderNode()
end

local function pauseGame()
	Core.setTimeSpeed(0)
end

local function unPauseGame()
	Core.setTimeSpeed(1)
end

local function loseOfLife()
	statsBilboard = Core.getBillboard("stats")
	if statsBilboard:getInt("life") < 20 then
		pauseGame()
		form:setVisible(true)
		return true
	end
	form:setVisible(false)
	return false
end

local function hideForm()
	
end

local function restartWave()
	local lesson = tutorial[tutorial.index]
	lesson.restarted = true
end

local function reachWave()
	return statsBilboard:getInt("wave") == 2
end

local function getKeyBindIconWallTower(id)
	local keyBindText = keyBinds:getKeyBind("Building "..id):getKeyBindName(0)
	return "<img src='icon_table.tga' uvmin=Vec2(0,0.9375) uvmax=Vec2(0.125,1) letter='" .. keyBindText .. "' letterColor=rgb(0,0,0)>"
end

local function getKeyBindSpeed()
	local keyBindText = keyBinds:getKeyBind("Speed"):getKeyBindName(0)
	return "<img src='icon_table.tga' uvmin=Vec2(0,0.9375) uvmax=Vec2(0.125,1) letter='" .. keyBindText .. "' letterColor=rgb(0,0,0)>"
end

local function getLeftMouseClickIcon()
	return "<img src='icon_table.tga' uvmin=Vec2(0,0.8125) uvmax=Vec2(0.125,0.875)>"
end

local function getRightMouseClickIcon()
	return "<img src='icon_table.tga' uvmin=Vec2(0.125,0.8125) uvmax=Vec2(0.25,0.875)>"
end

local function getMouseScrollIcon()
	return "<img src='icon_table.tga' uvmin=Vec2(0.25,0.8125) uvmax=Vec2(0.375,0.875)>"
end

function create()
	
	keyBinds = Core.getBillboard("keyBind");
	
	comUnit:setName("tutorialComunit")
	comUnit:setCanReceiveTargeted(false)
	comUnit:setCanReceiveBroadcast(true)
	
	restartWaveListener = Listener("RestartWave")
	restartWaveListener:registerEvent("restartWave", restartWave)
	
	
	local camera = ConvertToCamera(this:getRootNode():findNodeByName("MainCamera"));
	
	form = Form( camera, PanelSize(Vec2(-1,-1)), Alignment.BOTTOM_RIGHT);
	form:setName("tutorial form")
	form:setRenderLevel(201)
	form:setCanHandleInput(false)
	form:setLayout(FlowLayout())

	textNode:setTextHeight(renderSize.y * 0.025)
	textNode:setColor(Vec3(1))
	textNode:setSize(renderSize)
	
	tutorialCounter:setTextHeight(renderSize.y * 0.025)
	tutorialCounter:setColor(Vec3(1))
	tutorialCounter:setSize(renderSize)
	
	buttonState = 1
	local buttonSize = 0.025
	xButtonCreate( xButtonMesh, buttonSize, Vec2(renderSize.x * (0.95 + buttonSize * 0.5), renderSize.y * 0.07), Vec4(1,1,1,1) )
	
	
	tutorial = {
		index = 1,
		
		--guidad tour of the menu system
		{renderMode="full", next=anyButtonPressed, doneFunc=moveCamera, textAlign="center", textPos=Vec2(0.5), text="Welcome to the tutorial"}, 
		{renderMode="quad", next=anyButtonPressed, initFunc=findrenderNode, renderData={name="spawn"}, arrow="renderData", sleep=1, textAlign="auto-down", text="Enemies will spawn from this portal"},
		{renderMode="quad", next=anyButtonPressed, initFunc=findrenderNode, renderData={name="waypoint"}, arrow="renderData", textAlign="auto-up", text="they will move towards this waypoint"},
		{renderMode="quad", next=anyButtonPressed, initFunc=findrenderNode, renderData={name="endcrystall"}, arrow="renderData", textAlign="auto-down", text="and they will go to the endcrystall.\nIf they reach this point you lose a life."},
		{renderMode="quad", next=anyButtonPressed, doneFunc=restoreCamera, renderData={min=Vec2(0.25,0.15), max=Vec2(0.75, 0.95)}, textAlign="auto-up", text="you can always se how the enemies will run by watching the spirits movments"},
		{renderMode="quad", next=anyButtonPressed, renderData={panelMin="tower2",panelMax="tower8"},arrow="renderData",textAlign="auto-right", text="The first enemies will start spawning,\nwhen one of this towers has been built"},
		{renderMode="quad", next=anyButtonPressed, renderData={panel="npcPanel"},arrow="renderData", textAlign="auto-down", text="Here you can se information what enemies is about to spawn.\nThis can help you plan what towers to build and uppgrade."},
		{renderMode="quad", next=anyButtonPressed, renderData={panel="life remaining"},arrow="renderData", textAlign="auto-down", text="This is how many life you have left.\nA life is lost when the enemy reaches the end crystal."},
		{renderMode="quad", next=anyButtonPressed, renderData={panel="money"},arrow="renderData", textAlign="auto-down", text="Towers cost gold to upgrade and build.\nFor every 1000gold here you earn 1 extra gold per kill."},
		{renderMode="quad", next=anyButtonPressed, renderData={panel="score"},arrow="renderData", textAlign="auto-down", text="This is your score counter."},
		
		--first tutorial step
		{renderMode="quad", next=towerSelected, towerIndex=1, renderData={panel="tower1"},arrow="renderData",textAlign="auto-right", text="Now lets get starting playing the game.\nTo start planing out where all the tower should be placed.\nStart by selecting the wall tower. By pressing this button or the key "..getKeyBindIconWallTower(1)},
		{renderMode="quad", next=twoTowersBuilt, initFunc=getFirstTowerPlacment, doneFunc=clearGhostTower, renderData={name="qube"}, textAlign="auto-up", text="Now build 2 wall towers on the two marked areas.\nPress down to build "..getLeftMouseClickIcon().." a wall tower"},
		{renderMode="quad", next=fiveTowersBuilt, initFunc=getSecondTowerPlacment, doneFunc=clearGhostTower, timer=2, renderData={name="qube"}, textAlign="auto-up", text="Towers can be rotated with the mouse scroll "..getMouseScrollIcon().." \nNow rotate the Wall tower and place the remaning 3 towers."},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Now when we have planed out where we will place towers.\nIts time to build towers that can deal damage."},
		{renderMode="quad", next=towerSelected, towerIndex=2,arrow="renderData", renderData={panel="tower2"}, textAlign="auto-right", text="We start of by selecting the minigun tower from the menu or press down key ".. getKeyBindIconWallTower(2) ..".\nMinigun tower is a good single target tower. Thats targets the closest enemy to the endcrystal."},
		{renderMode="quad", next=towerBuilt, towerIndex=2, initFunc=selectTower, doneFunc=pauseGame, renderData={towerId=1,name="qube"}, textAlign="auto-up", text="Build the Minigun Tower on top of the wall Tower.\nAll towers can also be placed freely as the Wall Tower\nI have paused the game during the tutorial."},
		{renderMode="quad", next=towerSelected, towerIndex=4,arrow="renderData", renderData={panel="tower4"}, textAlign="auto-right", text="Now select the Swarm tower from the menu or press down key ".. getKeyBindIconWallTower(4) ..".\nSwarm tower needs to have enemies in range for 13 seconds to be fully activated.\nThis make it a high damage when fully chared making it great in extended fights."},
		{renderMode="quad", next=towerBuilt, towerIndex=4, initFunc=selectTower, renderData={towerId=2,name="qube"}, textAlign="auto-up", text="Build one Swarm Tower on top of the wall Tower."},
		{renderMode="quad", next=deselectTower, doneFunc=unPauseGame, renderData={min=Vec2(0.25,0.15), max=Vec2(0.75, 0.95)}, textAlign="auto-up", text="De select the tower by pressing right mouse button "..getRightMouseClickIcon()},
		{renderMode="quad", next=speedIncrease, renderData={panel="speed"},arrow="renderData", textAlign="auto-down", text="Klick on the speed button to switch bettewn x1 and x3 or press down key " .. getKeyBindSpeed() .. "\n and watch as the game unfold before you.\nNext part of the tutorial start when when you have lost a life."},
		
		--sedond part of the tutorial
		{renderMode="full", next=anyButtonPressed, initWait=reachWave, textAlign="center", textPos=Vec2(0.5), text="Okey to clear this wave somthinge needs to be done to not lose a single life."},
		{renderMode="full", next=anyButtonPressed, initFunc=saveWave, textAlign="center", textPos=Vec2(0.5), text="The wave has been restarted. You can see no life has been lost.\nNow to get thrue this map you are gone use the boost button on the tower.\nthis will significant increase the damage of the tower for a short moment.\nNow let's wait for a good moment to boost the tower."},

		{renderMode="quad", next=getTowerMenuActive, initFunc=selectTower, renderData={towerId=1,name="qube"}, textAlign="auto-up", timer=5, textPos=Vec2(0.5), text="The time time is now good to boos the tower"},
		{renderMode="quad", next=getTowerMenuActive, initFunc=selectTower, renderData={towerId=1,name="qube"}, textAlign="auto-up", text="We now wil upgrade the towers to handle this wave.\nKlick on the minigun tower tower"},
		{renderMode="quad", next=anyButtonPressed, arrow="renderData",sleep=0.1, renderData={panel="selectedTowerPanel"}, textAlign="auto-left", text="Here you can see the information about the tower"},
		{renderMode="quad", next=anyButtonPressed, arrow="renderData", renderData={panel="damageInfoBar"}, textAlign="auto-left", text="If you hower over this bar you can se detailed information\nabout how the tower is doing damage wise"},
		{renderMode="quad", next=anyButtonPressed, arrow="renderData", renderData={panel="upgradePanel"}, textAlign="auto-left", text="Here you can upgrade the tower.\nMost of this upgrade requires to be unlocked in the shop\nThe shop can be found in the main menu when selecting\nwhat map to play in campaign"},
		{renderMode="quad", next=towerUpgraded, arrow="renderData", renderData={panel="upgradeTowerButton"}, textAlign="auto-left", text="Press on the button to uppgrade the tower"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="now let's the game unfoled again"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="it's obvious the towers will not be able to hold of this wave\n we can temporary boost a tower do incresed damage"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="This will conclude the tutorial.\nI will leave it up to you to finish the map."}		
	}
	

	
	form:addRenderObject(mesh)
	form:addRenderObject(xButtonMesh)
	form:addRenderObject(arrowMesh)
	form:addRenderObject(textNode)
	form:addRenderObject(tutorialCounter)
	
	
	
	updateTutorialRenderObject()
	
	return true
end

function update()
	
	
	local mouseOnButton = (Core.getInput():getMousePos() - buttonPosition):length() < buttonRadius
	
	if buttonState ~= 2 and mouseOnButton then
		buttonState = 2
		local buttonSize = 0.025
		xButtonCreate( xButtonMesh, buttonSize, Vec2(renderSize.x * (0.95 + buttonSize * 0.5), renderSize.y * 0.07), buttonState == 1 and Vec4(1,1,1,1) or Vec4(0.7,0.7,0.7,1) )
	elseif buttonState ~= 1 and not mouseOnButton then
		buttonState = 1
		local buttonSize = 0.025
		xButtonCreate( xButtonMesh, buttonSize, Vec2(renderSize.x * (0.95 + buttonSize * 0.5), renderSize.y * 0.07), buttonState == 1 and Vec4(1,1,1,1) or Vec4(0.7,0.7,0.7,1) )
	end
	

	if tutorial.index <= #tutorial then
		local lesson = tutorial[tutorial.index]
		
		if lesson.initWait == nil or lesson.initWait() == true then
			
			if lesson.initWait then
				--if we have waited for the event to start
				--prepare the event now
				if lesson and not lesson.sleep and lesson.initFunc then
					lesson.initFunc()
				end
				
				updateTutorialRenderObject()
				
				lesson.initWait = nil
			end
			
			
			
			if lesson.next() then
				if lesson.doneFunc then
					lesson.doneFunc()
				end
				tutorial.index = tutorial.index + 1
				lesson = tutorial[tutorial.index]
				if lesson == nil then
					form:setVisible(false)
					return true
				end
				
				if lesson.initWait == nil then
					--if do not need for the event to start then init the lesson
					if lesson and not lesson.sleep and lesson.initFunc then
						lesson.initFunc()
					end
					
					updateTutorialRenderObject()
				end
			elseif lesson.sleep then
				lesson.sleep = lesson.sleep - Core.getRealDeltaTime()
				if lesson.sleep <= 0.0 then
					lesson.sleep = nil
					if lesson.initFunc then
						lesson.initFunc()
					end
					updateTutorialRenderObject()
				end
			end
				
		end
		
		
	end
	
	form:update()
	
	return true
	
end