require("Menu/MainMenu/mainMenuStyle.lua")
require("Game/mapInfo.lua")
require("Menu/MainMenu/mapInformation.lua")
require("Game/campaignData.lua")
require("Menu/Campaign/shop.lua")
require("Menu/MainMenu/settingsCombobox.lua")
require("Game/scoreCalculater.lua")
--this = SceneNode()

CampaignGameMenu = {}
function CampaignGameMenu.new(panel)
	local self = {}
	local levelInfo = MapInfo.new()
	local campaignData = CampaignData.new()
	local files = campaignData.getMaps()
	local selectedButton
	local selectedFile
	--GUI
	local form = panel
	local windowShop
	local mapLabel
	local iconImage
--	local difficutyBox
	local firstMapButton
	local gameModeBox
	local mainPanel
	local rewardLabel
	local campaignPanel
	local campaignMapData = {}
	--Game modes
	local gameModes = levelInfo.getGameModesSinglePlayer()
	local optionsTooltip = {"default tooltip", "survival tooltip", "rush tooltip", "training tooltip", "leveler tooltip"}
	--Select
	local menuPrevSelect	--menuPrevSelect=Config()
	--
	local campaignList = {}
	local diffNames = {}
	local labels = {}
	
	local selectedMapPath = ""
	
	function self.languageChanged()
