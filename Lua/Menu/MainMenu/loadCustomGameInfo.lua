--this = SceneNode()
function create()
	
	local mapFolder = Core.getDataFolder("Map")
	files = mapFolder:getFiles()
	
	--This is the first map a user will see if they decide to open the campaign
	local firstMap = File("Data/Map/Campaign/Beginning.map")
	if #files > 0 then
		files[#files+1] = files[1]
	end
	files[1] = firstMap
	
	
	--print("load maps info")
	mapConfig = Config("mapsInfo")
	maps = mapConfig:get("data"):getTable()
	folders = {}
	--print("loaded maps info")
	--print("\n\n\n".."table = "..tostring(maps).."\n\n\n")
	
	folderIndex = 1
	index = 1
	updateCount = 1
	removeOnlyOnce = false
	
	return true
end

function removeDeadObjects()
	maps = mapConfig:get("data"):getTable()
	
	local toRemove = {}
	for key,value in pairs(maps) do
		for n=1, #value do
			local map = value[n]
			
			if not File(map.path):exist() then
				toRemove[#toRemove + 1] = {key=key,index=n}
			end
			
		end
	end
	
	for i=1, #toRemove do
		table.remove(maps[toRemove[i].key], toRemove[i].index)
	end
	
	if #toRemove > 0 then
		mapConfig:get("data"):setTable(maps)
		mapConfig:save()
	end
end

function update()
	
	if not removeOnlyOnce then
		removeOnlyOnce = true
		removeDeadObjects()
	end
	
	print("load maps info update")
	while index <= #files do
		local file = files[index]
		index = index + 1
		
		if file and file:isDirectory() then
			folders[#folders + 1] = file:getPath()
			print("Add folder: "..file:getPath())
			print("Folders: "..tostring(folders))
		elseif file then
		
			local fileName = file:getName()
			local mapsFileTable = maps[fileName]
			if not mapsFileTable then
				mapsFileTable = {}
				maps[fileName] = mapsFileTable
			end
			print("gather info from map \""..file:getPath().."\"")
			local loadFileData = file:isFile()
	
			print("mapsFileTable: "..tostring(mapsFileTable))
			
			--check if the file is in the data table and is the latest version
			for i=1, #mapsFileTable do
				if mapsFileTable[i] ~= nil and mapsFileTable[i].path == file:getPath() then
					loadFileData = false
					if mapsFileTable[i].time ~= file:getLastWriteTime() then
						if mapsFileTable[i].hash == file:getHash() then
							--the map has not change only the time stamp is different
							mapsFileTable[i].time = file:getLastWriteTime()
						else
							--file time and the hash don't match the map information need to be reloaded
							loadFileData = true
							print("remove map info: "..i)
							if mapsFileTable[i] and mapsFileTable[i].icon then
								File(mapsFileTable[i].icon):remove()
							end
							table.remove( mapsFileTable, i )
							
							mapConfig:get("data"):setTable(maps)
							mapConfig:save()
						end
					end	
					--break
					i = #mapsFileTable + 2
					--print("Path was found. ")
					--if loadFileData then
					--	print("Data will be reloaded")
					--end
				end
			end
			
			if loadFileData then
				--print("Load map informatio: "..file:getPath())
				--update info
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
							--print("Next image name: "..imageName)
						end
						
						local tmpFile = File("Data/Dynamic/"..imageName)
						if tmpFile:exist() then
							abort()
						end
						
						--print("save to file: ".."Data/Dynamic/"..imageName)
						
						iconFile:saveToFile(imageName)	
						imageName = "Data/Dynamic/" .. imageName
					end
					
					updateCount = updateCount + 1				
					
					--print("File found\n")
					local info = totable( mapInfo:getContent() )
					local mapTable = {}
					mapTable.mapSize = info.mapSize
					mapTable.gameMode = info.gameMode
					mapTable.players = info.players and info.players or 1
					mapTable.time = file:getLastWriteTime()
					mapTable.icon = imageName
					mapTable.hash = file:getHash()
					mapTable.path = file:getPath()
					mapTable.difficultyBase = info.difficultyMin
					mapTable.difficultyIncreaseMax = info.difficultyMax
					mapTable.waveCount = info.waveCount
					
					
					--print("File table: table = "..tostring(mapTable))
					--print("File: "..file:getPath())
					
					maps = mapConfig:get("data"):getTable()
					mapsFileTable = maps[fileName]
					if not mapsFileTable then
						mapsFileTable = {}
						maps[fileName] = mapsFileTable
					end
			
					mapsFileTable[#mapsFileTable + 1] = mapTable
					
					mapConfig:get("data"):setTable(maps)
				mapConfig:save()
				--else
				--	print("no file found")
				end
			end
			
			if updateCount%2 == 0 then
				return true
			end
		end
	end
	
	if #folders >= folderIndex then
		local mapFolder = File(folders[folderIndex])
		files = mapFolder:getFiles()
		
		--print("Folders: "..tostring(folders))
		--print("current folder index: "..folderIndex)
		--print("Change folder: "..folders[folderIndex])
		--print("Files found: "..#files)
		
		folderIndex = folderIndex + 1
		index = 1
		return true
	end
	
	if updateCount > 0 then
		mapConfig:get("data"):setTable(maps)
		mapConfig:save()	
	end
	
	return false
end