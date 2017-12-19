require("NPC/state.lua")
--this = SceneNode()
local soulManager

SoulManager = {}
function SoulManager.new()
	local EXPANDX = true
	local EXPANDY = false
	
--	local debug = {
--		zoneColors = {}
--	}
	local self = {}
	local comUnit = Core.getComUnit()
	local billboard = comUnit:getBillboard()
	local comUnitTable = {}
	local soulTable = {}
	local shieldGenerators = {}
	local binaryNumPos = {[1]=1,[2]=2,[4]=3,[8]=4,[16]=5,[32]=6,[64]=7,[128]=8,[256]=9}
	local shieldStateNumPos = binaryNumPos[state.shieldGenerator]
	local minX = -1
	local maxX = 1
	local minY = -1
	local maxY = 1
	local soulTableStr = {}
	
	function self.getDebug()
		return debug
	end
	function self.getLimits()
		return {minX=minX, maxX=maxX, minY=minY, maxY=maxY}
	end
	
	local function toBits(num)
		local t={}
		while num>0 do
			rest=math.fmod(num,2)
			t[#t+1]=rest
			num=(num-rest)/2
		end
		for i=#t+1, 16 do
			t[i]=0
		end
		return t
	end
	
	function self.destroy()
		billboard:clear()
		soulTable = {}
		shieldGenerators = {}
	end
	
	-- function:	updateShieldGenTable
	-- purpose:		Updates the global list of all enemies that are shield generators (turtle)
	local function updateShieldGenTable()
		local str = ""
		local count = 0
		for index,isSet in pairs(shieldGenerators) do
			local soul = soulTable[index]
			if soul then
				if count==0 then
					str = string.format("%d,%.2f,%.2f,%.2f",index,soul.position.x,soul.position.y,soul.position.z)
				else
					str = string.format("%s|%d,%.2f,%.2f,%.2f",str,index,soul.position.x,soul.position.y,soul.position.z)
				end
				count = count + 1
			end
		end
		billboard:setString("shieldGenerators",str)
	end
	-- function:	expand
	-- purpose:		Expands the area where enemies can exist
	local function expand(isX,toAmount)
		if isX then
			if toAmount<0 then
				if toAmount<minX then
					for x=minX-1, toAmount, -1 do
						for y=minY, maxY do
							billboard:setString("souls"..x.."/"..y,"")
							soulTableStr[x] = soulTableStr[x] or {}
							soulTableStr[x][y] = soulTableStr[x][y] or {}
--							if debug then
--								debug.zoneColors[x] = debug.zoneColors[x] or {}
--								debug.zoneColors[x][y] = debug.zoneColors[x][y] or math.randomVec3()
--							end
						end
					end
					minX = toAmount
					billboard:setVec2("min",Vec2(minX,minY))
				end
			else
				if toAmount>maxX then
					for x=maxX, toAmount, 1 do
						for y=minY, maxY do
							billboard:setString("souls"..x.."/"..y,"")
							soulTableStr[x] = soulTableStr[x] or {}
							soulTableStr[x][y] = soulTableStr[x][y] or {}
--							if debug then
--								debug.zoneColors[x] = debug.zoneColors[x] or {}
--								debug.zoneColors[x][y] = debug.zoneColors[x][y] or math.randomVec3()
--							end
						end
					end
					maxX = math.clamp(toAmount,maxX,16)
					billboard:setVec2("max",Vec2(maxX,maxY))
				end
			end
		else
			if toAmount<0 then
				if toAmount<minY then
					for y=minY-1, toAmount, -1 do
						for x=minX, maxX do
							billboard:setString("souls"..x.."/"..y,"")
							soulTableStr[x] = soulTableStr[x] or {}
							soulTableStr[x][y] = soulTableStr[x][y] or {}
--							if debug then
--								debug.zoneColors[x] = debug.zoneColors[x] or {}
--								debug.zoneColors[x][y] = debug.zoneColors[x][y] or math.randomVec3()
--							end
						end
					end
					minY = toAmount
					billboard:setVec2("min",Vec2(minX,minY))
				end
			else
				if toAmount>maxY then
					for y=maxY, toAmount, 1 do
						for x=minX, maxX do
							billboard:setString("souls"..x.."/"..y,"")
							soulTableStr[x] = soulTableStr[x] or {}
							soulTableStr[x][y] = soulTableStr[x][y] or {}
--							if debug then
--								debug.zoneColors[x] = debug.zoneColors[x] or {}
--								debug.zoneColors[x][y] = debug.zoneColors[x][y] or math.randomVec3()
--							end
						end
					end
					maxY = math.clamp(toAmount,maxX,16)
					billboard:setVec2("max",Vec2(maxX,maxY))
				end
			end
		end
	end
	-- function:	updateSoulsTable
	-- purpose:		Updated the billboard with all npc that can be targeted
	local function updateSoulsTable()
		local str = ""
		local count = 0
		
		--clear local soulTable
		for x=minX, maxX do
			for y=minY, maxY do
				soulTableStr[x][y] = {}
			end
		end
		--rebuild local soulTable
		for index,soul in pairs(soulTable) do
			if soul.team==0 then
				local x = math.floor(soul.position.x/8.0)
				local y = math.floor(soul.position.z/8.0)
				--make sure the table is big enough
				expand(EXPANDX,x)
				expand(EXPANDY,y)
				--DEBUG BEG
--				if debug then
--					local sPos = soul.position
--					Core.addDebugLine(sPos, sPos+Vec3(0,2.0,0), 0.05, debug.zoneColors[x][y] or Vec3(1))
--				end
				--DEBUG END
				local grid = soulTableStr[x][y]
				grid[#grid+1] = {index,
					soul.position.x,soul.position.y,soul.position.z,
					soul.velocity.x,soul.velocity.y,soul.velocity.z,
					soul.distanceToExit,soul.hp,soul.hpMax,soul.team,soul.state,soul.name}
				count = count + 1
			end
		end
		--publish the soulTable to the world
		billboard:setInt("npcsAlive",count)
		for x=minX, maxX do
			for y=minY, maxY do
				if soulTableStr[x][y] then
					billboard:setString("souls"..x.."/"..y,tabToStrMinimal(soulTableStr[x][y]))
				else
					billboard:setString("souls"..x.."/"..y,"{}")
				end
			end
		end
	end
	
	-- function:	addSoul
	-- purpose:		Adds a soul to the table to be updated in the future
	function self.addSoul(param, fromIndex)
		soulTable[fromIndex] = {position=param.pos,
								velocity=Vec3(),
								distanceToExit=256.0,
								hp=param.hpMax,
								hpMax=param.hpMax,
								name=param.name,
								team=param.team,
								aimHeight=param.aimHeight or Vec3(0),
								state=0}
		self.update(param.hpMax,fromIndex)
	end
	-- function:	updateSoul
	-- purpose:		updates an existing soul on the table
	function self.updateSoul(paramHp, fromIndex)
		local soul = soulTable[fromIndex]
		if soul then
			local billboard = Core.getBillboard(fromIndex)
			if billboard then
				local mover = billboard:getNodeMover("nodeMover")
				if mover then
					soul.position = mover:getCurrentPosition()+soul.aimHeight
					soul.velocity = mover:getCurrentVelocity()
					soul.distanceToExit = mover:getDistanceToExit()
				else
					--something is wrong kill that npc
					Core.getComUnit():sendTo(fromIndex,"attack","100000000")
				end
			end
			soul.hp = paramHp
		end
	end
	-- function:	updateState
	-- purpose:		updates an existing souls state on the table
	function self.updateState(param, fromIndex)
		if soulTable[fromIndex] then
			soulTable[fromIndex].state = param
			if toBits(param)[shieldStateNumPos]==1 then
				if not shieldGenerators[fromIndex] then
					shieldGenerators[fromIndex]=true
					updateShieldGenTable()
				end
			end
		end
	end
	-- function:	remove
	-- purpose:		removes the soul from the table
	function self.remove(param,fromIndex)
		--if soulTable[fromIndex]==nil then
		--	error("removing dead npc??")
		--end
		soulTable[fromIndex] = nil
		if shieldGenerators[fromIndex] then
			shieldGenerators[fromIndex] = nil
			updateShieldGenTable()
		end
	end
	
	function self.update()
		--Handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
		 	   comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		--
		updateShieldGenTable()
		updateSoulsTable()
		--billboard:setString("souls",tostring(soulTable.souls))
	end

	-- function:	clearData
	-- purpose:		removes all souls from the table
	local function clearData()
		comUnit:clearMessages()
--		--kill all NPCs
--		for index,soul in pairs(soulTable) do
--			if soul.team==0 then
--				comUnit:sendTo(index,"disappear","")
--			end
--		end
		--remove them
		soulTable = {}
		shieldGenerators = {}
		--update it to billboard
		updateSoulsTable()
	end

	local function init()
		for x=minX, maxX do--for x=-16, 16 do
			soulTableStr[x] = {}
			for y=minY, maxY do--for y=-16, 16 do
				soulTableStr[x][y] = ""
				billboard:setString("souls"..x.."/"..y,"")
--				if debug then
--					debug.zoneColors[x] = debug.zoneColors[x] or {}
--					debug.zoneColors[x][y] = math.randomVec3()
--				end
			end
		end
		billboard:setString("shieldGenerators","")
		billboard:setVec2("min",Vec2(minX,minY))
		billboard:setVec2("max",Vec2(maxX,maxY))
	
		comUnit:setName("SoulManager")
		comUnit:setCanReceiveTargeted(true)
		comUnitTable["addSoul"] = self.addSoul
		comUnitTable["update"] = self.updateSoul
		comUnitTable["setState"] = self.updateState 
		comUnitTable["remove"] = self.remove
		--
		restartListener = Listener("Restart")
		restartListener:registerEvent("restart", clearData)
		--
		restartListener = Listener("RestartWave")
		restartListener:registerEvent("restartWave", clearData)
	end
	init()
	
	return self
end

function displayDebugSquare(x,y)
	for x1=0, 8 do
		local xx = (x1==0 and 0.1) or (x1==8 and 7.9) or x1
		local pos1 = Vec3(xx+(x*8), 0, 0.1+(y*8))
		local pos2 = Vec3(xx+(x*8), 0, 7.9+(y*8))
		local d1 = soulManager.getDebug()
		Core.addDebugLine(pos1,pos1+Vec3(0,2,0),0.1,soulManager.getDebug().zoneColors[x][y])
		Core.addDebugLine(pos2,pos2+Vec3(0,2,0),0.1,soulManager.getDebug().zoneColors[x][y])
	end
	for y1=0, 8 do
		local yy = (y1==0 and 0.1) or (y1==8 and 7.9) or y1
		local pos1 = Vec3(0.1+(x*8), 0, yy+(y*8))
		local pos2 = Vec3(7.9+(x*8), 0, yy+(y*8))
		Core.addDebugLine(pos1,pos1+Vec3(0,2,0),0.1,soulManager.getDebug().zoneColors[x][y])
		Core.addDebugLine(pos2,pos2+Vec3(0,2,0),0.1,soulManager.getDebug().zoneColors[x][y])
	end
end

function destroy()
	if soulManager then
		soulManager.destroy()
	end
	soulManager = nil
end
function create()
	
	--Protection in multiplayer environment where multiple instances of this script is loaded
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	if ( node == nil and this:getSceneName() ~= "soulManager" ) or ( node and node:getClientId() ~= 0 ) then
		return false
	end
	--Core.setUpdateHz(60)
	
	if this:getNodeType() == NodeId.playerNode then
		local menuNode = this:getRootNode():addChild(SceneNode())
		--camera = Camera()
		menuNode:setSceneName("soulManager")
		menuNode:createWork()
				
		--Move this script to the world node
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		return false
	else
		soulManager = SoulManager.new()
	end
	return true
end
function update()
--	Core.addDebugLine(Vec3(0,0,0),Vec3(0,4,0),0.1,Vec3(1,1,0))
--	local limits = soulManager.getLimits()
--	for x=limits.minX, limits.maxX do
--		for y=limits.minY, limits.maxY do
--			displayDebugSquare(x,y)
--		end
--	end
	soulManager.update()
	return true
end