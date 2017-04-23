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
	
	local label = chatHistoryPanel:add(Label(PanelSize(Vec2(1,1/15),PanelSizeType.ParentPercent), Text(name ..": ") + text, Vec3(1)))
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
	if textField:getText() ~= "" then
		addMessage(client:getUserName(), textField:getText())
		local tab = {name=client:getUserName(), msg=textField:getText():toString()}
		comUnit:sendNetworkSyncSafe("SendChat",tabToStrMinimal(tab))
		textField:setText("")
	elseif Core.getTime() - visibleTime > 0.1 then
		chatTextField:clearKeyboardOwner()
	end
end

function updateForm()
	local keyboardFocus = chatTextField:haskeyboardFocus()
--	print("\nupdateForm()")
--	print("isInFocus: "..tostring(keyboardFocus))
--	print("mouseFocus: "..mouseFocus)
--	print("visible: "..tostring(visible))
	if keyboardFocus or mouseFocus > 0 then
		if not visible then
			visible = true
			visibleTime = Core.getTime()
			print("Show Chat")
			chatTextField:setVisible(true)
			chatTextFieldReplacmentPanel:setVisible(false)
			chatTextField:setBackgroundColor(Vec4(0,0,0,0.25))
			chatHistoryPanel:setBackground(Gradient(Vec4(0,0,0,0.4), Vec4(0,0,0,0.25)))
			chatHistoryPanel:getBorder():setBorderColor(Vec3(0.45))
			chatHistoryPanel:setCanHandleInput(true)
			if chatHistoryPanel:getYScrollBar() then
				chatHistoryPanel:getYScrollBar():setVisible(true)
			end
			
			for i=1, #textInfo do
				textInfo[i].label:setTextColor(Vec4(1))
			end
		end
	elseif visible and Core.getTime()-dimTimer > 0.1 then
		visible = false
		print("hide Chat")
		chatTextField:setVisible(false)
		chatTextFieldReplacmentPanel:setVisible(true)
		chatHistoryPanel:setBackground(Gradient(Vec4(0), Vec4(0)))
		chatHistoryPanel:getBorder():setBorderColor(Vec4(0))
		chatHistoryPanel:setCanHandleInput(false)
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
	
	textInfo = {}
	
	buildingBillboard = Core.getBillboard("buildings")
	
	if camera then
		
		Core.setScriptNetworkId("Chat")
		comUnit = Core.getComUnit()
		comUnit:setCanReceiveTargeted(true)
		
		comUnitTable = {}
		comUnitTable["SendChat"] = receiveMessage
		
		numMsg = 0
		
		form = Form( camera, PanelSize(Vec2(-1,0.35), Vec2(0.4/0.35,1)), Alignment.BOTTOM_LEFT);
		form:setName("InGameChat form")
		form:setLayout(FallLayout());
		form:setPadding(BorderSize(Vec4(MainMenuStyle.borderSize * 3)));
		form:setFormOffset(PanelSize(Vec2(0.005), Vec2(1)));
		form:setRenderLevel(2)
		
		chatPanel = form:add(Panel(PanelSize(Vec2(-1,-1))))
		chatPanel:setLayout(FallLayout(Alignment.BOTTOM_LEFT, PanelSize(Vec2(0,0.005))))
		
		chatTextField = chatPanel:add(TextField(PanelSize(Vec2(-1,0.03))))
		chatTextField:setBackgroundColor(Vec4(0,0,0,0.25))
		chatTextField:setTextColor(Vec3(1.0))
		chatTextField:addEventCallbackExecute(callbackExecuteText)
		chatTextField:addEventCallbackKeyboardFocusGain(updateForm)
		chatTextField:addEventCallbackKeyboardFocusLost(updateForm)
		chatTextField:setWhiteList("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ _-<>[]()!#+%&=1234567890?;:$@/,.*~^|:;")
		
		chatTextFieldReplacmentPanel = chatPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
		chatTextFieldReplacmentPanel:setVisible(false)
		chatTextFieldReplacmentPanel:setCanHandleInput(false)

		chatHistoryPanel = chatPanel:add(Panel(PanelSize(Vec2(-1,-1))))
		chatHistoryPanel:setBackground(Gradient(Vec4(0,0,0,0.4), Vec4(0,0,0,0.25)))
		chatHistoryPanel:setEnableYScroll()
		chatHistoryPanel:setBorder(Border(BorderSize(Vec4(0.001)),Vec3(0.45)))
		chatHistoryPanel:setLayout(FlowLayout(Alignment.BOTTOM_LEFT))

		
		local panelList = {form, chatPanel, chatHistoryPanel, chatTextField}
		
		for i=1, #panelList do 
			panelList[i]:addEventCallbackMouseFocusGain(mouseFocusGain)
			panelList[i]:addEventCallbackMouseFocusLost(mouseFocusLost)
		end
		
		for i=1, 30 do
			chatHistoryPanel:add(Label(PanelSize(Vec2(1,1/15),PanelSizeType.ParentPercent), "", Vec3(1))):setCanHandleInput(false)
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
		
		if (not Core.getPanelWithMouseFocus() or Core.getPanelWithMouseFocus():getForm() ~= form) and mouseFocus > 0 then
			--Somthinge is not right here 
			--this Chat script belive the mouse is inside the form but it's wrong
			--fix the problem 
			mouseFocus = 0
			updateForm()
		end
		
		if (buildingBillboard and buildingBillboard:getBool("inBuildMode")) then
			--update chat window mouse pointer will not show the chat window
			mouseFocus = 0
			updateForm()
		end
		
		if chatTextField:haskeyboardFocus() or mouseFocus > 0 then
			dimTimer = Core.getTime()
		else
			updateForm()
		end
	end
	
	if Core.getInput():getKeyDown(Key.enter) and not chatTextField:haskeyboardFocus() and Core.getPanelWithKeyboardFocus() == nil then
		visibleTime = Core.getTime()
		chatTextField:setKeyboardOwner()
	end
	
	form:update()
	
	return true
end