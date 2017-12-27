require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/towerImage.lua")
require("Menu/Campaign/shopPanel.lua")

require("Game/campaignData.lua")

--this = SceneNode()
Shop = {}
function Shop.new(camera, updateCrystalButton, inPanel)
	--mainAreaPanel = Panel()
	local self = {}
	--camera = Camera()
	local form
	local parentForm
	local shopPanel = nil
	local mainPanel = nil
	local crystalCountLabel = nil
	local buyPanel = nil
	local backButtonCallback = nil
	local updateCrystalCallback = updateCrystalButton
	
	local data = ShopFunction.data
	local language = Language() 
	local buttonList = {}
	local textUpgList = {}
	local predefinedUpdateButtonFunction = nil
	local predefinedupdateButtonsFunction = nil
	local towers = { "Tower/MinigunTower.lua", "Tower/ArrowTower.lua", "Tower/SwarmTower.lua", "Tower/ElectricTower.lua", "Tower/BladeTower.lua", "Tower/missileTower.lua", "Tower/quakerTower.lua", "Tower/SupportTower.lua" }
	
	local towerUpgInfo = ShopFunction.towerUpgInfo
	
	local textPanels = {}
	
	local function createBorderPanel()
		--Options panel
		mainPanel = inPanel:add(Panel(PanelSize(Vec2(-1))))
