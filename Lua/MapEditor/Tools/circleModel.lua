--this = SceneNode()
CircleModel = {}
CircleModel.mesh = NodeMesh.new()


function CircleModel.init()
	this:getRootNode():addChild(CircleModel.mesh:toSceneNode())	
	CircleModel.mesh:setRenderLevel(31)
	CircleModel.mesh:setShader(Core.getShader("toolNormal"))
	CircleModel.mesh:setColor(Vec4(1,1,1,1))
end

function CircleModel.create(radius)

	
	local cos = math.cos
	local sin = math.sin
	local radOffset = math.pi / 16
	local w = 0.04
	local upVec = Vec3(0,1,0)
	local mesh = CircleModel.mesh
	mesh:clearMesh()
	
	for r=0, math.pi*2+radOffset*0.5, radOffset do
		
		local atVec = Vec3(cos(r), 0, sin(r))
		local centerPos = Vec3(atVec.x, w, atVec.z) * radius
	
		
		local i = mesh:getNumVertex()
		mesh:addPosition(centerPos + atVec * w + upVec * w)
		mesh:addPosition(centerPos - atVec * w + upVec * w)
		mesh:addPosition(centerPos - atVec * w + upVec * w)
		mesh:addPosition(centerPos - atVec * w - upVec * w)
		mesh:addPosition(centerPos - atVec * w - upVec * w)
		mesh:addPosition(centerPos + atVec * w - upVec * w)
		mesh:addPosition(centerPos + atVec * w - upVec * w)
		mesh:addPosition(centerPos + atVec * w + upVec * w)
		
		mesh:addColor(Vec3(0.8,0.8,0.8))
		mesh:addColor(Vec3(0.8,0.8,0.8))
		mesh:addColor(Vec3(0.6,0.6,0.6))
		mesh:addColor(Vec3(0.6,0.6,0.6))
		mesh:addColor(Vec3(0.5,0.5,0.5))
		mesh:addColor(Vec3(0.5,0.5,0.5))
		mesh:addColor(Vec3(0.6,0.6,0.6))
		mesh:addColor(Vec3(0.6,0.6,0.6))

		if r ~= 0 then
			
			for n=i, i+6, 2 do
				mesh:addIndex(n - 8)
				mesh:addIndex(n - 7)
				mesh:addIndex(n - 0)
				
				mesh:addIndex(n - 7)
				mesh:addIndex(n + 1)
				mesh:addIndex(n - 0)
			end
		end
	end
	
	mesh:compile()
	CircleModel.mesh:setBoundingSphere(Sphere(Vec3(), radius + w))
end

function CircleModel.setPosition(globalPos, globalUp)
	
	local right = Vec3(1,0,0)
	if globalUp:dot(right) > 0.7 then
		right = Vec3(0,0,1)
	end
	
	local globalMatrix = Matrix()
	globalMatrix:createMatrixUp(globalUp, right)
	globalMatrix:setPosition(globalPos)
	
	CircleModel.mesh:setLocalMatrix(globalMatrix)
	
end