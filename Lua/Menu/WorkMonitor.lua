--this = SceneNode()

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

function create()
	if this:getNodeType() == NodeId.playerNode then
		local menuNode = this:getRootNode():addChild(SceneNode())
		--camera = Camera()
		menuNode:setSceneName("Work monitor")
		--Create a worker
		menuNode:createWork()
		--Move this script to the camera node
		--this:removeScript(this:getCurrentScript():getName());
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		return false
	else
		local rootNode = this:getRootNode();
		camera = ConvertToCamera(rootNode:findNodeByName("MainCamera"));
	
		if camera then
			form = Form( camera, PanelSize(Vec2(-1)), Alignment.TOP_RIGHT);
			form:setName("Workmonitor form")
			form:setLayout(FlowLayout());
			form:setRenderLevel(10)
			form:add(WorkMonitor(PanelSize(Vec2(-1))))
			form:setVisible(false)
		end
	end
	return true
end

function update()
	if Core.getInput():getKeyDown(Key.F6) then
		form:setVisible(not form:getVisible())
	end
	if form:getVisible() then
		form:update();
	end
	return true;
end