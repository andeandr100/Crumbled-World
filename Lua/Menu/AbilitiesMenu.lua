require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()

AbilitesMenu = {}
function AbilitesMenu.new()
	local self = {}
	local posterForm	
	local keyBindBoostBuilding = Core.getBillboard("keyBind"):getKeyBind("Boost")
	local showBoostableTowers = false
	local buildingNodeBillboard = Core.getBillboard("buildings")
	local billboardStats = Core.getBillboard("stats")
	local comUnit
	local camera
	local towerHasBeenBoostedThisWave = false
	local comUnitTable = {}
	local boostButton
	local boostButtonPressed = false
	local slowButton
	local damageButton
	
	function self.destroy()
		if posterForm then
			print("Destroy posterForm\n")
			posterForm:setVisible(false)
			posterForm:destroy()
			posterForm = nil
		end
	end
	
	local function init()
		local rootNode = this:getRootNode();
		local cameras = rootNode:findAllNodeByNameTowardsLeaf("MainCamera")
		
		if #cameras == 1 then
			camera = ConvertToCamera(cameras[1])
			
			posterForm = Form(camera, PanelSize(Vec2(1,0.1), Vec2(3.4,1)));
			
			posterForm:setName("Abilities form")
			posterForm:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor));
			posterForm:setLayout(FlowLayout());
			posterForm:getLayout():setPanelSpacing(PanelSize(Vec2(0.001)));
			posterForm:setRenderLevel(1)
			posterForm:setVisible(true)
			posterForm:getPanelSize():setFitChildren(true, true);
			posterForm:setFormOffset(PanelSize(Vec2(0.0, 0.0025)))
			posterForm:setAlignment(Alignment.BOTTOM_CENTER)
			
			
			--
			-- Add buttons  for the 3 abbilities 
			--
			local towerTexture = Core.getTexture("icon_table.tga")
				
			boostButton = posterForm:add(Button(PanelSize(Vec2(1,0.07), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, Vec2(0.125,0.4375), Vec2(0.25,0.5) ))
			--BoostButton:setBackground( Sprite( towerTexture ));
			boostButton:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
			boostButton:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			boostButton:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
			boostButton:addEventCallbackExecute(self.buttonPressed)		
			boostButton:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
			boostButton:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
			boostButton:setToolTip(Text("Boos tower, [<b>" .. keyBindBoostBuilding:getKeyBindName(0) .. "</b>]"))
			boostButton:setTag("boost")
			
			slowButton = posterForm:add(Button(PanelSize(Vec2(1,0.07), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, Vec2(), Vec2(1.0/3.0,1.0/3.0) ))
			slowButton:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
			slowButton:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			slowButton:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
			slowButton:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
			slowButton:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
			
			damageButton = posterForm:add(Button(PanelSize(Vec2(1,0.07), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, Vec2(), Vec2(1.0/3.0,1.0/3.0) ))
			damageButton:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
			damageButton:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			damageButton:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))	
			damageButton:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
			damageButton:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
			
			posterForm:update();
		end
		
		
		Core.setScriptNetworkId("AbilitiesMenu")
		comUnit = Core.getComUnit();
		comUnit:setName("AbilitiesMenu")
		comUnit:setCanReceiveTargeted(true);
		comUnit:setCanReceiveBroadcast(true);
		

		comUnitTable["waveChanged"] = self.waveChanged	
	end
	
	function self.buttonPressed(button)
		--button = Button()
		if button:getTag():toString() == "boost" then
			boostButtonPressed = true
		end
	end
	
	function self.waveChanged(param)
		towerHasBeenBoostedThisWave = false
		boostButton:setEnabled(true)
	end

	local function setGlowColor(node, color)
		if node then
			local meshList = node:findAllNodeByTypeTowardsLeaf({NodeId.mesh, NodeId.animatedMesh})
			for aKey, mesh in pairs(meshList) do
				local shader = mesh:getShader()
				local definitions = shader:getDefinitions()
				definitions[#definitions+1] = "GLOW"
				
				shader = Core.getShader( shader:getName(), definitions )
				mesh:setShader( shader )
				mesh:setUniform(shader, "glowColor", color )		
			end
		end
	end
	
	local function setNodeNotBoostable(node)
		if node then
			local meshList = node:findAllNodeByTypeTowardsLeaf({NodeId.mesh, NodeId.animatedMesh})
			for aKey, mesh in pairs(meshList) do
				local shader = mesh:getShader()
				local definitions = shader:getDefinitions()
				local i = 1
				while #definitions >= i do
					if definitions[i] == "GLOW" then
						table.remove(definitions, i)
					else
						i = i + 1
					end
				end
				mesh:setShader( Core.getShader( mesh:getShader():getName(), definitions ) )
			end
		end
	end
	
	local function showAllTowerThatCanBeBoosted(show)
		if showBoostableTowers == show then
			return
		end
		
		local playerNode = this:findNodeByType(NodeId.playerNode)
		local buildNode = playerNode:findNodeByType(NodeId.buildNode)
		local buildingList = buildNode and buildNode:getBuildingList() or {}
		--buildNode = buildNode()

		showBoostableTowers = show
		for key, node in pairs(buildingList) do
			if show then
				local script = node:getScriptByName("tower")
				local scriptBilboard = script and script:getBillboard() or nil
				if script and scriptBilboard and scriptBilboard:getString("Name") ~= "Wall tower" and scriptBilboard:getBool("isNetOwner") then
					setGlowColor( node, Vec3(0.05,0.15,0.05) )
				end
			else
				setNodeNotBoostable(node)
			end
		end	
	end
	
	local function posterUpdate()
		if posterForm:getVisible() then
			posterForm:update();
		end
	end
	
	
	function self.restore(data)
		if data.posterForm then
			data.posterForm:setVisible(false)
			data.posterForm:destroy()
			data.posterForm = nil
		end
	end
	
	local function isMouseInMainPanel()
		return billboardStats:getPanel("MainPanel") == Core.getPanelWithMouseFocus()
	end
	
	local function handleUpgrade(building,buyMessage,paramMessage)
		if building then
			local buildingScript = building:getScriptByName("tower")
			local clientId = building:getPlayerNode():getClientId()
			comUnit:sendTo("builder"..clientId, "buildingSubUpgrade", tabToStrMinimal({netId=buildingScript:getNetworkName(),cost=0,msg=buyMessage,param=paramMessage}))
		end
	end

	
	local function boostTower(building)
		--Boost the tower
		--Note the boost is upgrade2 in the tower upgrades
		local buildingScript = building:getScriptByName("tower")
		
		if building and buildingScript then	
			local buildingBillBoard = buildingScript:getBillboard()
			
			if buildingBillBoard and buildingBillBoard:getBool("isNetOwner") then
				handleUpgrade(building, "upgrade2", "1")
			end
		end
	end
	
	function self.update()
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			--print("selectedMenu: msg="..msg.message)
			if comUnitTable[msg.message]~=nil then
			 	comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		
		if posterForm:getVisible() then
			posterUpdate()
			posterForm:update()
		end
		
		if buildingNodeBillboard:getBool("inBuildMode") == false then
			local boostSelected = boostButtonPressed or keyBindBoostBuilding:getHeld()
			buildingNodeBillboard:setBool("AbilitesBeingPlaced", boostSelected)
			showAllTowerThatCanBeBoosted(boostSelected and towerHasBeenBoostedThisWave==false)
	
			
			if towerHasBeenBoostedThisWave == false and Core.getInput():getMouseDown(MouseKey.left) and boostSelected and buildingNodeBillboard:getBool("canBuildAndSelect") and isMouseInMainPanel() then
				local playerNode = this:findNodeByType(NodeId.playerNode)
				local buildNode = playerNode:findNodeByType(NodeId.buildNode)
				--buildNode = buildNode()
				if buildNode then
					
					local building = buildNode:getBuldingFromLine(camera:getWorldLineFromScreen(Core.getInput():getMousePos()))
					if building then
						print("boost tower")
						boostTower(building)
						setGlowColor( building, Vec3(0.05,0.15,0.05) )
						towerHasBeenBoostedThisWave = true
						boostButton:setEnabled(false)
						buildingNodeBillboard:setBool("AbilitesBeingPlaced", false)
					end
				end
			end
		else
			showAllTowerThatCanBeBoosted(false)
		end
		
		if Core.getInput():getMouseDown(MouseKey.left) or Core.getInput():getMouseDown(MouseKey.right) or Core.getInput():getKeyDown(Key.escape) then
			boostButtonPressed = false
		end
	
		return true
	end
	
	
	init()
	return self
end
function create()
	abilitesMenu = AbilitesMenu.new()
	update = abilitesMenu.update
	destroy = abilitesMenu.destroy
	restore = abilitesMenu.restore
	return true
end