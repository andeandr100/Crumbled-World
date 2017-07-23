require("Menu/settings.lua")
require("Menu/MainMenu/mainMenuStyle.lua")
require("Game/mapInfo.lua")
--this = SceneNode()
function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end

function hideForm()
	run = false
end

function next(panel)
	if tutorialIndex == #tutorialTexts then
		hideForm()
	end
	
	tutorialIndex = math.clamp(tutorialIndex+1,1, #tutorialTexts)
	print("next() tutorialIndex="..tutorialIndex.." max:"..#tutorialTexts)
	if tutorialIndex > 1 then
		previousButton:setVisible(true)
	end
	
	updateInfo()
end

function previous(panel)
	tutorialIndex = math.clamp(tutorialIndex-1,1, #tutorialTexts)
	if tutorialIndex == 1 then
		previousButton:setVisible(false)
	end
	updateInfo()
end

function updateInfo()
	label:setText(tutorialTexts[tutorialIndex])
	if fileName=="Data/Map/Campaign/Beginning.map" then
		images[tutorialIndex] = Core.getTexture("tutorial"..tutorialIndex..".png")
	elseif fileName=="Data/Map/Campaign/Intrusion.map" then
		images[tutorialIndex] = Core.getTexture("tutorial2_"..tutorialIndex..".png")
	elseif fileName=="Data/Map/Campaign/Expansion.map" then
		images[tutorialIndex] = Core.getTexture("tutorial3_"..tutorialIndex..".png")
	end
	image:setTexture(images[tutorialIndex])
	
	headerLable:setText("Tutorial "..tutorialIndex.."/"..#tutorialTexts)
	
	if tutorialIndex == #tutorialTexts then
		nextButton:setText("Start")
	else
		nextButton:setText("Next")
	end
end

function create()
	
	run = true
	
	mapInfo = MapInfo.new()
	fileName = mapInfo.getMapFileName()
	if not (fileName=="Data/Map/Campaign/Beginning.map" or fileName=="Data/Map/Campaign/Intrusion.map" or fileName=="Data/Map/Campaign/Expansion.map") then
		return false
	end
	if Settings.overideShowTutorial() == false then
		if fileName=="Data/Map/Campaign/Beginning.map" then
			if Settings.isTutorial1Done() then
				return false
			end
			Settings.setTutorial1Done()
		end
		if fileName=="Data/Map/Campaign/Intrusion.map" then
			if Settings.isTutorial2Done() then
				return false
			end
			Settings.setTutorial2Done()
		end
		if fileName=="Data/Map/Campaign/Expansion.map" then
			if Settings.isTutorial3Done() then
				return false
			end
			Settings.setTutorial3Done()
		end
	end
	
	--camera = Camera()
	local camera = this:getRootNode():findNodeByName("MainCamera")
	if not camera then
		return false
	end
	
	form = Form( camera, PanelSize(Vec2(1, 1)), Alignment.TOP_LEFT);
	
	form:getPanelSize():setFitChildren(false, false);
	form:setLayout(FlowLayout(Alignment.MIDDLE_CENTER, PanelSize(Vec2(0,0.001))));
	form:setRenderLevel(200)
	form:setVisible(true)
	form:setBackground(Sprite(Vec4(0,0,0,0.6)))
	form:addEventCallbackOnClick(hideForm)
	
	local formPanel = form:add(Panel(PanelSize(Vec2(1,0.45),Vec2(1.1,1))))
		
	formPanel:setPadding(BorderSize(Vec4(0.003), true))
	formPanel:setBackground(Gradient(Vec4(MainMenuStyle.backgroundTopColor:toVec3(), 0.9), Vec4(MainMenuStyle.backgroundDownColor:toVec3(), 0.75)))
	formPanel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize),true), MainMenuStyle.borderColor))
	formPanel:setLayout(FallLayout(Alignment.TOP_CENTER));	
	
	
	--Header

	local headerPanel = formPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
	headerPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
	MainMenuStyle.createBreakLine(formPanel)
	local quitButton = headerPanel:add( Button(PanelSize(Vec2(-1),Vec2(1)), "X", ButtonStyle.SQUARE ) )
	quitButton:addEventCallbackExecute(hideForm)
	
	quitButton:setTextColor(MainMenuStyle.textColor)
	quitButton:setTextHoverColor(MainMenuStyle.textColorHighLighted)
	quitButton:setTextDownColor(MainMenuStyle.textColorHighLighted)
	quitButton:setTextAnchor(Anchor.MIDDLE_CENTER)

	quitButton:setEdgeColor(Vec4(0), Vec4(0))
	quitButton:setEdgeHoverColor(Vec4(0), Vec4(0))
	quitButton:setEdgeDownColor(Vec4(0), Vec4(0))

	quitButton:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
	quitButton:setInnerHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
	quitButton:setInnerDownColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
	
	headerLable = headerPanel:add( Label( PanelSize(Vec2(-1)), "Tutorial 1/3", MainMenuStyle.textColor, Alignment.TOP_CENTER) )
	
	--Body
	local mainPanel = formPanel:add(Panel(PanelSize(Vec2(-1))))
	mainPanel:setLayout(FallLayout(Alignment.TOP_CENTER))
	
	
	tutorialIndex = 1
	images = {}
	tutorialTexts = {}
	if fileName=="Data/Map/Campaign/Beginning.map" then
		images[1] = Core.getTexture("tutorial1.png")
		for i=1, 6 do
			tutorialTexts[i] = language:getText("tutorial "..i)
		end
	elseif fileName=="Data/Map/Campaign/Intrusion.map" then
		images[1] = Core.getTexture("tutorial2_1.png")
		tutorialTexts[1] = language:getText("tutorial 7")
		tutorialTexts[2] = language:getText("tutorial 8")
		tutorialTexts[3] = language:getText("tutorial 9")
	elseif fileName=="Data/Map/Campaign/Expansion.map" then
		images[1] = Core.getTexture("tutorial3_1.png")
		tutorialTexts[1] = language:getText("tutorial 10")
		tutorialTexts[2] = language:getText("tutorial 11")
	end
	local textureSize = images[1]:getSize()
	
	
	
	--update header text
	headerLable:setText("Tutorial "..tutorialIndex.."/"..#tutorialTexts)
	
	--Spacing
	mainPanel:add(Panel(PanelSize(Vec2(-1,0.0075))))
	
	--create image panel
	image = mainPanel:add(Image(PanelSize(Vec2(-0.9,-1),Vec2(1,textureSize.y/textureSize.x)),images[1]))
	
	--Spacing
	mainPanel:add(Panel(PanelSize(Vec2(-1,0.0075))))
	
	--
	local infoAndButtonPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9,-1))))
	infoAndButtonPanel:setLayout(FallLayout(Alignment.BOTTOM_CENTER))
	
	--create next button
	local buttonPanel = infoAndButtonPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
	buttonPanel:setLayout(FlowLayout(Alignment.BOTTOM_RIGHT))
	nextButton = buttonPanel:add(MainMenuStyle.createButton(Vec2(-1),Vec2(4,1), "Next"))
	nextButton:addEventCallbackExecute(next)
	
	--create previous button
	previousButton = buttonPanel:add(MainMenuStyle.createButton(Vec2(-1),Vec2(4,1), "Previous"))
	previousButton:setVisible(false)
	previousButton:addEventCallbackExecute(previous)
	
	MainMenuStyle.createBreakLine(infoAndButtonPanel,-1)
	
	label = infoAndButtonPanel:add(Label(PanelSize(Vec2(-1)), tutorialTexts[tutorialIndex], MainMenuStyle.textColor))
	label:setTextAlignment(Alignment.TOP_LEFT)
	label:setTextHeight(0.015)
	
	
	return true
end

function update()
	
	form:update()
	
	return run
end