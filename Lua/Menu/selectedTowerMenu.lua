require("Game/builderUpgrader.lua")
require("Game/targetArea.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/settingsCombobox.lua")
require("Menu/settings.lua")
require("Menu/SelectedMenu/WallTowerPanel.lua")
require("Menu/SelectedMenu/UpgradePanel.lua")
require("Menu/SelectedMenu/TowerInfoPanel.lua")
require("Menu/SelectedMenu/DamageInfoPanel.lua")
require("Menu/SelectedMenu/TowerBarPanel.lua")


--comUnit = ComUnit()
--buildingNodeBillboard = Billboard()
--buildingBillBoard = Billboard()
--header = Label()
--selectedCamera = Camera()
--camera = Camera()
--this = SceneNode()
--esqKeyBind = KeyBind()
--setVisibleClass = Function()
--tonumber = Function()

selectedtowerMenu = {}
function selectedtowerMenu.new(inCamera)
	local self = {}
	--variabels from outside
	local formWallTower
	local headerWallTower
	local formTower 
	local headerTower
	local towerImagePanel = nil	
	local gameValues = GameValues.new()
	local header = nil
	local camera = inCamera
	
	--local variabels
	local keyBinds
	local keyBindUpgradeBuilding
	local keyBindSellBulding
	local wallTowerPanel
	local wallPanelInit
	local towerPanel
	local upgradePanel
	local infoPanel
	local towerBarPanel
	
	local imagePanel
	local damageInfoPanel
	local currentTowerName = ""
	
	local buildingBillBoard = nil
	local buildingScript = nil
	local callChangeWave = -1
	local targetArea = TargetArea.new()
	local updateBoostTimer = {}
	
	local billboardStats = Core.getBillboard("stats")
	
	local function sellTower(button)
		local playerNode = this:findNodeByType(NodeId.playerNode)
		local buildNode = playerNode:findNodeByType(NodeId.buildNode)
		
		if buildNode and buildingLastSelected then
			local buildingScript = buildingLastSelected:getScriptByName("tower")
			if buildingScript then--crash protection, when the tower has crashed
				
				
				if buildingBillBoard:getString("Name") == "tower.shop.WallTower.name" then
					senToBuildNode( "SELLTOWER", buildingScript:getNetworkName())					
				else
					
					local netName = buildingScript:getNetworkName()				
					local tab = {netName = netName, upgToScripName = "Tower/WallTower.lua", tName = (netName.."V3"), playerId = Core.getPlayerId(), buildCost=0}
					print("Sold tower: "..netName)
					senToBuildNode( "UpgradeWallTower", tabToStrMinimal(tab) )
					senToBuildNode( "addRebuildTower", tabToStrMinimal({upp=tab,down={towerName=netName,wallTowerName=(netName.."V3")}}) )
					local billBoard = buildingScript:getBillboard()
				end	
			end
		end
	end
	
	local function createForm()
		
		local panelSpacing = PanelSize(Vec2(0.005),Vec2(1))
		local form = Form( camera, PanelSize(Vec2(0.225,-1),PanelSizeType.WindowPercentBasedOnY), Alignment.BOTTOM_RIGHT);
		form:setName("SelectedMenu form")
		form:getPanelSize():setFitChildren(false,true)
		form:setBackground(Gradient(Vec4(Vec3(0),0.85), Vec4(Vec3(0),0.7)));
		form:setLayout(FallLayout(panelSpacing));
		form:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor));
		form:setPadding(BorderSize(Vec4(MainMenuStyle.borderSize * 3)));
		form:setFormOffset(PanelSize(Vec2(0.005), Vec2(1)));
		form:setRenderLevel(1)
		
		--form = Form()
		headerPanel = form:add(Panel(PanelSize(Vec2(-1,0.03))))
		headerPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		

		local sellButton = headerPanel:add(Button(PanelSize(Vec2(-1.0,-1.0), Vec2(1.0,1.0)), ButtonStyle.SIMPLE, Core.getTexture("icon_table.tga"), Vec2(0,0), Vec2(0.125, 0.0625)))
		sellButton:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
		sellButton:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
		sellButton:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))	
		sellButton:addEventCallbackExecute(sellTower)	

		
		local header = headerPanel:add(Label(PanelSize(Vec2(-1)), "Hello", Alignment.MIDDLE_CENTER))
		header:setTextColor(Vec3(1))
			
		local lineBreak = form:add(Panel(PanelSize(Vec2(-1,0.002))));
		lineBreak:setBackground(Sprite(Vec4(0.4,0.4,0.4,0.7)))
		
		return form, header
	end
	
	local function getLastBuildingSelected()
		return buildingLastSelected	
	end
	
	local function handleUpgrade(building, cost,buyMessage,paramMessage)
	
		local p1building = building
		local p2cost = cost
		local p3buyMessage = buyMessage
		local p4paramMessage = paramMessage
		if building and cost then
			if cost <= billboardStats:getDouble("gold") then
				--print("======= "..buyMessage.." =======")
				--print("Lua index: " .. buildingScript:getIndex() .. " Message: " .. buyMessage)
				--print("comUnit:sendTo(...,"..buyMessage..")")
				--print("tab="..tabToStrMinimal({netId=buildingScript:getNetworkName(),cost=0,msg=buyMessage,param=buyMessage..";"..paramMessage}))
				--print("")
				
				local clientId = building:getPlayerNode():getClientId()
				comUnit:sendTo("stats","removeGold",tostring(cost))
				comUnit:sendTo("builder"..clientId, "buildingSubUpgrade", tabToStrMinimal({netId=buildingScript:getNetworkName(),cost=0,msg=buyMessage,param=buyMessage..";"..paramMessage}))
			end
		end
	end
	
	local function changedTargetSystem(tag, index, items)
		comUnit:sendTo(buildingScript:getIndex(),"SetTargetMode",tostring(index))
	end
	
	local function senToBuildNode( netMessage, data)
		local playerNode = this:findNodeByType(NodeId.playerNode)
		local buildNode = playerNode:findNodeByType(NodeId.buildNode)
		
		if buildNode then
			comUnit:sendTo( buildNode:getScriptByName("BuilderScript"):getIndex(), netMessage, data)	
		end
	end
	
	local function instalForm()
	
		formWallTower, headerWallTower = createForm()
		formTower, headerTower = createForm()
	
		--Wall tower info panel
		wallTowerPanel = WallTowerPanel.new(formWallTower,getLastBuildingSelected, senToBuildNode)
		wallPanelInit = false
		towerImagePanel = formWallTower:add(Panel(PanelSize(Vec2(-1),Vec2(1))));
		towerImagePanel:setBackground(Sprite(selectedCamera:getTexture()));
		
		
		
		--other towers information
		towerPanel = formTower:add(Panel(PanelSize(Vec2(-1),Vec2(1,0.9))))
		towerPanel:setLayout(FallLayout(Alignment.BOTTOM_RIGHT))
		
		--secondary uppgrades
		upgradePanel = UpgradePanel.new(towerPanel, comUnit, handleUpgrade, changedTargetSystem, getLastBuildingSelected)
			
		damageInfoPanel = DamageInfoPanel.new(towerPanel)
		infoPanel = TowerInfoPanel.new(towerPanel)
		
		local label = Label(PanelSize(Vec2(-0.3,0.1),PanelSizeType.ParentPercent), "Level:");
		label:setTextColor(Vec3(1.0));		
		
		
		--tower image
		towerImagePanel = formTower:add(Panel(PanelSize(Vec2(-1),Vec2(1))));
		towerImagePanel:setBackground(Sprite(selectedCamera:getTexture()));
		towerImagePanel:setLayout(FlowLayout());
		towerImagePanel:getLayout():setPanelSpacing(PanelSize(Vec2(0.005)));
		
		imagePanel = towerImagePanel:add(Panel(PanelSize(Vec2(-1))))
		imagePanel:setPadding(BorderSize(Vec4(0.01)))
		towerBarPanel =  TowerBarPanel.new(imagePanel)
		
		local bottomPanel = imagePanel:add(Panel(PanelSize(Vec2(-1))))
		bottomPanel:setLayout(FlowLayout(Alignment.BOTTOM_LEFT))
		upgradePanel.addBoostPanel( bottomPanel )
		
	end
	
	
	
	local function init()
	
		
		
		--keybinds
		keyBinds = Core.getBillboard("keyBind");
		keyBindUpgradeBuilding = keyBinds:getKeyBind("Upgrade")
		keyBindSellBulding = keyBinds:getKeyBind("Sell")
		
		instalForm()
		
		upgradePanel.clearInfo()
		
		formWallTower:setVisible(false)
		formTower:setVisible(false)
		
	end
	
	function self.downGradeTower(paraNetWorkName)
		local buildingScript = Core.getScriptOfNetworkName(paraNetWorkName)		
		local towerNode = buildingScript:getBillboard():getSceneNode("TowerNode")
		local tab = {netName = paraNetWorkName, upgToScripName = "Tower/WallTower.lua", tName = (paraNetWorkName.."V3"), playerId = Core.getPlayerId()}
		senToBuildNode( "UpgradeWallTower", tabToStrMinimal(tab))
