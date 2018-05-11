require("Enviromental/worldEdgeStuff.lua")
require("Enviromental/islandMeshExporter.lua")
require("Enviromental/islandMeshImporter.lua")
require("Enviromental/MineEntrance.lua")

--this = Island()
local deathManager


function settingsChanged()
	worldEdgeStuff.settingsChanged()
	local fileNode = this:findNodeByType(NodeId.fileNode)
	if fileNode then
		reloadModelData = false
		if meshImporter and islandTable.modelInfo then
			meshImporter.import(islandTable.modelInfo, fileNode)
		end
	else
		reloadModelData = true
	end
end

function destroy()

end

function export()
	print("Export island id: "..this:getIslandId().."\n")		
	local fileNode = this:findNodeByType(NodeId.fileNode)

	islandTable = {}
	islandTable.edgeInfo = worldEdgeStuff.export(this)
	
	islandExporter = IslandMeshExporter.new()
	islandTable.modelInfo = islandExporter.export(fileNode)
	islandExporter.hideExportedMeshes()
	
	print("\n\nIsland:export() "..tostring(islandTable).."\n")
	return "table="..tabToStrMinimal(islandTable)
end

function exportDone()
	if islandExporter then
		islandExporter.showHidenNodes()
		islandExporter.destroy()
		islandExporter = nil
	end
end

function save()
	return "table="..tabToStrMinimal({})
end

function load(message)
	if Core.isInEditor() then
		return
	end
--	print("Island message: "..message.."\n")
	islandTable = totable(message)
	meshImporter = IslandMeshImporter.new()
	
	local fileNode = this:findNodeByType(NodeId.fileNode)
	if fileNode then
		reloadModelData = false
		if islandTable.modelInfo then
			meshImporter.import(islandTable.modelInfo, fileNode)
		end
	else
		reloadModelData = true
	end
	
	if islandTable.edgeInfo then
		dynamicNode = SceneNode.new()
		dynamicNode:createBoundVolumeGroup()
		dynamicNode:setBoundingVolumeCanShrink(false)
		this:addChild(dynamicNode)
		
		worldEdgeStuff.load( islandTable.edgeInfo, this, meshImporter.getStaticNode(), dynamicNode)
	else
		worldEdgeStuff.init(this, meshImporter.getStaticNode(), dynamicNode)
	end

end

function create()
	
	this:loadLuaScript("Enviromental/waterMelon.lua")
	
	islandTimeOffset = math.randomFloat(0,32)
	timeOffset = 0
	islandStartPosition = this:getLocalPosition()
	
	if Core.isInEditor() then
		return true
	end
	
	this:createBoundVolumeGroup()
	
	local nodes = this:findAllNodeByNameTowardsLeaf("mine")
	local mineLocation = {}
	for i=1, #nodes do
		mineLocation[#mineLocation+1] = this:getGlobalMatrix():inverseM() * nodes[i]:getGlobalMatrix()
	end
	
	statsBilboard = Core.getBillboard("stats")
	
	--
	Core.setUpdateHzRealTime(24)
	
	local staticIslandBilboard = Core.getGameSessionBillboard("staticIslandMeshList")

	
	
	
	for i=1, #mineLocation do
		MineEntrance.create(this, mineLocation[i])
	end
	
	settingsListener = Listener("Settings")
	settingsListener:registerEvent("Changed", settingsChanged)
	settingsChanged()
	
	return true
end

function update()
	
	if reloadModelData then
		local fileNode = this:findNodeByType(NodeId.fileNode)
		if fileNode then
			reloadModelData = false
			if islandTable and islandTable.modelInfo then
				meshImporter.import(islandTable.modelInfo, fileNode)
			end
		end
	end
	
	worldEdgeStuff.update()
	
	
	if timeOffset == 0 and statsBilboard and statsBilboard:getInt("wave") == 1 then
		--this is needed for network gameSync
		--when the first round starts all islands on the map will be in the same location for all games
		timeOffset = Core.getGameTime()
	end
	
	local time = (Core.getGameTime()-timeOffset) * 0.03 + islandTimeOffset
	this:setNextLocalPosition( islandStartPosition + Vec3(math.sin(time), 0, math.sin(time)):normalizeV() * math.cos(time) * 0.5)
	

	return true
end