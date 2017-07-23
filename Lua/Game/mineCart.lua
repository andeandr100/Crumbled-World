require("Game/targetSelector.lua")
--this = Model()
local points = {}
local numPoints = 0
local index = 1
local offset = 0
local maxSpeed = 1.75
local currentSpeed = 0
local moveBackTime = 15
local NUMNPCFORMAXSPEED = 5
local slowTimerUpdate = 0.0	--when to send the slow info (this is to minimize com message spaming)
--Lost game data
local lostTheGame = false
local fallVelocity = Vec3()
local fallDirection = Vec3()
local fallAtDirection = Vec3()
--Acievement
local untouched = true
--comunit
local comUnit
local comUnitTable = {}
local waveTable = {}

local billboard
local wheel1,wheel2

local activeTeam = 1
local targetSelector

--local lostTIme

function clearWavesAfter(wave)
	local index = wave+1
	while waveTable[index] do
		waveTable[index] = nil
		index = index + 1
	end
end
function storeWaveChangeStats( wave )
	--update wave stats only if it has not been set (this function will be called on wave changes when going back in time)
	if not waveTable[wave] then
		waveTable[wave] = {
			index = index,
			moveBackTime = moveBackTime,
			currentSpeed = currentSpeed,
			offset = offset,
			mat = this:getLocalMatrix()
		}
	end
end
function restoreWaveChangeStats( wave )
	if wave>0 then
		--we have gone back in time erase all tables that is from the future, that can never be used
		clearWavesAfter(wave)
		--restore the stats from the wave
		local tab = waveTable[wave]
		index = tab.index
		moveBackTime = tab.moveBackTime
		currentSpeed = tab.currentSpeed
		offset = tab.offset
		this:setLocalMatrix(tab.mat)
	end
end
function restartWave(param)
	restoreWaveChangeStats( tonumber(param) )
end

function waveChanged(param)
	local name
	local waveCount
	name,waveCount = string.match(param, "(.*);(.*)")
	--
	storeWaveChangeStats( tonumber(waveCount)+1 )
end

function restartMap()
	index = 1
	offset = 0
	currentSpeed = 0
	slowTimerUpdate = 0.0
	fallVelocity = Vec3()
	fallDirection = Vec3()
	fallAtDirection = Vec3()
	lostTheGame = false
	update = mainUpdate
	this:setLocalMatrix(startMatrix)
	--we have gone back in time erase all tables that is from the future, that can never be used
	clearWavesAfter(0)
end

function create()
	targetSelector = TargetSelector.new(activeTeam)
	comUnit = Core.getComUnit()
	comUnit:setName("mineCart")
	comUnit:setCanReceiveBroadcast(true)
	comUnit:setCanReceiveTargeted(false)
	comUnit:setPos(this:getGlobalPosition())
	comUnitTable["waveChanged"] = waveChanged
	billboard = comUnit:getBillboard()
	
	restartWaveListener = Listener("RestartWave")
	restartWaveListener:registerEvent("restartWave", restartWave)
	
	local meshList = this:findAllNodeByTypeTowardsLeaf(NodeId.mesh)
	for  i=1, #meshList do
		meshList[i]:setLocalPosition(meshList[i]:getLocalPosition() - Vec3(0,0.1,0))
	end
	
	wheel1 = this:getMesh("wheel1")
	wheel2 = this:getMesh("wheel2")
	
	mainUpdate = update
	startMatrix = this:getLocalMatrix()
	
	restartListener = Listener("Restart")
	restartListener:registerEvent("restart", restartMap)
		
	
	return true
end

function init(inPoints)
	if type(inPoints)=="string" then
		points = totable(inPoints)
	else
		points = inPoints
	end
	numPoints = #points
end

function getNumNpcOnTheCart()
	targetSelector.setPosition(this:getGlobalPosition())
	targetSelector.setRange(2.2)
	targetSelector.selectAllInRange()
	
	--we have now selected all possible targets, even turtles with a shield that is not close enough to push the cart
	local targetsInRangeCount = 0
	local targets = targetSelector.getAllTargets()
	for index,score in pairs(targets) do
		if (this:getGlobalPosition()-targetSelector.getTargetPosition(index)):length()<2.5 then
			targetsInRangeCount = targetsInRangeCount + 1
		end
	end
	
	return targetsInRangeCount
end

function move(point1, point2, offset, moveDistance)
	
end
function updateDeathArea()
	cartDeathPosition = cartDeathPosition or this:getGlobalPosition()
	comUnit:broadCast(cartDeathPosition,1,"attack",tostring(1000000000))
	return true