--		senToBuildNode( "addRebuildTower", tabToStrMinimal({upp=tab,down={towerName=paraNetWorkName,wallTowerName=(paraNetWorkName.."V3")}}) )
		
		local billBoard = buildingScript:getBillboard()
	end
	
	local function splitFirst(str,sep)
		local array = {}
		local size = 0
		local reg = string.format("([^%s]+)",sep)
		for mem in string.gmatch(str,reg) do
			if size == 2 then
				array[2] = array[2] .. "=" .. mem;
			else
				table.insert(array, mem)
				size = size + 1
			end
		end	
		return array, size
	end

	local function updateTowerName(button)
		local levelText = " "
		if buildingBillBoard:exist("level") then
			for i=1, buildingBillBoard:getInt("level") do
				levelText = levelText.."I"
			end
		end
		if button ~= nil then
			levelText = levelText.."I"
		end
		headerTower:setText(Text("<b>") + currentTowerName + levelText)
	end
	
	function self.waveChanged(param)
		callChangeWave = 2	
	end
	

	local function initSelectedMenu()
		print("initSelectedMenu")
		
		
		local builBilboard = Core.getBillboard("buildings")
		
		selectedBuildingType = 0
		if buildingLastSelected then
			buildingScript = buildingLastSelected:getScriptByName("tower")
			if buildingScript then
				buildingBillBoard = buildingScript:getBillboard()
				currentTowerName = language:getText( buildingBillBoard:getString("Name") )
				
				--force a resize of the panel
				formWallTower:setVisible(false)
				formTower:setVisible(false)
				
				if buildingBillBoard:getString("Name") == "tower.shop.WallTower.name" then
					
					builBilboard:setBool("isTowerSelected",false)
					selectedBuildingType = 2
					headerWallTower:setText(Text("<b>")+currentTowerName)