--		mainPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		--
--		--Top menu button panel
--		local aLabel = mainPanel:add(Label(PanelSize(Vec2(-1,0.04)), language:getText("campaign"), Vec3(0.94), Alignment.MIDDLE_CENTER))
--		aLabel:setTag("Shop")
--		
--		--shop = Shop.new(mainAreaPanel)
--		
--		--Add BreakLine
--		local breakLinePanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
--		local gradient = Gradient()
--		gradient:setGradientColorsHorizontal({Vec3(0.45),Vec3(0.66),Vec3(0.45)})
--		breakLinePanel:setBackground(gradient)
--		
--		local sPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9, -0.95))))
--		sPanel:setBorder(Border( BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		mainPanel:setVisible(false)
		
		return mainPanel
	end
	
	function self.destroy()
		TowerImage.destroy()
	end
	
	function self.setVisible(visible)
--		form:setVisible(visible)
		mainPanel:setVisible(visible)
	end
	
	function self.getVisible()
--		return form:getVisible()
		return mainPanel:getVisible()
	end
	
	function addTitle()
		shopPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		
		--Top menu button panel
		shopPanel:add(Label(PanelSize(Vec2(-1,0.04)),  language:getText("shop"), Vec3(0.94), Alignment.MIDDLE_CENTER))
		
		--Add BreakLine
		local breakLinePanel = shopPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		breakLinePanel:setBackground(Sprite(Vec3(0.45)))
	end
	
	
	
	local function updateUpgradeText()
		for i=1, #textUpgList do
			local label = textUpgList[i].label
			local towerName = textUpgList[i].towerName
			local upgLevel = textUpgList[i].upgLevel
			
			local countBought = 0
			local countExist = 0
			for n=1, #towerUpgInfo[towerName] do
				countBought = countBought + ( ( (upgLevel== 4 and towerUpgInfo[towerName][n].permaUppgrade ) or towerUpgInfo[towerName][n][upgLevel]) and ShopFunction.isUpgradeBought( towerUpgInfo[towerName][n], towerName, upgLevel) and 1 or 0 ) 
				countExist = countExist + ( towerUpgInfo[towerName][n][upgLevel] and 1 or 0 )
			end
			
			label:setText( tostring(countBought) .. "/" .. ( upgLevel==4 and "1" or tostring(countExist)) )
		end
	
	end
	
	local function buyUpGrade(tag)
		
		local tab = totable(tag)
		
		local towerName = tab.towerName
		local upgName = tab.towerInfo.name
		local upgLevel = tab.upgLevel
		local permUnlocked = tonumber(upgLevel) == 4
		
		--if add permenent upgrades, then remove existing permenent upgrades
		if permUnlocked and data.getTotalBuyablesBoughtForTower(towerName,true)>=1 then
			for k,v in pairs(towerUpgInfo[towerName]) do
				data.clear(towerName,v.name,true)
			end
		end
		
		--unlock upgrade
		data.buy(towerName,upgName,permUnlocked)
		
		--update labels
--		predefinedUpdateButtonFunction()
		updateUpgradeText()
		
		crystalCountLabel:setText(tostring(data.getCrystal()))
		
		--Achievements
		local comUnit = Core.getComUnit()
		if data.getTotalBuyablesBought()>=1 then
			comUnit:sendTo("SteamAchievement","Shop1","")
		end
		if data.getTotalBuyablesBought()>=44 then
			comUnit:sendTo("SteamAchievement","Shop50","")
		end
		if data.getTotalBuyablesBought()==88 then
			comUnit:sendTo("SteamAchievement","Shop100","")
		end
		print("data.getTotalBuyablesBought() == "..data.getTotalBuyablesBought())
		
		if updateCrystalCallback then
			updateCrystalCallback()
		end
	end

	--
	--	Purpose: to unlock/permently buy an upgrade for a tower
	--
	local function shopButtonClicked(theButton)
		print("Tag: "..theButton:getTag():toString())
		local tab = totable(theButton:getTag():toString())
		
		if buyPanel.getIsInCart(theButton) then
			buyPanel.removeItem(theButton)
		else
			buyPanel.addItem(theButton)
		end



		--update the button
		predefinedupdateButtonsFunction()
--		for i=1, #buttonList do
--			if buttonList[i].button == theButton then
--				predefinedUpdateButtonFunction(i)
--			end
--		end
	end
	
	local function updateButtonFromPanelId(id)
		for i=1, #buttonList do
			if buttonList[i].button:getPanelId() == id then
				predefinedUpdateButtonFunction(i)
			end
		end
	end
	
	local function updateButtonIndex(Index)
		
		local towerInfo = buttonList[Index].towerInfo
		local towerName = buttonList[Index].towerName
		local upgLevel = buttonList[Index].upgLevel
		local button = buttonList[Index].button
		local upgIndex = buttonList[Index].upgIndex
		local iconImage = buttonList[Index].iconImage

		local isInCart = buyPanel and buyPanel.getIsInCart(button) or false
		local isUpgBought = ShopFunction.isUpgradeBought(towerInfo, towerName, upgLevel)
		local state = isUpgBought and 1 or (isInCart and 3 or 2 )
		
		if buttonList[Index].state ~= state then
			
			buttonList[Index].state = state
			
			if upgLevel==4 then
				--set edge color for permaunlocked uppgrades
				local colorScale = ( isUpgBought or isInCart ) and 1.0 or 0.35 
				local borderColor = isInCart and Vec3(1,1,0.1) or Vec3(1,0.8,0.07)
				button:setEdgeColor(Vec4(borderColor * colorScale,1))
				button:setEdgeHoverColor(Vec4(borderColor,1))
				button:setEdgeDownColor(Vec4(borderColor,1))
			else
				--set edge color for all other upgrades
				local colorScale = ( isUpgBought or isInCart ) and 1.0 or 0.4
				local borderColor = isInCart and Vec3(0.3,0.3,0.8) or MainMenuStyle.borderColor:toVec3() 
				button:setEdgeColor(Vec4(borderColor * colorScale,MainMenuStyle.borderColor.w))
				button:setEdgeHoverColor(Vec4( borderColor, MainMenuStyle.borderColor.w))
				button:setEdgeDownColor(Vec4( borderColor, MainMenuStyle.borderColor.w))
			end
			
			local buttonColor = (isUpgBought or isInCart ) and Vec4() or Vec4(0,0,0,0.7)
			button:setInnerColor(buttonColor, buttonColor, buttonColor)
			button:setInnerHoverColor( ( isUpgBought or isInCart ) and Vec4(1,1,1,0.1) or Vec4())
			button:setInnerDownColor( ( isUpgBought or isInCart ) and Vec4(1,1,1,0.1) or Vec4(0,0,0,0.25))
			
			buttonList[Index].moneyIcon:setVisible(isInCart)
			
--				iconImage:setBackground(Sprite(isInCart and Vec3(0.3,0.3,0.3) or Vec3(0)))
			
			
		end
		
		local isPreviousUpgradeInCart = upgLevel ~= 1 and (buyPanel and buyPanel.isUpgradeInCart(upgIndex, towerName, upgLevel-1))
		button:setToolTip( ShopFunction.getShopToolTip(towerName, upgIndex, upgLevel, isPreviousUpgradeInCart, ShopFunction.data.getCrystal() - (buyPanel and buyPanel.getCost() or 0 )) )
		
		if (not isUpgBought) and (upgLevel==1 or (ShopFunction.isUpgradeBought(towerInfo, towerName, upgLevel-1)) or isPreviousUpgradeInCart ) and data.getCrystal() >= ShopFunction.getUpgradeCost(towerInfo, towerName, upgLevel) then
			--not bought
			local tab = {towerName=towerName, towerInfo=towerInfo, upgLevel=upgLevel, upgIndex=upgIndex}
			button:setTag(tabToStrMinimal(tab))
			button:clearEvents()
			button:addEventCallbackExecute(shopButtonClicked)
		else
			button:setTag("")
			button:clearEvents()
		end
	end
	
	local function updateButtons()
		
		for i=1, #buttonList do
			updateButtonIndex(i)
		end
	
	end

	local function  closeClicked()
		self.setVisible( false )
		if backButtonCallback then
			backButtonCallback()
		end
	end
	
	function self.setGoBackCallback(inBackButtonCallback)
		backButtonCallback = inBackButtonCallback
	end
	
	local function init()
	
		predefinedupdateButtonsFunction = updateButtons
		predefinedUpdateButtonFunction = updateButtonIndex
	
		local panelSpacing = 0.005
		local panelSpacingVec2 = Vec2(panelSpacing, panelSpacing)
		
		-- Basic upgrades that every one should have
		if data.getBoughtUpg("Tower/SupportTower.lua","range",false)==0 then
			data.buy("Tower/SupportTower.lua","range",false)
		end
		if data.getBoughtUpg("Tower/SupportTower.lua","damage",false)==0 then
			data.buy("Tower/SupportTower.lua","damage",false)
		end
		--
		
		shopPanel = createBorderPanel()
		
--		form = Form(camera, PanelSize(Vec2(-1,-0.8), Vec2(1.2,1)), Alignment.MIDDLE_CENTER);
--		form:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(panelSpacingVec2)));
--		form:setRenderLevel(9)	
--		form:setVisible(false)
--		
--		shopPanel = form:add(Panel(PanelSize(Vec2(-1))))
		
		shopPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, Vec4(0,0,0,0.5)))
		--shopPanel:setBackground( Sprite(Vec4(1,1,1,0.5)) )--DEBUG coloring
