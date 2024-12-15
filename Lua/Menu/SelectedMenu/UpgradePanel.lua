require("Menu/MainMenu/settingsCombobox.lua") 
require("Game/gameValues.lua")
--buildingBillBoard = Billboard()
--buildingNodeBillboard = Billboard()
--senToBuildNode = Function()
--this = SceneNode()

UpgradePanel = {}
function UpgradePanel.new(inParentPanel, inComUnit, handleUpgradeFunction, changedTargetSystemFunction, getLastBuildingSelectedFunction)
	local self = {}
	
	local gameValues = GameValues.new()
	local parentPanel = inParentPanel
	local handleUpgrade = handleUpgradeFunction
	local changedTargetSystemFunc = changedTargetSystemFunction
	local getLastBuildingSelected = getLastBuildingSelectedFunction
	local comUnit = inComUnit
	
	local upgradePanel--upgradePanel
	local buttonPanels = {}
	local showRange = false
	local billboardStats = Core.getBillboard("stats")
	local language = Language()
	local buttonsInfo = nil
	local buttonCostPanel = nil
	local retargetPanel = nil
	local buttonCostPanels = {}
	local statsOrder =  {"damage", "dmg","RPS", "ERPS","range", "slow","bladeSpeed", "fireDPS","burnTime","dmg_range","supportDamage","SupportRange","supportWeaken","weakenValue","supportGold","supportGoldPerWave"}
	local towerButtonUpdateIndex = -1
	local targetComboBox
	
	local upgradesPanel
	
	function self.clear()
		upgradePanel:clear()
	end
	
	function self.clearInfo()
		buttonsInfo = nil
		towerButtonUpdateIndex = -1
	end
	
	function self.getTowerShowRange()
		return showRange and buttonsInfo  and buttonsInfo["range"]
	end
	
	function self.getTowerRangeLevel()
		return buttonsInfo["range"].level
	end
	
	function self.setBuildingBillBoard(inBuildingBillBoard)
		buildingBillBoard = inBuildingBillBoard
	end
	
	local function buildToolTipPanelForUpgradeInfo(info)
		local requireText = Text("")
		if info.locked ~= nil then
			
			local requireTextCreated = false
			if info.locked == "tower.menu.tower level 2" or info.locked == "tower.menu.tower level 3" or info.locked == "tower.menu.shop required" or info.locked == "tower.menu.not your tower" then
				requireTextCreated = true
				requireText = Text("<font color=rgb(255,50,50)>")
			end
			
			
			if info.locked == "tower.menu.tower level 2" then
				requireText = requireText + language:getText("tower.menu.tower level") + Text(" 2")
			elseif info.locked == "tower.menu.tower level 3" then
				requireText = requireText + language:getText("tower.menu.tower level") + Text(" 3")
			elseif info.locked == "tower.menu.shop required" then
				requireText = requireText  + language:getText("tower.menu.shop required")
			elseif info.locked == "tower.menu.not your tower" then
				requireText = requireText  + language:getText("tower.menu.not your tower")
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
					local minCoord, maxCoord, text = gameValues.getUvCoordAndTextFromName(name)
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
	
	local function towerShowRange()
		showRange = true
	end
	
	local function towerHideRange()
		showRange = false
	end
	
	
	
	local function onExecute(button)
		print("")
		print("TRY UPGRADE TOWER")
		print("TAG: "..button:getTag():toString())

		if button:getTag():toString() ~= "" then
			--upgrade1;400;2	name;cost;level
			local subString, size = split(button:getTag():toString(), ";")
			
			print("SUBSTRING: "..tostring(subString))
			print("SIZE: "..tostring(size))
			
			if size == 3 and tonumber(subString[2]) then
				handleUpgrade(getLastBuildingSelected(), tonumber(subString[2]), subString[1], tonumber(subString[3]) )
			else
				handleUpgrade(getLastBuildingSelected(), 0, subString[1])	
			end
			--Disabel this upgrade for future use
			button:setTag("");
	
		end
	end
	
	local function addNewButton(upgrade)
		if upgrade == nil then
			return --ugrade don't exist any more
		end
		print("\n=== updateButton ===")
		print("Name "..upgrade.name)

		if not buttonsInfo[upgrade.name] then
			buttonsInfo[upgrade.name] = {}
		end
		local buttoninfo = buttonsInfo[upgrade.name]
		
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
				if buttoninfo.locked == "tower.menu.tower level 2" then
					requireLabel:setText("LvL 2")
					requireLabel:setVisible(true)
				elseif buttoninfo.locked == "tower.menu.tower level 3" then
					requireLabel:setText("LvL 3")
					requireLabel:setVisible(true)
				elseif buttoninfo.locked == "tower.menu.shop required" then
					requireLabel:setTextAlignment(Alignment.MIDDLE_LEFT)
					requireLabel:setText( language:getText("tower.menu.shop"))
					requireLabel:setVisible(true)
				elseif buttoninfo.locked == "tower.menu.not your tower" then
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
					if buttoninfo.locked == "tower.menu.tower level 2" then
						buttoninfo.requireLabel:setText("LvL 2")
						buttoninfo.requireLabel:setVisible(true)
					elseif buttoninfo.locked == "tower.menu.tower level 3" then
						buttoninfo.requireLabel:setText("LvL 3")
						buttoninfo.requireLabel:setVisible(true)
					elseif buttoninfo.locked == "tower.menu.shop required" then
						buttoninfo.requireLabel:setTextAlignment(Alignment.MIDDLE_LEFT)
						buttoninfo.requireLabel:setText( language:getText("tower.menu.shop"))
						buttoninfo.requireLabel:setVisible(true)
					elseif buttoninfo.locked == "tower.menu.not your tower" then
						buttoninfo.requireLabel:setTextAlignment(Alignment.MIDDLE_CENTER)
						buttoninfo.requireLabel:setText( Text("Lock"))
						buttoninfo.requireLabel:setVisible(true)
					end
				elseif buttoninfo.requireLabel then
					buttoninfo.requireLabel:setVisible(false)
				end
			end
			
			local dontHaveMoney = buttoninfo.cost <= billboardStats:getDouble("gold") and "" or "<font color=rgb(255,40,40)>"
			
			buttoninfo.button:setTag(upgrade.name..";"..tostring(buttoninfo.cost)..";"..tostring(buttoninfo.level))
			buttoninfo.costLabel:setText(Text( "<font color=rgb(255,40,40)>" .. costToShortString(buttoninfo.cost) .. "</font>" ))
			
			updateToolTip(buttoninfo.button, upgrade)
		end
		
	end
	
	function self.updateButtons(inBuildingBillBoard)
		
		local upgrades = buildingBillBoard:getTable("upgrades")
		local towerUpgrade = buildingBillBoard:getTable("towerUpgrade")
		
		if not buttonsInfo then
			buttonsInfo = {}
			upgradePanel:clear()
			--infopanelRight:clear()
			buttonCostPanel:clear()
			retargetPanel:clear()
			showRange = false
			targetModes = {}
			
			if not upgrades then
				return
			end
			
			--infopanelRight:setLayout(FallLayout(Alignment.BOTTOM_RIGHT))
			local targetModsString = buildingBillBoard:getString("targetMods")
			
			
			
			if targetModsString ~= "" then
				
				for splitedStr in (targetModsString .. ";"):gmatch("([^;]*);") do 
					targetModes[#targetModes + 1] = language:getText( splitedStr )
				end
				
				retargetPanel:setVisible(true)
				targetComboBox = SettingsComboBox.new(retargetPanel,PanelSize(Vec2(-1)), targetModes, "targeting", "WeakestUnit", changedTargetSystemFunc)
				targetComboBox.setIndex(buildingBillBoard:getInt("currentTargetMode"))	
			else
				retargetPanel:setVisible(false)
			end
			
			

			--infopanelRight:add(Panel(PanelSize(Vec2(-1))))
			
			buttonPanels = {}
			buttonPanels.index = 1
			buttonCostPanels = {}
			for i=1, 5 do
				buttonPanels[i] = upgradePanel:add(Panel(PanelSize(Vec2(-1))))
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
			local buttoninfo = buttonsInfo[towerUpgrade.name]
			if buttoninfo.button then
				buttoninfo.button:setEnabled( buttoninfo.cost <= billboardStats:getDouble("gold") and buttoninfo.locked == nil)
			end
			
			for i=1, #upgrades, 1 do
				buttoninfo = buttonsInfo[upgrades[i].name]
				if buttoninfo.button then
					buttoninfo.button:setEnabled( buttoninfo.cost <= billboardStats:getDouble("gold") and buttoninfo.locked == nil)
				end
			end
		end
		
	end
	
	function self.updateUpgradeInfoIcons()
		
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
	
	function self.addBoostPanel( towerCameraPanel )
		upgradesPanel = towerCameraPanel:add(Panel(PanelSize(Vec2(-1,-1),Vec2(6,1))))
		upgradesPanel:setLayout(GridLayout(1,5))
	end
	
	local function init()
		retargetPanel = parentPanel:add(Panel(PanelSize(Vec2(-1),Vec2(9,1))))
		--Spacing
		parentPanel:add(Panel(PanelSize(Vec2(-1),Vec2(35,1))))
		
		upgradePanel = parentPanel:add(Panel(PanelSize(Vec2(-1),Vec2(5.2,1)))); 
		upgradePanel:setLayout(GridLayout(1,5))
		
		--add Spacing
		buttonCostPanel = parentPanel:add(Panel(PanelSize(Vec2(-1),Vec2(16,1))))
		buttonCostPanel:setLayout(GridLayout(1,5))
	end
	
	
	init()
	
	return self
end