require("Game/Abilities/targetAreaEffect.lua") 
--this = SceneNode()

AttackArea = {}
function AttackArea.new()
	local self = {}
	local nodeArea = SceneNode.new()
	local areaEffect = TargetAreaEffect.new("abilities/attackTargetArea")

	function self.hiddeTargetMesh()
		nodeArea:setVisible(false)
		areaEffect.hiddeTargetMesh()
	end
	
	function self.destroyTargetMesh()
		if nodeArea then
			self.hiddeTargetMesh()
			nodeArea:destroyTree()
			nodeArea = nil
		end
	end
	
	local function initTargetMesh()
	
		areaEffect.setUniform( "Radius", 3)
		nodeArea:addChild(areaEffect.getSceneNode())
		
		--find main camera
		local rootNode = this:getRootNode()
		rootNode:addChild(nodeArea:toSceneNode())
		mainCamera = rootNode:findNodeByName("MainCamera")
		
		self.hiddeTargetMesh()
	end
	
	function self.update(visible, globalposition)
		nodeArea:setVisible(visible)
		areaEffect.update( visible, globalposition)
	end
	
	initTargetMesh()
	
	return self
end