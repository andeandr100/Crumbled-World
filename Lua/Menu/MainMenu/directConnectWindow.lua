require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/towerImage.lua")
--this = SceneNode()
DirectConnectWindow = {}
function DirectConnectWindow.new(camera)
	local self = {}
	local form = nil
	local mainPanel = nil
	local textField
	local client = Core.getNetworkClient()
	local menuChangeCallback
	local waitForConnection
	
	function self.setMenuChangeCallback(func)
		menuChangeCallback = func 
	end
	
	function self.destroy()
		if form then
			form:setVisible(false)
			form:destroy()
			form = nil
		end
	end
	
	function self.toggleVisible()
		form:setVisible( not form:getVisible() )
	end
	
	function self.setVisible(visible)
		form:setVisible(visible)
		if visible then
			textField:setKeyboardOwner()
		end
	end
	
	function self.getVisible()
		return form:getVisible()
	end
	
	function addTitle()
		
		local titlePanel = mainPanel:add(Panel(PanelSize(Vec2(1,0.4),PanelSizeType.ParentPercent)))
		
		titlePanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0))))
		--Top menu button panel
		mapNameLabel = titlePanel:add(Label(PanelSize(Vec2(-1,0.035)), language:getText("direct connect"), Vec3(0.94), Alignment.MIDDLE_CENTER))
		
		--Add BreakLine
		local breakLinePanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		breakLinePanel:setBackground(Sprite(Vec3(0.45)))
	end
	
	function addItem(text)
		local button = gameDifficultyComboBox:addItem(MainMenuStyle.createMenuButton(Vec2(-1,0.03), Vec2(), text))
		button:setTag(text)
		button:addEventCallbackExecute(changeItem)
	end
	
	function changeItem(button)
		gameDifficultyComboBox:setText(button:getTag())
	end
	--
	--	Callback
	--
	local function joinClicked()
		local text = textField:getText():toString()
		client:disconnect()
		client:connect(text)--"localhost"
		waitForConnection = {time = Core.getTime()}
	end
	local function closeClicked()
		self.setVisible(false)
	end
	--
	--
	--
	function init()
		
		local panelSpacing = 0.005
		local panelSpacingVec2 = Vec2(panelSpacing, panelSpacing)
		
		form = Form(ConvertToCamera(camera), PanelSize(Vec2(0.8,0.09), Vec2(6.5,1)), Alignment.TOP_CENTER);
		form:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(panelSpacingVec2)));
		form:setRenderLevel(9)	
		form:setVisible(false)
		
		form:setFormOffset(PanelSize(Vec2(0.3)))
		
		mainPanel = form:add(Panel(PanelSize(Vec2(-1))))
		--mainPanel:setLayout(FlowLayout(PanelSize(Vec2(0.01,0))))
		mainPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
		mainPanel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)),MainMenuStyle.borderColor))
		mainPanel:setLayout(FallLayout())
		
		addTitle()
		
		bottomPanel = mainPanel:add(Panel(PanelSize(Vec2(-1))))--spacing
		bottomPanel:setPadding(BorderSize(Vec4(0.004,0.008,0.004,0.008),true))
		
		--local panel = mainPanel:add(Panel(PanelSize(Vec2(-1))))
		
		bottomPanel:setLayout(FlowLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		textField = bottomPanel:add(TextField(PanelSize(Vec2(-0.8,-1), Vec2(9,1))))
		textField:addEventCallbackExecute(joinClicked)
		bottomPanel:add(Panel(PanelSize(Vec2(-0.1,-0.05))))--spacing
		local button = bottomPanel:add(Button(PanelSize(Vec2(-0.5,-1), Vec2(3,1)), language:getText("join server")))
		button:addEventCallbackExecute(joinClicked)
		button = bottomPanel:add(Button(PanelSize(Vec2(-1,-1), Vec2(3,1)), language:getText("quit")))
		button:addEventCallbackExecute(closeClicked)
		
	end
	init()

	--Update the map panel
	function self.update()
		form:update()
		if waitForConnection  then
			--print("until ("..tostring(client:isConnected()).." or "..(Core.getTime()-waitForConnection.time)..">1.0 )\n")
			if client:isConnected() then
				--client:read()
				self.setVisible(false)
				if menuChangeCallback then
					menuChangeCallback("Lobby")
				else
					error("No lobby window to open!!")
				end
			elseif Core.getTime()-waitForConnection.time>10.0 then
				print("failed to connect to server\n")
				self.setVisible(false)
			end
		else
		end
	end
		
	return self
end