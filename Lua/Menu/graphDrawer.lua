GraphDrawer = {}
function GraphDrawer.new(pPanel, pData, pLife, pScorePerLife)
	local self = {}
	local panel = pPanel
	local x = 0
	local y = 0
	local xPerWave = 0
	local yPerScore = 0
	local data = pData	--structure = data[wave][killNumber].*
	local maxScore = data[#data][#data[#data]]["score"]
	--
	local YMainSplitSize = 5000
	local YSubSplitSize = 1000
	local topYValue = math.floor( (maxScore*1.1)/YMainSplitSize +0.5)*YMainSplitSize	--1.1 just to make sure that there is some nice spacing on top
	local XMainSplitSize = 5
	local XSubSplitSize = 1
	local topXValue = #data+1
	--
	local leftMargin = 0
	local bottomMargin = 0
	--
	local textSizeY = math.floor(Core.getScreenResolution().y*0.012)
	local lineMainWidth = 2	--4 in total
	local lineSubWidth = 1	--2 in total
	
	--
	--
	--
	
	local function getGridX(wave)
		return math.clamp(math.floor(leftMargin+((wave-1)*xPerWave)), leftMargin, x)
	end
	local function getGridY(score)
		return math.clamp(math.floor(y-(bottomMargin+(score*yPerScore))), 0, y-bottomMargin)
	end
	local function getKill(wave)
		local waveIndex = math.floor(wave)
		local per = math.clamp(wave-waveIndex,0.0,1.0)
		local max = #data[waveIndex]
		local kill = math.clamp( math.floor(max*per+0.5), 1, max)
		return data[waveIndex][kill]
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
	local function drawLine(node2DMesh, posTable, width, color)
		if #posTable>1 then	
			local dir = (posTable[2]-posTable[1]):normalizeV()
			local perpandicular1 = Vec2(-dir.y,dir.x)
			local perpandicular2 = Vec2()
			local i = 1
			
			while posTable[i+1] do
				if posTable[i+2] then
					local dTemp1 = (posTable[i+2]-posTable[i+1]):normalizeV()
					local dTemp2 = (posTable[i+1]-posTable[i]):normalizeV()
					local pTemp1 = Vec2(-dTemp1.y,dTemp1.x)
					local pTemp2 = Vec2(-dTemp2
					.y,dTemp2.x)
					perpandicular2 = (pTemp1+pTemp2):normalizeV()
				else
					local dTemp = (posTable[i+1]-posTable[i]):normalizeV()
					perpandicular2 = Vec2(-dTemp.y,dTemp.x)
				end
				--
				--color = Vec4(math.randomFloat(),math.randomFloat(),math.randomFloat(),1)
				node2DMesh:addVertex(posTable[i]+(perpandicular1*width), color)
				node2DMesh:addVertex(posTable[i]-(perpandicular1*width), color)
				node2DMesh:addVertex(posTable[i+1]+(perpandicular2*width), color)
				node2DMesh:addVertex(posTable[i]-(perpandicular1*width), color)
				node2DMesh:addVertex(posTable[i+1]-(perpandicular2*width), color)
				node2DMesh:addVertex(posTable[i+1]+(perpandicular2*width), color)
				--
				perpandicular1 = perpandicular2
				i = i + 1
			end
			
		end
	end
	local function addText(text, position, textSizeY)
		local textNode = TextNode()
		panel:addRenderObject(textNode)
		textNode:setColor(Vec3(1))
		textNode:setSize(Vec2(128,textSizeY+4))
		textNode:setTextHeight(textSizeY)
		textNode:setText(text)
		textNode:setVisible(true)
		textNode:setLocalPosition(position-Vec2(0,4))
	end
	--
	local function addGrid(node2DMesh)
		--
		--	add min lines
		--
		--Y line (left, goes all the way down)
		drawLine(node2DMesh, {Vec2(leftMargin,0),Vec2(leftMargin,y-bottomMargin+lineMainWidth)}, lineMainWidth, Vec4(0.45))
		--X line (bottom, starts to the right of the Y line)
		drawLine(node2DMesh, {Vec2(leftMargin+lineMainWidth,y-(bottomMargin)), Vec2(x,y-(bottomMargin))}, lineMainWidth, Vec4(0.45))
		
		--
		--	add left score
		--
		for score=0, topYValue, YSubSplitSize do
			local yPos = getGridY(score)
			local xx = leftMargin-lineMainWidth
			if score%YMainSplitSize==0 then
				--main lines
				drawSingleLine(node2DMesh, {Vec2(xx,yPos), Vec2(xx-math.floor(leftMargin*0.5),yPos)}, lineMainWidth, Vec4(0.45), Vec4(0.55))
			else
				--sub lines
				drawSingleLine(node2DMesh, {Vec2(xx,yPos), Vec2(xx-math.floor(leftMargin*0.4),yPos)}, lineSubWidth, Vec4(0.45), Vec4(0.55))
			end
		end
		--
		--	add bottom wave lines
		--
		for wave=1, topXValue, XSubSplitSize do
			local xPos = getGridX(wave)
			local yy = y-bottomMargin+lineMainWidth
			if wave%XMainSplitSize==0 or wave==1 then
				--main lines
				drawSingleLine(node2DMesh, {Vec2(xPos,yy), Vec2(xPos,yy+(textSizeY*0.5))	}, lineMainWidth, Vec4(0.45), Vec4(0.55))
			else
				--sub lines
				drawSingleLine(node2DMesh, {Vec2(xPos,yy), Vec2(xPos,yy+(textSizeY*0.4))}, lineSubWidth, Vec4(0.45), Vec4(0.55))
			end
		end
		
		--
		--	add text
		--
			addText("0", Vec2(leftMargin+4,y-(bottomMargin+textSizeY+4)), textSizeY)
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
				break
			else
				line[#line+1] = Vec2(xx,func(wave))
			end
		end
		return line
	end
	
	
	
	function self.resize()
		--make sure it is a real rezise
		if x~=panel:getPanelContentPixelSize().x or y~=panel:getPanelContentPixelSize().y then
			--get new size
			textSizeY = math.floor(Core.getScreenResolution().y*0.012)
			x = panel:getPanelContentPixelSize().x
			y = panel:getPanelContentPixelSize().y
			leftMargin = math.floor(x*0.05)
			bottomMargin = math.floor(textSizeY*2.0)
			xPerWave = (x-leftMargin-lineMainWidth)/topXValue
			yPerScore = (y-bottomMargin-lineMainWidth)/topYValue
			
			--clear all old data
			panel:clear()
			
			--render new stuff
			local node2DMesh = Node2DMesh()
			panel:addRenderObject( node2DMesh )
			
			addGrid(node2DMesh, leftMargin, bottomMargin)
			
			drawLine(node2DMesh, drawScoreGraph(function(index)	return getGridY(getKill(index)["score"]) end), 1, Vec4(0.9))
			drawLine(node2DMesh, drawScoreGraph(function(index)	return getGridY(getKill(index)["score"]-(20*pScorePerLife)) end), 1, Vec4(0.85,0.85,0.85,0.1))--getKill(index)["life"]
			drawLine(node2DMesh, drawScoreGraph(function(index)	return getGridY(getKill(index)["goldGainedFromInterest"]) end), 1, Vec4(0.85,0.85,0.85,0.1))
			
			node2DMesh:compile()
		end
	end
	
	local function init()
		panel:addEventCallbackResized(self.resize)
	end
	init()
	
	return self
end