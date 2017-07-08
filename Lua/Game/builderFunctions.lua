require("Game/targetArea.lua")
require("Game/campaignTowerUpg.lua")

--this = BuildNode()

BuilderFunctions = {}
function BuilderFunctions.new(keyBinds, inCamera)
	local self = {}
	local keyRotationLocked = keyBinds:getKeyBind("Locked rotation")
	local previousTower = nil
	local camera = inCamera
	local billboardStats = Core.getBillboard("stats")
	--init target area
	local targetArea = TargetArea.new()
	
	function self.hiddeTargetMesh()
		targetArea.hiddeTargetMesh()	
	end
	
	function self.renderTargetArea(targetAreaName, towerMatrix, towerBilboard)
		
		if towerMatrix and (targetAreaName == "sphere" or targetAreaName == "capsule" or targetAreaName =="cone") then
			
			local targetMatrix = towerMatrix
			local numRangeUpgrades = (CampaignTowerUpg.new(towerBilboard:getString("FileName"),nil).isPermUpgraded("range",1) and 2 or 3)
			--print("bilboard: "..towerBilboard:toString())
			if targetAreaName == "sphere" then	
				local addedRange = towerBilboard:getFloat("rangePerUpgrade")
				numRangeUpgrades = (towerBilboard:getString("Name") == "Quake tower") and 0 or numRangeUpgrades
				targetArea.setExtraRangeInfo( numRanges, {addedRange,addedRange,addedRange}, {Vec4(0,0,0,0.45),Vec4(0,0,0,0.45),Vec4(0,0,0,0.45)} )
				targetArea.changeModel("sphere", towerBilboard:getFloat("range"), 0, targetMatrix)
			elseif targetAreaName == "capsule" then
				local addedRange = towerBilboard:getFloat("rangePerUpgrade")
				targetArea.setExtraRangeInfo( numRangeUpgrades, {addedRange,addedRange,addedRange}, {Vec4(0,0,0,0.45),Vec4(0,0,0,0.45),Vec4(0,0,0,0.45)} )
				targetArea.changeModel("capsule", towerBilboard:getFloat("range"), 0, targetMatrix)
			elseif targetAreaName == "cone" then
				local addedRange = towerBilboard:getFloat("rangePerUpgrade")
				targetArea.setExtraRangeInfo( numRangeUpgrades, {addedRange,addedRange,addedRange}, {Vec4(0,0,0,0.45),Vec4(0,0,0,0.45),Vec4(0,0,0,0.45)} )
				targetArea.changeModel("sphere", towerBilboard:getFloat("range"), towerBilboard:getFloat("targetAngle"), targetMatrix)--coneSphere				
			else
				targetArea.hiddeTargetMesh()
			end
		else
			targetArea.hiddeTargetMesh()
		end
	end
	
	function self.updateBuildingRotation(rotation)
		local mouseWheelTickes = Core.getInput():getKeyHeld(Key.lshift) and 0 or Core.getInput():getMouseWheelTicks()
		
		if keyRotationLocked and keyRotationLocked:getHeld() and mouseWheelTickes ~= 0 then
			print("mouseWheelTickes: "..mouseWheelTickes.."\n")
			
			local stepSize = math.pi * 0.25;
			print("stepSize: "..stepSize.."\n")
			local diff = rotation - math.floor(rotation / stepSize) * stepSize;
			print("diff: "..diff.."\n")
			if math.abs(diff) > 0.01 then
				
				if mouseWheelTickes > 0 then
					rotation = math.ceil(rotation / stepSize) * stepSize;
				else
					rotation = math.floor(rotation / stepSize) * stepSize;
				end
				
		
				if math.abs( diff ) > stepSize * 0.1 then
					rotationTime = Core.getGameTime()
				end
			end
			
			if Core.getGameTime() - rotationTime > 0.1 then
				if mouseWheelTickes > 0 then
					rotation = rotation + stepSize
					print("mouseWheelTickes > 0\n")
				else
					print("mouseWheelTickes < 0\n")
					rotation = rotation - stepSize
				end
				rotationTime = Core.getGameTime()
			end
		
		else
			if mouseWheelTickes > 0 then
				rotation = rotation + math.pi / 48;
			elseif mouseWheelTickes < 0 then
				rotation = rotation - math.pi / 48;
			end
			rotation = (rotation > 2 * math.pi) and rotation - 2 * math.pi or rotation
			rotation = (rotation < 0) and rotation + 2 * math.pi or rotation
		end
		return rotation
	end
	
	
	
	function self.updateSelectedTower(currentTower)
		local mouseInGamePanel = billboardStats:getPanel("MainPanel") == Core.getPanelWithMouseFocus()
		local canBuildAndSelect = buildingBillboard:getBool("canBuildAndSelect")
		local mouseTower = (not currentTower and mouseInGamePanel and canBuildAndSelect) and this:getBuldingFromLine(camera:getWorldLineFromScreen(Core.getInput():getMousePos())) or nil
		if previousTower ~= mouseTower then
			if previousTower then
				local meshList = previousTower:findAllNodeByTypeTowardsLeaf({NodeId.mesh, NodeId.animatedMesh, NodeId.nodeMesh})
				for i=1, #meshList do
					local shader = meshList[i]:getShader()
					if shader then
						local definitions = shader:getDefinitions()
						for i=1, #definitions do
							if definitions[i] == "SELECTED" then
								table.remove(definitions, i)
							end
						end
						
						local newShader = Core.getShader(shader:getName(), definitions)
						--print("New shader fullName: "..newShader:getFullName().."\n")
						if newShader then
							meshList[i]:setShader(newShader)			
						end
					end
				end
				previousTower = nil
			end
			
			if mouseTower then
				local meshList = mouseTower:findAllNodeByTypeTowardsLeaf({NodeId.mesh, NodeId.animatedMesh, NodeId.nodeMesh})
				for i=1, #meshList do
					local shader = meshList[i]:getShader()
					if shader then
						local definitions = shader:getDefinitions()
						definitions[#definitions+1] = "SELECTED"
						local newShader = Core.getShader(shader:getName(),definitions)
						--print("New shader fullName: "..newShader:getFullName().."\n")
						if newShader then
							meshList[i]:setShader(newShader)			
						end
					end
				end
				previousTower = mouseTower
			end
		end		
	end
	
	function self.changeColor( tower, color )
		if tower then
			local meshList = tower:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
			for i = 1, #meshList, 1 do
				meshList[i]:setColor(color)
			end
		end
	end
	
	return self
end