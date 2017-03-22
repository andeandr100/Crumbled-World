projectileManager = {}
function projectileManager.new()
	local self = {}
	
	local notInUse = {}
	local inUse = {size=0}
	
	function self.launch(projectile,param)
		local name = projectile.name
		--make sure the projectile has a base list
		notInUse[name] = notInUse[name] or {size=0}
		local notUsed = notInUse[name]
		--make sure that there use atleast one item left in the list
		if notUsed.size==0 then
			notUsed[1] = projectile.new()
			notUsed[1].projectileName = name
			notUsed.size=1
		end
		--use the last projectile in list
		inUse.size = inUse.size + 1
		inUse[inUse.size] = notUsed[notUsed.size]
		inUse[inUse.size].init(param)
		notUsed.size = notUsed.size - 1
	end
	function self.destroy()
		for i=1, inUse.size do
			if inUse[i].destroy then
				inUse[i].destroy()
			end
		end
		inUse = nil
		for key,value in ipairs(notInUse) do--loop all names
			for i=1, notInUse.size do--loop all items
				if notInUse[i].destroy then
					notInUse[i].destroy()
				end
			end
		end
		notInUse = nil
	end
	function self.getSize()
		return inUse.size
	end
	function self.update()
		local i=1
		while i<=inUse.size do
			if inUse[i].update()==false then
				local notInUseItem = notInUse[inUse[i].projectileName]
				notInUseItem.size = notInUseItem.size + 1
				notInUseItem[notInUseItem.size] = inUse[i]
				if i~=inUse.size then
					inUse[i] = inUse[inUse.size]
					i = i - 1--we removed this an item from this pos, and must now update the same position aagain
				end
				inUse.size = inUse.size - 1
			end
			i = i + 1
		end
		return (inUse.size>0)
	end
	function self.netSync(name,table)
		local i=1
		while i<=inUse.size do
			if inUse[i].getProjectileNetName and inUse[i].netSync and inUse[i].getProjectileNetName()==name then
				inUse[i].netSync(table)
				i = inUse.size
			end
			i = i + 1
		end
	end
	
	return self
end