Stats = {}
function Stats.new()
	local self = {}
	local current
	local cfg = Config("TowerStats")
	local function getChild(name,value)
		current = current:get(name,value)
	end
	local function set(value,amount)
		local cVal = current:getFloat()
		cVal = (cVal*amount)+(value*(1.0-amount))
		current:setFloat(cVal)
	end
	local function add(value)
		local cVal = current:getFloat()
		cVal = cVal+value
		current:setFloat(cVal)
	end
	function self.setValue(table,value)--wave,tower,keyWord,value
		current = cfg
		for i=1, #table, 1 do
			if i~=#table then
				getChild(table[i],value)
			else
				local sampleSize = math.max(1,current:get("sampleSize",0):getFloat())
				getChild(table[i],value)
				set(value,sampleSize/(sampleSize+1))
			end
		end
	end
	function self.addValue(table,value)
		--print("stats.addValue(table,value)\n")
		current = cfg
		for i=1, #table, 1 do
			if i~=#table then
				getChild(table[i],0)
			else
				getChild(table[i],0)
				add(value)
			end
		end
	end
	
	function self.save()
		if DEBUG then
			cfg:save()
		end
	end
	local function getTableAdd(table)
		if #table==0 then
			return 0
		end
		local val=0
		for i=1, #table do
			val = val + table[i]
		end
		return val
	end
	local function getTableAverage(table)
		return getTableAdd(table)/#table
	end
	return self
end
--function spairs(t, order)
--	-- collect the keys
--	local keys = {}
--	for k in pairs(t) do keys[#keys+1] = k end
--
--	-- if order function given, sort by it by passing the table and keys a, b,
--	-- otherwise just sort the keys 
--	if order then
--		table.sort(keys, function(a,b) return order(t, a, b) end)
--	else
--		table.sort(keys)
--	end
--
--	-- return the iterator function
--	local i = 0
--	return function()
--		i = i + 1
--		if keys[i] then
--			return keys[i], t[keys[i]]
--		end
--	end
--end

