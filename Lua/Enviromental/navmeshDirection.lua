--this = SceneNode()
local defaultUpdate = update
function create()
	
	navmeshDirectionData = nil
	
	navmeshDirectionListener = Listener("Navmesh direction node")
	navmeshDirectionListener:registerEvent("Change", changed)
	
	print("\n")
	print("############################\n")
	print("############################\n")
	print("############################\n")
	print("############################\n")
	print("\n")
	
	return true
end

function changed( tab )
	print(" -- changed -- ")
	navmeshDirectionData = tab
end

function export()
	print(" -- NAV MESH DIRECTION EXPORT -- ")
	return saveFunction()
end

function save()
	print(" -- NAV MESH DIRECTION SAVE -- ")
	return saveFunction()
end

function saveFunction()

	if navmeshDirectionData then
		print("NavMeshDirection data: "..tabToStrMinimal( navmeshDirectionData ).."\n")
		return "table="..tabToStrMinimal( navmeshDirectionData )
	end	

	return "table={}"
end


function load(inData)
	print(" -- NAV MESH DIRECTION LOAD -- ")
	print(" - DATA: " .. inData)
	navmeshDirectionData = totable( inData )
	navmeshDirectionListener:pushEvent("Loaded", navmeshDirectionData)
	
	local navMesh = this:getPlayerNode():findNodeByTypeTowardsLeafe(NodeId.navMesh)
	if navmesh then
		initNavMeshDirection(navmesh)
	elseif Core.isInEditor() == false then
		update = specialUpdate
	end
end

function initNavMeshDirection( navMesh )
	print(" -- ")
	print(" -- NAV MESH ADDINIG DIRECTION DATA DIRECTION -- ")
	print(" -- ")
	local navMeshNode = ConvertToNavMesh( navMesh )
	for i=1, #navmeshDirectionData do
		local pos = navmeshDirectionData[i].mat:getPosition()
		local dir = navmeshDirectionData[i].mat:getRightVec()
		navMeshNode:addDirectionalPoint(pos, -dir)
	end

end

function specialUpdate()
	print(" specialUpdate() ")
	local navMesh = this:getPlayerNode():findNodeByTypeTowardsLeafe(NodeId.navMesh)
	if navMesh then
		initNavMeshDirection(navMesh)
		return false
	end
	return true
end

function update()
	return Core.isInEditor()
end