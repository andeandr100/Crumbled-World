require("Menu/MainMenu/mainMenuStyle.lua")
require("Game/gameValues.lua")
--this = SceneNode()

local pixelWidth = 600
local toolTipPanelSpacing = 0.0025

FreeFormDesign = {}

FreeFormDesign.steps = 56
FreeFormDesign.stepSize = (math.pi*2.0) / FreeFormDesign.steps
FreeFormDesign.gameValues = GameValues.new()
FreeFormDesign.scale = 1.0
FreeFormDesign.colorScale = 1.0

function FreeFormDesign.getColorYfunc(value, colors)
--	return Vec3(value)
	local colorValue = value * (#colors-1)
	
	local startIndex = math.floor(colorValue)
	local colorScaleValue = colorValue - startIndex
	
	if startIndex < 0 then
		return colors[1]
	elseif startIndex >= (#colors-1) then
		return colors[#colors]
	end
	
	return math.interPolate(colors[startIndex+1],colors[startIndex+2],colorScaleValue)
end

function FreeFormDesign.addCircleYcolor(designModel, innerRadius, width, colors, alpha)	

	local finalColor = {}
	for n=1, #colors do
		finalColor[n] = Vec4(colors[n] * FreeFormDesign.colorScale, alpha)
	end

	innerRadius = (innerRadius / pixelWidth) * FreeFormDesign.scale
	width = (width / pixelWidth) * FreeFormDesign.scale
	
	local colFunc = FreeFormDesign.getColorYfunc
	local outerRadius = innerRadius + width
	for  r=0, FreeFormDesign.steps do
		local r1 = FreeFormDesign.stepSize * r
		local r2 = FreeFormDesign.stepSize * (r+1)
		
		local p1 = Vec2(math.sin(r1), math.cos(r1)) * innerRadius
		local p2 = Vec2(math.sin(r2), math.cos(r2)) * innerRadius
		
		local p3 = Vec2(math.sin(r1), math.cos(r1)) * outerRadius
		local p4 = Vec2(math.sin(r2), math.cos(r2)) * outerRadius
		
		local c1 = colFunc(0.5 + (p1.y/outerRadius) * 0.5, finalColor)
		local c2 = colFunc(0.5 + (p2.y/outerRadius) * 0.5, finalColor)
		local c3 = colFunc(0.5 + (p3.y/outerRadius) * 0.5, finalColor)
		local c4 = colFunc(0.5 + (p4.y/outerRadius) * 0.5, finalColor)
		designModel:addQuad(p1, p2, p3, p4, c1, c2, c3, c4)
	end	
	
end
	
function FreeFormDesign.addCircle(designModel, innerRadius, width, innerColor, outerColor)	

	innerRadius = (innerRadius / pixelWidth) * FreeFormDesign.scale
	width = (width / pixelWidth) * FreeFormDesign.scale
	innerColor = innerColor * FreeFormDesign.colorScale
	outerColor = outerColor * FreeFormDesign.colorScale
	
	
	local outerRadius = innerRadius + width
	for  r=0, FreeFormDesign.steps do
		local r1 = FreeFormDesign.stepSize * r
		local r2 = FreeFormDesign.stepSize * (r+1)
		
		local p1 = Vec2(math.sin(r1), math.cos(r1)) * innerRadius
		local p2 = Vec2(math.sin(r2), math.cos(r2)) * innerRadius
		
		local p3 = Vec2(math.sin(r1), math.cos(r1)) * outerRadius
		local p4 = Vec2(math.sin(r2), math.cos(r2)) * outerRadius
		
		designModel:addQuad(p1, p2, p3, p4, innerColor, innerColor, outerColor, outerColor)
	end	
	
end

function FreeFormDesign.addCircleInterior(designModel, innerRadius, outerColor, centerColor)	

	innerRadius = (innerRadius / pixelWidth) * FreeFormDesign.scale
	outerColor = outerColor * FreeFormDesign.colorScale

	for  r=0, FreeFormDesign.steps do
		local r1 = FreeFormDesign.stepSize * r
		local r2 = FreeFormDesign.stepSize * (r+1)
		
		local p1 = Vec2(math.sin(r1), math.cos(r1)) * innerRadius
		local p2 = Vec2(math.sin(r2), math.cos(r2)) * innerRadius
		
		designModel:addTriangle(p1, p2, Vec2(), outerColor, outerColor, centerColor)
	end	
	
end

function FreeFormDesign.addQuadEdge(designModel, innerDistance, width, innerColor, outerColor)	
	
	innerDistance = (innerDistance / pixelWidth)* FreeFormDesign.scale
	width = (width / pixelWidth) * FreeFormDesign.scale
	innerColor = innerColor * FreeFormDesign.colorScale
	outerColor = outerColor * FreeFormDesign.colorScale
	
	--P1 --- P2
	-- |	 |
	-- |	 |
	-- |	 |
	--P3 --- P4
	
	local p1 = Vec2(-innerDistance,-innerDistance)
	local p2 = Vec2( innerDistance,-innerDistance)
	local p3 = Vec2(-innerDistance, innerDistance)
	local p4 = Vec2( innerDistance, innerDistance)
	
	
	--Left border
	designModel:addQuad(p1+Vec2(-width,-width), p1, p3 + Vec2(-width, width), p3, outerColor, innerColor, outerColor, innerColor)
	
	--Top Border
	designModel:addQuad(p1+Vec2(-width,-width), p2 + Vec2(width, -width), p1, p2, outerColor, outerColor, innerColor, innerColor)
	
	--Right Border
	designModel:addQuad(p2, p2+Vec2( width,-width), p4, p4+Vec2( width, width), innerColor, outerColor, innerColor, outerColor)
	
	--Bottom border
	designModel:addQuad(p3, p4, p3+Vec2(-width,width), p4+Vec2( width, width), innerColor, innerColor, outerColor, outerColor)
end

function FreeFormDesign.addQuad(designModel, p1, p2, p3, p4, color)	
	color = color * FreeFormDesign.colorScale
	designModel:addQuad((p1/pixelWidth)*FreeFormDesign.scale, (p2/pixelWidth)*FreeFormDesign.scale, (p3/pixelWidth)*FreeFormDesign.scale, (p4/pixelWidth)*FreeFormDesign.scale, color, color, color, color)
end

function FreeFormDesign.getSkillButton()
	local buttonDesign = FreeFormButtonDesign(PanelSizeType.ParentPercentBasedOnY)
	FreeFormDesign.scale = 1.0
	FreeFormDesign.colorScale = 1.0
		
	local blackColor = Vec3(0.09,0.1,0.098)
	local darGrayColor = Vec3(0.027)
	local grayColor = Vec3(0.227)
	
	local redColor = Vec3(0.6,0.2,0.2)
	
	
	buttonDesign:setDisabledMesh()
	FreeFormDesign.colorScale = 0.4
	
	FreeFormDesign.addCircleInterior(buttonDesign, 57, blackColor, Vec3())	
	FreeFormDesign.addCircle( buttonDesign, 57, 3, blackColor, darGrayColor)
	FreeFormDesign.addCircle( buttonDesign, 60, 3, grayColor*0.7, grayColor*0.7)
	FreeFormDesign.addCircle( buttonDesign, 63, 2, grayColor*0.7, darGrayColor)
	FreeFormDesign.addCircle( buttonDesign, 65, 3, darGrayColor, blackColor)
	
	FreeFormDesign.addQuadEdge( buttonDesign, 50, 3, grayColor, darGrayColor)
	FreeFormDesign.addQuadEdge( buttonDesign, 46, 4, darGrayColor, darGrayColor)
	FreeFormDesign.addQuadEdge( buttonDesign, 43, 3, darGrayColor, grayColor)
	
	
	----------------------------------------------------------------------------------
		
	buttonDesign:setDefaultMesh()
	FreeFormDesign.colorScale = 1.1
	FreeFormDesign.addCircleInterior(buttonDesign, 57, blackColor, Vec3())
	
	FreeFormDesign.addCircle( buttonDesign, 57, 3, blackColor, darGrayColor)
	FreeFormDesign.addCircle( buttonDesign, 60, 3, grayColor, grayColor)
	FreeFormDesign.addCircle( buttonDesign, 63, 2, grayColor, darGrayColor)
	FreeFormDesign.addCircle( buttonDesign, 65, 3, darGrayColor, blackColor)
	
	FreeFormDesign.addQuadEdge( buttonDesign, 50, 3, grayColor, darGrayColor)
	FreeFormDesign.addQuadEdge( buttonDesign, 46, 4, darGrayColor, darGrayColor)
	FreeFormDesign.addQuadEdge( buttonDesign, 43, 3, darGrayColor, grayColor)
	
	FreeFormDesign.addQuad( buttonDesign, Vec2(-43, -43), Vec2(43, -43), Vec2(-43, 43), Vec2(43, 43), Vec3(0.15))
	
	
	----------------------------------------------------------------------------------
	
	buttonDesign:setSelectedMesh()
	FreeFormDesign.colorScale = 1.3
	FreeFormDesign.addCircleInterior(buttonDesign, 57, blackColor, Vec3())
	
	FreeFormDesign.addCircle( buttonDesign, 57, 3, blackColor, darGrayColor)
	FreeFormDesign.addCircle( buttonDesign, 60, 3, grayColor, grayColor)
	FreeFormDesign.addCircle( buttonDesign, 63, 2, grayColor, darGrayColor)
	FreeFormDesign.addCircle( buttonDesign, 65, 3, darGrayColor, blackColor)
	
	FreeFormDesign.addQuadEdge( buttonDesign, 50, 3, grayColor, darGrayColor)
	FreeFormDesign.addQuadEdge( buttonDesign, 46, 4, darGrayColor, darGrayColor)
	FreeFormDesign.addQuadEdge( buttonDesign, 43, 3, darGrayColor, grayColor)
	
	FreeFormDesign.addQuad( buttonDesign, Vec2(-43, -43), Vec2(43, -43), Vec2(-43, 43), Vec2(43, 43), Vec3(0.15))
	
	--Change Color
	blackColor = Vec3(0.1,0.027,0.027)
	
	--Add Read border
	FreeFormDesign.addQuadEdge( buttonDesign, 46, 2, blackColor, redColor)
	FreeFormDesign.addQuadEdge( buttonDesign, 48, 2, redColor, blackColor)
	
	----------------------------------------------------------------------------------
	
	buttonDesign:setMouseHoverMesh()
	FreeFormDesign.addCircle( buttonDesign, 65, 1, Vec4(0.09,0.1,0.098,1), Vec4(1,1,1,0.7))
	FreeFormDesign.addCircle( buttonDesign, 66, 6, Vec4(1,1,1,0.7), Vec4(1,1,1,0))
	
	FreeFormDesign.addQuadEdge( buttonDesign, 46, 2, blackColor*1.2, redColor*1.2)
	FreeFormDesign.addQuadEdge( buttonDesign, 48, 2, redColor*1.2, blackColor*1.2)
	
	
	----------------------------------------------------------------------------------
	
	
	
	buttonDesign:setButtonAreaSquare( Vec2(-48)/pixelWidth, Vec2(48)/pixelWidth)
	
	buttonDesign:setImageDefaultTexture(Core.getTexture("icon_table"))
	buttonDesign:setImageDefaultUvCoord(Vec2(), Vec2(0.125,0.0625))
	buttonDesign:setImageSize(Vec2(92)/pixelWidth)
	
	buttonDesign:enableImage()
	buttonDesign:enableSecondaryImage()
	
	return buttonDesign
end

local function rgb(red, green, blue)
	return Vec3(red/255.0,green/255.0,blue/255.0)
end

function FreeFormDesign.getMapButton(playedAndWon, unlocked)
	local buttonDesign = FreeFormButtonDesign(PanelSizeType.ParentPercentBasedOnY)
		
	
	local outerRingColor = {rgb(255,222,127),rgb(255,249,215),rgb(255,230,155),rgb(252,216,119),rgb(207,163,72),rgb(137,85,1),rgb(179,127,43),rgb(135,83,0)}
	local innerRingColor = {rgb(136,84,0),rgb(151,101,17),rgb(247,212,118),rgb(252,227,141),rgb(246,245,224)}
	local circleBackgroundColor = Vec3(0.07,0.07,0.07)
	local coverColor = Vec4(255/255,116/230,43/155,0.5)
	
	if playedAndWon == false then
		outerRingColor = {rgb(225,227,226),rgb(49,50,52)}
		innerRingColor = {rgb(63,67,68),rgb(220,221,223)}
	end
	
	
	if unlocked == false then
		circleBackgroundColor = circleBackgroundColor * 0.4
		coverColor = coverColor * 0.4
		for n=1, #outerRingColor do
			outerRingColor[n] = outerRingColor[n] * 0.4
		end
		for n=1, #innerRingColor do
			innerRingColor[n] = innerRingColor[n] * 0.4
		end
	end
	
	FreeFormDesign.scale = 0.8
	FreeFormDesign.colorScale = 1.0
	
	buttonDesign:setDefaultMesh()
	FreeFormDesign.addCircleInterior( buttonDesign, 75, circleBackgroundColor, circleBackgroundColor)
	FreeFormDesign.addCircleYcolor( buttonDesign, 75, 3, innerRingColor, 1.0)
	FreeFormDesign.addCircleYcolor( buttonDesign, 78, 7, outerRingColor, 1.0)
	FreeFormDesign.addCircleYcolor( buttonDesign, 77.7, 0.6, outerRingColor,0.5)--overlapping midle ring color 
	FreeFormDesign.addCircle( buttonDesign, 73, 2.1, Vec4(0,0,0,0), Vec4(innerRingColor[1],1.0))--inner edge to black
	FreeFormDesign.addCircle( buttonDesign, 84.9, 2.1, Vec4(outerRingColor[1],0.5), Vec4(0,0,0,0))--outer edge to black
	

	local scale = 1.3
	
	buttonDesign:setMouseHoverMesh()
	FreeFormDesign.addCircleYcolor( buttonDesign, 75, 3*scale, innerRingColor, 1.0)
	FreeFormDesign.addCircleYcolor( buttonDesign, 75+3*scale, 7*scale, outerRingColor, 1.0)
	FreeFormDesign.addCircleYcolor( buttonDesign, 74.7+3*scale, 0.6, outerRingColor,0.4)--overlapping midle ring color 
	FreeFormDesign.addCircle( buttonDesign, 73, 2.1, Vec4(0,0,0,0), Vec4(innerRingColor[1],0.7))--inner edge to black
	FreeFormDesign.addCircle( buttonDesign, 77.9+7*scale, 2.1, Vec4(outerRingColor[1],0.5), Vec4(0,0,0,0))--outer edge to black
	
	buttonDesign:setButtonAreaCircle( Vec2(), 85/pixelWidth)
	
	buttonDesign:setImageDefaultTexture(Core.getTexture("noImage"))
	buttonDesign:setImageDefaultUvCoord(Vec2(), Vec2(1))
	buttonDesign:setImageSize(Vec2(130)/pixelWidth)
	
	buttonDesign:enableImage()
	
	
	return buttonDesign
end

function FreeFormDesign.setLineDesign(lineHandler)
	
	local black = Vec3(0)
	local darkBlack = Vec3(0.1,0.027,0.027)
	local darkGray = Vec3(0.227)
 
	
	lineHandler:addLineDesign(7,5,black,darkGray)
	lineHandler:addLineDesign(5,3,darkGray,darkBlack)
	lineHandler:addLineDesign(-3,3,darkBlack,darkBlack)
	lineHandler:addLineDesign(-3,-5,darkBlack,darkGray)
	lineHandler:addLineDesign(-5,-6,darkGray,black)
end

function FreeFormDesign.setLineDesignSelected(lineHandler)
	
	local black = Vec3(0)
	local darkBlack = Vec3(0.1,0.027,0.027) * 4
	local darkGray = Vec3(0.227) * 1.5
 
	
	lineHandler:addLineDesign(7,5,black,darkGray)
	lineHandler:addLineDesign(5,3,darkGray,darkBlack)
	lineHandler:addLineDesign(-3,3,darkBlack,darkBlack)
	lineHandler:addLineDesign(-3,-5,darkBlack,darkGray)
	lineHandler:addLineDesign(-5,-6,darkGray,black)
end

function FreeFormDesign.setlineDesignSkillLevelSeperator(lineHandler)
	
	local black = Vec3(0)
	local darkBlack = Vec3(0.1,0.027,0.027) * 4
	local darkGray = Vec3(0.227)
 
	
	lineHandler:addLineDesign(-2,0,black,darkGray)
	lineHandler:addLineDesign(0,2,darkGray,black)
end


-----------------------------------------------------------------

function FreeFormDesign.convertValueToPrintedValue(value, name, func, addPercentage)
	
	local greenColor = "<font color=rgb(40,255,40)>+"
	if func == FreeFormDesign.gameValues.mul then
		if value < 1 then
			return tostring(math.round((1-value) * 100)) .. (addPercentage and "%" or ""), "<font color=rgb(255,50,50)>-"
		else
			return tostring(math.round((value-1) * 100)) .. (addPercentage and "%" or ""), greenColor
		end
		
	elseif name == "slow" then
		return tostring(math.round(value * 100)) .. (addPercentage and "%" or ""), greenColor
	else
		local roundedValue = value >= 10 and math.round(value) or (math.round(value * 10) / 10)
		return tostring(roundedValue), greenColor
	end
end

function FreeFormDesign.getValuesForToolTip(abilityData, level)
	local value1 = nil
	for n=1, #abilityData.infoValues do 
		local name = abilityData.infoValues[n]
		local data = abilityData.stats[name]

		if value1 == nil then
			value1 = FreeFormDesign.convertValueToPrintedValue(data[level], name, data.func)
		else
			return value1, FreeFormDesign.convertValueToPrintedValue(data[level], name, data.func)
		end
	end
	return (value1==nil and "" or value1), ""
end

-- Create tool tip base panel
local function createToolBasePanel()
	local panel = Panel(PanelSize(Vec2(-1)))
	panel:setLayout(FallLayout(PanelSize(Vec2(toolTipPanelSpacing),PanelSizeType.WindowPercentBasedOnY)))
	panel:getPanelSize():setFitChildren(true, true)
	panel:setCanHandleInput(false)
	return panel
end

local function addTooTipHeader(panel, headerText)
	local nameLabel = panel:add( Label(PanelSize(Vec2(-1)), headerText, Vec4(1) ))
	nameLabel:setTextHeight(0.017)
	nameLabel:setPanelSizeBasedOnTextSize()
	return nameLabel:getPanelSize():getSize()
end

local function addToolTipText(panel, totalPanelSizeInPixel, toolTipText)
	local textLabel = panel:add( Label(PanelSize(Vec2(-1)), toolTipText, Vec4(1) ) )
	textLabel:setTextHeight(0.015)
	textLabel:setPanelSizeBasedOnTextSize()
	local textSize = textLabel:getPanelSize():getSize()
	return Vec2( math.max( textSize.x, totalPanelSizeInPixel.x), totalPanelSizeInPixel.y + textSize.y + Core.getScreenResolution().y * toolTipPanelSpacing )
end

-- Add a line break to a panel
local function addLineBreaker(panel, totalPanelSizeInPixel)	
	local line = panel:add(Panel(PanelSize(Vec2(-1,0.001))))
	line:setBackground(Sprite(Vec3(0)))
	return totalPanelSizeInPixel + Vec2(0, Core.getScreenResolution().y * (toolTipPanelSpacing + 0.001 ) )
end

local function addAbility(panel, abilityData, index, level)


	local name = abilityData.infoValues[index]
	local data = abilityData.stats[name]

	local minCoord, maxCoord, text = FreeFormDesign.gameValues.getUvCoordAndTextFromName(name)
	local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga"))
	icon:setUvCoord(minCoord,maxCoord)
				
				
	local valueStr, fontStr = FreeFormDesign.convertValueToPrintedValue(data[level], name, data.func, true)
	notifyText = fontStr .. valueStr .. "</font>\n"
	
	
	panel:add(icon)
	panel:add(Label(PanelSize(Vec2(-1)), notifyText, Vec3(1.0)))
end

local function addCrystalCost(panel, totalPanelSizeInPixel, abilityData, level, upgradeNeeded)
	--crystal cost
	local row = panel:add(Panel(PanelSize(Vec2(-1,0.025))))
	row:setLayout(FlowLayout())
	
	
	local cost = abilityData.maxLevel == 1 and 3 or level
	local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table"))
	icon:setUvCoord(Vec2(0.5,0.375),Vec2(0.625,0.4375))
	
	row:add(icon)
	local label = nil
	if upgradeNeeded then
		label = row:add(Label(PanelSize(Vec2(-1)), tostring(cost).." Requiers \"Upgrade "..level.."\"", Vec3(1.0,0,0)))
	else
		label = row:add(Label(PanelSize(Vec2(-1)), tostring(cost), Vec3(1.0)))
	end

	
	return totalPanelSizeInPixel + Vec2(0, (0.025+toolTipPanelSpacing) * Core.getScreenResolution().y )
end

function FreeFormDesign.buildToolTipPanelForTower(towerName)

	local towerTextName = "tower.shop."..towerName
	local panel = createToolBasePanel()
	local totalPanelSizeInPixel = addTooTipHeader(panel, language:getText(towerTextName..".name"))
	
	totalPanelSizeInPixel = addLineBreaker(panel, totalPanelSizeInPixel)

	totalPanelSizeInPixel = addToolTipText(panel, totalPanelSizeInPixel, language:getText(towerTextName..".tooltip") )

	panel:setPanelSize(PanelSize(totalPanelSizeInPixel + Vec2(3), PanelSizeType.Pixel))
	return panel
end

function FreeFormDesign.buildToolTipPanelForAbility(abilityData, level, upgradeNeeded)
	
	local panel = createToolBasePanel()
	
	totalPanelSizeInPixel = addTooTipHeader(panel, abilityData.displayName..(abilityData.maxLevel == 1 and "" or (" "..level)) )
	
	totalPanelSizeInPixel = Vec2(math.max(totalPanelSizeInPixel.x, Core.getScreenResolution().y * 0.2), totalPanelSizeInPixel.y)
	
	totalPanelSizeInPixel = addLineBreaker(panel, totalPanelSizeInPixel)

	if abilityData.name ~= "upgrade" then
		local infoValueText = (abilityData.toolTip and abilityData.toolTip or "no tool tip")
		local value1, value2 = FreeFormDesign.getValuesForToolTip(abilityData, level)
		local toolTipText = language:getTextWithValues(infoValueText, value1, value2)
		
		totalPanelSizeInPixel = addToolTipText(panel, totalPanelSizeInPixel, toolTipText )
	else
		local toolTipText = language:getTextWithValues(abilityData.toolTip, tostring(level))
		totalPanelSizeInPixel = addToolTipText(panel, totalPanelSizeInPixel, toolTipText )
	end
	
	totalPanelSizeInPixel = addLineBreaker(panel, totalPanelSizeInPixel)
	
	
	for n=1, #abilityData.infoValues, 2 do 
		local row = panel:add( Panel(PanelSize(Vec2(-1,0.025),Vec2(5,1))) )
		row:setLayout(FlowLayout())
		
		local column1 = row:add(Panel(PanelSize(Vec2(-0.5,-1))))
		local column2 = row:add(Panel(PanelSize(Vec2(-1))))
		
		addAbility(column1, abilityData, n, level )
		
		if n+1 <= #abilityData.infoValues then
			addAbility(column2, abilityData, n+1, level )
		end
		
		totalPanelSizeInPixel = totalPanelSizeInPixel + Vec2(0, Core.getScreenResolution().y * (0.025 + toolTipPanelSpacing) )
	end
	
	totalPanelSizeInPixel = addCrystalCost(panel, totalPanelSizeInPixel, abilityData, level, upgradeNeeded)
	
	panel:setPanelSize(PanelSize(totalPanelSizeInPixel, PanelSizeType.Pixel))
	return panel
end