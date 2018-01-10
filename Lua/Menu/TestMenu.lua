--this = SceneNode()
function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

function create()

	--camera = Camera()
	local camera = this.getRootNode(this):findNodeByName("MainCamera")
	Core.setMaxFrameRate(60)
	
	renderCount = 1
	if camera then
		form = Form(ConvertToCamera(camera), PanelSize(Vec2(-1,-1)), Alignment.TOP_LEFT);
		form:setLayout(FlowLayout(PanelSize(Vec2(0.01,0.01))));
		
		textArea = form:add(TextArea(PanelSize(Vec2(-1,-1))));

		once = true
		
		local textEditorConfig = Config("TextEditor")
		local conf = textEditorConfig:get("LuaEdtiorFiles")
		textArea:setTextHeight(textEditorConfig:get("textHeight", 12):getInt())
		local count = 1
		while conf:exist("file"..count) do
			textArea:openFile(Text(conf:get("file"..count):getString()))
			count = count + 1
		end
		if count > 1 then
			textArea:setOpenedFile(conf:get("file1"):getString())
		end
	end
	return true
end

function update()
	if Core.getInput():getKeyHeld(Key.lctrl) and Core.getInput():getKeyDown(Key.s) then
		listString = textArea:getOpenFiles()
		local textEditorConfig = Config("TextEditor")
		textEditorConfig:get("textHeight"):setInt(textArea:getTextHeight())
		local conf = textEditorConfig:get("LuaEdtiorFiles")
		local count = #listString + 1
		while conf:exist("file"..count) do
			conf:remove("file"..count)
		end

		for i=1, #listString do
			conf:get("file"..i):setString(listString[i])
		end
		textEditorConfig:save()
	end

	form:update();

	if once then
		form:setKeyboardOwner()
		once = false
	end


	return true;
end