require("Menu/settings.lua")
require("Game/particleEffect.lua")
--this = SceneNode()
worldEdgeStuff = {}
function worldEdgeStuff.init(island, staticNode, dynamicNode)
	local self = worldEdgeStuff
	--Core.setUpdateHzRealTime(16)
	--assert(island,"no island in in parameter")
	print("island:getNodeType()="..island:getNodeType().."\n")
	--Dust
	self.g1 = Core.getModel( "Data/Models/nature/stone/gravel1.mym" )
	self.g2 = Core.getModel( "Data/Models/nature/stone/gravel2.mym" )
	self.g3 = Core.getModel( "Data/Models/nature/stone/gravel3.mym" )
	self.s1 = Core.getModel( "Data/Models/nature/stone/stone1.mym" )
	self.s2 = Core.getModel( "Data/Models/nature/stone/stone2.mym" )
	self.s3 = Core.getModel( "Data/Models/nature/stone/stone3.mym" )
	self.worldEdgePos = {}
	self.worldEdgeMatrix = {}
	self.worldEdgeConnections = {size=0}
	self.nodes = {size=0,tick=1}
	self.counter = 0
	self.UPDATE_TIME = 0.5
	self.gravelDensity = Settings.getFloatingStonesDensity()
	self.updateTimer = self.UPDATE_TIME
	self.visibleStones = true
	self.visibleDust = true
	self.staticNode = staticNode
	self.dynamicNode = dynamicNode
	self.hasBeenCreated = true
	--dust
	self.dust = {}
	--Gravel
	self.staticStones = {}
	self.island = island
	self.dynamicStones = {size=0}
	self.dynamicFloaters = {size=0}

--	self.listAllWorldEdges()
--	self.createWorldEdgeConnections()
--	self.createDustAndGravel()
--	self.manageFloaters()
	
	return true
end

function worldEdgeStuff.load(importTable, island, staticNode, dynamicNode)
	--{ counter = self.counter, worldEdgePos = self.worldEdgePos, worldEdgeMatrix = self.worldEdgeMatrix}
	local self = worldEdgeStuff
	--Core.setUpdateHzRealTime(16)
	--assert(island,"no island in in parameter")
	print("island:getNodeType()="..island:getNodeType().."\n")
	--Dust
	self.g1 = Core.getModel( "Data/Models/nature/stone/gravel1.mym" )
	self.g2 = Core.getModel( "Data/Models/nature/stone/gravel2.mym" )
	self.g3 = Core.getModel( "Data/Models/nature/stone/gravel3.mym" )
	self.s1 = Core.getModel( "Data/Models/nature/stone/stone1.mym" )
	self.s2 = Core.getModel( "Data/Models/nature/stone/stone2.mym" )
	self.s3 = Core.getModel( "Data/Models/nature/stone/stone3.mym" )
	self.worldEdgePos = {}
	self.worldEdgeMatrix = {}
	self.worldEdgeConnections = {size=0}
	self.nodes = {size=0,tick=1}
	self.counter = 0
	self.UPDATE_TIME = 0.5
	self.gravelDensity = Settings.getFloatingStonesDensity()
	self.updateTimer = self.UPDATE_TIME
	self.visibleStones = true
	self.visibleDust = true
	self.staticNode = staticNode
	self.dynamicNode = dynamicNode
	self.hasBeenCreated = true
	--dust
	self.dust = {}
	--Gravel
	self.staticStones = {}
	self.island = island
	self.dynamicStones = {size=0}
	self.dynamicFloaters = {size=0}

	self.counter = importTable.counter
	self.worldEdgePos = importTable.worldEdgePos
	self.worldEdgeMatrix = importTable.worldEdgeMatrix
	
	self.createWorldEdgeConnections()
	self.createDustAndGravel()
	self.manageFloaters()
end

local function setNode(pos)
	local self = worldEdgeStuff
	--Core.addDebugLine(pos,pos+Vec3(0,5,0),3600,Vec3(0.2)+math.randomVec3())
	self.nodes.size = self.nodes.size + 1
	self.nodes[self.nodes.size] = {nodeStatic=SceneNode(), nodeDynamic=SceneNode(), position=pos}
	pos = this:getGlobalMatrix():inverseM()*pos
	self.nodes[self.nodes.size].nodeStatic:setLocalPosition(pos)
	self.nodes[self.nodes.size].nodeDynamic:setLocalPosition(pos)
	this:addChild(self.nodes[self.nodes.size].nodeStatic)
	this:addChild(self.nodes[self.nodes.size].nodeDynamic)