--		for i=1, #labels do
--			labels[i]:setText(language:getText(labels[i]:getTag()))
--		end
--		gameModeBox.updateLanguage()
--		difficutyBox.updateLanguage()
	end

	local function setDefaultButtonColor(button)
		local mNum = tonumber(string.match(button:getTag():toString(),"(.*):"))
		if mNum%2 == 0 then
			if campaignData.isMapAvailable(mNum)>0 then
				button:setEdgeColor(Vec4(1,1,1,0.05), Vec4(1,1,1,0.05))
				button:setInnerColor(Vec4(1,1,1,0.05), Vec4(1,1,1,0.05), Vec4(1,1,1,0.05))
			else
				button:setEdgeColor(Vec4(1,1,1,0.2), Vec4(1,1,1,0.2))
				button:setInnerColor(Vec4(1,1,1,0.2), Vec4(1,1,1,0.2), Vec4(1,1,1,0.2))
			end
		else
			button:setEdgeColor(Vec4(0), Vec4(0))
			button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
		end
	end
	local function updateRewardInfo()
		if rewardLabel then	
			if gameModeBox.getIndexText()~="survival" then
				rewardLabel:setText( tostring(levelInfo.getReward()) )
			else
				rewardLabel:setText( "1/10W" )
			end
		end
	end
	local function setSelectedButtonColor(button)
		local mNum = tonumber(string.match(button:getTag():toString(),"(.*):"))
		if campaignData.isMapAvailable(mNum)>0 then
			selectedButton = button
			button:setEdgeColor(Vec4(1,1,1,0.25), Vec4(1,1,1,0.25))
			button:setInnerColor(Vec4(1,1,1,0.25), Vec4(1,1,1,0.25), Vec4(1,1,1,0.25))
		end
		updateRewardInfo()
	end
	local function highScoreCallback(highScoreTable)
		scoreArea:clear()
		print("highScoreTable type: "..type(highScoreTable))
		print("table: "..tostring(highScoreTable))
		if type(highScoreTable) == "table" then
			local labelColor = Vec4(0.9,0.9,0.9,1.0)
			for i=1, math.min(9,#highScoreTable) do
				print("add row: "..highScoreTable[i].name..", "..tostring(highScoreTable[i].score))
				local row = scoreArea:add(Panel(PanelSize(Vec2(-1))))
				row:add(Label(PanelSize(Vec2(-0.65,-1)), highScoreTable[i].name, labelColor))
				row:add(Label(PanelSize(Vec2(-0.5,-1)), tostring(highScoreTable[i].score), labelColor))
				local icon = Image(PanelSize(Vec2(-1), Vec2(2,1)), Text("icon_table.tga") )
				local scoreItem = ScoreCalculater.getScoreItemOnScore(highScoreTable[i].score)
				icon:setUvCoord(scoreItem.minPos,scoreItem.maxPos)
				row:add(icon)
			end
		end
	end
	
	local function updateHighScorePanel()
		if mainPanel:getVisible() then 
			scoreArea:clear()
			Core.getHighScore():getHighScoreList(levelInfo.getMapName(),1 ,levelInfo.getGameMode(), highScoreCallback)
		end
	end
	
	local function updateIcons()
		local scoreLimits = ScoreCalculater.getScoreLimits()
		for i=1, #files do
			if campaignData.isMapAvailable(i)>0 then
				if campaignData.hasMapBeenBeaten(i) then
					local level = math.clamp(campaignData.getMapModeBeatenLevel(i,levelInfo.getGameMode()),1,#scoreLimits)
					campaignList[i].icon:setUvCoord(scoreLimits[level].minPos,scoreLimits[level].maxPos)
				else
					campaignList[i].icon:setUvCoord(Vec2(0.0,0.0),Vec2(0.0,0.0))--no icon
				end
			else
				campaignList[i].icon:setUvCoord(Vec2(0.5,0.0),Vec2(0.625,0.0625))--locked icon
			end
		end
		if gameModeBox then
			if gameModeBox.getIndexText()=="survival" then
				for i=1, #files do
					campaignList[i].waveLabel:setText("100")
				end
			else
				for i=1, #files do
					campaignList[i].waveLabel:setText(tostring(files[i].waveCount))
				end
			end
		end
	end
--	local function changeDifficulty(tag, index)
--		if difficutyBox.isEnabled()==true then
--			levelInfo.setLevel(1)
--			--
--			menuPrevSelect:get("campaign"):get("selectedDifficulty"):setInt(index)
--			--
--			updateIcons()
--			updateRewardInfo()
--			--
--			difficutyBox.setIndex(index)
--			updateHighScorePanel()
--		end
--	end
--	local function fillDificulty(levels,currentLevel)
--		diffNames = {"easy", "normal", "hard", "extreme", "insane"}
--		for i=#diffNames+1, levels do
--			diffNames[#diffNames + 1] = language:getText("impossible") + " " + tostring(i-5)
--		end
--		difficutyBox.setItems(diffNames)
--		difficutyBox.setIndex(currentLevel)
--	end
	local function getMapIndex(filePath)
		for i=1, #files do	
			local file = files[i].file
			if file:isFile() and file:getPath()==filePath then
				return i
			end
		end
		return 0
	end
--	local function fillDificulty()
--		local levels = math.max(5,campaignData.getMapModeBeatenLevel(levelInfo.getMapNumber(),levelInfo.getGameMode())+1)
--		local currentLevel = math.min(levels,levelInfo.getLevel())
--		levelInfo.setLevel(1)--the difficulty may have been lowered
--		--reset list to default
--		diffNames = {"easy", "normal", "hard", "extreme", "insane"}
--		--insert the new dynamic levels
--		for i=#diffNames+1, levels do
--			diffNames[#diffNames + 1] = language:getText("imposible") + " " + tostring(i-5)
--		end
--		--add it to the controller
--		difficutyBox.setItems(diffNames)
--		difficutyBox.setIndex(currentLevel)
--	end
	local function changeMapTo(mNum, filePath, mapFile)
		
		if mNum<1 or not mapFile:isFile() then
			return false
		end
		
		levelInfo.setMapNumber(mNum)
		levelInfo.setMapName(mapFile:getName())
		levelInfo.setSead(files[mNum].sead)
		--set current active map
		selectedFile = filePath
		--update GUI
		mapLabel:setText( mapFile:getName() )
		local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
		local imageName = mapInfo and mapInfo.icon or nil
		local texture = Core.getTexture(imageName and imageName or "noImage")
		if mapInfo then
			levelInfo.setIsCartMap(mapInfo.gameMode=="Cart")
			levelInfo.setIsCircleMap(mapInfo.gameMode=="Circle")
			levelInfo.setIsCrystalMap(mapInfo.gameMode=="Crystal")
			levelInfo.setAddPerLevel(mapInfo.difficultyIncreaseMax)
			levelInfo.setDifficultyBase(mapInfo.difficultyBase)
			levelInfo.setWaveCount(mapInfo.waveCount)
								levelInfo.setMapSize(mapInfo.mapSize)
			levelInfo.setLevel(1)
			--changing default selected map
			menuPrevSelect:get("campaign"):get("selectedMap"):setString(filePath)
		end
		
		iconImage:setTexture(texture)

		--Update hihgscore after map information is set
		updateHighScorePanel()

		return true
	end
	
	local function customeGameChangedMap(button)
		if type(button)=="userdata" then
			local filePath = button:getTag():toString()
			
			--mNum = tonumber(mNum)
			
			selectedMapPath = filePath
			local mNum = getMapIndex(filePath)
			if mNum>=1 then
				local mapFile = File(filePath)
				if mapFile:isFile() then
					changeMapTo(mNum,filePath,mapFile)
				end
			end
		end
	end
	local function setLabelListItemColor(label,available)
		if available>0 then
			label:setTextColor(Vec4(0.7,0.7,0.7,1.0))
		else
			label:setTextColor(Vec4(0.5))
		end
	end

	
	local function addButton(mapData)

		local innerRingColorTop = mapData.playedAndWon and Vec3(137.0,86.0,4.0) / 255.0 or Vec3(230.0,230.0,230.0) / 255.0
		local innerRingColorBottom = mapData.playedAndWon and Vec3(253.0, 249.0, 220.0) / 255.0 or Vec3(65.0,65.0,65.0) / 255.0
		local outerRingColorTop = mapData.playedAndWon and Vec3(253.0, 244.0, 201.0) / 255.0 or Vec3(160.0,160.0,160.0) / 255.0
		local outerRingColorBottom = mapData.playedAndWon and Vec3(138.0, 86.0, 2.0) / 255.0 or Vec3(240.0,240.0,240.0) / 255.0
		
	
		local button = FreeFormButton(mapData.position, -0.09, -0.01, mapData.texture)
		button:setColor(innerRingColorTop, innerRingColorBottom, outerRingColorTop, outerRingColorBottom)
		button:setEnabled( mapData.unlocked )
		button:setTag( mapData.filePath )
		button:addEventCallbackExecute(customeGameChangedMap)
		campaignPanel:add( button )
	end
	
	local function addCampaignData(position,fileName,unlocked, playedAndWon)
	
		local filePath = "Data/Map/Campaign/" .. fileName .. ".map"
	
		local mapFile = File(filePath)
		local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
		local imageName = mapInfo and mapInfo.icon or "noImage"
		local texture = Core.getTexture(imageName and imageName or "noImage")
	
		campaignMapData[#campaignMapData+1] = {position=position,unlocked=unlocked,texture=imageName,playedAndWon=playedAndWon,connections={},filePath=filePath}
		return #campaignMapData;
	end
	
	local function addConnections(startMap, connections)
		campaignMapData[startMap].connections = connections
	end
	

	
	local function addMapsPanel(panel)
		local mapFolder = Core.getDataFolder("Map")
		
		local bgTexture = Core.getTexture("tmpImage.jpg")
		local background = Sprite(bgTexture,Vec2(0.25,0.0), Vec2(0.75,1.0))
		
		campaignPanel = panel:add(Panel(PanelSize(Vec2(-0.75, -1))))
--		campaignPanel:setBackground(background)


		campaignPanel:add(FreeFormSprite(Vec2(),Vec2(-1,-2),"SB1_RB",Vec2(),Vec2(1,3)))	
		
		campaignPanel:setLayout(FreeFormLayout(PanelSize(Vec2(-1))))
		campaignPanel:setEnableScroll()
		
		local lines = FreeFormLine()
		campaignPanel:add(lines)
		
		
		local yPos = -0.2
		local yDiff = -0.25
		local map1 = addCampaignData(Vec2(-0.5, yPos),"Beginning",true, true)
		yPos = yPos + yDiff
		
		local map2 = addCampaignData(Vec2(-0.5, yPos),"Intrusion",true, true)
		yPos = yPos + yDiff
		
		local map3 = addCampaignData(Vec2(-0.25, yPos),"Stockpile",true, true)
		local map4 = addCampaignData(Vec2(-0.75, yPos),"Expansion",true, true)
		yPos = yPos + yDiff
		
		local map5 = addCampaignData(Vec2(-0.2, yPos),"Repair station",true, true)
		local map6 = addCampaignData(Vec2(-0.5, yPos),"Edge world",true, false)
		local map7 = addCampaignData(Vec2(-0.8, yPos),"Bridges",true, false)
		yPos = yPos + yDiff
		
		local map8 = addCampaignData(Vec2(-0.15, yPos),"Spiral",true, false)
		local map9 = addCampaignData(Vec2(-0.15 - (0.7/3), yPos),"Broken mine",true, false)
		local map10 = addCampaignData(Vec2(-0.15 - (0.7/3) * 2, yPos),"Town",false, false)
		local map11 = addCampaignData(Vec2(-0.85, yPos),"Centeral",false, false)
		yPos = yPos + yDiff
		
		local map12 = addCampaignData(Vec2(-0.25, yPos),"Outpost",false, false)
		local map13 = addCampaignData(Vec2(-0.75, yPos),"Plaza",false, false)
		yPos = yPos + yDiff
		
		local map14 = addCampaignData(Vec2(-0.2, yPos),"Long haul",false, true)
		local map15 = addCampaignData(Vec2(-0.5, yPos),"Dock",false, false)
		local map16 = addCampaignData(Vec2(-0.8, yPos),"Lodge",false, false)
		yPos = yPos + yDiff
		
		local map17 = addCampaignData(Vec2(-0.2, yPos),"Crossroad",false, false)
		local map18 = addCampaignData(Vec2(-0.5, yPos),"Mine",false, false)
		local map19 = addCampaignData(Vec2(-0.8, yPos),"West river",false, false)
		yPos = yPos + yDiff
		
		local map20 = addCampaignData(Vec2(-0.25, yPos),"Blocked path",false, true)
		local map21 = addCampaignData(Vec2(-0.75, yPos),"The line",false, false)
		yPos = yPos + yDiff
		
		local map22 = addCampaignData(Vec2(-0.15, yPos),"Dump station",false, false)
		local map23 = addCampaignData(Vec2(-0.15 - (0.7/3), yPos),"Rifted",false, false)
		local map24 = addCampaignData(Vec2(-0.15 - (0.7/3) * 2, yPos),"Paths",false, false)
		local map25 = addCampaignData(Vec2(-0.85, yPos),"Divided",false, false)
		yPos = yPos + yDiff

		local map26 = addCampaignData(Vec2(-0.2, yPos),"Nature",false, false)
		local map27 = addCampaignData(Vec2(-0.5, yPos),"Train station",false, false)
		local map28 = addCampaignData(Vec2(-0.8, yPos),"Desperado",false, false)
		yPos = yPos + yDiff
		
		local map29 = addCampaignData(Vec2(-0.5, yPos),"The end",false, false)
		--yPos = -2.95

		addConnections(map1, {map2})
		
		addConnections(map2, {map3, map4})
		
		addConnections(map3, {map5, map6})
		addConnections(map4, {map6, map7})
		
		addConnections(map5, {map8, map9})
		addConnections(map6, {map9, map10})
		addConnections(map7, {map10, map11})
		
		addConnections(map8, {map12})
		addConnections(map9, {map12})
		addConnections(map10, {map13})
		addConnections(map11, {map13})
		


--		mapsPanel:add( FreeFormSprite(Vec2(150, 150), Vec2(300,300), "tmpImage.jpg") )
		local color2 = Vec3(253.0, 249.0, 220.0) / 255.0
		local color1 = Vec3(137.0,86.0,4.0) / 255.0
		
		local color1Locked = Vec3(65.0,65.0,65.0) / 255.0;
		local color2Locked = Vec3(230.0,230.0,230.0) / 255.0
		

		local yStepSize = -0.25
		local yOffset = -0.2	
		
		for index=1, #campaignMapData do
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
		
		

--		lines:addLine(Vec2(-0.5, yOffset), Vec2(-0.3, yOffset+yStepSize), 8, color1, color2, color1)
--		lines:addLine(Vec2(-0.5, yOffset), Vec2(-0.7, yOffset+yStepSize), 8, color1, color2, color1)
		
		
		local count = 0
		for i=1, #files do
			
			local file = files[i].file
			--file = File()
			
			if file:isFile() then
				count = count + 1
				
				local button = Button(PanelSize(Vec2(-1,0.03)), "", ButtonStyle.SQUARE)
				--icon
				local icon = Image(PanelSize(Vec2(-1), Vec2(2,1)), Text("icon_table.tga") )
				--wave counter
				local waveCountLabel = button:add(Label(PanelSize(Vec2(-1, -1)), tostring(files[i].waveCount), Vec3(0.85)))
				
				
				--store
				campaignList[i] = {button=button, icon=icon, waveLabel=waveCountLabel}
			end
		end
	
	end
	
	local function changeGameMode(tag, index)
		if index<=0 or index>#gameModes then
			index = 1
		end
		levelInfo.setGameMode(gameModes[index])
		--
		gameModeBox.setIndex(index)
		--
		menuPrevSelect:get("campaign"):get("selectedGameMode"):setInt(index)
--		if gameModes[index]=="survival" or gameModes[index]=="rush" then
--			changeDifficulty("",2)
--			difficutyBox.setEnabled(false)
--		else
--			difficutyBox.setEnabled(true)
--		end
--		--
--		fillDificulty()
		--
		updateIcons()
		updateRewardInfo()
		updateHighScorePanel()
	end

	local function startMap(button)
		button:clearEvents()	
		levelInfo.setIsCampaign(true)
		levelInfo.setGameMode(gameModeBox.getIndexText())
		local mapFile = File(selectedFile)
		if mapFile:exist() then
			
			local mNum = getMapIndex(selectedMapPath)
--			local mNum = tonumber(string.match(selectedButton:getTag():toString(),"(.*):"))
			levelInfo.setMapNumber(mNum)
			levelInfo.setSead(files[mNum].sead)
			levelInfo.setMapFileName(selectedFile)
			levelInfo.setMapName(mapFile:getName())
			if mapFile:isFile() then
				mapLabel:setText( mapFile:getName() )
				local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
				if mapInfo then
					levelInfo.setIsCartMap(mapInfo.gameMode=="Cart")
					levelInfo.setIsCircleMap(mapInfo.gameMode=="Circle")
					levelInfo.setIsCrystalMap(mapInfo.gameMode=="Crystal")
				end
				if mapInfo then
					levelInfo.setAddPerLevel(mapInfo.difficultyIncreaseMax)
					levelInfo.setDifficultyBase(mapInfo.difficultyBase)
					levelInfo.setWaveCount(mapInfo.waveCount)
					levelInfo.setMapSize(mapInfo.mapSize)
				else
					error("No map information was found")
				end
				levelInfo.setLevel(1)
				local d1 = levelInfo.getDifficulty()
				local d2 = levelInfo.getDifficultyIncreaser()
			end
			--save default selection
			menuPrevSelect:save()
			--
			Core.startMap(selectedFile)
			local worker = Worker("Menu/loadingScreen.lua", true)
			worker:start()
		else
			error("The map "..tostring(selectedFile).." does not exist")
		end
	end
	local function showShop()
		windowShop.setVisible(true)
		mainPanel:setVisible(false)
	end
	local function updateCrystalButton()
		crystalCountLabel:setText( Text(tostring(campaignData.getCrystal())) )
	end
	local function addMapInfoPanel(panel)
		local infoPanel = panel:add(Panel(PanelSize(Vec2(-1, -1))))
	--	infoPanel:getPanelSize():setFitChildren(false, true)
		infoPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.005))))
		infoPanel:setPadding(BorderSize(Vec4(0.005),true))
		infoPanel:setBackground(Gradient(Vec4(0,0,0,0.9), Vec4(0,0,0,0.9)))
		
		local BackgroundImage = infoPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), "SB1_RB"))
		local texture = Core.getTexture("SB1_RB")
		
		
		BackgroundImage:setUvCoord(Vec2(), Vec2(texture:getSize().y/texture:getSize().x,1.0))
			
		
		iconImage = BackgroundImage:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("noImage")))
		iconImage:setBorder(Border( BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		iconImage:setShader("a2DWorldIcon")
		
		mapLabel = infoPanel:add(Label(PanelSize(Vec2(-1, 0.03)), "The island world", Vec3(0.7), Alignment.MIDDLE_CENTER))
		
--		--
--		--	Difficulties
--		--
--		local rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
--		labels[1] = rowPanel:add(Label(PanelSize(Vec2(-0.6,-1)), language:getText("difficulty"), Vec3(0.7)))
--		labels[1]:setTag("difficulty")
--		local optionsNames = {"easy", "normal", "hard", "extreme", "insane"}
--		local difficultLevel = 2
--		difficutyBox = SettingsComboBox.new(rowPanel,PanelSize(Vec2(-1)), optionsNames, "difficulty", optionsNames[difficultLevel], changeDifficulty )
		--
		--	Game modes
		--
		--Game mode		
		rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		labels[2] = rowPanel:add(Label(PanelSize(Vec2(-0.6,-1)), language:getText("game mode"), Vec3(0.7)))
		labels[2]:setTag("game mode")
		local defaultMode = 1
		gameModeBox = SettingsComboBox.new(rowPanel,PanelSize(Vec2(-1)), gameModes, "game mode", gameModes[defaultMode], changeGameMode, optionsTooltip )
		
		--
		--	Reward
		--
		rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		rowPanel:add(Label(PanelSize(Vec2(-0.6,-1)), "Reward", Vec3(0.7)))--language:getText("reward")
		rewardLabel = rowPanel:add(Label(PanelSize(Vec2(-0.5,-1)), "2", Vec3(0.7)))
		--	Crystal
		local image = rowPanel:add(Image(PanelSize(Vec2(-1),Vec2(1)), Text("icon_table.tga")))
		image:setUvCoord(Vec2(0.5, 0.375),Vec2(0.625, 0.4375))
		
		
		
		--
		--	start button
		--
		local startAGameButton = infoPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(7,1), language:getText("start game")))
		startAGameButton:addEventCallbackExecute(startMap)
		labels[4] = startAGameButton
		labels[4]:setTag("start game")
		
		--	Spacing
		local highScorePanel = infoPanel:add(Panel(PanelSize(Vec2(-1,-0.85))))
		
		highScorePanel:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
		local borderPanel = highScorePanel:add(Panel(PanelSize(Vec2(-0.96,-0.98))))
		borderPanel:setLayout(FallLayout())
		borderPanel:setBorder(Border(BorderSize(Vec4(2),PanelSizeType.Pixel), Vec3(0.3)))
		borderPanel:setBackground(Gradient(Vec3(0.15),Vec3(0.1)))
		--add header
		local scoreHeader = borderPanel:add(Panel(PanelSize(Vec2(-1,-0.1))))
		local labelColor = Vec4(0.9,0.9,0.9,1.0)
		scoreHeader:add(Label(PanelSize(Vec2(-0.65,-1)), language:getText("name"), labelColor))
		scoreHeader:add(Label(PanelSize(Vec2(-0.5,-1)), language:getText("score"), labelColor))
		local scoreLine = borderPanel:add(Panel(PanelSize(Vec2(-1,1),PanelSizeType.Pixel)))		
		scoreLine:setBackground(Sprite(Vec3(0.3)))
		scoreArea = borderPanel:add(Panel(PanelSize(Vec2(-1))))
		scoreArea:setLayout(GridLayout(9,1))
		
		
		
		
		--
		--	shop button
		--
		local shopPanel = infoPanel:add(Panel(PanelSize(Vec2(-1,-1))))
		shopPanel:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
		local shopButton = shopPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(7,1), language:getText("shop")))
		shopButton:addEventCallbackExecute(showShop)
		

		shopButton:setLayout(FlowLayout(Alignment.MIDDLE_RIGHT))
		local image = shopButton:add(Image(PanelSize(Vec2(-1,-0.9),Vec2(1)), Text("icon_table.tga")))
		image:setUvCoord(Vec2(0.5, 0.375),Vec2(0.625, 0.4375))
