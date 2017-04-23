--this = SceneNode()
local defaultUpdate = update
function create()
	
	grassData = nil
	
	grassListener = Listener("Grass node")
	grassListener:registerEvent("Change", changed)
	
	print("\n")
	print("############################\n")
	print("############################\n")
	print("############################\n")
	print("############################\n")
	print("\n")
	
	return true
end

function changed(text)
	grassData = text
end

function export()
	return saveFunction(true)
end

function save()
	return saveFunction(false)
end

function saveFunction(export)
	outData = {}
	local count = 0
	local fileNode = this:findNodeByType(NodeId.fileNode)
	
	--print("Grass save: "..tostring(grassData).."\n")
	
	if grassData then
		for islandId,islandData in pairs(grassData) do
			print("Island "..islandId.."\n")
			outData[islandId] = {}
			--copy local straw data
			if not export then
				outData[islandId].straw = islandData.straw
			end
			--copy the 
			
			for key,subIsland in pairs(islandData) do
				print("3 key: "..key.."\n")
				outData[islandId][key] = {}
				if key ~= "island" then
					for subKey,subIslandData in pairs(subIsland) do
						print("3 sub key: "..subKey.."\n")
						if subKey == "straw" then
							if not export then
								outData[islandId][key].straw = subIslandData
							end
							count = count + #subIslandData
						elseif subKey == "mesh" then
							outData[islandId][key].position = subIslandData:getLocalPosition()
							
							local fileName = "Grass"..islandId..key
							outData[islandId][key].fileName = fileName
							local file = subIslandData:getData(fileName)
							
							
							if fileNode then
								fileNode:addFile(fileName, file)
							end
						end				
					end
				end
				
			end
		end
	end
	print("Num straw: "..count.."\n")

	return "table="..tabToStrMinimal(outData)
end

function createNodeMesh(island, localPosition)
	nodeMesh = NodeMesh()
		
	nodeMesh:setCollisionEnabled(false)
	nodeMesh:setLocalPosition(localPosition)
	local grassShader = Core.getShader("grassSway")
	local grassShaderShadow = Core.getShader("grassSwayShadow")
	local texture = Core.getTexture("grass.tga")

	nodeMesh:setBoundingSphere(Sphere(Vec3(), 17.0))
	nodeMesh:setShader(grassShader)
	nodeMesh:setTexture(grassShader,texture,0)
	nodeMesh:setShadowShader(grassShaderShadow)
	nodeMesh:setTexture(grassShaderShadow,texture,0)
	nodeMesh:setColor(Vec4(1))
	nodeMesh:setRenderLevel(3)
	nodeMesh:setCanBeSaved(false)
	
	
	island:addChild(nodeMesh)
	return nodeMesh
end

function load(inData)
	grassData = {}
	

	local fileNode = this:getRootNode():findNodeByType(NodeId.fileNode)
	local islandList = this:getRootNode():findAllNodeByTypeTowardsLeaf(NodeId.island)
	if fileNode and #islandList > 0 then
	
		local initData = totable( inData )
		
		print("File node found")
		print("Island id list: \n")
		for i=1, #islandList do
			print("\t\tislandId = "..islandList[i]:getIslandId().."\n")
		end
		--print("init data: "..tostring(initData).."\n")
		for islandId,islandData in pairs(initData) do	
			
			--print("num Island Id: "..#islandId.."\n")
			
			--create new empy table
			local islandContainer = {}
			
			--print("Init table done\n")
			
			--find the island
			for i=1, #islandList do
				if islandId == islandList[i]:getIslandId() then
					islandContainer.island = islandList[i]
					print("Island found\n")
				end
			end
			
			if islandContainer.island then
				print("Island detction is over found island "..islandId.."\n")
				grassData[islandId] = islandContainer
				for key,subIsland in pairs(islandData) do
					if key ~= "island" then
						print("SubMesh: "..key.."\n")
						--copy straw data
						islandContainer[key] = {}
						islandContainer[key].straw = subIsland.straw
						
						local file = fileNode:getFile(subIsland.fileName)	
						--create the mesh
						islandContainer[key].mesh = createNodeMesh(islandContainer.island, subIsland.position)
						--set mesh data
						islandContainer[key].mesh:setData(file)
						--compile mesh
						islandContainer[key].mesh:compile()
					end
				end
			else
				print("Failed to find island "..islandId.."\n")
			end
		end
	
		--print("grassData"..tostring(grassData).."\n")
	
		grassListener:pushEvent("Loaded", grassData)
	else
		tmpData = inData
		update = specialUpdate
	end
end

function specialUpdate()
	if this:getRootNode():findNodeByType(NodeId.fileNode) and #this:getRootNode():findAllNodeByTypeTowardsLeaf(NodeId.island) > 0 then
		update = defaultUpdate
		load(tmpData)
	end
	return true
end

function update()
	return true
end