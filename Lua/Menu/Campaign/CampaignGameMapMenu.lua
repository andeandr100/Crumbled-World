require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/mapInformation.lua")
require("Game/campaignData.lua")
require("Game/mapInfo.lua")
require("Game/scoreCalculater.lua")
require("Menu/MainMenu/settingsCombobox.lua")

--this = SceneNode()

CampaignGameMapMenu = {}
function CampaignGameMapMenu.new(parentPanel)
	local self = {}
	
	
	local mainPanel = parentPanel:add(Panel(PanelSize(Vec2(-1))))
	local campaignMapData = {}
	local campaignData = CampaignData.new()
	local files = campaignData.getMaps()
	local levelInfo = MapInfo.new()
	local menuPrevSelect	--menuPrevSelect=Config()
	local mapLabel
	local gameModeBox
	local gameModes = levelInfo.getGameModesSinglePlayer()
	local optionsTooltip = {"default tooltip", "survival tooltip", "rush tooltip", "training tooltip", "leveler tooltip"}
	local campaignList = {}
	local labels = {}
	
	
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
	
	local function getMapIndex(filePath)
		for i=1, #files do	
			local file = files[i].file
			if file:isFile() and file:getPath()==filePath then
				return i
			end
		end
		return 0
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
	
	function self.setVisible(visible)
		mainPanel:setVisible(visible)
		if visible then
			updateHighScorePanel()
		end
	end
	
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
	
	local function addMapsPanel()
		local mapFolder = Core.getDataFolder("Map")
		
		local bgTexture = Core.getTexture("tmpImage.jpg")
		local background = Sprite(bgTexture,Vec2(0.25,0.0), Vec2(0.75,1.0))
		
		campaignPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.75, -1))))
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
	
	local function updateRewardInfo()
		if rewardLabel then	
			if gameModeBox.getIndexText()~="survival" then
				rewardLabel:setText( tostring(levelInfo.getReward()) )
			else
				rewardLabel:setText( "1/10W" )
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
	
	local function addMapInfoPanel()
	
		local infoPanel = mainPanel:add(Panel(PanelSize(Vec2(-1, -1))))
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
		
		
	end
	
	local function init()
	
	
		mainPanel:setBorder(Border( BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
	
		--Previosly selected
		menuPrevSelect = Config("menuPrevSelect")
		
		addMapsPanel()
		
		--add midle Border line
		mainPanel:add(Panel(PanelSize(Vec2(MainMenuStyle.borderSize,-1),PanelSizeType.WindowPercentBasedOnY))):setBackground(Sprite(MainMenuStyle.borderColor))
		
		--Add info panel
		addMapInfoPanel()
		
		updateIcons()
		
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
	end
	init()
	
	return self
end