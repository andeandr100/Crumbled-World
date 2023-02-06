
function split(str,sep)
	local array = {}
	local size = 0
	local reg = string.format("([^%s]+)",sep)
	for mem in string.gmatch(str,reg) do
		table.insert(array, mem)
		size = size + 1
	end	
	return array, size
end

UpgradeData = {}
function UpgradeData.new()
	local self = {}
	local name = ""
	local info = ""
	local level = 0
	local maxLevel = 0
	local cost = {}
	local iconId = 0
	local stats= {}
	local timeout = -1
	local supportTowerIndexes = {} --List of support towers that has the max level support bonus active on this tower
	local changedLevelCallback = nil
	local achievementName = nil
	
	function self.getStats()
		return stats
	end
	
	function self.getStatValue(statName)
		return stats[statName] and stats[statName][level] or nil
	end
	
	function self.getLevel()
		return level
	end
	
	function self.getCost(level)
		return cost[level]
	end	
	
	function self.getValueInGold()
		local goldValue = 0
		for i=1, level do
			goldValue = goldValue + ( cost[i] and cost[i] or 0 )
		end
		return goldValue
	end
	
	function self.getMaxLevel()
		return maxLevel
	end	
	
	function self.getAchievement()
		return achievementName
	end
	
	function self.getName()
		return name
	end	
	
	function self.getIconId()
		return iconId
	end	
	
	function self.getInfo()
		return info
	end	
	
	function self.getSupportTowerIndex()
		return supportTowerIndexes
	end	
	
	function self.setSupportTowerIndex(towerIndexes)
		supportTowerIndexes = towerIndexes
	end	
	
	
	function self.setLevel(newlevel)
		level = newlevel
		
		if changedLevelCallback then
			changedLevelCallback()
		end
	end	
	
	--Function used to temporary activate one level above
	function self.activate()
		timeout = Core.getGameTime() + 10
	end
	
	function self.isActive()
		return Core.getGameTime() < timeout
	end
	
	
	function self.init(data)
		name = data.name
		info = data.info
		level = data.level
		maxLevel = data.maxLevel
		cost = data.cost
		iconId = data.iconId
		stats = data.stats
		achievementName = data.achievementName
		changedLevelCallback = data.callback
	end
	
	return self
end