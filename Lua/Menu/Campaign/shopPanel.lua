require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/Campaign/shopFunction.lua")
require("Menu/towerImage.lua")
require("Game/campaignData.lua")
--this = SceneNode()
ShopPanel = {}
function ShopPanel.new(shopPanel)
	--mainAreaPanel = Panel()
	local self = {}
	--buy panels
	local cost = 0
	local countItems = 0
	local bottomRight = shopPanel
	local buyCrystalImage
	local buyCostLabel
	local buyCostButton
	local item8Panel
	local item18Panel
	local itemUpdateCallback = nil
	local itemRemovedCallback = nil
	local itemBuyCallback = nil
	
	local item8Panels = {}
	local item18Panels = {}
	
	local function setBuyPanelEnable(enable)
		
		local color = enable and 1 or 0.4
		bottomRight:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)),Vec4(MainMenuStyle.borderColor:toVec3()*color,1)))
		
		local colorVec4 = Vec4(Vec3(color),1)
		buyCostLabel:setTextColor(colorVec4)
		buyCrystalImage:setColor(colorVec4)
		buyCostButton:setEnabled(enable)
		buyCostButton:setTextColor(colorVec4)
	end
	
	function self.getIsInCart(button)
		for i=1, #item8Panels do
			if button and item8Panels[i].id == button:getPanelId() then
				return true
			end
		end
		return false
	end
	
	local function showPanel(button)
		for i=1, #item8Panels do
			if item8Panels[i].button == button then
				item8Panels[i].xIcon:setVisible(true)
			end
		end
	end
	local function hidePanel(button)
		for i=1, #item8Panels do
			if item8Panels[i].button == button then
				item8Panels[i].xIcon:setVisible(false)
			end
		end
	end
	
	local function clearAllItems()
	
		for i=1, #item8Panels do
			
			local panelId = item8Panels[i].id	
			local currentPanel = item8Panels[i].panel
			currentPanel:clear()
			item8Panels[i] = {}
			item8Panels[i].panel = currentPanel
			
		end
		cost = 0
		countItems = 0
		buyCostLabel:setText(tostring(cost))
		setBuyPanelEnable(false)
		
		if itemUpdateCallback then
			itemUpdateCallback()
		end
	end
	
	local function removeItemByButton(button)
		local index = 0
		for i=1, #item8Panels do
			if item8Panels[i].button == button then
				index = i
			end
		end
		if index == 0 or button == nil then
			return
		end
		--update cost
		cost = cost - item8Panels[index].cost
		buyCostLabel:setText(tostring(cost))
		
		--clear panel that has been droped
		local tmpPanel = item8Panels[index].panel
		tmpPanel:clear()
		local panelId = item8Panels[index].id
		item8Panels[index] = {}
		item8Panels[index].panel = tmpPanel
		
		--move all icons one step to the right
		for i=index+1, #item8Panels do
			if item8Panels[i].button then
				local previosPanel = item8Panels[i-1].panel
				local currentPanel = item8Panels[i].panel
				
				currentPanel:removePanel(item8Panels[i].rootPanel)
				previosPanel:add(item8Panels[i].rootPanel)
				
				item8Panels[i-1] = item8Panels[i]
				item8Panels[i-1].panel = previosPanel
				item8Panels[i] = {}
				item8Panels[i].panel = currentPanel
			end
		end
		
		--check if the buy panel should be disabled
		countItems = countItems - 1
		if countItems == 0 then
			setBuyPanelEnable(false)
		end
		
		--update the panel
		if itemRemovedCallback then
			itemRemovedCallback(panelId)
		end
	end
	
	function self.setItemRemovedCallback(updateButtonFromPanelId)
		itemRemovedCallback = updateButtonFromPanelId
	end
	
	function self.setBuyItemCallback(buyUpGrade)
		itemBuyCallback = buyUpGrade
	end
	
	function self.setItemUpdateCallback(updateCallback)
		itemUpdateCallback = updateCallback
	end
	
	function self.removeItem(button)
		if button == nil then
			return
		end
		
		
		--find and remove all upgrades that are greater then this
		local upgTab = totable(button:getTag():toString())
		local index = 1
		while index <= countItems do
			if item8Panels[index].upgTab.upgLevel > upgTab.upgLevel and item8Panels[index].upgTab.upgIndex == upgTab.upgIndex and item8Panels[index].upgTab.towerName == upgTab.towerName then
				removeItemByButton(item8Panels[index].button)
			else
				index = index + 1
			end
		end
		
		for i=1, #item8Panels do
			if button and item8Panels[i].id == button:getPanelId() then
				removeItemByButton(item8Panels[i].button)
				return
			end
		end
		
	end
	
	function self.isUpgradeInCart(upgIndex, towerName, upgLevel)
		for i=1, countItems do
			if item8Panels[i].upgTab.upgLevel == upgLevel and item8Panels[i].upgTab.upgIndex == upgIndex and item8Panels[i].upgTab.towerName == towerName then
				return true
			end
		end
		return false
	end
	
	function self.getCost()
		return cost
	end
	
	function self.addItem(button)
		
		local upgTab = totable(button:getTag():toString())

		--check for identicaly upgrade
		for i=1, countItems do
			if item8Panels[i].upgTab.upgLevel == upgTab.upgLevel and item8Panels[i].upgTab.upgIndex == upgTab.upgIndex and item8Panels[i].upgTab.towerName == upgTab.towerName then
				return false
			end
		end
		
		if countItems >= 8 then
			return false
		end
		
		
		local tab = item8Panels[countItems + 1]
		local upgCost = ShopFunction.getCostForUpgrade(upgTab.towerName, upgTab.upgIndex, upgTab.upgLevel)
		print("item8Panels: "..tostring(item8Panels))
		print("tab: "..tostring(tab))
		print("upgTab: "..tostring(upgTab))
		
		if (cost + upgCost) > ShopFunction.data.getCrystal() then
			return false
		end
		
		
		
		countItems = countItems + 1
		local aButton, rootPanel = ShopFunction.createIconButton( tab.panel, upgTab.towerInfo.iconIndex, upgTab.upgLevel, true )
		
		if countItems == 1 then
			setBuyPanelEnable(true)
		end
		
		aButton:setTag(button:getTag())

		
		aButton:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
		local xIcon = aButton:add(Image(PanelSize(Vec2(-0.8),Vec2(1)),Text("icon_table.tga")))
		xIcon:setUvCoord(Vec2(0.0, 0.875),Vec2(0.125, 0.9375))
		xIcon:setCanHandleInput(false)
		xIcon:setVisible(false)
		aButton:addEventCallbackMouseFocusGain(showPanel)
		aButton:addEventCallbackMouseFocusLost(hidePanel)
		aButton:addEventCallbackExecute(removeItemByButton)
		
		aButton:setToolTip( ShopFunction.getShopToolTip(upgTab.towerName, upgTab.upgIndex, upgTab.upgLevel, true, 999) )
		
		tab.button = aButton
		tab.xIcon = xIcon
		tab.rootPanel = rootPanel
		tab.cost = upgCost
		tab.upgTab = upgTab
		tab.id = button:getPanelId()
		
		cost = cost + tab.cost
		buyCostLabel:setText(tostring(cost))
		
		if upgTab.upgLevel == 4 then
			--check for another level 4
			for i=1, countItems-1 do
				if item8Panels[i].upgTab.upgLevel == 4 and item8Panels[i].upgTab.towerName == upgTab.towerName then
					removeItemByButton(item8Panels[i].button)
					return true
				end
			end
		end
		return true
	end
	
	local function buyAllUpgrades()
		for i=1, #item8Panels do
			if item8Panels[i].id then
				itemBuyCallback(item8Panels[i].button:getTag():toString())
			end
		end
		clearAllItems()
	end
	
	local function init()
		bottomRight:setLayout(FlowLayout(Alignment.MIDDLE_RIGHT,PanelSize(Vec2(1,0.005),Vec2(1))))
		bottomRight:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)),MainMenuStyle.borderColor))
		
		
		--	Crystal
		buyCrystalImage = bottomRight:add(Image(PanelSize(Vec2(-1,-0.5),Vec2(1)), Text("icon_table.tga")))
		buyCrystalImage:setUvCoord(Vec2(0.5, 0.375),Vec2(0.625, 0.4375))
		buyCostLabel = bottomRight:add(Label(PanelSize(Vec2(-1,-0.5), Vec2(1.25,1)), tostring(cost), Vec3(0.94), Alignment.MIDDLE_RIGHT))
		
		
		buyCostButton = bottomRight:add(MainMenuStyle.createButton(Vec2(-1,-0.5), Vec2(3,1), Text("Buy") ))
		buyCostButton:addEventCallbackExecute(buyAllUpgrades)
		
		--bought icons
		item8Panel = bottomRight:add(Panel(PanelSize(Vec2(-1,-1))))
		item8Panel:setLayout(FlowLayout(Alignment.MIDDLE_RIGHT, PanelSize(Vec2(1,0.005),Vec2(1))))
		for i=1, 8 do
			item8Panels[i] = {}
			item8Panels[i].panel = item8Panel:add(Panel(PanelSize(Vec2(-1,0.51),Vec2(1),PanelSizeType.ParentPercent)))
			item8Panels[i].panel:setBackground(Sprite(Vec3(0.075)))
		end


		item18Panel= bottomRight:add(Panel(PanelSize(Vec2(-1,-1))))
		item18Panel:setLayout(FlowLayout(Alignment.MIDDLE_RIGHT, PanelSize(Vec2(1,0.005),Vec2(1))))
		item18Panel:setVisible(false)
		for i=1, 15 do
			item18Panels[i] = {}
			item18Panels[i].panel = item18Panel:add(Panel(PanelSize(Vec2(-1,0.4),Vec2(1),PanelSizeType.ParentPercent)))
			item18Panels[i].panel:setBackground(Sprite(Vec3(math.randomFloat(),math.randomFloat(),math.randomFloat())))
		end

		setBuyPanelEnable(false)
	end
	
	init()
	
	return self
end