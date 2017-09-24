require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/towerImage.lua")
require("Game/campaignData.lua")
--this = SceneNode()
Shop = {}
function Shop.new(camera)
	--mainAreaPanel = Panel()
	local self = {}
	--camera = Camera()
	local form
	local parentForm
	local shopPanel = nil
	local crystalCountLabel = nil
	local data = CampaignData.new()
	local language = Language() 
	local buttonList = {}
	local textUpgList = {}
	local predefinedUpdateButtonFunction = nil
	local towers = { "Tower/MinigunTower.lua", "Tower/ArrowTower.lua", "Tower/SwarmTower.lua", "Tower/ElectricTower.lua", "Tower/BladeTower.lua", "Tower/missileTower.lua", "Tower/quakerTower.lua", "Tower/SupportTower.lua" }
	local towerUpgInfo = { ["Tower/MinigunTower.lua"]={
			{text="minigun tower range",[1]={["value1"]="5.75"},[2]={["value1"]="6.5"},[3]={["value1"]="7.25"}, permaUppgrade=true, iconIndex=59, name="range" },
			{text="minigun tower overcharge",[1]={["value1"]="40"},[2]={["value1"]="80"},[3]={["value1"]="120"}, permaUppgrade=true, iconIndex=63, name="overCharge"},
			{text="minigun tower firecrit",[1]={["value1"]="20"},[2]={["value1"]="40"},[3]={["value1"]="60"}, permaUppgrade=true, iconIndex=36, name="fireCrit"}
		},
		["Tower/ArrowTower.lua"]={
			{text="Arrow tower range",[1]={["value1"]="10.5"},[2]={["value1"]="12"},[3]={["value1"]="13.5"}, permaUppgrade=true, iconIndex=59, name="range" },
			{text="Arrow tower hardArrow",[1]={["value1"]="135",["value2"]="50"},[2]={["value1"]="240",["value2"]="60"},[3]={["value1"]="410",["value2"]="70"}, permaUppgrade=true, iconIndex=54, name="hardArrow"},
			{text="Arrow tower mark of death",[1]={["value1"]="8"},[2]={["value1"]="16"},[3]={["value1"]="24"}, permaUppgrade=true, iconIndex=61, name="markOfDeath"}
		},
		["Tower/SwarmTower.lua"]={
			{text="swarm tower range",[1]={["value1"]="7.25"},[2]={["value1"]="8"},[3]={["value1"]="8.75"}, permaUppgrade=true, iconIndex=59, name="range"},
			{text="swarm tower damage",[1]={["value1"]="30"},[2]={["value1"]="60"},[3]={["value1"]="90"}, permaUppgrade=true, iconIndex=2, name="burnDamage"},
			{text="swarm tower fire",[1]={["value1"]="22",["value2"]="15"},[2]={["value1"]="38",["value2"]="30"},[3]={["value1"]="52",["value2"]="45"}, permaUppgrade=true, iconIndex=38, name="fuel"}
		},
		["Tower/ElectricTower.lua"]={
			{text="electric tower range",[1]={["value1"]="4.75"},[2]={["value1"]="5.5"},[3]={["value1"]="6.25"}, permaUppgrade=true, iconIndex=59 , name="range"},
			{text="electric tower slow",[1]={["value1"]="15",["value2"]="0.75"},[2]={["value1"]="30",["value2"]="1.25"},[3]={["value1"]="45",["value2"]="1.75"}, permaUppgrade=true, iconIndex=55, name="ampedSlow"},
			{text="electric tower energy pool",[1]={["value1"]="30"},[2]={["value1"]="60"},[3]={["value1"]="90"}, permaUppgrade=true, iconIndex=41, name="energyPool"},
			{text="electric tower energy regen",[1]={["value1"]="15"},[2]={["value1"]="30"},[3]={["value1"]="45"}, permaUppgrade=true, iconIndex=38, name="energy"}
		},
		["Tower/BladeTower.lua"]={
			{text="Arrow tower range",[1]={["value1"]="10.5"},[2]={["value1"]="12"},[3]={["value1"]="13.5"}, permaUppgrade=true, iconIndex=59, name="range" },
			{text="blade tower attackSpeed",[1]={["value1"]="15"},[2]={["value1"]="30"},[3]={["value1"]="45"}, permaUppgrade=true, iconIndex=58, name="attackSpeed"},
			{text="blade tower firecrit",[1]={["value1"]="20"},[2]={["value1"]="40"},[3]={["value1"]="60"}, permaUppgrade=true, iconIndex=36, name="masterBlade"},
			{text="blade tower slow",[1]={["value1"]="20"},[2]={["value1"]="36"},[3]={["value1"]="49"}, permaUppgrade=true, iconIndex=55, name="electricBlade"},
			{text="blade tower shield", [1]={}, permaUppgrade=true, iconIndex=40, name="shieldBreaker"}
		},
		["Tower/missileTower.lua"]={
			{text="missile tower range",[1]={["value1"]="8"},[2]={["value1"]="9"},[3]={["value1"]="10"}, permaUppgrade=true, iconIndex=59, name="range" },
			{text="missile tower explosion",[1]={["value1"]="8"},[2]={["value1"]="16"},[3]={["value1"]="24"}, permaUppgrade=true, iconIndex=39, name="Blaster"},
			{text="missile tower fire",[1]={["value1"]="20",["value2"]="1"},[2]={["value1"]="22",["value2"]="1.75"},[3]={["value1"]="24",["value2"]="2.5"}, permaUppgrade=true, iconIndex=38, name="fuel"},
			{text="missile tower shield destroyer", [1]={}, permaUppgrade=true, iconIndex=42, name="shieldSmasher"}
		},
		["Tower/quakerTower.lua"]={
			{text="quak tower firecrit",[1]={["value1"]="40"},[2]={["value1"]="80"},[3]={["value1"]="120"}, permaUppgrade=false, iconIndex=36, name="fireCrit"},
			{text="quak tower fire",[1]={["value1"]="20",["value2"]="1"},[2]={["value1"]="22",["value2"]="1.75"},[3]={["value1"]="24",["value2"]="2.5"}, permaUppgrade=false, iconIndex=38, name="fireStrike"},
			{text="quak tower electric",[1]={["value1"]="30",["value2"]="15"},[2]={["value1"]="60",["value2"]="28"},[3]={["value1"]="90",["value2"]="39"}, permaUppgrade=false, iconIndex=50, name="electricStrike"},
			{text="free sub upgrade", permaUppgrade=true, iconIndex=53, name="freeUpgrade"}
		},
		["Tower/SupportTower.lua"]={
			{text="support tower range",[1]={["value1"]="10"},[2]={["value1"]="20"},[3]={["value1"]="30"}, permaUppgrade=true, iconIndex=59, name="range" },
			{text="support tower damage",[1]={["value1"]="10"},[2]={["value1"]="20"},[3]={["value1"]="30"}, permaUppgrade=true, iconIndex=64, name="damage"},
			{text="support tower weaken",[1]={["value1"]="10"},[2]={["value1"]="20"},[3]={["value1"]="30"}, permaUppgrade=true, iconIndex=66, name="weaken"},
			{text="support tower gold",[1]={["value1"]="1"},[2]={["value1"]="2"},[3]={["value1"]="3"}, permaUppgrade=true, iconIndex=67, name="gold"}
		}
	}

	
	local textPanels = {}
	
	function self.destroy()
		TowerImage.destroy()
	end
	
	function self.setVisible(visible)
		form:setVisible(visible)
	end
	
	function self.getVisible()
		return form:getVisible()
	end
	
	function addTitle()
		shopPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		
		--Top menu button panel
		shopPanel:add(Label(PanelSize(Vec2(-1,0.04)),  language:getText("shop"), Vec3(0.94), Alignment.MIDDLE_CENTER))
		
		--Add BreakLine
		local breakLinePanel = shopPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		breakLinePanel:setBackground(Sprite(Vec3(0.45)))
	end
	local function updateShopButtonToolTip(towerName,upgName)
		local button = textPanels[towerName][upgName]["0"].button
		local displayLevel = math.max(1,math.min(data.getBoughtUpg(towerName,upgName,false)+1,data.getBuyablesTotal(upgName,false)))
		local tab = towerUpgInfo[towerName][upgName]
		local str = Text()
		
		local permLeft = data.getBuyablesTotal(upgName,true)-data.getBoughtUpg(towerName,upgName,true)
		local doneLevels = upgName=="freeUpgrade" and 1 or data.getBoughtUpg(towerName,upgName,false)
		for i=1, doneLevels do
			if permLeft==0 and i==1 then
				str = str + "<font color=rgb(40,255,40)>"
				str = str + "Bought" + ":</font>\n"
			elseif (permLeft==1 and i==1) or (permLeft==0 and i==2) then
				if doneLevels>=1 then
					str = str + "<font color=rgb(40,255,40)>"
					str = str + "Buyable" + ":</font>\n"--language:getText("unlocked")
				end
			end
			str = str + ("Level "..i.." = ")
			tab =  towerUpgInfo[towerName][upgName][i]
			if not tab then
				str = str + language:getTextWithValues(towerUpgInfo[towerName][upgName].text,"")
			elseif tab["value2"]==nil then
				str = str + language:getTextWithValues(towerUpgInfo[towerName][upgName].text,tab["value1"])
			else
				str = str + language:getTextWithValues(towerUpgInfo[towerName][upgName].text,tab["value1"],tab["value2"])
			end
			str = str + "\n"
		end
		if doneLevels~=displayLevel then
			str = str + "<font color=rgb(255,255,40)>"
			str = str + language:getText("locked") + ":</font>\n"
			for i=displayLevel, data.getBuyablesTotal(upgName,upgName=="freeUpgrade") do
				str = str + ("Level "..i.." = ")
				tab =  towerUpgInfo[towerName][upgName][i]
				if not tab then
					str = str + language:getTextWithValues(towerUpgInfo[towerName][upgName].text,"")
				elseif tab["value2"]==nil then
					str = str + language:getTextWithValues(towerUpgInfo[towerName][upgName].text,tab["value1"])
				else
					str = str + language:getTextWithValues(towerUpgInfo[towerName][upgName].text,tab["value1"],tab["value2"])
				end
				str = str + "\n"
			end
		end
		
		local level = data.getBoughtUpg(towerName,upgName,false)
		if level<data.getBuyablesTotal(upgName,false) then
			local cost = data.getBuyablesTotal(upgName,false)==1 and 3 or (level+1)
			if data.getCrystal()>=cost then
				str = str + "\n"
				str = str + language:getTextWithValues("crystals to unlock(enough crystals)",tostring(cost),tostring(displayLevel))
			else
				str = str + "\n"
				str = str + language:getTextWithValues("crystals to unlock(no crystals)",tostring(cost),tostring(displayLevel))
			end
		end
		button:setToolTip(str)
	end
	
	local function isUpgradeBought(towerInfo, towerName, upgLevel)
		return not ( ( upgLevel~=4 and towerInfo[upgLevel] and data.getBoughtUpg(towerName,towerInfo.name,false) < upgLevel) or 
					(upgLevel==4 and towerInfo.permaUppgrade == true and data.getBoughtUpg(towerName,towerInfo.name,true) == 0) )
	end
	
	
	local function getUpgradeCost(upgradeTab, towerName, upgLevel)
		local hasAllreadeAnPermaUnlock = false
		for i=1, #towerUpgInfo[towerName] do
			hasAllreadeAnPermaUnlock = hasAllreadeAnPermaUnlock or isUpgradeBought(towerUpgInfo[towerName][i], towerName, 4)
		end
		return isUpgradeBought(upgradeTab, towerName, upgLevel) and 0 or ( (upgLevel == 1 and upgradeTab[2] == nil) and 3 or (upgLevel == 4 and (hasAllreadeAnPermaUnlock and 0 or 12) or upgLevel))
	end
	
	local function updateUpgradeText()
		for i=1, #textUpgList do
			local label = textUpgList[i].label
			local towerName = textUpgList[i].towerName
			local upgLevel = textUpgList[i].upgLevel
			
			local countBought = 0
			local countExist = 0
			for n=1, #towerUpgInfo[towerName] do
				countBought = countBought + ( ( (upgLevel== 4 and towerUpgInfo[towerName][n].permaUppgrade ) or towerUpgInfo[towerName][n][upgLevel]) and isUpgradeBought( towerUpgInfo[towerName][n], towerName, upgLevel) and 1 or 0 ) 
				countExist = countExist + ( towerUpgInfo[towerName][n][upgLevel] and 1 or 0 )
			end
			
			label:setText( tostring(countBought) .. " / " .. ( upgLevel==4 and "1" or tostring(countExist)) )
		end
	
	end
	
	local function getShopToolTip(towerName,upgNameIndex, upgradeLevel)

		local tabUppgrade = towerUpgInfo[towerName][upgNameIndex]
		local str = Text()

		local upgradeAllreadyBought = (upgradeLevel == 4 and data.getBoughtUpg(towerName,tabUppgrade.name,true) == 1) or (data.getBoughtUpg(towerName,tabUppgrade.name,false) >= upgradeLevel )
		if upgradeAllreadyBought then
			str = str + "<font color=rgb(40,255,40)>"
			str = str + "Bought" + ":</font>\n"
		else
			str = str + "<font color=rgb(40,255,40)>"
			str = str + "Buyable" + ":</font>\n"--language:getText("unlocked")
		end
		str = str + ("Level "..upgradeLevel.." = ")
		local subUppgradeTab =  tabUppgrade[upgradeLevel]
		if subUppgradeTab and subUppgradeTab["value1"] and not subUppgradeTab["value2"] then
			str = str + language:getTextWithValues(tabUppgrade.text,subUppgradeTab["value1"])
		elseif subUppgradeTab and subUppgradeTab["value1"] and subUppgradeTab["value2"] then
			str = str + language:getTextWithValues(tabUppgrade.text,subUppgradeTab["value1"],subUppgradeTab["value2"])
		else
			str = str + language:getTextWithValues(tabUppgrade.text,"")
		end
		str = str + "\n"

		local cost = getUpgradeCost(towerUpgInfo[towerName][upgNameIndex], towerName, upgradeLevel)--(upgradeLevel==4) and 12 or upgradeLevel
		local canAffordToPay = data.getCrystal()>=cost
		local textHeight = Core.getScreenResolution().y * 0.0125
		local costLabel = Label(PanelSize(Vec2(-1), Vec2(3,1)), Text(tostring(cost)), canAffordToPay and Vec3(0,1,0) or Vec3(1,0,0), Alignment.TOP_RIGHT )
		costLabel:setTextHeight(textHeight)
		local costLabelSize = costLabel:getTextSizeInPixel()
		
		local panel = Panel(PanelSize(Vec2(0.2)))
		local label = Label(PanelSize(Vec2(-1)), str, Vec3(1), Alignment.TOP_LEFT)
		label:setTextHeight(textHeight)
		local textSize = label:getTextSizeInPixel()
		label:setPanelSize(PanelSize(textSize,PanelSizeType.Pixel))--Vec2(Core.getScreenResolution().y * 0.004)
		panel:setPanelSize(PanelSize(textSize + ( upgradeAllreadyBought == false and Vec2(0,costLabelSize.y) or Vec2() ),PanelSizeType.Pixel))
		panel:setLayout(FallLayout())
		panel:add(label)
		if upgradeAllreadyBought == false then
			local costRow = panel:add(Panel(PanelSize(Vec2(-1))))
			costLabel:setPanelSize(PanelSize(costLabelSize,PanelSizeType.Pixel))
			costRow:add(costLabel)
			costRow:add(Image(PanelSize(Vec2(-1,-0.9), Vec2(1)), "icon_table.tga")):setUvCoord(Vec2(0.5, 0.375),Vec2(0.625, 0.4375))
		end
		
		return panel 
	end

	--
	--	Purpose: to unlock/permently buy an upgrade for a tower
	--
	local function shopButtonClicked(theButton)
		print("Tag: "..theButton:getTag():toString())
		local towerName,upgName,upgLevel = string.match(theButton:getTag():toString(), "(.*);(.*);(.*)")
		local permUnlocked = tonumber(upgLevel) == 4--  data.getBoughtUpg(towerName,upgName,false)==data.getBuyablesTotal(upgName,false)
		
		--if add permenent upgrades, then remove existing permenent upgrades
		if permUnlocked and data.getTotalBuyablesBoughtForTower(towerName,true)>=1 then
			for k,v in pairs(towerUpgInfo[towerName]) do
				data.clear(towerName,v.name,true)
			end
		end
		
		--unlock upgrade
		data.buy(towerName,upgName,permUnlocked)
		
		--update labels
		predefinedUpdateButtonFunction()
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
	end

	local function  closeClicked()
		self.setVisible( false )
		parentForm:setVisible( true )
	end
	
	function self.setParentForm(pForm)
		parentForm = pForm
	end
		
	
	local function updateButtons()
		
		for i=1, #buttonList do
			
			local towerInfo = buttonList[i].towerInfo
			local towerName = buttonList[i].towerName
			local upgLevel = buttonList[i].upgLevel
			local button = buttonList[i].button
			local upgIndex = buttonList[i].upgIndex
			
			local isUpgBought = isUpgradeBought(towerInfo, towerName, upgLevel)
			local state = isUpgBought and 1 or 2
			
			if buttonList[i].state ~= state then
				
				buttonList[i].state = state
				
				if upgLevel==4 then
					--set edge color for permaunlocked uppgrades
					local colorScale = isUpgBought and 1.0 or 0.35
					button:setEdgeColor(Vec4(Vec3(1,0.8,0.07) * colorScale,1))
					button:setEdgeHoverColor(Vec4(1,0.8,0.07,1))
					button:setEdgeDownColor(Vec4(1,0.8,0.07,1))
				else
					--set edge color for all other upgrades
					local colorScale = isUpgBought and 1.0 or 0.4
					button:setEdgeColor(Vec4(MainMenuStyle.borderColor:toVec3() * colorScale,MainMenuStyle.borderColor.w))
					button:setEdgeHoverColor(MainMenuStyle.borderColor)
					button:setEdgeDownColor(MainMenuStyle.borderColor)
				end
				
				local boderColor = isUpgBought and Vec4() or Vec4(0,0,0,0.7)