--		image:setBackground(Sprite(Vec3(1)))
		image:setCanHandleInput(false)
		crystalCountLabel = shopButton:add(Label(PanelSize(Vec2(-1,-0.9),Vec2(2,1)), Text(tostring(campaignData.getCrystal())), labelColor, Alignment.MIDDLE_RIGHT))
		crystalCountLabel:setTextColor(Vec3(0.5,1,0.5))
		crystalCountLabel:setCanHandleInput(false)
		
		labels[6] = shopButton
		labels[6]:setTag("shop")
		
		
	end
	local function mapInfoLoaded()
		local mapFolder = Core.getDataFolder("Map")
		for i=1, #files do
			local file = files[i].file
			local mapInfoItem = MapInformation.getMapInfoFromFileName(file:getName(), file:getPath()) 
		end
	end
	function self.changedVisibility(panel)
		MapInformation.setMapInfoLoadedFunction(mapInfoLoaded)
	end
	function self.update()
		if windowShop.getVisible() then
			windowShop.update()
		end
	end
	local function returnFromShopToCampaign()
		mainPanel:setVisible(true)
	end
	local function init()
		
		--CampaignGameMenu.mapTable = {}
		selectedFile = ""
		
		--Previosly selected
		menuPrevSelect = Config("menuPrevSelect")
		
		--Options panel
		mainPanel = panel:add(Panel(PanelSize(Vec2(-1))))
		mainPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		--
		
		
		--Top menu button panel
		local topMenuButtons = mainPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
		topMenuButtons:setLayout(FlowLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		local campaignButton = MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(7,1), language:getText("campaign"))
		local shopButton = MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(7,1), language:getText("Shop"))
		
