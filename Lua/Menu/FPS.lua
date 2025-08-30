--this = SceneNode()

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

function create()
--	return true

	--Protection in multiplayer environment where multiple instances of this script is loaded
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	if ( node == nil and this:getSceneName() ~= "Stats menu" ) or ( node and node:getClientId() ~= 0 ) then
		return false
	end
	
	scriptGroupes = {}
	
	scriptGroupes[1] = {name="NPC",scripts="NPC;npc_*"}
	scriptGroupes[2] = {name="Tower",scripts="tower.shop.*"}
	scriptGroupes[3] = {name="Camera",scripts="Camera;MainCamera"}
	scriptGroupes[4] = {name="Form",scripts="Form:*"}
	
	statistics = Statistics()
	
	
	
	Core.setScriptNetworkId("FPS")
	local rootNode = this:getRootNode();
	local cameras = rootNode:findAllNodeByNameTowardsLeaf("MainCamera");

	if #cameras == 1 then
		local camera = ConvertToCamera(cameras[1]);
		form = Form(camera, PanelSize(Vec2(0.45,0.4), PanelSizeType.WindowPercentBasedOnY), Alignment.TOP_RIGHT, "FpsForm");
		form:setName("FPS form")
		form:setRenderLevel(1)
		form:setLayout(FallLayout());
--		form:setFormOffset(PanelSize(Vec2(0.005,0.05)));
		form:setBackground(Sprite(Vec4(0.1,0.1,0.1,0.5)))
		form:setVisible(true)

		label = form:add(Label(PanelSize(Vec2(1,0.06),PanelSizeType.ParentPercent),"FPS", Vec3(1)))
		labelMs = form:add(Label(PanelSize(Vec2(1,0.06),PanelSizeType.ParentPercent),"ms", Vec3(1)))
		workLabel = form:add(Label(PanelSize(Vec2(1,0.06),PanelSizeType.ParentPercent),"ms", Vec3(1)))
		
--		workLabel:setBackground(Sprite(Vec3(1,0,0)))
		
		local tablePanel = form:add(Panel(PanelSize(Vec2(1,0.4),PanelSizeType.ParentPercent)))
		tablePanel:setLayout(FlowLayout())
