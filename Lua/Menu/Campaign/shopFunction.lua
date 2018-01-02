require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/towerImage.lua")
require("Game/campaignData.lua")
--this = SceneNode()
ShopFunction = {}
ShopFunction.data = CampaignData.new()
ShopFunction.towerUpgInfo = { ["Tower/MinigunTower.lua"]={
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
			--{text="support tower damage",[1]={["value1"]="10"},[2]={["value1"]="20"},[3]={["value1"]="30"}, permaUppgrade=true, iconIndex=64, name="damage"},
			{text="support tower weaken",[1]={["value1"]="10"},[2]={["value1"]="20"},[3]={["value1"]="30"}, permaUppgrade=true, iconIndex=66, name="weaken"},
			{text="support tower gold",[1]={["value1"]="1"},[2]={["value1"]="2"},[3]={["value1"]="3"}, permaUppgrade=true, iconIndex=67, name="gold"}
		}
	}
	
function ShopFunction.isUpgradeBought(towerInfo, towerName, upgLevel)
	return not ( ( upgLevel~=4 and towerInfo[upgLevel] and ShopFunction.data.getBoughtUpg(towerName,towerInfo.name,false) < upgLevel) or 
				(upgLevel==4 and towerInfo.permaUppgrade == true and ShopFunction.data.getBoughtUpg(towerName,towerInfo.name,true) == 0) )
end

function ShopFunction.getUpgradeCost(upgradeTab, towerName, upgLevel)
	local hasAllreadeAnPermaUnlock = false
	for i=1, #ShopFunction.towerUpgInfo[towerName] do
		hasAllreadeAnPermaUnlock = hasAllreadeAnPermaUnlock or ShopFunction.isUpgradeBought(ShopFunction.towerUpgInfo[towerName][i], towerName, 4)
	end
	return ShopFunction.isUpgradeBought(upgradeTab, towerName, upgLevel) and 0 or ( (upgLevel == 1 and upgradeTab[2] == nil) and 3 or (upgLevel == 4 and (hasAllreadeAnPermaUnlock and 0 or 12) or upgLevel))
end

function ShopFunction.getCostForUpgrade(towerName,upgNameIndex, upgradeLevel)
	return ShopFunction.getUpgradeCost(ShopFunction.towerUpgInfo[towerName][upgNameIndex], towerName, upgradeLevel)
end
	
function ShopFunction.getShopToolTip(towerName,upgNameIndex, upgradeLevel, isPreviousUpgradeInCart, crystalLeft)

	local tabUppgrade = ShopFunction.towerUpgInfo[towerName][upgNameIndex]
	local str = Text()

	local upgradeAllreadyBought = (upgradeLevel == 4 and ShopFunction.data.getBoughtUpg(towerName,tabUppgrade.name,true) == 1) or (ShopFunction.data.getBoughtUpg(towerName,tabUppgrade.name,false) >= upgradeLevel )
	local canBeBought = true
	if upgradeLevel>1 and not isPreviousUpgradeInCart then
		canBeBought = (upgradeLevel == 4 and ShopFunction.data.getBoughtUpg(towerName,tabUppgrade.name,false) >= 3) or (ShopFunction.data.getBoughtUpg(towerName,tabUppgrade.name,false) >= (upgradeLevel-1) )
	end
	if upgradeLevel == 4 then
		if upgradeAllreadyBought then
			str = str + "<font color=rgb(40,255,40)>"
			str = str + "Bought: (permanently unlocks level 1)</font>\n"
		elseif canBeBought then
			str = str + "<font color=rgb(40,255,40)>"
			str = str + "Buyable: (permanently unlocks level 1)</font>\n"--language:getText("unlocked")
		else
			str = str + "<font color=rgb(255,40,40)>"
			str = str + "Level 3 is not unlocked: (permanently unlocks level 1)</font>\n"--language:getText("unlocked")
		end
	else	
		if upgradeAllreadyBought then
			str = str + "<font color=rgb(40,255,40)>"
			str = str + "Bought:</font>\n"
		elseif canBeBought then
			str = str + "<font color=rgb(40,255,40)>"
			str = str + "Buyable:</font>\n"--language:getText("unlocked")
		else
			str = str + "<font color=rgb(255,40,40)>"
			str = str + "Level " + tostring(upgradeLevel-1) + " is not unlocked:</font>\n"--language:getText("unlocked")
		end
	end
	
	local subUppgradeTab =  tabUppgrade[upgradeLevel == 4 and 1 or upgradeLevel]
	
	if subUppgradeTab and subUppgradeTab["value1"] and subUppgradeTab["value2"] then
		str = str + language:getTextWithValues(tabUppgrade.text,subUppgradeTab["value1"],subUppgradeTab["value2"])
	elseif subUppgradeTab and subUppgradeTab["value1"] then
