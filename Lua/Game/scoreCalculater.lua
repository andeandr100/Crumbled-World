require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/graphDrawer.lua")
require("Game/mapInfo.lua")
require("Game/campaignData.lua")
require("Game/soundManager.lua")
--this = SceneNode()
local campaignData = CampaignData.new()
local files = campaignData.getMaps()
local mapInfo = MapInfo.new()


ScoreCalculater = {
	getScoreLimits = function()
		currentMapData = files[mapInfo.getMapNumber()]
		local diffPerLevelBase = math.floor( ((currentMapData.maxScore-currentMapData.minScore)*0.3)/1000 )
		diffPerLevelBase = math.clamp(diffPerLevelBase, 2, 8)
		local diffPerLevel = diffPerLevelBase*1000
		local scoreLimits = {
			{score=0, 										index=1, name="none", minPos=Vec2(0.25,0.75),		maxPos=Vec2(0.5,0.8125), 	color=Vec3(0.65,0.65,0.65)},
			{score=currentMapData.minScore, 				index=2, name="copper", minPos=Vec2(0.0,0.5625),	maxPos=Vec2(0.25,0.625), 	color=Vec3(0.86,0.63,0.38)},
			{score=currentMapData.maxScore-diffPerLevel,	index=3, name="silver", minPos=Vec2(0.0,0.625),		maxPos=Vec2(0.25,0.6875), 	color=Vec3(0.64,0.70,0.73)},
			{score=currentMapData.maxScore,					index=4, name="gold", minPos=Vec2(0.0,0.6875),		maxPos=Vec2(0.25,0.75), 	color=Vec3(0.93,0.73,0.13)},
			{score=currentMapData.maxScore+diffPerLevel,	index=5, name="dimond", minPos=Vec2(0.0,0.75),		maxPos=Vec2(0.25,0.8125), 	color=Vec3(0.5,0.92,0.92)}
		}
		return scoreLimits
	end,
	getScoreItemOnName = function(name)
		local scoreLimits = ScoreCalculater.getScoreLimits()
		for i=#scoreLimits, 1, -1 do
			if scoreLimits[i].name==name then
				return scoreLimits[i]
				
			end
		end
		return nil
	end,
	getScoreItemOnScore = function(score)
		local scoreLimits = ScoreCalculater.getScoreLimits()
		for i=#scoreLimits, 1, -1 do
			if score>=scoreLimits[i].score then
				return scoreLimits[i]
			end
		end
		return nil
	end
}