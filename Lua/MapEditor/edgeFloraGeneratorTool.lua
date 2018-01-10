require("MapEditor/Tools/Tool.lua")
--this = SceneNode()
local island
function create()
	--Create tool
	Tool.create()
	--get seleced scene nodes
	selectedNodes = Tool.getSelectedSceneNodes()
	for i=1, #selectedNodes do
		island = selectedNodes[i]:findNodeByTypeTowardsRoot(NodeId.island)
		greenDensity = {}
		greenDensityMax = 0.0
		nature = {size=0}
		natureConectToScene = {}--list all nodes to connect nature models to(so they dont colide with each other)
		natureCount = 0
		vineCountPerRockFace = 5
		rootCountPerRockFace = 3
	
		for i=-128, 128, 1 do
			greenDensity[i] = {}
			for j=-128, 128, 1 do 
				greenDensity[i][j] = 0.0
			end
		end
		
		evaluateGreenDensity(island)
		setMaxDensity()--finds the higest density
	
		generateFlora(island)--fills the world
		
		-- add the connection last, so no collisions occurs
		for i=1, nature.size, 1 do
			--nature[i].model:setLocalPosition(nature[i].globalPos)
			nature[i].model:setLocalMatrix(nature[i].parrent:getGlobalMatrix():inverseM()*nature[i].model:getGlobalMatrix())
			nature[i].parrent:addChild(nature[i].model:toSceneNode())
		end
	end
	return false--no need for updates
end

function setMaxDensity()
	local total = 0
	local count = 0
	local objTable = this:getRootNode():findAllNodeByNameTowardsLeaf("*rock_face*")
	local val = 0.0
	for i=1, #objTable, 1 do
		val = calculateGreenDensity(objTable[i]:getGlobalPosition())
		total = total + val
		count = count + 1
		if val>greenDensityMax then greenDensityMax = val end
	end
	greenDensityMax = math.min(greenDensityMax,total/count*2.0)
end
function calculateGreenDensity(vec)
	local x = math.floor(vec.x)
	local y = math.floor(vec.z)
	local value = 0.0
	local xp = 0.0
	local yp = 0.0
	local DIST = 3
	for i=-DIST, DIST, 1 do
		xp = 0.25 + ( 0.75 * (DIST-math.abs(i)) )
		for j=-DIST, DIST, 1 do
			yp = 0.25 + ( 0.75 * (DIST-math.abs(j)) )
			value = value + (xp * yp * greenDensity[x+i][y+j])
		end
	end
	return value
end
function evaluateGreenDensity(island)
	increaseGreenDensityByObj(island,"*tree*",2.5)
	increaseGreenDensityByObj(island,"*bush*",1.0)
	increaseGreenDensityByObj(island,"*fearn*",1.0)
	increaseGreenDensityByObj(island,"*leaf*",0.2)
	increaseGreenDensityByObj(island,"*vine*",0.2)
	increaseGreenDensityByObj(island,"*cactus*",0.3)
	increaseGreenDensityByObj(island,"*weed*",0.3)
	increaseGreenDensityByObj(island,"*flower*",0.2)
	increaseGreenDensityByObj(island,"*flora*",0.2)
	increaseGreenDensityByObj(island,"*mushroom*",0.25)
end
function increaseGreenDensityByObj(island,name,val)
	local objTable = island:findAllNodeByNameTowardsLeaf(name)
	for i=1, #objTable, 1 do
		local x = math.floor(objTable[i]:getGlobalPosition().x)
		local y = math.floor(objTable[i]:getGlobalPosition().z)
		greenDensity[x][y] = greenDensity[x][y] + val
	end
end
function generateFlora(island)
	local objTable = island:findAllNodeByNameTowardsLeaf("*rock_face*")
	for i=1, #objTable, 1 do
		--
		--  vines
		--	
		for j=1, vineCountPerRockFace do
			local offsetRightVec = (objTable[i]:getGlobalMatrix():getRightVec():normalizeV() * (1.5 * ((2.0*math.randomFloat())-1.0)))
			tryPlace(objTable[i],offsetRightVec,0.0,1.0,true)
		end
		--
		--  roots
		--
		for j=1, rootCountPerRockFace do
			local offsetRightVec = (objTable[i]:getGlobalMatrix():getRightVec():normalizeV() * (1.5 * ((2.0*math.randomFloat())-1.0)))
			tryPlace(objTable[i],offsetRightVec,0.0,1.0,false)
		end
	end
end
function tryPlace(node,offsetRightVec,yOffset,odds,placeVines)
	local yRand = math.randomFloat()
	if placeVines then
		yRand = 0.5>math.randomFloat() and math.randomFloat()*0.35 or yRand--top heavy vines
	else
		yRand = 0.5>math.randomFloat() and 1.0-(math.randomFloat()*0.4) or yRand--botton heavy roots
	end
	local mat = node:getGlobalMatrix()
	local offset = odds<0.99 and Vec3(0.0,yOffset,0.0)+offsetRightVec or Vec3(0.0,yOffset+0.15-((2.2-yOffset) * yRand),0.0)+offsetRightVec

	--gPer is the nature density on the map
	local gPer = math.min(1.0,odds*0.90*(calculateGreenDensity(node:getGlobalPosition()+offset)/greenDensityMax))
	if gPer>math.randomFloat() then
		local vStart = mat:getPosition() + offset - mat:getUpVec():normalizeV()
		local vEnd   = mat:getPosition() + offset + mat:getUpVec():normalizeV()
		local vNormal = Vec3()
		local cLine = Line3D(vStart,vEnd)
		local retScene = node:collisionTree(cLine,vNormal)
		if retScene then
			nature.size = nature.size + 1
			local pos = nature.size
			cLine.endPos = cLine.endPos + (mat:getUpVec():normalizeV()*0.05)--push the item a little closer to the wall
			if placeVines then
				if yRand*2.0<math.randomFloat() then
					--high probability higher up (large vine)
					nature[pos] = {model=Core.getModel( "vine_down2.mym" ), parrent=node, globalPos = cLine.endPos}
					tryPlace(node,offsetRightVec+(offsetRightVec:normalizeV()*math.randomFloat(-0.1,0.1))+Vec3(0,math.randomFloat(-0.5,-0.75),0),offset.y,odds>0.95 and odds*0.9 or odds*0.75,placeVines)
				else
					--high probability lower down (small vine)
					nature[pos] = {model=Core.getModel( "vine_down1.mym" ), parrent=node, globalPos = cLine.endPos}
				end
			else
				nature[pos] = {model=Core.getModel( string.format("root%d.mym", math.randomInt(1,5)) ), parrent=node, globalPos = cLine.endPos}
			end
			local lMat = nature[pos].model:getLocalMatrix()
			lMat:createMatrix(Vec3(0,1,0),mat:getUpVec())
			lMat:setPosition(cLine.endPos)
			nature[pos].model:setLocalMatrix(lMat)
			nature[pos].model:getMesh(0):rotate(Vec3(1,0,0),-math.pi*0.475)
			return cLine
		end
	end
	return Line3D(Vec3(),Vec3())
end
function update()
	return false
end