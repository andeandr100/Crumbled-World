require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/mapInformation.lua")
require("Game/campaignData.lua")
require("Game/mapInfo.lua")
require("Game/scoreCalculater.lua")
require("Menu/MainMenu/settingsCombobox.lua")
require("Menu/Campaign/FreeFormDesign.lua")
require("Menu/Campaign/CampaignMapDesign.lua")



--this = SceneNode()

CampaignGameMapMenu = {}
function CampaignGameMapMenu.new(parentPanel)
	local self = {}
	
	
	local gameValues = FreeFormDesign.gameValues
	local mainPanel = parentPanel:add(Panel(PanelSize(Vec2(-1))))
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
	local mapHandler = CampaignMapDesign.new()
	
	local selectedMapPath = nil

	
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
			gameValues.reloadConfig()
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
--			menuPrevSelect:get("campaign"):get("selectedMap"):setString(filePath)
			gameValues.setSelectedMap(filePath)
		end
		
		iconImage:setTexture(texture)

		--Update hihgscore after map information is set
		updateHighScorePanel()

		return true
	end
	
	local function customeGameChangedMap(button)

		local filePath = button:getTag():toString()
		local mNum = gameValues.getMapIndex(filePath)
		local mapFile = File(filePath)
		if mNum>=1 and mapFile:isFile() then
			selectedMapPath = filePath
			changeMapTo(mNum,filePath,mapFile)
		end
	end
	
	local function startMap(button)
		button:clearEvents()	
		levelInfo.setIsCampaign(true)
		levelInfo.setGameMode(gameModeBox.getIndexText())
		local mapFile = File(selectedFile)
		if mapFile:exist() then
			
			local mNum = gameValues.getMapIndex(selectedMapPath)

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
	
	local function updateRewardInfo()
		if rewardLabel then	
			if gameModeBox.getIndexText()~="survival" then
				rewardLabel:setText( tostring(levelInfo.getReward()) )
			else
				rewardLabel:setText( "6" )
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
		gameValues.setSelectedMapGameMode(index)
		--
		updateRewardInfo()
		updateHighScorePanel()
	end
	
	local function changeDifficulty(tag, index)
		if difficutyBox.isEnabled()==true then
			levelInfo.setLevel(index)
			--
			gameValues.setSelectedMapDifficulty(index)
			--
			updateRewardInfo()
			--
			difficutyBox.setIndex(index)
			updateHighScorePanel()
		end
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
		local rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		labels[1] = rowPanel:add(Label(PanelSize(Vec2(-0.6,-1)), language:getText("difficulty"), Vec3(0.7)))
		labels[1]:setTag("difficulty")
		local optionsNames = {"normal", "hard", "extreme", "insane"}
		local difficultLevel = 1
		difficutyBox = SettingsComboBox.new(rowPanel,PanelSize(Vec2(-1)), optionsNames, "difficulty", optionsNames[difficultLevel], changeDifficulty )
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
		rewardLabel = rowPanel:add(Label(PanelSize(Vec2(-0.5,-1)), "3", Vec3(0.7)))
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
		
		campaignPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.75, -1))))
		mapHandler.fillMapPanel(campaignPanel, customeGameChangedMap)
		
		--add midle Border line
		mainPanel:add(Panel(PanelSize(Vec2(MainMenuStyle.borderSize,-1),PanelSizeType.WindowPercentBasedOnY))):setBackground(Sprite(MainMenuStyle.borderColor))
		
		--Add info panel
		addMapInfoPanel()
		
		
		MapInformation.setMapInfoLoadedFunction(mapHandler.mapInfoLoaded)
		MapInformation.init()
		
		local selectedMap = gameValues.getSelectedMap() and gameValues.getSelectedMap() or files[1].file:getPath()
		--set previous selected settings or a default setting
		if selectedMap then
			if gameValues.getMapIndex(selectedMap) >= 1 and File(selectedMap):isFile() then
				changeMapTo(gameValues.getMapIndex(selectedMap), selectedMap, File(selectedMap))
			end
			changeDifficulty("",gameValues.getSelectedMapDifficulty())
			changeGameMode("", gameValues.getSelectedMapGameMode())
		end
	end
	init()
	
	function self.update()
		
	end
	
	return self
end