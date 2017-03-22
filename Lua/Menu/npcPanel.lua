require("Game/mapInfo.lua")
--this = SceneNode()
NpcPanel = {}

function NpcPanel.new(panel)
	local self = {}
	local selectedCamera
	local targetPanel
	local delayOffset = 0.25
	local topPanelRight
	local frameBufferSize = Vec2i(0,0)
	
	local function LaunchNextWave(panel)
		comUnit:sendTo("EventManager","spawnNextGroup","")
		comUnit:sendTo("SteamAchievement","Skip","")
	end
	
	function self.getTopPanelRight()
		return topPanelRight
	end
	
	local function init()
		local mapInfo = MapInfo.new()
		if mapInfo.getGameMode()=="Training" then
			local nextIcon = Core.getTexture("icon_table.tga")
			local SkipWaveButton = panel:add(Button(PanelSize(Vec2(-0.6,-1), Vec2(1.0,1.0),PanelSizeType.ParentPercent), ButtonStyle.SIMPLE, nextIcon, Vec2(0.375,0.25), Vec2(0.50, 0.3125)))

			SkipWaveButton:addEventCallbackExecute(LaunchNextWave)
			SkipWaveButton:setTag("NextWave")
			SkipWaveButton:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
			SkipWaveButton:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			SkipWaveButton:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
			SkipWaveButton:setEdgeColor(Vec4(0), Vec4(0))
			SkipWaveButton:setEdgeHoverColor(Vec4(0), Vec4(0))
			SkipWaveButton:setEdgeDownColor(Vec4(0), Vec4(0))
		end
		
		
		topPanelRight = panel:add(Panel(PanelSize(Vec2(-1,-1))))
		topPanelRight:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		
		
		
		
	end
	
	function self.addTargetPanel()
		--Create camera
		selectedCamera = Camera(Text("eventCamera"),false,800,100);
		--clear color
		selectedCamera:setClearColor(Vec4(0,0,0,1.0))
		
		
		--Create the panel we will render to
		targetPanel = topPanelRight:add(Panel(PanelSize(Vec2(-1))))
		--set the background texture to use the camera
		targetPanel:setBackground(Sprite(selectedCamera:getTexture()))
	end
	
	init()
	
	local function updatePosition()
		local tDelay = delayOffset
		for i=spawnList.index, spawnList.count do
			local npc = spawnList[i]
			tDelay = tDelay + npc.delay
			--alpha on units to the far right side
			local npcX = tDelay*xPixelPerSecond-npc.width
			local leftFlank = xPixelPerSecond*3.0
			--local alpha = tDelay<2.0 and tDelay-1.0 or 1.0--npcX<targetPanel:getPanelContentPixelSize().x-leftFlank and 1.0 or 1.0-((npcX-(targetPanel:getPanelContentPixelSize().x-leftFlank))/leftFlank)
			local alpha = npc.startAlpha*math.clamp(tDelay-(delayOffset-0.5),0,1)--if 0<alpha or alpha>1 then the npc is not visible
			--
			npc.icon:setColor(Vec4(1,1,1,alpha))
			npc.icon:setPosition( Vec2(npcX,npc.yOffset) )
		end
	end
	local function removeTimeLineIcon(delay)
		--remove npc/item
		npcToBeRemoved[npcToBeRemoved.size+1] = spawnList.index
		npcToBeRemoved.size = npcToBeRemoved.size + 1
		--selectedCamera:remove2DScene(npc.icon)
		--spawnList[spawnList.index] = nil
		--
		if spawnList[spawnList.index] then
			spawnList[spawnList.index].startDelay = -1.1
			spawnList[spawnList.index].delay = -1.1
			spawnList[spawnList.index].icon:setPosition( Vec2(-1024,0) )
		end
		--
		spawnList.index = spawnList.index + 1
		if spawnList[spawnList.index] then
			originalStartDelay = spawnList[spawnList.index].startDelay>0.1 and spawnList[spawnList.index].startDelay or originalStartDelay
			spawnList[spawnList.index].delay = spawnList[spawnList.index].delay + delay
		end
	end
	
	
	local function getSize(index)
		if currentWave[index].npc=="rat_tank" then
			return 0.66
		elseif currentWave[index].npc=="rat" then
			return 0.575
		elseif currentWave[index].npc=="scorpion" then
			return 0.66
		elseif currentWave[index].npc=="skeleton" then
			return 0.75
		elseif currentWave[index].npc=="fireSpirit" or currentWave[index].npc=="electroSpirit" then
			return 0.75
		elseif currentWave[index].npc=="turtle" then
			return 0.66
		end
		return 1.0
	end
	local function getStartDelayForTurtle(checkWave,index)
		local tDelay = 0.0
		--turtle,npc,npc,npc,none
		for i=index+1, #checkWave, 1 do
			if checkWave[i].npc=="none" then
				return 0.0
			elseif checkWave[i].npc=="turtle" then
				--minDelay == 1.75 == 3.5m / 2.0m/s
				tDelay = tDelay + checkWave[i].delay
				if tDelay<1.75 then
					return 1.75-tDelay
				end
			end
			tDelay = tDelay + checkWave[i].delay
		end
		return 0.0
	end
	
	local function getMinDelayForTurtle(checkWave,index)
		local tDelay = 0.0
		--turtle,npc,npc,npc,none
		for i=index-1, 2, -1 do
			if checkWave[i].npc=="none" then
				return 0.0
			elseif checkWave[i].npc=="turtle" then
				--minDelay == 1.75 == 3.5m / 2.0m/s
				if tDelay<1.80 then
					return 1.80-tDelay
				end
			end
			tDelay = tDelay + checkWave[i].delay
		end
		return 0.0
	end
	function addNpc(npc)
		if spawnList.count>0 or npc.name~="none" then
			selectedCamera:add2DScene(npc.icon)
			spawnList.count = spawnList.count + 1
			spawnList[spawnList.count] = npc
		end
	end
	
	local function setStartTimeIconPer(per)
		per = math.max(0.0,math.min(1.0,per))
		local height = targetPanel:getPanelContentPixelSize().y-4
		local perHeight = math.floor(height*per)
		startTimeIcone:resize(Vec2(xPixelPerSecond*delayOffset-2,2+(height-perHeight)),Vec2(4,perHeight))
		--startTimeIcone:setSize(Vec2(4,height*per))
		--startTimeIcone:setPosition( Vec2(xPixelPerSecond-2,2+(height-height*per)) )
	end
	
	local function fixCurrentWave(param)
		currentWave = waves[param]
		if currentWave==nil then
			return false
		end
		if not currentWave.wave and param>0 then
			currentWave.wave = param
			currentIndex = 2
			--local group = {delay=0.0,startDelay=0.0,waveIndex=param,index=1}
			local currentUp = false
			local heightData = targetPanel:getPanelContentPixelSize().y
			local startIndex = currentIndex
			
			--local icon = Sprite(Vec4(1,1,1,1))
			local icon = Gradient(Vec4(0.96,0.96,0.96,1.0),Vec4(0.30,0.34,0.37,1.0),Vec4(0.96,0.96,0.96,1.0),Vec4(0.30,0.34,0.37,1.0))
			--icon:setSize(Vec2(8,targetPanel:getPanelContentPixelSize().y))
			--icon:setPosition( Vec2(xPixelPerSecond-4,0) )
			icon:resize(Vec2(xPixelPerSecond*delayOffset-4,0),Vec2(8,targetPanel:getPanelContentPixelSize().y))
			selectedCamera:add2DScene(icon)
			--
			local icon2 = Gradient(Vec4(0.30,0.34,0.37,1.0),Vec4(0.96,0.96,0.96,1.0),Vec4(0.30,0.34,0.37,1.0),Vec4(0.96,0.96,0.96,1.0))
			icon2:resize(Vec2(xPixelPerSecond*delayOffset-2,2),Vec2(4,targetPanel:getPanelContentPixelSize().y-4))
			selectedCamera:add2DScene(icon2)
			--
			startTimeIcone = Gradient(Vec4(0.35,0.06,0.06,1.0),Vec4(0.70,0.09,0.09,1.0),Vec4(0.35,0.06,0.06,1.0),Vec4(0.70,0.09,0.09,1.0))
			setStartTimeIconPer(1.0)
			selectedCamera:add2DScene(startTimeIcone)
			--
			
			for i=currentIndex, #currentWave do
				local npc2
				local npc = {
					delay = 0.0,
					startDelay = 0.0,
					startAlpha = 1.0,
					waveIndex = param,
					name = currentWave[i].npc,
					icon = Sprite(Core.getTexture("icon_table.tga"))
				}
				npc.icon:setRenderLevel(2)
				local height = heightData * getSize(i)
				npc.yOffset = heightData - height 
				if height<heightData then
					if currentUp then
						npc.yOffset = 0.0
					end
					currentUp = not currentUp 
				end
				if currentWave[i].npc=="rat" or currentWave[i].npc=="rat_tank" then
					npc.icon:setUvCoord(Vec2(0.0,0.0625),Vec2(0.1875,0.125))
					npc.icon:setSize(Vec2(height*1.5,height))
					npc.width = height*1.5*0.5
				elseif currentWave[i].npc=="scorpion" then
					npc.icon:setUvCoord(Vec2(0.25,0.0625),Vec2(0.375,0.125))
					npc.icon:setSize(Vec2(height))
					npc.width = height*0.5
				elseif currentWave[i].npc=="skeleton" then
					npc.icon:setUvCoord(Vec2(0.1875,0.0625),Vec2(0.25,0.125))
					npc.icon:setSize(Vec2(height*0.5,height))
					npc.width = height*0.5*0.5
				elseif currentWave[i].npc=="electroSpirit" then
					npc.icon:setUvCoord(Vec2(0.375,0.0625),Vec2(0.50,0.125))
					npc.icon:setSize(Vec2(height))
					npc.width = height*0.5
				elseif currentWave[i].npc=="fireSpirit" then
					npc.icon:setUvCoord(Vec2(0.625,0.0625),Vec2(0.75,0.125))
					npc.icon:setSize(Vec2(height))
					npc.width = height*0.5
				elseif currentWave[i].npc=="dino" then
					npc.icon:setUvCoord(Vec2(0.0,0.125),Vec2(0.1875,0.1875))
					npc.icon:setSize(Vec2(height*1.5,height))
					npc.width = height*1.5*0.5
				elseif currentWave[i].npc=="turtle" then
					npc.icon:setUvCoord(Vec2(0.1875,0.125),Vec2(0.375,0.1875))
					npc.icon:setSize(Vec2(height*1.5,height))
					npc.icon:setRenderLevel(3)
					npc.width = height*1.5*0.5
					--
					--	Background
					--
					npc2 = {
						delay = 0.0,
						startDelay = 0.0,
						startAlpha = 1.0,
						waveIndex = param,
						name = "background",
						icon = Sprite(Core.getTexture("icon_table.tga")),
						yOffset = 0.0,
						width = heightData*6.2*0.5
					}
					npc2.icon:setRenderLevel(-2)
					npc2.icon:setUvCoord(Vec2(0.125,0.1875),Vec2(0.875,0.250))
					npc2.icon:setSize(Vec2(heightData*6.2,heightData))
					npc2.startAlpha = 0.5
					npc2.icon:setColor(Vec4(1,1,1,npc2.startAlpha))
				elseif currentWave[i].npc=="skeleton_cf" then
					npc.icon:setUvCoord(Vec2(0.375,0.125),Vec2(0.4375,0.1875))
					npc.icon:setSize(Vec2(height*0.5,height))
					npc.width = height*0.5*0.5
				elseif currentWave[i].npc=="skeleton_cb" then
					npc.icon:setUvCoord(Vec2(0.4375,0.125),Vec2(0.5,0.1875))
					npc.icon:setSize(Vec2(height*0.5,height))
					npc.width = height*0.5*0.5
				elseif currentWave[i].npc=="reaper" then
					npc.icon:setUvCoord(Vec2(0.50,0.125),Vec2(0.625,0.1875))
					npc.icon:setSize(Vec2(height))
					npc.width = height*0.5
				elseif currentWave[i].npc=="stoneSpirit" then
					npc.icon:setUvCoord(Vec2(0.50,0.0625),Vec2(0.625,0.125))
					npc.icon:setSize(Vec2(height))
					npc.width = height*0.5
				elseif currentWave[i].npc=="hydra5" or currentWave[i].npc=="hydra4" or currentWave[i].npc=="hydra3" or currentWave[i].npc=="hydra2" or currentWave[i].npc=="hydra1" then
					npc.icon:setUvCoord(Vec2(0.625,0.125),Vec2(0.75,0.1875))
					npc.icon:setSize(Vec2(height))
					npc.width = height*0.5
				end
				if currentWave[i].npc=="none" then
					startDelayBuff = startDelayBuff + currentWave[i].delay
					if spawnList.count>0 then
						currentUp = false
						--npc.waveIndex = npc.waveIndex - 1
						if i==2 then
							--wave splitter
							local sizeDelay = (height*0.5+(spawnList.count>=0 and spawnList[spawnList.count].width or 0.0)+5.0)/xPixelPerSecond--shift for this icon
							local turtleDelay = param>1 and getMinDelayForTurtle(waves[param-1],#waves[param-1]) or getMinDelayForTurtle(waves[param],i)
							sizeDelay = turtleDelay>0.0 and turtleDelay or sizeDelay--turtleDelay>sizeDelay and turtleDelay or sizeDelay
							npc.delay = sizeDelay
							noneDelayBuff = (height*0.5+5.0)/xPixelPerSecond--shift for after comming npc
							local testDelayBuff = getStartDelayForTurtle(waves[param],i)
							if testDelayBuff>noneDelayBuff then
								noneDelayBuff = testDelayBuff
							end
							startDelayBuff = startDelayBuff - sizeDelay
							npc.icon:setUvCoord(Vec2(0.0,0.1885),Vec2(0.083984,0.231445))
							npc.icon:setSize(Vec2(height))
							npc.width = height*0.5
							npc.noneType = "wave splitter"
						else
							--group splitter
							noneDelayBuff = getStartDelayForTurtle(waves[param],i)
							noneDelayBuff = noneDelayBuff - (noneDelayBuff>0.0 and 0.25 or 0.0)--because of bad math somewhere
							npc.width = height*0.225806*0.5
							local sizeDelay = (npc.width+(spawnList.count>=0 and spawnList[spawnList.count].width or 0.0)+5.0)/xPixelPerSecond
							local turtleDelay = getMinDelayForTurtle(waves[param],i)
							sizeDelay = turtleDelay>0.0 and turtleDelay or sizeDelay--sizeDelay = turtleDelay>sizeDelay and turtleDelay or sizeDelay
							npc.delay = sizeDelay
							startDelayBuff = startDelayBuff - sizeDelay
							npc.icon:setUvCoord(Vec2(0.091797,0.18842),Vec2(0.11914,0.24903))
							npc.icon:setSize(Vec2(height*0.225806,height))
							npc.noneType = "group splitter"
						end
					end
				else
					npc.delay = currentWave[i].delay
					--check if we need to add a delay to the first npc (to move it away from the left edge)
					local sizeDelay = math.max(0.5,(height*0.5+5.0)/xPixelPerSecond + noneDelayBuff)
					if npc.delay<sizeDelay and startDelayBuff>=sizeDelay then
						local missing = sizeDelay-npc.delay
						npc.delay = npc.delay + missing
						startDelayBuff = startDelayBuff - missing
					end
					if currentWave[i+1] and currentWave[i+1].npc=="none" then
						--noneDelayBuff = sizeDelay
					end
					if startDelayBuff>0.0 then
						npc.startDelay = startDelayBuff
						startDelayBuff = 0.0
					end
				end
				addNpc(npc)
				if npc2 then
					addNpc(npc2)
				end
			end
		end
		return true
	end
	local function isLongerThenMenu()
		local tDelay = 1.0--groups[groups.index].delay
		for i=spawnList.index, spawnList.count do
			tDelay = tDelay + spawnList[i].delay
		end
		return tDelay>(targetPanel:getPanelContentPixelSize().x*1.1/xPixelPerSecond)
	end
	local function fillMenu(index)
		if not isLongerThenMenu() then
			if fixCurrentWave(index) then
				fillMenu(index+1)
			end
		end
	end
	
	function self.handleStartWave(param)
		npcToBeRemoved = npcToBeRemoved or {size=0}
		spawnList = spawnList or {count=0,index=1}
		startDelayBuff = 0.0
		noneDelayBuff = 0.0
		xPixelPerSecond = targetPanel:getPanelContentPixelSize().y*1.75
		--populate menu
		fillMenu(param)
		updatePosition()
		--
		originalStartDelay = originalStartDelay or spawnList[1].startDelay or 30.0
		currentWaveDelay = 0.0
		currentWaveIndex = param
		currentWave = waves[param]
		nextWave = waves[param+1]
		currentIndex = 2
		--
	end
	function self.handleWaveInfo(paramTable)
		waves = paramTable
		self.handleStartWave(1)
		currentWaveIndex = 0
	end
	
	function self.handleSetWaveNpcIndex(param)
		local start = spawnList.index
		for i=spawnList.index, spawnList.count do
			if spawnList[i].noneType and start~=i then
				break
			end
			spawnList[i].startDelay = -1.0
			spawnList[i].delay = -1.0
		end
		while spawnList[spawnList.index] and (spawnList[spawnList.index].delay<0.0 or currentWaveIndex>spawnList[spawnList.index].waveIndex) do
			removeTimeLineIcon(0.0)
		end
		updatePosition()
	end
	
	
	
	

	function self.update()
		if frameBufferSize ~= targetPanel:getPanelContentPixelSize() then
			frameBufferSize = targetPanel:getPanelContentPixelSize()
			--set frame buffer size
			--this will only change the buffer if the buffer size changes
			selectedCamera:setFrameBufferSize(frameBufferSize)
			
	--		for i=1, #testIcons do
	--			testIcons[i]:setSize(Vec2(frameBufferSize.y))
	--		end
	--		if currentWave then
	--			for i=currentIndex, #currentWave do
	--				currentWave[i].icon:setSize(Vec2(frameBufferSize.y))
	--			end
	--		end
		end
		if spawnList then
			--make sure there is enough npc's to fill the menu
			fillMenu(currentWaveIndex)
			--remove units outside this waveCount
			while spawnList[spawnList.index] and (spawnList[spawnList.index].delay<0.0 or currentWaveIndex>spawnList[spawnList.index].waveIndex) do
				removeTimeLineIcon(0.0)
			end
			--
			local npc = spawnList[spawnList.index]
			if npc then
				if currentWaveIndex>=npc.waveIndex then
					if npc.startDelay>0.0 then
						npc.startDelay = npc.startDelay - Core.getDeltaTime()
						if npc.startDelay<=0.0 then
							npc.delay = npc.delay + npc.startDelay
						end
					end
					if npc.startDelay<=0.0 then
						npc.delay = npc.delay - Core.getDeltaTime()
						if npc.delay<0.0 then
							removeTimeLineIcon(npc.delay)
						end
					end
					setStartTimeIconPer(npc.startDelay/originalStartDelay)
					--
					updatePosition()
				end
			end
			--removed deleted icons
			for i=1, npcToBeRemoved.size do
				selectedCamera:remove2DScene(spawnList[npcToBeRemoved[i]].icon)
				spawnList[npcToBeRemoved[i]] = nil
			end
			npcToBeRemoved.size = 0
		end
		
		--only render when the images changes
		selectedCamera:render()
	end
	
	
	return self
end