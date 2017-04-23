--this = SceneNode()
function create()
	if Core.isInMultiplayer() then
		Core.setScriptNetworkId("TimeSync")
		comUnit = Core.getComUnit()
		comUnit:setCanReceiveTargeted(true)
		
		comUnitTable = {}
		comUnitTable["addDropTime"] = addDropTime
		Core.clearLostTime()
		return true
	else
		return false	
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