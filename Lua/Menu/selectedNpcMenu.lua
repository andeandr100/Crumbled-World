require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/settings.lua")
require("Game/targetSelector.lua")
require("NPC/state.lua")
--this = SceneNode()
--comUnit = ComUnit()

selectedNpcMenu = {}
function selectedNpcMenu.new(inForm, inLeftMainPanel, inTowerImagePanel)
	local self = {}
	--variabels from outside
	local form = inForm
	local mainPanel = inLeftMainPanel
	local towerImagePanel = inTowerImagePanel
	local soulListener
	local souls = {}
	local camera
	local lastSelectedMeshList = nil
	local previousSelectedNode = nil
	local currentNode = nil
	local currentIndex = nil
	local currentNetName = nil
	local counter = 0
	local soulManagerBillboard = nil
	local healtBar = nil
	local targetSelector
	local deadTimer = -1
	local keyBinds
	local keyBindIgnoreTarget
	local keyBindHighPrioritet
	local hp, hpMax, name
	
	--this = SceneNode()
	local function instalForm()
	
		leftMainPanel:setPanelSize(PanelSize(Vec2(-1),Vec2(1,1.3)))
	
		--Wall tower info panel
		--npcPanel = Panel()
		npcPanel = mainPanel:add(Panel(PanelSize(Vec2(-1))))
		npcPanel:setVisible(false)
		npcPanel:setLayout(FallLayout(PanelSize(Vec2(0,0.003))))
		
		
	end
	
	local function deselectNpc()
		--deselect previous selected mesh
		if lastSelectedMeshList then
			for index, mesh in pairs(lastSelectedMeshList) do
				mesh:setShader(Core.getShader(mesh:getShader():getName()))
			end
			lastSelectedMeshList = nil
		end
	end
	
	function self.setVisible(visible)
		npcPanel:setVisible(visible)
		deadTimer = -1
		if not visible then
			deselectNpc()
			currentNode = nil
			currentIndex = nil
			currentNetName = nil
		end
	end
	
	local function addSoul(data)
		if data ~= nil and data.id and type(data.node) == "userdata" then
			souls[data.id] = {data.node,data.netname}
			counter = counter + 1
			--print("num souls "..counter)
		end
	end
	
	local function removeSoul(data)
		if data and data.id then
			souls[data.id] = nil
			counter = counter - 1
			--print("num souls "..counter)
			
			if currentIndex == data.id then
				healtBar:setValue(0)
				healtBar:setText("0/"..hpMax)	
				deadTimer = 7
			end
		end
	end
	
	local function testFunc()
--		print("test")
	end
	
	local function init()		
		instalForm()
		
		keyBinds = Core.getBillboard("keyBind");
		keyBindIgnoreTarget = keyBinds:getKeyBind("Ignore target")
		keyBindHighPrioritet = keyBinds:getKeyBind("High priority")

		
		targetSelector = TargetSelector.new(1)
		targetSelector.setPosition(Vec3(0))
		targetSelector.setRange(512.0)
		
		camera = ConvertToCamera(this:getRootNode():findNodeByName("MainCamera"));
		soulListener = Listener("souls")
		soulListener:registerEvent("addSoul",addSoul)
		soulListener:registerEvent("removeSoul",removeSoul)
		soulListener:registerEvent("test",testFunc)	
	end
	
	
	
	local function getNpcNode()
		local nextNode = nil
		local nextIndex = nil
		local netName = nil
		local line = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
		for index, node in pairs(souls) do
			if node[1]:collisionTree(line) then
				nextNode = node[1]
				nextIndex = index
				netName = node[2]
			end
		end
		
		if previousSelectedNode ~= nextNode then
			previousSelectedNode = nextNode
			
			deselectNpc()
			
			if nextNode then
				
				--find all meshes in the node
				lastSelectedMeshList = nextNode:findAllNodeByTypeTowardsLeaf({NodeId.animatedMesh, NodeId.mesh})
				--select all meshes
				for index, mesh in pairs(lastSelectedMeshList) do
					mesh:setShader(Core.getShader(mesh:getShader():getName(), "SELECTED"))
				end
			end
		end	
		return nextNode, nextIndex, netName
	end
	
	local function getNpcInfo()
		soulManagerBillboard = soulManagerBillboard or Core.getBillboard("SoulManager")
		if soulManagerBillboard and currentIndex then