--				if (upgLevel~=4 and towerInfo[upgLevel] and data.getBoughtUpg(towerName,towerInfo.name,false) < upgLevel) or (upgLevel==4 and towerInfo.permaUppgrade == true and data.getBoughtUpg(towerName,towerInfo.name,true) == 0) then 
--					boderColor = Vec4(0,0,0,0.7)
--				end
				
				button:setInnerColor(boderColor,boderColor,boderColor)
				button:setInnerHoverColor( isUpgBought and Vec4(1,1,1,0.1) or Vec4())
				button:setInnerDownColor( isUpgBought and Vec4(1,1,1,0.1) or Vec4(0,0,0,0.25))
				
			end
			
			button:setToolTip( getShopToolTip(towerName, upgIndex, upgLevel) )
			
			if (not isUpgBought) and (upgLevel==1 or isUpgradeBought(towerInfo, towerName, upgLevel-1)) and data.getCrystal() >= getUpgradeCost(towerInfo, towerName, upgradeLevel) then
				--not bought
				button:setTag(towerName..";"..towerInfo.name..";"..upgLevel)
				button:clearEvents()
				button:addEventCallbackExecute(shopButtonClicked)
			else
				button:setTag("")
				button:clearEvents()
			end
			
		end
	
	end
	
	local function init()
	
		predefinedUpdateButtonFunction = updateButtons
	
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
		
		form = Form(camera, PanelSize(Vec2(-1,-0.8), Vec2(1.2,1)), Alignment.MIDDLE_CENTER);
		form:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(panelSpacingVec2)));
		form:setRenderLevel(9)	
		form:setVisible(false)
		
		shopPanel = form:add(Panel(PanelSize(Vec2(-1))))
		
		shopPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, Vec4(0,0,0,0.5)))
		--shopPanel:setBackground( Sprite(Vec4(1,1,1,0.5)) )--DEBUG coloring
		shopPanel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)),MainMenuStyle.borderColor))
		
		--Add the title
		addTitle()
		
		local shopArea = shopPanel:add(Panel(PanelSize(Vec2(-0.875,-0.9))))
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
							
							local thisButtonTab = {}
							buttonList[#buttonList + 1] = thisButtonTab
							thisButtonTab.button = panel:add(Button(PanelSize(Vec2(-1), Vec2(1)),"",ButtonStyle.SQUARE))
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
				local label = textAreaPanel:add(Label(PanelSize(Vec2(-1)), n == 4 and "0 / 1" or "0 / 4"))
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
		local bottomPanel = shopPanel:add(Panel(PanelSize(Vec2(-1))))
		bottomPanel:setLayout(FlowLayout(Alignment.MIDDLE_CENTER,PanelSize(Vec2(-1,-1))))
		--bottomPanel:add(Panel(PanelSize(Vec2(0.025,-1))))--spacing
		
		--crystal count
		--bottomPanel:add(Panel(PanelSize(Vec2(0.025,-1))))--spacing
		crystalCountLabel = bottomPanel:add(Label(PanelSize(Vec2(-1,0.035),Vec2(1.25,1)), tostring(data.getCrystal()), Vec3(0.94), Alignment.MIDDLE_LEFT))
		local image = bottomPanel:add(Image(PanelSize(Vec2(0.035),Vec2(0.9,1)), Text("icon_table.tga")))
		image:setUvCoord(Vec2(0.5, 0.375),Vec2(0.625, 0.4375))
		
		--close
		bottomPanel:add(Panel(PanelSize(Vec2(-1,0.03),Vec2(3,1))))--spacing
		local button = bottomPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(5,1), language:getText("back") ))
		button:addEventCallbackExecute( closeClicked )
		
--		--Add a tower uppgrade area
--		addShopArea()
	end
	init()

	--Update the map panel
	function self.update()
		form:update()
		TowerImage.update()
	end
		
	return self
end