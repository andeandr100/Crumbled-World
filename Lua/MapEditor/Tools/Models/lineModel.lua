--this = SceneNode()

LineModel = {}
function LineModel.new(inParentNode, inColor, size)
	--inParentNode = SceneNode()
	local self = {}
	local mesh = NodeMesh()
	local color = inColor
	local points = {}
	local w = size and size or 0.075
	
	function self.setVisible(visible)
		mesh:setVisible(visible)
	end
	
	function self.setColor(inColor)
		color = inColor
	end
	
	function self.destroy()
		mesh:destroy()
		mesh = nil
	end
	
	function self.collision(globalLine)
		local inverseMat = mesh:getGlobalMatrix():inverseM()
		local localLine = Line3D( inverseMat * globalLine.startPos, inverseMat * globalLine.endPos)
		for i=2, #points do
			local distance, collpos1 = Collision.lineSegmentLineSegmentLength2(Line3D(points[i-1], points[i]),localLine)
			if math.sqrt(distance) < 0.15 then
				return true, collpos1
			end
		end
		return false, nil
	end

	function self.setlinePath(inPoints)
		points = inPoints
		if #points < 2 then
			mesh:setVisible(false)
			return
		else
			mesh:setVisible(true)
		end
		
		mesh:clearMesh();
		
		local w = 0.075
		for i=1, #points do
			local centerPos = points[i]
			local atVec = i==1 and (points[i+1]-points[i]):normalizeV() or (points[i]-points[i-1]):normalizeV()
			local upVec = Vec3(0,1,0):dot(atVec) > 0.7 and Vec3(0,1,0):crossProductV(atVec) or Vec3(0,1,0)
			local rightVec = upVec:crossProductV(atVec)
			
			if i==1 then
				
				index = mesh:getNumVertex()
				mesh:addVertex(centerPos - rightVec * w + upVec * w, color*0.4)
				mesh:addVertex(centerPos - rightVec * w - upVec * w, color*0.4)
		
				mesh:addVertex(centerPos + rightVec * w - upVec * w, color*0.4)
				mesh:addVertex(centerPos + rightVec * w + upVec * w, color*0.4)
				
				mesh:addIndex(index + 0)
				mesh:addIndex(index + 1)
				mesh:addIndex(index + 2)
				
				mesh:addIndex(index + 2)
				mesh:addIndex(index + 3)
				mesh:addIndex(index + 0)
			end
			
			
			local index = mesh:getNumVertex()
			mesh:addVertex(centerPos + rightVec * w + upVec * w, color)
			mesh:addVertex(centerPos - rightVec * w + upVec * w, color)
			mesh:addVertex(centerPos - rightVec * w + upVec * w, color*0.7)
			mesh:addVertex(centerPos - rightVec * w - upVec * w, color*0.7)
			mesh:addVertex(centerPos - rightVec * w - upVec * w, color*0.5)
			mesh:addVertex(centerPos + rightVec * w - upVec * w, color*0.5)
			mesh:addVertex(centerPos + rightVec * w - upVec * w, color*0.7)
			mesh:addVertex(centerPos + rightVec * w + upVec * w, color*0.7)

			if i ~= 1 then
				
				for n=index, index+6, 2 do
					mesh:addIndex(n - 8)
					mesh:addIndex(n - 7)
					mesh:addIndex(n - 0)
					
					mesh:addIndex(n - 7)
					mesh:addIndex(n + 1)
					mesh:addIndex(n - 0)
				end
			end
			if i==#points then
				
				index = mesh:getNumVertex()
				mesh:addVertex(centerPos - rightVec * w + upVec * w, color*0.4)
				mesh:addVertex(centerPos - rightVec * w - upVec * w, color*0.4)
		
				mesh:addVertex(centerPos + rightVec * w - upVec * w, color*0.4)
				mesh:addVertex(centerPos + rightVec * w + upVec * w, color*0.4)
				
				mesh:addIndex(index + 0)
				mesh:addIndex(index + 1)
				mesh:addIndex(index + 2)
				
				mesh:addIndex(index + 2)
				mesh:addIndex(index + 3)
				mesh:addIndex(index + 0)
			end
		end
		
		mesh:compile()
		mesh:setBoundingSphere(Sphere( (points[1]+points[#points]) * 0.5, (points[1]+points[#points]):length()))
	end
	
	function init()
		mesh = NodeMesh()
		mesh:setVertexType(VertexType.position3, VertexType.color3)
		inParentNode:addChild(mesh)	
		mesh:setRenderLevel(31)
		mesh:setShader(Core.getShader("toolNormal"))
		mesh:setColor(Vec4(1))
		mesh:setCanBeSaved(false)
		mesh:setCollisionEnabled(false)
	end

	init()
		
	return self
end