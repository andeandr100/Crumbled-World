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
	
	local tutorialBillboard = Core.getGameSessionBillboard("tutorial")
	tutorialBillboard:setPanel("selectedTowerPanel", inForm)
	
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
	local infoPanel
	local infopanelRight
	local energyBar
	local overHeatBar
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
	local towerUpdateIndex = -1
	local towerButtonUpdateIndex = -1		
	
	--this = SceneNode()
	local function instalForm()
	
		leftMainPanel:setPanelSize(PanelSize(Vec2(-1)))
--		leftMainPanel:setBackground(Sprite(Vec3(1,0,0)))
	
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
		
		
		--Spacing
		towerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(16,1))))
		damageInfoBar = towerPanel:add(ProgressBar(PanelSize(Vec2(-1),Vec2(9,1)), Text(""), 0))
		
		
		local infoPanelMain = towerPanel:add(Panel(PanelSize(Vec2(-1))))
		

		local tutorialBillboard = Core.getGameSessionBillboard("tutorial")
		tutorialBillboard:setPanel("damageInfoBar", damageInfoBar)
		tutorialBillboard:setPanel("upgradePanel", buttonPanel)
	
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
		
		
		imagePanel = towerImagePanel:add(Panel(PanelSize(Vec2(-1))))
	
		imagePanel:setPadding(BorderSize(Vec4(0.01)))
		imagePanel:add(energyBar)
		imagePanel:add(overHeatBar)
		
	
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
--		statsOrder =  {"damage", "dmg","RPS", "ERPS","range", "slow","bladeSpeed", "fireDPS","burnTime","dmg_range","supportDamage","SupportRange","supportWeaken","weakenValue","supportGold","supportGoldPerWave"}
		statsOrder =  {"damage", "dmg","RPS", "ERPS","range", "slow","bladeSpeed", "fireDPS","burnTime","dmg_range","supportDamage","SupportRange","supportWeaken","weakenValue","supportGold","supportGoldPerWave"}
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
			return buildingScript:getBillboard():getInt("cost")
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
				
				
				
				local x = towers[i]%4
				local y = 2-math.floor((towers[i]/4))
				local start = Vec2(x/4.0, y/4.0)
			
				--print( "textureName: "..texture:getName():toString().."\n")
				--Make sure that information about the tower uppgrade actually exist				
				local button = Button(PanelSize(Vec2(-1,-1), Vec2(1,1),PanelSizeType.ParentPercent), ButtonStyle.SIMPLE, towerTexture, start, start+Vec2(0.25,0.25))
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
			
			createWallTowerPanel(row1, 2, {7,8,-1})
			createWallTowerPanel(row2, 3, {1,2,3})
			createWallTowerPanel(row3, 3, {4,5,6})
			
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
	
		print("handleUpgrade")
		print("COST: "..tostring(cost))
	
		--print("uppgrade building\n")
		if buildingLastSelected then
			print("Building found")
			--print("money on bank " .. billboardStats:getDouble("gold") .. "\n")
			if cost <= billboardStats:getDouble("gold") then
				print("======= "..buyMessage.." =======")
				print("Lua index: " .. buildingScript:getIndex() .. " Message: " .. buyMessage)
				print("comUnit:sendTo(...,"..buyMessage..")")
				print("tab="..tabToStrMinimal({netId=buildingScript:getNetworkName(),cost=0,msg=buyMessage,param=buyMessage..";"..paramMessage}))
				print("")
				
				local clientId = buildingLastSelected:getPlayerNode():getClientId()
				--Core.getNetworkClient():getClientId()
				comUnit:sendTo("stats","removeGold",tostring(cost))
				comUnit:sendTo("builder"..clientId, "buildingSubUpgrade", tabToStrMinimal({netId=buildingScript:getNetworkName(),cost=0,msg=buyMessage,param=buyMessage..";"..paramMessage}))
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

	
	local function onExecute(button)
		print("")
		print("TRY UPGRADE TOWER")
		print("TAG: "..button:getTag():toString())
