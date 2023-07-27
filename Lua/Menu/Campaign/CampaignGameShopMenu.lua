require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/Campaign/FreeFormDesign.lua")
require("Game/campaignData.lua")
require("Tower/TowerValues.lua")
--this = SceneNode()

CampaignGameShopMenu = {}
function CampaignGameShopMenu.new(parentPanel)
	local self = {}
	local mainPanel = parentPanel:add(Panel(PanelSize(Vec2(-1))))
	--mainPanel = Panel()
	
	local conf = CampaignData.new()
	local buttons = {}
	local towerValues = TowerValues.new()
	local towers = {}
	
	
	
	function self.setVisible(visible)
		mainPanel:setVisible(visible)
	end
	
	local function setVisibleSkillTree( button )
		local skillIndex = tonumber(button:getTag():toString())
		
		for i=1, 10 do
			local tab = buttons[i]
			local towerName = buttons[i].towerName
			local towerTab = towers[buttons[i].towerName]
			
			buttons[i].panel:setVisible(i==skillIndex)
			towers[buttons[i].towerName].crystalLabel:setText(tostring(towerValues.getCrystals()))
		end
	end
	
	local function abilityButtonEnabled(towerName, upgradeName, level)
		local unlocked = towers[towerName][upgradeName].unlocked
		if upgradeName == "upgrade" or towerName == "Passiv" then
			return unlocked+1 == level or unlocked == level
		else
			local upgradeUnlocked = towers[towerName]["upgrade"].unlocked
			return upgradeUnlocked >= level and (unlocked+1 == level or unlocked == level)
		end
	end
	
	local function updateButtonState(freeFormButton)
		if freeFormButton == nil then
			return
		end
	
		local buttonData = totable(freeFormButton:getTag():toString())
		
		local towerName = buttonData.towerName 
		local upgradeName = buttonData.upgradeName
		local level = buttonData.level
		
		
		
		
		
		
		local debugData = towers[towerName][upgradeName]
		local unlockedLevel = towers[towerName][upgradeName].unlocked
		local upgradeLevel = towers[towerName]["upgrade"] ~= nil and towers[towerName]["upgrade"].unlocked or -1
		local toolTipPanel = towers[towerName][upgradeName].toolTipPanel[level]
		local toolTipPanelWarning = towers[towerName][upgradeName].toolTipPanelWarning[level]
		
		
	
		
