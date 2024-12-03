require("Game/gameValues.lua")

--buildingBillBoard = Billboard()
--buildingNodeBillboard = Billboard()
--this = SceneNode()

WallTowerPanel = {}
function WallTowerPanel.new(inParentPanel, inGetLastBuildingSelectedFunction, senToBuildNodeFunction)
	local self = {}
	local gameValues = GameValues.new()
	local wallPanel = nil
	--parentPanel = Panel()
	local parentPanel = inParentPanel
	local billboardStats = Core.getBillboard("stats")
	local wallTowerButtons = {}
	local wallTowerCostLabels = {}
	
	local getLastBuildingSelectedFunction = inGetLastBuildingSelectedFunction
	local senToBuildNode = senToBuildNodeFunction
	
	function self.setVisible(visible)
		local vis = visible
		local panel = wallPanel
		wallPanel:setVisible(visible)
	end
	
	local function getTowerCost(towerId)
		local towerNode = buildingNodeBillboard:getSceneNode(tostring(towerId).."Node")
		--print("\n\n\nShow Node\n")
		if towerNode then
			local buildingScript = towerNode:getScriptByName("tower")
			--get the cost of the new tower
			return buildingScript:getBillboard():getInt("cost")
		end
		return 0
	end
	
	local function uppgradeWallTowerCallback(button)
		--Get the tower node that will be built
		local towerNode = buildingNodeBillboard:getSceneNode(button:getTag():toString())
		--print("\n\n\nShow Node\n")
		
		if towerNode then
			local buildingScript = towerNode:getScriptByName("tower")
			--get the cost of the new tower
			local buildCost = buildingScript:getBillboard():getFloat("cost")
			--get the script file name
			local scriptName = buildingScript:getFileName()
			--lastBuildingSelected = SceneNode()
			local lastBuildingSelected = getLastBuildingSelectedFunction()
			local script = lastBuildingSelected:getScriptByName("tower")
			if script and (buildCost-getTowerCost(1)) <= billboardStats:getDouble("gold") then
				local netName = script:getNetworkName()
				local tab = {netName = netName, upgToScripName = scriptName, tName = (netName.."V2"), playerId = Core.getPlayerId(), buildCost = buildCost}
				local upgradeData =	{netName, 0, scriptName, nil, (netName.."V2"), true}
				local downGradeData = {netName = (netName.."V2"), upgToScripName = "Tower/WallTower.lua", tName = netName, playerId = Core.getPlayerId(), buildCost=0}
				senToBuildNode( "UpgradeWallTower", tabToStrMinimal(tab))
				senToBuildNode( "addDowngradeTower", tabToStrMinimal({upp=upgradeData,down=downGradeData}) )
			end
		end
	end
	
	local function createWallTowerPanel(panel, numColumns, towers)
		columns = {}
		for i=1, numColumns do
			columns[i] = panel:add(Panel(PanelSize(Vec2(-1/(numColumns-i+1),-1))))
		end
		
		local towerTexture = Core.getTexture("icon_tower_table")
		local texture = Core.getTexture("icon_table.tga")
		for i=1, #columns do

			columns[i]:setLayout(FallLayout())
				
			local wallTowerCost = getTowerCost(1)
			local costPanel = columns[i]:add(Panel(PanelSize(Vec2(-1), Vec2(5,1))))
			local text = Text( tostring(getTowerCost(towers[i]) - wallTowerCost) )
			local costLabel = Label(PanelSize(Vec2(-1),Vec2(text:getTextScale().x+0.3,1)), text, Vec4(1))
			costLabel:setTextHeight(-0.75)
			--costLabel:setBackground(Sprite(Vec3(0.3)))
			local costIcon = Panel(PanelSize(Vec2(-1),Vec2(1)))
			local costIconSprite = Sprite(texture)
			costIconSprite:setUvCoord(Vec2(), Vec2(0.125,0.0625))
			costIcon:setBackground(costIconSprite)
				
			costPanel:setLayout(FlowLayout(Alignment.TOP_CENTER))
			costPanel:add(costLabel)
			costPanel:add(costIcon)
			costPanel:setCanHandleInput(false)

			
				
			local x = (towers[i]-1)%4
			local y =3-math.floor(((towers[i]-1)/4))
			local start = Vec2(x/4.0, y/4.0)
			
			--Make sure that information about the tower uppgrade actually exist				
			local button = Button(PanelSize(Vec2(-1,-1), Vec2(1,1),PanelSizeType.ParentPercent), ButtonStyle.SIMPLE, towerTexture, start, start+Vec2(0.25,0.25))
			button:setTag(tostring(towers[i]).."Node")
			button:addEventCallbackExecute(uppgradeWallTowerCallback)
		
			button:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
			button:setInnerHoverColor(Vec4(Vec3(1.3),0.3),Vec4(Vec3(1.3),0.5), Vec4(Vec3(1.3),0.3))
			button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))

			--{"Passiv", "MinigunTower", "ArrowTower","SwarmTower", "ElectricTower", "BladeTower", "MissileTower", "QuakerTower", "SupportTower", "BankTower"}
			local towerName = gameValues.getStoreGroupNames()
			if gameValues.isTowerUnlocked(towerName[towers[i]]) == false then
				button:setEnabled(false)
			end
				
			wallTowerButtons[#wallTowerButtons+1] = button
			wallTowerCostLabels[#wallTowerCostLabels+1] = costLabel
				
			columns[i]:add(button)
		end
	end
	
	local function getBuildingBilBoard()
		buildingScript = getLastBuildingSelectedFunction():getScriptByName("tower")
		if buildingScript then
			return buildingScript:getBillboard()
		end
		return nil
	end
	
	function self.updateWallTowerButtons()
		for i=1, #wallTowerButtons do
			
			local towerNode = buildingNodeBillboard:getSceneNode(wallTowerButtons[i]:getTag():toString())
			--print("\n\n\nShow Node\n")
			local upgradeBuildCost = 0
			if towerNode then
				local buildingScript = towerNode:getScriptByName("tower")
				--get the cost of the new tower
				local buildCost = buildingScript:getBillboard():getFloat("cost")
				upgradeBuildCost = (buildCost-getTowerCost(1))
			end
			local towerName = gameValues.getStoreGroupNames()
			local buildingBillBoard = getBuildingBilBoard()
			local isNetOwner = buildingBillBoard and buildingBillBoard:getBool("isNetOwner") or false
			local enable = isNetOwner and upgradeBuildCost <= billboardStats:getDouble("gold") and gameValues.isTowerUnlocked(towerName[i+1])
			wallTowerButtons[i]:setEnabled(enable)
			wallTowerCostLabels[i]:setTextColor(enable and Vec4(1) or Vec4(4,1,1,1))
		end
	end
	
	local function sellTower(button)
		local playerNode = this:findNodeByType(NodeId.playerNode)
		local buildNode = playerNode:findNodeByType(NodeId.buildNode)
		local buildingLastSelected = getLastBuildingSelectedFunction()
		local buildingBillBoard = getBuildingBilBoard()
		
	
		if buildNode and buildingLastSelected and buildingBillBoard then
			local buildingScript = buildingLastSelected:getScriptByName("tower")
			if buildingScript then--crash protection, when the tower has crashed
				
				
				if buildingBillBoard:getString("Name") == "Wall tower" then
					senToBuildNode( "SELLTOWER", buildingScript:getNetworkName())					
				else
					
					local netName = buildingScript:getNetworkName()				
					local tab = {netName = netName, upgToScripName = "Tower/WallTower.lua", tName = (netName.."V3"), playerId = Core.getPlayerId(), buildCost=0}
					print("Sold tower: "..netName)
					senToBuildNode( "UpgradeWallTower", tabToStrMinimal(tab) )
					senToBuildNode( "addRebuildTower", tabToStrMinimal({upp=tab,down={towerName=netName,wallTowerName=(netName.."V3")}}) )
					local billBoard = buildingScript:getBillboard()
--					if billBoard and billBoard:getBool("isNetOwner") then
--						comUnit:sendTo("stats", "addGold", tostring(math.max(billBoard:getFloat("value")-getTowerCost(1),0)))
--					end
				end	
			end
		end
	end
	
	function initWallTower()

		local topRowPanel = wallPanel:add(Panel(PanelSize(Vec2(-1,-0.2))))
		local row1 = wallPanel:add(Panel(PanelSize(Vec2(-1,-1/3))))
		local row2 = wallPanel:add(Panel(PanelSize(Vec2(-1,-0.5))))
		local row3 = wallPanel:add(Panel(PanelSize(Vec2(-1,-1.0))))
		
		--{"Passiv", "MinigunTower", "ArrowTower","SwarmTower", "ElectricTower", "BladeTower", "MissileTower", "QuakerTower", "SupportTower", "BankTower"}
		createWallTowerPanel(row1, 3, {2,3,4})
		createWallTowerPanel(row2, 3, {5,6,7})
		createWallTowerPanel(row3, 3, {8,9,10})
		
		topRowPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		topRowPanel:setPadding(BorderSize(Vec4(0,0,0.006,0),true))
		local texture = Core.getTexture("icon_table.tga")
		local button = topRowPanel:add(Button(PanelSize(Vec2(-0.6,-0.6), Vec2(1.0,1.0),PanelSizeType.ParentPercent), ButtonStyle.SIMPLE, texture, Vec2(0,0), Vec2(0.125, 0.0625)))
		wallTowerButtons[#wallTowerButtons + 1] = button
		wallTowerCostLabels[#wallTowerCostLabels + 1] = button
		
		button:addEventCallbackExecute(sellTower)	
		button:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
		button:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
		button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))

	end
	
	local function init()
		wallPanel = parentPanel:add(Panel(PanelSize(Vec2(-1))))
		wallPanel:setVisible(false)
		wallPanel:setLayout(FallLayout())
		
		initWallTower()
	end
	
	
	init()
	
	return self
end