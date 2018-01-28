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
	--Select
	local gameModes = {"default", "survival", "training", "leveler"}--"rush"
	local menuPrevSelect	--menuPrevSelect=Config()
	local files
	
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
		
		for i=1, #files do
			local file = files[i].file
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
		if difficutyBox.isEnabled()==true then
			--set difficulty
			levelInfo.setLevel(index)
			--
			menuPrevSelect:get("custom"):get("selectedDifficulty"):setInt(index)
			--
			difficutyBox.setIndex(index)
		end
	end

	local function updateWaveCount()
		--force game mode update
		local activeGameMode = gameModeBox and gameModeBox.getIndexText() or ""
		--
		print("updateWaveCount("..levelInfo.getGameMode()..")")
		for i=1, #files do
			if files[i].waveCountLabel then
				local file = files[i].file
				local filePath =  file:getPath()
				local mapInfoItem = MapInformation.getMapInfoFromFileName(file:getName(), file:getPath())
				if activeGameMode=="survival" then
					files[i].waveCountLabel:setText( mapInfoItem and "100" or "" )
				else
					files[i].waveCountLabel:setText( mapInfoItem and tostring(mapInfoItem.waveCount) or "" )
				end
			end
		end
	end
	local function changeGameMode(tag, index)
		if index<=0 or index>#gameModes then
			index = 1
		end
		--set game mode
		levelInfo.setGameMode(gameModes[index])
		--
		gameModeBox.setIndex(index)
		--
		if levelInfo.getGameMode()=="survival" or levelInfo.getGameMode()=="rush" then
			changeDifficulty("",2)
			difficutyBox.setEnabled(false)
		else
			difficutyBox.setEnabled(true)
		end
		updateWaveCount()
		
		menuPrevSelect:get("custom"):get("selectedGameMode"):setInt(index)
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
				levelInfo.setAddPerLevel(mapInfo.difficultyIncreaseMax)
				levelInfo.setDifficultyBase(mapInfo.difficultyBase)
			end
			levelInfo.setLevel(difficutyBox.getIndex())
		end
		--
		menuPrevSelect:save()
		--
		Core.startMap(selectedFile)
		local worker = Worker("Menu/loadingScreen.lua", true)
		worker:start()
	end
	local function addMapInfoPanel(panel)
		local infoPanel = panel:add(Panel(PanelSize(Vec2(-1, -1))))
		infoPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.005))))
		infoPanel:setPadding(BorderSize(Vec4(0.005),true))
		infoPanel:setBackground(Gradient(Vec4(0,0,0,0.9), Vec4(0,0,0,0.9)))
		
		iconImage = infoPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("noImage")))
		iconImage:setBorder(Border( BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		
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
		local optionsTooltip = {"default tooltip", "survival tooltip", "training tooltip", "leveler tooltip"}
		gameModeBox = SettingsComboBox.new(rowPanel,PanelSize(Vec2(-1)), gameModes, "game mode", gameModes[1], changeGameMode, optionsTooltip )
		
		local startAGameButton = infoPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(7,1), language:getText("start game")))
		startAGameButton:setTag("start game")
		startAGameButton:addEventCallbackExecute(startMap)
		labels[3] = startAGameButton
		
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
	local function workMapName(mapName)
		if mapName:sub(1,5)=="Co-op" then
			return mapName:sub(7)
		end
		return mapName
	end
	local function changeMapTo(filePath)
		local mNum = getMapIndex(filePath)
		if mNum>=1 then
			selectedFile = filePath
			local mapFile = File(filePath)
		
			if mapFile:isFile() then
				mapLabel:setText( workMapName(mapFile:getName()) )
				local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
				local imageName = mapInfo and mapInfo.icon or nil
				local texture = Core.getTexture(imageName and imageName or "noImage")
				levelInfo.setIsCartMap(mapInfo and mapInfo.gameMode=="Cart" or false)
				levelInfo.setWaveCount(mapInfo and mapInfo.waveCount or 25)
				if mapInfo then
					levelInfo.setAddPerLevel(mapInfo.difficultyIncreaseMax)
					levelInfo.setDifficultyBase(mapInfo.difficultyBase)
				end
				menuPrevSelect:get("custom"):get("selectedMap"):setString(filePath)
				
				iconImage:setTexture(texture)
			end
			
			--set selected color
			if selectedMapButton then
				setDefaultButtonColor(selectedMapButton)
			end
			selectedMapButton = files[mNum].button
			setSelectedButtonColor(selectedMapButton)
		end
	end
	local function customeGameChangedMap(button)
		print("==================================================================")
		print("customeGameChangedMap()")
		local mNum,path = string.match(button:getTag():toString(),"(.*):(.*)")
		--mNum = tonumber(mNum)
		changeMapTo(path)
		updateWaveCount()
	end
	local function changeFolder(dirPath)
		curentDirectory = dirPath
		self.updateMaps()
		
		if selectedMapButton then
			customeGameChangedMap(selectedMapButton)
		end
	end
	local function changeFolderButton(button)
		print("changeFolder: "..button:getTag():toString().."\n")
		changeFolder(button:getTag():toString())
	end
	local function addRowButton(file, num)
		local button = mapListPanel:add(Button(PanelSize(Vec2(-1,0.03)), "", ButtonStyle.SQUARE))
		local waveCountLabel = nil
		
		button:setLayout(FlowLayout(Alignment.TOP_LEFT))
		
		if file then
			if file:isDirectory() then
				button:setTag(curentDirectory.."/"..file:getName())
				button:addEventCallbackExecute(changeFolderButton)
				local img = button:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") ))
				img:setUvCoord(Vec2(0.75,0.0),Vec2(0.875,0.0625))
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
			waveCountLabel = button:add(Label(PanelSize(Vec2(-1, -1)), str, Vec3(0.85)))
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
			button:addEventCallbackExecute(changeFolderButton)
			
			
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
		
		return button, waveCountLabel
	end
	function self.updateMaps()
		
		local mapFolder = Core.getDataFolder(curentDirectory)
		local tFiles = mapFolder:getFiles()
		files = {}
		for i=1, #tFiles do
			files[i]={file = tFiles[i], button=nil}
		end
		
		mapTable = {}
		selectedMapButton = nil
	
		mapListPanel:clear()
			
		local count = 0
		
		if curentDirectory ~= "Map" then
			count = count + 1
			addRowButton(nil, count)
		end
		
		for i=1, #files do
			local file = files[i].file
			--file = File()
			if file:isDirectory() and file:getName() ~= "hidden" and file:getName() ~= "Campaign" then
			
				count = count + 1
				
				addRowButton(file, count)	
			end
		end
		
		for i=1, #files do
			local file = files[i].file
			--file = File()
			
			if file:isFile() then
				count = count + 1
				
				local button, waveCountLabel = addRowButton(file, count)
				files[i].button = button
				files[i].waveCountLabel = waveCountLabel
				
