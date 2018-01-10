--this = SceneNode()

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

function create()
	timer = 0.0
	if this:getNodeType() == NodeId.playerNode then
		local menuNode = this:getRootNode():addChild(SceneNode.new())
		--camera = Camera()
		menuNode:setSceneName("crash log menu")
		menuNode:createWork()
				
		--Move this script to the camera node
		--this:removeScript(this:getCurrentScript():getName());
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		return false
	end
	keyBindToogleVisible = KeyBind()
	keyBindToogleVisible:setKeyBindKeyboard(0, Key.F7)
	
	
	return true
end
function generateForm()
	local rootNode = this:getRootNode();
	local camera = ConvertToCamera(rootNode:findNodeByName("MainCamera"));
	
	form = Form( camera, PanelSize(Vec2(0.15,0.75)), Alignment.TOP_LEFT);
	form:setBackground(Sprite(Vec4(0.1, 0.1, 0.1, 0.7)));
	form:setLayout(FlowLayout());
	form:setBorder(Border(BorderSize(Vec4(0.005)), Vec4(0,0,0,0),Vec4(0,0,0,1)));
	form:setPadding(BorderSize(Vec4(0.005)));
	form:getLayout():setPanelSpacing(PanelSize(Vec2(0.001)));
	form:setFormOffset(PanelSize(Vec2(0.055,0.1)));
	form:setRenderLevel(9)
	form:setVisible(true)
	
	
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
function printAll()
	for i=1, numLabels do
		labels[i]:setText(textList[i])
	end
end
function isNewOnTable(name)
	if oldTable then
		for i=1, #oldTable do
			if oldTable[i]==name then
				return false
			end
		end
	end
	return true
end
function update()
	if keyBindToogleVisible:getPressed() then
		if show==nil then
			show=true
			generateForm()
		elseif show==false then
			show = true
			form:setVisible(true)
		else
			show = false
			form:setVisible(false)
		end
	end
	if show==true then
		timer = timer + Core.getRealDeltaTime()
		if timer>1.0 then
			timer = 0.0
--			newTable = getActiveScriptCounterTable()
--			local min = math.min(numLabels,#newTable)
--			for i=1, min do
--				if isNewOnTable(newTable[i]) then
--					labels[i]:setText("<font color=rgb(10,255,10)>"..newTable[i].."</font>")
--				else
--					labels[i]:setText(newTable[i])
--				end
--			end
--			if min~=numLabels then
--				for i=min+1, numLabels do
--					labels[i]:setText("")
--				end
--			end
--			oldTable = newTable
			
			local groups = getGroupScriptTimeTable();
			local count = 1
			for i=count, #groups do
				labels[i]:setText( groups[i].name..", "..groups[i].count..", "..(math.round(groups[i].time*10000)/10).."ms" )
				count = count + 1
			end
			count = count + 1
--			print("groups: "..tostring(groups))
			labels[count]:setText("scripts:")
			count = count + 1
			
			local tab = getScriptTimeTable()
--			print("scripts: "..tostring(tab))
			
--			print("numLabels: "..numLabels)
--			print("tab: "..#tab)
			for i=count, math.min(numLabels, #tab) do
				labels[i]:setText( tab[i-count+1].name..", "..tab[i-count+1].count..", "..(math.round(tab[i-count+1].time*10000)/10).."ms" )
			end
		end
		--form
		form:update()
	end
	
	return true
end