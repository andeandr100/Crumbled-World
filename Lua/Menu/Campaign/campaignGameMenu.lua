require("Menu/MainMenu/mainMenuStyle.lua")
require("Game/mapInfo.lua")
require("Menu/MainMenu/mapInformation.lua")
require("Game/campaignData.lua")
require("Menu/Campaign/shop.lua")
require("Menu/MainMenu/settingsCombobox.lua")
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
	local difficutyBox
	local firstMapButton
	local gameModeBox
	local mainPanel
	local rewardLabel
	--Game modes
	local gameModes = {"default", "survival", "training", "leveler"}
	--Select
	local menuPrevSelect	--menuPrevSelect=Config()
	--
	local campaignList = {}
	local diffNames = {}
	local labels = {}
	
	function self.languageChanged()
		for i=1, #labels do
			labels[i]:setText(language:getText(labels[i]:getTag()))
		end
		gameModeBox.updateLanguage()
		difficutyBox.updateLanguage()
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
			rewardLabel:setText( tostring(levelInfo.getReward()) )
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
	local function updateIcons()
		for i=1, #files do
			if campaignData.isMapAvailable(i)>0 then
				if campaignData.hasMapModeLevelBeenBeaten(i,levelInfo.getGameMode(),levelInfo.getLevel()) then
					campaignList[i].icon:setUvCoord(Vec2(0.625,0.0),Vec2(0.75,0.0625))--this map with game mode and difficulty has been beaten
				elseif campaignData.hasMapBeenBeaten(i) then
					campaignList[i].icon:setUvCoord(Vec2(0.0,0.25),Vec2(0.125,0.3125))--this map has been beaten (on any game mode / difficulty)
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
					campaignList[i].waveLabel:setText(tostring(files[i].waveCount*2))
				end
			else
				for i=1, #files do
					campaignList[i].waveLabel:setText(tostring(files[i].waveCount))
				end
			end
		end
	end
	local function changeDifficulty(tag, index)
		levelInfo.setLevel(index)
		--
		menuPrevSelect:get("campaign"):get("selectedDifficulty"):setInt(index)
		--
		updateIcons()
		updateRewardInfo()
	end
	
	local function fillDificulty(levels,currentLevel)
		diffNames = {"easy", "normal", "hard", "extreme", "insane"}
		for i=#diffNames+1, levels do
			diffNames[#diffNames + 1] = language:getText("imposible") + " " + tostring(i-5)
		end
		difficutyBox.setItems(diffNames)
		difficutyBox.setIndex(currentLevel)
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
	local function changeMapTo(filePath)
		local mNum = getMapIndex(filePath)
		if mNum>=1 then
			local mapFile = File(filePath)
			levelInfo.setMapNumber(mNum)
			levelInfo.setSead(files[mNum].sead)
		
			if mapFile:isFile() then
				--set current active map
				selectedFile = filePath
				--update GUI
				mapLabel:setText( mapFile:getName() )
				local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
				local imageName = mapInfo and mapInfo.icon or nil
				local texture = Core.getTexture(imageName and imageName or "noImage")
				if mapInfo then
					levelInfo.setIsCartMap(mapInfo.gameMode=="Cart")
					levelInfo.setChangedDifficultyMax(mapInfo.difficultyIncreaseMax)
					levelInfo.setChangedDifficultyMin(mapInfo.difficultyIncreaseMin)
					levelInfo.setWaveCount(mapInfo.waveCount)
					levelInfo.setLevel(difficutyBox.getIndex())
					--changing default selected map
					menuPrevSelect:get("campaign"):get("selectedMap"):setString(filePath)
				end
				
				iconImage:setTexture(texture)
			end
			
			if selectedButton then
				setDefaultButtonColor(selectedButton)
			end
			selectedButton = files[mNum].button
			setSelectedButtonColor(files[mNum].button)
			local beatenLevel = math.max(5,campaignData.getMapModeBeatenLevel(mNum,levelInfo.getGameMode())+1)
			fillDificulty(beatenLevel,levelInfo.getLevel())
		end
	end
	local function customeGameChangedMap(button)
		local mNum,path = string.match(button:getTag():toString(),"(.*):(.*)")
		--mNum = tonumber(mNum)
		changeMapTo(path)
	end
	local function setLabelListItemColor(label,available)
		if available>0 then
			label:setTextColor(Vec3(0.7))
		else
			label:setTextColor(Vec3(0.3))
		end
	end
	local function addMapsPanel(panel)
		local mapFolder = Core.getDataFolder("Map")
		
		local mapsPanel = panel:add(Panel(PanelSize(Vec2(-0.6, -1))))
		mapsPanel:setBackground(Gradient(Vec4(1,1,1,0.01), Vec4(1,1,1,0.025)))
		
		local headerPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, 0.035))))
		headerPanel:setBackground(Gradient(Vec4(1,1,1,0.05), Vec4(1,1,1,0.1)))
		headerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(1))))--spacing
		labels[1] = headerPanel:add(Label(PanelSize(Vec2(-0.65, -1)), language:getText("name"), Vec4(0.95)))
		labels[2] = headerPanel:add(Label(PanelSize(Vec2(-0.5, -1)), language:getText("type"), Vec3(0.95)))
		labels[3] = headerPanel:add(Label(PanelSize(Vec2(-1.0, -1)), language:getText("wave"), Vec3(0.95)))
		labels[1]:setTag("name")
		labels[2]:setTag("type")
		labels[3]:setTag("wave")
			
		local mapListPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, -1))))
		mapListPanel:setEnableYScroll()
		
		local count = 0
		for i=1, #files do
			
			local file = files[i].file
			--file = File()
			
			if file:isFile() then
				count = count + 1
				
				local button = mapListPanel:add(Button(PanelSize(Vec2(-1,0.03)), "", ButtonStyle.SQUARE))
				button:setTag(tostring(i)..":"..file:getPath())
				
				button:setTextColor(Vec3(0.7))
				button:setTextHoverColor(Vec3(0.92))
				button:setTextDownColor(Vec3(1))
				
				setDefaultButtonColor(button)
				
				button:setEdgeHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
				button:setEdgeDownColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
				--
				button:setInnerHoverColor(Vec4(1,1,1,0.3), Vec4(1,1,1,0.35), Vec4(1,1,1,0.3))
				button:setInnerDownColor(Vec4(1,1,1,0.2), Vec4(1,1,1,0.3), Vec4(1,1,1,0.2))	
	
				--icon
				local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") )
				button:add(icon)
				
				button:setLayout(FlowLayout(Alignment.TOP_LEFT))
				
				--map name
				local label = button:add(Label(PanelSize(Vec2(-0.65, -1)), file:getName(), Vec4(0.85)))
				label:setCanHandleInput(false)
				setLabelListItemColor(label, campaignData.isMapAvailable(i))
				
				--type
				local mapTypeLabel = button:add(Label(PanelSize(Vec2(-0.5, -1)), files[i].type, Vec3(0.85)))
				mapTypeLabel:setCanHandleInput(false)
				setLabelListItemColor(mapTypeLabel, campaignData.isMapAvailable(i))
				
				--wave counter
				local waveCountLabel = button:add(Label(PanelSize(Vec2(-1, -1)), tostring(files[i].waveCount), Vec3(0.85)))
				waveCountLabel:setCanHandleInput(false)
				setLabelListItemColor(waveCountLabel, campaignData.isMapAvailable(i))
				
				local mapInfoItem = MapInformation.getMapInfoFromFileName(file:getName(), file:getPath())
				if mapInfoItem == nil then
					mapInfoItem = {mapSize = "-", gameMode = "-"}
				end

				if campaignData.isMapAvailable(i)>0 then
					button:addEventCallbackExecute(customeGameChangedMap)
					files[i].button = button
				else
					button:setEnabled(false)
				end
				
				if count == 1 and mapInfoItem then
					firstMapButton = button
				end
				
				--store
				campaignList[i] = {button=button, icon=icon, waveLabel=waveCountLabel}
			end
		end
	end
	
	local function changeGameMode(tag, index)
		levelInfo.setGameMode(gameModes[index])
		--
		menuPrevSelect:get("campaign"):get("selectedGameMode"):setInt(index)
		--
		updateIcons()
		updateRewardInfo()
	end

	local function startMap(button)
		levelInfo.setIsCampaign(true)
		levelInfo.setGameMode(gameModeBox.getIndexText())
		local mapFile = File(selectedFile)
		local mNum = tonumber(string.match(selectedButton:getTag():toString(),"(.*):"))
		levelInfo.setMapNumber(mNum)
		levelInfo.setSead(files[mNum].sead)
		levelInfo.setMapFileName(selectedFile)
		levelInfo.setMapName(mapFile:getName())
		if mapFile:isFile() then
			mapLabel:setText( mapFile:getName() )
			local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
			if mapInfo then
				levelInfo.setIsCartMap(mapInfo.gameMode=="Cart")
			end
			if mapInfo then
				levelInfo.setChangedDifficultyMax(mapInfo.difficultyIncreaseMax)
				levelInfo.setChangedDifficultyMin(mapInfo.difficultyIncreaseMin)
				levelInfo.setWaveCount(mapInfo.waveCount)
			end
			levelInfo.setLevel(difficutyBox.getIndex())
		end
		--save default selection
		menuPrevSelect:save()
		--
		Core.startMap(selectedFile)
		Worker("Menu/loadingScreen.lua", true)
	end
	local function showShop()
		windowShop.setVisible(true)
		form:setVisible(false)
	end
	local function addMapInfoPanel(panel)
		local infoPanel = panel:add(Panel(PanelSize(Vec2(-1, -1))))
	--	infoPanel:getPanelSize():setFitChildren(false, true)
		infoPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.005))))
		infoPanel:setPadding(BorderSize(Vec4(0.005),true))
		infoPanel:setBackground(Gradient(Vec4(0,0,0,0.9), Vec4(0,0,0,0.9)))
		
		iconImage = infoPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("noImage")))
		iconImage:setBorder(Border( BorderSize(Vec4(0.0015), true), Vec3(0)))
		
		mapLabel = infoPanel:add(Label(PanelSize(Vec2(-1, 0.03)), "The island world", Vec3(0.7), Alignment.MIDDLE_CENTER))
		
		--
		--	Difficulties
		--
		local rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		labels[1] = rowPanel:add(Label(PanelSize(Vec2(-0.6,-1)), language:getText("difficulty"), Vec3(0.7)))
		labels[1]:setTag("difficulty")
		local optionsNames = {"easy", "normal", "hard", "extreme", "insane"}
		local difficultLevel = 2
		difficutyBox = SettingsComboBox.new(rowPanel,PanelSize(Vec2(-1)), optionsNames, "difficulty", optionsNames[difficultLevel], changeDifficulty )
		
		--
		--	Game modes
		--
		--Game mode		
		rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		labels[2] = rowPanel:add(Label(PanelSize(Vec2(-0.6,-1)), language:getText("game mode"), Vec3(0.7)))
		labels[2]:setTag("game mode")
		local optionsTooltip = {"default tooltip", "survival tooltip", "training tooltip", "leveler tooltip"}
		local defaultMode = 1
		gameModeBox = SettingsComboBox.new(rowPanel,PanelSize(Vec2(-1)), gameModes, "game mode", gameModes[defaultMode], changeGameMode, optionsTooltip )
		
		--
		--	Reward
		--
		rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		rowPanel:add(Label(PanelSize(Vec2(-0.6,-1)), "Reward", Vec3(0.7)))--language:getText("reward")
		rewardLabel = rowPanel:add(Label(PanelSize(Vec2(-0.2,-1)), "2", Vec3(0.7)))
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
		infoPanel:add(Panel(PanelSize(Vec2(-1,-0.75))))
		--
		--	shop button
		--
		local shopButton = infoPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(7,1), language:getText("shop")))
		shopButton:addEventCallbackExecute(showShop)
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
	function self.update()
		if windowShop.getVisible() then
			windowShop.update()
		end
	end
	local function init()
		local camera = this:getRootNode():findNodeByName("MainCamera")
		if camera then
			windowShop = Shop.new(camera)
			windowShop.setParentForm(form)
		end
		--CampaignGameMenu.mapTable = {}
		selectedFile = ""
		
		--Previosly selected
		menuPrevSelect = Config("menuPrevSelect")
		
		--Options panel
		mainPanel = panel:add(Panel(PanelSize(Vec2(-1))))
		mainPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		--
		--Top menu button panel
		labels[5] = mainPanel:add(Label(PanelSize(Vec2(-1,0.04)), language:getText("campaign"), Vec3(0.94), Alignment.MIDDLE_CENTER))
		labels[5]:setTag("campaign")
		
		--shop = Shop.new(mainAreaPanel)
		
		--Add BreakLine
		local breakLinePanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		breakLinePanel:setBackground(Sprite(Vec3(0.45)))
		
		local sPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9, -0.95))))
		
		--Add map panel
		addMapsPanel(sPanel)
		--Add info panel
		addMapInfoPanel(sPanel)
		--updated the icon list and the wave count
		updateIcons()
		
