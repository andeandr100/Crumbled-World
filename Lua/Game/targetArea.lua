--this = SceneNode()

TargetArea = {}
function TargetArea.new()
	local self = {}
	local mesh
	local sphereShader = Core.getShader("targetArea", "SPHERE")
	local targetAreaLineShader = Core.getShader("targetArea", "LINE")
	local targetAreaConeShader = Core.getShader("targetArea", {"SPHERE","CONE"})
	local targetAreaSphereConeShader = Core.getShader("targetArea", {"SPHERE","CONE","NOANGLERESTRICTION"})
	local meshNumExtraRange = 0
	local meshExtraRange = {}
	local meshExtraRangeColor = {Vec4(1,0,0,0.5),Vec4(1,1,0,0.35),Vec4(0,1,1,0.2)}
	local nodeArea = SceneNode()
	local curentShader = sphereShader
	
	
	function self.setExtraRangeInfo(num, ranges, colors)
		meshNumExtraRange = num
		meshExtraRange = ranges
		meshExtraRangeColor = colors
	end
	
	function self.hiddeTargetMesh()
		nodeArea:setVisible(false)
		mesh:setVisible(false)
	end
	
	function self.destroyTargetMesh()
		if nodeArea then
			self.hiddeTargetMesh()
			nodeArea:destroyTree()
			nodeArea = nil
		end
	end
	
	local function buildTargetAreaMesh(mesh)
		mesh:clearMesh()
	
		mesh:addPosition( Vec3(-2,-2, -1) )
		mesh:addPosition( Vec3( 2,-2, -1) )
		mesh:addPosition( Vec3(-2, 2, -1) )
		mesh:addPosition( Vec3( 2, 2, -1) )
	
		mesh:addTriangleIndex(0,1,2)
		mesh:addTriangleIndex(2,1,3)
	
		mesh:compile()
	end
	
	local function initTargetMesh()
		--Sphere
		mesh = NodeMesh()
		mesh:setRenderLevel(6)
		nodeArea:addChild(mesh)
		buildTargetAreaMesh(mesh)
		mesh:setShader(curentShader)
		
		--find main camera
		local rootNode = this:getRootNode()
		rootNode:addChild(nodeArea)
		mainCamera = rootNode:findNodeByName("MainCamera")
		
		self.hiddeTargetMesh()
	end
	
	local function setDefaultData( position, range)
		mesh:setShader(curentShader)
		mesh:setBoundingSphere(Sphere(position, 5.0))
		mesh:setUniform(curentShader, "ScreenSize", Core.getRenderResolution())
		mesh:setUniform(curentShader, "CenterPosition", position)
		mesh:setUniform(curentShader, "Radius", range)
		mesh:setUniformInt(curentShader, "NumExtraRange", meshNumExtraRange)
		mesh:setUniform(curentShader, "ExtraRange", meshExtraRange)
		mesh:setUniform(curentShader, "ExtraRangeColor", meshExtraRangeColor)
	end
	
	local function createTargetSphere(position, range)
		curentShader = sphereShader
		setDefaultData( position, range)
	end
	
	local function createCapsule(towerMatrix, length)
		curentShader = targetAreaLineShader
		setDefaultData( towerMatrix:getPosition(), 1.5)
		mesh:setUniform(curentShader, "LineStart", towerMatrix:getPosition())
		mesh:setUniform(curentShader, "LineEnd", towerMatrix * Vec3(0,0,length))		
	end
	
	local function createCone(towerMatrix, range, angle)
		curentShader = targetAreaConeShader
		setDefaultData( towerMatrix:getPosition(), range)
		mesh:setColor(Vec4(0.2,0.2,1.0,0.15))
		mesh:setUniform(curentShader, "AtVec", Vec3(towerMatrix:getAtVec().x, 0, towerMatrix:getAtVec().z):normalizeV())
		mesh:setUniform(curentShader, "AtVecLeft", towerMatrix * (Vec3(math.sin(angle), 0,math.cos(angle)) * range))
		mesh:setUniform(curentShader, "AtVecRight", towerMatrix * (Vec3(math.sin(-angle), 0,math.cos(-angle)) * range))
		mesh:setUniform(curentShader, "Angle", angle)		
	end
	
	local function createConeSphere(towerMatrix, range, angle)
		curentShader = targetAreaSphereConeShader
		setDefaultData( towerMatrix:getPosition(), range)
		mesh:setColor(Vec4(0.2,0.2,1.0,0.15))
		mesh:setUniform(curentShader, "AtVec", Vec3(towerMatrix:getAtVec().x, 0, towerMatrix:getAtVec().z):normalizeV())
		mesh:setUniform(curentShader, "AtVecLeft", towerMatrix * (Vec3(math.sin(angle), 0,math.cos(angle)) * range))
		mesh:setUniform(curentShader, "AtVecRight", towerMatrix * (Vec3(math.sin(-angle), 0,math.cos(-angle)) * range))
		mesh:setUniform(curentShader, "Angle", angle)
	end
	
	
	function self.changeModel(name, range, anglexz, towerMatrix)
		
		local visible = name == "sphere" or name == "capsule" or name == "cone" or name == "coneSphere"
		nodeArea:setVisible(visible)
		mesh:setVisible(visible)
			
		if name == "sphere" then
			createTargetSphere(towerMatrix:getPosition(), range)
		elseif name == "capsule" then
			createCapsule(towerMatrix, range)
		elseif name == "cone" then
			createCone(towerMatrix, range, anglexz)
		elseif name == "coneSphere" then
			createConeSphere(towerMatrix, range, anglexz)
		end
	end
	
	function self.setRenderTarget(node, rangeLevel, colorTabel)
		--node = SceneNode()
		
		if node ~= nil then
			local towerScript = node:getScriptByName("tower")
			if not towerScript then return end
			local towerBilboard = towerScript:getBillboard()
			local targetAreaName = towerBilboard:getString("TargetArea")
			
			if targetAreaName == "sphere" or targetAreaName == "capsule" or targetAreaName =="cone" then
				local targetMatrix = node:getGlobalMatrix()
				
				if targetAreaName == "sphere" then
					local addedRange = towerBilboard:getFloat("rangePerUpgrade")
					self.setExtraRangeInfo( math.max(0,4-rangeLevel), {addedRange,addedRange,addedRange}, colorTabel )
					self.changeModel("sphere", towerBilboard:getFloat("range"), 0, targetMatrix)
				elseif targetAreaName == "capsule" then
					local addedRange = towerBilboard:getFloat("rangePerUpgrade")
					self.setExtraRangeInfo( math.max(0,4-rangeLevel), {addedRange,addedRange,addedRange}, colorTabel )
					self.changeModel("capsule", towerBilboard:getFloat("range"), 0, targetMatrix)
				elseif targetAreaName == "cone" then
					local addedRange = towerBilboard:getFloat("rangePerUpgrade")
					self.setExtraRangeInfo( math.max(0,4-rangeLevel), {addedRange,addedRange,addedRange}, colorTabel )
					local targetAreaMatrix = towerBilboard:getMatrix("TargetAreaOffset")
					targetAreaMatrix:setPosition(Vec3())
					self.changeModel("cone", towerBilboard:getFloat("range"), towerBilboard:getFloat("targetAngle"), targetMatrix * targetAreaMatrix)
				else
					self.hiddeTargetMesh()	
				end
				return
			end
		end
		self.hiddeTargetMesh()	
	end
	
	initTargetMesh()
	
	return self
end