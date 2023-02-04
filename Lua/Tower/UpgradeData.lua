

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
	
	
	function self.getStats()
		return stats
	end
	
	function self.getLevel()
		return level
	end
	
	function self.getCost(level)
		return cost[level]
	end	
	
	function self.getMaxLevel()
		return maxLevel
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
	
	
	function self.setLevel(newlevel)
		level = newlevel
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
	end
	
	return self
end