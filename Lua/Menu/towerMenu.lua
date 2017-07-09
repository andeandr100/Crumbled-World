require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/settings.lua")
require("Menu/towerImage.lua")
--this = SceneNode()

function restore(data)
	if data.posterForm then
		data.posterForm:setVisible(false)
		data.posterForm:destroy()
		data.posterForm = nil
	end
	
	if data.form then
		data.form:setVisible(false)
		data.form:destroy()
		data.form = nil
	end
end

function createPoster(camera)
	
	posterForm = Form(camera, PanelSize(Vec2(1,0.2), Vec2(12,9)));
	form:setName("Tower Poster form")
	posterForm:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor));
	posterForm:setLayout(FlowLayout());
	posterForm:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor));
	posterForm:setPadding(BorderSize(Vec4(MainMenuStyle.borderSize * 3)));
	posterForm:getLayout():setPanelSpacing(PanelSize(Vec2(0.001)));
	posterForm:setRenderLevel(1)
	posterForm:setVisible(false)

	--Header
	header = posterForm:add(Label(PanelSize(Vec2(1, 0.15), PanelSizeType.ParentPercent), "tower", Alignment.MIDDLE_CENTER))
	header:setTextColor(Vec3(1))
	--breakLine
	local line = posterForm:add(Panel(PanelSize(Vec2(1,0.005), PanelSizeType.ParentPercent)))
	line:setBackground(Sprite(Vec4(1,1,1,0.75)));
	
	local bottomPanel = posterForm:add(Panel(PanelSize(Vec2(-1))))
	bottomPanel:setLayout(FlowLayout(Alignment.BOTTOM_RIGHT))
	
	--right
	rightPanel = bottomPanel:add(Panel(PanelSize(Vec2(-1), Vec2(1))))
	rightPanel:setMargin(BorderSize(Vec4(0.0005)))
	rightPanel:setBackground( Sprite(Core.getTexture("icon_tower_table")))

	--left
	leftPanel = bottomPanel:add(Panel(PanelSize(Vec2(-1))))
	leftPanel:setLayout(FallLayout())

	posterForm:update();
end

function posterUpdate()
	if buildingIndex and posterForm:getVisible() then
		
		if posetHideTime >= 0 then
			posetHideTime = posetHideTime - Core.getRealDeltaTime()
			if posetHideTime < 0 then
				posterForm:setVisible(false)
			end
		end

		posterForm:update();
	end
end

function showPoster(button)
	
--	print(" -- Show Poster --")
	
	local offsetPixel = Vec2(form:getMaxPos().x + form:getMinPos().x, button:getMinPos().y) 
	local offsetSize = PanelSize(offsetPixel, PanelSizeType.Pixel)
	
	buildingIndex = tonumber(button:getTag():toString())
	if buildingIndex and buildings[buildingIndex] then
		
		local building = buildings[buildingIndex]
		----------------------
		------ Load text -----
		----------------------
		
		local backGround = Sprite(building.texture)
		backGround:setUvCoord(building.uvCoordMin, building.uvCoordMax )
		rightPanel:setBackground( backGround )
		
		header:setText( language:getText( string.lower(building.name) ))
		
		leftPanel:clear()
		
		for i, name in pairs(statsOrder) do
			if building[name] then
				local row = leftPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
				
				local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga"))
				if name=="damage" or name=="dmg" then
					icon:setUvCoord(Vec2(0.25,0.0),Vec2(0.375,0.0625))
				elseif name=="RPS" or name=="rps" then
					icon:setUvCoord(Vec2(0.25,0.25),Vec2(0.375,0.3125))
				elseif name=="range" then
					icon:setUvCoord(Vec2(0.375,0.4375),Vec2(0.5,0.5))
				elseif name=="fireDPS" then
					icon:setUvCoord(Vec2(0.75,0.25),Vec2(0.875,0.3125))
				elseif name=="burnTime" then
					icon:setUvCoord(Vec2(0.625,0.25),Vec2(0.75,0.3125))
				elseif name=="slow" then
					icon:setUvCoord(Vec2(0.875,0.375),Vec2(1.0,0.4375))
				elseif name=="bladeSpeed" then
					icon:setUvCoord(Vec2(0.125,0.25),Vec2(0.25,0.3125))
				elseif name=="dmg_range" then
					icon:setUvCoord(Vec2(0.875,0.25),Vec2(1.0,0.3125))
				else
					icon:setUvCoord(Vec2(0.0,0.25),Vec2(0.125,0.3125))
				end
				
				row:add(icon)
				row:add(Label(PanelSize(Vec2(-1)), (building[name] and tostring(building[name]) or "---"), Vec3(1.0)))
			end
		end
		
		local fillPanel = leftPanel:add(Panel(PanelSize(Vec2(-1))))
		fillPanel:setLayout(FallLayout(Alignment.BOTTOM_RIGHT))
		
		local row = fillPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
		
		
		local icon = row:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga")))
		icon:setUvCoord(Vec2(0,0), Vec2(0.125, 0.0625))
		row:add(Label(PanelSize(Vec2(-1)), (building["cost"] and tostring(building["cost"]) or "---"), Vec3(1.0)))
		
		----------------------
		------- Camera -------
		----------------------
			
		posetHideTime = -1
		posterForm:setVisible(true)
		posterForm:setFormOffset(offsetSize)

		posterUpdate()		
	end
