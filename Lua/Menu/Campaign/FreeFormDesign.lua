require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()

local pixelWidth = 1500

FreeFormDesign = {}

FreeFormDesign.steps = 22
FreeFormDesign.stepSize = (math.pi*2.0) / FreeFormDesign.steps
	
function FreeFormDesign.addCircle(designModel, innerRadius, width, innerColor, outerColor)	

	innerRadius = innerRadius / pixelWidth
	width = width / pixelWidth
	
	
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

	innerRadius = innerRadius / pixelWidth

	for  r=0, FreeFormDesign.steps do
		local r1 = FreeFormDesign.stepSize * r
		local r2 = FreeFormDesign.stepSize * (r+1)
		
		local p1 = Vec2(math.sin(r1), math.cos(r1)) * innerRadius
		local p2 = Vec2(math.sin(r2), math.cos(r2)) * innerRadius
		
		designModel:addTriangle(p1, p2, Vec2(), outerColor, outerColor, centerColor)
	end	
	
end

function FreeFormDesign.addQuadEdge(designModel, innerDistance, width, innerColor, outerColor)	
	
	innerDistance = innerDistance / pixelWidth
	width = width / pixelWidth
	
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
	designModel:addQuad(p1/pixelWidth, p2/pixelWidth, p3/pixelWidth, p4/pixelWidth, color, color, color, color)
end

function FreeFormDesign.getSkillButton()
	local buttonDesign = FreeFormButtonDesign(PanelSizeType.WindowPercentBasedOnX)
		
	buttonDesign:setBackgroundMesh()
	FreeFormDesign.addCircleInterior(buttonDesign, 57, Vec3(0.09,0.1,0.098), Vec3())
	
	FreeFormDesign.addCircle( buttonDesign, 57, 3, Vec3(0.09,0.1,0.098), Vec3(0.027))
	FreeFormDesign.addCircle( buttonDesign, 60, 3, Vec3(0.227), Vec3(0.227))
	FreeFormDesign.addCircle( buttonDesign, 63, 2, Vec3(0.227), Vec3(0.027))
	FreeFormDesign.addCircle( buttonDesign, 65, 3, Vec3(0.027), Vec3(0.09,0.1,0.098))
	
	
	
	FreeFormDesign.addQuadEdge( buttonDesign, 50, 3, Vec3(0.227), Vec3(0.027))
	FreeFormDesign.addQuadEdge( buttonDesign, 46, 4, Vec3(0.027), Vec3(0.027))
	FreeFormDesign.addQuadEdge( buttonDesign, 43, 3, Vec3(0.027), Vec3(0.227))
	
	FreeFormDesign.addQuad( buttonDesign, Vec2(-43, -43), Vec2(43, -43), Vec2(-43, 43), Vec2(43, 43), Vec3(0.15))
	
	buttonDesign:setMouseHoverMesh()
	FreeFormDesign.addCircle( buttonDesign, 65, 1, Vec4(0.09,0.1,0.098,1), Vec4(1,1,1,0.7))
	FreeFormDesign.addCircle( buttonDesign, 66, 6, Vec4(1,1,1,0.7), Vec4(1,1,1,0))
	
	FreeFormDesign.addQuadEdge( buttonDesign, 46, 2, Vec3(0.1,0.027,0.027)*1.2, Vec3(0.6,0.2,0.2)*1.2)
	FreeFormDesign.addQuadEdge( buttonDesign, 48, 2, Vec3(0.6,0.2,0.2)*1.2, Vec3(0.1,0.027,0.027)*1.2)
	
	
	
	
	
	buttonDesign:setPressedMesh()
	--Add Read border
--	FreeFormDesign.addQuadEdge( buttonDesign, 46, 2, Vec3(0.1,0.027,0.027), Vec3(0.6,0.2,0.2))
--	FreeFormDesign.addQuadEdge( buttonDesign, 48, 2, Vec3(0.6,0.2,0.2), Vec3(0.1,0.027,0.027))
	
	
	buttonDesign:setButtonAreaSquare( Vec2(-48)/pixelWidth, Vec2(48)/pixelWidth)
	
	buttonDesign:setImageDefaultTexture(Core.getTexture("icon_table"))
	buttonDesign:setImageDefaultUvCoord(Vec2(), Vec2(0.125,0.0625))
	buttonDesign:setImageSize(Vec2(96)/pixelWidth)
	
	buttonDesign:enableImage()
	buttonDesign:enableSecondaryImage()
	
	return buttonDesign
end


function FreeFormDesign.getMapButton()
	local buttonDesign = FreeFormButtonDesign(PanelSizeType.WindowPercentBasedOnX)
		
	buttonDesign:setBackgroundMesh()
	FreeFormDesign.addCircle( buttonDesign, 57, 6, Vec3(1.0,0.8,0.1), Vec3(1.0,0.8,0.1))
	
	
	buttonDesign:setMouseHoverMesh()
	FreeFormDesign.addCircle( buttonDesign, 63, 6, Vec3(1.0,0.8,0.1), Vec3(1.0,0.8,0.1))
	
	buttonDesign:setPressedMesh()
	FreeFormDesign.addCircle( buttonDesign, 63, 6, Vec3(1.0,0.8,0.1), Vec3(1.0,0.8,0.1))
	
	buttonDesign:setButtonAreaCircle( Vec2(), 63/pixelWidth)
	
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