--this = SceneNode()

LobbyChatPanel = {}
function LobbyChatPanel.new(panel, client)
	local self = {}
	local aClient = client
	local chatPanel
	local chatTextField
	local chatHistoryPanel
	local numMsg = 0
	
	local function addMessage(name, text)
		
		local scroll = chatHistoryPanel:getYScrollBar()
		chatHistoryPanel:add(Label(PanelSize(Vec2(1,0.1),PanelSizeType.ParentPercent), Text(name and name ..": " or "") + text, Vec3(1)))
		
		numMsg = numMsg + 1
		if numMsg > 30 then
			chatHistoryPanel:removePanel(chatHistoryPanel:getPanel(0))
		end
		
		if not scroll and chatHistoryPanel:getYScrollBar() then
			scroll = chatHistoryPanel:getYScrollBar()
			scroll:setScrollOffset(scroll:getMaxScrollOffset())
		end
		
	end
	
	function self.updateMsg(msgTag, msgData)
		if msgTag == "Chat" then
			local name,msg = string.match(msgData, "(.*);(.*)")
			addMessage(name, Text(msg))
		elseif msgTag == "systemMsg" then
			addMessage(nil, Text(msgData))
		end
	end
	
	local function callbackExecuteText(textField)
		local aString = textField:getText():toString()
		if aString ~= "" then
			aClient:writeSafe("Chat:"..aClient:getUserName()..";"..aString)
			addMessage(aClient:getUserName(), textField:getText())
		end
		textField:setText("")
	end
	
	local function init()
		chatPanel = panel:add(Panel(PanelSize(Vec2(-1,-1))))
		--chatPanel:setBackground(Gradient(Vec4(1,1,1,0.05), Vec4(1,1,1,0.1)))
		
		chatPanel:setLayout(FallLayout(Alignment.BOTTOM_LEFT, PanelSize(Vec2(0,0.005))))
		
		chatTextField = chatPanel:add(TextField(PanelSize(Vec2(-1,0.03))))
		chatTextField:setBackgroundColor(Vec4(0,0,0,0.25))
		chatTextField:setTextColor(Vec3(1.0))
		chatTextField:addEventCallbackExecute(callbackExecuteText)
		
		chatHistoryPanel = chatPanel:add(Panel(PanelSize(Vec2(-1,-1))))
		chatHistoryPanel:setBackground(Gradient(Vec4(1,1,1,0.05), Vec4(1,1,1,0.1)))
		chatHistoryPanel:setEnableScroll()
		chatHistoryPanel:setBorder(Border(BorderSize(Vec4(0.001)),Vec3(0.45)))
		chatHistoryPanel:setLayout(FlowLayout(Alignment.BOTTOM_LEFT))
	end
	init()
	return self
end