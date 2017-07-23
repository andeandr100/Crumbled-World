--this = SceneNode()
function create()
	
	return true
end

function update()
	
	local bilboard = Core.getGlobalBillboard("MapEditor")

	local rootNode = bilboard:getSceneNode("RootNode")
	
	Editor.export(bilboard:getString("exportToFile"), bilboard:getBool("exportLuaFiles"))
	
	--restore
	local islands = rootNode:findAllNodeByTypeTowardsLeaf(NodeId.island)
	for i=1, #islands do
		local islandScript = islands[i]:getScriptByName("island")
		if islandScript then
			islandScript:callFunction("exportDone")
			print("Island script found\n")
		else
			print("No island script found\n")
		end
		print("Found island\n")
	end
	print("export done\n\n\n\n")
	
	return false
end