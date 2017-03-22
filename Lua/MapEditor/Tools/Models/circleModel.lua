--this = SceneNode()

CircleModel = {}
function CircleModel.new(inParentNode, radius, lineWidth, inColor)
	--inParentNode = SceneNode()
	local self = {}
	local mesh = NodeMesh()
	local color = inColor
	local sphereRadius = radius
	
	function self.setVisible(visible)
		mesh:setVisible(visible)
	end
	
	function self.setPosition(globalPos)
		mesh:setLocalPosition(globalPos)
	end
	
	function self.collision(globalLine)
		local sphere = Sphere( mesh:getGlobalPosition(), sphereRadius)
		return Collision.lineSegmentSphereIntersection( globalLine, sphere )
	end
	
	function self.destroy()
		mesh:destroy()
		mesh = nil
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
		
		
		
		local cos = math.cos
		local sin = math.sin
		local radOffset = math.pi / 16
		local w = lineWidth
		local upVec = Vec3(0,1,0)

		mesh:clearMesh()
		
		for r=0, math.pi*2+radOffset*0.5, radOffset do
			
			local atVec = Vec3(cos(r), 0, sin(r))
			local centerPos = Vec3(atVec.x, w, atVec.z) * radius
		
			local index = mesh:getNumVertex()
			
			mesh:addVertex(centerPos + atVec * w + upVec * w, color * 0.8)
			mesh:addVertex(centerPos - atVec * w + upVec * w, color * 0.8)
			mesh:addVertex(centerPos - atVec * w + upVec * w, color * 0.6)
			mesh:addVertex(centerPos - atVec * w - upVec * w, color * 0.6)
			mesh:addVertex(centerPos - atVec * w - upVec * w, color * 0.5)
			mesh:addVertex(centerPos + atVec * w - upVec * w, color * 0.5)
			mesh:addVertex(centerPos + atVec * w - upVec * w, color * 0.6)
			mesh:addVertex(centerPos + atVec * w + upVec * w, color * 0.6)

	
			if r ~= 0 then
				
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
		
		mesh:setBoundingSphere(Sphere(Vec3(), radius + w))
		mesh:compile()
		
	end

	init()
		
	return self
end