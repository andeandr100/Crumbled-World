TimedValues = {}
function TimedValues.new()
	local self = {}
	local size = 0
	local table = {}
	local maxKey
	
	local function updateEdgeKeys()
		maxKey = nil
		local maxVal = 0
		for key,val in pairs(table) do
			if not maxKey or val.key>maxVal then
				maxKey = key
				maxVal = val.key
			end
		end
	end
	function self.set(pKey,value)
		local item = table[tostring(pKey)]
		if item==nil then
			table[tostring(pKey)] = {key=pKey, val=value}
			size = size + 1
			updateEdgeKeys()
		elseif item.val<value then
			item.val = value
		end
	end
	function self.getValue(key)
		local item = table[tostring(key)]
		return item and item.val or 0.0
	end
	function self.existKey(key)
		return table[tostring(key)]~=nil
	end
	function self.clear()
		size = 0
		table = {}
	end
	local function remove(key)
		table[key] = nil
		size = size - 1
		updateEdgeKeys()
	end
	function self.getTable()
		return table
	end
	function self.getMaxKey()
		if maxKey then
		end
		return (maxKey and table[maxKey]) and table[maxKey].key or 0.0
	end
	function self.getMaxValue()
		return (maxKey and table[maxKey]) and table[maxKey].val or 0.0
	end
	function self.isNotEmpty()
		for key,val in pairs(table) do
			return true
		end
		return false
	end
	function self.isEmpty()
		return not self.isNotEmpty()
	end
	function self.update()
		local deltaTime = Core.getDeltaTime()
		for key,val in pairs(table) do
			val.val = val.val - deltaTime
			if val.val<0.0 then
				remove(key)
			end
		end
	end
	return self
end