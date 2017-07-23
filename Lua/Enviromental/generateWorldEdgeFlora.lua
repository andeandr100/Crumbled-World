--this = SceneNode()
function create()
	--this:setIsStatic(true)

	greenDensity = {}
	greenDensityMax = 0.0
	nature = {}
	natureConectToScene = {}--list all nodes to connect nature models to(so they dont colide with each other)
	natureCount = 0

	for i=-128, 128, 1 do
		greenDensity[i] = {}
		for j=-128, 128, 1 do 
			greenDensity[i][j] = 0.0
		end
	end
	local islands = this:getRootNode():findAllNodeByNameTowardsLeaf("*island*")
	for i=0, islands:size()-1, 1 do
		generateGreenDensity(islands:item(i))
	end

	setMaxDensity()--finds the higest density


	for i=0, islands:size()-1, 1 do
		generateFlora(islands:item(i))
	end
	-- add the connection last, so no collisions occure
	for i=0, natureCount-1, 1 do
		natureConectToScene[i]:addChild(nature[i])
		--now make so there is no need to do an update
		nature[i]:setIsStatic(true)
		--nature[i]:render()
	end
	return true
end

function setMaxDensity()
	local list = this:getRootNode():findAllNodeByNameTowardsLeaf("*rock_face*")
	local val = 0.0
	for i=0, list:size()-1, 1 do
		val = calculateGreenDensity(list:item(i):getGlobalPosition())
		if val>greenDensityMax then greenDensityMax = val end
	end
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
function generateGreenDensity(island)
	increaseGreenDensityByObj(island,"*tree*",2.0)
	increaseGreenDensityByObj(island,"*bush*",0.3)
	increaseGreenDensityByObj(island,"*fearn*",0.3)
	increaseGreenDensityByObj(island,"*leaf*",0.1)
	increaseGreenDensityByObj(island,"*vine*",0.1)
	increaseGreenDensityByObj(island,"*cactus*",0.1)
	increaseGreenDensityByObj(island,"*weed*",0.25)
	increaseGreenDensityByObj(island,"*flower*",0.1)
	increaseGreenDensityByObj(island,"*flora*",0.1)
	increaseGreenDensityByObj(island,"*mushroom*",0.25)
end
function increaseGreenDensityByObj(island,name,val)
	local list = island:findAllNodeByNameTowardsLeaf(name)
	for i=0, list:size()-1, 1 do
		local x = math.floor(list:item(i):getGlobalPosition().x)
		local y = math.floor(list:item(i):getGlobalPosition().z)
		greenDensity[x][y] = greenDensity[x][y] + val
	end
end
function generateFlora(island)
	local list = island:findAllNodeByNameTowardsLeaf("*world_edge*")
	local gPer = 0.0
	for i=0, list:size()-1, 1 do
		--
		--  vines
		--
		for j=0, 5, 1 do
			local yRand = math.randomFloat()
			local mat = list:item(i):getGlobalMatrix()
			local offset = Vec3(0.0,-(2.1 * yRand),0.0)+(mat:getRightVec():normalizeV() * (1.5 * ((2.0*math.randomFloat())-1.0)))

			--gPer is the nature density on the map
			gPer = 0.20 + (0.80*(calculateGreenDensity(list:item(i):getGlobalPosition()+offset)/greenDensityMax))
			if gPer>math.randomFloat() then
				local vStart = mat:getPosition() + offset + mat:getAtVec():normalizeV()
				local vEnd   = mat:getPosition() + offset - mat:getAtVec():normalizeV()
				local vNormal = Vec3()
				local cLine = Line3D(vStart,vEnd)
				local retScene = island:collisionTree(cLine,vNormal)
				if retScene then
					--(0.65*yRand)>math.randomFloat() will increase posibility offset larger plant spwn lower down
					if (0.65*yRand)>math.randomFloat() then
						nature[natureCount] = Core.getModel( "Data/Models/nature/Plants/vines/vine_down2.mym" )
					else
						nature[natureCount] = Core.getModel( "Data/Models/nature/Plants/vines/vine_down1.mym" )
					end

					nature[natureCount]:setLocalPosition(mat:inverseM()*cLine.endPos)
					natureConectToScene[natureCount] = list:item(i)
					natureCount = natureCount + 1
				end
			end
		end
		--
		--  roots
		--
--		for j=0, 4, 1 do
--			local yRand = math.randomFloat()
--			local mat = list:item(i):getGlobalMatrix()
--			local offset = Vec3(0.0,-0.8-(1.3 * yRand),0.0)+(mat:getRightVec():normalizeV() * (1.5 * ((2.0*math.randomFloat())-1.0)))
--
--			--gPer is the nature density on the map
--			gPer = 0.15 + (0.85*(calculateGreenDensity(list:item(i):getGlobalPosition()+offset)/greenDensityMax))
--			if gPer>math.randomFloat() then
--				local vStart = mat:getPosition() + offset + mat:getAtVec():normalizeV()
--				local vEnd   = mat:getPosition() + offset - mat:getAtVec():normalizeV()
--				local vNormal = Vec3()
--				local cLine = Line3D(vStart,vEnd)
--				local retScene = island:collisionTree(cLine,vNormal)
--				if retScene then

--					nature[natureCount] = Core.getModel( string.format("Data/Models/nature/roots/root%d.mym", (1.0+(math.randomFloat()*4.95))) )

--					nature[natureCount]:setLocalPosition(mat:inverseM()*cLine.endPos)
--					natureConectToScene[natureCount] = list:item(i)
--					natureCount = natureCount + 1
--				end
--			end
--		end
	end
end
function update()
	return false
end