require("Game/campaignData.lua")
require("Game/mapInfo.lua")
--this = SceneNode()
CampaignTowerUpg = {}
function CampaignTowerUpg.new(pTowerFile,pUpgrade)
	local self = {}
	local cData = CampaignData.new()
	local mapInfo = MapInfo.new()
	local towerFile = pTowerFile
	local upgCallback = {}
	local upgrade = pUpgrade
	
	function self.getLevelRequierment(upgName,level)
		if cData.getBoughtUpg(towerFile,upgName,false)>=cData.getBuyablesTotal(upgName,false) then
			return level
		end
		return (cData.getBoughtUpg(towerFile,upgName,false)>=level or mapInfo.isCampaign()==false) and level or 4
	end
	function self.isPermUpgraded(upgName,level)
		return mapInfo.isCampaign() and cData.getBoughtUpg(towerFile,upgName,true)>=level
	end
	function self.addUpg(upgName,callback)
		assert(type(callback)=="function", "CampaignTowerUpg.addUpg(upgName,callback) \"callback\" must be a function")
		upgCallback[upgName] = callback
	end
	function self.fixAllPermBoughtUpgrades()
		local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
		if isThisReal then
			if mapInfo.isCampaign() then
				local currentLevel = upgrade.getLevel("upgrade")
				print("currentLevel=="..currentLevel)
				for upgName,func in pairs(upgCallback) do
					print("upgName = "..upgName.."("..type(func)..").isPermUpgraded = "..tostring(self.isPermUpgraded(upgName,currentLevel)))
					if self.isPermUpgraded(upgName,currentLevel) then
						upgrade.addFreeSubUpgrade()--because it is a free upgrade
						func( "1" )
						--upgrade.removeFreeSubUpgrade()
					end
				end
			end
		end
	end
	return self
end