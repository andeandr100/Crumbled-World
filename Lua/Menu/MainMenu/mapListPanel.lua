require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/mapInformation.lua")
--this = SceneNode()
MapListPanel = {}
function MapListPanel.new(panel, changeMapCallback)
	local self = {}
	local mapTable = {}
	local worker
	local firstButton = nil
	local curentDirectory = "Map"
	local mapListPanel
	local addRowFunction
	local labels = {}
	
	function self.getFirstMapButton()
		return firstButton
	end

	function self.languageChanged()
		for i=1, #labels do
			labels[i]:setText(language:getText(labels[i]:getTag()))
		end
	end

	local function splitString(str,sep)
		local array = {}
		local reg = string.format("([^%s]+)",sep)
		for mem in string.gmatch(str,reg) do
			table.insert(array, mem)
		end	
		return array
	end
	
	local function mapInfoLoaded()
		local mapFolder = Core.getDataFolder(curentDirectory)
		local files = mapFolder:getFiles()
		
		local mapConfig = Config("mapsInfo")
		local mapInfoTable = mapConfig:get("data"):getTable()
		
		for i=1, #files do
			local file = files[i]
			--file = File()
			
			local panels = mapTable[file:getPath()]
			local mapInfoItem = mapInfoTable[file:getPath()]
			if panels and mapInfoItem then
				panels.mapSize:setText(mapInfoItem.mapSize)
				panels.player:setText(tostring(mapInfoItem.players))
			end
		end
	end
	
	local function updateMapList()
		local mapFolder = Core.getDataFolder(curentDirectory)
		local files = mapFolder:getFiles()
		local count = 0
		
		mapListPanel:clear()
		
		if curentDirectory ~= "Map" then
			count = count + 1
			addRowFunction(nil, count%2 == 0)
		end
		
		for i=1, #files do
			if files[i]:isDirectory() and files[i]:getName() ~= "hidden" and files[i]:getName() ~= "Campaign" then
				count = count + 1
				addRowFunction( files[i], count%2 == 0 )
			end
		end	
		
		for i=1, #files do
			if files[i]:isFile() then
				local mapInfoItem = MapInformation.getMapInfoFromFileName(files[i]:getName(), files[i]:getPath())
				if mapInfoItem and mapInfoItem.players > 1 then
					count = count + 1
					addRowFunction( files[i], count%2 == 0 )
				end
			end
		end	
	end
	
	local function changeFolder(button)
		curentDirectory = button:getTag():toString()
		updateMapList()
	end
		
	local function addRowButton(file, evenRow)

		local button = mapListPanel:add(Button(PanelSize(Vec2(-1,0.03)), "", ButtonStyle.SQUARE))

		button:setTextColor(Vec3(0.7))
		button:setTextHoverColor(Vec3(0.92))
		button:setTextDownColor(Vec3(1))
		
		if evenRow then
			button:setEdgeColor(Vec4(1,1,1,0.05), Vec4(1,1,1,0.05))
			button:setInnerColor(Vec4(1,1,1,0.05), Vec4(1,1,1,0.05), Vec4(1,1,1,0.05))
		else
			button:setEdgeColor(Vec4(0), Vec4(0))
			button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
		end
		button:setEdgeHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
		button:setEdgeDownColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
	
		
		button:setInnerHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.45), Vec4(1,1,1,0.4))
		button:setInnerDownColor(Vec4(1,1,1,0.3), Vec4(1,1,1,0.4), Vec4(1,1,1,0.3))	
		
		button:setLayout(FlowLayout(Alignment.TOP_LEFT))
		
		if file then		
			if file:isDirectory() then
				button:setTag(curentDirectory.."/"..file:getName())
				button:addEventCallbackExecute(changeFolder)
				local img = button:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") ))
				img:setUvCoord(Vec2(0.75,0.0),Vec2(0.875,0.0625))
			elseif file:isFile() then
				button:setTag(file:getPath())
				button:addEventCallbackExecute(changeMapCallback)
				button:add(Panel(PanelSize(Vec2(-1), Vec2(1))))
				
				if firstButton == nil then
					firstButton = button
				end	
			end
				
			local label = button:add(Label(PanelSize(Vec2(-0.65, -1)), file:getName(), Vec4(0.85)))
			label:setCanHandleInput(false)
			
			local mapInfoItem = MapInformation.getMapInfoFromFileName(file:getName(), file:getPath())
			if mapInfoItem == nil then
				mapInfoItem = {mapSize = "-", players = 1}
			end
			
			local mapSizeLabel = button:add(Label(PanelSize(Vec2(-0.5, -1)), mapInfoItem.mapSize, Vec3(0.85), Alignment.MIDDLE_CENTER))
			mapSizeLabel:setCanHandleInput(false)
			
			local playerLabel = button:add(Label(PanelSize(Vec2(-1, -1)), tostring(mapInfoItem.players), Vec3(0.85), Alignment.MIDDLE_CENTER))
			playerLabel:setCanHandleInput(false)
			
			mapTable[file:getPath()] = {mapSize = mapSizeLabel, player = playerLabel}
		
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
			
			
			local label = button:add(Label(PanelSize(Vec2(-0.65, -1)), " ..", Vec4(0.85)))
			label:setCanHandleInput(false)
		end
			
	end
	
	local function init()
		local mapFolder = Core.getDataFolder(curentDirectory)
		local files = mapFolder:getFiles()
		
		local mapsPanel = panel:add(Panel(PanelSize(Vec2(-1, -1))))
		mapsPanel:setBackground(Gradient(Vec4(1,1,1,0.01), Vec4(1,1,1,0.025)))
		
		local headerPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, 0.035))))
		headerPanel:setBackground(Gradient(Vec4(1,1,1,0.05), Vec4(1,1,1,0.1)))
		labels[1] = headerPanel:add(Label(PanelSize(Vec2(-0.65, -1)), language:getText("name"), Vec4(0.95)))
		labels[2] = headerPanel:add(Label(PanelSize(Vec2(-0.5, -1)), language:getText("size"), Vec3(0.95)))
		labels[3] = headerPanel:add(Label(PanelSize(Vec2(-1, -1)), language:getText("players"), Vec3(0.95)))
		
		labels[1]:setTag("name")
		labels[2]:setTag("size")
		labels[3]:setTag("players")
			
		mapListPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, -1))))
		mapListPanel:setEnableYScroll()	
			
		addRowFunction = addRowButton
		updateMapList()
		
		MapInformation.setMapInfoLoadedFunction(mapInfoLoaded)
		
		
	end
	init()
	
	return self
end