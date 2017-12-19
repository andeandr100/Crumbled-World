require("Menu/settings.lua")
require("Game/targetSelector.lua")
require("NPC/state.lua")

--this = SceneNode()

function create()
	local playerNode = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	targetSelector = TargetSelector.new(1)
	targetSelector.setPosition(Vec3(0))
	targetSelector.setRange(512.0)
	camera = playerNode:getRootNode():findNodeByName("MainCamera")
	
	nodeMesh = NodeMesh(RenderMode.points)
	
	local shader = Core.getShader("lifeBar")
	
	
	nodeMesh:setBoundingSphere(Sphere(Vec3(), 3.0))
	nodeMesh:setShader(shader)
	nodeMesh:setRenderLevel(2)
	nodeMesh:setTexture(shader,Core.getTexture("icon_table.tga"),0)
	
	playerNode:getRootNode():addChild(nodeMesh)
	
	
	settingsListener = Listener("Settings")
	settingsListener:registerEvent("Changed", settingsChanged)
	settingsChanged()
	
	lifeBarCount = 0
	
	normalList = {}
	positionList = {}
	
	for i=1, 120 do
		normalList[i] = Vec3(0)
		positionList[i] = Vec4( 0, -1, 0, 0 )
	end

	return true
end

function settingsChanged()
	nodeMesh:setVisible( Settings.healthBar.getIsVisible() )
	showOnlyDamagedNpcs = Settings.healthBar.getIsVisibleOnlyWhenDamaged()
	showDamageValue = showOnlyDamagedNpcs and 0.0 or 1.0
end

function update()
	
	if nodeMesh:getVisible() and targetSelector.disableRealityCheck() then
		targetSelector.selectAllInRange()
		local soulList = targetSelector.getAllSouls()
		soulList.count = #soulList
		--remove all souls that  do not have 100% life
		local i=1
		while i<=soulList.count do
			local soul = soulList[i]
			local ignore = targetSelector.isTargetInState(soul.index, state.ignore)
			local highPrio = targetSelector.isTargetInState(soul.index, state.highPriority)
			if soul.hp==soul.hpMax and ignore == false and highPrio == false then
				if showOnlyDamagedNpcs then
					soulList[i] = soulList[soulList.count]
					soulList[soulList.count] = nil
					soulList.count = soulList.count - 1
					i = i - 1
				end
			else
				soulList[i].ignore = ignore
				soulList[i].highPrio = highPrio
			end
			i = i + 1
		end
		
		
		--display all the souls on the map
		local souls = soulList.count
		local indexList = {}
		if lifeBarCount ~= souls or souls > 0 then
			lifeBarCount = souls
			nodeMesh:clearMesh()
			local positionOffset = Vec3(0,1.1,0)
			for i=1, souls do
				local soul = soulList[i]
				positionList[i] = Vec4( soul.position + positionOffset,soul.hp/soul.hpMax)
				normalList[i] = Vec3(soul.ignore and 1.0 or 0.0,soul.highPrio and 1.0 or 0.0,showDamageValue)
				indexList[i] = i - 1
			end


			nodeMesh:setPositionsVec4(positionList)
			nodeMesh:setNormals(normalList)
			nodeMesh:setIndices(indexList)
			
			
			nodeMesh:compile()
			nodeMesh:setBoundingSphere(Sphere(camera:getGlobalPosition(), 5.0))
		end
	end
	
	return true
end