--		freeFormButton:setEnabled(abilityButtonEnabled(towerName, upgradeName, level))
		
		local boughtColor = Vec4(1)
		local canBeBoughtColor = Vec4(0.4,0.4,0.4,1)
		local unavailableColor = Vec4(0.1,0.1,0.1,1)
		
		if upgradeName == "upgrade" or towerName == "Passiv" then
			if unlockedLevel >= level then
				freeFormButton:setEnabled(true)
				freeFormButton:getImage():setColor( boughtColor )
				freeFormButton:getSecondaryImage():setColor( boughtColor )
			elseif (unlockedLevel+1) == level then
				freeFormButton:setEnabled(true)
				freeFormButton:getImage():setColor( canBeBoughtColor )
				freeFormButton:getSecondaryImage():setColor( canBeBoughtColor )
			else
				freeFormButton:setEnabled(false)
				freeFormButton:getImage():setColor( unavailableColor )
				freeFormButton:getSecondaryImage():setColor( unavailableColor )
			end
			
		else
			if unlockedLevel >= level then
				freeFormButton:setToolTip(toolTipPanel)
				freeFormButton:getImage():setColor( boughtColor )
				freeFormButton:getSecondaryImage():setColor( boughtColor )
			elseif upgradeLevel >= level and (unlockedLevel+1) == level then
				freeFormButton:setToolTip(toolTipPanel)
				freeFormButton:setEnabled(true)
				freeFormButton:getImage():setColor( canBeBoughtColor )
				freeFormButton:getSecondaryImage():setColor( canBeBoughtColor )
			else
				freeFormButton:setToolTip(toolTipPanelWarning)
				freeFormButton:setEnabled(false)
				freeFormButton:getImage():setColor( unavailableColor )
				freeFormButton:getSecondaryImage():setColor( unavailableColor )
			end
		end	
	end
	
	local function updateButton(towerName, upgradeName, level)
	
		local ability = towers[towerName][upgradeName]
		local unlocked = ability.unlocked
		local button = ability.buttons[level]
		local buttonsPosition = ability.buttonsPosition
		local lineSelectedHandler = towers[towerName].lineSelectedHandler
		
		
	
		local crystalCost = ability.maxLevel == 1 and 3 or level
		
	
		if unlocked == level then
			-- Selling an ability				
			local newUnlockLevel = level - 1 
			
			ability.unlocked = newUnlockLevel
			towerValues.addCrystal(crystalCost)
			towerValues.setUnlockedLevel(towerName, upgradeName, newUnlockLevel)
			
			if level > 1 then
				lineSelectedHandler:removeLine(buttonsPosition[level-1], buttonsPosition[level])
				lineSelectedHandler:rebuildMesh()
			end				
			towers[towerName].crystalLabel:setText(tostring(towerValues.getCrystals()))			
			
			if upgradeName == "upgrade" then
				local towerData = towers[towerName]
				local towerAbilities = towerData.upgradeNames
				for n=1, #towerAbilities do
					local abilityName = towerAbilities[n]
					--if the upgrade was higher or equal to the removed tower level remove this update also
					while abilityName ~= "upgrade" and towerData[abilityName].unlocked >= level do
						updateButton(towerName, abilityName, towerData[abilityName].unlocked)						
					end
				end
			end
			--
				
		elseif (unlocked+1) == level then
			--Buying an ability
			if towerValues.getCrystals() < crystalCost then
				return
			end
			
			ability.unlocked = level
			towerValues.removeCrystal(crystalCost)
			towerValues.setUnlockedLevel(towerName, upgradeName, level)
	
			if level > 1 then
				lineSelectedHandler:addLine(buttonsPosition[level-1], buttonsPosition[level])
				lineSelectedHandler:rebuildMesh()
			end
			towers[towerName].crystalLabel:setText(tostring(towerValues.getCrystals()))
		end
		
		if upgradeName == "upgrade" then
			local towerData = towers[towerName]
			local towerAbilities = towerData.upgradeNames
			for n=1, #towerAbilities do
				local abilityName = towerAbilities[n]
				--update button status
				if abilityName ~= "upgrade" then
					updateButtonState(towerData[abilityName].buttons[1])
					updateButtonState(towerData[abilityName].buttons[2])
					updateButtonState(towerData[abilityName].buttons[3])
				end
			end
			
		end
		
		
		
		updateButtonState(ability.buttons[level-1])
		updateButtonState(button)
		updateButtonState(ability.buttons[level+1])
		
	end
	
	local function buttonEvent(freeFormButton)
		local tag = freeFormButton:getTag():toString()
		local buttonData = totable(tag)
		--buttonData = {towerName=towerName,upgradeName=upgradeName,level=level}
		updateButton(buttonData.towerName, buttonData.upgradeName, buttonData.level, true)
	end
	
	local function buttonMoseOver(freeFormButton)
		local tag = freeFormButton:getTag():toString()
		local buttonData = totable(tag)
		local unlocked = towers[buttonData.towerName][buttonData.upgradeName].unlocked
		
		if (unlocked+1) == buttonData.level and freeFormButton:getEnabled() then
			freeFormButton:getImage():setColor( Vec4(0.8,0.8,0.8,1) )
			freeFormButton:getSecondaryImage():setColor( Vec4(0.8,0.8,0.8,1) )
		end
	end
	
	local function buttonMoseAway(freeFormButton)
		local tag = freeFormButton:getTag():toString()
		local buttonData = totable(tag)
		local unlocked = towers[buttonData.towerName][buttonData.upgradeName].unlocked
		
		if (unlocked+1) == buttonData.level and freeFormButton:getEnabled() then
			freeFormButton:getImage():setColor( Vec4(0.4,0.4,0.4,1) )
			freeFormButton:getSecondaryImage():setColor( Vec4(0.4,0.4,0.4,1) )
		end
	end
	
	
	
	
	local function convertValueToPrintedValue(value, func)
		if func == towerValues.mul then
			return tostring(value * 100) .. "%"
		else
			return tostring(value)
		end
	end
	
	local function getValuesForToolTip(abilityData, level)
		local value1 = nil
		for n=1, #abilityData.infoValues do 
			local name = abilityData.infoValues[n]
			local data = abilityData.stats[name]

			if value1 == nil then
				value1 = convertValueToPrintedValue(data[level], data.func)
			else
				return value1, convertValueToPrintedValue(data[level], data.func)
			end
		end
		return (value1==nil and "" or value1), ""
	end
	
	
	local function buildToolTipPanelForAbility(abilityData, level, upgradeNeeded)
		
		
		local panel = Panel(PanelSize(Vec2(-1)))
		panel:setLayout(FallLayout())
		panel:getPanelSize():setFitChildren(true, true)
		panel:setCanHandleInput(false)
		
		local infoValueText = (abilityData.info and abilityData.info or "")
		local value1, value2 = getValuesForToolTip(abilityData, level)
		local textLabel = Label(PanelSize(Vec2(-1)), language:getTextWithValues(infoValueText, value1, value2), Vec4(1) )
		textLabel:setTextHeight(0.015)
		textLabel:setPanelSizeBasedOnTextSize()
		panel:add(textLabel)
		
		local tempLabel = Label(PanelSize(Vec2(-1)), "999 Requiers Upgrade level 3", Vec3(1.0,0,0))
		tempLabel:setTextHeight(0.015)
		tempLabel:setPanelSizeBasedOnTextSize()
		local warningTextSize = tempLabel:getPanelSize():getSize()
		local textSize = textLabel:getPanelSize():getSize()
		
		local totalPanelSizeInPixel = Vec2( math.max( textSize.x, warningTextSize.x), textSize.y)
		

		for n=1, #abilityData.infoValues do 
			local name = abilityData.infoValues[n]
			local data = abilityData.stats[name]
			
	
			local minCoord, maxCoord, text = towerValues.getUvCoordAndTextFromName(name)
			local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga"))
			icon:setUvCoord(minCoord,maxCoord)
							
		
			local fontTag = "<font color=rgb(255,255,255)>"
			if data[level] > 0 then
				fontTag = "<font color=rgb(40,255,40)>+"
			elseif data[level] < 0 then
				fontTag = "<font color=rgb(255,50,50)>"
			end

			notifyText = fontTag .. convertValueToPrintedValue(data[level], data.func) .. "</font>\n"
			
			local row = Panel(PanelSize(Vec2(-1,0.025),Vec2(5,1)))
			row:add(icon)
			row:add(Label(PanelSize(Vec2(-1)), notifyText, Vec3(1.0)))
			panel:add(row)

			
			totalPanelSizeInPixel = totalPanelSizeInPixel + Vec2(0, 0.025 * Core.getScreenResolution().y )
		end
		
		--crystal cost
		panel:add(Panel(PanelSize(Vec2(-1,0.01))))
		local row = panel:add(Panel(PanelSize(Vec2(-1,0.025))))
		local cost = abilityData.maxLevel == 1 and 3 or level
		
		local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table"))
		icon:setUvCoord(Vec2(0.5,0.375),Vec2(0.625,0.4375))
		row:setLayout(FlowLayout())
		row:add(icon)
		local label = nil
		if upgradeNeeded then
			label = row:add(Label(PanelSize(Vec2(-1)), tostring(cost).." Requiers Upgrade level "..level, Vec3(1.0,0,0)))
		else
			label = row:add(Label(PanelSize(Vec2(-1)), tostring(cost), Vec3(1.0)))
		end

		
		totalPanelSizeInPixel = totalPanelSizeInPixel + Vec2(0, 0.035 * Core.getScreenResolution().y )
	
		
		panel:setPanelSize(PanelSize(totalPanelSizeInPixel, PanelSizeType.Pixel))
		return panel
	end
	
	
	
	
	local function init()
	
		mainPanel:setBorder(Border( BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
	
		local leftPanel = mainPanel:add(Panel(PanelSize(Vec2(-1, -1))))
		leftPanel:setLayout(FallLayout())
		
		
		
		local towerBorderMenu = leftPanel:add(Panel(PanelSize(Vec2(-1, -1),Vec2(9.5,1))))
		towerBorderMenu:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
		towerButtonMenu = towerBorderMenu:add(Panel(PanelSize(Vec2(-1, -0.95),Vec2(10,1))))
		towerButtonMenu:setLayout(GridLayout(1,10, Alignment.MIDDLE_CENTER))


		local breakline = leftPanel:add(Panel(PanelSize(Vec2(-1,MainMenuStyle.borderSize))))
		breakline:setBackground(Sprite(MainMenuStyle.borderColor))
		
		local skillPanel = leftPanel:add(Panel(PanelSize(Vec2(-1, -1))))
		
		
		--
		
		local towerTexture = Core.getTexture("icon_tower_table")
		
		local passivUpgrades = towerButtonMenu:add(Button(PanelSize(Vec2(-1,-0.95), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, Vec2(), Vec2(1.0/4.0, 1.0/4.0) ))
		passivUpgrades:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
		passivUpgrades:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
		passivUpgrades:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
		passivUpgrades:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
		passivUpgrades:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
		passivUpgrades:setTag("1")
		
		buttons[1] = {}
		buttons[1].button = passivUpgrades
		
		local upgrades = towerValues.getStoreGroupNames()
		
		
		for i=2, 10 do
			local x = (i-1)%4
			local y =3-math.floor(((i-1)/4))
			local minCoord = Vec2(x/4.0, y/4.0)
			

			local button = towerButtonMenu:add(Button(PanelSize(Vec2(-1,-0.95), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, minCoord, minCoord+Vec2(1.0/4.0, 1.0/4.0) ))
			button:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
			button:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
			button:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
			button:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
			button:setTag(""..i)
			
			buttons[i] = {}
			buttons[i].button = button
		end
		
		for n=1, 10 do
			local towerName = upgrades[n]
			buttons[n].button:addEventCallbackExecute(setVisibleSkillTree)
			buttons[n].panel = skillPanel:add(Panel(PanelSize(Vec2(-1, -1))))
			buttons[n].panel:setVisible(n==1)
			buttons[n].panel:setLayout(FreeFormLayout(PanelSize(Vec2(-1))))
			buttons[n].towerName = towerName
--			buttons[i].panel:setBackground(Sprite(Vec3(i*0.1)))


			local localSkillPanel = buttons[n].panel 
			
			
			local panelBorder = Vec2(0.003,0.003)
			local panelOffset = Vec2(0.03,0.03) + panelBorder
			local panelSize = Vec2(0.13,0.045) * 1.2
			
			localSkillPanel:add(FreeFormSprite(PanelSizeType.WindowPercentBasedOnY, panelOffset - panelBorder, panelOffset + panelBorder + panelSize, Vec3(0.6)))
			localSkillPanel:add(FreeFormSprite(PanelSizeType.WindowPercentBasedOnY, panelOffset, panelOffset + panelSize, Vec3(0.05)))
			localSkillPanel:add(FreeFormSprite(PanelSizeType.WindowPercentBasedOnY, panelOffset-Vec2(0,panelBorder.y), panelOffset+Vec2(panelSize.y)+Vec2(panelBorder.x,0),"icon_table",Vec2(0.5,0.375),Vec2(0.625,0.4375))):setColor(Vec3(1.25))
			local crystalLabel = localSkillPanel:add(FreeFormLabel(PanelSizeType.WindowPercentBasedOnY, panelOffset + Vec2(panelSize.y,0), tostring( towerValues.getCrystals() ), panelSize.y*0.75, Vec4(1), Alignment.TOP_LEFT))
			crystalLabel:setCanHandleInput(false)
			
			local lineSkillLevelSeperator = FreeFormLine()	
			FreeFormDesign.setlineDesignSkillLevelSeperator(lineSkillLevelSeperator)
			localSkillPanel:add(lineSkillLevelSeperator)
			lineSkillLevelSeperator:addLine(Vec2(0,-0.35), Vec2(-1,-0.35))
			lineSkillLevelSeperator:addLine(Vec2(0,-0.65), Vec2(-1,-0.65))
			
			
			
			local lineHandler = FreeFormLine()	
			FreeFormDesign.setLineDesign(lineHandler)
			localSkillPanel:add(lineHandler)
			
			local lineSelectedHandler = FreeFormLine()	
			FreeFormDesign.setLineDesignSelected(lineSelectedHandler)
			localSkillPanel:add(lineSelectedHandler)
			
			
			
			
			
			local skillButtonDesign = FreeFormDesign.getSkillButton()
			
			
			local towerData = towerValues.getTowerValues(towerName)
			towerData.lineSelectedHandler = lineSelectedHandler
			towerData.crystalLabel = crystalLabel
			towers[towerName] = towerData	
			
			local skillCount = #towerData.upgradeNames
			local skillDistance = 1 / (skillCount+1)
			local iconTexture = Core.getTexture("icon_table")
			
			for i=1, #towerData.upgradeNames do
				local upgradeName = towerData.upgradeNames[i]
				local abilityData = towerData[upgradeName]
				abilityData.buttons = {}
				abilityData.buttonsPosition = {}
				abilityData.toolTipPanel = {}
				abilityData.toolTipPanelWarning = {}
				
				local maxLevel = abilityData.maxLevel
				local iconId = abilityData.iconId
				local unlocked = abilityData.unlocked
				
				local offset = Vec2((abilityData.iconId%8)*0.125, math.floor(abilityData.iconId/8)*0.0625)
				local uvSize = Vec2(0.125,0.0625)
				if n==1 then
					iconTexture = Core.getTexture("abilities")
					offset = Vec2((abilityData.iconId%2)*0.5, math.floor(abilityData.iconId/2)*0.5)
					uvSize = Vec2(0.5)
				end
				
				local oldPosition = Vec2()
				for y=1, maxLevel do
					
					local position = Vec2(-skillDistance * i, -0.2 + (y-1)*-(0.6/2))
					local button = FreeFormButton(position, skillButtonDesign, iconTexture, offset, offset+uvSize)
					
					local buttonTagData = {towerName=towerName,upgradeName=upgradeName,level=y}
					
					button:setTag(tabToStrMinimal(buttonTagData))
					button:addEventCallbackExecute(buttonEvent)
					button:addEventCallbackMouseFocusGain(buttonMoseOver)
					button:addEventCallbackMouseFocusLost(buttonMoseAway)
					
					if maxLevel > 1 then
						button:getSecondaryImage():setTexture(Core.getTexture("icon_table"))
						button:getSecondaryImage():setUvCoord(Vec2(0.625 + (y-1) * 0.125,0.3125), Vec2(0.625 + y * 0.125, 0.375))					
					end
					localSkillPanel:add( button )
					abilityData.buttons[y] = button
					abilityData.buttonsPosition[y] = position
					
					
					
					-- add ToolTip
					local toolTipPanel, costLabel, CostLabelWarning = buildToolTipPanelForAbility(abilityData, y, false)
					local toolTipPanelWarning, costLabel, CostLabelWarning = buildToolTipPanelForAbility(abilityData, y, true)
					button:setToolTip(toolTipPanel)
					
					abilityData.toolTipPanel[y] = toolTipPanel
					abilityData.toolTipPanelWarning[y] = toolTipPanelWarning
					
					--Add the line
					updateButtonState(button)
					
					if y > 1 then
						lineHandler:addLine(oldPosition, position)
						
						if y <= unlocked then
							lineSelectedHandler:addLine(oldPosition, position)
						end
					end
					oldPosition = position
				end
				
			end	
			
					
			
		end
	end
	init()
	
	return self
end