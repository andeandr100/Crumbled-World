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
	local shopInfoLabel = nil
	local shopInfoGoldCost = nil
	local crystalCountLabel = nil
	local data = CampaignData.new()
	local language = Language() 
	local towers = { "Tower/MinigunTower.lua", "Tower/ArrowTower.lua", "Tower/SwarmTower.lua", "Tower/ElectricTower.lua", "Tower/BladeTower.lua", "Tower/missileTower.lua", "Tower/quakerTower.lua", "Tower/SupportTower.lua" }
	local towerUpgInfo = { ["Tower/MinigunTower.lua"]={
			range = {text="minigun tower range",[1]={["value1"]="5.75"},[2]={["value1"]="6.5"},[3]={["value1"]="7.25"}},
			overCharge = {text="minigun tower overcharge",[1]={["value1"]="40"},[2]={["value1"]="80"},[3]={["value1"]="120"}},
			fireCrit = {text="minigun tower firecrit",[1]={["value1"]="20"},[2]={["value1"]="40"},[3]={["value1"]="60"}}
		},
		["Tower/ArrowTower.lua"]={
			range = {text="Arrow tower range",[1]={["value1"]="10.5"},[2]={["value1"]="12"},[3]={["value1"]="13.5"}},
			hardArrow = {text="Arrow tower hardArrow",[1]={["value1"]="135",["value2"]="50"},[2]={["value1"]="240",["value2"]="60"},[3]={["value1"]="410",["value2"]="70"}},
			markOfDeath = {text="Arrow tower mark of death",[1]={["value1"]="8"},[2]={["value1"]="16"},[3]={["value1"]="24"}}
		},
		["Tower/SwarmTower.lua"]={
			range = {text="swarm tower range",[1]={["value1"]="7.25"},[2]={["value1"]="8"},[3]={["value1"]="8.75"}},
			burnDamage = {text="swarm tower damage",[1]={["value1"]="30"},[2]={["value1"]="60"},[3]={["value1"]="90"}},
			fuel = {text="swarm tower fire",[1]={["value1"]="22",["value2"]="15"},[2]={["value1"]="38",["value2"]="30"},[3]={["value1"]="52",["value2"]="45"}}
		},
		["Tower/ElectricTower.lua"]={
			range = {text="electric tower range",[1]={["value1"]="4.75"},[2]={["value1"]="5.5"},[3]={["value1"]="6.25"}},
			ampedSlow = {text="electric tower slow",[1]={["value1"]="15",["value2"]="0.75"},[2]={["value1"]="30",["value2"]="1.25"},[3]={["value1"]="45",["value2"]="1.75"}},
			energyPool = {text="electric tower energy pool",[1]={["value1"]="30"},[2]={["value1"]="60"},[3]={["value1"]="90"}},
			energy = {text="electric tower energy regen",[1]={["value1"]="15"},[2]={["value1"]="30"},[3]={["value1"]="45"}}
		},
		["Tower/BladeTower.lua"]={
			range = {text="Arrow tower range",[1]={["value1"]="10.5"},[2]={["value1"]="12"},[3]={["value1"]="13.5"}},
			attackSpeed = {text="blade tower attackSpeed",[1]={["value1"]="15"},[2]={["value1"]="30"},[3]={["value1"]="45"}},
			masterBlade = {text="blade tower firecrit",[1]={["value1"]="20"},[2]={["value1"]="40"},[3]={["value1"]="60"}},
			electricBlade = {text="blade tower slow",[1]={["value1"]="20"},[2]={["value1"]="36"},[3]={["value1"]="49"}},
			shieldBreaker = {text="blade tower shield"}
		},
		["Tower/missileTower.lua"]={
			range = {text="missile tower range",[1]={["value1"]="8"},[2]={["value1"]="9"},[3]={["value1"]="10"}},
			Blaster = {text="missile tower explosion",[1]={["value1"]="8"},[2]={["value1"]="16"},[3]={["value1"]="24"}},
			fuel = {text="missile tower fire",[1]={["value1"]="20",["value2"]="1"},[2]={["value1"]="22",["value2"]="1.75"},[3]={["value1"]="24",["value2"]="2.5"}},
			shieldSmasher = {text="missile tower shield destroyer"}
		},
		["Tower/quakerTower.lua"]={
			fireCrit = {text="quak tower firecrit",[1]={["value1"]="40"},[2]={["value1"]="80"},[3]={["value1"]="120"}},
			fireStrike = {text="quak tower fire",[1]={["value1"]="20",["value2"]="1"},[2]={["value1"]="22",["value2"]="1.75"},[3]={["value1"]="24",["value2"]="2.5"}},
			electricStrike = {text="quak tower electric",[1]={["value1"]="30",["value2"]="15"},[2]={["value1"]="60",["value2"]="28"},[3]={["value1"]="90",["value2"]="39"}},
			freeUpgrade = {text="free sub upgrade"}
		},
		["Tower/SupportTower.lua"]={
			range = {text="support tower range",[1]={["value1"]="10"},[2]={["value1"]="20"},[3]={["value1"]="30"}},
			damage = {text="support tower damage",[1]={["value1"]="10"},[2]={["value1"]="20"},[3]={["value1"]="30"}},
			weaken = {text="support tower weaken",[1]={["value1"]="10"},[2]={["value1"]="20"},[3]={["value1"]="30"}},
			gold = {text="support tower gold",[1]={["value1"]="1"},[2]={["value1"]="2"},[3]={["value1"]="3"}}
		},
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
	--
	--	Purpose: update all tooltips for all buttons
	--
	local function updateAllToolTips()
		--loop all towers
		for i=1, #towers do
			local towerName = towers[i]
			for k,v in pairs(textPanels[towerName]) do
				--avialabe upgrade
				if v["0"] then
					updateShopButtonToolTip(towerName,k,false)
				end
			end
		end
	end
	--
	--	Purpose: update a specific button and label
	--
	local function updateLabel(towerName,upgName)
		local unlocked = data.getBoughtUpg(towerName,upgName,false)
		local unlocksAvailable = data.getBuyablesTotal(upgName,false)
		if unlocked==unlocksAvailable then
			unlocked = unlocked + data.getBoughtUpg(towerName,upgName,true)
		end
		if upgName=="freeUpgrade" then
			textPanels[towerName][upgName]["0"].label:setText(tostring(unlocked).."/1")
		else
			textPanels[towerName][upgName]["0"].label:setText(tostring(unlocked).."/"..unlocksAvailable)
		end
		if towerName=="Tower/quakerTower.lua" then
			local permUnlockLeft = data.getBuyablesLimitForTower(towerName,true)-data.getTotalBuyablesBoughtForTower(towerName,true)
			if textPanels[towerName].buyable then
				local str = tostring(data.getTotalBuyablesBoughtForTower(towerName,false))
				if data.getTotalBuyablesBoughtForTower(towerName,true)>0 then
					str = str.."(+"..tostring(data.getTotalBuyablesBoughtForTower(towerName,true))..")"
				end
				str = str.."/"
				str = str..(data.getBuyablesLimitForTower(towerName,false))
				if permUnlockLeft>0 then
					str = str.."(+"..tostring(data.getBuyablesLimitForTower(towerName,true))..")"
				end
				textPanels[towerName].buyable:setText(str)
			end
			if data.getBoughtUpg(towerName,upgName,false)==3 and (towerName=="Tower/quakerTower.lua" and (upgName=="fireCrit" or upgName=="fireStrike" or upgName=="electricStrike")) then
				textPanels[towerName][upgName]["0"].button:setEnabled(false)
			end
			if permUnlockLeft<=0 and upgName=="freeUpgrade" then
				textPanels[towerName][upgName]["0"].button:setEnabled(false)
			end
		else
			--
			if textPanels[towerName].buyable then
				local permUnlockLeft = data.getBuyablesLimitForTower(towerName,true)-data.getTotalBuyablesBoughtForTower(towerName,true)
				local str = tostring(data.getTotalBuyablesBoughtForTower(towerName,false))
				if data.getTotalBuyablesBoughtForTower(towerName,true)>0 then
					str = str.."(+"..data.getTotalBuyablesBoughtForTower(towerName,true)..")"
				end
				str = str.."/"
				str = str..data.getBuyablesLimitForTower(towerName,false)
				if permUnlockLeft>0 then 
					str = str.."(+"..permUnlockLeft..")"
				end
				textPanels[towerName].buyable:setText(str)
			end
	
			if textPanels[towerName][upgName]["0"] then
				local permLeft = data.getBuyablesTotal(upgName,true)-data.getBoughtUpg(towerName,upgName,true)
				if data.getBoughtUpg(towerName,upgName,false)==3 and upgName=="overCharge" then
					textPanels[towerName][upgName]["0"].button:setEnabled(false)
				else
					textPanels[towerName][upgName]["0"].button:setEnabled(data.canBuyUnlock(towerName,upgName,false) or permLeft>0)
				end
			end
		end
	end
	--
	--	Purpose: update all labesl connected to all buttons
	--
	local function updateAllLabels()
		--loop all towers
		for i=1, #towers do
			local towerName = towers[i]
			local tPanels = textPanels
			--loop all upgrades
			for k,v in pairs(textPanels[towerName]) do
				--availabe upgrade
				if v["0"] then
					updateLabel(towerName,k,false)
				end
			end
		end
	end
	--
	--	Purpose: to unlock/permently buy an upgrade for a tower
	--
	local function shopButtonClicked(theButton)
		local towerName,upgName = string.match(theButton:getTag():toString(), "(.*);(.*)")
		local permUnlocked = data.getBoughtUpg(towerName,upgName,false)==data.getBuyablesTotal(upgName,false)
		
		--if add permenent upgrades, then remove existing permenent upgrades
		if permUnlocked and data.getTotalBuyablesBoughtForTower(towerName,true)>=1 then
			for k,v in pairs(towerUpgInfo[towerName]) do
				data.clear(towerName,k,true)
			end
		end
		
		--unlock upgrade
		data.buy(towerName,upgName,permUnlocked)
		
		--update labels
		updateAllLabels()
		updateAllToolTips()
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
	local function labelClicked(theLabel)
		local towerName,upgName,permUnlocked = string.match(theLabel:getTag():toString(),"(.*);(.*);(.*)")
		if tonumber(permUnlocked)>0.5 then
			data.clear(towerName,upgName,true)
			crystalCountLabel:setText(tostring(data.getCrystal()))
			--
			updateAllLabels()
			updateAllToolTips()
		end
	end
	local function lableMouseOver(theLabel)
		local towerName,upgName,permUnlocked = string.match(theLabel:getTag():toString(),"(.*);(.*);(.*)")
		if permUnlocked=="1" then
			theLabel:setTextColor(Vec3(1.0))
		end
	end
	local function lableMouseLost(theLabel)
		theLabel:setTextColor(Vec3(0.65))
	end
	local function addLabel(towerName,upgName,permUnlocked,label)
		local item = textPanels
		item[towerName] = item[towerName] or {}
		item = item[towerName]
		item[upgName] = item[upgName] or {}
		item = item[upgName]
		item[permUnlocked] = item[permUnlocked] or {}
		item[permUnlocked].label = label
		label:setTextColor(Vec3(0.65))
		if permUnlocked=="1" then
			label:addEventCallbackExecute(labelClicked)
			label:addEventCallbackMouseFocusGain(lableMouseOver)
			label:addEventCallbackMouseFocusLost(lableMouseLost)
			label:setTag(towerName..";"..upgName)
		end
	end
	local function addShopButton(panel,spacing,iconNumber,towerIndex,name)
		if iconNumber then
			--we have a button to place
			local upgIcons = Core.getTexture("Data/Images/icon_table.tga")
			local xStart = iconNumber%8*0.125
			local yStart = math.floor(iconNumber/8)*0.0625
			--
			local unlocked = data.getBoughtUpg(towers[towerIndex],name,false)
			local unlocksAvailable = data.getBuyablesTotal(name,false)
			-- make sure
			data.shouldExist(towers[towerIndex],name)
			-- info
			if spacing then
				panel:add(Panel(PanelSize(Vec2(-1,0.03),Vec2(0.25,1))))--spacing
			end
			addLabel(towers[towerIndex],name,"0",panel:add(Label(PanelSize(Vec2(-1,0.025),Vec2(1,1)), "-/-", Vec3(0.94))))
			-- button
			local button = panel:add(Button(PanelSize(Vec2(-1,0.03), Vec2(1,1)), ButtonStyle.SIMPLE, upgIcons, Vec2(xStart,yStart), Vec2(xStart+0.125,yStart+0.0625) ))
			textPanels[towers[towerIndex]][name]["0"].button = button
			button:setInnerColor(Vec4(0,0,0,0.15), Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
			button:setInnerHoverColor(Vec4(0,0,0,0), Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			button:setInnerDownColor(Vec4(0,0,0,0.3), Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
			
			button:setEdgeHoverColor(Vec4(1,1,1,1), Vec4(0.8,0.8,0.8,1))
			button:setEdgeDownColor(Vec4(0.8,0.8,0.8,1), Vec4(0.6,0.6,0.6,1))
			
			
			updateShopButtonToolTip(towers[towerIndex],name,false)
			
			button:setTag(towers[towerIndex]..";"..name)
			button:addEventCallbackExecute(shopButtonClicked)
			return button
		else
			if spacing then
				panel:add(Panel(PanelSize(Vec2(-1,0.03),Vec2(0.25,1))))--spacing
			end
			panel:add(Panel(PanelSize(Vec2(-1,0.025),Vec2(1,1))))--spacing
			panel:add(Panel(PanelSize(Vec2(-1,0.03), Vec2(1,1))))--spacing
		end
	end
	function addTowerButtons(towerIndex)
		
		local buttonPanel = shopPanel:add(Panel(PanelSize(Vec2(-1.0, 0.070), Vec2(7.5,1))))
		--buttonPanel:setBackground( Sprite( Vec4(1,0,0,0.5) ))--DEBUG coloring
		buttonPanel:setLayout(FlowLayout(PanelSize(Vec2(-1,-1))))
		--
		local towerTexture = Core.getTexture("icon_tower_table")
		local x = (towerIndex)%3
		local y = 2-math.floor(((towerIndex)/3))
		local start = Vec2(x/3.0, y/3.0)
					
		local button = buttonPanel:add(Button(PanelSize(Vec2(0.06,0.07), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, start, start+Vec2(1.0/3.0,1.0/3.0) ))
		--button:setBackground( Sprite( towerTexture ));
		button:setInnerColor(Vec4(0,0,0,0.15), Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
		button:setInnerHoverColor(Vec4(0,0,0,0), Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
		button:setInnerDownColor(Vec4(0,0,0,0.3), Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
		
		button:setEdgeHoverColor(Vec4(1,1,1,1), Vec4(0.8,0.8,0.8,1))
		button:setEdgeDownColor(Vec4(0.8,0.8,0.8,1), Vec4(0.6,0.6,0.6,1))
		--
		--Add BreakLine
		local upgradeAreaPanel = buttonPanel:add(Panel(PanelSize(Vec2(-1))))--add panel to the right of the Tower icon
		upgradeAreaPanel:add(Panel(PanelSize(Vec2(-1,0.02))))--add some top spacing
		--upgradeAreaPanel:setBackground( Sprite( Vec4(0,1,0,0.5) ))--DEBUG coloring(covers up the red area)
		--"Available unlocks"
		local upper = upgradeAreaPanel:add(Panel(PanelSize(Vec2(-1,0.030))))
		upper:add(Panel(PanelSize(Vec2(1,0.03),Vec2(0.25,1))))--spacing
		--upper:setBackground( Sprite( Vec4(0,0,1,0.5) ))--DEBUG coloring
		if towerIndex==1 then
			addShopButton(upper,false,59,towerIndex,"range")--range
			addShopButton(upper,true,63,towerIndex,"overCharge")--overCharge
			addShopButton(upper,true,36,towerIndex,"fireCrit")--fireCrit
			addShopButton(upper,true)--[Not Available]
			addShopButton(upper,true)--[Not Available]
		elseif towerIndex==2 then
			addShopButton(upper,false,59,towerIndex,"range")--range
			addShopButton(upper,true,54,towerIndex,"hardArrow")--hardArrow
			addShopButton(upper,true,61,towerIndex,"markOfDeath")--markOfDeath
			addShopButton(upper,true)--[Not Available]
			addShopButton(upper,true)--[Not Available]
		elseif towerIndex==3 then
			addShopButton(upper,false,59,towerIndex,"range")--range
			addShopButton(upper,true,2,towerIndex,"burnDamage")--burn
			addShopButton(upper,true,38,towerIndex,"fuel")--fuel
			addShopButton(upper,true)--[Not Available]
			addShopButton(upper,true)--[Not Available]
		elseif towerIndex==4 then
			addShopButton(upper,false,59,towerIndex,"range")--range
			addShopButton(upper,true,55,towerIndex,"ampedSlow")--slow
			addShopButton(upper,true,41,towerIndex,"energyPool")--energy
			addShopButton(upper,true,50,towerIndex,"energy")--energy
			addShopButton(upper,true)--[Not Available]
		elseif towerIndex==5 then
			addShopButton(upper,false,59,towerIndex,"range")--range
			addShopButton(upper,true,58,towerIndex,"attackSpeed")--attackSpeed
			addShopButton(upper,true,36,towerIndex,"masterBlade")--masterBlade
			addShopButton(upper,true,55,towerIndex,"electricBlade")--electricBlade
			addShopButton(upper,true,40,towerIndex,"shieldBreaker")--shieldBreaker
		elseif towerIndex==6 then
			addShopButton(upper,false,59,towerIndex,"range")--range
			addShopButton(upper,true,39,towerIndex,"Blaster")--damage
			addShopButton(upper,true,38,towerIndex,"fuel")--speed
			addShopButton(upper,true,42,towerIndex,"shieldSmasher")
			addShopButton(upper,true)--[Not Available]
		elseif towerIndex==7 then
			addShopButton(upper,false,36,towerIndex,"fireCrit")
			addShopButton(upper,true,38,towerIndex,"fireStrike")
			addShopButton(upper,true,50,towerIndex,"electricStrike")
			addShopButton(upper,true,53,towerIndex,"freeUpgrade")
			addShopButton(upper,true)--[Not Available]
		elseif towerIndex==8 then
			addShopButton(upper,false,65,towerIndex,"range")
			addShopButton(upper,true,64,towerIndex,"damage")
			addShopButton(upper,true,66,towerIndex,"weaken")
			addShopButton(upper,true,67,towerIndex,"gold")
			addShopButton(upper,true)--[Not Available]
		end
		upper:add(Panel(PanelSize(Vec2(-1,0.03),Vec2(1,1))))--spacing
		local str = tostring(data.getTotalBuyablesBoughtForTower(towers[towerIndex],false)).."/"..data.getBuyablesLimitForTower(towers[towerIndex],false).."(+1)"
		textPanels[towers[towerIndex]].buyable = upper:add(Label(PanelSize(Vec2(-1,0.025),Vec2(3.5,1)), str, Vec3(0.94)))
		--textPanels[towers[towerIndex]].buyable:setBackground( Sprite( Vec4(1,1,0,0.5) ))--DEBUG coloring
		local stuff = upper:add(Panel(PanelSize(Vec2(-1,0.03))))--line breaker
		--stuff:setBackground( Sprite( Vec4(0,1,1,0.5) ))--DEBUG coloring
		--
--		local breakLinePanel = shopPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
--		breakLinePanel:setBackground(Sprite(Vec3(0.45)))
	end
	
	function addShopArea()
		
		shopPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		
		local bottomShopPanel = shopPanel:add(Panel(PanelSize(Vec2(-0.9,-0.96))))
		bottomShopPanel:setLayout(FallLayout(Alignment.BOTTOM_LEFT, PanelSize(Vec2(0.004),Vec2(1))))
		
		--Info buy panel
		local InfoBuyPanel = bottomShopPanel:add(Panel(PanelSize(Vec2(-1, 0.11))))
		InfoBuyPanel:setLayout(FlowLayout(PanelSize(Vec2(0.004),Vec2(1))))
		
		--Info panel
		local infoPanel = InfoBuyPanel:add(Panel(PanelSize(Vec2(-0.7,-1))))
		infoPanel:setPadding(BorderSize(Vec4(0.005),true))
		infoPanel:setBorder(Border(BorderSize(Vec4(0.005),true), Vec4(Vec3(0.2),0.9)))
		shopInfoLabel = infoPanel:add(Label(PanelSize(Vec2(-1)), "<b>U</b>pgrade information\nText\nAnd another <b>row</b>", MainMenuStyle.textColor, Alignment.TOP_LEFT))
		shopInfoLabel:setPadding(BorderSize(Vec4(0.005), true))
		shopInfoLabel:setTextHeight(0.015)
		
		--Gold cost panel
		local pricePanel = InfoBuyPanel:add(Panel(PanelSize(Vec2(-1))))
		pricePanel:setLayout(FallLayout(Alignment.TOP_CENTER))
		shopInfoGoldCost = pricePanel:add(Label(PanelSize(Vec2(-1,-0.5),Vec2(2,1)), "0G", MainMenuStyle.textColor, Alignment.TOP_CENTER))
		shopInfoGoldCost:setBackground(Sprite(Vec4(0,0,0,0.7)))
		
		--unlock button
		pricePanel:add(Button(PanelSize(Vec2(-1), Vec2(4,1)), "Unlock"))
		
		
		--Upgrade panel area
		local uppgradePanel = bottomShopPanel:add(Panel(PanelSize(Vec2(-1,-1))))
		uppgradePanel:setLayout(GridLayout(6, 4, Alignment.TOP_CENTER))
		
		for i=0, 24 do
			uppgradePanel:add(Button(PanelSize(Vec2(-1),Vec2(1)),"X"))
		end
	end
	
	local function  closeClicked()
		self.setVisible( false )
		parentForm:setVisible( true )
	end
	
	function self.setParentForm(pForm)
		parentForm = pForm
	end
	local function init()
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
		
		form = Form(camera, PanelSize(Vec2(-0.9,-0.8), Vec2(3.5,4)), Alignment.MIDDLE_CENTER);
		form:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(panelSpacingVec2)));
		form:setRenderLevel(9)	
		form:setVisible(false)
		
		shopPanel = form:add(Panel(PanelSize(Vec2(-1))))
		
		shopPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, Vec4(0,0,0,0.5)))
		--shopPanel:setBackground( Sprite(Vec4(1,1,1,0.5)) )--DEBUG coloring
		shopPanel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)),MainMenuStyle.borderColor))
		
		--Add the title
		addTitle()
		
		--Add all diffrent towers
		for i=1, #towers do
			addTowerButtons(i)
		end
		--fixe crystal limits
		data.fixCrystalLimits()
		--Update all information
		updateAllLabels()
		updateAllToolTips()
		
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
--		if shopPanel:getVisible() and Core.getInput():getMouseDown(MouseKey.left) then
--		
--			local panel = Form.getPanelFromGlobalPos(Core.getInput():getMousePos())
--			local mouseInsideShopPanel = false
--			while panel and not mouseInsideShopPanel do
--				panel = panel:getParent()
--				if panel == shopPanel then
--					mouseInsideShopPanel = true
--				end
--			end
--			
--			if not mouseInsideShopPanel then
--				shopPanel:setVisible( false )
--			end
--			
--		end
	end
		
	return self
end