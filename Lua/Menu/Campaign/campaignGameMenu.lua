require("Menu/Campaign/shop.lua")

require("Menu/Campaign/CampaignGameMapMenu.lua")
require("Menu/Campaign/CampaignGameShopMenu.lua")
--this = SceneNode()

CampaignGameMenu = {}
function CampaignGameMenu.new(panel)
	local self = {}
	
	
	local selectedButton
	local selectedFile
	local mainPanel
	--
	
	local campaignMap
	local campaingShop
	
	function self.languageChanged()
		
	end
	
	function self.update()

	end
	
	local function returnFromShopToCampaign()
		mainPanel:setVisible(true)
	end
	
	local function buttonPressed(button)
		if button:getTag():toString() == "campaign" then
			campaignMap.setVisible(true)
			campaingShop.setVisible(false)
		elseif button:getTag():toString() == "shop" then
			campaignMap.setVisible(false)
			campaingShop.setVisible(true)
		end
	end
	
	local function init()
		
		--CampaignGameMenu.mapTable = {}
		selectedFile = ""
		
		--Options panel
		mainPanel = panel:add(Panel(PanelSize(Vec2(-1))))
		mainPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		--
		
		--Top menu button panel
		local topMenuButtons = mainPanel:add(Panel(PanelSize(Vec2(-1,0.04))))
		topMenuButtons:setLayout(FlowLayout(Alignment.MIDDLE_CENTER, PanelSize(Vec2(0,0.01))))

		local textScale = language:getText("button.campaign"):getTextScale() 
		
		local campaignButton = MainMenuStyle.addTopMenuButton(topMenuButtons, "button.campaign", Vec2(textScale.x/2+3,1))
		campaignButton:setTag("campaign")
		campaignButton:addEventCallbackExecute(buttonPressed)
		local buttonIcon = campaignButton:add(Image(PanelSize(Vec2(-1),Vec2(1)), "icon_table.tga"))
		buttonIcon:setUvCoord(Vec2(0.125,0),Vec2(0.25,0.0625))
		
		
		
		local shopButton = MainMenuStyle.addTopMenuButton(topMenuButtons, "button.shop", Vec2(textScale.x/2+3,1))
		buttonIcon = shopButton:add(Image(PanelSize(Vec2(-1),Vec2(1)), "icon_table.tga"))
		buttonIcon:setUvCoord(Vec2(),Vec2(0.125,0.0625))
		shopButton:setTag("shop")
		shopButton:addEventCallbackExecute(buttonPressed)
		
		
		--Add BreakLine
		local breakLinePanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		local gradient = Gradient()
		gradient:setGradientColorsHorizontal({Vec3(0.45),Vec3(0.66),Vec3(0.45)})
		breakLinePanel:setBackground(gradient)
		
		local sPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.93, -0.95))))
		campaignMap = CampaignGameMapMenu.new(sPanel)
		campaingShop = CampaignGameShopMenu.new(sPanel)		
		
		
		campaingShop.setVisible(false)
		campaignMap.setVisible(true)
		
		mainPanel:setVisible(false)
	end
	init()
	--
	--	Public functions
	--
	function self.isVisible()
	end
	
	function self.getVisible()
		return mainPanel:getVisible()
	end
	
	function self.getChildVisible()
		return false--windowShop.getVisible()
	end
	
	function self.changedVisibility()
		
	end
	
	function self.setVisible(set,set2)
		if type(set)=="boolean" then
			mainPanel:setVisible(set)
			campaignMap.setVisible(set)
			campaingShop.setVisible(false)
		else
			mainPanel:setVisible(set2)
			campaignMap.setVisible(set2)
			campaingShop.setVisible(false)
		end
	end
	--
	--
	--
	return self
end