--this = SceneNode()
function create()
	--Protection in multiplayer environment where multiple instances of this script is loaded
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	if not Core.isInMultiplayer() or ( node == nil and this:getSceneName() ~= "TimeSyncNode" ) or ( node and node:getClientId() ~= 0 ) then
		return false
	end
	
	if this:getNodeType() == NodeId.playerNode then
		local menuNode = this:getRootNode():addChild(SceneNode())
		--camera = Camera()
		menuNode:setSceneName("TimeSyncNode")
		menuNode:createWork()
				
		--Move this script to the root node
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		return false
	else
		Core.setScriptNetworkId("TimeSync")
		comUnit = Core.getComUnit()
		comUnit:setCanReceiveTargeted(true)
		
		comUnitTable = {}
		comUnitTable["addDropTime"] = addDropTime
		Core.clearLostTime()
		return true	
	end
end

function addDropTime(param)
	Core.addTimeToDrop(tonumber(param))
end

function update()
	
	if Core.getLostTime() > 0.01 then
		local lostTime = Core.getLostTime()
		Core.clearLostTime()
		comUnit:sendNetworkSyncSafe("addDropTime", tostring(lostTime))
	end
	
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message]~=nil then
			comUnitTable[msg.message](msg.parameter)
		end
	end
	return true
end