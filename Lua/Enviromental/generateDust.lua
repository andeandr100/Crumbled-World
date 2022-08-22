--this = SceneNode()
function worldEdge.create(island)
	
	
	abort()
	--TODO REMOVE FILE
	
	
--	Core.setUpdateHz(2)
--
--	local islands = this:getRootNode():findAllNodeByNameTowardsLeaf("*Island*")
--	--Dust
--	rockDust = {}
--	worldEdgePos = {}
--	worldEdgeMatrix = {}
--	worldEdgeConnections = {size=0}
--	counter = 0
--	UPDATE_TIME = 0.5
--	updateTimer = UPDATE_TIME
--	--Gravel
--	TIMERS_COUNT = 5
--	timersBig = {}
--	timersSmall = {}
--	axles = {}
--	gravels = {}
--	gravelsSize = {}
--	pos = {}
--	gravelCount = 0
--	gravelOffset = 0.0
--
--	for i=0, islands:size()-1, 1 do
--		generateDust(islands:item(i))
--	end
--	createWorldEdgeConnections()
--	for i = 0, TIMERS_COUNT-1, 1 do
--		timersBig[i] = {time=math.randomFloat()*10.0, pos=Vec3()}
--		timersSmall[i] = {time=math.randomFloat()*10.0, pos=Vec3()}
--		axles[i] = math.randomVec3()
--	end
--	counter = 0
--	for i=1, worldEdgeConnections.size do
--		--Dust
--		--Core.addDebugLine(worldEdgePos[worldEdgeConnections[i][1]],worldEdgePos[worldEdgeConnections[i][2]],3600.0,worldEdgeConnections[i][3])
--		counter = counter + 1
--		rockDust[counter] = ParticleSystem.new("RockDust",true)
--		this:addChild( rockDust[counter]:toSceneNode() )
--		rockDust[counter]:activate(Vec3())
--		rockDust[counter]:setEmitterLine(Line3D(worldEdgePos[worldEdgeConnections[i][1]],worldEdgePos[worldEdgeConnections[i][2]]))
--		abort()
--		--Gravel
--		generateGravel(worldEdgePos[worldEdgeConnections[i][1]],worldEdgePos[worldEdgeConnections[i][2]],worldEdgeMatrix[i])
--	end
--	return true
	return false
end
function worldEdge.generateDust(island)
	local list = island:findAllNodeByNameTowardsLeaf("*rock_face*")

	for i=0, list:size()-1, 1 do
		counter = counter + 1
--		rockDust[counter] = {dust = ParticleSystem.new("RockDust",true), emitterNode=list:item(i)}
--		island:getParent():addChild(rockDust[counter].dust:toSceneNode())
--		rockDust[counter].dust:activate(rockDust[counter].emitterNode:getGlobalPosition()+Vec3(0.0,-3.0,0.0))
		worldEdgePos[counter] = list:item(i):getGlobalPosition()+Vec3(0.0,-2.25,0.0)
		worldEdgeMatrix[counter] = list:item(i):getGlobalMatrix()
	end
end
function worldEdge.createWorldEdgeConnections()
	local indexLeftTable = {}
	local indexLeftTableSize = counter
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
			indexNew=findNextInLoop(index,prevIndex,indexLeftTable,indexLeftTableSize)
			if indexNew>0 then
				--print("Connect("..index.."-->"..indexNew..")\n")
				worldEdgeConnections.size = worldEdgeConnections.size + 1
				worldEdgeConnections[worldEdgeConnections.size] = {index,indexNew,math.randomVec3()*0.75+Vec3(0.25,0.25,0.25)}
			end
			indexLeftTableSize = indexLeftTableSize - 1
			prevIndex = index
			index = indexNew
		until indexNew==0 or indexNew==startIndex
	end
end
function worldEdge.findNextInLoop(index,butNotIndex,indexLeftTable,indexLeftTableSize)
	local pos = worldEdgePos[index]
	local maxLength = 6.0
	local ret = 0
	local tableIndex = 0
	for i=1, indexLeftTableSize do
		if not (indexLeftTable[i]==index or indexLeftTable[i]==butNotIndex) then
			local length = (pos-worldEdgePos[indexLeftTable[i]]):length()
			--print("length["..i.."]=="..length.."\n")
			if length<maxLength then
				ret = indexLeftTable[i]
				tableIndex = i
				maxLength = length
			end
		end
	end
	if ret>1 and  tableIndex~=indexLeftTableSize then
		indexLeftTable[tableIndex],indexLeftTable[indexLeftTableSize] = indexLeftTable[indexLeftTableSize],indexLeftTable[tableIndex]
	end
	return ret
end
--
--
--
function worldEdge.generateGravel(startPos,endPos,matrix)
	Core.addDebugLine(matrix:getPosition(),matrix:getPosition()+matrix:getUpVec(),3600,Vec3(0.2,0.2,0.2)+math.randomVec3())
	local spawnCount = (endPos-startPos):length()*10.0
	for j=0, 10, 1 do
		local rand = 1+(math.randomFloat()*2.5)
		local randVec = math.randomVec3()
		randVec = Vec3(randVec.x,-math.abs(1.5*randVec.y)+0.75,randVec.z)
		local pos = startPos + ((endPos-startPos)*math.randomFloat()) + randVec

--		local x = (1.4 * ((2.0*math.randomFloat())-1.0))--along side the wall
--		local y = (2.25 * math.randomFloat())--height
--		local z = 0.30+(1.1 * math.randomFloat())--distance away from wall

		--if z<y+0.4 then--0.4 so there is alwas a chanse for spawn
			if math.randomFloat()>0.25 then
				gravels[gravelCount] = Core.getModel( string.format("Data/Models/nature/stone/stone%d.mym", rand) )
				local mat = gravels[gravelCount]:getLocalMatrix()
				mat:scale(0.1+(math.randomFloat()*0.1))
				gravels[gravelCount]:setLocalMatrix(mat)
				gravelsSize[gravelCount] = 0.0
			else
				gravels[gravelCount] = Core.getModel( string.format("Data/Models/nature/stone/stone%d.mym", rand) )
				local mat = gravels[gravelCount]:getLocalMatrix()
				mat:scale(0.2+(math.randomFloat()*0.5))
				gravels[gravelCount]:setLocalMatrix(mat)
				--special tretment large rocks
				pos = pos + Vec3(0,0.5,0)
--				z = (z*0.3) + 0.10--(z*0.3) makes the big rock come close to the edge + 0.15 sets a minimum distance

				gravelsSize[gravelCount] = 1.0
			end
			
			pos[gravelCount] =  pos--Vec3(x,-y,z) 
			gravels[gravelCount]:setLocalPosition( pos[gravelCount] )
			this:addChild(gravels[gravelCount]:toSceneNode())
			--gravels[gravelCount]:setIsStatic(true)
			gravelCount = gravelCount + 1
		--end
	end
end
function update()
	
	abort()
	--TODO REMOVE FILE
	
	return true
end