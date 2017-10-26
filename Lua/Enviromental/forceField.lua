
ForceField = {}
ForceField.positions = {}
ForceField.lifeTime = {}
ForceField.spawnTime = {}
function ForceField.create(node, radius, offset)
	--node = SceneNode()
	--radius = number()
	--offset = Vec3()
	local mesh = NodeMesh()
	mesh:setVertexType(VertexType.position3, VertexType.color4, VertexType.uvcoord, VertexType.normal)
	
	local yDiff = math.pi/17
	local xDiff = math.pi/12
	

	local stopWatch = Stopwatch()
	stopWatch:start()
	
	local cos = math.cos
	local sin = math.sin
	local pi = math.pi
	local pi2 = pi * 2
	
	local maxY = math.pi + yDiff * 0.5
	local color = Vec4(1,1,1,0)
	
	local previousRowIndexOffset = 0
	local rowIndexOffset = 0
	
	local minY = -(offset.y*1.5) / radius;

	
	for y=0, maxY, yDiff do
		if y>=math.pi-yDiff * 2.5 then
			color.w  = math.max( 0, color.w-0.5)
		end
		
		local yPos = -cos(y)
		if yPos >= minY then
			previousRowIndexOffset = rowIndexOffset
			rowIndexOffset = mesh:getNumVertex()
			local localRadius = sin(y)
			
			for x=0,pi2 + xDiff*0.5, xDiff do
				local position = Vec3(cos(x)*localRadius, yPos, sin(x)*localRadius) * radius + offset
				mesh:addVertex(position, color, Vec2( x / pi2, y / pi ), position:normalizeV())
			end
			
			if rowIndexOffset > 0 then
				
				for x=0, 23 do
					mesh:addTriangleIndex(previousRowIndexOffset + x, previousRowIndexOffset + x + 1, rowIndexOffset + x)
					mesh:addTriangleIndex(rowIndexOffset + x, previousRowIndexOffset + x + 1, rowIndexOffset + x + 1)
				end
			end
			
			color.w = math.min( 1, color.w+0.25)
		end
	end
	
	local buildTime = stopWatch:stop()
	print("\n\n\n\nForeceField build time: "..(math.round((buildTime*1000.0)*100.0)/100.0).."ms\n\n\n\n\n")
	
	
	local texture = Core.getTexture("hexagon.tga")
	ForceField.forceFieldShader = Core.getShader("ForceField")

	node:addChild(mesh)
	
	mesh:setBoundingSphere(Sphere(Vec3(), 2.0))
	mesh:setShader(ForceField.forceFieldShader)
	mesh:setTexture(ForceField.forceFieldShader,texture,4)
	mesh:setUniform(ForceField.forceFieldShader, "ScreenSize", Core.getRenderResolution())
	mesh:setColor(Vec4(1))
	mesh:setRenderLevel(4)
	mesh:compile()

	
	ForceField.mesh = mesh
end

function ForceField.addForceFieldHit(position, maxTime)
	local index = #ForceField.positions + 1
	if index < 20 then
		--print("Field add "..tostring(index).."\n")
		ForceField.positions[index] = position
		ForceField.spawnTime[index] = Core.getGameTime() - 0.05--the ring need to have a head start
		ForceField.lifeTime[index] = maxTime + 0.05
	end
end

function ForceField.update()
	local deltaTime = Core.getDeltaTime()
	local i=1
	while i <= #ForceField.positions do
		if Core.getGameTime() > ForceField.spawnTime[i] + ForceField.lifeTime[i] then
			--print("Field remove "..tostring(i).."\n")
			table.remove(ForceField.positions, i)
			table.remove(ForceField.lifeTime, i)
			table.remove(ForceField.spawnTime, i)
		else
			i = i + 1
		end
	end
	
	ForceField.mesh:setUniform(ForceField.forceFieldShader, "positions", ForceField.positions)
	ForceField.mesh:setUniform(ForceField.forceFieldShader, "spawnTime", ForceField.spawnTime)
	ForceField.mesh:setUniform(ForceField.forceFieldShader, "lifeTime", ForceField.lifeTime)
	ForceField.mesh:setUniformInt( ForceField.forceFieldShader, "numHit", #ForceField.positions)
end