--			str = str + Text("1 values found\n")
--			print("Value1: "..subUppgradeTab["value1"])
--			print(str:toString())
		str = str + language:getTextWithValues(tabUppgrade.text,subUppgradeTab["value1"])
	else
--			str = str + Text("0 values found\n")
--			print(str:toString())
		str = str + language:getTextWithValues(tabUppgrade.text,"")
	end
	str = str + "\n"

	local cost = ShopFunction.getUpgradeCost(ShopFunction.towerUpgInfo[towerName][upgNameIndex], towerName, upgradeLevel)--(upgradeLevel==4) and 12 or upgradeLevel
	local canAffordToPay = crystalLeft>=cost
	local textHeight = Core.getScreenResolution().y * 0.0125
	local costLabel = Label(PanelSize(Vec2(-1), Vec2(3,1)), Text(tostring(cost)), canAffordToPay and Vec3(0,1,0) or Vec3(1,0,0), Alignment.TOP_RIGHT )
	costLabel:setTextHeight(textHeight)
	local costLabelSize = costLabel:getTextSizeInPixel()
	costLabelSize = costLabelSize + Vec2(2,0)
	
	local panel = Panel(PanelSize(Vec2(0.2)))
	local label = Label(PanelSize(Vec2(-1)), str, Vec3(1), Alignment.TOP_LEFT)
	label:setTextHeight(textHeight)
	local textSize = label:getTextSizeInPixel()+ Vec2(7,1)
	label:setPanelSize(PanelSize(textSize,PanelSizeType.Pixel))--Vec2(Core.getScreenResolution().y * 0.004)
--		label:setText(str)
--		label:setPanelSizeBasedOnTextSize()
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


function ShopFunction.createIconButton(aPanel, iconIndex, upgradeLevel, isUpgBought)
	
	local upgIcons = Core.getTexture("Data/Images/icon_table.tga")
	local offset = Vec2( iconIndex%8*0.125, math.floor(iconIndex/8)*0.0625 )
							
	local iconImage = aPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)),upgIcons))
	iconImage:setUvCoord(offset,offset+Vec2(0.125,0.0625))
	iconImage:setImageScale(0.9)
	
	local panel = nil
	if upgradeLevel ~= 4 then 
		--add level icon to the button
		panel = iconImage:add(Image(PanelSize(Vec2(-1)),upgIcons))
		
		local levelOffset = Vec2(0.5+0.125*upgradeLevel,0.0625*5)
		panel:setUvCoord(levelOffset,levelOffset+Vec2(0.125,0.0625))
		panel:setImageScale(0.85)
		
	else
		panel = iconImage
	end
	
	local button = panel:add(Button(PanelSize(Vec2(-1), Vec2(1)),"",ButtonStyle.SQUARE))	
	
	if upgradeLevel==4 then
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
	
	button:setInnerColor(boderColor,boderColor,boderColor)
	button:setInnerHoverColor( isUpgBought and Vec4(1,1,1,0.1) or Vec4())
	button:setInnerDownColor( isUpgBought and Vec4(1,1,1,0.1) or Vec4(0,0,0,0.25))
		
	return button, iconImage	
end