require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/Campaign/mapPanel.lua")
require("Menu/Campaign/shop.lua")
--this = SceneNode()
Campaing = {}
function Campaing.new(camera, inForm)

	local self = {}
	--camera = Camera()
	local form = nil
	local mainForm = inForm
	local mapPanel = nil
	local mainMenuListener = Listener("MainMenu")
	
	function self.destroy()
		if form then
			form:setVisible(false)
			form:destroy()
		end
		if shop then
			shop.destroy()
		end
		if mapPanel then
			mapPanel.destroy()
		end
	end
	
	function showShop()
		shop.toggleVisible()
		mapPanel.setShopVisible(shop.getVisible())
	end
	
	function self.setVisible(visible)
		if form then	
			
			--change world visibility
			local playerNode = this:getRootNode():findNodeByType(NodeId.playerNode)				
			if playerNode then
				playerNode:setVisible(not visible)
			end
			--change main form visibility
			mainForm:setVisible(not visible)
			
			--stop or resume camera rotation
			if visible then
				mainMenuListener:pushEvent("EnterCampaign")
			else
				mainMenuListener:pushEvent("LeaveCampaign")
			end
			
			--set campaing form visibility
			form:setVisible(visible)
		end
	end
	
	function quitCampaing()
		self.setVisible(false)
	end
	
	function init()
		
			
		form = Form(ConvertToCamera(camera), PanelSize(Vec2(-1,-1)), Alignment.TOP_LEFT);
		form:setLayout(FlowLayout(PanelSize(Vec2(0.01,0))));
		form:setRenderLevel(8)	
		form:setVisible(false)	
		

		local topPanel = MainMenuStyle.createTopMenu(form, PanelSize(Vec2(-1,0.05)))
	
		local buttons = {}
		buttons[1] = {text = "Main menu", size = Vec2(5,1), callback = quitCampaing}
		buttons[2] = {text = "Shop", size = Vec2(2,1), callback = showShop}
		
		for i=1, #buttons do
			buttons[i].button = MainMenuStyle.addTopMenuButton(topPanel, buttons[i].size, buttons[i].text)
			buttons[i].button:addEventCallbackExecute(buttons[i].callback)
		end
		
		--Create main Area
		local mainAreaPanel = form:add(Panel(PanelSize(Vec2(-1))))
		mainAreaPanel:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
		
		mapPanel = MapPanel.new(mainAreaPanel, camera)
		shop = Shop.new(mainAreaPanel)
	
	end

	init()

	
	
	function self.getVisible()
		return form and form:getVisible() or false
	end
	
	function self.update()
		if form and form:getVisible() then
			if not shop.getVisible() then
				mapPanel.update()
			end
			shop.update()
			
			form:update()
		end
	end
		
	return self
end