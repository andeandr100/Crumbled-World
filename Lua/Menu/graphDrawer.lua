GraphDrawer = {}
function GraphDrawer.new(pPanel, pLife, pScorePerLife, pScoreLimits)
	local self = {}
	local panel = pPanel
	local x = 0
	local y = 0
	local xPerWave = 0
	local yPerScore = 0
	local data
	local displaingInfoFromWaveIndex = 1
	local displayIndexChangeFunction
	--
	local scoreLimits = pScoreLimits
	--
	local leftMargin = 0
	local bottomMargin = 0
	--
	local textSizeY = math.floor(Core.getScreenResolution().y*0.012)
	local lineMainWidth = 2	--4 in total
	local lineSubWidth = 1	--2 in total
	--
	local topYValue = 0				--1.1 just to make sure that there is some nice spacing on top
	local topXValue = 0
	--
	local node2DMesh = Node2DMesh()
	local staticMesh = Node2DMesh()
	local displayInfo = Node2DMesh()
	--
	local panelMin = Vec2()
	local panelMax = Vec2()
	local input = Core.getInput()
	--
	--
	--
	
	local function getGridX(wave)
		return math.clamp(math.floor(leftMargin+((wave-1)*xPerWave)), leftMargin, x)
	end
	local function getWaveIndex(xPos)
		local x = xPos-leftMargin
		if x>=0 then
			return math.clamp((x/xPerWave)+1, 1, #data+0.9999)
		end
		return 1
	end
	local function getGridY(score)
		return math.clamp(math.floor(y-(bottomMargin+(score*yPerScore))), 0, y-bottomMargin)+textSizeY
	end
	local function getKill(wave)
		local waveIndex = math.floor(wave)
		local d1 = data
		local d2 = data[waveIndex]
		local per = math.clamp(wave-waveIndex,0.0,1.0)
		local max = #data[waveIndex]
		local kill = math.clamp( math.floor(max*per+0.5), 1, max)
		local item = data[waveIndex][kill] or data[waveIndex][0] or data[waveIndex-1][0]
		return {
			--GOLD
			goldAvailable = item[1],
			goldGainedTotal = item[2],
			goldGainedFromKills = item[3],
			goldGainedFromInterest = item[4],
			goldGainedFromWaves = item[5],
			goldGainedFromSupportTowers = item[6],
			goldInsertedToTowers = item[7],
			goldLostFromSelling = item[8],
			--SCORE
			score = item[9],
			totalTowerValue = item[10],
			life = item[11],
			--TOWERS
			towersBuilt = item[12],
			wallTowerBuilt = item[13],
			towersSold = item[14],
			towersUpgraded = item[15],
			towersSubUpgraded = item[16],
			towersBoosted = item[17],
			--ENEMIES
			spawnCount = item[18],
			killCount = item[19],
			totalDamageDone = item[20],
		}
	end
	--
	local function drawSingleLine(node2DMesh, posTable, width, color1, color2)
		if #posTable==2 then	
			local dir = (posTable[2]-posTable[1]):normalizeV()
			local perpandicularWidth = Vec2(-dir.y,dir.x)*width

			node2DMesh:addVertex(posTable[1]+(perpandicularWidth), color1)
			node2DMesh:addVertex(posTable[1]-(perpandicularWidth), color1)
			
			node2DMesh:addVertex(posTable[2]+(perpandicularWidth), color2 or color1)
			node2DMesh:addVertex(posTable[1]-(perpandicularWidth), color1)
			node2DMesh:addVertex(posTable[2]-(perpandicularWidth), color2 or color1)
			node2DMesh:addVertex(posTable[2]+(perpandicularWidth), color2 or color1)
		end
	end
	local function drawLine(node2DMesh, posTable, width, color, useDivider)
		if #posTable>1 then
			local dividerX = getGridX(displaingInfoFromWaveIndex)
			
			local dir = (posTable[2]-posTable[1]):normalizeV()
			local perpandicular1 = Vec2(-dir.y,dir.x)
			local perpandicular2 = Vec2()
			local i = 1
			
			while posTable[i+1] do
				if posTable[i+2] then
					local dTemp1 = (posTable[i+2]-posTable[i+1]):normalizeV()
					local dTemp2 = (posTable[i+1]-posTable[i]):normalizeV()
					local pTemp1 = Vec2(-dTemp1.y,dTemp1.x)
					local pTemp2 = Vec2(-dTemp2.y,dTemp2.x)
					perpandicular2 = (pTemp1+pTemp2):normalizeV()
				else
					local dTemp = (posTable[i+1]-posTable[i]):normalizeV()
					perpandicular2 = Vec2(-dTemp.y,dTemp.x)
				end
				--
				local activeColor = (posTable[i+1].x<dividerX or not useDivider) and color or Vec4(color.x,color.y,color.z,color.w*0.25)
				--color = Vec4(math.randomFloat(),math.randomFloat(),math.randomFloat(),1)
				node2DMesh:addVertex(posTable[i]+(perpandicular1*width), activeColor)
				node2DMesh:addVertex(posTable[i]-(perpandicular1*width), activeColor)
				node2DMesh:addVertex(posTable[i+1]+(perpandicular2*width), activeColor)
				node2DMesh:addVertex(posTable[i]-(perpandicular1*width), activeColor)
				node2DMesh:addVertex(posTable[i+1]-(perpandicular2*width), activeColor)
				node2DMesh:addVertex(posTable[i+1]+(perpandicular2*width), activeColor)
				--
				perpandicular1 = perpandicular2
				i = i + 1
			end
			
		end
	end
	local function addText(text, position, textSizeY, textColor)
		local textNode = TextNode()
		panel:addRenderObject(textNode)
		textNode:setColor(textColor or Vec3(1))
		textNode:setSize(Vec2(128,textSizeY+4))
		textNode:setTextHeight(textSizeY)
		textNode:setText(text)
		textNode:setVisible(true)
		textNode:setLocalPosition(position-Vec2(0,4))
	end
	--
	local function addGrid(node2DMesh)
		local YMainSplitSize = topYValue>=20000 and 10000 or 5000
		local YSubSplitSize = 1000
		local XMainSplitSize = topXValue>=30 and 10 or 5
		local XSubSplitSize = 1
		--
		--	add min lines
		--
		--Y line (left, goes all the way down)
		drawLine(node2DMesh, {Vec2(leftMargin,textSizeY),Vec2(leftMargin,(y+textSizeY)-bottomMargin+lineMainWidth)}, lineMainWidth, Vec4(0.45))
		--X line (bottom, starts to the right of the Y line)
		drawLine(node2DMesh, {Vec2(leftMargin+lineMainWidth,getGridY(0)), Vec2(x-lineMainWidth,getGridY(0))}, lineMainWidth, Vec4(0.45))
		
		--
		--	add left score
		--
		for score=0, topYValue, YSubSplitSize do
			local yPos = getGridY(score)
			local xx = leftMargin-lineMainWidth
			if score%YMainSplitSize==0 then
				--main lines
				drawSingleLine(node2DMesh, {Vec2(xx,yPos), Vec2(xx-(textSizeY),yPos)}, lineSubWidth, Vec4(0.45), Vec4(0.55))
				drawSingleLine(node2DMesh, {Vec2(leftMargin+lineMainWidth,yPos), Vec2(x,yPos)}, 0.5, Vec4(1,1,1,0.1), Vec4(1,1,1,0.1))
				--text
				addText(tostring(score/1000).."K", Vec2(leftMargin+4,yPos-(textSizeY+4)), textSizeY)
			else
				--sub lines
				drawSingleLine(node2DMesh, {Vec2(xx,yPos), Vec2(xx-(textSizeY*0.66),yPos)}, lineSubWidth, Vec4(0.45), Vec4(0.55))
				drawSingleLine(node2DMesh, {Vec2(leftMargin+lineMainWidth,yPos), Vec2(x,yPos)}, 0.5, Vec4(1,1,1,0.02), Vec4(1,1,1,0.03))
				--text
				if topYValue==score then
					addText(tostring(score/1000).."K", Vec2(leftMargin+4,yPos-(textSizeY+4)), textSizeY)
				end
			end
		end
		--
		--	add bottom wave lines
		--
		for wave=1, topXValue, XSubSplitSize do
			local xPos = getGridX(wave)
			local yy = (y+textSizeY)-bottomMargin+lineMainWidth
			if wave%XMainSplitSize==0 or wave==1 then
				--main lines
				drawSingleLine(node2DMesh, {Vec2(xPos,yy), Vec2(xPos,yy+(textSizeY))	}, lineSubWidth, Vec4(0.45), Vec4(0.55))
				drawSingleLine(node2DMesh, {Vec2(xPos,textSizeY), Vec2(xPos,(y+textSizeY)-bottomMargin-lineMainWidth)}, lineSubWidth, Vec4(1,1,1,0.06), Vec4(1,1,1,0.05))
			else
				--sub lines
				drawSingleLine(node2DMesh, {Vec2(xPos,yy), Vec2(xPos,yy+(textSizeY*0.66))}, lineSubWidth, Vec4(0.45), Vec4(0.55))	
				drawSingleLine(node2DMesh, {Vec2(xPos,textSizeY), Vec2(xPos,(y+textSizeY)-bottomMargin-lineMainWidth)}, lineSubWidth, Vec4(1,1,1,0.03), Vec4(1,1,1,0.02))
			end
		end
		
		--
		--	add text
		--
		
		--
		--	add medals
		--
		for k,v in pairs(scoreLimits) do
			if v.score>1 then
				local yPos = getGridY(v.score)
				local xx = leftMargin-lineMainWidth
				drawSingleLine(node2DMesh, {Vec2(leftMargin+lineMainWidth,yPos), Vec2(x-lineMainWidth,yPos)}, 0.5, Vec4(v.color,0.25), Vec4(v.color,0.75))
				--text
				local textScore = ""
				if v.score%1000==0 then
					textScore = tostring(v.score/1000).."K"
				else
					textScore = string.format("%.1fK",v.score/1000.0)
				end
				local textX = xx+((x-xx)*0.1)
				addText(textScore, Vec2(textX,yPos-(textSizeY+4)), textSizeY, v.color)
				--icon
				local icon = Sprite(Core.getTexture("icon_table.tga"))
				local iconPos = Vec2(textSizeY*4, textSizeY*2)
				panel:addRenderObject(icon)
				icon:setRenderLevel(2)
				icon:setUvCoord(v.minPos,v.maxPos)
				icon:setSize(iconPos)
				icon:setPosition(Vec2(x, yPos)-iconPos)
			end
		end
		
	end
	--
	function drawScoreGraph(func)
		local line = {}
		local steps = #data/(x-leftMargin)
		local max = #data+0.9999
		local wave = 1
		while true do
			local xx = getGridX(wave)
			wave = wave+steps
			if wave>=max then
				line[#line+1] = Vec2(xx,func(max))
				return line
			else
				line[#line+1] = Vec2(xx,func(wave))
			end
		end
		return line
	end
	
	function self.setCallbackOnDisplayIndexChange(func)
		displayIndexChangeFunction = func
	end
	function self.setDisplayedIndex(index)
		displaingInfoFromWaveIndex = index
		if self.isDispalyed() then
			local xx = getGridX(displaingInfoFromWaveIndex)
			
			if displayIndexChangeFunction then
				displayIndexChangeFunction(index)
			end
			
			node2DMesh:clearMesh()
			drawLine(node2DMesh, drawScoreGraph(function(index)	return getGridY(getKill(index)["score"]) end), 1, Vec4(0.9), true)
			node2DMesh:compile()
			
			displayInfo:clearMesh()
			drawSingleLine(displayInfo, {Vec2(xx,textSizeY), Vec2(xx,(y+textSizeY)-bottomMargin+lineMainWidth)}, 0.5, Vec4(0.85), Vec4(0.85))
			displayInfo:compile()
		end
	end
	function self.isMouseInsidePanel()
		local mPos = input:getMousePos()
		return mPos.x>=panelMin.x and mPos.x<=panelMax.x and mPos.y>=panelMin.y and mPos.y<=panelMax.y
	end
	function self.mouseClicked()
		local mousePos = Core.getInput():getMousePos()-panelMin
		
		self.setDisplayedIndex(getWaveIndex(mousePos.x))
	end
	function self.isDispalyed()
		return not (x==0 or y==0)
	end
	function self.resize()
		local bilboardStats = Core.getBillboard("stats")
		data = bilboardStats:getTable("scoreHistory")
		local d1 = data
		--make sure it is a real rezise
		if data and x~=panel:getPanelContentPixelSize().x or y~=panel:getPanelContentPixelSize().y-textSizeY then
			--
			textSizeY = math.floor(Core.getScreenResolution().y*0.012)
			x = panel:getPanelContentPixelSize().x
			y = panel:getPanelContentPixelSize().y - textSizeY
			--
			local iconPercentageRequirement = 1.01 + ((textSizeY*4)/y)
			--
			panel:getPanelGlobalMinMaxPosition(panelMin,panelMax)
			local maxScore = math.max(getKill(#data+0.9999).score, scoreLimits[#scoreLimits].score)*iconPercentageRequirement
			topYValue = math.floor( (maxScore )/5000 + 1)*5000
			topXValue = #data
			--get new size
			lineMainWidth = 2
			lineSubWidth = 1
			leftMargin = math.floor(textSizeY*2.0)
			bottomMargin = math.floor(textSizeY*2.0)
			xPerWave = (x-leftMargin-lineMainWidth)/topXValue
			yPerScore = (y-bottomMargin-lineMainWidth)/topYValue
			
			--clear all old data
			panel:clear()
			
			--render new stuff
			panel:addRenderObject( node2DMesh )
			panel:addRenderObject( displayInfo )
			panel:addRenderObject( staticMesh )
			
			drawLine(staticMesh, drawScoreGraph(function(index)	return getGridY(getKill(index)["score"]-(20*pScorePerLife)) end), 1, Vec4(0.85,0.85,0.85,0.1))--getKill(index)["life"]
			drawLine(staticMesh, drawScoreGraph(function(index)	return getGridY(getKill(index)["goldGainedFromInterest"]) end), 1, Vec4(0.85,0.85,0.85,0.1))
			addGrid(staticMesh)
			
			staticMesh:compile()
			
			self.setDisplayedIndex(1)
		end
	end
	
	local function init()
		panel:addEventCallbackResized(self.resize)
	end
	init()
	
	
	return self
end