end
function update()
	local numNpc = getNumNpcOnTheCart()
	if not lostTheGame then
		--Handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
				comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		--cart is still alive
		moveBackTime = moveBackTime - Core.getDeltaTime()
		--Achievement
		if numNpc==0 and moveBackTime+Core.getDeltaTime()+0.01>15 then
			local atVec = (points[index+1] - points[index])
			local pos = points[index] + atVec * offset
			local distance = 0
			distance = distance + (pos-points[index+1]):length()
			for i=index+1, numPoints-1 do
				distance = distance + (points[i]-points[i+1]):length()
			end
			if distance<=1.0 then
				comUnit:sendTo("SteamAchievement","ToClose","")
			end
		end
		if untouched and numNpc>0 then
			untouched = false
			comUnit:sendTo("stats","addBillboardInt","mineCartIsMoved;1")
		end
		--
		if currentSpeed > 0.1 or numNpc > 0 then
			if numNpc>0 then
				local accelerateOverXSec = 1.0/4.0--over 4.0s
				currentSpeed = math.clamp(currentSpeed + (maxSpeed*accelerateOverXSec*Core.getDeltaTime()),0,maxSpeed)
			else
				currentSpeed = currentSpeed * (1-Core.getDeltaTime())
			end
			moveBackTime = 15
			if index < numPoints then
				local moveDistance = currentSpeed * Core.getDeltaTime()
				local atVec = (points[index+1] - points[index])
				local distace = atVec:normalize()
				local nextAtVec = 	(index+1 < numPoints) and (points[index+2] - points[index+1]):normalizeV() or atVec
				
				local localMatrix = Matrix()
				localMatrix:createMatrix(math.interPolate(atVec, nextAtVec, math.clamp( (moveDistance + offset)/ distace,0,1)), Vec3(0,1,0))
				localMatrix:setPosition( points[index] + atVec * (moveDistance + offset) )
				this:setLocalMatrix(localMatrix)
				
				billboard:setVec3("position",this:getGlobalPosition())
				
				offset = offset + moveDistance
				
				if offset > distace then
					offset = offset - distace
					index = index + 1
				end
			end
			--rotating wheel
			local rotationThisFrame = Core.getDeltaTime()*2*math.pi*(currentSpeed/1.153)	--1.153=diameter*pi
			wheel1:rotate(Vec3(1,0,0),rotationThisFrame)
			wheel2:rotate(Vec3(1,0,0),rotationThisFrame)
			if index == numPoints then
				lostTheGame = true
				
				fallDirection = ((points[numPoints] - points[numPoints-1]):normalizeV() + Vec3(0,-0.3,0)):normalizeV()
				fallAtDirection = fallDirection
				fallVelocity = fallDirection * currentSpeed
			end
			
		elseif moveBackTime < 0 and (index > 1 or offset > 0) then
			currentSpeed = math.clamp(currentSpeed - (maxSpeed*0.2*Core.getDeltaTime()), -maxSpeed*0.2, 0.0)
			local moveDistance = currentSpeed * Core.getDeltaTime()
			local atVec = (points[index+1] - points[index])
			local distace = atVec:normalize()
			local nextAtVec = 	(index+1 < numPoints) and (points[index+2] - points[index+1]):normalizeV() or atVec
			
			offset = offset + moveDistance
			
			local localMatrix = Matrix()
			localMatrix:createMatrix(math.interPolate(atVec, nextAtVec, math.clamp( offset/ distace,0,1)), Vec3(0,1,0))
			local pos = points[index] + atVec * offset
			localMatrix:setPosition( pos )
			this:setLocalMatrix(localMatrix)
			--rotating wheels
			local rotationThisFrame = Core.getDeltaTime()*2*math.pi*(currentSpeed/1.153)	--1.153=diameter*pi
			wheel1:rotate(Vec3(1,0,0),rotationThisFrame)
			wheel2:rotate(Vec3(1,0,0),rotationThisFrame)
			
			if offset < 0 then
				offset = offset + ( index > 1 and (points[index-1] - points[index]):length() or 0)
				index =  math.max( index - 1, 1 )
				if index == 1 and offset < 0 then
					offset = 0
				end
			end
		end
		--
		--	slow field
		--
		slowTimerUpdate = slowTimerUpdate - Core.getDeltaTime()
		if slowTimerUpdate<0.0 then
			slowTimerUpdate = slowTimerUpdate + 0.2
			comUnit:broadCast(this:getGlobalPosition(),5.5,"maxSpeed",{mSpeed=math.max(currentSpeed,maxSpeed/NUMNPCFORMAXSPEED),range=6.5,pos=this:getGlobalPosition()})
		end
		--
		--
		--
	else
		--cart is dead
		updateDeathArea()
		
		--
		--	Communicate map failure
		--
		comUnit:sendTo("stats", "npcReachedEnd",1)	--for menu stats
		--
		
		local localMatrix = this:getLocalMatrix()
		
		local len = (localMatrix:getPosition() - points[numPoints]):length()
		if len > 100 then
			--the cart is over 100m from endpoint, quit
			update = updateDeathArea--keep the death aura alive for ever
			return true
		elseif len > 2.1  then
			fallDirection = (fallDirection - Vec3(0,15,0) * Core.getDeltaTime()):normalizeV()	
			fallAtDirection = (fallAtDirection - Vec3(0,15,0) * Core.getDeltaTime()):normalizeV()	
			currentSpeed = currentSpeed + currentSpeed * 1.8 * Core.getDeltaTime()
			
			fallVelocity = fallVelocity  - Vec3(0,9,0) * Core.getDeltaTime()
		else
			--fallDirection = (fallDirection - Vec3(0,8,0) * Core.getDeltaTime()):normalizeV()	
			currentSpeed = currentSpeed + currentSpeed * 0.17 * Core.getDeltaTime()
			fallAtDirection = (fallAtDirection - Vec3(0,4,0) * Core.getDeltaTime()):normalizeV()
			
			
			fallVelocity = fallVelocity + fallAtDirection * Core.getDeltaTime()
		end
		
		
		localMatrix:createMatrix(math.interPolate( localMatrix:getAtVec(), fallAtDirection, Core.getDeltaTime()):normalizeV(), localMatrix:getUpVec())
		localMatrix:setPosition( localMatrix:getPosition() + fallVelocity * Core.getDeltaTime() )
		this:setLocalMatrix(localMatrix)
		
	end
	return true
end