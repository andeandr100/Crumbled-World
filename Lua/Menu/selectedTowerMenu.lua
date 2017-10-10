require("Game/builderUpgrader.lua")
require("Game/targetArea.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/settingsCombobox.lua")
require("Menu/settings.lua")
--comUnit = ComUnit()
--buildingNodeBillboard = Billboard()
--buildingBillBoard = Billboard()
--header = Label()
--selectedCamera = Camera()
--this = SceneNode()

selectedtowerMenu = {}
function selectedtowerMenu.new(inForm, inLeftMainPanel, inTowerImagePanel)
	local self = {}
	--variabels from outside
	local form = inForm
	local leftMainPanel = inLeftMainPanel
	local towerImagePanel = inTowerImagePanel
	
	--local variabels
	local keyBinds
	local keyBindUpgradeBuilding
	local keyBindBoostBuilding
	local keyBindSellBulding
	local keyBindTable
	local wallTowerPanel
	local wallPanelInit
	local towerPanel
	local buttonPanel
	local buttonCostPanel
	local MainButtonPanel
	local MainButtonCostPanel
	local infoPanel
	local infopanelRight
	local energyBar
	local overHeatBar
	local xpBar
	local upgradesPanel
	local towerInfo
	local imagePanel
	local retargetPanel
	local targetComboBox
	local currentTowerName = ""
	
	local storedButtonsInfo = {}
	local towerValue = 0
	local showRange = false
	local buttonPanels = {}
	local buttonCostPanels = {}
	local wallTowerButtons = {}
	local wallTowerCostLabels = {}
	local initSelectedmenuFunction = nil
	local buildingBillBoard = nil
	local buildingScript = nil
	local callChangeWave = -1
	local targetArea = TargetArea.new()
	local showBoostableTowers = false
	local updateBoostTimer = {}
			
	
	--this = SceneNode()
	local function instalForm()
	
		leftMainPanel:setPanelSize(PanelSize(Vec2(-1),Vec2(1,1.3)))
	
		--Wall tower info panel
		wallTowerPanel = leftMainPanel:add(Panel(PanelSize(Vec2(-1))))
		wallTowerPanel:setVisible(false)
		wallTowerPanel:setLayout(FallLayout())
		
		wallPanelInit = false
		
		
		--other towers information
		towerPanel = leftMainPanel:add(Panel(PanelSize(Vec2(-1))))
		towerPanel:setLayout(FallLayout(Alignment.BOTTOM_RIGHT))
		
		retargetPanel = towerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(9,1))))
		--Spacing
		towerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(35,1))))
			
	
		--secondary uppgrades
		buttonPanel = towerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(5.2,1)))); 
		buttonPanel:setLayout(GridLayout(1,5))
	
		
		--add Spacing
		buttonCostPanel = towerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(16,1))))
		buttonCostPanel:setLayout(GridLayout(1,5))
		
	
		--Main uppgrade, tower uppgrade, boost, rotate arrow tower, sell building
		MainButtonPanel = towerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(5.2,1)))); 
		MainButtonPanel:setLayout(GridLayout(1,5))
		
		--add Spacing
		MainButtonCostPanel = towerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(16,1))))
		MainButtonCostPanel:setLayout(GridLayout(1,5))
		
		
		
		--Spacing
		towerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(16,1))))
		damageInfoBar = towerPanel:add(ProgressBar(PanelSize(Vec2(-1),Vec2(9,1)), Text(""), 0))
		
		

		local infoPanelMain = towerPanel:add(Panel(PanelSize(Vec2(-1))))
	
		infoPanel = infoPanelMain:add(Panel(PanelSize(Vec2(-0.5,-1))))
		infoPanel:setLayout(GridLayout(5,1))
		
		infopanelRight = infoPanelMain:add(Panel(PanelSize(Vec2(-1))))
		
		local label = Label(PanelSize(Vec2(-0.3,0.1),PanelSizeType.ParentPercent), "Level:");
		label:setTextColor(Vec3(1.0));		
		
		
		
		--add progress bar
		energyBar = ProgressBar(PanelSize(Vec2(-1.0,0.1),PanelSizeType.ParentPercent), Text("0 / 0"), 0.0)
		energyBar:setTextColor(Vec3(1.0));
		energyBar:setInnerColor(Vec4(0,0,0,0.3), Vec4(0.1,0.1,0.1,0.6))
		energyBar:setColor(Vec4(0.5,0.5,1.1,0.75), Vec4(0,0,0.65,0.75))
		energyBar:setVisible(false)
	
		overHeatBar = ProgressBar(PanelSize(Vec2(-1.0,0.1),PanelSizeType.ParentPercent), Text(""), 0.0)
		overHeatBar:setTextColor(Vec3(1.0));
		overHeatBar:setInnerColor(Vec4(0,0,0,0.3), Vec4(0.1,0.1,0.1,0.6))
		overHeatBar:setColor(Vec4(1.0,0.5,0,0.75), Vec4(0.5,0.2,0.,0.75))
		overHeatBar:setVisible(false)
		
		xpBar = ProgressBar(PanelSize(Vec2(-1.0,0.1),PanelSizeType.ParentPercent), Text(""), 0.0)
		xpBar:setTextColor(Vec3(1.0));
		xpBar:setInnerColor(Vec4(0,0,0,0.3), Vec4(0.1,0.1,0.1,0.6))
		xpBar:setColor(Vec4(1.0,0.5,0,0.75), Vec4(0.5,0.2,0.,0.75))
		xpBar:setVisible(false)
		
		imagePanel = towerImagePanel:add(Panel(PanelSize(Vec2(-1))))
	
		imagePanel:setPadding(BorderSize(Vec4(0.01)))
		imagePanel:add(energyBar)
		imagePanel:add(overHeatBar)
		imagePanel:add(xpBar)
		
	
		local bottomPanel = imagePanel:add(Panel(PanelSize(Vec2(-1))))
		bottomPanel:setLayout(FlowLayout(Alignment.BOTTOM_LEFT))
		
		upgradesPanel = bottomPanel:add(Panel(PanelSize(Vec2(-1,-1),Vec2(6,1))))
		upgradesPanel:setLayout(GridLayout(1,5))
	
	end
	
	
	local function init()
		
		--keybinds
		keyBinds = Core.getBillboard("keyBind");
		keyBindUpgradeBuilding = keyBinds:getKeyBind("Upgrade")
		keyBindBoostBuilding = keyBinds:getKeyBind("Boost")
		keyBindSellBulding = keyBinds:getKeyBind("Sell")

		
		towerInfo = {}
		statsOrder =  {"damage", "dmg","RPS","range", "slow","bladeSpeed", "fireDPS","burnTime","dmg_range"}
		keyBindTable = {keyBindUpgradeBuilding, keyBindBoostBuilding}
		
		billboardStats = Core.getBillboard("stats")
		
		instalForm()
		
	end
	
	local function senToBuildNode( netMessage, data)
		local playerNode = this:findNodeByType(NodeId.playerNode)
		local buildNode = playerNode:findNodeByType(NodeId.buildNode)
		
		
	
		if buildNode then
			comUnit:sendTo( buildNode:getScriptByName("BuilderScript"):getIndex(), netMessage, data)	
		end
	end

	
	local function getTowerCost(towerId)
		local towerNode = buildingNodeBillboard:getSceneNode(tostring(towerId).."Node")
		--print("\n\n\nShow Node\n")
		if towerNode then
			local buildingScript = towerNode:getScriptByName("tower")
			--get the cost of the new tower
			return buildingScript:getBillboard():getFloat("cost")
		end
		return 0
	end
	
	
	
	function self.downGradeTower(paraNetWorkName)
		local buildingScript = Core.getScriptOfNetworkName(paraNetWorkName)		
		local towerNode = buildingScript:getBillboard():getSceneNode("TowerNode")
--		local tab = {netName = paraNetWorkName, upgToScripName = "Tower/WallTower.lua", tName = (paraNetWorkName.."V3"), playerId = Core.getPlayerId(), buildCost=0}
		local tab = {netName = paraNetWorkName, upgToScripName = "Tower/WallTower.lua", tName = (paraNetWorkName.."V3"), playerId = Core.getPlayerId()}
		senToBuildNode( "UpgradeWallTower", tabToStrMinimal(tab))
--		senToBuildNode( "addRebuildTower", tabToStrMinimal({upp=tab,down={towerName=paraNetWorkName,wallTowerName=(paraNetWorkName.."V3")}}) )
		
		local billBoard = buildingScript:getBillboard()
