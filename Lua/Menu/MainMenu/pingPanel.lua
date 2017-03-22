--this = SceneNode()

PingPanel = {}

--panelSize = is a class object of type Panelsize()
--ping = ping in seconds
function PingPanel.new(panelSize, ping)
	local self = {}
	local panel
	local renderMesh
	local maxPos
	local thePing = ping
	local isResized = false
	
	
	local function addBox(minPos, maxPos, color)
		renderMesh:addVertex(Vec2(minPos.x, minPos.y), color)
		renderMesh:addVertex(Vec2(maxPos.x, minPos.y), color)
		renderMesh:addVertex(Vec2(maxPos.x, maxPos.y), color * 0.8)
		
		renderMesh:addVertex(Vec2(minPos.x, minPos.y), color)
		renderMesh:addVertex(Vec2(maxPos.x, maxPos.y), color * 0.8)
		renderMesh:addVertex(Vec2(minPos.x, maxPos.y), color * 0.8)
	end

	local function resize()
		isResized = true
		maxPos = panel:getPanelContentPixelSize()
		print("\n\n\n")
		print("MaxPos: "..maxPos.y)
		
		local color = Vec4( (thePing < 0.2) and Vec3(0,0.9,0) or ( (thePing < 0.4) and Vec3(0.9,0.45,0.15) or Vec3(0.92,0,0) ), 1)
		local offset = maxPos.y * 0.1
		local height = maxPos.y - offset * 2
		local width = height / 3
		
		renderMesh:clearMesh()
		
		addBox( Vec2(offset, offset + (height/3)*2), Vec2(offset + width, maxPos.y - offset), color )
		addBox( Vec2(offset, offset + (height/3)*1) + Vec2(width*1.2,0), Vec2(offset + width, maxPos.y - offset) + Vec2(width*1.2,0), color )
		addBox( Vec2(offset, offset + (height/3)*0) + Vec2(width*2.4,0), Vec2(offset + width, maxPos.y - offset) + Vec2(width*2.4,0), color )
		
		renderMesh:compile()
	end
	
	--ping is in seconds
	function self.setPing(ping)
		thePing = ping	
		if isResized then
			resize()
		end
		
--		panel:setToolTip(String(tostring(math.round(thePing*1000)).."ms"))
	end
	
	function self.getPanel()
		return panel
	end
	
	local function init()
		panel = Panel(panelSize)
		panel:addEventCallbackResized(resize)
		panel:setCanHandleInput(false)
		
		renderMesh = Node2DMesh()
		panel:addRenderObject(renderMesh)
		
		self.setPing(ping)	
	end
	
	init()
	
	return self
end