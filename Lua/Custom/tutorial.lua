--this = SceneNode()

local tutorial = nil
local mesh = Node2DMesh()
local textNode = TextNode()
local xButtonMesh = Node2DMesh()
local tutorialCounter = TextNode()
local black = Vec4(0,0,0,0.5)
local renderSize = Core.getRenderResolution()
local buttonPosition = Vec2()
local buttonRadius = 0
local buttonState = 1

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
	
end

local function updateTutorialRenderObject()
	
	mesh:setVisible(false)
	textNode:setVisible(false)
	tutorialCounter:setVisible(false)
	
	if tutorial.index <= #tutorial then
		local lesson = tutorial[tutorial.index]
		
		--build render quad
		if lesson.renderMode == "full" then
			mesh:clearMesh()
			addQuad(mesh, Vec2(), Vec2(1,0), Vec2(0,1), Vec2(1), black)
			mesh:compile()
			mesh:setVisible(true)
		elseif lesson.renderMode == "quad" then
			mesh:clearMesh()
			selectArea(lesson.renderData)
			mesh:compile()
			mesh:setVisible(true)
		end
		
		
		--Text
		if lesson.textAlign == "center" then
			textNode:setText(lesson.text)
			textNode:setVisible(true)
			textNode:setSize(textNode:getTextSize())
			textNode:setLocalPosition(Vec2(renderSize.x * lesson.textPos.x, renderSize.y * lesson.textPos.y) - textNode:getTextSize() * 0.5)
		end
		
		
		tutorialCounter:setText(tutorial.index.."/"..#tutorial)
		tutorialCounter:setVisible(true)
		tutorialCounter:setSize(tutorialCounter:getTextSize())
		tutorialCounter:setLocalPosition(Vec2(renderSize.x * 0.95 - tutorialCounter:getTextSize().x, renderSize.y * 0.07 - tutorialCounter:getTextSize().y * 0.5))
	end

end

local function anyButtonPressed()
	return Core.getInput():getAnyKeyDownEvent() ~= -1 or Core.getInput():getAnyMouseDownEvent() ~= -1
end

function create()
	
	local camera = ConvertToCamera(this:getRootNode():findNodeByName("MainCamera"));
	
	form = Form( camera, PanelSize(Vec2(-1,-1)), Alignment.BOTTOM_RIGHT);
	form:setName("tutorial form")
	form:setRenderLevel(201)
	
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
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Welcome to the tutorial"}, 
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Enemies will first start to spawn when a tower that deals damage has been built"},
		{renderMode="quad", next=anyButtonPressed, renderData={min=Vec2(0.1,0),max=Vec2(0.6,0.032)}, textAlign="center", textPos=Vec2(0.5), text="Here you can se information about the next waves of emeies"},
		{renderMode="quad", next=anyButtonPressed, renderData={min=Vec2(0.08,0),max=Vec2(0.1,0.032)}, textAlign="center", textPos=Vec2(0.5), text="This indicates the time until next wave of enemies spawns"},
		{renderMode="quad", next=anyButtonPressed, renderData={min=Vec2(0.7,0),max=Vec2(0.8,0.032)}, textAlign="center", textPos=Vec2(0.5), text="Here you can se the amount of gold you have access to.\n hold your mouse pointer over the gold field to se more detailed infomration"},
		{renderMode="quad", next=anyButtonPressed, renderData={min=Vec2(0.8,0),max=Vec2(0.9,0.032)}, textAlign="center", textPos=Vec2(0.5), text="This life left before you die, when this counter reach zero you have lost the game"},
		{renderMode="quad", next=anyButtonPressed, renderData={min=Vec2(0.6,0),max=Vec2(0.7,0.032)}, textAlign="center", textPos=Vec2(0.5), text="Score counter"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="game speed"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Now lets get starting playing the game.\nTo start planing out where all the tower should be placed.\nStart by selecting the wall tower."},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Now place the tower on the two marked areas"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Towers can be rotated with the mouse scroll. With this information place the remaning towers"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Now when we have planed out where we will place towers. its time to build real tower"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Press {f} to increse the game speed to x3, and watch as the game unfold before you."},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Now ouer awsome defence faild to stop all the enemies.\n don't wory we can fix the misstake. press {backspace} to replay the preivous wave."},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Good now we need to increse the defense click on the tower"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="Press on the button to uppgrade the tower"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="now let's the game unfoled again"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="it's obius the towers will not be able to hold of this wave\n we can temporary boost a tower do incresed damage"},
		{renderMode="full", next=anyButtonPressed, textAlign="center", textPos=Vec2(0.5), text="good you made it.\nOne last lession try to keep as mutch gold in the bank as posible. for every 1000gold in the bank you gain 1 gold for every enemy you kill on the battlefield.\nUse what you learned and finish the map.\nGood luck"}		
	}
	
	
	
	form:addRenderObject(mesh)
	form:addRenderObject(xButtonMesh)
	form:addRenderObject(textNode)
	form:addRenderObject(tutorialCounter)
	
	
	
	
	updateTutorialRenderObject()
	
	return true
end

function update()
	
	
	local mouseOnButton = (Core.getInput():getMousePos() - buttonPosition):length() < buttonRadius
	
	print("")
	print("ButtonState: "..buttonState)
	print("mouseOnButton: "..(mouseOnButton and "true" or "false"))
	print("distToButton: "..(Core.getInput():getMousePos() - buttonPosition):length())
	
	
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
		if tutorial[tutorial.index].next() then
			tutorial.index = tutorial.index + 1
			updateTutorialRenderObject()
		end
	end
	
	form:update()
	
	return true
	
end