require("NPC/state.lua")
--this = SceneNode()
local soulManager

SoulManager = {}
function SoulManager.new()
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
	local function expand(isX,toAmount)
		if isX then
			if toAmount<0 then
				if toAmount<minX then
					for x=minX-1, toAmount, -1 do
						for y=minY, maxY do
							billboard:setString("souls"..x.."/"..y,"")
							soulTableStr[x] = soulTableStr[x] or {}
							soulTableStr[x][y] = ""
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
							soulTableStr[x][y] = ""
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
							soulTableStr[x][y] = ""
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
							soulTableStr[x][y] = ""
						end
					end
					maxY = math.clamp(toAmount,maxX,16)
					billboard:setVec2("max",Vec2(maxX,maxY))
				end
			end
		end
	end
	local function updateSoulsTable()
		local str = ""
		local count = 0
		
		
		for x=minX, maxX do
			for y=minY, maxY do
				soulTableStr[x][y] = ""
			end
		end
		for index,soul in pairs(soulTable) do
			if soul.team==0 then
				local x = math.floor(soul.position.x/8.0)
				local y = math.floor(soul.position.z/8.0)
				--Core.addDebugLine(Vec3(x*8.0,0,y*8.0),Vec3(x*8.0,5.0,y*8.0),0.05,Vec3(1))
				expand(true,x)
				expand(false,y)
				if soulTableStr[x][y]:len()==0 then
					soulTableStr[x][y] = string.format("%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%d,%d,%d,%d,%d,%s",index,
					soul.position.x,soul.position.y,soul.position.z,
					soul.velocity.x,soul.velocity.y,soul.velocity.z,
					soul.distanceToExit,soul.hp,soul.hpMax,soul.team,soul.state,soul.name)
				else
					soulTableStr[x][y] = string.format("%s|%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%d,%d,%d,%d,%d,%s",soulTableStr[x][y],index,
					soul.position.x,soul.position.y,soul.position.z,
					soul.velocity.x,soul.velocity.y,soul.velocity.z,
					soul.distanceToExit,soul.hp,soul.hpMax,soul.team,soul.state,soul.name)
				end
				count = count + 1
			end
		end
		billboard:setInt("npcsAlive",count)
		for x=minX, maxX do
			for y=minY, maxY do
				billboard:setString("souls"..x.."/"..y,soulTableStr[x][y])
			end
		end
	end
	
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
	function self.updateSoul(paramHp, fromIndex)
		local soul = soulTable[fromIndex]
		if soul then
			local billboard = Core.getBillboard(fromIndex)
			if billboard then
				local mover = billboard:getNodeMover("nodeMover")
				soul.position = mover:getCurrentPosition()+soul.aimHeight
				soul.velocity = mover:getCurrentVelocity()
				soul.distanceToExit = mover:getDistanceToExit()
			end
			soul.hp = paramHp
		end
	end
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

	local function restartMap()
		comUnit:clearMessages()
		soulTable = {}
		shieldGenerators = {}
		updateSoulsTable()
	end

	local function init()
		for x=minX, maxX do--for x=-16, 16 do
			soulTableStr[x] = {}
			for y=minY, maxY do--for y=-16, 16 do
				soulTableStr[x][y] = ""
				billboard:setString("souls"..x.."/"..y,"")
			end
		end
		billboard:setString("shieldGenerators","")
		billboard:setVec2("min",Vec2(minX,minY))
		billboard:setVec2("max",Vec2(maxX,maxY))
	
		comUnit:setName("SoulManager")
		comUnit:setCanReceiveTargeted(true)
		comUnitTable["addSoul"] = self.addSoul
		comUnitTable["update"] = self.updateSoul
		--comUnitTable["updateMovment"] = self.updateMovment
		comUnitTable["setState"] = self.updateState
		comUnitTable["remove"] = self.remove
		--
		restartListener = Listener("Restart")
		restartListener:registerEvent("restart", restartMap)
	end
	init()
	
	return self
end

function destroy()
	if soulManager then
		soulManager.destroy()
	end
	soulManager = nil
end
function create()
	soulManager = SoulManager.new()
	return true
end
function update()
	soulManager.update()
	return true
end