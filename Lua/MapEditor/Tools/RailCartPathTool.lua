require("MapEditor/Tools/Tool.lua")
require("MapEditor/menuStyle.lua")
require("MapEditor/Tools/railwaysModels.lua")
require("MapEditor/Tools/Models/lineModel.lua")
--this = SceneNode()


RailCartPathTool = {}
function RailCartPathTool.new(inRailPath)
	
	local self = {}
	local lineModel = nil
	local lineModelRemove = nil
	local previousRailNode = nil
	local selectedIsland = nil
	local islandRailWays = {}
	local points = {}
	local railwayNames = {}
	local railPath = inRailPath
	local lineColor = Vec3(1,0.5,0.125)
	local camera = nil

	grassData = {}	
	islandData = nil
	toCompile = {}
			
	minecartModel = Core.getModel("props/minecart_npc")
	minecartModel:setVisible(false)
	
	this:getRootNode():addChild(minecartModel)
	
	--Load all railpaths
	railways = RailwaysModels.getModelTable()	
	
	for i=1, #railways do
		railwayNames[i] = railways[i].model:getSceneName()
	end
	
	lineModel = LineModel.new(this:getRootNode(), lineColor)
	lineModel.setlinePath({Vec3(), Vec3(2,0,0)})
	lineModel.setVisible(false)
	
	lineModelRemove = LineModel.new(this:getRootNode(), Vec3(1,0,0), 0.15)
	lineModelRemove.setlinePath({Vec3(), Vec3(2,0,0)})
	lineModelRemove.setVisible(false)
	
	camera = this:getRootNode():findNodeByType(NodeId.camera)
	
	function self.newMap(inRailPath)
		railPath = inRailPath
		print("\n\nRail cart path tool New World\n\n\n")
	
	end
	
	function self.loadedMap()
		
	end
	
	function findIslandFromId(islandId)
		local islandList = this:getRootNode():findAllNodeByTypeTowardsLeaf(NodeId.island)
		for i=1, #islandList do
			if islandList[i]:getIslandId() == islandId then
				return islandList[i]
			end
		end
		return nil
	end

	
	
	
	function self.loaded(inRailPath)
		railPath = inRailPath
		
		for i=1, #railPath do
			railPath[i].island = findIslandFromId(railPath[i].islandId)
			railPath[i].mesh = LineModel.new(railPath[i].island, lineColor, 0.075)
			railPath[i].mesh.setlinePath(railPath[i].points)
			
			local minecart = Core.getModel("props/minecart_npc")
			minecart:setCanBeSaved(false)
			railPath[i].island:addChild(minecart)
			minecart:setLocalMatrix( railPath[i].mineCartLocalMatrix )
					
			railPath[i].minecart = minecart			
		end
	end
	
	function self.activated()
		
		minecartModel:setVisible(false)
		Tool.clearSelectedNodes()
		
		previousRailNode = nil
		selectedIsland = nil
		islandRailWays = {}
		
		--check if there exist data to init
		print("activated\n")
	end
	
	function self.deActivated()

		minecartModel:setVisible(false)
		lineModel.setVisible(false)
		
		previousRailNode = nil
		selectedIsland = nil
		islandRailWays = {}
		
		print("Deactivated\n")
	end
	
	function isAAceptedRailwayModel(sceneNode)
		for i=1, #railways do
			if sceneNode:getSceneName() == railways[i].model:getSceneName() then
				return railways[i]
			end
		end
		return nil
	end
	
	function getAllRailways(island)
		if selectedIsland ~= island then
			selectedIsland = island
			islandRailWays = island:findAllNodeByNameTowardsLeaf(railwayNames)
		end
		return islandRailWays
	end
	
	
	function getAllRailwaysFromPos(position)
		local outList = {}
		for i=1, #islandRailWays do
			local info = isAAceptedRailwayModel(islandRailWays[i])
			if ((islandRailWays[i]:getGlobalMatrix() * info.offset:inverseM()):getPosition()-position):length() < 0.2 then
				outList[#outList+1] = islandRailWays[i]
			end
		end
		return outList
	end
	
	function getRailwayLineFromNode(sceneNode)
		local railwayLine = {}
		railwayLine[1] = sceneNode
		local rails = getAllRailwaysFromPos(sceneNode:getGlobalPosition())
		
		while #rails == 1 do
			railwayLine[#railwayLine+1] = rails[1]
			rails = getAllRailwaysFromPos(railwayLine[#railwayLine]:getGlobalPosition())
		end
		
		return railwayLine
	end
	
	function self.collisionAginstMinecartLines()
		local spawnArea = nil
		local index = nil
		local minDistance = math.huge
		local globalLine = camera:getWorldLineFromScreen(Core.getInput():getMousePos())
		for i=1, #railPath do
			local collision, position = railPath[i].mesh.collision(globalLine)
			if collision then
				minDistance = (position - globalLine.startPos):length()
				spawnArea = railPath[i]
				index = i
			end
		end
		return spawnArea, index, minDistance	
	end
	
	function self.update()
		local save = false
		local spawnPath, spawnIndex = self.collisionAginstMinecartLines()
		if spawnPath then
			lineModel.setVisible(false)
			minecartModel:setVisible(false)
			lineModelRemove.setVisible(true)
			lineModelRemove.setlinePath(spawnPath.globalPoints)
			
			if Core.getInput():getMouseDown(MouseKey.left) then
				--remove model from island
				spawnPath.mesh.destroy()
				spawnPath.minecart:destroy()
				spawnPath.minecart = nil
				--remove information from table
				table.remove(railPath, spawnIndex)
				save = true
				
				lineModelRemove.setVisible(false)
			end
		else
			lineModelRemove.setVisible(false)
			local node, collisionPos, collisionNormal = Tool.getCollision(true)
			--node = SceneNode()
			
			if collisionPos then
				Core.addDebugSphere(Sphere(collisionPos, 0.5), 0, Vec3(1))
			end
			
			local railWay = node and isAAceptedRailwayModel(node) or nil
			if railWay then		
				islandRailWays = getAllRailways(node:findNodeByTypeTowardsRoot(NodeId.island))
				
				minecartModel:setVisible(true)		
				lineModel.setVisible(true)
				
				if Core.getInput():getMousePressed( MouseKey.left ) then
					
					local island = node:findNodeByTypeTowardsRoot(NodeId.island)
					local mesh = LineModel.new(island, lineColor, 0.075)
					local localPoints = {}
					local invIslandMatrix = island:getGlobalMatrix():inverseM()
					for i=1, #points do
						localPoints[i] =  invIslandMatrix * points[i]
					end
					mesh.setlinePath(localPoints)
					
					
					local minecart = Core.getModel("props/minecart_npc")
					minecart:setCanBeSaved(false)
					island:addChild(minecart)
					minecart:setLocalMatrix( invIslandMatrix * minecartModel:getGlobalMatrix() )
					
					--getId() is defined in pathTool.lua
					railPath[#railPath+1] = { id = getId(), points = localPoints, island = island, islandId = island:getIslandId(), mesh = mesh, minecart = minecart, globalPoints = points, 
												position = invIslandMatrix * collisionPos, mineCartLocalMatrix = minecart:getLocalMatrix()}
					save = true			
					previousRailNode = nil
				elseif previousRailNode ~= node then
					previousRailNode = node
					local offset = Vec3(0,0.1,0)
					local railwayLine = getRailwayLineFromNode(node)
					
					points = {}
					
					local startMatrix = railwayLine[1]:getGlobalMatrix() * isAAceptedRailwayModel(railwayLine[1]).offset:inverseM()
					
					points[1] = startMatrix:getPosition() + offset
					local previousMatrix = startMatrix
					for i=1, #railwayLine do
						if previousMatrix:getAtVec():dot(railwayLine[i]:getGlobalMatrix():getAtVec()) > 0.95 then
							points[#points+1] = railwayLine[i]:getGlobalPosition()
						else
							local railMatrix = railwayLine[i]:getGlobalMatrix()
							local length = (previousMatrix:getPosition() - railwayLine[i]:getGlobalPosition()):length()
							if length < 1.5 then
								length = length *0.5
							elseif length < 2.5 then
								length = length * 0.8
							end
							
							local tab = math.bezierCurve3D(previousMatrix:getPosition(), previousMatrix:getPosition() + previousMatrix:getAtVec() * length * 0.55, railMatrix:getPosition() - railMatrix:getAtVec() * 0.55, railMatrix:getPosition(), 4 + length * 2 )
							for n=2, #tab do
								points[#points+1] = tab[n] 
							end
						end
						previousMatrix = railwayLine[i]:getGlobalMatrix()
					end
					
					for i=1, #points do
						points[i] = points[i] + offset
					end
					
					--set model position
					minecartModel:setLocalMatrix(startMatrix)
					
					--create line
					lineModel.setlinePath(points)
					
				end
			else
				lineModel.setVisible(false)
				minecartModel:setVisible(false)
			end
		end
		return save
	end
	return self
end