require("Menu/MainMenu/mapInformation.lua")
require("Menu/Campaign/FreeFormDesign.lua")

--this = SceneNode()
CampaignMapDesign = {}
function CampaignMapDesign.new(parentPanel)
	local self = {}
	
	
	local gameValues = FreeFormDesign.gameValues
	local campaignMapData = {}
	local reloadImages = {}
	local campaignPanel
	local changeMapFunction
	local yPos = -0.2
	local yDiff = -0.28
	local rowInfo = {}
	
	local function addCampaignData(position,fileName)
	
		local playedAndWon, unlocked = gameValues.getMapStatus(fileName)
	
		local filePath = "Data/Map/Campaign/" .. fileName .. ".map"
	
		local mapFile = File(filePath)
		local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
		local imageName = mapInfo and mapInfo.icon or "noImage"
		local texture = Core.getTexture(imageName and imageName or "noImage")
	
		campaignMapData[#campaignMapData+1] = {position=position,unlocked=unlocked,texture=texture,playedAndWon=playedAndWon,connections={},filePath=filePath,fileName=fileName}
		return #campaignMapData;
	end
	
	local function addConnection(startMap, connections)
		campaignMapData[startMap].connections = connections
	end
	

	
	
	local function addButton(mapData)

		local buttonDesign = FreeFormDesign.getMapButton(mapData.playedAndWon, mapData.unlocked)
		local button = FreeFormButton(mapData.position, buttonDesign, Core.getTexture("noImage"), Vec2(), Vec2(1) )
		button:getImage():setShader(Core.getShader("a2DWorldIcon"))

		if mapData.unlocked then
			button:getImage():setTexture(mapData.texture)
			if mapData.texture:getName():toString() == Core.getTexture("noImage"):getName():toString() then
				reloadImages[#reloadImages+1] = {button=button, filePath=mapData.filePath}
			end
		else
			button:getImage():setColor(Vec4(0.4,0.4,0.4,1))
		end
		
		button:setEnabled( mapData.unlocked )
		button:setTag( mapData.filePath )
		button:addEventCallbackExecute(changeMapFunction)
		campaignPanel:add( button )
	end
	
	local function addMaps(map1, map2, map3, map4)
		local rowData = {}
		if map2 == nil then
			rowData = { addCampaignData(Vec2(-0.5, yPos),map1) }
			
		elseif map3 == nil then
			rowData = { addCampaignData(Vec2(-0.25, yPos),map1),
						addCampaignData(Vec2(-0.75, yPos),map2) }
		elseif map4 == nil then
			rowData = { addCampaignData(Vec2(-0.2, yPos),map1),
						addCampaignData(Vec2(-0.5, yPos),map2),
						addCampaignData(Vec2(-0.8, yPos),map3) }
		else
			rowData = { addCampaignData(Vec2(-0.15, yPos),map1),
						addCampaignData(Vec2(-0.15 - (0.7/3), yPos),map2),
						addCampaignData(Vec2(-0.15 - (0.7/3) * 2, yPos),map3),
						addCampaignData(Vec2(-0.85, yPos),map4) }
		end
		rowInfo[#rowInfo+1] = rowData
	
		yPos = yPos + yDiff
	end
	
	local function addConnections()
		for n=1, #rowInfo-1 do
			local firstRow = rowInfo[n]
			local nextrow = rowInfo[n+1]
			
			if #firstRow == 1 then
				addConnection(firstRow[1], nextrow)
			else
				for i=1, #firstRow do
					if #nextrow == 1 then
						addConnection(firstRow[i], {nextrow[1]})
					elseif #firstRow == #nextrow then
						addConnection(firstRow[i], {nextrow[i]})
					elseif (#firstRow+1) == #nextrow then
						addConnection(firstRow[i], {nextrow[i],nextrow[i+1]})
					elseif #firstRow == 2 and #nextrow == 4 then
						addConnection(firstRow[i], {nextrow[(i-1)*2+1],nextrow[(i-1)*2+2]})
					elseif (#firstRow-1) == #nextrow then
						if i==1 then
							addConnection(firstRow[i], {nextrow[1]})
						elseif i==#firstRow then
							addConnection(firstRow[i], {nextrow[#nextrow]})
						else
							addConnection(firstRow[i], {nextrow[i-1],nextrow[i]})
						end
					elseif #firstRow == 4 and #nextrow == 2 then
						addConnection(firstRow[i], {nextrow[i<3 and 1 or 2]})
					end
				end
			end
		end
	end
	
	local function updateUnlocked(mapIndex)
		if campaignMapData[mapIndex].unlocked == true then
			return
		end
	
		for index=1, mapIndex do
			for n=1, #campaignMapData[index].connections do
				if campaignMapData[index].connections[n] == mapIndex then
					if campaignMapData[index].playedAndWon then
						gameValues.setMapUnLockedStatus(campaignMapData[mapIndex].fileName, true)
						campaignMapData[mapIndex].unlocked = true
					end
				end
			end
		end
	end
	
	local function addMapsPanel()

		campaignPanel:setLayout(FreeFormLayout(PanelSize(Vec2(-1))))
		campaignPanel:setEnableScroll()
		
		local lines = FreeFormLine()
		campaignPanel:add(lines)
		
		gameValues.setMapUnLockedStatus("Beginning", true)
		
		addMaps("Beginning")
		addMaps("Intrusion")
		addMaps("Stockpile", "Expansion")
		addMaps("Repair station", "Edge world", "Bridges")
		addMaps("Spiral", "Broken mine", "Town","Centeral")
		addMaps("Outpost", "Plaza")
		addMaps("Long haul", "Dock", "Lodge")
		addMaps("Crossroad", "Mine", "West river")
		addMaps("Blocked path", "The line")
		addMaps("Dump station", "Rifted", "Paths","Divided")
		addMaps("Nature", "Train station", "Desperado")
		addMaps("The end")
		
		addConnections()
				
		gameValues.saveConfig()

		


		local color2 = Vec3(253.0, 249.0, 220.0) / 255.0
		local color1 = Vec3(137.0,86.0,4.0) / 255.0
		
		local color1Locked = Vec3(65.0,65.0,65.0) / 255.0;
		local color2Locked = Vec3(230.0,230.0,230.0) / 255.0
		

		for index=1, #campaignMapData do
			
			updateUnlocked(index)
			local mapData = campaignMapData[index]
			addButton(mapData)
				
			for i=1, #mapData.connections do
				if mapData.playedAndWon then
					lines:addLine(mapData.position, campaignMapData[mapData.connections[i]].position, 6, color1, color2, color1)
				else
					local colorScale = mapData.unlocked == false and 0.5 or 1.0
					lines:addLine(mapData.position, campaignMapData[mapData.connections[i]].position, 6, color1Locked * colorScale, color2Locked * colorScale, color1Locked * colorScale)
				end
			end
			
		end
			
	
	end
	
	function self.mapInfoLoaded()
		
		for n=1, #reloadImages do
		
			local mapFile = File(reloadImages[n].filePath)
			local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())

			if mapInfo then
				reloadImages[n].button:getImage():setTexture(Core.getTexture(mapInfo.icon))

				--Remove the reload images testing
				reloadImages[n] = reloadImages[#reloadImages]
				n = n - 1
			end
		end
	end
	
	function self.fillMapPanel(panel, changeMapFunc)
		changeMapFunction = changeMapFunc
		campaignPanel = panel
		
		addMapsPanel()
	end
	
	return self
end