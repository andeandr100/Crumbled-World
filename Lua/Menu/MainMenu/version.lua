--this = SceneNode()

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
	end
end

function create()
	this:loadLuaScript("settings.lua")
	
	
	local versionCamera = Camera("Version camera", false, 512,128 )
	
	form = Form( versionCamera, PanelSize(Vec2(-1,-1)), Alignment.TOP_LEFT);
	form:setBackground(Gradient(Vec4(Vec3(0),0.85), Vec4(Vec3(0),0.7)));
	form:setLayout(FallLayout());
	form:setRenderLevel(1)
	
	form:add(Label(PanelSize(Vec2(-1, -0.9)), "v0.9.4", Vec3(1), Alignment.MIDDLE_CENTER ))
	form:update()
	versionCamera:render()
	

	local rootNode = this:getRootNode()
	local model = rootNode:findNodeByName("hanging_sign")
	
	if model then
		local meshes = model:findAllNodeByNameTowardsLeaf("Plane")
		for i=1, #meshes do
			local shader = meshes[i]:getShader()
			meshes[i]:setTexture(shader, versionCamera:getTexture(), 0)
		end
	else	
		
		local camera = this:getRootNode():findNodeByName("MainCamera")
		--camera = Camera()
	
		if camera then
			form = Form(camera, PanelSize(Vec2(1,0.025)), Alignment.BOTTOM_LEFT);
			
			form:setRenderLevel(6)
			
			local version = Core.getGlobalBillboard("version"):getString("version")
			
			form:add(Label(PanelSize(Vec2(-1)), "v"..version, Vec3(1)))
	
		end
	end
	return true
end

function update()
	
	if form then
		form:update()
	end
	return true
end