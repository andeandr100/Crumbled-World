require("Menu/MainMenu/mainMenuStyle.lua")
require("Game/mapInfo.lua")
require("Menu/MainMenu/mapInformation.lua")
require("Menu/MainMenu/settingsCombobox.lua")

CustomeGameMenu = {}
function CustomeGameMenu.new(panel)
	local self = {}
	--this = SceneNode()
	local mapTable = {}
	local levelInfo = MapInfo.new()
	--local mapInfoTable = nil
	local curentDirectory = "Map"
	--
	local selectedFile = ""
	local selectedMapButton
	--GUI
	local mainPanel
	local iconImage
	local mapLabel
	local difficutyBox
	local gameModeBox
	local mapListPanel
	local diffNames = {}
	local labels = {}
	
	function self.languageChanged()
		for i=1, #labels do
			labels[i]:setText(language:getText(labels[i]:getTag()))
		end
		difficutyBox.updateLanguage()
		gameModeBox.updateLanguage()
	end
	
	local function splitString(str,sep)
		local array = {}
		local reg = string.format("([^%s]+)",sep)
		for mem in string.gmatch(str,reg) do
			table.insert(array, mem)
		end	
		return array
	end
	local function setDefaultButtonColor(button,num)
		local set = false
		if num then
			set = num%2==0
		else
			set = tonumber(string.match(button:getTag():toString(),"(.*):"))%2==0
		end
		if set then
			button:setEdgeColor(Vec4(1,1,1,0.05), Vec4(1,1,1,0.05))
			button:setInnerColor(Vec4(1,1,1,0.05), Vec4(1,1,1,0.05), Vec4(1,1,1,0.05))
		else
			button:setEdgeColor(Vec4(0), Vec4(0))
			button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
		end
	end
	local function setSelectedButtonColor(button)
		selectedNum = button
		button:setEdgeColor(Vec4(1,1,1,0.25), Vec4(1,1,1,0.25))
		button:setInnerColor(Vec4(1,1,1,0.25), Vec4(1,1,1,0.25), Vec4(1,1,1,0.25))
	end
	local function mapInfoLoaded()
		local mapFolder = Core.getDataFolder(curentDirectory)
		local files = mapFolder:getFiles()
		
		for i=1, #files do
			local file = files[i]
			--file = File()
			
			local panels = mapTable[file:getPath()]
			local mapInfoItem = MapInformation.getMapInfoFromFileName(file:getName(), file:getPath()) 
			
			print("Update "..file:getPath().." found "..(panels and "Panels" or "nil").." and "..(mapInfoItem and "mapInfoItem" or "nil").."\n")
			
			if panels and mapInfoItem then
				panels.gameMode:setText(mapInfoItem.gameMode)
			end
		end
	end
	function self.changedVisibility(panel)
		MapInformation.setMapInfoLoadedFunction(mapInfoLoaded)
	end
	local function changeDifficulty(tag, index)
		--set difficulty
		levelInfo.setLevel(index)
	end

	local function changeGameMode(tag, index, items)
		--set game mode
		levelInfo.setGameMode(items[index])
	end

	local function startMap(button)
		local mapFile = File(selectedFile)
		levelInfo.setIsCampaign(false)
		levelInfo.setMapFileName(selectedFile)
		levelInfo.setMapName(mapFile:getName())
		levelInfo.setGameMode(gameModeBox.getIndexText())
		if mapFile:isFile() then
			local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
			levelInfo.setIsCartMap(mapInfo and mapInfo.gameMode=="Cart" or false)
			levelInfo.setWaveCount(mapInfo and mapInfo.waveCount or 25)
			levelInfo.setPlayerCount(mapInfo and mapInfo.players or 1)
			if mapInfo then
				levelInfo.setChangedDifficultyMax(mapInfo.difficultyIncreaseMax)
				levelInfo.setChangedDifficultyMin(mapInfo.difficultyIncreaseMin)
			end
			levelInfo.setLevel(difficutyBox.getIndex())
		end
		--
		Core.startMap(selectedFile)
		Worker("Menu/loadingScreen.lua", true)
	end
	local function addMapInfoPanel(panel)
		local infoPanel = panel:add(Panel(PanelSize(Vec2(-1, -1))))
		infoPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.005))))
		infoPanel:setPadding(BorderSize(Vec4(0.005),true))
		infoPanel:setBackground(Gradient(Vec4(0,0,0,0.9), Vec4(0,0,0,0.9)))
		
		iconImage = infoPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("noImage")))
		iconImage:setBorder(Border( BorderSize(Vec4(0.0015), true), Vec3(0)))
		
		mapLabel = infoPanel:add(Label(PanelSize(Vec2(-1, 0.03)), "The island world", Vec3(0.7), Alignment.MIDDLE_CENTER))
		
		--difficulty
		local rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		labels[1] = rowPanel:add(Label(PanelSize(Vec2(-0.6,-1)), language:getText("difficulty"), Vec3(0.7)))
		labels[1]:setTag("difficulty")
		local optionsNames = {"easy", "normal", "hard", "extreme", "insane"}
		difficutyBox = SettingsComboBox.new(rowPanel,PanelSize(Vec2(-1)), optionsNames, "difficulty", optionsNames[2], changeDifficulty )
		
		
		--Game mode		
		rowPanel = infoPanel:add(Panel(PanelSize(Vec2(-1, 0.03))))
		labels[2] = rowPanel:add(Label(PanelSize(Vec2(-0.6,-1)), language:getText("game mode"), Vec3(0.7)))
		labels[2]:setTag("game mode")
		local optionsNames = {"default", "survival", "training", "leveler"}
		local optionsTooltip = {"default tooltip", "survival tooltip", "training tooltip", "leveler tooltip"}
		gameModeBox = SettingsComboBox.new(rowPanel,PanelSize(Vec2(-1)), optionsNames, "game mode", optionsNames[1], changeGameMode, optionsTooltip )
		
		local startAGameButton = infoPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(7,1), language:getText("start game")))
		startAGameButton:setTag("start game")
		startAGameButton:addEventCallbackExecute(startMap)
		labels[3] = startAGameButton
		
	end
	local function workMapName(mapName)
		if mapName:sub(1,5)=="Co-op" then
			return mapName:sub(7)
		end
		return mapName
	end
	local function customeGameChangedMap(button)
		local mNum,path = string.match(button:getTag():toString(),"(.*):(.*)")
		selectedFile = path
		local mapFile = File(path)
	
		if mapFile:isFile() then
			mapLabel:setText( workMapName(mapFile:getName()) )
			local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
			local imageName = mapInfo and mapInfo.icon or nil
			local texture = Core.getTexture(imageName and imageName or "noImage")
			levelInfo.setIsCartMap(mapInfo and mapInfo.gameMode=="Cart" or false)
			levelInfo.setWaveCount(mapInfo and mapInfo.waveCount or 25)
			if mapInfo then
				levelInfo.setChangedDifficultyMax(mapInfo.difficultyIncreaseMax)
				levelInfo.setChangedDifficultyMin(mapInfo.difficultyIncreaseMin)
			end
			
			iconImage:setTexture(texture)
		end
		
		--set selected color
		if selectedMapButton then
			setDefaultButtonColor(selectedMapButton)
		end
		selectedMapButton = button
		setSelectedButtonColor(selectedMapButton)
		
	end
	local function changeFolder(button)
		print("changeFolder: "..button:getTag():toString().."\n")
		curentDirectory = button:getTag():toString()
		self.updateMaps()
		
		if selectedMapButton then
			customeGameChangedMap(selectedMapButton)
		end
	end
	local function addRowButton(file, num)
		local button = mapListPanel:add(Button(PanelSize(Vec2(-1,0.03)), "", ButtonStyle.SQUARE))
		
		button:setLayout(FlowLayout(Alignment.TOP_LEFT))
		
		if file then
			if file:isDirectory() then
				button:setTag(curentDirectory.."/"..file:getName())
				button:addEventCallbackExecute(changeFolder)
				local img = button:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") ))
				img:setUvCoord(Vec2(0.75,0.0),Vec2(0.875,0.125))
			elseif file:isFile() then
				button:setTag(tostring(num)..":"..file:getPath())
				button:addEventCallbackExecute(customeGameChangedMap)
				button:add(Panel(PanelSize(Vec2(-1), Vec2(1))))
			end
			
			--mapName
			local name = file:getName()
			local l1 = workMapName(name)
			local label = button:add(Label(PanelSize(Vec2(-0.65, -1)), l1, Vec4(0.85)))
			label:setCanHandleInput(false)
			
			--gameMode
			local mapInfoItem = MapInformation.getMapInfoFromFileName(file:getName(), file:getPath())
			if mapInfoItem == nil then
				mapInfoItem = {gameMode = " "}
			end
			local gameModeLabel = button:add(Label(PanelSize(Vec2(-0.5, -1)), mapInfoItem.gameMode, Vec3(0.85), Alignment.MIDDLE_LEFT))
			gameModeLabel:setCanHandleInput(false)
			
			--wave counter
			local str = mapInfoItem.waveCount and tostring(mapInfoItem.waveCount) or ""
			local waveCountLabel = button:add(Label(PanelSize(Vec2(-1, -1)), str, Vec3(0.85)))
			waveCountLabel:setCanHandleInput(false)
			
			mapTable[file:getPath()] = {gameMode = gameModeLabel}
		else
			local folders = splitString(curentDirectory, "/")
			local strDirectory = folders[1]
			for i=2, #folders - 1 do
				strDirectory = strDirectory.."/"..folders[i]
			end
			
			button:setTag(strDirectory)
			local img = button:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") ))
			img:setUvCoord(Vec2(0.75,0.0),Vec2(0.875,0.0625))
			button:addEventCallbackExecute(changeFolder)
			
			
			local label = button:add(Label(PanelSize(Vec2(-0.80, -1)), " ..", Vec4(0.85)))
			label:setCanHandleInput(false)
		end
		
		button:setTextColor(Vec3(0.7))
		button:setTextHoverColor(Vec3(0.92))
		button:setTextDownColor(Vec3(1))
		
		setDefaultButtonColor(button, num)
		
		button:setEdgeHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
		button:setEdgeDownColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
	
		
		button:setInnerHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.45), Vec4(1,1,1,0.4))
		button:setInnerDownColor(Vec4(1,1,1,0.3), Vec4(1,1,1,0.4), Vec4(1,1,1,0.3))	
		
		return button
	end
	function self.updateMaps()
		
		local mapFolder = Core.getDataFolder(curentDirectory)
		local files = mapFolder:getFiles()
		
		mapTable = {}
		selectedMapButton = nil
	
		mapListPanel:clear()
			
		local count = 0
		
		if curentDirectory ~= "Map" then
			count = count + 1
			addRowButton(nil, count)
		end
		
		for i=1, #files do
			local file = files[i]
			--file = File()
			if file:isDirectory() and file:getName() ~= "hidden" and file:getName() ~= "Campaign" then
			
				count = count + 1
				
				addRowButton(file, count)	
			end
		end
		
		for i=1, #files do
			local file = files[i]
			--file = File()
			
			if file:isFile() then
				count = count + 1
				
				local button = addRowButton(file, count)
				
				if selectedMapButton == nil and MapInformation.getMapInfoFromFileName(file:getName(), file:getPath()) then
					selectedMapButton = button
				end
			end
		end
	end
	
	local function addMapsPanel(panel)
		
		
		local mapsPanel = panel:add(Panel(PanelSize(Vec2(-0.6, -1))))
		mapsPanel:setBackground(Gradient(Vec4(1,1,1,0.01), Vec4(1,1,1,0.025)))
		
		local headerPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, 0.035))))
		headerPanel:setBackground(Gradient(Vec4(1,1,1,0.05), Vec4(1,1,1,0.1)))
		headerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(1))))--spacing
		--heaterPanel:add(Label(PanelSize(Vec2(-1), Vec2(1))))
		labels[5] = headerPanel:add(Label(PanelSize(Vec2(-0.65, -1)), language:getText("name"), Vec4(0.95)))
		labels[6] = headerPanel:add(Label(PanelSize(Vec2(-0.5, -1)), language:getText("type"), Vec3(0.95)))
		labels[7] = headerPanel:add(Label(PanelSize(Vec2(-1.0, -1)), language:getText("wave"), Vec3(0.95)))
		labels[5]:setTag("name")
		labels[6]:setTag("type")
		labels[7]:setTag("wave")
			
		mapListPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, -1))))
		mapListPanel:setEnableYScroll()	

		self.updateMaps()
	end
	--
	--
	--
	function init()
		selectedFile = ""
	
		
		--Options panel
		mainPanel = panel:add(Panel(PanelSize(Vec2(-1))))
		mainPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		--Top menu button panel
		labels[4] = mainPanel:add(Label(PanelSize(Vec2(-1,0.04)), language:getText("custome game"), Vec3(0.94), Alignment.MIDDLE_CENTER))
		labels[4]:setTag("custome game")
		
		--Add BreakLine
		local breakLinePanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		breakLinePanel:setBackground(Sprite(Vec3(0.45)))
		
		local sPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9, -0.95))))
		
		--Add map panel
		addMapsPanel(sPanel)
		--Add info panel
		addMapInfoPanel(sPanel)
		
		if selectedMapButton then
			customeGameChangedMap(selectedMapButton)
		end
		
		MapInformation.setMapInfoLoadedFunction(mapInfoLoaded)
	
		mainPanel:setVisible(false)
	end
	init()
	--
	--
	--
	function self.isVisible()
		MapInformation.init()
	end
	function self.getVisible()
		return mainPanel:getVisible()
	end
	function self.setVisible(set,set2)
		if type(set)=="boolean" then
			print("mainPanel:setVisible("..tostring(set)..")\n")
			mainPanel:setVisible(set)
		else
			print("mainPanel:setVisible("..tostring(set2)..")\n")
			mainPanel:setVisible(set2)
		end
	end
	return self
end