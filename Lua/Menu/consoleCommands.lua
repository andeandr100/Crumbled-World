----this = SceneNode()
--function create()
--	
--	Core.getBillboard("console")
--	
--	--billboard
--	comUnit = Core.getComUnit()
--	comUnit:setName("console")
--	billboard = comUnit:getBillboard()
--	
--	--comUnit
--	comUnit = Core.getComUnit()
--	comUnit:setCanReceiveTargeted(true)
--	
--	--ComUnitCallbacks
--	comUnitTable = {}
--	comUnitTable["run"] = executeCommand
--	
--	--thisScript
--	script = this:getCurrentScript()
--	
--	return true
--end
--
--function executeCommand(command)
--	print("script:doString("..command..")\n")
--	script:doString(Text(command))
--end
--
--function update()
--	--Handle communication
--	while comUnit:hasMessage() do
--		local msg = comUnit:popMessage()
--		if comUnitTable[msg.message]~=nil then
--			comUnitTable[msg.message](msg.parameter,msg.fromIndex)
--		else
--			print("["..msg.message.."]("..msg.parameter..","..msg.fromIndex..")\n")
--		end
--	end
--	return true
--end