end

function HiddePoster()
--	print(" -> Hidde Poster <-")
	posetHideTime = 0.1
end

function buttonPressed(button)
	print("\nButton pressed. tag: \""..button:getTag():toString().."\"\n\n")
	comUnit:sendTo("builder", "changeBuilding", button:getTag():toString())
end

function destroy()
	
	if form then
		print("Destroy form\n")
		form:setVisible(false)
		form:destroy()
		form = nil
	end
	
	if posterForm then
		print("Destroy posterForm\n")
		posterForm:setVisible(false)
		posterForm:destroy()
		posterForm = nil
	end

end

local function getTowerInfo(towerId, value)
	local buildingNodeBillboard = Core.getBillboard("buildings") 
	local towerNode = buildingNodeBillboard:getSceneNode(tostring(towerId).."Node")
	--print("\n\n\nShow Node\n")
	if towerNode then
		local buildingScript = towerNode:getScriptByName("tower")
		--get the cost of the new tower
		return math.round(buildingScript:getBillboard():getFloat(value)*100.0) * 0.01
	end
	return 0
end

function create()
	print("TOWERMENU:::Create()\n")
	if this:getNodeType() == NodeId.playerNode then
		
		local menuNode = this:getRootNode():addChild(SceneNode())
		--camera = Camera()
		menuNode:setSceneName("Tower menu")
	
		
		menuNode:createWork()
				
		--Move this script to the camera node
		--this:removeScript(this:getCurrentScript():getName());
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		print("TOWERMENU:::Create()->return=false\n")
		return false
	else
		statsOrder =  {"damage","rps","range","slow","fireDPS","burnTime","dmg_range"}
		buildings = {}
		buildings[1] = {name="Wall tower", cost=0}
		buildings[2] = {name="Minigun tower", range=0,damage=0,rps=0,cost=10}
		buildings[3] = {name="Arrow tower", range=0,damage=0,rps=0,cost=200}
		buildings[4] = {name="Swarm tower", range=0,damage=0, burnTime=0, fireDPS=0,cost=0}
		buildings[5] = {name="Electric tower", range=0,damage=0,rps=0, slow=-1,cost=0}
		buildings[6] = {name="Blade tower", damage=0, rps=0,cost=0}
		buildings[7] = {name="Missile tower", range=0,damage=0,dmg_range=-1,cost = 0}
		buildings[8] = {name="Quake tower", range=0,damage=0,dmg_range=-1,cost = 0}
		buildings[9] = {name="Support tower", range=0,cost = 0}
		
		local keyBinds = Core.getBillboard("keyBind")
		local keyBind = {}
		for i = 1, 9 do
			keyBind[i] = keyBinds:getKeyBind("Building " .. i)
		end
		
		local rootNode = this:getRootNode();
		local cameras = rootNode:findAllNodeByNameTowardsLeaf("MainCamera")
	
		comUnit = Core.getComUnit()
		comUnit:setName("builderMenu")
		
		posetHideTime = -1
		towerTexture = Core.getTexture("icon_tower_table")
		
		if #cameras == 1 then
			local camera = ConvertToCamera(cameras[1])
			
			form = Form( camera, PanelSize(Vec2(-1,-1)), Alignment.TOP_LEFT);
			form:setName("Tower menu form")
			form:setFormOffset(PanelSize(Vec2(0.0025, 0.04)))
			form:getPanelSize():setFitChildren(true, true);
			form:setLayout(FallLayout());
			form:setRenderLevel(1)
			form:setVisible(true)
			form:setBorder(Border(BorderSize(Vec4(0.0015,0.0015,0.0015,0.0015), true), Vec3(0.45)))
			
			local topPanel = form:add(Panel(PanelSize(Vec2(0.05,0.5))))
			topPanel:setBackground(Sprite(Vec4(Vec3(0),0.95)))
			topPanel:setLayout(FallLayout(PanelSize(Vec2(0.003), Vec2(1))))
			topPanel:setPadding(BorderSize(Vec4(0.003), true))
			topPanel:getPanelSize():setFitChildren(true, true);
	
			local buildingBillboard = Core.getBillboard("buildings")
			--buildingBillboard:

			local numBuildings = 1
			while buildingBillboard:exist(tostring(numBuildings)) do
				
				if buildings[numBuildings] == nil then
					buildings[numBuildings] = {name = "Tower"}
				end
				
				
				
				--Load a tower node
				buildings[numBuildings].towerNode = SceneNode()
	
				local scriptName = buildingBillboard:getString(tostring(numBuildings))
				print("\n\nTower id: "..numBuildings.." script name: "..scriptName.."\n")
				local luaScript = buildings[numBuildings].towerNode:loadLuaScript(scriptName)
				buildings[numBuildings].towerNode:update()

				print("Tower loaded\n")
				if luaScript then
					luaScript:setName("tower");
					buildingBillboard:setSceneNode( tostring(numBuildings).."Node", buildings[numBuildings].towerNode )
				end
				
	
				print("Tower loaded\n")					

				local start
				local x = (numBuildings-1)%3
				local y = 2-math.floor(((numBuildings-1)/3))
				start = Vec2(x/3.0, y/3.0)
				
				buildings[numBuildings].uvCoordMin=start
				buildings[numBuildings].uvCoordMax=start+Vec2(1.0/3.0,1.0/3.0)
				buildings[numBuildings].texture=towerTexture

				local button = topPanel:add(Button(PanelSize(Vec2(1,0.07), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, start, start+Vec2(1.0/3.0,1.0/3.0) ))
				--button:setBackground( Sprite( towerTexture ));
				button:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
				button:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
				button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
				button:addEventCallbackExecute(buttonPressed)
				button:addEventCallbackMouseFocusGain(showPoster)
				button:addEventCallbackMouseFocusLost(HiddePoster)
				button:setTag(tostring(numBuildings))
				
				button:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
				button:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
			
				button:setLayout(FallLayout(Alignment.BOTTOM_RIGHT))
				local label = button:add(Label(PanelSize(Vec2(-0.3),Vec2(0.8,1)), keyBind[numBuildings] and keyBind[numBuildings]:getKeyBindName(0) or "", MainMenuStyle.textColor, Alignment.MIDDLE_CENTER))
				label:setCanHandleInput(false)
				
	
				numBuildings = numBuildings + 1;
			end
	
			createPoster(camera)
			
			setRestoreData({posterForm=posterForm, form=form})
			
			settingsListener = Listener("Settings")
			settingsListener:registerEvent("Changed", settingsChanged)
			settingsChanged()
		else
			print("No camera was ever found\n");
		end
		
		for i=1, 9 do
			buildings[i].cost = getTowerInfo(i, "cost")
			if i~=1 and i~= 6 then
				buildings[i].range = getTowerInfo(i, "range")
			end
			if i~=1 and i~= 9 then
				buildings[i].damage = i==7 and getTowerInfo(i, "dmg") or getTowerInfo(i, "damage")
			end
			if i==2 or i==3 or i==5 or i==6 then
				buildings[i].rps = getTowerInfo(i, "RPS")
			end
			if i==7 or i==8 then
				buildings[i].dmg_range = getTowerInfo(i, "dmg_range")
			end
		end
		buildings[4].burnTime = getTowerInfo(4, "burnTime")
		buildings[4].fireDPS = getTowerInfo(4, "fireDPS")
		buildings[5].slow = getTowerInfo(5, "slow")
		
--		buildings[1] = {name="Wall tower", cost=35}
--		buildings[2] = {name="Minigun tower", range=5,damage=42,rps=2.5,cost=getTowerInfo(2, "cost")}
--		buildings[3] = {name="Arrow tower", range=9,damage=268,rps=1.0/1.5,cost=200}
--		buildings[4] = {name="Swarm tower", range=6.5,damage=108, burnTime=2, fireDPS=54,cost=200}
--		buildings[5] = {name="Electric tower", range=4,damage=574,rps=1, slow=0.15,cost=200}
--		buildings[6] = {name="Blade tower", damage=110, rps=math.round((1.0/2.75)*100)/100,cost=200}
--		buildings[7] = {name="Missile tower", range=7,damage=615,dmg_range=1.5,cost = 400}
--		buildings[8] = {name="Quake tower", range=2.5,damage=615,dmg_range=1.5,cost = 200}
--		buildings[9] = {name="Support tower", range=2.5,cost = 200}
		
	end
	print("TOWERMENU:::Create()->return=true\n")
	return true
end

function settingsChanged()
	local visible = Settings.towerMenu.getIsVisible()
	form:setVisible(visible)
end

function update()
	
	if form:getVisible() then
		posterUpdate()
		form:update()
	end
	
	return true
end