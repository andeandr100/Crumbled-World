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
	function self.getIsPermUpgraded(upgName,level)
		return mapInfo.isCampaign() and cData.getBoughtUpg(towerFile,upgName,true)>=level
	end
	function self.addUpg(upgName,callback)
		upgCallback[upgName] = callback
	end
	function self.fixAllPermBoughtUpgrades()
		if mapInfo.isCampaign() then
			local currentLevel = upgrade.getLevel("upgrade")
			for upgName,func in pairs(upgCallback) do
				if (upgName=="shieldBreaker" or upgName=="shieldSmasher") then
					if upgrade.getLevel("upgrade")==3 and self.getIsPermUpgraded(upgName,1) then
						upgrade.addFreeSubUpgrade()--because it is a free upgrade
						func( tostring(upgrade.getLevel(upgName)+1) )
						--upgrade.removeFreeSubUpgrade()
					end
				else
					if self.getIsPermUpgraded(upgName,currentLevel) then
						upgrade.addFreeSubUpgrade()--because it is a free upgrade
						func( tostring(upgrade.getLevel(upgName)+1) )
						--upgrade.removeFreeSubUpgrade()
					end
				end
			end
		end
	end
	return self
end