--				if selectedMapButton == nil and MapInformation.getMapInfoFromFileName(file:getName(), file:getPath()) then
--					selectedMapButton = button
--				end
			end
		end
		--update wave count
		updateWaveCount()
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
	local function getDir(path)
		local dir = {}
		for str in string.gmatch(path,"([^/]+)") do
			dir[#dir+1] = str
		end
		--remove last as this should only be the file
		if #dir>=1 then
			dir[#dir] = nil
		end
		return dir
	end
	local function replaceAllWrongPath(path)
		local ret = ""
		for str in string.gmatch(path,"([^\\]+)") do
			if ret~="" then
				ret = ret.."/"..str
			else
				ret = str
			end
		end
		return ret
	end
	--
	--
	--
	function init()
		selectedFile = ""
	
		--Previosly selected
		menuPrevSelect = Config("menuPrevSelect")
		
		--Options panel
		mainPanel = panel:add(Panel(PanelSize(Vec2(-1))))
		mainPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		--Top menu button panel
		labels[4] = mainPanel:add(Label(PanelSize(Vec2(-1,0.04)), language:getText("custome game"), Vec3(0.94), Alignment.MIDDLE_CENTER))
		labels[4]:setTag("custome game")
		
		--Add BreakLine
		local breakLinePanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		local gradient = Gradient()
		gradient:setGradientColorsHorizontal({Vec3(0.45),Vec3(0.66),Vec3(0.45)})
		breakLinePanel:setBackground(gradient)
		
		local sPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9, -0.95))))
		sPanel:setBorder(Border( BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		
		--Add map panel
		addMapsPanel(sPanel)
		
		--add midle Border line
		sPanel:add(Panel(PanelSize(Vec2(MainMenuStyle.borderSize,-1),PanelSizeType.WindowPercentBasedOny))):setBackground(Sprite(MainMenuStyle.borderColor))
		
		--Add info panel
		addMapInfoPanel(sPanel)
		
--		if selectedMapButton then
--			customeGameChangedMap(selectedMapButton)
--		end

		MapInformation.setMapInfoLoadedFunction(mapInfoLoaded)

		--set previous selected settings or a default setting
		if menuPrevSelect:get("custom"):exist("selectedMap") then
			--manage if the map is in a sub folder
			local path = menuPrevSelect:get("custom"):get("selectedMap"):getString()
			local dir = getDir(replaceAllWrongPath(path))
			if #dir>2 then
				--the map is in a sub folder
				local folder
				for i=2, #dir do--i=2 because the first is "Data" wich is not used for map path
					if i~=2 then
						folder = folder.."/"..dir[i]
					else
						folder = dir[i]
					end
				end
				changeFolder(folder)
			end
			--previous selection available
			changeMapTo(path)
		else
			--no previous selection available
			for i=1, #files do
				local file = files[i].file
				if file:isFile() then
					changeMapTo(file:getPath())
					break
				end
			end
		end
		if menuPrevSelect:get("custom"):exist("selectedDifficulty") then
			--previous selection available
			local diffIndex = menuPrevSelect:get("custom"):get("selectedDifficulty"):getInt()
			changeDifficulty("",diffIndex)
		else
			--no previous selection available
			changeDifficulty("",2)
		end
		if menuPrevSelect:get("custom"):exist("selectedGameMode") then
			--previous selection available
			local selIndex = menuPrevSelect:get("custom"):get("selectedGameMode"):getInt()
			changeGameMode("", selIndex)
		else
			--no previous selection available
			changeGameMode("", 1)
		end
	
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