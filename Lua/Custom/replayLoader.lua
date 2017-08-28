require("Game/mapInfo.lua")
require("Game/campaignData.lua")
require("Menu/MainMenu/mapInformation.lua")

local files = nil

function getMapIndex(filePath)
	for i=1, #files do	
		local file = files[i].file
		if file:isFile() and file:getPath()==filePath then
			return i
		end
	end
	return 0
end

function create()
	
	
	
	return true
end

function update()
	
	local levelInfo = MapInfo.new()
	local campaignData = CampaignData.new()
	files = campaignData.getMaps()
	local filePath = Core.getGlobalBillboard("highScoreReplay"):getString("filePath")
	local difficulty = Core.getGlobalBillboard("highScoreReplay"):getInt("difficulty")
	local mapFile = File(filePath)
	
	print("filePath: "..filePath)
	
	local mNum = getMapIndex(filePath)
	
	print("mapIndex: "..mNum)
	
	levelInfo.setIsCampaign(true)
	levelInfo.setMapNumber(mNum)
	levelInfo.setSead(files[mNum].sead)
	levelInfo.setMapFileName(filePath)
	levelInfo.setMapName(mapFile:getName())
	if mapFile:isFile() then
		local mapInfo = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
		if mapInfo then
			levelInfo.setIsCartMap(mapInfo.gameMode=="Cart")
		end
		if mapInfo then
			levelInfo.setChangedDifficultyMax(mapInfo.difficultyIncreaseMax)
			levelInfo.setChangedDifficultyMin(mapInfo.difficultyIncreaseMin)
			levelInfo.setWaveCount(mapInfo.waveCount)
		end
	end
	levelInfo.setLevel(difficulty)
	files = nil
	
	return true
end