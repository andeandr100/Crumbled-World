projectileManager = {}
function projectileManager.new()
	local self = {}
	
	local notInUse = {}		--projectiles is stored here for fast reuse to a lower cost then creating a new projectile
	local inUse = {size=0}	--projectiles that are in transit to there destinations
	
	-- function:	launch
	-- purpose:		Launches a new projectile with param as setting
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
	-- function:	destroy
	-- purpose:		deletes all projectiles and all there asosiated memories (should only be used when destroying the script)
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
	-- function:	getSize
	-- purpose:		returns how many projectiles that are in transit
	function self.getSize()
		return inUse.size
	end
	-- function:	removeProjectile
	-- purpose:		removes a single active projectile
	local function removeProjectile(index)
		local notInUseItem = notInUse[inUse[index].projectileName]
		notInUseItem.size = notInUseItem.size + 1
		notInUseItem[notInUseItem.size] = inUse[index]
		if index~=inUse.size then
			inUse[index] = inUse[inUse.size]
		end
		inUse.size = inUse.size - 1
	end
	-- function:	clear
	-- purpose:		removes all active projectils, and allows them to be used for future ueses
	function self.clear()
		local i=inUse.size
		while i>0 do
			removeProjectile(i)
			i = i - 1
		end
	end
	-- function:	update
	-- purpose:		updated all active projectiles, and removes any that has reached its end
	function self.update()
		local i=1
		while i<=inUse.size do
			if inUse[i].update()==false then
				removeProjectile(i)
				i = i - 1
			end
			i = i + 1
		end
		return (inUse.size>0)
	end
	-- function:	netSync
	-- purpose:
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