--		button:clearEvents()
		
		--print("button:getTag()="..button:getTag().."\n")
		if button:getTag():toString() ~= "" then
			--upgrade1;400;2	name;cost;level
			local subString, size = split(button:getTag():toString(), ";")
			
			print("SUBSTRING: "..tostring(subString))
			print("SIZE: "..tostring(size))
			
			if size == 3 and tonumber(subString[2]) then
				handleUpgrade(tonumber(subString[2]), subString[1], tonumber(subString[3]) )
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
		elseif name=="ERPS" then
			return Vec2(0.25,0.375),Vec2(0.375,0.4375), language:getText("charges per second")
		elseif name=="range" then
			return Vec2(0.375,0.4375),Vec2(0.5,0.5), language:getText("target range")
		elseif name=="slow" then
			return Vec2(0.875,0.375),Vec2(1.0,0.4375), language:getText("slow")
		elseif name=="bladeSpeed" then
			return Vec2(0.125,0.25),Vec2(0.25,0.3125), language:getText("blade speed")
		elseif name=="dmg_range" then
			return Vec2(0.875,0.25),Vec2(1.0,0.3125), language:getText("damage range")
		elseif name=="supportDamage" then
			return Vec2(0.0,0.5),Vec2(0.125,0.5625), language:getText("support damage")
		elseif name=="SupportRange" then
			return Vec2(0.125,0.5),Vec2(0.25,0.5625), language:getText("support range")
		elseif name=="weakenValue" then
			return Vec2(0.875,0.1875),Vec2(1.0,0.25), language:getText("selectedTower weaken")	
		elseif name=="supportWeaken" then
			return Vec2(0.25,0.5),Vec2(0.375,0.5625), language:getText("support weaken")
		elseif name=="supportGold" then
			return Vec2(0.375,0.5),Vec2(0.5,0.5625), language:getText("support gold")
		elseif name=="supportGoldPerWave" then
			return Vec2(0.75,0.5), Vec2(0.875, 0.5625), language:getText("support gold per wave")
		else
			return Vec2(0.0,0.25),Vec2(0.125,0.3125), Text("")
		end
	end
	
	local function valueToString(value, decimalLimit)
		--could use math.floor(math.log10) to get the 10^x but why complicate a simple issue
		--2 significants are to little, 3 is almost to much
		decimalLimit = decimalLimit or 3
		if math.abs(value)<0 and decimalLimit>=3 then
			return string.format("%.3f",value)
		elseif math.abs(value)<10 and decimalLimit>=2 then
			return string.format("%.2f",value)
		elseif math.abs(value)<100 and decimalLimit>=1 then
			return string.format("%.1f",value)
		else
			return string.format("%.0f",value)
		end
	end
	
	local function updateText()

		--check if the stats need to be reloaded
		if towerUpdateIndex ~= buildingBillBoard:getInt("updateIndex") then
			towerUpdateIndex = buildingBillBoard:getInt("updateIndex")
			--print("\n\nupdateText()\n")
			local displayStats = buildingBillBoard:getTable("displayStats")
			
			if towerInfo.info then
				local info = towerInfo.info
				for index, statName in ipairs(displayStats) do
					if info[statName] ~= nil and info[statName].label then
						info[statName].valueupg = tonumber(buildingBillBoard:getString(statName.."-upg"))
						info[statName].value = tonumber(buildingBillBoard:getString(statName)) - info[statName].valueupg
						
						local upgradeValue = ""
						if info[statName].valueupg ~= 0 then
							upgradeValue = ( info[statName].valueupg > 0 and "<font color=rgb(0,255,0)>+" or "<font color=rgb(255,0,0)>" ) .. valueToString(info[statName].valueupg) .. "</font>"
						end
						
						info[statName].label:setText(valueToString(info[statName].value,2)..upgradeValue)
					end
					
				end
			else
				--build info
				local info = {}
				towerInfo.info = info
				
				--print("displayStats"..storedShowText)
				for index, statName in ipairs(displayStats) do
					info[statName] = {}
					info[statName].valueupg = tonumber(buildingBillBoard:getString(statName.."-upg"))
					info[statName].value=tonumber(buildingBillBoard:getString(statName)) - info[statName].valueupg
					
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
						local upgradeValue = ""
						if info[name].valueupg ~= 0 then
							upgradeValue = ( info[name].valueupg > 0 and "<font color=rgb(0,255,0)>+" or "<font color=rgb(255,0,0)>" ) .. valueToString(info[name].valueupg) .. "</font>"
						end
						local label = row:add(Label(PanelSize(Vec2(-1)), (info[name].value and valueToString(info[name].value,2) or "-") .. upgradeValue, Vec3(1.0)))
	
						info[name].icon = icon
						info[name].label = label
					end				
				end
			end
		
		end
	end
	
	local function towerShowRange()
		showRange = true
	end
	
	local function towerHideRange()
		showRange = false
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
	
	local function costToShortString(cost)
		local cost = tonumber(cost)
		if cost<1000 then
			return tostring(cost)
		elseif cost>1000 then
			return "1K+"
		else
			return "1K"
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
	
	local function buildToolTipPanelForUpgradeInfo(info)
		local requireText = Text("")
		if info.locked ~= nil then
			
			local requireTextCreated = false
			if info.locked == "tower level 2" or info.locked == "tower level 3" or info.locked == "shop required" or info.locked == "not your tower" then
				requireTextCreated = true
				requireText = Text("<font color=rgb(255,50,50)>")
			end
			
			
			if info.locked == "tower level 2" then
				requireText = requireText + language:getText("tower level") + Text(" 2")
			elseif info.locked == "tower level 3" then
				requireText = requireText + language:getText("tower level") + Text(" 3")
			elseif info.locked == "shop required" then
				requireText = requireText  + language:getText("shop required")
			elseif info.locked == "not your tower" then
				requireText = requireText  + language:getText("not your tower")
			end
			
			if requireTextCreated then
				requireText = requireText + Text("</font><br>")
			end
		end
		
		
		local panel = Panel(PanelSize(Vec2(-1)))
		panel:setLayout(FallLayout())
		panel:getPanelSize():setFitChildren(true, true)
		

		local infoValueText = (info.info and info.info or "")
		local value1 = info.values[1] and tostring(info.values[1]) or ""
		local value2 = info.values[2] and tostring(info.values[2]) or ""
		local textLabel = Label(PanelSize(Vec2(-1)), requireText + language:getTextWithValues(infoValueText, value1, value2), Vec4(1) )
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
				if info.stats[name] then
					
					local row = Panel(PanelSize(Vec2(-1,0.025),Vec2(5,1)))
					local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga"))
					local minCoord, maxCoord, text = getUvCoordAndTextFromName(name)
					icon:setUvCoord(minCoord,maxCoord)
					icon:setToolTip(text)
									
				
					local fontTag = "<font color=rgb(255,255,255)>"
					if info.stats[name] > 0 then
						fontTag = "<font color=rgb(40,255,40)>+"
					elseif info.stats[name] < 0 then
						fontTag = "<font color=rgb(255,50,50)>"
					end
					notifyText = fontTag .. info.stats[name] .. "</font>\n"
					
					
					row:add(icon)
					local label = row:add(Label(PanelSize(Vec2(-1)), notifyText, Vec3(1.0)))
					panel:add(row)
					
					info.toolTipIcon = icon
					info.toolTipLabel = label
					
					
					totalPanelSizeInPixel = totalPanelSizeInPixel + Vec2(0, 0.025 * Core.getScreenResolution().y )
				end				
			end
		end
		
		panel:setPanelSize(PanelSize(totalPanelSizeInPixel, PanelSizeType.Pixel))
		return panel, textLabel
	end
	
	local function updateToolTip(button, info)
		
		
		local panel, textLabel = buildToolTipPanelForUpgradeInfo(info)
		
		info.toolTipPanel = panel
		info.toolTipLabel = textLabel
		
		button:setToolTip(panel)
	end
	
	local function updateUpgradeInfoIcons()
		
		--print("\n\nupdateUpgradeInfoIcons\n")
		local upgradeInfo = buildingBillBoard:getTable("activeTowerUpgrades")
		
		if upgradeInfo and towerActiveUpdateIndex ~= buildingBillBoard:getInt("updateIndex") then
			towerActiveUpdateIndex = buildingBillBoard:getInt("updateIndex")

			upgradesPanel:clear();
			
			local texture = Core.getTexture("icon_table.tga")
			for i=1, #upgradeInfo, 1 do 
				if upgradeInfo[i] then
					local info = upgradeInfo[i]
					local offset = Vec2((info.icon%8)*0.125, math.floor(info.icon/8)*0.0625)
					
					local image = upgradesPanel:add(Image(PanelSize(Vec2(-1,-1), Vec2(1.0,1.0)), Text("icon_table.tga")))
					image:setUvCoord(offset,offset+Vec2(0.125, 0.0625))
					image:setBackground(Sprite( Vec3(0) ))
					local panel, textLabel = buildToolTipPanelForUpgradeInfo(info)
					image:setToolTip(panel)
				end
			end
		end
	end
	
	local function addNewButton(upgrade)
		if upgrade == nil then
			return --ugrade don't exist any more
		end
		print("\n=== updateButton ===")
		print("Name "..upgrade.name)

		if not towerInfo.buttonsInfo[upgrade.name] then
			towerInfo.buttonsInfo[upgrade.name] = {}
		end
		local buttoninfo = towerInfo.buttonsInfo[upgrade.name]
		
		if upgrade.level > upgrade.maxLevel then
			if buttoninfo.button then
				buttoninfo.button:setVisible(false)
				buttoninfo.costLabel:setVisible(false)
				buttoninfo.costIcon:setVisible(false)
			else
				buttonPanels.index = buttonPanels.index + 1
			end
			return
		end
		

		if buttoninfo.button == nil then
		
			buttoninfo.infoName = upgrade.name
			buttoninfo.cost = upgrade.cost
			buttoninfo.locked = upgrade.locked
			buttoninfo.level = upgrade.level
			buttoninfo.info = upgrade.info
			buttoninfo.values = upgrade.values
			buttoninfo.stats = upgrade.stats
	
			local texture = Core.getTexture("icon_table.tga")
			local offset = Vec2((upgrade.icon%8)*0.125, math.floor(upgrade.icon/8)*0.0625)
			local button = Button(PanelSize(Vec2(-1), Vec2(1)), ButtonStyle.SIMPLE, texture, offset, offset+Vec2(0.125, 0.0625))
			
			local levelPanel = nil
			if buttoninfo.level ~= nil and buttoninfo.infoName ~= "rotate" and buttoninfo.infoName ~= "boost" then
				levelPanel = button:add(Panel(PanelSize(Vec2(-1))))
				levelPanel:setCanHandleInput(false)
				levelPanel:setBackground(Sprite( texture, Vec2(0.625 + (upgrade.level-1) * 0.125,0.3125), Vec2(0.625 + upgrade.level * 0.125, 0.375)))
				
				buttoninfo.levelPanel = levelPanel
			end

			button:setEnabled( buttoninfo.cost <= billboardStats:getDouble("gold") and buttoninfo.locked == nil)
			button:addEventCallbackExecute(onExecute)
			button:setTag(upgrade.name..";"..tostring(buttoninfo.cost)..";"..tostring(buttoninfo.level))
	
			button:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
			button:setInnerHoverColor(Vec4(Vec3(1.3),0.2),Vec4(Vec3(1.3),0.4), Vec4(Vec3(1.3),0.2))
			button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
			
			local costPanel = nil
			local costLabel = nil
			local requireLabel = nil
			local costIcon = nil
			local costIconSprite = nil
			
			costPanel = Panel(PanelSize(Vec2(-1)))
			local text = Text( costToShortString(buttoninfo.cost) )
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
			costPanel:add(requireLabel)
			costPanel:add(costLabel)
			costPanel:add(costIcon)
			
			costPanel:setCanHandleInput(false)
			

			if buttoninfo.locked ~= nil then
				print("\buttoninfo.locked="..buttoninfo.locked.."\n")
				if buttoninfo.locked == "tower level 2" then
					requireLabel:setText("LvL 2")
					requireLabel:setVisible(true)
				elseif buttoninfo.locked == "tower level 3" then
					requireLabel:setText("LvL 3")
					requireLabel:setVisible(true)
				elseif buttoninfo.locked == "shop required" then
					requireLabel:setTextAlignment(Alignment.MIDDLE_LEFT)
					requireLabel:setText( language:getText("shop"))
					requireLabel:setVisible(true)
				elseif buttoninfo.locked == "not your tower" then
					requireLabel:setTextAlignment(Alignment.MIDDLE_CENTER)
					requireLabel:setText( Text("Lock"))
					requireLabel:setVisible(true)
				end
			end

			buttoninfo.button = button
			buttoninfo.costLabel = costLabel
			buttoninfo.costIcon = costIcon
			buttoninfo.requireLabel = requireLabel
			buttoninfo.costIconSprite = costIconSprite
			buttoninfo.added = true
			
			if upgrade.name == "range" then
				button:addEventCallbackMouseFocusGain(towerShowRange)
				button:addEventCallbackMouseFocusLost(towerHideRange)
			end
			
			local index = buttonPanels.index
			buttonPanels.index = buttonPanels.index + 1

			
			if buttonPanels[index] then
				buttonPanels[index]:add(button)
				button:setToolTipParentpanel(costPanel)
			end
			if costPanel and buttonCostPanels[index] then
				buttonCostPanels[index]:add(costPanel)
			end

			updateToolTip(buttoninfo.button, upgrade)	
		else
			
			local texture = Core.getTexture("icon_table.tga")
			buttoninfo.cost = upgrade.cost
			
			if buttoninfo.levelPanel and buttoninfo.level ~= upgrade.level then
				buttoninfo.level = upgrade.level
				buttoninfo.levelPanel:setBackground(Sprite( texture, Vec2(0.625 + (upgrade.level-1) * 0.125,0.3125), Vec2(0.625 + upgrade.level * 0.125, 0.375)))
			end
			
			if buttoninfo.locked ~= upgrade.locked then
				buttoninfo.locked = upgrade.locked
				buttoninfo.button:setEnabled( buttoninfo.cost <= billboardStats:getDouble("gold") and buttoninfo.locked == nil)
				
				if buttoninfo.locked ~= nil then
					print("\buttoninfo.locked="..buttoninfo.locked.."\n")
					if buttoninfo.locked == "tower level 2" then
						buttoninfo.requireLabel:setText("LvL 2")
						buttoninfo.requireLabel:setVisible(true)
					elseif buttoninfo.locked == "tower level 3" then
						buttoninfo.requireLabel:setText("LvL 3")
						buttoninfo.requireLabel:setVisible(true)
					elseif buttoninfo.locked == "shop required" then
						buttoninfo.requireLabel:setTextAlignment(Alignment.MIDDLE_LEFT)
						buttoninfo.requireLabel:setText( language:getText("shop"))
						buttoninfo.requireLabel:setVisible(true)
					elseif buttoninfo.locked == "not your tower" then
						buttoninfo.requireLabel:setTextAlignment(Alignment.MIDDLE_CENTER)
						buttoninfo.requireLabel:setText( Text("Lock"))
						buttoninfo.requireLabel:setVisible(true)
					end
				elseif buttoninfo.requireLabel then
					buttoninfo.requireLabel:setVisible(false)
				end
			end
			
			buttoninfo.button:setTag(upgrade.name..";"..tostring(buttoninfo.cost)..";"..tostring(buttoninfo.level))
			buttoninfo.costLabel:setText(Text( costToShortString(buttoninfo.cost) ))
			
			updateToolTip(buttoninfo.button, upgrade)
		end
		
	end
	
	
	
		
	local function updateButtons()

		local upgrades = buildingBillBoard:getTable("upgrades")
		local towerUpgrade = buildingBillBoard:getTable("towerUpgrade")
		
		if not towerInfo.buttonsInfo then
			towerInfo.buttonsInfo = {}
			storedButtonsInfo = {}
			buttonPanel:clear()
			infopanelRight:clear()
			buttonCostPanel:clear()
			retargetPanel:clear()
			towerValue = 0
			showRange = false
			targetModes = {}
			
			if not upgrades then
				return
			end
			
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
				buttonPanels[i] = buttonPanel:add(Panel(PanelSize(Vec2(-1))))
				buttonCostPanels[i] = buttonCostPanel:add(Panel(PanelSize(Vec2(-1))))
			end
			
			-----------------------------
			-- Add Main upgrade button --
			-----------------------------
			if towerUpgrade then
				addNewButton(towerUpgrade)
			else
				buttonPanels.index = 2
			end
			
			
			----------------------------
			-- Add Sub upgrade button --
			----------------------------
			local rangeUpgrade = nil
			for i=1, #upgrades, 1 do
				local upgrade = upgrades[i]
				
				if upgrade == nil then
					
				else
					if upgrade.name == "range" then
						rangeUpgrade = upgrade
					else
						addNewButton(upgrade)
					end
					
				end
			end
			
			------------------------------
			-- Add Range upgrade button --
			------------------------------
			if rangeUpgrade and buttonPanels.index <= 5 then
				buttonPanels.index = 5
				addNewButton(rangeUpgrade)
			end
			

			towerButtonUpdateIndex = buildingBillBoard:getInt("updateIndex")

		elseif towerButtonUpdateIndex ~= buildingBillBoard:getInt("updateIndex") then
			towerButtonUpdateIndex = buildingBillBoard:getInt("updateIndex")
			if not upgrades then
				return
			end
			
			
			addNewButton(towerUpgrade)
			
			for i=1, #upgrades, 1 do
				local upgrade = upgrades[i]
				if upgrade then
					addNewButton(upgrade)
				end
			end
		else
			local buttoninfo = towerInfo.buttonsInfo[towerUpgrade.name]
			if buttoninfo.button then
				buttoninfo.button:setEnabled( buttoninfo.cost <= billboardStats:getDouble("gold") and buttoninfo.locked == nil)
			end
			
			for i=1, #upgrades, 1 do
				buttoninfo = towerInfo.buttonsInfo[upgrades[i].name]
				if buttoninfo.button then
					buttoninfo.button:setEnabled( buttoninfo.cost <= billboardStats:getDouble("gold") and buttoninfo.locked == nil)
				end
			end
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
			wallTowerCostLabels[i]:setTextColor(enable and Vec4(1) or Vec4(4,1,1,1))
		end
	end
	
	local function initSelectedMenu()
		print("initSelectedMenu")
		buttonPanel:clear()
		towerInfo = {}
		local builBilboard = Core.getBillboard("buildings")
		
		
		storedNumStats = 0
		storedShowText = ""
		towerUpdateIndex = -1
		towerButtonUpdateIndex = -1
		
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
					
					builBilboard:setBool("isTowerSelected",false)
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
					builBilboard:setBool("isTowerSelected",true)
					leftMainPanel:setPanelSize(PanelSize(Vec2(-1),Vec2(1,1.1)))
					wallTowerPanel:setVisible(false)
					towerPanel:setVisible(true)
					imagePanel:setVisible(true)
					
					selectedBuildingType = 1
					
					buttonPanel:clear()
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
		else
			builBilboard:setBool("isTowerSelected",false)
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
--		showAllTowerThatCanBeBoosted(keyBindBoostBuilding:getHeld())

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
		
		if Core.getInput():getMouseDown(MouseKey.left) and not buildingNodeBillboard:getBool("AbilitesBeingPlaced") and not buildingNodeBillboard:getBool("inBuildMode") and buildingNodeBillboard:getBool("canBuildAndSelect") and isMouseInMainPanel() then
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
--						elseif keyBindBoostBuilding:getHeld() then
--							print("boost tower")
--							boostTower(building)
--							setGlowColor( building, Vec3(0.05,0.15,0.05) )
--							updateBoostTimer[#updateBoostTimer + 1] = {time=Core.getGameTime() + 15, node = building}
--							setNodeNotBoostable(building)
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
--						elseif keyBindBoostBuilding:getHeld() then
--							boostTower(buildingLastSelected)
--							setGlowColor( buildingLastSelected, Vec3(0.05,0.15,0.05) )
--							if buildingLastSelected then
--								updateBoostTimer[#updateBoostTimer + 1] = {time=Core.getGameTime() + 15, node = buildingLastSelected}
--							end
--							setNodeNotBoostable(buildingLastSelected)
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
--			if keyBindBoostBuilding:getPressed() then
--				setNodeNotBoostable(buildingLastSelected)
--				setGlowColor( buildingLastSelected, Vec3(0.05,0.15,0.05) )
--				if buildingLastSelected then
--					updateBoostTimer[#updateBoostTimer + 1] = {time=Core.getGameTime() + 15, node = buildingLastSelected}
--				end
--				boostTower()
--			end  
			
			
			if selectedBuildingType == 1 then
				updateBars()
				updateEnergyBar()
				updateOverHeatBar()
				updateText()
				updateButtons()
				updateUpgradeInfoIcons()
				
			elseif selectedBuildingType == 2 then
				updateWallTowerButtons()
			end
			
			if buildingLastSelected then
				
				local rangeLevel = 4
				
				if showRange and towerInfo and towerInfo.buttonsInfo and towerInfo.buttonsInfo["range"] then
	--				print("towerInfo: "..tostring(towerInfo.buttonsInfo))
--					for name, data in pairs(towerInfo.buttonsInfo) do
--						if data.name and data.level ~= nil and data.name.value == "range" then
							rangeLevel = towerInfo.buttonsInfo["range"].level
--						end
--					end
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