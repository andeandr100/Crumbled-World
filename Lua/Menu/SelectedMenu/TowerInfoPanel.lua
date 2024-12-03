require("Game/gameValues.lua")

--buildingBillBoard = Billboard()
--buildingNodeBillboard = Billboard()
--senToBuildNode = Function()
--this = SceneNode()

TowerInfoPanel = {}
function TowerInfoPanel.new(inParentPanel)
	local self = {}
	local parentPanel = inParentPanel
	local statsOrder =  {"damage", "dmg","RPS", "ERPS","range", "slow","bladeSpeed", "fireDPS","burnTime","dmg_range","supportDamage","SupportRange","supportWeaken","weakenValue","supportGold","supportGoldPerWave"}
	local gameValues = GameValues.new()
	local towerUpdateIndex = -1
	
	local towerInfo = nil
	local infoPanel
	
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
	
	function self.clearInfo()
		towerInfo = nil
		towerUpdateIndex = -1
	end
	
	function self.clear()
		infoPanel:clear()
	end
	
	function self.updateText(clearInfo)
		
		--check if the stats need to be reloaded
		if towerUpdateIndex ~= buildingBillBoard:getInt("updateIndex") then
			towerUpdateIndex = buildingBillBoard:getInt("updateIndex")
			--print("\n\nupdateText()\n")
			local displayStats = buildingBillBoard:getTable("displayStats")
			
			if towerInfo then
				local info = towerInfo
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
				towerInfo = {}
				local info = towerInfo
				
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
						local minCoord, maxCoord, text = gameValues.getUvCoordAndTextFromName(name)
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

	local function init()
		local infoPanelMain = parentPanel:add(Panel(PanelSize(Vec2(-1))))
		infoPanel = infoPanelMain:add(Panel(PanelSize(Vec2(-1,-1))))
		infoPanel:setLayout(GridLayout(5,1))
	end
	
	
	init()
	
	return self
end