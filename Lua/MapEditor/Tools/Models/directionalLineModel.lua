--this = SceneNode()

DirectionalLineModel = {}
function DirectionalLineModel.new(inParentNode, inColor, size)
	--inParentNode = SceneNode.new()
	local self = {}
	local mesh = NodeMesh.new()
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
	
	function addQuad(mesh, p1, p2, p3, p4, color)
		local offsetIndex = mesh:getNumVertex()
		mesh:addVertex(p1, color)
		mesh:addVertex(p2, color)

		mesh:addVertex(p3, color)
		mesh:addVertex(p4, color)
		
		mesh:addIndex(offsetIndex + 0)
		mesh:addIndex(offsetIndex + 1)
		mesh:addIndex(offsetIndex + 2)
		
		mesh:addIndex(offsetIndex + 2)
		mesh:addIndex(offsetIndex + 1)
		mesh:addIndex(offsetIndex + 3)
	end

	function self.setlinePath(firstPoint, secondPoint)
		
		local lineAtVec = (secondPoint - firstPoint)
		local lineLength = lineAtVec:normalize()
		local arrowLength = math.clamp(lineLength * 0.5, 0.1, 0.7)
		
		points = {firstPoint, ( lineLength > 0.5 ) and secondPoint - lineAtVec * arrowLength or secondPoint}

		mesh:setVisible(true)
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
		end
		
		--Add arrow
		local centerPos = secondPoint - lineAtVec * arrowLength
		local upVec = Vec3(0,1,0):dot(lineAtVec) > 0.7 and Vec3(0,1,0):crossProductV(lineAtVec) or Vec3(0,1,0)
		local lineRightVec = lineAtVec:crossProductV(upVec):normalizeV() * arrowLength * 0.6
		lineAtVec = lineAtVec * arrowLength
		upVec = upVec * w
		
		--Top triangle
		index = mesh:getNumVertex()
		mesh:addVertex(centerPos + lineRightVec + upVec, color)
		mesh:addVertex(centerPos - lineRightVec + upVec, color)
		mesh:addVertex(centerPos + lineAtVec + upVec, color)
		
		--Bottom triangle
		mesh:addVertex(centerPos + lineRightVec - upVec, color)
		mesh:addVertex(centerPos - lineRightVec - upVec, color)
		mesh:addVertex(centerPos + lineAtVec - upVec, color)
		
		mesh:addIndex(index + 0)
		mesh:addIndex(index + 1)
		mesh:addIndex(index + 2)
		
		mesh:addIndex(index + 3)
		mesh:addIndex(index + 5)
		mesh:addIndex(index + 4)
	
		addQuad(mesh, centerPos + lineRightVec + upVec, centerPos + lineAtVec + upVec, centerPos + lineRightVec - upVec, centerPos + lineAtVec - upVec, color * 0.5)
		addQuad(mesh, centerPos + lineRightVec + upVec, centerPos - lineRightVec + upVec, centerPos + lineRightVec - upVec, centerPos - lineRightVec - upVec, color * 0.4)
		addQuad(mesh, centerPos - lineRightVec + upVec, centerPos + lineAtVec + upVec, centerPos - lineRightVec - upVec, centerPos + lineAtVec - upVec, color * 0.6)
		
		mesh:compile()
		mesh:setBoundingSphere(Sphere( (points[1]+points[#points]) * 0.5, (points[1]+points[#points]):length()))
	end
	
	function init()
		
		mesh:setVertexType(VertexType.position3, VertexType.color3)
		inParentNode:addChild(mesh:toSceneNode())	
		mesh:setRenderLevel(31)
		mesh:setShader(Core.getShader("toolNormal"))
		mesh:setColor(Vec4(1))
		mesh:setCanBeSaved(false)
		mesh:setCollisionEnabled(false)
	end

	init()
		
	return self
end