--		labels[5] = mainPanel:add(Label(PanelSize(Vec2(-1,0.04)), language:getText("campaign"), Vec3(0.94), Alignment.MIDDLE_LEFT))
		labels[5] = topMenuButtons:add(campaignButton)
		labels[5]:setTag("campaign")
		
		topMenuButtons:add(shopButton)
		shopButton:setTag("campaign")
		
		--MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(7,1), language:getText("start game"))
		
		
		local camera = this:getRootNode():findNodeByName("MainCamera")
		if camera then
			windowShop = Shop.new(camera, updateCrystalButton, panel, labels[5])
			windowShop.setGoBackCallback(returnFromShopToCampaign)
		end
		
		--shop = Shop.new(mainAreaPanel)
		
		--Add BreakLine
		local breakLinePanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		local gradient = Gradient()
		gradient:setGradientColorsHorizontal({Vec3(0.45),Vec3(0.66),Vec3(0.45)})
		breakLinePanel:setBackground(gradient)
		
		local sPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.93, -0.95))))
		sPanel:setBorder(Border( BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		
		--Add map panel
		addMapsPanel(sPanel)
		
		--add midle Border line
		sPanel:add(Panel(PanelSize(Vec2(MainMenuStyle.borderSize,-1),PanelSizeType.WindowPercentBasedOny))):setBackground(Sprite(MainMenuStyle.borderColor))
		
		--Add info panel
		addMapInfoPanel(sPanel)
		--updated the icon list and the wave count
		updateIcons()
		
--		if firstMapButton then
--			customeGameChangedMap(firstMapButton)
--		end
		
		MapInformation.setMapInfoLoadedFunction(mapInfoLoaded)
				MapInformation.init()
		
		local setDefault = true
		--set previous selected settings or a default setting
		if menuPrevSelect:get("campaign"):exist("selectedMap") and menuPrevSelect:get("campaign"):exist("selectedDifficulty") and menuPrevSelect:get("campaign"):exist("selectedGameMode") then
			local index = getMapIndex(menuPrevSelect:get("campaign"):get("selectedMap"):getString())
			index = index>0 and index or 1--we must select a valid value
			if files[index].available then
--				changeMapTo(menuPrevSelect:get("campaign"):get("selectedMap"):getString())
				--
--				local diffIndex = menuPrevSelect:get("campaign"):get("selectedDifficulty"):getInt()
--				changeDifficulty("",diffIndex)
				--
				local selIndex = menuPrevSelect:get("campaign"):get("selectedGameMode"):getInt()
				changeGameMode("", selIndex)
				--
				setDefault =  false
			end
		end
		if setDefault then
			--changeMapTo(files[1].file:getPath())
--			changeDifficulty("",2)
			changeGameMode("", 1)
		end
	
		mainPanel:setVisible(false)
	end
	init()
	--
	--	Public functions
	--
	function self.isVisible()
	end
	function self.getVisible()
		return mainPanel:getVisible()
	end
	function self.getChildVisible()
		return windowShop.getVisible()
	end
	function self.setVisible(set,set2)
		if type(set)=="boolean" then
			print("mainPanel:setVisible("..tostring(set)..")\n")
			mainPanel:setVisible(set)
			windowShop.setVisible(false)
			if set then
				updateHighScorePanel()
			end
		else
			print("mainPanel:setVisible("..tostring(set2)..")\n")
			mainPanel:setVisible(set2)
			windowShop.setVisible(false)
			if set then
				updateHighScorePanel()
			end
		end
	end
	--
	--
	--
	return self
end