end
local function getClosestNode(pos,getStatic)
	local self = worldEdgeStuff
	local closestLength = 128.0
	local closest = 0
	for i=1, self.nodes.size do
		if (pos-self.nodes[i].position):length()<closestLength then
			closestLength = (pos-self.nodes[i].position):length()
			closest = i
		end
	end
	if getStatic then
		return self.nodes[closest].nodeStatic
	end
	return self.nodes[closest].nodeDynamic
end
function worldEdgeStuff.createDustAndGravel()
	local self = worldEdgeStuff
	self.counter = 0
	for i=1, self.worldEdgeConnections.size do
		local globalStartPos = self.worldEdgePos[self.worldEdgeConnections[i][1]]
		local globalEndPos = self.worldEdgePos[self.worldEdgeConnections[i][2]]
		local node = self.dynamicNode--getClosestNode( (globalStartPos+globalEndPos)*0.5,true )
		local localStartPos = node:getGlobalMatrix():inverseM()*self.worldEdgePos[self.worldEdgeConnections[i][1]]
		local localEndPos = node:getGlobalMatrix():inverseM()*self.worldEdgePos[self.worldEdgeConnections[i][2]]
		--Dust
		self.counter = self.counter + 1
		local rockDust = ParticleSystem(ParticleEffect.RockDust)
		node:addChild( rockDust )
		rockDust:activate(Vec3())
		rockDust:setSpawnRate( math.min(1.0,(localEndPos-localStartPos):length()/4.5) )
		rockDust:setEmitterLine(Line3D(localStartPos,localEndPos))
		rockDust:ageParticles(18.0)
		self.dust[#self.dust+1] = rockDust
		--Gravel
		local atVec = (self.worldEdgeMatrix[self.worldEdgeConnections[i][1]]:getUpVec()+self.worldEdgeMatrix[self.worldEdgeConnections[i][2]]:getUpVec())*0.5
		local rightVec = (self.worldEdgeMatrix[self.worldEdgeConnections[i][1]]:getRightVec()+self.worldEdgeMatrix[self.worldEdgeConnections[i][2]]:getRightVec())*0.5
		local upVec = (self.worldEdgeMatrix[self.worldEdgeConnections[i][1]]:getAtVec()+self.worldEdgeMatrix[self.worldEdgeConnections[i][2]]:getAtVec())*0.5
		self.generateGravel(globalStartPos,globalEndPos,atVec,rightVec,upVec)
	end
	for i=1, self.nodes.size do
		self.nodes[i].nodeStatic:setEnableUpdates(false)
	end
end
function worldEdgeStuff.manageFloaters()
	--
	--Currently buged feature
	--
--	local self = worldEdgeStuff
--	local list = self.island:findAllNodeByNameTowardsLeaf("edge_floater")
--	for i=1, #list, 1 do
--		local maxLength = 128.0
--		local index = 0
--		local globalPos = list[i]:getGlobalPosition()
--		for i=1, self.worldEdgeConnections.size do
--			local pos = self.worldEdgeMatrix[self.worldEdgeConnections[i][1]]:getPosition()
--			pos = (pos + self.worldEdgeMatrix[self.worldEdgeConnections[i][1]]:getPosition())*0.5
--			if (pos-globalPos):length()<maxLength then
--				maxLength = (pos-globalPos):length()
--				index = i
--			end
--		end
--		if index>0 then			
--			self.dynamicFloaters.size = self.dynamicFloaters.size + 1
--			self.dynamicFloaters[self.dynamicFloaters.size] = {node=list[i], pos=list[i]:getLocalPosition(), mat=list[i]:getLocalMatrix(), timer=math.randomFloat()*2.0*math.pi, timer2=math.randomFloat()*10 }
--		end
--	end
end

function  worldEdgeStuff.export(island)
	local self = worldEdgeStuff
	local list = island:findAllNodeByNameTowardsLeaf("*rock_face*")

	local counter = 0
	local worldEdgePos = {}
	local worldEdgeMatrix = {}
	for i=1, #list do
		counter = counter + 1
		worldEdgePos[counter] = list[i]:getGlobalPosition()+Vec3(0.0,-2.0,0.0)
		worldEdgeMatrix[counter] = list[i]:getGlobalMatrix()
	end
	
	return { counter = counter, worldEdgePos = worldEdgePos, worldEdgeMatrix = worldEdgeMatrix}
end

function worldEdgeStuff.listAllWorldEdges()
	local self = worldEdgeStuff
	local list = self.island:findAllNodeByNameTowardsLeaf("*rock_face*")

	for i=1, #list do
		self.counter = self.counter + 1
		self.worldEdgePos[self.counter] = list[i]:getGlobalPosition()+Vec3(0.0,-2.0,0.0)
		self.worldEdgeMatrix[self.counter] = list[i]:getGlobalMatrix()
	end
end
function worldEdgeStuff.createWorldEdgeConnections()
	local self = worldEdgeStuff
	local indexLeftTable = {}
	local indexLeftTableSize = self.counter
	for i=1, indexLeftTableSize do
		indexLeftTable[i]=i
	end
	while indexLeftTableSize>0 do
		local startIndex = indexLeftTable[indexLeftTableSize]
		local index = startIndex
		local indexNew = 0
		local prevIndex = index
		--print("indexLeftTableSize=="..indexLeftTableSize.."\n")
		repeat
			indexNew=self.findNextInLoop(index,prevIndex,indexLeftTable,indexLeftTableSize)
			if indexNew>0 then
				--print("Connect("..index.."-->"..indexNew..")\n")
				self.worldEdgeConnections.size = self.worldEdgeConnections.size + 1
				self.worldEdgeConnections[self.worldEdgeConnections.size] = {index,indexNew,math.randomVec3()*0.75+Vec3(0.25,0.25,0.25)}
			end
			indexLeftTableSize = indexLeftTableSize - 1
			prevIndex = index
			index = indexNew
		until indexNew==0 or indexNew==startIndex
	end
end
function worldEdgeStuff.findNextInLoop(index,butNotIndex,indexLeftTable,indexLeftTableSize)
	local self = worldEdgeStuff
	local pos = self.worldEdgePos[index]
	local maxLength = 9.0
	local ret = 0
	local tableIndex = 0
	for i=1, indexLeftTableSize do
		if not (indexLeftTable[i]==index or indexLeftTable[i]==butNotIndex) then
			local atVec = pos-self.worldEdgePos[indexLeftTable[i]]
			local iVec = Vec3(atVec.z*0.25,0.0,atVec.x*0.25)
			local length = atVec:length()
			if length<maxLength then
				local tm = (pos+self.worldEdgePos[indexLeftTable[i]])*0.5
				local outNormal = Vec3()
				local collisionLine1 = Line3D(tm+Vec3(atVec.z*0.5,10,-atVec.x*0.5), tm+Vec3(atVec.z*0.5,-10,-atVec.x*0.5) )
				local collisionLine2 = Line3D(tm+Vec3(-atVec.z*0.5,10,atVec.x*0.5), tm+Vec3(-atVec.z*0.5,-10,atVec.x*0.5) )
				local collosionNode1 = self.island:collisionTree(collisionLine1,outNormal,{NodeId.islandMesh})
				local collosionNode2 = self.island:collisionTree(collisionLine2,outNormal,{NodeId.islandMesh})
				if (collosionNode1 and not collosionNode2) or (collosionNode2 and not collosionNode1) then
					--abort()
					ret = indexLeftTable[i]
					tableIndex = i
					maxLength = length
				end
			end
		end
	end
	if ret>0 and  tableIndex~=indexLeftTableSize then
		indexLeftTable[tableIndex],indexLeftTable[indexLeftTableSize] = indexLeftTable[indexLeftTableSize],indexLeftTable[tableIndex]
	end
	if ret>0 then
		self.nodes.tick = self.nodes.tick - 1
		if self.nodes.tick==0 then
			self.nodes.tick = 2
			setNode(self.worldEdgePos[ret])
		end
	end
	return ret
end
--
--
--
function worldEdgeStuff.generateGravel(startPos,endPos,atVec,rightVec,upVec)
	local self = worldEdgeStuff
	local color = Vec3(0.3)+math.randomVec3()
	local spawnCount = (endPos-startPos):length()*self.gravelDensity
	for j=0, spawnCount, 1 do
		local rand = 1+(math.randomFloat()*2.5)
		local upMul = math.randomFloat()
		local randVec = (-atVec*(math.randomFloat()*upMul+0.20))+(rightVec*(0.5-math.randomFloat()))+(upVec*(0.5-upMul)*2.25)
		randVec = Vec3(randVec.x,-math.abs(1.5*randVec.y)+0.60,randVec.z)
		local pos = startPos + ((endPos-startPos)*math.randomFloat()) + randVec
		
		if math.randomFloat()>0.20 then
			--static stones
			local str = string.format("Data/Models/nature/stone/gravel%d.mym", rand)
			local model = Core.getModel( str )--:getMesh(0)
			local mesh = model:getMesh(0)
			model:removeChild(mesh)
			local mat = mesh:getLocalMatrix()
			mat:scale(0.75+(math.randomFloat()*0.5))
			mesh:setLocalMatrix(mat)
			if math.randomFloat()>0.75 then
				pos = pos + Vec3(0,(pos.y+0.75)*1.5,0)
			end
			
			--local node = self.staticNode--getClosestNode(pos,true)
			local localPosition = this:getGlobalMatrix():inverseM()*pos
			mesh:setLocalPosition( localPosition )
			self.island:addChild(mesh)
			self.staticStones[#self.staticStones+1] = mesh
		else
			--dynamic stones
			local file = string.format("Data/Models/nature/stone/stone%d.mym", rand)
			local model = Core.getModel( file )--:getMesh(0)
			local mesh = model:getMesh(0)
			--assert(mesh,"no mesh found for "..file)
			
			mesh:setSceneName("dynamicStone")
			model:removeChild(mesh)
			local mat = mesh:getLocalMatrix()
			mat:scale(0.2+(math.randomFloat()*0.5))
			mesh:setLocalMatrix(mat)
			--special tretment large rocks
			pos = pos + (upVec*0.55) - (atVec*(math.randomFloat()*0.30+0.15))
			
			local node = self.staticNode--getClosestNode(pos,false)
			local localPosition = this:getGlobalMatrix():inverseM()*pos
			mesh:setLocalPosition( localPosition )
			node:addChild(mesh)
			self.dynamicStones.size = self.dynamicStones.size + 1
			self.dynamicStones[self.dynamicStones.size] = {node=mesh, timer=0.0, axis1=math.randomVec3(),axis2=math.randomVec3(), offset=mesh:getLocalPosition()+math.randomVec3()*(0.2+0.3*math.randomFloat())}
		end
	end
end

function worldEdgeStuff.settingsChanged()
	if worldEdgeStuff.hasBeenCreated then
		worldEdgeStuff.setVisibleStones(Settings.floatingStones.getIsVisible())
		worldEdgeStuff.setVisibleDust(Settings.islandSmoke.getIsVisible())
	end
end

function worldEdgeStuff.setVisibleDust(visible)
	local self = worldEdgeStuff
	if self.visibleDust ~= visible then
		self.visibleDust = visible
		for i=1, #self.dust do
			self.dust[i]:setVisible(visible)
		end
	end
end

function worldEdgeStuff.setVisibleStones(visible)
	local self = worldEdgeStuff
	
	if self.visibleStones ~= visible then
		self.visibleStones = visible
		for i=1, self.dynamicStones.size do
			self.dynamicStones[i].node:setVisible(visible)
		end
		for i=1, self.dynamicFloaters.size do
			self.dynamicFloaters[i].node:setVisible(visible)
		end
		for i=1, #self.staticStones do
			--print("static "..tostring(i).."\n")
			self.staticStones[i]:setVisible(visible)
		end
	end
end

function worldEdgeStuff.update()
	local self = worldEdgeStuff
	
	if self.visibleStones then
		local deltaTime = Core.getDeltaTime()
		for i=1, self.dynamicStones.size do
			local item = self.dynamicStones[i]
			item.timer = item.timer + deltaTime
			item.node:rotateAroundPoint(item.axis1,item.offset,deltaTime*0.13)
			item.node:rotate(item.axis2,deltaTime*0.1)
		end
		for i=1, self.dynamicFloaters.size do
			local item = self.dynamicFloaters[i]
			item.timer = item.timer + deltaTime*0.1
			item.timer2 = item.timer2 + deltaTime*0.05
			item.node:setLocalPosition(item.pos + (item.mat:getRightVec()*math.sin(item.timer)*0.3) - (item.mat:getUpVec()*math.sin(item.timer2)*0.3) - (item.mat:getAtVec()*math.sin((item.timer2+item.timer)*0.2)*0.6) )
		end
		
	end
end