--DamageInfoPamel 

--buildingNodeBillboard = Billboard()
--senToBuildNode = Function()
--this = SceneNode()

DamageInfoPanel = {}
function DamageInfoPanel.new(inParentPanel)
	local self = {}
	local parentPanel = inParentPanel
	local damageInfoBar
	local language = Language()
	local buildingBillBoard
	
	function self.setBuildingBillBoard( inBuildingBillBoard ) 
		buildingBillBoard = inBuildingBillBoard
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
	
	local function getDamageToolTipText()
		local totalDamage, maxDamage = getAllDamageFromTowers()
		local damage = buildingBillBoard:getDouble("DamagePreviousWave")
		local totalCost = buildingBillBoard:getDouble("totalCost")
		local damageToolTip = Text(tostring(math.round(damage/totalCost)).." ") + language:getText("# damage per gold") + Text("\n")
		damageToolTip = damageToolTip + Text(tostring(math.round(damage)).." ") + language:getText("# damage delt to enemies") 
		local passivDamageTextAdded = false
		if buildingBillBoard:exist("DamagePreviousWavePassive") then
			local passivDamage = buildingBillBoard:getDouble("DamagePreviousWavePassive")
			if passivDamage > 1 then
				if damage < 1 then
					damageToolTip = Text("")
				else
					damageToolTip = damageToolTip + Text("\n")
				end
				
				passivDamageTextAdded = true
				damageToolTip = damageToolTip + Text(tostring(math.round(passivDamage/totalCost)).." ") + language:getText("# damage per gold") + Text("\n")
				damageToolTip = damageToolTip + Text(tostring(math.round(passivDamage)).." ") + language:getText("# damage delt to enemies") 
			end
		end
		
		if buildingBillBoard:exist("goldEarned") then
			local goldEarned = math.round(buildingBillBoard:getDouble("goldEarned"))
			local goldEarnedPreviousWave = math.round(buildingBillBoard:getDouble("goldEarnedPreviousWave"))
			if goldEarned > 1 then
				if damage < 1 and not passivDamageTextAdded then
					damageToolTip = Text("")
				else
					damageToolTip = damageToolTip + Text("\n")
				end
				
				damageToolTip = damageToolTip + Text(tostring(goldEarned).." ") + language:getText("# gold earned") + Text("\n")
				damageToolTip = damageToolTip + Text(tostring(goldEarnedPreviousWave).." ") + language:getText("# gold earned previous wave") 
			end
		end
		return damageToolTip
	end
	
	function self.updateTowerDamageInfo()
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
		damageInfoBar:setValue(damageValues)
		damageInfoBar:setToolTip( damageToolTip )
		damageInfoBar:setText( tostring((math.round((damage / maxDamage)*1000)/10)).."%" )
		damageInfoBar:setInnerColor(Vec4(Vec3(0), 1), Vec4(Vec3(0), 1))
		damageInfoBar:setColor({Vec4(0.5*0.7, 1.1*0.7, 0.5*0.7, 0.75), Vec4(0.0, 0.65*0.7, 0.0, 0.75), Vec4(1.1*0.7, 0.5*0.7, 0.3*0.7, 0.75), Vec4(1.1*0.4, 0.5*0.4, 0.0, 0.75), Vec4(0.94, 0.94, 0.61, 0.75), Vec4(0.61, 0.61, 0.4, 0.75)})
	end
	
	local function init()
		parentPanel:add(Panel(PanelSize(Vec2(-1),Vec2(16,1))))
		damageInfoBar = parentPanel:add(ProgressBar(PanelSize(Vec2(-1),Vec2(9,1)), Text(""), 0))
	end
	
	
	init()
	
	return self
end