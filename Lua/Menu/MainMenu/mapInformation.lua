--this = SceneNode()
MapInformation = {}
MapInformation.mapConfig = nil
MapInformation.maps = nil
MapInformation.worker = nil
MapInformation.functionMapInfoChanged = nil

function MapInformation.init()
	MapInformation.mapConfig = Config("mapsInfo")
	MapInformation.mapTables = MapInformation.mapConfig:get("data"):getTable()
	
--	if MapInformation.worker == nil then	
--		MapInformation.worker = Worker("Menu/MainMenu/loadCustomGameInfo.lua")
--		MapInformation.worker:addCallbackUpdated(MapInformation.mapInfoLoaded)
--		MapInformation.worker:start()
--	end
end

function MapInformation.setMapInfoLoadedFunction( aFunction )
	MapInformation.functionMapInfoChanged = aFunction
end

--function MapInformation.mapInfoLoaded()
--	local mapConfig = MapInformation.mapConfig:get("data")
--	if mapConfig then
--		MapInformation.mapTables = mapConfig:getTable()
--	
--		if MapInformation.functionMapInfoChanged then
--			MapInformation.functionMapInfoChanged()
--		end 
--	else
--		
--	end
--	
--end

function MapInformation.loadMapInfo(filePath)
	
	local file = File(filePath)
	
	local maps = MapInformation.mapTables[file:getName()]
	if not maps then
		maps = {}
		MapInformation.mapTables[file:getName()] = maps
	end
	
	
	local mapInfo = File(file:getPath(), "info.txt")
	local iconFile = File(file:getPath(), "icon.jpg")
	if mapInfo:exist() then
		
		local imageName = nil
		if iconFile:exist() then
			imageName = "Icon/"..file:getName().."_Icon.jpg"
			local iconIndex = 1
			while File("Data/Dynamic/"..imageName):exist() do
				imageName = "Icon/"..file:getName().."_Icon"..iconIndex..".jpg"
				iconIndex = iconIndex + 1
				print("Next image name: "..imageName.."\n")
			end
			
			local tmpFile = File("Data/Dynamic/"..imageName)
			if tmpFile:exist() then
				abort()
			end
			
			print("save to file: ".."Data/Dynamic/"..imageName.."\n")
			
			iconFile:saveToFile(imageName)	
			imageName = "Data/Dynamic/" .. imageName
		end
		
		print("File found\n")
		local info = totable( mapInfo:getContent() )
		local mapTable = {}
		mapTable.mapSize = info.mapSize
		mapTable.difficultyIncreaseMin = info.difficultyIncreaseMin
		mapTable.difficultyIncreaseMax = info.difficultyIncreaseMax
		mapTable.gameMode = info.gameMode
		mapTable.players = info.players and info.players or 1
		mapTable.time = file:getLastWriteTime()
		mapTable.icon = imageName
		mapTable.hash = file:getHash()
		mapTable.path = file:getPath()
		
		print("File table: table = "..tostring(mapTable).."\n")
		print("File: "..file:getPath().."\n")
		

		maps[#maps + 1] = mapTable
		
		MapInformation.mapConfig:get("data"):setTable(maps)
		MapInformation.mapConfig:save()
	else
		print("no file found\n")
	end
end

function MapInformation.getMapInfoFromFileName(fileName, filePath)
	
	if MapInformation.mapConfig == nil then
		MapInformation.init()
	end
	
	local maps = MapInformation.mapTables[fileName]
	
--	print("\n\nFileName: "..fileName.."\n")
	if maps then
--		print("Maps: "..tostring(maps).."\n")
		for i=1, #maps do
--			print("Compare "..maps[i].path.."=="..filePath.."\n")
			if maps[i].path == filePath then
--				print("found\n")
				return maps[i]
			end
		end		
	end
--	print("nil\n")
	
	--print("Table: "..tostring(MapInformation.mapTables).."\n")
	
	return nil
end

function MapInformation.getMapInfoFromFileNameAndHash(fileName, hash)
	if MapInformation.mapConfig == nil then
		MapInformation.init()
	end
	
	local maps = MapInformation.mapTables[fileName]
	
	if maps and #maps > 0 then
		for i=1, #maps do
			if maps[i].hash == hash then
				return maps[i]
			end
		end		
	end
	return nil
end