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
	tableSize=0
	if this:getNodeType() == NodeId.playerNode then
		local menuNode = this:getRootNode():addChild(SceneNode())
		--camera = Camera()
		menuNode:setSceneName("crash log menu")
		menuNode:createWork()
				
		--Move this script to the camera node
		--this:removeScript(this:getCurrentScript():getName());
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		return false
	else
		comUnit = Core.getComUnit()
		comUnit:setCanReceiveTargeted(true)
		comUnit:setName("logCrash")
		
		--ComUnitCallbacks
		comUnitTable = {}
		comUnitTable["maybeCrashed"] = maybeCrashed
		
		maybeCrashed()
	end
	return true
end
function generateForm()
	local rootNode = this:getRootNode();
	local camera = ConvertToCamera(rootNode:findNodeByName("MainCamera"));
	
	form = Form( camera, PanelSize(Vec2(0.15,0.22)), Alignment.TOP_LEFT);
	form:setName("LogCrash form")
	form:setBackground(Sprite(Vec4(0.1, 0.1, 0.1, 0.7)));
	form:setLayout(FlowLayout());
	form:setBorder(Border(BorderSize(Vec4(0.005)), Vec4(0,0,0,0),Vec4(0,0,0,1)));
	form:setPadding(BorderSize(Vec4(0.005)));
	form:getLayout():setPanelSpacing(PanelSize(Vec2(0.001)));
	form:setFormOffset(PanelSize(Vec2(0.055,0.1)));
	form:setRenderLevel(1)
	form:setVisible(true)
	form:setCanHandleInput(false)
	
	local rowHeight = 0.025 - 0.001
	local yHeight = form:getPanelSize():getSize().y - 0.01 - form:getPaddingSize():getSize().y
	numLabels = math.floor( yHeight / rowHeight)
	labels = {}
	textList = {}
	for i=1,numLabels do
		textList[i] = ""
		labels[i] = form:add(Label(PanelSize(Vec2(-1,rowHeight)),textList[i],Vec3(1)))
	end
end
function moveDown()
	for i=numLabels-1, 1, -1  do
		textList[i-1] = textList[i]
	end
end
function printAll()
	for i=1, numLabels do
		labels[i]:setText(textList[i])
	end
end
function maybeCrashed(out)
	tab = getCrashTable()
	if tableSize~=#tab then
		if form == nil then
			generateForm()
		end
		tableSize = #tab
		local start = tableSize>numLabels and tableSize-(numLabels-1) or 1
		for i=start, tableSize do
			textList[i-start+1] = "<b><font color=rgb(255,10,10)>"..tab[i].."</font></b>"
		end
		printAll()
	end
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
	if form then
		form:update();
	end
	
	return true
end