--		tablePanel:setBackground(Sprite(Vec3(1)))
		local columNames = {"Name","min","avg","max","Num","total"}
		local rowNames = {"thread"}
		for i=1, #scriptGroupes do
			statistics:addScriptGroup(scriptGroupes[i].name, scriptGroupes[i].scripts )
			rowNames[#rowNames+1] = scriptGroupes[i].name
		end
		rowNames[#rowNames+1] = "ungrouped"
		local columns = {}
		labelTable = {}
		for i=1, #columNames do
			columns[i] = tablePanel:add(Panel(PanelSize(Vec2(0.83/#columNames + (i==1 and 0.15 or 0),1),PanelSizeType.ParentPercent)))
			columns[i]:setLayout(FallLayout())
			local headerName = columns[i]:add(Label(PanelSize(Vec2(1,1/(#rowNames+1)),PanelSizeType.ParentPercent),columNames[i],Vec3(1)))
			headerName:setBackground(Sprite(Vec3(0.05)))
	
			labelTable[i] = {}
			for n=1, #rowNames do
				local labelText = i==1 and rowNames[n] or "X"
				labelTable[i][n] = columns[i]:add(Label(PanelSize(Vec2(0.99,0.99/(#rowNames+1)),PanelSizeType.ParentPercent),labelText,Vec3(1)))
				labelTable[i][n]:setBackground(Sprite(i==1 and Vec3(0.05) or Vec3(0.2)))
			end
		end
		
		-------------------------------------
		tablePanel = form:add(Panel(PanelSize(Vec2(1,0.41),PanelSizeType.ParentPercent)))
		tablePanel:setLayout(FlowLayout())
		
		columns = {}
		secondTable = {}
		local rowCount = 9
		for i=1, #columNames do
			columns[i] = tablePanel:add(Panel(PanelSize(Vec2(0.84/#columNames + (i==1 and 0.15 or 0),1),PanelSizeType.ParentPercent)))
			columns[i]:setLayout(FallLayout())
			local headerName = columns[i]:add(Label(PanelSize(Vec2(1,1/rowCount),PanelSizeType.ParentPercent),columNames[i],Vec3(1)))
			headerName:setBackground(Sprite(Vec3(0.05)))
	
			secondTable[i] = {}
			for n=1, (rowCount-1) do
				secondTable[i][n] = columns[i]:add(Label(PanelSize(Vec2(1,1/rowCount),PanelSizeType.ParentPercent),"-",Vec3(1)))
				secondTable[i][n]:setBackground(Sprite(i==1 and Vec3(0.05) or Vec3(0.2)))
			end
		end

--		if Core.isInMultiplayer() then
--			labelPing = form:add(Label(PanelSize(Vec2(-1,-0.2),PanelSizeType.ParentPercent),"ping"));
--			labelPing:setTextColor(Vec3(1));
--			client = Core.getNetworkClient()
--		end
	else
		abort("ERROR To many cameras found\n")
	end
	
	deltaTimeMs = 16
	updateTextTimer = 0.25
	frameCount = 50.0
	return true
end

local function setGameSpeed(speed)
	if Core.isInMultiplayer() then
		Core.getNetworkClient():writeSafe("CMD-GameSpeed:"..speed)
	else
		Core.setTimeSpeed(speed)
	end
end

function intToString(value)
	return value == nil and "-" or tostring(math.floor(value))
end

function numToString(value)
	return value == nil and "-" or tostring(math.floor(value*1000*10)/10)
end

function labelText(name, minValue, avgValue, maxValue, count)
	return name ..  " min: " .. numToString(minValue) .. "ms, avg: ".. numToString(avgValue) .. "ms, max: " .. numToString(maxValue) .. "ms, count: " .. intToString(count) .. "x"
end

function updateTableValues(row, min, avg, max, count)
	labelTable[2][row]:setText(numToString(min))
	labelTable[3][row]:setText(numToString(avg))
	labelTable[4][row]:setText(numToString(max))
	labelTable[5][row]:setText(intToString(count))
	labelTable[6][row]:setText(numToString(avg*count))
end

function updateSecondTableValues(row, name, min, avg, max, count)
	local groupData = secondTable[1]
	local labelData = secondTable[1][row]
	secondTable[1][row]:setText(name)
	secondTable[2][row]:setText(numToString(min))
	secondTable[3][row]:setText(numToString(avg))
	secondTable[4][row]:setText(numToString(max))
	secondTable[5][row]:setText(intToString(count))
	secondTable[6][row]:setText(numToString(avg*count))
end

function update()
	
	statistics:update()
	
	local p = 1.0 / Core.getRealDeltaTime()
	frameCount = (frameCount*0.99) + (p*0.01)
	deltaTimeMs = deltaTimeMs * 0.9 + Core.getRealDeltaTime() * 0.1
	
	if Core.getInput():getKeyPressed(Key.t) then
		form:setVisible( not form:getVisible() )
		updateTextTimer = -1
	end
	
	if form:getVisible() then	
		updateTextTimer = updateTextTimer - Core.getRealDeltaTime()
		if updateTextTimer < 0 then
			updateTextTimer = 0.5
			
			label:setText( "FPS: " .. intToString(frameCount))
			labelMs:setText( "Delta: " .. numToString(deltaTimeMs).."ms")
			workLabel:setText( "Work Count: " .. intToString(statistics:getAverageNumWork()) .. ", Nodes: " .. this:getRootNode():countAllNodeInTree() )
			

			updateTableValues(1, statistics:getMinThreadTime(), statistics:getAverageThreadTime(), statistics:getMaxThreadTime(), statistics:getNumThreads() )
			for i=1, #scriptGroupes do
				local groupName = scriptGroupes[i].name
				local groupValues = statistics:getScriptGroupStatistics(groupName)
				updateTableValues(1+i,  groupValues.minTime, groupValues.time, groupValues.maxTime, groupValues.scriptCount )
			end
			local ungroupValues = statistics:getUngroupedScriptStatistics()
			updateTableValues(2+#scriptGroupes,  ungroupValues.minTime, ungroupValues.time, ungroupValues.maxTime, ungroupValues.scriptCount )
			
			
			local secondTableVal = statistics:getMostCostlyScriptStatistics()
			for n=1, math.min( #secondTable[1], #secondTableVal) do
				
				updateSecondTableValues(n, secondTableVal[n].name, secondTableVal[n].minTime, secondTableVal[n].time, secondTableVal[n].maxTime, secondTableVal[n].scriptCount)
			end
			
--			if labelPing then
--				labelPing:setText("Ping: " .. math.floor(client:getPing()*1000).."ms")
--			end
		end
		if form then
			form:update()
		end
	end
	
	if Core.getInput():getKeyPressed(Key.F1) then
		setGameSpeed(0.05)
	elseif Core.getInput():getKeyPressed(Key.F2) then
		setGameSpeed(0.1)
	elseif Core.getInput():getKeyPressed(Key.F3) then
		setGameSpeed(0.5)
	elseif Core.getInput():getKeyPressed(Key.F4) then
		setGameSpeed(1.0)
	elseif Core.getInput():getKeyPressed(Key.F5) then
		setGameSpeed(3.0)
	elseif Core.getInput():getKeyPressed(Key.kp_plus) then
		setGameSpeed(Core.getTimeSpeed()*2.0)
	elseif Core.getInput():getKeyPressed(Key.kp_minus) then
		setGameSpeed(Core.getTimeSpeed()*0.5)
	end
	
	return true
end