--			print("currentIndex: "..currentIndex)
			local worldMin = soulManagerBillboard:getVec2("min")
			local worldMax = soulManagerBillboard:getVec2("max")
			for x=worldMin.x, worldMax.x do
				for y=worldMin.y, worldMax.y do
					local input = soulManagerBillboard:getString("souls"..x.."/"..y)
					for str in string.gmatch(input, "([^|]+)") do
--						print("npc Soul info: "..str)
						local index = string.match(str, "([^,]+)")
						
						if tonumber(index) == currentIndex then
							local index,x1,y1,z1,x2,y2,z2,dist,hp,hpmax,team,npcState,name = string.match(str, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
							return hp, hpmax, name, dist
						end
					end
					
				end
			end			
		end
	end
	
	local function isMouseInMainPanel()
		return billboardStats and (billboardStats:getPanel("MainPanel") == Core.getPanelWithMouseFocus()) or false
	end
	
	local function ignoreNpc()
		if currentIndex then
			print("ignoreNpc()")
			comUnit:sendTo("builder","addPrioEvent",tabToStrMinimal( {netName=currentNetName,event=0} ))
			comUnit:sendTo(currentIndex,"addState",tostring(state.highPriority)..";0")
			comUnit:sendTo(currentIndex,"addState",tostring(state.ignore)..";1")
			if Core.isInMultiplayer() then
				comUnit:sendNetworkSyncSafeTo( Core.getNetworkNameOf(currentIndex),"addState",tostring(state.highPriority)..";0")
				comUnit:sendNetworkSyncSafeTo( Core.getNetworkNameOf(currentIndex),"addState",tostring(state.ignore)..";0")
			end
		end
	end
	
	local function highPriorityTarget()
		if currentIndex then
			print("highPriorityTarget()")
			comUnit:sendTo("builder","addPrioEvent",tabToStrMinimal( {netName=currentNetName,event=1} ))
			comUnit:sendTo(currentIndex,"addState",tostring(state.ignore)..";0")
			comUnit:sendTo(currentIndex,"addState",tostring(state.highPriority)..";1")
			if Core.isInMultiplayer() then
				comUnit:sendNetworkSyncSafeTo( Core.getNetworkNameOf(currentIndex),"addState",tostring(state.ignore)..";0")
				comUnit:sendNetworkSyncSafeTo( Core.getNetworkNameOf(currentIndex),"addState",tostring(state.highPriority)..";1")
			end
		end
	end
	
	local function initMenu()
		hp, hpMax, name, distance = getNpcInfo()
		print("set size to fit npc panel")
		leftMainPanel:setPanelSize(PanelSize(Vec2(-1),Vec2(1,0.30)))
		if hp and hpMax and name then
			header:setText(Text("<b>")+language:getText(name))
		
			npcPanel:clear()
			
			local row1 = npcPanel:add(Panel(PanelSize(Vec2(-1,0.025))))			
			
			local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga"))
			icon:setUvCoord(Vec2(0.375,0),Vec2(0.5,0.0625))
			row1:add(icon)
			
			healtBar = row1:add(ProgressBar(PanelSize(Vec2(-1)), Text(tostring(math.max(0,hp)).."/"..hpMax), math.max(0,hp)/hpMax ))	
			healtBar:setTextColor(Vec3(1))
			healtBar:setColor(Vec4(0.5*0.7, 1.1*0.7, 0.5*0.7, 0.75), Vec4(0.0, 0.65*0.7, 0.0, 0.75))
			healtBar:setInnerColor(Vec4(Vec3(0), 1), Vec4(Vec3(0), 1))

			
			local row2 = npcPanel:add(Panel(PanelSize(Vec2(-1,-1))))
			row2:setLayout(GridLayout(1,5))
			
			local texture = Core.getTexture("icon_table.tga")
			local button = row2:add(Button(PanelSize(Vec2(-1), Vec2(1.0,1.0),PanelSizeType.ParentPercent), ButtonStyle.SIMPLE, texture, Vec2(0.5,0), Vec2(0.625, 0.0625)))
			
			button:setToolTip(language:getText("ignore this NPC"))
			button:addEventCallbackExecute(ignoreNpc)	
			button:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
			button:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
			
			
			--fill empty space
			row2:add(Panel(PanelSize(Vec2(-1))))
			row2:add(Panel(PanelSize(Vec2(-1))))
			row2:add(Panel(PanelSize(Vec2(-1))))
			
			
			button = row2:add(Button(PanelSize(Vec2(-1), Vec2(1.0,1.0),PanelSizeType.ParentPercent), ButtonStyle.SIMPLE, texture, Vec2(0.625,0.4375), Vec2(0.75, 0.5)))
			button:setToolTip(language:getText("high priority"))
			button:addEventCallbackExecute(highPriorityTarget)	
			button:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
			button:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
		end
	end	
	
	
	function self.update()
		
		if deadTimer > 0  then
			deadTimer = deadTimer - Core.getDeltaTime()
			if deadTimer < 0 then
				self.setVisible(false)
				form:setVisible(false)
			end
		end
				
		
		local nextNode = nil
		local nextIndex = nil
		local netName = nil
		if isMouseInMainPanel() then
			nextNode, nextIndex, netName = getNpcNode()
		end
		
		
		
		if Core.getInput():getMouseDown(MouseKey.left) and isMouseInMainPanel() then
			if keyBindIgnoreTarget:getHeld() then
				if nextNode then
					comUnit:sendTo("builder","addPrioEvent",tabToStrMinimal( {netName=netName,event=0} ))
					comUnit:sendTo(nextIndex,"addState",tostring(state.highPriority)..";0")
					comUnit:sendTo(nextIndex,"addState",tostring(state.ignore)..";1")
					if Core.isInMultiplayer() then
						comUnit:sendNetworkSyncSafeTo( Core.getNetworkNameOf(nextIndex),"addState",tostring(state.highPriority)..";0")
						comUnit:sendNetworkSyncSafeTo( Core.getNetworkNameOf(nextIndex),"addState",tostring(state.ignore)..";0")
					end
				end
			elseif keyBindHighPrioritet:getHeld() then
				if nextNode then
					comUnit:sendTo("builder","addPrioEvent",tabToStrMinimal( {netName=netName,event=1} ))
					comUnit:sendTo(nextIndex,"addState",tostring(state.ignore)..";0")
					comUnit:sendTo(nextIndex,"addState",tostring(state.highPriority)..";1")
					if Core.isInMultiplayer() then
						comUnit:sendNetworkSyncSafeTo( Core.getNetworkNameOf(nextIndex),"addState",tostring(state.ignore)..";0")
						comUnit:sendNetworkSyncSafeTo( Core.getNetworkNameOf(nextIndex),"addState",tostring(state.highPriority)..";1")
					end
				end
			else
				currentNode = nextNode
				currentIndex = nextIndex
				deadTimer = -1
				if currentNode then
				
					setVisibleClass(self)
					--force a resize
					form:setVisible(false)
					form:setVisible(true)
					header:setText("")
					currentNode:addChild(selectedCamera:toSceneNode())
					
					initMenu()
					
				else
					currentNode = nil
					currentIndex = nil
				end
			end
		end
		
		if currentNode then
			hp, hpMax, name, distance = getNpcInfo()
			if hp and hpMax and name and deadTimer < 0 then
				healtBar:setValue(math.max(0,hp)/hpMax)
				healtBar:setText(tostring(math.max(0,hp)).."/"..hpMax)	
			end
			
			
			local camMatrix = Matrix();
			local camPos = Vec3(0,6,-4)
			camMatrix:createMatrix((camPos-Vec3(0,1.2,0)):normalizeV(), Vec3(0,1,0))
			camMatrix:setPosition(camPos)
			selectedCamera:setLocalMatrix(camMatrix)
		end
		
		soulListener:pushEvent("test")
	end
	
	init()
	
	return self
end