--		shopPanel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)),MainMenuStyle.borderColor))
		
		--Add the title
		addTitle()
		
		local shopArea = shopPanel:add(Panel(PanelSize(Vec2(-0.9,-0.86))))
		shopArea:setLayout(GridLayout(4,2)):setPanelSpacing(PanelSize( Vec2(0.025), Vec2(1), PanelSizeType.WindowPercent ))
		
		for i=1, 8 do
			local towerPane1 = shopArea:add(Panel(PanelSize(Vec2(-1))))
			
			towerPane1:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
			
			
			towerPane1:setBorder(Border( BorderSize( Vec4(MainMenuStyle.borderSize) ), MainMenuStyle.borderColor ) )
			towerPane1:setPadding(BorderSize(Vec4(MainMenuStyle.borderSize * 3)))
			
			towerPane1:setLayout(FlowLayout(PanelSize(Vec2(MainMenuStyle.borderSize * 3),Vec2(1))))
			
			local towerImage = towerPane1:add(Image(PanelSize(Vec2(-1), Vec2(1)), "icon_tower_table.tga"))
			towerImage:setBorder(Border( BorderSize( Vec4(MainMenuStyle.borderSize * 2) ), MainMenuStyle.borderColor ) )
			local textureOffset = Vec2((i%3)/3.0, math.floor((8-i)/3.0) * 0.3333)
			towerImage:setUvCoord( textureOffset, textureOffset + Vec2(0.3333))
			
			local upgradeAreaPanel = towerPane1:add(Panel(PanelSize(Vec2(-1),Vec2(5,4))))
			upgradeAreaPanel:setLayout(GridLayout(4,5, PanelSize(Vec2(MainMenuStyle.borderSize), Vec2(1))))
			
			local upgIcons = Core.getTexture("Data/Images/icon_table.tga")
			
			for y=1, 4 do
				for x=1, 5 do
					local towerinfo = towerUpgInfo[towers[i]]
					if towerinfo[x] then
					
						if (y==1 and towerinfo[x].permaUppgrade) or (y==4 and towerinfo[x].permaUppgrade == false and towerinfo[x][5-y] == nil) or towerinfo[x][5-y] then
							local offset = Vec2( towerinfo[x].iconIndex%8*0.125, math.floor(towerinfo[x].iconIndex/8)*0.0625 )
							
							local iconImage = upgradeAreaPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)),upgIcons))
							iconImage:setUvCoord(offset,offset+Vec2(0.125,0.0625))
							iconImage:setImageScale(0.9)
							
							local panel = nil
							if y~=1 and towerinfo[x][5-y] then 
								--add level icon to the button
								panel = iconImage:add(Image(PanelSize(Vec2(-1)),upgIcons))
								
								local levelOffset = Vec2(0.125*(5+4-y),0.0625*5)
								panel:setUvCoord(levelOffset,levelOffset+Vec2(0.125,0.0625))
								panel:setImageScale(0.85)
								
							else
								panel = iconImage
							end
							
							local button = panel:add(Button(PanelSize(Vec2(-1), Vec2(1)),"",ButtonStyle.SQUARE))
							button:setLayout(FlowLayout(Alignment.BOTTOM_LEFT))
							local moneyIcon = button:add(Image(PanelSize(Vec2(-0.5), Vec2(1)),upgIcons))
							moneyIcon:setUvCoord(Vec2(),Vec2(0.125,0.0625))
							moneyIcon:setImageScale(0.85)
							moneyIcon:setVisible(false)
							moneyIcon:setCanHandleInput(false)
							
							local thisButtonTab = {}
							buttonList[#buttonList + 1] = thisButtonTab
							thisButtonTab.iconImage = iconImage
							thisButtonTab.button = button
							thisButtonTab.moneyIcon = moneyIcon
							thisButtonTab.towerInfo = towerinfo[x]
							thisButtonTab.towerName = towers[i]
							thisButtonTab.upgLevel = 5-y
							thisButtonTab.upgIndex = x
		
						else
							upgradeAreaPanel:add(Panel(PanelSize(Vec2(-1))))
						end
					else
						upgradeAreaPanel:add(Panel(PanelSize(Vec2(-1))))
					end
				end
			end
			
			local textAreaPanel = towerPane1:add(Panel(PanelSize(Vec2(-1))))
			textAreaPanel:setLayout(GridLayout(4,1, PanelSize(Vec2(MainMenuStyle.borderSize), Vec2(1))))
			
			for n=1, 4 do
				local label = textAreaPanel:add(Label(PanelSize(Vec2(-1)), n == 4 and "0/1" or "0/4"))
				label:setTextColor(MainMenuStyle.textColorHighLighted)
				
				textUpgList[#textUpgList + 1] = {}
				textUpgList[#textUpgList].label = label
				textUpgList[#textUpgList].towerName = towers[i]
				textUpgList[#textUpgList].upgLevel = 5-n
			end
		end
		
		updateButtons()
		updateUpgradeText()
		
		--bottom info
		local bottomPanel = shopPanel:add(Panel(PanelSize(Vec2(-0.9,-0.85))))
		bottomPanel:setLayout(GridLayout(1,2)):setPanelSpacing(PanelSize( Vec2(0.025), Vec2(1), PanelSizeType.WindowPercent ))
		
		local bottomLeft = bottomPanel:add(Panel(PanelSize(Vec2(-1))))
		bottomRight = bottomPanel:add(Panel(PanelSize(Vec2(-1))))
		
		
		bottomLeft:setLayout(FlowLayout(Alignment.MIDDLE_CENTER,PanelSize(Vec2(-1,-1))))
		--bottomPanel:add(Panel(PanelSize(Vec2(0.025,-1))))--spacing
		
		--crystal count
		--bottomPanel:add(Panel(PanelSize(Vec2(0.025,-1))))--spacing
		crystalCountLabel = bottomLeft:add(Label(PanelSize(Vec2(-1,0.035),Vec2(1.25,1)), tostring(data.getCrystal()), Vec3(0.94), Alignment.MIDDLE_LEFT))
		crystalCountLabel:setTextColor(Vec3(0.5,1,0.5))
		local image = bottomLeft:add(Image(PanelSize(Vec2(0.035),Vec2(0.9,1)), Text("icon_table.tga")))
		image:setUvCoord(Vec2(0.5, 0.375),Vec2(0.625, 0.4375))
		
		--close
		bottomLeft:add(Panel(PanelSize(Vec2(-1,0.03),Vec2(3,1))))--spacing
		local button = bottomLeft:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(5,1), language:getText("back") ))
		button:addEventCallbackExecute( closeClicked )
		
		bottomRight:setLayout(FlowLayout(Alignment.MIDDLE_CENTER,PanelSize(Vec2(-1,-1))))
		local shopPanelsPanel = bottomRight:add(Panel(PanelSize(Vec2(-1,-0.57))))
		
		buyPanel = ShopPanel.new(shopPanelsPanel)
		buyPanel.setItemRemovedCallback(updateButtonFromPanelId)
		buyPanel.setBuyItemCallback(buyUpGrade)
		buyPanel.setItemUpdateCallback(updateButtons)
	end
	init()

	--Update the map panel
	function self.update()
--		form:update()
		TowerImage.update()
	end
		
	return self
end