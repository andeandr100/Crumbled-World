--this = Island()

IslandMeshImporter = {}
function IslandMeshImporter.new()
	
	local self = {}
	local staticNode = SceneNode()
	local staticDensityNode = nil
	local modelDensity = 2.0
	
	function self.getStaticNode()
		return staticNode
	end
	
	function self.import(modelGroup, fileNode)
		if modelDensity == Settings.modelDensity.getValue() then
			return
--		else
--			return
		end
		
		
		modelDensity = Settings.modelDensity.getValue()
		
		if staticDensityNode then
			staticDensityNode:destroy()
			staticDensityNode = nil
		end
		staticDensityNode = SceneNode()
		staticNode:addChild(staticDensityNode)
		
		
		
		print("Load models")
		modelGroupIndex = 1
		for i=2, #modelGroup do
			if math.abs( modelDensity - modelGroup[modelGroupIndex].value ) > math.abs( modelDensity - modelGroup[i].value ) then
				modelGroupIndex = i
			end
		end
		
		print("Islan modelData: "..tostring(modelGroup).."\n")
		print("modelGroupIndex: "..modelGroupIndex.."\n")

		if modelGroup[modelGroupIndex] then
			local modelInfo = modelGroup[modelGroupIndex].models
			print("modeinfo: "..tostring(modelInfo).."\n")
			for i=1, #modelInfo do
				nodeMesh = NodeMesh()
				
				print("add mesh\n")
				
				local file = fileNode:getFile(modelInfo[i].modelName)	
				
				nodeMesh:setData2(file)
				
				nodeMesh:setLocalPosition(modelInfo[i].localPosition)
--				nodeMesh:setColor(Vec4(math.randomFloat(),math.randomFloat(),math.randomFloat(),1.0))
				nodeMesh:compile()
				
				staticDensityNode:addChild(nodeMesh)
			end
		end

	end
	
	local function init()
		--create a bound volme for all static nodes
		staticNode:createBoundVolumeGroup()
		staticNode:setBoundingVolumeCanShrink(false)
		--no updates is needed
		staticNode:setEnableUpdates(false)
		--add static node to the island
		this:addChild(staticNode)
		
	end
		
	init()
	return self
end