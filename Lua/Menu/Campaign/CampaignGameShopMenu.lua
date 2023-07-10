require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()

CampaignGameShopMenu = {}
function CampaignGameShopMenu.new(parentPanel)
	local self = {}
	local mainPanel = parentPanel:add(Panel(PanelSize(Vec2(-1))))
	--mainPanel = Panel()
	
	local buttons = {}
	
	function self.setVisible(visible)
		mainPanel:setVisible(visible)
	end
	
	local function setVisibleSkillTree( button )
		local skillIndex = tonumber(button:getTag():toString())
		
		for i=1, 10 do
			buttons[i].panel:setVisible(i==skillIndex)
		end
	end
	
	local function init()
	
		mainPanel:setBorder(Border( BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
	
		local leftPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.75, -1))))
		leftPanel:setLayout(FallLayout())
		
		mainPanel:add(Panel(PanelSize(Vec2(MainMenuStyle.borderSize,-1),PanelSizeType.WindowPercentBasedOnY))):setBackground(Sprite(MainMenuStyle.borderColor))
		
		local infoPanel = mainPanel:add(Panel(PanelSize(Vec2(-1, -1))))
		infoPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.005))))
		infoPanel:setPadding(BorderSize(Vec4(0.005),true))
		infoPanel:setBackground(Gradient(Vec4(0,0,0,0.9), Vec4(0,0,0,0.9)))
		
		
		--
		
		
		local towerBorderMenu = leftPanel:add(Panel(PanelSize(Vec2(-1, -1),Vec2(9.5,1))))
		towerBorderMenu:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
		towerButtonMenu = towerBorderMenu:add(Panel(PanelSize(Vec2(-1, -0.95),Vec2(10,1))))
		towerButtonMenu:setLayout(GridLayout(1,10, Alignment.MIDDLE_CENTER))


		local breakline = leftPanel:add(Panel(PanelSize(Vec2(-1,MainMenuStyle.borderSize))))
		breakline:setBackground(Sprite(MainMenuStyle.borderColor))
		
		local skillPanel = leftPanel:add(Panel(PanelSize(Vec2(-1, -1))))
		
		
		
		--
		
		local towerTexture = Core.getTexture("icon_tower_table")
		
		local passivUpgrades = towerButtonMenu:add(Button(PanelSize(Vec2(-1,-0.95), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, Vec2(), Vec2(1.0/4.0, 1.0/4.0) ))
		passivUpgrades:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
		passivUpgrades:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
		passivUpgrades:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
		passivUpgrades:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
		passivUpgrades:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
		passivUpgrades:setTag("1")
		
		buttons[1] = {}
		buttons[1].button = passivUpgrades
		
		for i=2, 10 do
			local x = (i-1)%4
			local y =3-math.floor(((i-1)/4))
			local minCoord = Vec2(x/4.0, y/4.0)
			

			local button = towerButtonMenu:add(Button(PanelSize(Vec2(-1,-0.95), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, minCoord, minCoord+Vec2(1.0/4.0, 1.0/4.0) ))
			button:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
			button:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
			button:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
			button:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
			button:setTag(""..i)
			
			buttons[i] = {}
			buttons[i].button = button
		end
		
		for i=1, 10 do
			buttons[i].button:addEventCallbackExecute(setVisibleSkillTree)
			buttons[i].panel = skillPanel:add(Panel(PanelSize(Vec2(-1, -1))))
			buttons[i].panel:setVisible(i==1)
			buttons[i].panel:setLayout(FreeFormLayout(PanelSize(Vec2(-1))))
			buttons[i].panel:setBackground(Sprite(Vec3(i*0.1)))
		end
	
		
		
		local lineHandler = FreeFormLine()	
		buttons[1].panel:add(lineHandler)
		
		lineHandler:addLineDesign(9,7,Vec3(0),Vec3(1))
		lineHandler:addLineDesign(7,5,Vec3(1),Vec3(0))
		lineHandler:addLineDesign(-5,5,Vec3(0),Vec3(0))
		lineHandler:addLineDesign(-5,-7,Vec3(0),Vec3(1))
		lineHandler:addLineDesign(-7,-8,Vec3(1),Vec3(0))
		
		lineHandler:addLine(Vec2(-0.1,-0.1), Vec2(-0.1, -0.3))
		lineHandler:addLine(Vec2(-0.2,-0.1), Vec2(-0.3, -0.3))
		lineHandler:addLine(Vec2(-0.3,-0.1), Vec2(-0.6, -0.1))
		
		local buttonDesign = FreeFormButtonDesign()
		
		buttonDesign:setBackgroundMesh()
		buttonDesign:addQuad(Vec2(-50, -50), Vec2(50, -50), Vec2(-50, 50), Vec2(50, 50), Vec3(1),Vec3(1),Vec3(1),Vec3(0))

		
		local steps = 22
		local stepSize = (math.pi*2.0) / steps;
		
		
		local radius = 57
		local outerRadius = 60
		for  r=0, steps do
			local r1 = stepSize * r
			local r2 = stepSize * (r+1)
			
			local p1 = Vec2(math.sin(r1), math.cos(r1)) * radius
			local p2 = Vec2(math.sin(r2), math.cos(r2)) * radius
			
			local p3 = Vec2(math.sin(r1), math.cos(r1)) * outerRadius
			local p4 = Vec2(math.sin(r2), math.cos(r2)) * outerRadius
			
			buttonDesign:addQuad(p1, p2, p3, p4, Vec3(0),Vec3(0),Vec3(0),Vec3(0))
		end	
		
		local radius = 60
		local outerRadius = 65
		for  r=0, steps do
			local r1 = stepSize * r
			local r2 = stepSize * (r+1)
			
			local p1 = Vec2(math.sin(r1), math.cos(r1)) * radius
			local p2 = Vec2(math.sin(r2), math.cos(r2)) * radius
			
			local p3 = Vec2(math.sin(r1), math.cos(r1)) * outerRadius
			local p4 = Vec2(math.sin(r2), math.cos(r2)) * outerRadius
			
			buttonDesign:addQuad(p1, p2, p3, p4, Vec3(1),Vec3(1),Vec3(1),Vec3(1))
		end		
		
		local radius = 65
		local outerRadius = 68
		for  r=0, steps do
			local r1 = stepSize * r
			local r2 = stepSize * (r+1)
			
			local p1 = Vec2(math.sin(r1), math.cos(r1)) * radius
			local p2 = Vec2(math.sin(r2), math.cos(r2)) * radius
			
			local p3 = Vec2(math.sin(r1), math.cos(r1)) * outerRadius
			local p4 = Vec2(math.sin(r2), math.cos(r2)) * outerRadius
			
			buttonDesign:addQuad(p1, p2, p3, p4, Vec3(0),Vec3(0),Vec3(0),Vec3(0))
		end	
		
		
		buttonDesign:setMouseHoverMesh()
		buttonDesign:addQuad(Vec2(-50, -50), Vec2(50, -50), Vec2(-50, 50), Vec2(50, 50), Vec3(1),Vec3(1),Vec3(1),Vec3(1))

			
		buttons[1].panel:add( FreeFormButton(Vec2(200,200), buttonDesign) )
		
	end
	init()
	
	return self
end