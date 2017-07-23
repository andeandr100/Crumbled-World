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
	
	lifeBarCound = 0

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
		
		--remove all souls that  do not have 100% life
		local i=1
		while i<=#soulList do
			local soul = soulList[i]
			local ignore = targetSelector.isTargetInState(soul.index, state.ignore)
			local highPrio = targetSelector.isTargetInState(soul.index, state.highPriority)
			if soul.hp==soul.hpMax and ignore == false and highPrio == false then
				if showOnlyDamagedNpcs then
					soulList[i] = soulList[#soulList]
					soulList[#soulList] = nil
					i = i - 1
				end
			else
				soulList[i].ignore = ignore
				soulList[i].highPrio = highPrio
			end
			i = i + 1
		end
		
		
		--display all the souls on the map
		local souls = #soulList
		if lifeBarCound ~= souls or souls > 0 then
			lifeBarCound = souls
			nodeMesh:clearMesh()
			for i=1, souls do
				local soul = soulList[i]
				nodeMesh:addPosition(Vec4( soul.position + Vec3(0,1.1,0),soul.hp/soul.hpMax))
				if soul.ignore then
					--is in state ignore (ignore state overrides highPriority)
					nodeMesh:addNormal(Vec3(1.0,0.0,showDamageValue))
				elseif soul.highPrio then
					--is in state highPriority
					nodeMesh:addNormal(Vec3(0.0,1.0,showDamageValue))
				else
					nodeMesh:addNormal(Vec3(0,0,showDamageValue))
				end
				nodeMesh:addIndex(i-1)
			end
			for i=souls+1, 120 do
				nodeMesh:addNormal(Vec3(0))
				nodeMesh:addPosition(Vec4( Vec3(0,-1,0),0.0))
			end
			nodeMesh:compile()
			nodeMesh:setBoundingSphere(Sphere(camera:getGlobalPosition(), 5.0))
		end
	end
	
	return true
end