--		if firstMapButton then
--			customeGameChangedMap(firstMapButton)
--		end
		
		MapInformation.setMapInfoLoadedFunction(mapInfoLoaded)
		
		--set previous selected settings or a default setting
		if menuPrevSelect:get("campaign"):exist("selectedMap") then
			--previous selection available
			changeMapTo(menuPrevSelect:get("campaign"):get("selectedMap"):getString())
		else
			--no previous selection available
			changeMapTo(files[1].file:getPath())
		end
		if menuPrevSelect:get("campaign"):exist("selectedDifficulty") then
			--previous selection available
			local diffIndex = menuPrevSelect:get("campaign"):get("selectedDifficulty"):getInt()
			changeDifficulty("",diffIndex)
			difficutyBox.setIndex(diffIndex)
		else
			--no previous selection available
			changeDifficulty("",2)
		end
		if menuPrevSelect:get("campaign"):exist("selectedGameMode") then
			--previous selection available
			local selIndex = menuPrevSelect:get("campaign"):get("selectedGameMode"):getInt()
			changeGameMode("", selIndex)
			gameModeBox.setIndex(selIndex)
		else
			--no previous selection available
			changeGameMode("", 1)
		end
	
		mainPanel:setVisible(false)
	end
	init()
	--
	--	Public functions
	--
	function self.isVisible()
		MapInformation.init()
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
		else
			print("mainPanel:setVisible("..tostring(set2)..")\n")
			mainPanel:setVisible(set2)
			windowShop.setVisible(false)
		end
	end
	--
	--
	--
	return self
end