--		if billBoard and billBoard:getBool("isNetOwner") then
--			comUnit:sendTo("stats", "addGold", tostring(math.max(billBoard:getFloat("value")-getTowerCost(1),0)))
--		end
		
	end
	
	local function sellTower(button)
		local playerNode = this:findNodeByType(NodeId.playerNode)
		local buildNode = playerNode:findNodeByType(NodeId.buildNode)
		
		
	
		if buildNode and buildingLastSelected then
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
			local script = buildingLastSelected:getScriptByName("tower")
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
			if towers[i] ~= -1 then
				columns[i]:setLayout(FallLayout())
				
				local wallTowerCost = getTowerCost(1)
				local costPanel = columns[i]:add(Panel(PanelSize(Vec2(-1), Vec2(5,1))))
				local text = Text( tostring(getTowerCost(towers[i]) - wallTowerCost) )
				local costLabel = Label(PanelSize(Vec2(-1),Vec2((text:getTextScale().x/4*3)+0.5,1)), text, Vec4(1))
				costLabel:setTextHeight(-0.75)
				local costIcon = Panel(PanelSize(Vec2(-1),Vec2(1)))
				local costIconSprite = Sprite(texture)
				costIconSprite:setUvCoord(Vec2(), Vec2(0.125,0.0625))
				costIcon:setBackground(costIconSprite)
				
				costPanel:setLayout(FlowLayout(Alignment.TOP_CENTER))
				costPanel:add(costLabel)
				costPanel:add(costIcon)
				costPanel:setCanHandleInput(false)
				
				
				local x = (towers[i]-1)%3
				local y = 2-math.floor(((towers[i]-1)/3))
				local start = Vec2(x/3.0, y/3.0)
			
				--print( "textureName: "..texture:getName():toString().."\n")
				--Make sure that information about the tower uppgrade actually exist				
				local button = Button(PanelSize(Vec2(-1,-1), Vec2(1,1),PanelSizeType.ParentPercent), ButtonStyle.SIMPLE, towerTexture, start, start+Vec2(1/3,1/3))
				button:setTag(tostring(towers[i]).."Node")
				button:addEventCallbackExecute(uppgradeWallTowerCallback)
		--		button:addEventCallbackMouseFocusGain(showWallBuildingInformation)
		--		button:addEventCallbackMouseFocusLost(clearWallBuildingInformation)
		
				button:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
				button:setInnerHoverColor(Vec4(Vec3(1.3),0.3),Vec4(Vec3(1.3),0.5), Vec4(Vec3(1.3),0.3))
				button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
				
				wallTowerButtons[#wallTowerButtons+1] = button
				wallTowerCostLabels[#wallTowerCostLabels+1] = costLabel
				
				columns[i]:add(button)
			end
		end
	end
	
	function initWallTower()
		if wallPanelInit == false then
			wallPanelInit = true
			
			local row1Panel = wallTowerPanel:add(Panel(PanelSize(Vec2(-1,-1/3))))
			local row2 = wallTowerPanel:add(Panel(PanelSize(Vec2(-1,-0.5))))
			local row3 = wallTowerPanel:add(Panel(PanelSize(Vec2(-1,-1.0))))

			
			--First row
			local row1 = row1Panel:add(Panel(PanelSize(Vec2(-2/3,-1))))
			wallTowerSellPanel = row1Panel:add(Panel(PanelSize(Vec2(-1))))
			
			createWallTowerPanel(row1, 2, {8,9,-1})
			createWallTowerPanel(row2, 3, {2,3,4})
			createWallTowerPanel(row3, 3, {5,6,7})
			
			wallTowerSellPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
			wallTowerSellPanel:setPadding(BorderSize(Vec4(0,0,0.006,0),true))
			local texture = Core.getTexture("icon_table.tga")
			local button = wallTowerSellPanel:add(Button(PanelSize(Vec2(-0.6,-0.6), Vec2(1.0,1.0),PanelSizeType.ParentPercent), ButtonStyle.SIMPLE, texture, Vec2(0,0), Vec2(0.125, 0.0625)))
			wallTowerButtons[#wallTowerButtons + 1] = button
			wallTowerCostLabels[#wallTowerCostLabels + 1] = button
			
			button:addEventCallbackExecute(sellTower)	
			button:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
			button:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
		end
	end
	
	
	local function handleUpgrade(cost,buyMessage,paramMessage)
		--print("uppgrade building\n")
		if buildingLastSelected then
			
			--print("money on bank " .. billboardStats:getDouble("gold") .. "\n")
			if cost <= billboardStats:getDouble("gold") then
				--print("======= "..buyMessage.." =======\n")
				--print("Lua index: " .. buildingScript:getIndex() .. " Message: " .. buyMessage .. "\n")
				--print("comUnit:sendTo(...,"..buyMessage..")\n")
--				comUnit:sendTo("stats","removeGold",tostring(cost))
				comUnit:sendTo("builder"..Core.getNetworkClient():getClientId(), "buildingSubUpgrade", tabToStrMinimal({netId=buildingScript:getNetworkName(),cost=0,msg=buyMessage,param=paramMessage}))
			end
		end
	end
	
	local function split(str,sep)
		local array = {}
		local size = 0
		local reg = string.format("([^%s]+)",sep)
		for mem in string.gmatch(str,reg) do
			table.insert(array, mem)
			size = size + 1
		end	
		return array, size
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
	

	local function updateEnergyBar()
		if energyBar:getVisible() then
			
			local enegrgy = buildingBillBoard:getInt("energy")
			local maxEnergy = buildingBillBoard:getInt("energyMax")
			energyBar:setText(Text(enegrgy.."/"..maxEnergy))
			energyBar:setValue(enegrgy/maxEnergy)
		end
	end
	
	local function updateOverHeatBar()
		if overHeatBar:getVisible() then
			local enegrgy = buildingBillBoard:getFloat("overHeatPer")
			
			overHeatBar:setValue(enegrgy)
		end
	end
	
	local function updateXpBar()
		if xpBar:getVisible() then
			
			local xp = buildingBillBoard:getInt("xp")
			local maxXp = buildingBillBoard:getInt("xpToNextLevel")
			xpBar:setText(Text(xp.."/"..maxXp))
			xpBar:setValue(xp/maxXp)
		end
	end
	
	local function onExecute(button)
	
		--print("button:getTag()="..button:getTag().."\n")
		if button:getTag():toString() ~= "" then
			--upgrade1;400;2	name;cost;level
			local subString, size = split(button:getTag():toString(), ";")
			if size == 3 and tonumber(subString[2]) then
				handleUpgrade(tonumber(subString[2]), subString[1], tonumber(subString[1]=="upgrade2" and 1 or subString[3]) )
			else
				handleUpgrade(0, subString[1])	
			end
			--Disabel this upgrade for future use
			button:setTag("");
		end
	end
	
	
	
	local function getUvCoordAndTextFromName(name)
		if name=="damage" or name=="dmg" then
			return Vec2(0.25,0.0),Vec2(0.375,0.0625), language:getText("damage")
		elseif name=="RPS" then
			return Vec2(0.25,0.25),Vec2(0.375,0.3125), language:getText("attack per second")
		elseif name=="range" then
			return Vec2(0.375,0.4375),Vec2(0.5,0.5), language:getText("target range")
		elseif name=="fireDPS" then
			return Vec2(0.75,0.25),Vec2(0.875,0.3125), language:getText("burn damage per second")
		elseif name=="burnTime" then
			return Vec2(0.625,0.25),Vec2(0.75,0.3125), language:getText("burn time")
		elseif name=="slow" then
			return Vec2(0.875,0.375),Vec2(1.0,0.4375), language:getText("slow")
		elseif name=="bladeSpeed" then
			return Vec2(0.125,0.25),Vec2(0.25,0.3125), language:getText("blade speed")
		elseif name=="dmg_range" then
			return Vec2(0.875,0.25),Vec2(1.0,0.3125), language:getText("damage range")
		else
			return Vec2(0.0,0.25),Vec2(0.125,0.3125), Text("")
		end
	end
	
	local function updateText()
		
		local reload = not (storedShowText == buildingBillBoard:getString("currentStats") )
		
		--check if the stats need to be reloaded
		if reload then
			--print("\n\nupdateText()\n")
			
			--infoPanel:clear()	towerInfo
			if towerInfo.info then
				--update info
				storedShowText = buildingBillBoard:getString("currentStats")
				local info = towerInfo.info
				--print("displayStats"..storedShowText)
				for splitedStr in (storedShowText .. ";"):gmatch("([^;]*);") do 
					--print("Splited:".. splitedStr)
					local array = splitFirst(splitedStr, "=")
					local name = array[1]
					local value = array[2]
					if info[name] ~= nil and info[name].label then
						info[name].value = value
						info[name].label:setText((value and value or "---"))
					end
					
				end
			else
				--build info
				local info = {}
				towerInfo.info = info
				storedShowText = buildingBillBoard:getString("currentStats")
				--print("displayStats"..storedShowText)
				for splitedStr in (storedShowText .. ";"):gmatch("([^;]*);") do 
					--print("Splited:".. splitedStr)
					local array = splitFirst(splitedStr, "=")
					info[array[1]] = {value=array[2]}
					
				end
	
				infoPanel:clear()
				for i, name in pairs(statsOrder) do
					if info[name] then	
						local row = infoPanel:add(Panel(PanelSize(Vec2(-1))))
						local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga"))
						local minCoord, maxCoord, text = getUvCoordAndTextFromName(name)
						icon:setUvCoord(minCoord,maxCoord)
						icon:setToolTip(text)
						
						row:add(icon)--Label(PanelSize(Vec2(-0.4,0.166),PanelSizeType.ParentPercent), (array[1] and array[1] or "----")..":", Vec3(1.0)))
						local label = row:add(Label(PanelSize(Vec2(-1)), (info[name].value and info[name].value or "-"), Vec3(1.0)))
	
						info[name].icon = icon
						info[name].label = label
					end				
				end
			end
		end
	end
	
	local function updateToolTip(button, info)
		local requireText = Text("")
		if info["require"] ~= nil then
			local value = info["require"].value
			local requireTextCreated = false
			if value == "tower level 2" or value == "tower level 3" or value == "Wave" or value == "shop required" or value == "not your tower" or value == "conflicting upgrade" then
				requireTextCreated = true
				requireText = Text("<font color=rgb(255,50,50)>")
			end
			
			
			if value == "tower level 2" then
				requireText = requireText + language:getText("tower level") + Text(" 2")
			elseif value == "tower level 3" then
				requireText = requireText + language:getText("tower level") + Text(" 3")
			elseif value == "Wave" then
				local wave = ( info.duration and info.timerStart) and tonumber(info.duration.value) + tonumber(info.timerStart.value) or 0
				requireText = requireText  + language:getText("req wave") + Text(" "..tostring(wave))
			elseif value == "shop required" then
				requireText = requireText  + language:getText("shop required")
			elseif value == "not your tower" then
				requireText = requireText  + language:getText("not your tower")
			elseif value == "conflicting upgrade" then
				requireText = requireText  + language:getText("conflicting upgrade")
			end
			
			
			if requireTextCreated then
				requireText = requireText + Text("</font><br>")
			end
		end
		
		
					
		if info.toolTipPanel ~= nil then
			if info.infoName == "sell" then
				info.toolTipSellLabel:setText("<font color=rgb(40,255,40)>+"..(info.towerValue and tostring(info.towerValue) or "0").."</font>")
			else
				for i, name in pairs(statsOrder) do
					if info[name] and info[name].toolTipLabel then
						local notifyText = "?"
						if info[name].value and info[name].value then
							local fontTag = "<font color=rgb(255,255,255)>"
							if tonumber(info[name].value) > 0 then
								fontTag = "<font color=rgb(40,255,40)>+"
							elseif tonumber(info[name].value) < 0 then
								fontTag = "<font color=rgb(255,50,50)>"
							end
							notifyText = fontTag .. (info[name].value and info[name].value or "?") .. "</font>\n"
						end
						
						info[name].toolTipLabel:setText(notifyText)
					end	
				end
				local infoValueText = (info.info and info.info.value or "")
				info.toolTipLabel:setText( requireText + language:getTextWithValues(infoValueText, (info.value1 ~= nil) and info.value1.value or "", (info.value2 ~= nil) and info.value2.value or ""))
				local startSize = info.toolTipLabel:getPanelSize():getSize()
				info.toolTipLabel:setPanelSizeBasedOnTextSize()
				
				if startSize.y ~= info.toolTipLabel:getPanelSize():getSize().y then
					local diff = info.toolTipLabel:getPanelSize():getSize() - startSize
					local panelSize = info.toolTipPanel:getPanelSize():getSize()
					print("\n\n\n\ndiff = "..diff.y.."\n\n\n\n")
					info.toolTipPanel:setPanelSize(PanelSize( panelSize + Vec2(math.max(diff.x, panelSize.x) - panelSize.x, diff.y), PanelSizeType.Pixel))
				end
			end
		else
			local panel = Panel(PanelSize(Vec2(-1)))
			panel:setLayout(FallLayout())
			panel:getPanelSize():setFitChildren(true, true)
			
	--		local value1 = (info.value1 ~= nil) and info.value1.value or ""
	--		local value2 = (info.value2 ~= nil) and info.value2.value or ""
			local infoValueText = (info.info and info.info.value or "")
			local textLabel = Label(PanelSize(Vec2(-1)), requireText + language:getTextWithValues(infoValueText, (info.value1 ~= nil) and info.value1.value or "", (info.value2 ~= nil) and info.value2.value or ""), Vec4(1) )
			textLabel:setTextHeight(0.015)
			textLabel:setPanelSizeBasedOnTextSize()
			panel:add(textLabel)
			
			local totalPanelSizeInPixel = textLabel:getPanelSize():getSize()
			
			if info.infoName == "sell" then
				local row = Panel(PanelSize(Vec2(-1,0.025),Vec2(4,1)))
				
				local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga"))
				icon:setUvCoord(Vec2(0),Vec2(0.125,0.0625))
					
				
				local notifyText = "<font color=rgb(40,255,40)>+"..(info.towerValue and tostring(info.towerValue) or "0").."</font>"
				row:add(icon)
				local label = row:add(Label(PanelSize(Vec2(-1)), notifyText, Vec3(1.0)))
				panel:add(row)
				
				info.toolTipSellIcon = icon
				info.toolTipSellLabel = label		
				
				totalPanelSizeInPixel = totalPanelSizeInPixel + Vec2(0, 0.025 * Core.getScreenResolution().y )
				
			else
				for i, name in pairs(statsOrder) do
					if info[name] then
						
						local row = Panel(PanelSize(Vec2(-1,0.025),Vec2(5,1)))
						local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga"))
						local minCoord, maxCoord, text = getUvCoordAndTextFromName(name)
						icon:setUvCoord(minCoord,maxCoord)
						icon:setToolTip(text)
										
						local notifyText = "?"
						if info[name].value and info[name].value then
							local fontTag = "<font color=rgb(255,255,255)>"
							if tonumber(info[name].value) > 0 then
								fontTag = "<font color=rgb(40,255,40)>+"
							elseif tonumber(info[name].value) < 0 then
								fontTag = "<font color=rgb(255,50,50)>"
							end
							notifyText = fontTag .. (info[name].value and info[name].value or "?") .. "</font>\n"
						end
						
						row:add(icon)
						local label = row:add(Label(PanelSize(Vec2(-1)), notifyText, Vec3(1.0)))
						panel:add(row)
						
						info[name].toolTipIcon = icon
						info[name].toolTipLabel = label
						
						
						totalPanelSizeInPixel = totalPanelSizeInPixel + Vec2(0, 0.025 * Core.getScreenResolution().y )
					end				
				end
			end
			
			panel:setPanelSize(PanelSize(totalPanelSizeInPixel, PanelSizeType.Pixel)	)
			
			info.toolTipPanel = panel
			info.toolTipLabel = textLabel
			
			button:setToolTip(panel)
		end
	end
	
	local function towerShowRange()
		showRange = true
	end
	
	local function towerHideRange()
		showRange = false
	end
	
	local function updateRangeButton()
		if showRange and towerInfo and towerInfo.buttonsInfo then
			for name, data in pairs(towerInfo.buttonsInfo) do
				if data.name and data.level ~= nil and data.name.value == "range" then
					if data.level.level == 3 then
						updateButton(name, nil)
						return
					end
				end
			end
		end
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
		header:setText(Text("<b>") + language:getText(currentTowerName) + levelText)
	end
	
	local function updateButton(name, inText)
		print("\n=== updateButton ===")
		print("Name "..name)
		print("Text: \""..(inText and inText or "nil").."\"")
		if not towerInfo.buttonsInfo[name] then
			towerInfo.buttonsInfo[name] = {infoName = name}
		end
		local buttoninfo = towerInfo.buttonsInfo[name]
		
		if inText then
			buttoninfo.cost = nil
			buttoninfo["require"] = nil
			for splitedStr in (inText .. ";"):gmatch("([^;]*);") do 
				local array, size = splitFirst(splitedStr, "=")
				if size == 2 then
					print(array[1].." = "..array[2])
					if buttoninfo[array[1]] == nil then
						buttoninfo[array[1]] = {value=array[2]}
					else
						buttoninfo[array[1]].value = array[2]
					end
		 		end
			end
			
			if name == "sell" then
				buttoninfo.towerValue = buildingBillBoard:getInt("value")
			end
			
			--update information
			if buttoninfo.info ~= nil and buttoninfo.info.value then
				buttoninfo.info.value = buttoninfo.info.value:gsub("\"", "")
			end
			if buttoninfo["require"] ~= nil and buttoninfo["require"].value then
				buttoninfo["require"].value = buttoninfo["require"].value:gsub("\"", "")
			end
			if buttoninfo["name"] ~= nil and buttoninfo["name"].value then
				buttoninfo["name"].value = buttoninfo["name"].value:gsub("\"", "")
			end
			
			if buttoninfo.button then
				
				if buttoninfo.level ~= nil and buttoninfo.level.level ~= buttoninfo.level.value and buttoninfo.level.levelPanel ~= nil then
					local level = buttoninfo.level.value
					local texture = Core.getTexture("icon_table.tga")
					buttoninfo.level.level = level
					buttoninfo.level.levelPanel:setBackground(Sprite( texture, Vec2(0.625 + (level-1) * 0.125,0.3125), Vec2(0.625 + level * 0.125, 0.375)))
				end
				
				if buttoninfo.cost ~= nil and buttoninfo.costLabel and tonumber(buttoninfo.cost.value) > 0 then
					local text = Text(tostring(buttoninfo.cost.value))
					buttoninfo.costLabel:setPanelSize(PanelSize(Vec2(-1),Vec2(2,1)))
					buttoninfo.costLabel:setText( text )
					--update tag
					buttoninfo.button:setTag(name..";"..tostring(buttoninfo.cost and buttoninfo.cost.value or 0)..";"..tostring(buttoninfo.level.level))
					
					if name ~= "sell" then
						local enable = tonumber(buttoninfo.cost.value) <= billboardStats:getDouble("gold")
						buttoninfo.button:setEnabled( enable )
						buttoninfo.costLabel:setTextColor( enable and Vec4(1) or Vec4(0.8,0.2,0.2,1))
						buttoninfo.costIconSprite:setColor(enable and Vec4(1) or Vec4(Vec3(0.7),1))
						buttoninfo.costIcon:setBackground(buttoninfo.costIconSprite)
						
						buttoninfo.costLabel:setVisible(true)
						buttoninfo.costIcon:setVisible(true)
					end
					
					
				else
					
					if name == "upgrade2" then
						buttoninfo.button:setEnabled(buttoninfo.cost ~= nil)
					else
						buttoninfo.button:setEnabled(name == "sell" and buildingBillBoard:getBool("isNetOwner"))
					end
					buttoninfo.costLabel:setVisible(false)
					buttoninfo.costIcon:setVisible(false)
					if buttoninfo["require"] ~= nil then
						if buttoninfo["require"].value == "tower level 2" then
							buttoninfo.requireLabel:setText( language:getText("lvl") + Text(" 2") )
							buttoninfo.requireLabel:setVisible(true)
						elseif buttoninfo["require"].value == "tower level 3" then
							buttoninfo.requireLabel:setText( language:getText("lvl") + Text(" 3") )
							buttoninfo.requireLabel:setVisible(true)
						elseif buttoninfo["require"].value == "Wave" then
							local wave = ( buttoninfo.duration and buttoninfo.timerStart) and tonumber(buttoninfo.duration.value) + tonumber(buttoninfo.timerStart.value) or 0
							buttoninfo.requireLabel:setTextAlignment(Alignment.MIDDLE_CENTER)
							buttoninfo.requireLabel:setText( language:getText("w") + Text(" "..tostring(wave)) )
							buttoninfo.requireLabel:setVisible(true)
						elseif buttoninfo["require"].value == "shop required" then
							buttoninfo.requireLabel:setTextAlignment(Alignment.MIDDLE_LEFT)
							buttoninfo.requireLabel:setText( language:getText("shop"))
							buttoninfo.requireLabel:setVisible(true)
						elseif buttoninfo["require"].value == "not your tower" then
							buttoninfo.requireLabel:setTextAlignment(Alignment.MIDDLE_CENTER)
							buttoninfo.requireLabel:setText( Text("Lock"))
							buttoninfo.requireLabel:setVisible(true)
						elseif buttoninfo["require"].value == "conflicting upgrade" then
							buttoninfo.requireLabel:setTextAlignment(Alignment.MIDDLE_CENTER)
							buttoninfo.requireLabel:setText( Text("Lock"))
							buttoninfo.requireLabel:setVisible(true)
						end
					else
						buttoninfo.requireLabel:setVisible(false)
					end
				end
				
				if buttoninfo.isOwner ~= nil then
					buttoninfo.button:setEnabled(false)
				end
				
				--boost button, only allowed on boost button
				if buttoninfo.timerStart ~= nil and buttoninfo.duration ~= nil and name == "upgrade2" then
					
					if tonumber(buttoninfo.duration.value) == 10 then
						--count down in seconds
						local str = tostring(math.round( (tonumber(buttoninfo.duration.value) + tonumber(buttoninfo.timerStart.value)) - Core.getGameTime() ))
						if buttoninfo.timeLabel then
							--update time text
							buttoninfo.timeLabel:setText(str)						
						else
							--create time text
							local timeLabel = buttoninfo.button:add(Label(PanelSize(Vec2(-1)), str, MainMenuStyle.textColor, Alignment.MIDDLE_CENTER))
							timeLabel:setCanHandleInput(false)	
							buttoninfo.timeLabel = timeLabel
						end
					elseif buttoninfo.timeLabel then
						--we are waiting for the right wave
						buttoninfo.timeLabel:setVisible(false)
					end
				end
				
				updateToolTip(buttoninfo.button, buttoninfo)
			else
				--make usre we have a icon id
				if not buttoninfo.icon then buttoninfo.icon = {value=0} end
				
				local texture = Core.getTexture("icon_table.tga")
				local offset = Vec2((buttoninfo.icon.value%8)*0.125, math.floor(buttoninfo.icon.value/8)*0.0625)
				local button = Button(PanelSize(Vec2(-1), Vec2(1)), ButtonStyle.SIMPLE, texture, offset, offset+Vec2(0.125, 0.0625))
				
				local levelPanel = nil
				local level = 0
				if buttoninfo.level ~= nil and buttoninfo["name"].value ~= "rotate" and buttoninfo["name"].value ~= "boost" then
					level = buttoninfo.level.value
					levelPanel = button:add(Panel(PanelSize(Vec2(-1))))
					levelPanel:setCanHandleInput(false)
					levelPanel:setBackground(Sprite( texture, Vec2(0.625 + (level-1) * 0.125,0.3125), Vec2(0.625 + level * 0.125, 0.375)))
					
					buttoninfo.level.level = level
					buttoninfo.level.levelPanel = levelPanel
				end
				
				if name ~= "sell" then
					button:setEnabled( buttoninfo.cost ~= nil and (tonumber(buttoninfo.cost.value) <= billboardStats:getDouble("gold")) )
					button:addEventCallbackExecute(onExecute)
				else
					button:setEnabled(buildingBillBoard:getBool("isNetOwner"))
					button:addEventCallbackExecute(sellTower)
				end
				button:setTag(name..";"..tostring(buttoninfo.cost and buttoninfo.cost.value or 0)..(buttoninfo.level and ";"..tostring(buttoninfo.level.level) or ""))
	
				button:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
				button:setInnerHoverColor(Vec4(Vec3(1.3),0.2),Vec4(Vec3(1.3),0.4), Vec4(Vec3(1.3),0.2))
				button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
				
				local costPanel = nil
				local costLabel = nil
				local requireLabel = nil
				local costIcon = nil
				local costIconSprite = nil
				
				costPanel = Panel(PanelSize(Vec2(-1)))
				local text = Text( buttoninfo.cost~=nil and tostring(buttoninfo.cost.value) or "" )
				costLabel = Label(PanelSize(Vec2(-1),Vec2(2,1)), text, Vec4(1))
				costLabel:setTextHeight(-0.75)
				requireLabel = Label(PanelSize(Vec2(-1)), "Lvl2", Vec4(0.8,0.2,0.2,1))
				requireLabel:setTextHeight(-0.75)
				requireLabel:setVisible(false)
				costIcon = Panel(PanelSize(Vec2(-1),Vec2(1)))
				costIconSprite = Sprite(texture)
				costIconSprite:setUvCoord(Vec2(), Vec2(0.125,0.0625))
				costIcon:setBackground(costIconSprite)
				costPanel:add(Panel(PanelSize(Vec2(-1),Vec2(-0.125,-1))))
				costPanel:add(costLabel)
				costPanel:add(costIcon)
				costPanel:add(requireLabel)
				costPanel:setCanHandleInput(false)
				
				if buttoninfo.cost == nil then
					costLabel:setVisible(false)
					costIcon:setVisible(false)
					if buttoninfo["require"] ~= nil then
						print("\nrequire.value="..buttoninfo["require"].value.."\n")
						if buttoninfo["require"].value == "tower level 2" then
							requireLabel:setText("LvL 2")
							requireLabel:setVisible(true)
						elseif buttoninfo["require"].value == "tower level 3" then
							requireLabel:setText("LvL 3")
							requireLabel:setVisible(true)
						elseif buttoninfo["require"].value == "Wave" then
							local wave = ( buttoninfo.duration and buttoninfo.timerStart) and tonumber(buttoninfo.duration.value) + tonumber(buttoninfo.timerStart.value) or 0
							requireLabel:setTextAlignment(Alignment.MIDDLE_CENTER)
							requireLabel:setText(language:getText("w") + Text(" "..tostring(wave)))
							requireLabel:setVisible(true)
						elseif buttoninfo["require"].value == "shop required" then
							requireLabel:setTextAlignment(Alignment.MIDDLE_LEFT)
							requireLabel:setText( language:getText("shop"))
							requireLabel:setVisible(true)
						elseif buttoninfo["require"].value == "not your tower" then
							requireLabel:setTextAlignment(Alignment.MIDDLE_CENTER)
							requireLabel:setText( Text("Lock"))
							requireLabel:setVisible(true)
						elseif buttoninfo["require"].value == "conflicting upgrade" then
							requireLabel:setTextAlignment(Alignment.MIDDLE_CENTER)
							requireLabel:setText( Text("Lock"))
							requireLabel:setVisible(true)
						end
					end
				end
				
				
				--boost button timer, only allowed on boost button
				if buttoninfo.timerStart ~= nil and buttoninfo.duration ~= nil and name == "upgrade2" then
					if tonumber(buttoninfo.duration.value) == 10 then
						local str = tostring(math.round( (tonumber(buttoninfo.duration.value) + tonumber(buttoninfo.timerStart.value)) - Core.getGameTime() ))
						local timeLabel = button:add(Label(PanelSize(Vec2(-1)), str, MainMenuStyle.textColor, Alignment.MIDDLE_CENTER))
						timeLabel:setCanHandleInput(false)	
						buttoninfo.timeLabel = timeLabel			
					end
				end
				
				
	--			duration = 10
	--			timerStart = 32.568678027869
	--			
	--			duration = 3
	--			timerStart = 3
				
				
				buttoninfo.button = button
				buttoninfo.costLabel = costLabel
				buttoninfo.costIcon = costIcon
				buttoninfo.requireLabel = requireLabel
				buttoninfo.costIconSprite = costIconSprite
				buttoninfo.added = true
				
	--			print("buttoninfo.info: \""..tostring(buttoninfo.info).."\" <-----------")
				
				
				if name == "upgrade1" or name ==  "upgrade2" then
					if name == "upgrade2" then
						MainButtonPanel:add(Panel(PanelSize(Vec2(-1))))
						MainButtonCostPanel:add(Panel(PanelSize(Vec2(-1))))
						
						towerInfo.rangeChangePanel = MainButtonPanel:add(Panel(PanelSize(Vec2(-1))))
						MainButtonCostPanel:add(Panel(PanelSize(Vec2(-1))))
						
						MainButtonPanel:add(Panel(PanelSize(Vec2(-1))))
						MainButtonCostPanel:add(Panel(PanelSize(Vec2(-1))))
					end
					local buttonHidePanel = Panel(PanelSize(Vec2(-1)))
					MainButtonPanel:add(buttonHidePanel)
					buttonHidePanel:add(button)
					
					
					--Only upgrade panel of the main buttons cost anythinge
					button:setToolTipParentpanel(costPanel)
					
					if costPanel then
						MainButtonCostPanel:add(costPanel)
					end
					
					if name == "upgrade2" then
						costLabel:setVisible(false)
						costIcon:setVisible(false)
--						costPanel:setVisible(false)
					else
						button:addEventCallbackExecute(updateTowerName)
					end
					
				elseif name == "sell" then
					local sellPanel = inoPanelTopRight:add(Panel(PanelSize(Vec2(-1),Vec2(3,1))))
					sellPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
					sellPanel:add(button)
				elseif buttoninfo.info ~= nil and buttoninfo["name"].value == "rotate" then
					towerInfo.rangeChangePanel:add(button)
				else
					local index = buttonPanels.index
					if buttoninfo["name"] then
						if buttoninfo["name"].value == "range" then
							index = 5
							button:addEventCallbackMouseFocusGain(towerShowRange)
							button:addEventCallbackMouseFocusLost(towerHideRange)
							button:addEventCallbackExecute(updateRangeButton)
						elseif buttoninfo["name"].value == "smartTargeting" then
							index = 4
						else
							buttonPanels.index = buttonPanels.index + 1
						end
					else
						buttonPanels.index = buttonPanels.index + 1
					end
					buttonPanel[index]:add(button)
					button:setToolTipParentpanel(costPanel)
					
					if costPanel then
						buttonCostPanels[index]:add(costPanel)
					end
				end
				
				if buttoninfo.isOwner ~= nil then
					button:setEnabled(false)
				end
				
				updateToolTip(buttoninfo.button, buttoninfo)
			end
		else
			--this button has been removed or was never added
			if buttoninfo.button then
				buttoninfo.button:setVisible(false)	
			end
			if buttoninfo.costLabel then
				buttoninfo.costLabel:setVisible(false)
				buttoninfo.costIcon:setVisible(false)
			end
			if buttoninfo.requireLabel then
				buttoninfo.requireLabel:setVisible(false)
			end
			
			if not buttoninfo.added then
				if name == "upgrade1" or name ==  "upgrade2" then
					if name == "upgrade2" then
						MainButtonPanel:add(Panel(PanelSize(Vec2(-1))))
						MainButtonCostPanel:add(Panel(PanelSize(Vec2(-1))))
						
						buttoninfo.rangeChangePanel = MainButtonPanel:add(Panel(PanelSize(Vec2(-1))))
						MainButtonCostPanel:add(Panel(PanelSize(Vec2(-1))))
						
						MainButtonPanel:add(Panel(PanelSize(Vec2(-1))))
						MainButtonCostPanel:add(Panel(PanelSize(Vec2(-1))))
					end
					MainButtonPanel:add(Panel(PanelSize(Vec2(-1))))
					MainButtonCostPanel:add(Panel(PanelSize(Vec2(-1))))
				
				else
					buttonPanel:add(Panel(PanelSize(Vec2(-1))))
					buttonCostPanel:add(Panel(PanelSize(Vec2(-1))))
				end
				
				buttoninfo.added = true
			end
			
			towerInfo.buttonsInfo[name] = nil
		end
		print("====================")
	end
	
	local function buildToolTipPanelForUpgradeInfo(info)
		--statsOrder =  {"damage", "dmg","RPS","range", "slow","bladeSpeed", "fireDPS","burnTime","dmg_range"}
		local panel = Panel(PanelSize(Vec2(-1)))
		panel:setLayout(FallLayout())
		panel:getPanelSize():setFitChildren(true, true)
		
		local infoValueText = (info.info and info.info or "")
		local textLabel = Label(PanelSize(Vec2(-1)), language:getTextWithValues(infoValueText, (info.value1 ~= nil) and tostring(info.value1) or "", (info.value2 ~= nil) and tostring(info.value2) or ""), Vec4(1) )
		textLabel:setTextHeight(0.015)
		textLabel:setPanelSizeBasedOnTextSize()
		panel:add(textLabel)
		
		local totalPanelSizeInPixel = textLabel:getPanelSize():getSize()
		for name, data in pairs(info.stats) do
	
			local inList = false
			for i=1, #statsOrder do
				if statsOrder[i] == name then
					inList = true
				end
			end
			
			if inList then
				local row = Panel(PanelSize(Vec2(-1,0.025),Vec2(5,1)))
				local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga"))
				local minCoord, maxCoord, text = getUvCoordAndTextFromName(name)
				icon:setUvCoord(minCoord,maxCoord)
				icon:setToolTip(text)
								
				local notifyText = nil
				if data[2] and data[3] then
					local fontTag = "<font color=rgb(255,255,255)>"
					if data[2] > 0 then
						fontTag = "<font color=rgb(40,255,40)>+"
					elseif data[2] < 0 then
						fontTag = "<font color=rgb(255,50,50)>"
					end
					notifyText = fontTag .. data[2] .. data[3] .. "</font>\n"
				end
				
				print("\n\n----(1)  "..(data[2] and data[2] or "<null>"))
				print("----(2)  "..(data[3] and data[3] or "<null>").."\n\n")
				
				if notifyText then
					row:add(icon)
					local label = row:add(Label(PanelSize(Vec2(-1)), notifyText, Vec3(1.0)))
					panel:add(row)
					totalPanelSizeInPixel = totalPanelSizeInPixel + Vec2(0, 0.025 * Core.getScreenResolution().y )
				end
				
			end				
		end
		
		panel:setPanelSize(PanelSize(totalPanelSizeInPixel, PanelSizeType.Pixel)	)
		return panel
		
	end
	
	local function updateUpgradeInfoIcons()
		
		--print("\n\nupdateUpgradeInfoIcons\n")
		local upgradeInfo = buildingBillBoard:getTable("upgraded")
		if upgradeInfoText == nil or (upgradeInfo and upgradeInfoText.version ~= upgradeInfo.version ) then
	--		print("upgradeInfoText: \""..(upgradeInfoText and upgradeInfoText or "").."\"")
	--		print("upgradeInfo: \""..upgradeInfo.."\"")
			upgradeInfoText = upgradeInfo
			upgradesPanel:clear();
			
			local texture = Core.getTexture("icon_table.tga")
			for i=2, 10 do 
				if upgradeInfo[i] then
					local info = upgradeInfo[i]
					local offset = Vec2((info.icon%8)*0.125, math.floor(info.icon/8)*0.0625)
					
					local image = upgradesPanel:add(Image(PanelSize(Vec2(-1,-1), Vec2(1.0,1.0)), Text("icon_table.tga")))
					image:setUvCoord(offset,offset+Vec2(0.125, 0.0625))
					image:setBackground(Sprite( Vec3(0) ))
					image:setToolTip(buildToolTipPanelForUpgradeInfo(info))
				end
			end
		end
	end
	
	local function changedTargetSystem(tag, index, items)
		comUnit:sendTo(buildingScript:getIndex(),"SetTargetMode",tostring(index))
	end
	
	local function getAllDamageFromTowers()
		local playerNode = this:getRootNode()
		local builderNode = playerNode:findNodeByTypeTowardsLeafe(NodeId.buildNode)
		local buildingList = builderNode:getBuildingList()
		
		local totalDamage = 1
		local maxTowerDamage = 1
		for i=1, #buildingList do
			local buildingScript = buildingList[i]:getScriptByName("tower")
			if buildingScript then
				local billBoard = buildingScript:getBillboard()
				if billBoard:getBool("isNetOwner") and billBoard:getString("Name")~="Support tower" then
					local towerDamage = billBoard:getDouble("DamagePreviousWave")
					--towerDamage = billBoard:exist("DamagePreviousWavePassive") and (towerDamage + billBoard:getDouble("DamagePreviousWavePassive")) or towerDamage
					totalDamage = totalDamage + towerDamage
					maxTowerDamage = math.max(maxTowerDamage, towerDamage)
				end
			end
		end
		
		return totalDamage, maxTowerDamage
	end
	
	function self.waveChanged(param)
		callChangeWave = 2	
	end
	
	local function getDamageToolTipText()
		local totalDamage, maxDamage = getAllDamageFromTowers()
		local damage = buildingBillBoard:getDouble("DamagePreviousWave")
		local totalCost = buildingBillBoard:getDouble("totalCost")
		local damageToolTip = Text(tostring(math.round(damage/totalCost)).." ") + language:getText("damage per gold") + Text("\n")
		damageToolTip = damageToolTip + Text(tostring(math.round(damage)).." ") + language:getText("damage delt to enemies") 
		local passivDamageTextAdded = false
		if buildingBillBoard:exist("DamagePreviousWavePassive") then
			passivDamage = buildingBillBoard:getDouble("DamagePreviousWavePassive")
			if passivDamage > 1 then
				if damage < 1 then
					damageToolTip = Text("")
				else
					damageToolTip = damageToolTip + Text("\n")
				end
				
				passivDamageTextAdded = true
				damageToolTip = damageToolTip + Text(tostring(math.round(passivDamage/totalCost)).." ") + language:getText("damage per gold") + Text("\n")
				damageToolTip = damageToolTip + Text(tostring(math.round(passivDamage)).." ") + language:getText("damage delt to enemies") 
			end
		end
		
		if buildingBillBoard:exist("goldEarned") then
			goldEarned = math.round(buildingBillBoard:getDouble("goldEarned"))
			goldEarnedPreviousWave = math.round(buildingBillBoard:getDouble("goldEarnedPreviousWave"))
			if goldEarned > 1 then
				if damage < 1 and not passivDamageTextAdded then
					damageToolTip = Text("")
				else
					damageToolTip = damageToolTip + Text("\n")
				end
				
				damageToolTip = damageToolTip + Text(tostring(goldEarned).." ") + language:getText("gold earned") + Text("\n")
				damageToolTip = damageToolTip + Text(tostring(goldEarnedPreviousWave).." ") + language:getText("gold earned previous wave") 
			end
		end
		return damageToolTip
	end
	
	local function updateTowerDamageInfo(progressBar)
		local totalDamage, maxDamage = getAllDamageFromTowers()
		local damage = buildingBillBoard:getDouble("DamagePreviousWave")
		local damageToolTip = getDamageToolTipText()
		local damageValues = {damage / maxDamage, 0, 0}
		if buildingBillBoard:exist("DamagePreviousWavePassive") then
			local passivDamage = buildingBillBoard:getDouble("DamagePreviousWavePassive")
			damage = damage + passivDamage
			if passivDamage > 1 then
				damageValues[2] = passivDamage / maxDamage
			end
		end
		
		if buildingBillBoard:exist("goldEarnedPreviousWave") then
			goldEarnedPreviousWave = buildingBillBoard:getDouble("goldEarnedPreviousWave")
			if goldEarnedPreviousWave > 1 then
				damageValues[3] = goldEarnedPreviousWave / 300
			end
		end
		progressBar:setValue(damageValues)
		progressBar:setToolTip( damageToolTip )
		progressBar:setText( tostring((math.round((damage / maxDamage)*1000)/10)).."%" )
		progressBar:setInnerColor(Vec4(Vec3(0), 1), Vec4(Vec3(0), 1))
		progressBar:setColor({Vec4(0.5*0.7, 1.1*0.7, 0.5*0.7, 0.75), Vec4(0.0, 0.65*0.7, 0.0, 0.75), Vec4(1.1*0.7, 0.5*0.7, 0.3*0.7, 0.75), Vec4(1.1*0.4, 0.5*0.4, 0.0, 0.75), Vec4(0.94, 0.94, 0.61, 0.75), Vec4(0.61, 0.61, 0.4, 0.75)})
	end
	
	local function updateButtons()

	
		local numUpgradeButtons = buildingBillBoard:getInt("numupgrades")
		
		
		if not towerInfo.buttonsInfo then
			towerInfo.buttonsInfo = {}
			storedButtonsInfo = {}
			buttonPanel:clear()
			MainButtonPanel:clear()
			infopanelRight:clear()
			MainButtonCostPanel:clear()
			buttonCostPanel:clear()
			retargetPanel:clear()
			towerValue = 0
			showRange = false
			targetModes = {}
			
			
			infopanelRight:setLayout(FallLayout(Alignment.BOTTOM_RIGHT))
			
			
			local targetModsString = buildingBillBoard:getString("targetMods")
			
			for splitedStr in (targetModsString .. ";"):gmatch("([^;]*);") do 
				targetModes[#targetModes + 1] = language:getText( splitedStr )
			end
			
			if targetModsString ~= "" then
				retargetPanel:setVisible(true)
				targetComboBox = SettingsComboBox.new(retargetPanel,PanelSize(Vec2(-1)), targetModes, "targeting", "WeakestUnit", changedTargetSystem)
				targetComboBox.setIndex(buildingBillBoard:getInt("currentTargetMode"))	
			else
				retargetPanel:setVisible(false)
			end
			updateTowerDamageInfo( damageInfoBar )
			

			inoPanelTopRight = infopanelRight:add(Panel(PanelSize(Vec2(-1))))
			
			buttonPanels = {}
			buttonPanels.index = 1
			buttonCostPanels = {}
			for i=1, 5 do
				buttonPanel[i] = buttonPanel:add(Panel(PanelSize(Vec2(-1))))
				buttonCostPanels[i] = buttonCostPanel:add(Panel(PanelSize(Vec2(-1))))
			end
			
			for i=1, numUpgradeButtons, 1 do
				storedButtonsInfo[i] = buildingBillBoard:getString("upgrade"..i)
				if storedButtonsInfo[i] ~= "" then
					updateButton("upgrade"..i, storedButtonsInfo[i])
				else
					updateButton("upgrade"..i, nil)
				end
			end
			
			updateButton("sell","info=\"sell tower\";")
			
			
			--target modes
			
			
		else
			local infoNames = {}
			infoNames[1] = "sell"
			for i=1, numUpgradeButtons, 1 do
				local text = buildingBillBoard:getString("upgrade"..i)
				infoNames[#infoNames + 1] = "upgrade"..i
				if storedButtonsInfo[i] ~= text then
					storedButtonsInfo[i] = text
					if storedButtonsInfo[i] ~= "" then
						updateButton("upgrade"..i,text)
					else
						updateButton("upgrade"..i,nil)
					end
				else
					local buttoninfo = towerInfo.buttonsInfo["upgrade"..i]
					if buttoninfo and buttoninfo.button and i ~= 2 then
						local enable = buttoninfo.cost ~= nil and (tonumber(buttoninfo.cost.value) <= billboardStats:getDouble("gold"))
						buttoninfo.button:setEnabled( enable )
						if buttoninfo.costLabel then
							buttoninfo.costLabel:setTextColor( enable and Vec4(1) or Vec4(0.8,0.2,0.2,1))
							buttoninfo.costIconSprite:setColor(enable and Vec4(1) or Vec4(Vec3(0.7),1))
							buttoninfo.costIcon:setBackground(buttoninfo.costIconSprite)
						end
					end
					
					--update boost info
					if i == 2 and buttoninfo.timerStart ~= nil and buttoninfo.duration ~= nil and buttoninfo.timeLabel and tonumber(buttoninfo.duration.value) == 10 then
						local num = math.round( (tonumber(buttoninfo.duration.value) + tonumber(buttoninfo.timerStart.value)) - Core.getGameTime() )
						if num > 0 then
							buttoninfo.timeLabel:setText(tostring(num))						
						end
					end
					
				end
			end
			if towerValue ~= buildingBillBoard:getInt("value") then
				towerValue = buildingBillBoard:getInt("value")
				updateButton("sell","info=\"sell tower\";")
			end
			
			updateUpgradeInfoIcons()
		end
	end
	
	local function showWallBuildingInformation(button)
		local towerNode = buildingBillboard:getSceneNode(button:getTag():toString())
		--print("\n\n\nShow Node\n")
		if towerNode then	
			--print("\n\n\nTower Node found\n")
			local buildingScript = towerNode:getScriptByName("tower")					
			local billBoard = buildingScript:getBillboard()
			
			----------------------
			------ Load text -----
			----------------------
			
	--		local wallTowerScript = buildingLastSelected:getScriptByName("tower")
	--		local wallTowerCost = wallTowerScript:getBillboard():getFloat("buildCost")
			
			header:setText(billBoard:getString("Name"))
	--		leftPanel:clear()		
		end
	end
	
	
	
--	function self.netUpgradeWallTower(param)
--		--print("netUpgradeWallTower()\n")
--		local tab = totable(param)
--		local building = Core.getScriptOfNetworkName(tab.netName):getParentNode()
--		uppgradeWallTower(building, 0, tab.upgToScripName, nil, tab.tName, false, tab.playerId )
--	end
	
	local function clearWallBuildingInformation(button)
		if selectedBuildingType == 2 then
	--		leftPanel:clear()
		end
	end
	
	local function updateBars()
		energyBar:setVisible(buildingBillBoard:exist("energy") and buildingBillBoard:exist("energyMax") );
		overHeatBar:setVisible(buildingBillBoard:exist("overHeatPer"))
		xpBar:setVisible(buildingBillBoard:exist("xp"))
	end
	
	local function updateWallTowerButtons()
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
			local enable = buildingBillBoard:getBool("isNetOwner") and upgradeBuildCost <= billboardStats:getDouble("gold")
			wallTowerButtons[i]:setEnabled(enable)
			wallTowerCostLabels[i]:setTextColor(enable and Vec4(1) or Vec4(0.8,0.2,0.2,1))
		end
	end
	
	local function initSelectedMenu()
		print("initSelectedMenu")
		buttonPanel:clear()
		towerInfo = {}
		
		storedNumStats = 0
		storedShowText = ""
		
		selectedBuildingType = 0
		storedNumButtons = 0
		storedButtonsInfo = {}
		storedButtonsInfo.size = 0
		upgradeInfoText = ""
		if buildingLastSelected then
			buildingScript = buildingLastSelected:getScriptByName("tower")
			if buildingScript then
				buildingBillBoard = buildingScript:getBillboard()
				
				currentTowerName = string.lower( buildingBillBoard:getString("Name") )
				
--				print("building bilboard: ".. buildingBillBoard:toString())
				
				--force a resize of the panel
				form:setVisible(false)
				form:setVisible(true)
				if currentTowerName == "wall tower" then
					selectedBuildingType = 2
					header:setText(Text("<b>")+language:getText(currentTowerName))
					initWallTower()
					print("Change panelSize to wallTower size")
					leftMainPanel:setPanelSize(PanelSize(Vec2(-1),Vec2(1,1.18)))
					wallTowerPanel:setVisible(true)
					towerPanel:setVisible(false)
					imagePanel:setVisible(false)
					targetArea.hiddeTargetMesh()
					
					updateWallTowerButtons()
					--columns
					--buildingBillBoard:getBool("isNetOwner")
				else
					
					print("Change panelSize to tower size")
					updateTowerName(nil)
					--this panel is hidden when not in use
					local sizeDiff = buildingBillBoard:getString("targetMods") ~= "" and 0 or (1.0/9.0)
					leftMainPanel:setPanelSize(PanelSize(Vec2(-1),Vec2(1,1.4 - sizeDiff)))
					wallTowerPanel:setVisible(false)
					towerPanel:setVisible(true)
					imagePanel:setVisible(true)
					
					selectedBuildingType = 1
					
					buttonPanel:clear()
					MainButtonPanel:clear()
					infoPanel:clear()				
					
					updateBars()
					
					updateText()
					updateButtons()
				end
				
				updateUpgradeInfoIcons()
				
			end
			buildingLastSelected:addChild(selectedCamera:toSceneNode())
					
			local camMatrix = Matrix();
			local camPos = Vec3(4,6,4)
			camMatrix:createMatrix((camPos-Vec3(0,1.5,0)):normalizeV(), Vec3(0,1,0))
			camMatrix:setPosition(camPos)
			selectedCamera:setLocalMatrix(camMatrix)
			
			local contentSize = towerImagePanel:getPanelContentPixelSize()
			if contentSize.x < 32 then
				contentSize.x = 32
			end
			if contentSize.y < 32 then
				contentSize.y = 32
			end
			
			selectedCamera:setFrameBufferSize(contentSize * 2)
		end
	end
	
	function self.updateSelectedTower()
--		abort()
		if form:getVisible() then
			
			initSelectedMenu()
		end
	end
	
	initSelectedmenuFunction = initSelectedMenu
	
	local function getUpgradeInfoFromBilboard(upgradeName, bilboard)
		local result = bilboard:getString(upgradeName)
		--print( "upgrade: "..result.."\n" )
		
		local tag = upgradeName
		local cost = nil
		local icon = nil
		local duration = nil
		local timerStart = nil
		local cooldown = nil
		local notifyText = ""
		local requireText = ""
		for splitedStr in (result .. ";"):gmatch("([^;]*);") do 
			local array, size = splitFirst(splitedStr, "=")
			if size == 2 then
				--print("string: "..splitedStr.."\n")
				if array[1] == "cost" then  
					cost = tonumber(array[2])
				elseif array[1] == "icon" then  
					icon = tonumber(array[2])
				elseif array[1] == "duration" then  
					duration = tonumber(array[2])
				elseif array[1] == "timerStart" then  
					timerStart = tonumber(array[2])
				elseif array[1] == "cooldown" then
					cooldown = tonumber(array[2])
					if cooldown < Core.getGameTime()-0.01 then
						cooldown = nil
					end
				elseif array[1] == "require" then  
					requireText = array[2]
				else
					
					local newString = array[2]:gsub("\"", "")
	
					if newString == array[2] then--is number
						local fontTag = "<font color=rgb(255,255,255)>"
						if tonumber(array[2]) > 0 then
							fontTag = "<font color=rgb(40,255,40)>+"
						elseif tonumber(array[2]) < 0 then
							fontTag = "<font color=rgb(255,50,50)>"
						end
						notifyText = notifyText .. array[1] .. ": " .. fontTag .. array[2] .. "</font>\n"
						
						
					else--is string
						if array[1] == "info" then
							notifyText = notifyText .. newString .. "\n"
						else
							notifyText = notifyText .. array[1] .. ": " .. newString .. "\n"
						end							
					end
					
				end
	 		end
		end
		
		return cost, icon, duration, timerStart, cooldown, notifyText, requireText
	end
	
	local function getUpgradeInfo(upgradeName)
		return getUpgradeInfoFromBilboard(upgradeName, buildingBillBoard)
	end
	
	local function getTowerInfo()
		if buildingLastSelected then
			buildingScript = buildingLastSelected:getScriptByName("tower")
			if buildingScript then
				local billBoard = buildingScript:getBillboard()
				if billBoard:getBool("isNetOwner") then
					return true, billBoard, buildingScript
				end
			end
		end
		return false
	end
	
	local function upgradeTower(building)
	
		local script = buildingScript
		local bilboard = buildingBillBoard
		local oldBuilding = buildingLastSelected
		
		buildingLastSelected = building
		if building then	
			buildingScript = building:getScriptByName("tower")
			if buildingScript then
				buildingBillBoard = buildingScript:getBillboard()
			else
				buildingBillBoard = nil
			end
		else
			buildingBillBoard = nil
			buildingScript = nil
		end
		
		if getTowerInfo() then
			local cost = getUpgradeInfo("upgrade1")
			if cost then
				handleUpgrade(cost, "upgrade1", tostring(building:getScriptByName("tower"):getBillboard():getInt("level")+1) )
			end
		end
		
		buildingLastSelected = oldBuilding
		buildingScript = script
		buildingBillBoard = bilboard		
	end
	
	local function sellTowerKeyBind(building)
		
		
		if getTowerInfo() then
			sellTower()
		end
		
	end
	
	local function boostTower(building)
		local script = buildingScript
		local bilboard = buildingBillBoard
		local oldBuilding = buildingLastSelected
		
		buildingLastSelected = building
		if building then	
			buildingScript = building:getScriptByName("tower")
			if buildingScript then
				buildingBillBoard = buildingScript:getBillboard()
			else
				buildingBillBoard = nil
			end
		else
			buildingBillBoard = nil
			buildingScript = nil
		end
		
		if getTowerInfo() then
			local cost = getUpgradeInfo("upgrade2")
			if cost then
				handleUpgrade(cost, "upgrade2", "1")
			end
		end
		
		buildingLastSelected = oldBuilding
		buildingScript = script
		buildingBillBoard = bilboard	
	end
	
	local function isMouseInMainPanel()
		return billboardStats:getPanel("MainPanel") == Core.getPanelWithMouseFocus()
	end
	
	function self.getVisible()
		return towerPanel:getVisible()
	end
	
	function self.setVisible(visible)
		wallTowerPanel:setVisible(visible)
		towerPanel:setVisible(visible)
		imagePanel:setVisible(visible)
		if not visible then
			buildingLastSelected = nil
			targetArea.setRenderTarget(nil)
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
	
	local function showAllTowerThatCanBeBoosted(show)
		if showBoostableTowers == show then
			return
		end
		
		local playerNode = this:findNodeByType(NodeId.playerNode)
		local buildNode = playerNode:findNodeByType(NodeId.buildNode)
		--buildNode = buildNode()
		if buildNode then
			showBoostableTowers = show
			if show then
				buildingList = buildNode:getBuildingList()
--				print("\n\nWave: "..billboardStats:getInt("wave"))
				for key, node in pairs(buildingList) do
					
					local script = node:getScriptByName("tower")
					local scriptBilboard = script and script:getBillboard() or nil
					
					if script and scriptBilboard and scriptBilboard:getString("Name") ~= "Wall tower" and scriptBilboard:getBool("isNetOwner") then
						local cost, icon, duration, timerStart, cooldown, notifyText, requireText = getUpgradeInfoFromBilboard("upgrade2", script:getBillboard())
--						print("cost: "..(cost and cost or "nil"))
--						print("requireText: "..(requireText and requireText or "nil"))
						if cost or requireText == "\"Wave\"" then
							if cost then
								setGlowColor( node, Vec3(0.05,0.05,0.18) )
							elseif duration and timerStart then
								local waveLeft = (duration + timerStart) - billboardStats:getInt("wave")
								if waveLeft == 3 then
									setGlowColor( node, Vec3(0.18,0.05,0.05) )
								elseif waveLeft == 2 then
									setGlowColor( node,  Vec3(0.12,0.12,0.05) )
								else
									setGlowColor( node,  Vec3(0.012,0.05,0.012) )
								end
							else
								setGlowColor( node, Vec3(0.05,0.05,0.18) )
							end
						else
							setGlowColor( node, Vec3(0.05,0.15,0.05) )
						end
					end
				end
			else
				for key, node in pairs(buildingList) do
					setNodeNotBoostable(node)
				end
			end
		end
	end
	
	local function funcWaveChanged()
		if damageInfoBar and buildingBillBoard and form:getVisible() then
			updateTowerDamageInfo( damageInfoBar )
		end
		
		if showBoostableTowers then
			showBoostableTowers = false
			showAllTowerThatCanBeBoosted(true)
		end
	end
	
	function self.update()
		--when in game menu is shown hide selected tower menu
		if esqKeyBind:getPressed() or buildingNodeBillboard:getBool("inBuildMode") then
			form:setVisible(false)
			targetArea.hiddeTargetMesh()
		end
		
		
		--show boostable towers
		showAllTowerThatCanBeBoosted(keyBindBoostBuilding:getHeld())

		if showBoostableTowers then	

			local i=1	
			while #updateBoostTimer >= i do
				local node = updateBoostTimer[i].node
				local script = node:getScriptByName("tower")
				
				if script then
					local color = Vec3(0.18,0.05,0.05)
					local cost, icon, duration, timerStart, cooldown, notifyText, requireText = getUpgradeInfoFromBilboard("upgrade2", script:getBillboard())
--						print("cost: "..(cost and cost or "nil"))
--						print("requireText: "..(requireText and requireText or "nil"))
					if cost or requireText == "\"Wave\"" then
						if cost then
							color = Vec3(0.05,0.05,0.18)
						elseif duration and timerStart then
							local waveLeft = (duration + timerStart) - billboardStats:getInt("wave")
							if waveLeft == 3 then
								scolor = Vec3(0.18,0.05,0.05)
							elseif waveLeft == 2 then
								color = Vec3(0.12,0.12,0.05)
							else
								color = Vec3(0.012,0.05,0.012)
							end
						else
							color = Vec3(0.05,0.05,0.18)
						end
					else
						color = Vec3(0.05,0.15,0.05)
					end
					
					if color ~= updateBoostTimer[i].color then
						updateBoostTimer[i].color = color
						setGlowColor( node, color )
					end
				end
				
				if updateBoostTimer[i].time < Core.getGameTime() then
					table.remove( updateBoostTimer, i )
					updateBoostColors = true
				else
					i = i + 1
				end
			end
		end
		
		if Core.getInput():getMouseDown(MouseKey.left) and not buildingNodeBillboard:getBool("inBuildMode") and buildingNodeBillboard:getBool("canBuildAndSelect") and isMouseInMainPanel() then
			local playerNode = this:findNodeByType(NodeId.playerNode)
			local buildNode = playerNode:findNodeByType(NodeId.buildNode)
			--buildNode = buildNode()
			if buildNode then
				
				local building = buildNode:getBuldingFromLine(camera:getWorldLineFromScreen(Core.getInput():getMousePos()))
				if building then
					if buildingLastSelected ~= building then
						print("tower selected")
						
						if keyBindUpgradeBuilding:getHeld() then
							print("uppgrade tower")
							upgradeTower(building)
						elseif keyBindBoostBuilding:getHeld() then
							print("boost tower")
							boostTower(building)
							setGlowColor( building, Vec3(0.05,0.15,0.05) )
							updateBoostTimer[#updateBoostTimer + 1] = {time=Core.getGameTime() + 15, node = building}
							setNodeNotBoostable(building)
						else
							print("Selected tower")
							setVisibleClass(self)
							buildingLastSelected = building
							initSelectedMenu()
							form:setVisible(true)
						end  
					else
						if keyBindUpgradeBuilding:getHeld() then
							upgradeTower(buildingLastSelected)
						elseif keyBindBoostBuilding:getHeld() then
							boostTower(buildingLastSelected)
							setGlowColor( buildingLastSelected, Vec3(0.05,0.15,0.05) )
							if buildingLastSelected then
								updateBoostTimer[#updateBoostTimer + 1] = {time=Core.getGameTime() + 15, node = buildingLastSelected}
							end
							setNodeNotBoostable(buildingLastSelected)
						end
					end
				else
					self.setVisible(false)
					form:setVisible(false)
				end
			end
		end
		
		--if tower has been sold don't show the window
		if buildingLastSelected and buildingLastSelected:getScriptByName("tower") == nil then
			self.setVisible(false)
			form:setVisible(false)
		end
		
		if form:getVisible() then
			
			if keyBindSellBulding:getPressed() then
				sellTowerKeyBind()
			end
			
			if keyBindUpgradeBuilding:getPressed() then
				upgradeTower()
			end
			if keyBindBoostBuilding:getPressed() then
				setNodeNotBoostable(buildingLastSelected)
				setGlowColor( buildingLastSelected, Vec3(0.05,0.15,0.05) )
				if buildingLastSelected then
					updateBoostTimer[#updateBoostTimer + 1] = {time=Core.getGameTime() + 15, node = buildingLastSelected}
				end
				boostTower()
			end  
			
			
			if selectedBuildingType == 1 then
				updateBars()
				updateEnergyBar()
				updateOverHeatBar()
				updateXpBar()
				updateText()
				updateButtons()
				
				if boostLabel and boostTime then
					boostLabel:setText(""..(boostDuration-math.round(Core.getGameTime()-boostTime)))
				end
			elseif selectedBuildingType == 2 then
				updateWallTowerButtons()
			end
			
			if buildingLastSelected then
				
				local rangeLevel = 4
				
				if showRange and towerInfo and towerInfo.buttonsInfo then
	--				print("towerInfo: "..tostring(towerInfo.buttonsInfo))
					for name, data in pairs(towerInfo.buttonsInfo) do
						if data.name and data.level ~= nil and data.name.value == "range" then
							rangeLevel = data.level.level
						end
					end
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
				funcWaveChanged()
			end
		end
	end
	
	init()
	
	return self
end