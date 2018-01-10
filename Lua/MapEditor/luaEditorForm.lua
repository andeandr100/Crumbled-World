require("MapEditor/listener.lua")
--this = SceneNode()
function showFile( fileName )
	visible = true
	textArea:openFile(Text(fileName))
end

function showWindow(name)
	if name == "TextEditor:Show" then
		visible = true
	elseif name == "TextEditor" then
		visible = not visible
	else
		visible = false
	end
	
	form:setVisible(visible)
	
	if not visible then
		print("text editor not visible")
		listString = textArea:getOpenFiles()
		local mapEditorConf = Config("MapEditor")
		local conf = mapEditorConf:get("LuaEdtiorFiles")
		mapEditorConf:get("textHeight"):setInt(textArea:getTextHeight())
		local count = #listString + 1

		for i=1, #listString do
			conf:get("file"..i):setString(listString[i])
		end
		
		while conf:exist("file"..count) do
			conf:remove("file"..count)
			count = count + 1
		end
		mapEditorConf:save()
	else
		print("text editor visible")
	end
end

function create()
	
	comUnit = Core.getComUnit()
	comUnit:setName("LuaTextEditor")
	comUnit:setCanReceiveTargeted(true)
	comUnit:setCanReceiveBroadcast(false)
	
	comUnitTable = {}
	comUnitTable["showFile"] = showFile
	
	editorListener:registerEvent("window", showWindow)

	--camera = Camera()
	local camera = this.getRootNode(this):findNodeByName("MainCamera")
	visible = false;
	if camera then
		form = Form(ConvertToCamera(camera), PanelSize(Vec2(-1,-1)), Alignment.TOP_LEFT);
		form:setLayout(FlowLayout(PanelSize(Vec2(0.01,0.01))));
		form:setRenderLevel(12)
		
		textArea = form:add(TextArea(PanelSize(Vec2(-1,-1))));
		
		local mapEditorConf = Config("MapEditor")
		local conf = mapEditorConf:get("LuaEdtiorFiles")
		textArea:setTextHeight(mapEditorConf:get("textHeight", 12):getInt())
		local count = 1
		while conf:exist("file"..count) do
			textArea:openFile(Text(conf:get("file"..count):getString()))
			count = count + 1
		end
	end
	return true
end

function update()
	
	--Handle communication
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message]~=nil then
			comUnitTable[msg.message](msg.parameter,msg.fromIndex)
		end
	end
	
	if Core.getInput():getKeyDown(Key.F3) then
		editorListener:pushEvent("window","TextEditor")
	end
	if Core.getInput():getKeyDown(Key.escape) then
		editorListener:pushEvent("window","hide")
	end

	if visible then
		form:update();
	end
	return true;
end