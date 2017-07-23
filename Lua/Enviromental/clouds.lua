--this = SceneNode()
function create()
	--generates the skybox
	createSpace()
	--stars
	starData = {}
	for i=1, 15 do
		starData[i] = {time=math.randomFloat()*4.0,mesh=NodeMesh()}
		starData[i].mesh=createStars()
		local mat = Matrix()
	end
	--
	return true
end
function createStars()
	local mesh = NodeMesh()
	for i=0, 200 do
		local atVec = Vec3()
		atVec = math.randomVec3()	
		--atVec.y = -math.abs(atVec.y)
		atVec:normalize()
		
		local rightVec = atVec:crossProductV(Vec3(0,1,0)):normalizeV()
		local upVec = atVec:crossProductV(rightVec):normalizeV()
		rightVec = atVec:crossProductV(-upVec):normalizeV()
	
		local r = math.randomFloat()*0.5 + 0.5
		local brightness =  math.randomFloat(1.3,1.75)
		local starSize = math.randomFloat() * 0.001 + 0.0010
		local uvOffset = Vec2(math.floor(math.randomFloat()*3.999)*0.25,math.floor(math.randomFloat()*3.999)*0.25)
		if i>200 then
			brightness =  2.0
			starSize = (math.randomFloat() * 0.002 + 0.001) * 2.0
			if uvOffset.x>0.7 then uvOffset.x = 0.5 end
		end
		local color = Vec3(brightness,brightness,brightness)
		settBoard(mesh,color,atVec,rightVec*starSize,upVec*starSize,uvOffset,Vec2(0.25,0.25))
	end
	activateMesh(mesh,Core.getTexture("stars.tga"))
	return mesh
end
function createSpace()
	local mesh1 = NodeMesh()
	local mesh2 = NodeMesh()
	local atVec = Vec3(0,0,1)
	local rightVec = Vec3(1,0,0)
	local upVec = Vec3(0,1,0)
	local uvOffset = Vec2(0.5,0.0)
	settBoard(mesh1,Vec3(1.75,1.75,1.75),atVec,rightVec,upVec,uvOffset,Vec2(0.5,0.5))
	atVec = Vec3(1,0,0)
	rightVec = Vec3(0,0,-1)
	uvOffset = Vec2(0.0,0.0)
	settBoard(mesh1,Vec3(1.75,1.75,1.75),atVec,rightVec,upVec,uvOffset,Vec2(0.5,0.5))
	atVec = Vec3(0,1,0)
	rightVec = Vec3(1,0,0)
	upVec = Vec3(0,0,-1)
	uvOffset = Vec2(0.5,0.5)
	settBoard(mesh1,Vec3(1.75,1.75,1.75),atVec,rightVec,upVec,uvOffset,Vec2(0.5,0.5))
	atVec = Vec3(0,-1,0)
	rightVec = Vec3(1,0,0)
	upVec = Vec3(0,0,1)
	uvOffset = Vec2(0.0,0.5)
	settBoard(mesh1,Vec3(1.75,1.75,1.75),atVec,rightVec,upVec,uvOffset,Vec2(0.5,0.5))
	--
	atVec = Vec3(-1,0,0)
	rightVec = Vec3(0,0,1)
	upVec = Vec3(0,1,0)
	uvOffset = Vec2(0.0,0.0)
	settBoard(mesh2,Vec3(1.75,1.75,1.75),atVec,rightVec,upVec,uvOffset,Vec2(0.5,1.0))
	atVec = Vec3(0,0,-1)
	rightVec = Vec3(-1,0,0)
	upVec = Vec3(0,1,0)
	uvOffset = Vec2(0.5,0.0)
	settBoard(mesh2,Vec3(1.75,1.75,1.75),atVec,rightVec,upVec,uvOffset,Vec2(0.5,1.0))
	
	activateMesh(mesh1,Core.getTexture("SB1_BTLF"))
	activateMesh(mesh2,Core.getTexture("SB1_RB"))
	
	local axis = math.randomVec3()
	local rad = math.randomFloat()*math.pi*2.0
	--mesh1:rotate(axis,rad)
	--mesh2:rotate(axis,rad)
end
function settBoard(mesh,color,atVec,rightVec,upVec,uvOffset,uvSize)
	--mesh = NodeMesh()
	local index = mesh:getNumVertex()
	mesh:addPosition( (atVec + rightVec - upVec) * 200 )
	mesh:addPosition( (atVec + rightVec + upVec) * 200 )
	mesh:addPosition( (atVec - rightVec + upVec) * 200 )
	mesh:addPosition( (atVec - rightVec - upVec) * 200 )
	
	mesh:addColor(color)
	mesh:addColor(color)
	mesh:addColor(color)
	mesh:addColor(color)

	mesh:addUvCoord(uvOffset + Vec2(0.0,0.0))
	mesh:addUvCoord(uvOffset + Vec2(0.0,uvSize.y))
	mesh:addUvCoord(uvOffset + uvSize)
	mesh:addUvCoord(uvOffset + Vec2(uvSize.x,0.0))
	
	mesh:addTriangleIndex(index, index + 1, index + 2)
--	mesh:addIndex(i0);
--	mesh:addIndex(i1);
--	mesh:addIndex(i2);
	
	mesh:addTriangleIndex(index + 2, index, index + 3)
--	mesh:addIndex(i2);
--	mesh:addIndex(i0);
--	mesh:addIndex(i3);
end
function activateMesh(mesh,texture)
	--mesh = NodeMesh()
	--Finis up the star mesh
	local starShader = Core.getShader("space")
	this:addChild(mesh)
	mesh:setBoundingSphere(Sphere(Vec3(), 5.0))
	mesh:setShader(starShader)
	mesh:setTexture(starShader, texture, 0)
	mesh:setColor(Vec4(1))
	mesh:setRenderLevel(0)
	--mesh:setIsStatic(true)
	mesh:compile()
	--mesh:render()
end

function update()
	for i=1, 15 do
		starData[i].time = starData[i].time + (Core.getDeltaTime()*(1.0+(i/15))*0.25)
		local brightness = 0.6+(math.sin(starData[i].time)*0.3)
		if starData[i].time>3.85 then
			local per = 1.0-((starData[i].time-3.85)/0.15)
			if starData[i].time>4.0 then
				per=0.0
				starData[i].time = 0.0
			end
			brightness = brightness*per
		elseif starData[i].time<0.15 then
			local per = starData[i].time/0.15
			brightness = brightness*(per<0.0 and 0.0 or per)
		end
		starData[i].mesh:setColor(Vec4(1,1,1,brightness))
		--starData[i].mesh:render()
	end
	return true
end