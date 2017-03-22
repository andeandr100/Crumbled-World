--this = SceneNode()
function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
	end
end

function create()
	if not DEBUG then
		return false
	end
	if this:getNodeType() == NodeId.playerNode then
		local menuNode = this:getRootNode():addChild(SceneNode())
		--camera = Camera()
		menuNode:setSceneName("Log menu")
		menuNode:createWork()
				
		--Move this script to the camera node
		--this:removeScript(this:getCurrentScript():getName());
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		return false
	else
		local rootNode = this:getRootNode();
		local camera = ConvertToCamera(rootNode:findNodeByName("MainCamera"));
		backgroundSet = false
		
		form = Form( camera, PanelSize(Vec2(0.25,0.45)), Alignment.BOTTOM_LEFT);
		form:setName("Log form")
		--form:setBackground(Sprite(Vec4(0.1, 0.1, 0.1, 0.7)));
		form:setLayout(FlowLayout());
		--form:setBorder(Border(BorderSize(Vec4(0.005)), Vec4(0,0,0,0),Vec4(0,0,0,1)));
		form:setPadding(BorderSize(Vec4(0.005)));
		form:getLayout():setPanelSpacing(PanelSize(Vec2(0.001)));
		form:setFormOffset(PanelSize(Vec2(0.005), Vec2(1)));
		form:setVisible(true)
		form:setCanHandleInput(false)
		form:setRenderLevel(11)
		
		local rowHeight = 0.025 - 0.001
		local yHeight = form:getPanelSize():getSize().y - 0.01 - form:getPaddingSize():getSize().y
		numLabels = math.floor( yHeight / rowHeight) - 1
		labels = {}
		textList = {}
		for i=1,numLabels do
			textList[i] = ""
			labels[i] = form:add(Label(PanelSize(Vec2(-1,rowHeight)),textList[i],Vec3(1)))
			labels[i]:setCanHandleInput(false)
		end
		
		comUnit = Core.getComUnit()
		comUnit:setCanReceiveTargeted(true)
		comUnit:setName("log")
		
		--ComUnitCallbacks
		comUnitTable = {}
		comUnitTable["println"] = println
		comUnitTable["printlnerror"] = printlnerror
	end
	return true
end
function moveUp()
	for i=2, numLabels do
		textList[i-1] = textList[i]
	end
end
function printAll()
	for i=1, numLabels do
		labels[i]:setText(textList[i])
	end
end
function println(out)
	moveUp()
	textList[numLabels] = tostring(out)
	printAll()
end
function printlnerror(out)
	comUnit:sendTo("logCrash","maybeCrashed","")
	if backgroundSet==false then
		backgroundSet=true
		form:setBackground(Sprite(Vec4(0.1, 0.1, 0.1, 0.7)));
		
		
		--local luaTextEditor = this:getRootNode():addChild(SceneNode())
		--luaTextEditor:createWork()
		--luaTextEditor:loadLuaScript("Menu/luaTextEditor.lua")
		
		
		--form:setBorder(Border(BorderSize(Vec4(0.005)), Vec4(0,0,0,0),Vec4(0,0,0,1)));
	end
	moveUp()
	textList[numLabels] = "<b><font color=rgb(255,10,10)>"..tostring(out).."</font></b>"
	printAll()
end
function update()
	--Handle communication
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message]~=nil then
			comUnitTable[msg.message](msg.parameter)
		end
	end
	
	--form
	form:update();
	
	return true
end