--this = SceneNode()

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

function create()
	
	--Protection in multiplayer environment where multiple instances of this script is loaded
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	if not DEBUG or ( node == nil and this:getSceneName() ~= "Stats menu" ) or ( node and node:getClientId() ~= 0 ) then
		return false
	end
	
	Core.setScriptNetworkId("FPS")
	local rootNode = this:getRootNode();
	local cameras = rootNode:findAllNodeByNameTowardsLeaf("MainCamera");

	if #cameras == 1 then
		local camera = ConvertToCamera(cameras[1]);
		form = Form(camera, PanelSize(Vec2(-1,0.05), Vec2(7.5,1)), Alignment.TOP_RIGHT);
		form:setName("FPS form")
		form:setRenderLevel(1)
		form:setLayout(FlowLayout());
		form:getLayout():setPanelSpacing(PanelSize(Vec2(0.001)));
		form:setFormOffset(PanelSize(Vec2(0.005,0.05)));
		form:setVisible(true)
		
		local sizeX = Core.isInMultiplayer() and -0.33 or -0.5
		
		label = form:add(Label(PanelSize(Vec2(sizeX,-1)),"FPS"));
		label:setTextColor(Vec3(1));
		
		labelMs = form:add(Label(PanelSize(Vec2(sizeX,-1)),"ms"));
		labelMs:setTextColor(Vec3(1));
		
		if Core.isInMultiplayer() then
			labelPing = form:add(Label(PanelSize(Vec2(-1,-1)),"ping"));
			labelPing:setTextColor(Vec3(1));
			client = Core.getNetworkClient()
		end
	else
		print("ERROR To many cameras found\n")
	end
	
	deltaTimeMs = math.floor(Core.getRealDeltaTime() * 100000)/100
	updateTextTimer = 0.25
	frameCount = 50.0
	print("done\n")
	return true
end

local function setGameSpeed(speed)
	if Core.isInMultiplayer() then
		Core.getNetworkClient():writeSafe("CMD-GameSpeed:"..speed)
	else
		Core.setTimeSpeed(speed)
	end
end

function update()
	
	local p = 1.0 / Core.getRealDeltaTime()
	frameCount = (frameCount*0.99) + (p*0.01)
	deltaTimeMs = deltaTimeMs * 0.9 + Core.getRealDeltaTime() * 10000 * 0.1
	
	updateTextTimer = updateTextTimer - Core.getRealDeltaTime()
	if updateTextTimer < 0 then
		updateTextTimer = 0.25
		
		label:setText(tostring(math.floor(frameCount)))
	
		labelMs:setText(tostring(math.floor(deltaTimeMs)/10).."ms")
		
		if labelPing then
			labelPing:setText(math.floor(client:getPing()*1000).."ping")
		end
	end
	form:update()
	
	if DEBUG then
		if Core.getInput():getKeyPressed(Key.F1) then
			setGameSpeed(2.0)
		elseif Core.getInput():getKeyPressed(Key.F2) then
			setGameSpeed(1.0)
		elseif Core.getInput():getKeyPressed(Key.F3) then
			setGameSpeed(0.5)
		elseif Core.getInput():getKeyPressed(Key.F4) then
			setGameSpeed(0.25)
		elseif Core.getInput():getKeyPressed(Key.kp_plus) then
			setGameSpeed(Core.getTimeSpeed()*2.0)
		elseif Core.getInput():getKeyPressed(Key.kp_minus) then
			setGameSpeed(Core.getTimeSpeed()*0.5)
		end
	end
	
	return true
end