--					initWallTower()
					print("Change panelSize to wallTower size")
					
					targetArea.hiddeTargetMesh()
					
					wallTowerPanel.updateWallTowerButtons()
					formWallTower:setVisible(true)
					--columns
					--buildingBillBoard:getBool("isNetOwner")
				else
					
		
					print("Change panelSize to tower size")
					updateTowerName(nil)
					--this panel is hidden when not in use
					builBilboard:setBool("isTowerSelected",true)
					
					
					selectedBuildingType = 1
					
					infoPanel.clearInfo()
					upgradePanel.clear()
					upgradePanel.clearInfo()	
					
					upgradePanel.setBuildingBillBoard( buildingBillBoard )
					damageInfoPanel.setBuildingBillBoard( buildingBillBoard )		
					
					towerBarPanel.updateBars(buildingBillBoard)
					
					infoPanel.updateText()
					upgradePanel.updateButtons(buildingBillBoard)
					damageInfoPanel.updateTowerDamageInfo()
					
					upgradePanel.updateUpgradeInfoIcons()
					
					formTower:setVisible(true)
				end
				
			end
			buildingLastSelected:addChild(selectedCamera:toSceneNode())
					
			local camMatrix = Matrix();
			local camPos = Vec3(4,6,4)
			camMatrix:createMatrix((camPos-Vec3(0,1.5,0)):normalizeV(), Vec3(0,1,0))
			camMatrix:setPosition(camPos)
			selectedCamera:setLocalMatrix(camMatrix)
			
			local contentSize = towerImagePanel:getPanelContentPixelSize()
			contentSize:maximize(Vec2i(32))
			selectedCamera:setFrameBufferSize(contentSize * 2)
		else
			builBilboard:setBool("isTowerSelected",false)
		end
	end
	
	function self.updateSelectedTower()
		--called from tower builder 
		if self.getVisible() then
			initSelectedMenu()
		end
	end
	
	local function getUpgradeCost(buildingBillBoard, upgradeName)
		local dataInBillBoard = buildingBillBoard:toString()
		local result = buildingBillBoard:getString(upgradeName)
		local cost = nil
		for splitedStr in (result .. ";"):gmatch("([^;]*);") do 
			local array, size = splitFirst(splitedStr, "=")
			if size == 2 then
				--print("string: "..splitedStr.."\n")
				if array[1] == "cost" then  
					cost = tonumber(array[2])
					abort()
				end
	 		end
		end
		abort()
		return cost
	end
	

	local function upgradeTower(inBuilding)
		
		local building = inBuilding and inBuilding or buildingLastSelected
		local buildingScript = building and building:getScriptByName("tower") or nil
		local bilboard =  buildingScript and buildingScript:getBillboard() or nil
		
		if bilboard == nil or bilboard:getBool("isNetOwner") == false then
			--building is not a tower or the user is not the owner of the tower
			return
		end
		local cost = getUpgradeCost(bilboard, "upgrade")
		handleUpgrade(building, cost, "upgrade", tostring(bilboard:getInt("level")+1) )
		abort()
	end
	
	local function sellTowerKeyBind(building)
		if buildingBillBoard and buildingBillBoard:getBool("isNetOwner") then
			sellTower()
		end
	end
	
	local function isMouseInMainPanel()
		return billboardStats:getPanel("MainPanel") == Core.getPanelWithMouseFocus()
	end
	
	function self.getVisible()
		return formTower:getVisible() or formWallTower:getVisible()
	end
	
	function self.setVisible(visible)
		if visible and ( selectedBuildingType == 1 or selectedBuildingType == 2 ) then
			formTower:setVisible(selectedBuildingType == 1)
			formWallTower:setVisible(selectedBuildingType == 2)
		else
			formTower:setVisible(false)
			formWallTower:setVisible(false)
			buildingLastSelected = nil
			targetArea.setRenderTarget(nil)
		end
	end
	
	function self.update()
		
		if keyBindUpgradeBuilding:getPressed() then
			--abort()
		end
		if keyBindSellBulding:getPressed() then
			--abort()
		end
		
		--when in game menu is shown hide selected tower menu
		if esqKeyBind:getPressed() or buildingNodeBillboard:getBool("inBuildMode") then
			self.setVisible(false)
			targetArea.hiddeTargetMesh()
		end
		--if tower has been sold don't show the window
		if buildingLastSelected and buildingLastSelected:getScriptByName("tower") == nil then
			self.setVisible(false)
		end
		
		
		if Core.getInput():getMouseDown(MouseKey.left) and not buildingNodeBillboard:getBool("AbilitesBeingPlaced") and not buildingNodeBillboard:getBool("inBuildMode") and buildingNodeBillboard:getBool("canBuildAndSelect") and isMouseInMainPanel() then
			local playerNode = this:findNodeByType(NodeId.playerNode)
			local buildNode = playerNode:findNodeByType(NodeId.buildNode)
			--buildNode = buildNode()
			local building = buildNode and buildNode:getBuldingFromLine(camera:getWorldLineFromScreen(Core.getInput():getMousePos())) or nil
			
			if building then
				if buildingLastSelected ~= building then
					if keyBindUpgradeBuilding:getHeld() then
						upgradeTower(building)
					else
						setVisibleClass(self)
						buildingLastSelected = building
						initSelectedMenu()
