--this = SceneNode()

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
	end
end

function create()
	return false
--	if this:getNodeType() == NodeId.playerNode then
--		local menuNode = this:getRootNode():addChild(SceneNode())
--		--camera = Camera()
--		menuNode:setSceneName("Stats menu")
--		menuNode:createWork()	
--		--Move this script to the camera node
--		--this:removeScript(this:getCurrentScript():getName());
--		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
--		return false
--	else
--		local rootNode = this:getRootNode();
--		local camera = ConvertToCamera( rootNode:findNodeByName("MainCamera") );
--	
--		if camera then
--			
--			form = Form( camera, PanelSize(Vec2(0.35,0.05)), Alignment.TOP_LEFT);
--			form:setName("Console form")
--			form:setBackground(Sprite(Vec4(0.1, 0.1, 0.1, 0.7)));
--			form:setLayout(FlowLayout());
--			form:setBorder(Border(BorderSize(Vec4(0.005)), Vec4(0,0,0,0),Vec4(0,0,0,1)));
--			form:setPadding(BorderSize(Vec4(0.005)));
--			form:getLayout():setPanelSpacing(PanelSize(Vec2(0.001)));
--			form:setFormOffset(PanelSize(Vec2(0.005), Vec2(1)));
--			form:setVisible(false)
--			form:setRenderLevel(3)
--			form:setCanHandleInput(false)
--			--Render this menu over all other forms
----			local formList = form.getAllFormFromCamera(camera)
----			local localWork = this:createWork()
----			for i=0, formList:size()-1 do
----				localWork:addDependency( formList:item(i):getWorkUpdater() )
----			end
--			
--			textField = form:add(TextField(PanelSize(Vec2(-1))))
--			textField:addEventCallbackExecute(executeCommand)
--			
--			comUnit = Core.getComUnit()
--			consoleCommands = SceneNode()
--			consoleCommands:loadLuaScript("Menu/consoleCommands.lua")
--			this:addChild(consoleCommands)
--		else
--			return false
--		end
--	end
--	return true
end
--
--function executeCommand(textField)
--	comUnit:sendTo("console","run",textField:getText())
--	textField:setText(Text(""))
--end

function update()
--	if #consoleCommands:getAllScript()==0 then
--		--it crashed restore the script
--		consoleCommands:loadLuaScript("Menu/consoleCommands.lua")
--	end
--	if Core.getInput():getKeyPressed(Key.grave) then
--		form:setVisible(not form:getVisible())
--		if form:getVisible() then
--			textField:setKeyboardOwner()
--			textField:setText(Text(""))
--		end
--	end
--	form:update()
--	return true
	return false
end