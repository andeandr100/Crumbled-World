require("Menu/Campaign/islandInfo.lua")
--this = SceneNode()
MapPanel = {}
function MapPanel.new(mainAreaPanel, camera)
	--mainAreaPanel = Panel()
	local self = {}
	--camera = Camera()
	local islands = {}
	local selectedIsland = nil
	local form = mainAreaPanel:getForm()
	local iconSize = 0.075
	local iconSizeSelected = 0.090
	
	local lines = {}
	local lineMesh = Node2DMesh()
	local islandInfo = IslandInfo.new(camera)
	
	function self.destroy()
		islandInfo.destroy()
	end
	
	--Add a island to the map
	function addIsland(position, uvCoordOffset, canBePlayed, mapName, inFilePath)
		
		--Remove top menu bar from the yPosition
		position.y = position.y * 0.95 + 0.05
		
		local winSize = Core.getScreenResolution()
		local pixelSize = Vec2( math.max( winSize.x * iconSize, winSize.y * iconSize ) )
		
		local data = {}
		islands[#islands + 1] = data
		
		data.canBePlayed = canBePlayed
		data.sprite = Sprite(Core.getTexture("islandIcon.tga"))
		data.sprite:setUvCoord(uvCoordOffset, uvCoordOffset + Vec2(0.2,0.2))
		data.sprite:setLocalPosition(winSize * position )
		data.sprite:setSize(pixelSize)
		data.sprite:setAnchor(Anchor.MIDDLE_CENTER)
		data.sprite:setColor(canBePlayed and Vec4(1) or Vec4(Vec3(0.3),1))
		data.filePath = inFilePath
		data.centerPos =  winSize * position
		data.islandRadius = pixelSize:length() * 0.50
		data.name = mapName

		mainAreaPanel:addRenderObject(data.sprite)
	end
	
	--add line bettwen two island
	function addLine(startIsland, endIsland)
		lines[#lines + 1] = {startIsland, endIsland}
	end
	
	--pos1 = Vec2()
	--pos2 = Vec2()
	--add a line mesh to line model
	function addLineMesh(pos1, pos2, activeLine)
		
		local color = activeLine and Vec4(1) or  Vec4(Vec3(0.2),1)
		local lineThickness = 3
		local atVec = (pos2-pos1):normalizeV()
		local rightVec = Vec3(atVec.x, atVec.y, 0):crossProductV(Vec3(0,0,1)):toVec2() * lineThickness
		
		lineMesh:addVertex( pos1 + rightVec, color )
		lineMesh:addVertex( pos1 - rightVec, color )
		lineMesh:addVertex( pos2 - rightVec, color )
		
		lineMesh:addVertex( pos2 - rightVec, color )
		lineMesh:addVertex( pos2 + rightVec, color )
		lineMesh:addVertex( pos1 + rightVec, color )
	end
	
	--Update the line mesh with the current data
	function updateLineMesh()
		lineMesh:clearMesh()
		for i=1, #lines do
			local island1 = islands[lines[i][1]]
			local island2 = islands[lines[i][2]]
			local activeLine = island1.canBePlayed and island2.canBePlayed
			
			addLineMesh( island1.centerPos, island2.centerPos, activeLine )
		end
		lineMesh:compile()
	end
	
	local function getMapVec(position)
		--gridSize == 5
		return Vec2((position%5-1)*0.2, 0.8-(math.floor((position-1)/5)*0.2))
	end
	--Init all island and information
	function init()
		mainAreaPanel:addRenderObject(lineMesh)

		local maps = {	"Data/Map/world0.map","Data/Map/world0_tut2.map","Data/Map/world0_tut3.map","Data/Map/world_train_line.map","Data/Map/world2.map",
						"Data/Map/world4.map","Data/Map/world_towny.map","Data/Map/world_circular.map","Data/Map/world_train_station.map","Data/Map/world_flat.map",
						"Data/Map/world_quadruple.map","Data/Map/world_split.map","Data/Map/world_train_splitline.map","Data/Map/world_selection.map","Data/Map/world1.map",
						"Data/Map/world_train_mine.map","Data/Map/world3.map","Data/Map/world_eulers_bridge.map","Data/Map/world_triple_entry.map","Data/Map/world_train_dock.map",
						"Data/Map/world_trimid.map"}
		
		addIsland( Vec2(0.094, 0.094), getMapVec(1), true, "world 1", maps[1])
		addIsland( Vec2(0.196, 0.196), getMapVec(2), true, "world 2", maps[2])
		addIsland( Vec2(0.284, 0.284), getMapVec(3), true, "world 3", maps[3])	
		addIsland( Vec2(0.405, 0.405), getMapVec(4), true, "world 4", maps[4])
		addIsland( Vec2(0.598, 0.355), getMapVec(5), true, "world 5", maps[5])
		addIsland( Vec2(0.739, 0.498), getMapVec(6), true, "world 6", maps[6])
		addIsland( Vec2(0.685, 0.691), getMapVec(7), true, "world 7", maps[7])
		addIsland( Vec2(0.350, 0.599), getMapVec(8), true, "world 8", maps[8])
		addIsland( Vec2(0.491, 0.742), getMapVec(9), true, "world 9", maps[9])
		addIsland( Vec2(0.445, 0.188), getMapVec(10), true, "world 10", maps[10])
		addIsland( Vec2(0.638, 0.188), getMapVec(11), true, "world 11", maps[11])
		addIsland( Vec2(0.804, 0.283), getMapVec(12), true, "world 12", maps[12])
		addIsland( Vec2(0.899, 0.448), getMapVec(13), true, "world 13", maps[13])
		addIsland( Vec2(0.899, 0.640), getMapVec(14), true, "world 14", maps[14])
		addIsland( Vec2(0.187, 0.449), getMapVec(15), true, "world 15", maps[15])
		addIsland( Vec2(0.187, 0.640), getMapVec(16), true, "world 16", maps[16])
		addIsland( Vec2(0.278, 0.802), getMapVec(17), true, "world 17", maps[17])
		addIsland( Vec2(0.449, 0.901), getMapVec(18), true, "world 18", maps[18])
		addIsland( Vec2(0.640, 0.901), getMapVec(19), true, "world 19", maps[19])
		addIsland( Vec2(0.805, 0.805), getMapVec(20), true, "world 20", maps[20])
		addIsland( Vec2(0.893, 0.893), getMapVec(21), true, "world 21", maps[21])
				
		addLine(1,2)
		addLine(2,3)
		
		addLine(3,4)
		
		addLine(4,5)
		addLine(5,6)
		addLine(6,7)
		
		addLine(4,8)
		addLine(8,9)
		addLine(9,7)
		addLine(7,20)
		
		addLine(3,10)
		addLine(10,11)
		addLine(11,12)
		addLine(12,13)
		addLine(13,14)
		addLine(14,20)
		
		addLine(3,15)
		addLine(15,16)
		addLine(16,17)
		addLine(17,18)
		addLine(18,19)
		addLine(19,20)
		
		addLine(20,21)
		
		updateLineMesh()
	end
	--Call init function
	init()

	
	function setSelectedIsland(aIsland)
		if selectedIsland and selectedIsland ~= aIsland then
			local winSize = Core.getScreenResolution()
			local pixelSize = Vec2( math.max( winSize.x * iconSize, winSize.y * iconSize ) )
			selectedIsland.sprite:setSize(pixelSize)
		end
		
		if aIsland then
			local winSize = Core.getScreenResolution()
			local pixelSize = Vec2( math.max( winSize.x * iconSizeSelected, winSize.y * iconSizeSelected ) )
			aIsland.sprite:setSize(pixelSize)
		end
		
		selectedIsland = aIsland
	end
	
	function self.setShopVisible(visible)
		if visible then
			islandInfo.setVisible(false)
		end
	end
	
	--Update the map panel
	function self.update()
		
		local panel = Form.getPanelFromGlobalPos(Core.getInput():getMousePos())
		local hasThisFormMouseFocus = not panel and true or panel:getForm():getPanelId() == form:getForm():getPanelId()
		
		if hasThisFormMouseFocus then
			local localMousePos = Core.getInput():getMousePos() - Vec2(mainAreaPanel:getMinPos().x, mainAreaPanel:getMinPos().y)
			--Check if an island icon should be highlighted
			local selectIsland = nil
			local minDist = math.huge
			for i=1, #islands do
				local dist = (islands[i].centerPos - localMousePos):length()
				if minDist > dist and dist<islands[i].islandRadius and islands[i].canBePlayed then
					minDist = dist
					selectIsland = islands[i]
				end
			end
			--highlighted or deselect an island
			setSelectedIsland(selectIsland)
			
			--Check if the island info window should be hidden
			if Core.getInput():getMouseDown(MouseKey.left) then
				if selectIsland then
					islandInfo.setVisible(true)
					islandInfo.setData(selectIsland.filePath, selectIsland.name)
				else
					islandInfo.setVisible(false)
				end
			end
		else
			--No island can be highlighted
			setSelectedIsland(nil)
		end
		
		--Update island info window
		islandInfo.update()
	end
		
	return self
end