--						self.setVisible(false)
					end  
				else
					if keyBindUpgradeBuilding:getHeld() then
						upgradeTower(buildingLastSelected)
					end
				end
			else
				self.setVisible(false)
			end
			
		end
		
		
		
		if self.getVisible() then
			
			if keyBindSellBulding:getPressed() then
				sellTowerKeyBind()
			end
			
			if keyBindUpgradeBuilding:getPressed() then
				upgradeTower()
				
			end
			
			if selectedBuildingType == 1 then
				towerBarPanel.updateBars(buildingBillBoard)
				towerBarPanel.update()
				infoPanel.updateText()
				upgradePanel.updateButtons(buildingBillBoard)
				damageInfoPanel.updateTowerDamageInfo()
				upgradePanel.updateUpgradeInfoIcons()
				
			elseif selectedBuildingType == 2 then
				wallTowerPanel.updateWallTowerButtons()
			end
			
			if buildingLastSelected then
				
				local rangeLevel = 4
				if upgradePanel.getTowerShowRange() then
					rangeLevel = upgradePanel.getTowerRangeLevel()
				end
				
				local colorList = {Vec4(0.4,0.4,1,2), Vec4(0,0,0,0.4), Vec4(0,0,0,0.4)}
				targetArea.setRenderTarget(buildingLastSelected, rangeLevel, colorList)
			else
				targetArea.setRenderTarget(nil)
			end		
		else
			targetArea.hiddeTargetMesh()
		end
	
		if callChangeWave > 0 then
			callChangeWave = callChangeWave - 1
			if callChangeWave == 0 then
				damageInfoPanel.updateTowerDamageInfo()
			end
		end
		
		formWallTower:update()
		formTower:update()
	end
	
	init()
	
	return self
end