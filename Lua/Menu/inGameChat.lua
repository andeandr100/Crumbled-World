require("Menu/MainMenu/mainMenuStyle.lua")

function restore(data)
	--remove previous chat form
	if data.form then
		data.form:setVisible(false)
		data.form:destroy()
		data.form = nil
	end
end

--this = SceneNode()
function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

local function addMessage(name, text)
	
	local label = chatHistoryPanel:add(Label(PanelSize(Vec2(1,1/11),PanelSizeType.ParentPercent), Text(name ..": ") + text, Vec3(1)))
	label:setCanHandleInput(false)
	local removeLabel = chatHistoryPanel:getPanel(0)
	chatHistoryPanel:removePanel(removeLabel)
	
	for i=#textInfo, 1, -1 do
		if textInfo[i].label == removeLabel then
			table.remove(textInfo, i)
		end
	end
	
	textInfo[#textInfo+1] = {label=label,time=Core.getTime()}
end

function receiveMessage(inData)
	local msgTab = totable(inData)
	addMessage(msgTab.name, Text(msgTab.msg))
end

function callbackExecuteText(textField)
	if textField:getText():length() > 0 then
		print("")
		print("Chat text: \""..textField:getText():toString().."\"")
		print("")
		addMessage(client:getUserName(), textField:getText())
		local tab = {name=client:getUserName(), msg=textField:getText():toString()}
		comUnit:sendNetworkSyncSafe("SendChat",tabToStrMinimal(tab))
		textField:setText("")
	else
		chatTextField:clearKeyboardOwner()
		updateForm()
	end
end

function updateForm()
	local keyboardFocus = chatTextField:haskeyboardFocus()

	if keyboardFocus or mouseFocus > 0 then
		local alpha = keyboardFocus and 1.0 or 0.27
	
		if not visible then
			useAlphaMode = not keyboardFocus
			visible = true
			visibleTime = Core.getTime()
			
			chatTextField:setVisible(true)
			chatTextFieldReplacmentPanel:setVisible(false)
			chatTextField:setBackgroundColor(Vec4(0,0,0,0.25))
			chatHistoryPanel:setBackground(Gradient(Vec4(0,0,0,0.5) * alpha, Vec4(0,0,0,0.28) * alpha))
			chatHistoryPanel:getBorder():setBorderColor(Vec4(Vec3(0.45), alpha))
			if chatHistoryPanel:getYScrollBar() then
				chatHistoryPanel:getYScrollBar():setVisible( true )
				chatHistoryPanel:getYScrollBar():setColor(Vec4(1,1,1,alpha))
			end
			
			for i=1, #textInfo do
				textInfo[i].label:setTextColor(Vec4(1))
			end
		elseif ( useAlphaMode == true and keyboardFocus) or (useAlphaMode == false and mouseFocus > 0) then
			useAlphaMode = not keyboardFocus
			chatHistoryPanel:setBackground(Gradient(Vec4(0,0,0,0.5) * alpha, Vec4(0,0,0,0.28) * alpha))
			chatHistoryPanel:getBorder():setBorderColor(Vec4(Vec3(0.45), alpha))
			chatHistoryPanel:getYScrollBar():setColor(Vec4(1,1,1,alpha))
		end
	elseif visible and Core.getTime()-dimTimer > 0.1 then

		visible = false
		chatTextField:setVisible(false)
		chatTextFieldReplacmentPanel:setVisible(true)
		chatHistoryPanel:setBackground(Gradient(Vec4(0), Vec4(0)))
		chatHistoryPanel:getBorder():setBorderColor(Vec4(0))
		if chatHistoryPanel:getYScrollBar() then
			chatHistoryPanel:getYScrollBar():setVisible(false)
		end
	end
end

function updateFromColor()
	chatTextField:setBackgroundColor(Vec4(0,0,0,0.25))
end

function mouseFocusGain(panel)
	if not (buildingBillboard and buildingBillboard:getBool("inBuildMode")) then
		mouseFocus = mouseFocus + 1
		updateForm()
	end
end

function mouseFocusLost(panel)
	if not (buildingBillboard and buildingBillboard:getBool("inBuildMode")) then
		mouseFocus = math.max( 0, mouseFocus - 1 )
		updateForm()
	end
end

function create()
	
	client = Core.getNetworkClient()
	if not client:isConnected() then
		return false
	end
	camera = this:getRootNode():findNodeByName("MainCamera");
	--camera = Camera()
	
	mouseFocus = 0
	visible = true
	dimTimer = 0
	visibleTime = 0
	useAlphaMode = false
	
	textInfo = {}
	
	buildingBillboard = Core.getBillboard("buildings")
	
	if camera then
		
		Core.setScriptNetworkId("Chat")
		comUnit = Core.getComUnit()
		comUnit:setCanReceiveTargeted(true)
		
		comUnitTable = {}
		comUnitTable["SendChat"] = receiveMessage
		
		numMsg = 0
		
		
		
		form = Form( camera, PanelSize(Vec2(-1,0.29), Vec2(0.4/0.29,1)), Alignment.BOTTOM_LEFT);
		form:setName("InGameChat form")
		form:setLayout(FallLayout());
		form:setPadding(BorderSize(Vec4(MainMenuStyle.borderSize * 3)));
		form:setFormOffset(PanelSize(Vec2(0.005), Vec2(1)));
		form:setRenderLevel(2)
		form:setCanHandleInput(false)
		
--		chatPanel = form:add(Panel(PanelSize(Vec2(-1,-1))))
		form:setLayout(FallLayout(Alignment.BOTTOM_LEFT, PanelSize(Vec2(0,0.005))))
		
		
		Core.getGameSessionBillboard("dataSharer"):setPanel("InGameChat form",form)
		
		chatTextField = form:add(TextField(PanelSize(Vec2(-1,0.03))))
		chatTextField:setBackgroundColor(Vec4(0,0,0,0.25))
		chatTextField:setTextColor(Vec3(1.0))
--		chatTextField:addEventCallbackExecute(callbackExecuteText)
		chatTextField:addEventCallbackKeyboardFocusGain(updateForm)
		chatTextField:addEventCallbackKeyboardFocusLost(updateForm)
		chatTextField:setWhiteList("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ _-<>[]()!#+%&=1234567890?;:$@/,.*~^|:;")
		
		
		
		chatTextFieldReplacmentPanel = form:add(Panel(PanelSize(Vec2(-1,0.03))))
		chatTextFieldReplacmentPanel:setVisible(false)
		chatTextFieldReplacmentPanel:setCanHandleInput(false)

		chatHistoryPanel = form:add(Panel(PanelSize(Vec2(-1,-1))))
		chatHistoryPanel:setBackground(Gradient(Vec4(0,0,0,0.4), Vec4(0,0,0,0.25)))
		chatHistoryPanel:setEnableYScroll()
		chatHistoryPanel:setBorder(Border(BorderSize(Vec4(0.001)),Vec3(0.45)))
		chatHistoryPanel:setLayout(FlowLayout(Alignment.BOTTOM_LEFT))
		chatHistoryPanel:setCanHandleInput(false)
		
--		local panelList = {form, chatHistoryPanel}
		
--		form:addEventCallbackMouseFocusGain(mouseFocusGain)
--		form:addEventCallbackMouseFocusLost(mouseFocusLost)
		
--		chatTextField:addEventCallbackMouseFocusGain(mouseFocusGain)
--		chatTextField:addEventCallbackMouseFocusLost(mouseFocusLost)
--		for i=1, #panelList do 
--			panelList[i]:addEventCallbackMouseFocusGain(mouseFocusGain)
--			panelList[i]:addEventCallbackMouseFocusLost(mouseFocusLost)
--		end
		
		for i=1, 30 do
			local label = chatHistoryPanel:add(Label(PanelSize(Vec2(1,1/11),PanelSizeType.ParentPercent), "", Vec3(1)))
			label:setCanHandleInput(false)
		end
		
		updateForm()
		
		
		oldUpdate = update
		update = specialUpdate
		
	end
	
	setRestoreData({form=form})
	return true
end

function specialUpdate()
	form:update()
	local scroll = chatHistoryPanel:getYScrollBar()
	if scroll then
		scroll:setScrollOffset(scroll:getMaxScrollOffset())
		scroll:setVisible(visible)
		update = oldUpdate
	else
		print("Chatt update")
	end
	return true
end

function update()
	
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		print("msg: "..msg.message)
		if comUnitTable[msg.message]~=nil then
			comUnitTable[msg.message](msg.parameter)
		end
	end	
	
	local min = Vec2()
	local max = Vec2()
	local mousePos = Core.getInput():getMousePos()
	form:getPanelGlobalMinMaxPosition(min, max)
	if min.x < mousePos.x and max.x > mousePos.x and min.y < mousePos.y and max.y > mousePos.y then
		
		chatHistoryPanel:getYScrollBar():addScrollOffset(Vec2(0,Core.getInput():getMouseWheelTicks()))
		
		if mouseFocus == 0 then
			mouseFocusGain(nil)
		end
	elseif mouseFocus == 1 then
		mouseFocusLost(nil)
	end
	
	if not visible then
		if Core.getTime()-dimTimer > 0.1 then
			updateForm()
			for i=1, #textInfo do
				local time = Core.getTime() - textInfo[i].time
				if time > 60 then
					textInfo[i].label:setTextColor(Vec4(0))
				elseif time > 58 then
					textInfo[i].label:setTextColor(Vec4(Vec3(1), (60-time) / 2))
				else
					textInfo[i].label:setTextColor(Vec3(1))
				end
			end	
		end
	else
	
		if chatTextField:haskeyboardFocus() or mouseFocus > 0 then
			dimTimer = Core.getTime()
		else
			updateForm()
		end
	end
	
--	if Core.getInput():getKeyDown(Key.enter) and not chatTextField:haskeyboardFocus() and Core.getPanelWithKeyboardFocus() == nil then
--		visibleTime = Core.getTime()
--		chatTextField:setKeyboardOwner()
--	end
	
	if Core.getInput():getKeyDown(Key.enter) then
		if not chatTextField:haskeyboardFocus() and Core.getPanelWithKeyboardFocus() == nil then
			visibleTime = Core.getTime()
			chatTextField:setKeyboardOwner()
		elseif chatTextField:haskeyboardFocus() then
			callbackExecuteText(chatTextField)
		end
	end
	
	form:update()
	
	return true
end