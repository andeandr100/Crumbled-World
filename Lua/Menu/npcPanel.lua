require("Game/mapInfo.lua")
--this = SceneNode()
NpcPanel = {}

function NpcPanel.new(panel)
	local self = {}
	local selectedCamera
	local targetPanel
	local DELAYOFFSET = 0.25
	local topPanelRight
	local frameBufferSize = Vec2i(0,0)
	local currentWaveIndex = 0
	--
	local loadBarIcon1
	local loadBarIcon2
	local startTimeIcone
	--
	local spawnList
	local spawnListWaveIndex = {}
	
	-- function:	handleStartWave
	-- purpose:		returns how fast the panel should scroll
	local function getPixelsPerSecond()
		return targetPanel:getPanelContentPixelSize().y*1.75
	end
	
	-- function:	LaunchNextWave
	-- purpose:		Callback that when called, lanunches the next npc group in the panel
	local function LaunchNextWave(panel)
		comUnit:sendTo("EventManager","spawnNextGroup","")
		comUnit:sendTo("SteamAchievement","Skip","")
	end
	-- function:	removeNextDelay
	-- purpose:		callback that removes the delay on the next group splitter, but not after any wave spliter
	local function removeNextDelay(panel)
		if currentWaveIndex>=1 then
			local success = false
			for i=spawnList.index, spawnList.count do
				if spawnList[i].name == "none" then
					if spawnList[i].noneType=="group splitter" then
						if not spawnList[i].disabled and i+1<=spawnList.count then
							spawnList[i+1].delay = 0.5
							spawnList[i+1].startDelay = 0.0
							spawnList[i].disabled = true
							success = true
							break
						end
					else
						break
					end
				elseif currentWaveIndex>1 and spawnList[i].startDelay>0.01 then
					spawnList[i].delay = 0.5
					spawnList[i].startDelay = 0.0
					success = true
					break
				end
			end
			if success then
				comUnit:sendTo("EventManager","removeNextDelay","")
				comUnit:sendTo("SteamAchievement","Skip","")
			end
		end
	end
	-- function:	getTopPanelRight
	-- purpose:		returns the top right panel
	function self.getTopPanelRight()
		return topPanelRight
	end
	-- function:	getSize
	-- purpose:		returns the y height of an icon based on its name
	local function getSize(npc)
		if npc.name=="rat_tank" then
			return 0.66
		elseif npc.name=="rat" then
			return 0.575
		elseif npc.name=="scorpion" then
			return 0.66
		elseif npc.name=="skeleton" then
			return 0.75
		elseif npc.name=="fireSpirit" or npc.name=="electroSpirit" then
			return 0.75
		elseif npc.name=="turtle" then
			return 0.66
		end
		return 1.0
	end
	-- function:	updateNpcIcon
	-- purpose:		updates the icon data, for a given npc
	local function updateNpcIcon(npc)
		local heightData = targetPanel:getPanelContentPixelSize().y
		local height = heightData * getSize(npc)
		--
		if not (npc.name=="turtle" or npc.name=="background" or npc.name=="none") then
			npc.icon:setRenderLevel(2)
			npc.yOffset = heightData - height 
			if height<heightData then
				if npc.currentUp then
					npc.yOffset = 0.0
				end
			end
		end
		if npc.name=="rat" or npc.name=="rat_tank" then
			npc.icon:setUvCoord(Vec2(0.0,0.0625),Vec2(0.1875,0.125))
			npc.icon:setSize(Vec2(height*1.5,height))
			npc.width = height*1.5*0.5
		elseif npc.name=="scorpion" then
			npc.icon:setUvCoord(Vec2(0.25,0.0625),Vec2(0.375,0.125))
			npc.icon:setSize(Vec2(height))
			npc.width = height*0.5
		elseif npc.name=="skeleton" then
			npc.icon:setUvCoord(Vec2(0.1875,0.0625),Vec2(0.25,0.125))
			npc.icon:setSize(Vec2(height*0.5,height))
			npc.width = height*0.5*0.5
		elseif npc.name=="electroSpirit" then
			npc.icon:setUvCoord(Vec2(0.375,0.0625),Vec2(0.50,0.125))
			npc.icon:setSize(Vec2(height))
			npc.width = height*0.5
		elseif npc.name=="fireSpirit" then
			npc.icon:setUvCoord(Vec2(0.625,0.0625),Vec2(0.75,0.125))
			npc.icon:setSize(Vec2(height))
			npc.width = height*0.5
		elseif npc.name=="dino" then
			npc.icon:setUvCoord(Vec2(0.0,0.125),Vec2(0.1875,0.1875))
			npc.icon:setSize(Vec2(height*1.5,height))
			npc.width = height*1.5*0.5
		elseif npc.name=="turtle" then
			npc.icon:setUvCoord(Vec2(0.1875,0.125),Vec2(0.375,0.1875))
			npc.icon:setSize(Vec2(height*1.5,height))
			npc.icon:setRenderLevel(3)
			npc.width = height*1.5*0.5
		elseif npc.name=="background" then
			npc.icon:setRenderLevel(-2)
			npc.icon:setUvCoord(Vec2(0.125,0.1875),Vec2(0.875,0.250))
			npc.icon:setSize(Vec2(heightData*6.2,heightData))
			npc.startAlpha = 0.5
			npc.icon:setColor(Vec4(1,1,1,npc.startAlpha))
		elseif npc.name=="skeleton_cf" then
			npc.icon:setUvCoord(Vec2(0.375,0.125),Vec2(0.4375,0.1875))
			npc.icon:setSize(Vec2(height*0.5,height))
			npc.width = height*0.5*0.5
		elseif npc.name=="skeleton_cb" then
			npc.icon:setUvCoord(Vec2(0.4375,0.125),Vec2(0.5,0.1875))
			npc.icon:setSize(Vec2(height*0.5,height))
			npc.width = height*0.5*0.5
		elseif npc.name=="reaper" then
			npc.icon:setUvCoord(Vec2(0.50,0.125),Vec2(0.625,0.1875))
			npc.icon:setSize(Vec2(height))
			npc.width = height*0.5
		elseif npc.name=="stoneSpirit" then
			npc.icon:setUvCoord(Vec2(0.50,0.0625),Vec2(0.625,0.125))
			npc.icon:setSize(Vec2(height))
			npc.width = height*0.5
		elseif npc.name=="hydra5" or npc.name=="hydra4" or npc.name=="hydra3" or npc.name=="hydra2" or npc.name=="hydra1" then
			npc.icon:setUvCoord(Vec2(0.625,0.125),Vec2(0.75,0.1875))
			npc.icon:setSize(Vec2(height))
			npc.width = height*0.5
		elseif npc.name=="none" then
			if npc.noneType == "wave splitter" then
				npc.icon:setUvCoord(Vec2(0.0,0.1885),Vec2(0.083984,0.231445))
				npc.icon:setSize(Vec2(height))
				npc.width = height*0.5
			elseif npc.noneType == "group splitter" then
				npc.icon:setUvCoord(Vec2(0.091797,0.18842),Vec2(0.11914,0.24903))
				npc.icon:setSize(Vec2(height*0.225806,height))
				npc.width = height*0.225806*0.5
			else
				abort()
			end
		else
			abort()
		end
	end
	-- function:	updatePosition
	-- purpose:		updates the position of the icon and its color/alpha
	local function updatePosition()
		local tDelay = DELAYOFFSET
		if spawnList then
			for i=spawnList.index, spawnList.count do
				local npc = spawnList[i]
				if not npc.disabled then
					tDelay = tDelay + npc.delay
					--alpha on units to the far right side
					local npcX = tDelay*getPixelsPerSecond()-npc.width
					local leftFlank = getPixelsPerSecond()*3.0
					--local alpha = tDelay<2.0 and tDelay-1.0 or 1.0--npcX<targetPanel:getPanelContentPixelSize().x-leftFlank and 1.0 or 1.0-((npcX-(targetPanel:getPanelContentPixelSize().x-leftFlank))/leftFlank)
					local alpha = npc.startAlpha*math.clamp(tDelay-(DELAYOFFSET-0.5),0,1)--if 0<alpha or alpha>1 then the npc is not visible
					--
					npc.icon:setColor(Vec4(1,1,1,alpha))
					npc.icon:setPosition( Vec2(npcX,npc.yOffset) )
				else
					npc.icon:setColor(Vec4(1,1,1,0))
				end
			end
		end
	end
	-- function:	resize
	-- purpose:		callback event that is trigered when the window is resized. It will update all icons and positions
	local function resize()
		print("resize("..(spawnList and spawnList.count or 0)..")")
		print("Y = "..targetPanel:getPanelContentPixelSize().y)
		--if any npc has been initiated
		if spawnList then
			--update all initiated npcs
			for i=spawnList.index, spawnList.count do
				updateNpcIcon( spawnList[i] )
			end
		end
		--update position
		updatePosition()
	end
	-- function:	init
	-- purpose:		the constructor
	local function init()
		local mapInfo = MapInfo.new()
		panel:addEventCallbackResized(resize)
		if mapInfo.getGameMode()=="default" or mapInfo.getGameMode()=="rush" then
			local nextIcon = Core.getTexture("icon_table.tga")
			local SkipWaveButton = panel:add(Button(PanelSize(Vec2(-0.6,-1), Vec2(1.0,1.0),PanelSizeType.ParentPercent), ButtonStyle.SIMPLE, nextIcon, Vec2(0.375,0.25), Vec2(0.50, 0.3125)))

			SkipWaveButton:addEventCallbackExecute(removeNextDelay)
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
	-- function:	addTargetPanel
	-- purpose:		sets what panel we will work against
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
	-- function:	removeTimeLineIcon
	-- purpose:		moves icon (spawnList.index) to a list that will be deleted
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
		if spawnList[spawnList.index] and spawnList[spawnList.index].disabled then
			npcToBeRemoved[npcToBeRemoved.size+1] = spawnList.index
			npcToBeRemoved.size = npcToBeRemoved.size + 1
			spawnList.index = spawnList.index + 1
		end
		if spawnList[spawnList.index] then
			originalStartDelay = spawnList[spawnList.index].startDelay>0.1 and spawnList[spawnList.index].startDelay or originalStartDelay
			spawnList[spawnList.index].delay = spawnList[spawnList.index].delay + delay
		end
	end
	-- function:	getStartDelayForTurtle
	-- purpose:		returns what delay the turtle needs to be able to work
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
	-- function:	getMinDelayForTurtle
	-- purpose:		returns the minimum delay that a turtle/splitter needs
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
	-- function:	addNpc
	-- purpose:		adds an npc to the list to be displayed in the bar
	function addNpc(npc)
		if spawnList.count>0 or npc.name~="none" then
			selectedCamera:add2DScene(npc.icon)
			spawnList.count = spawnList.count + 1
			spawnList[spawnList.count] = npc
			--return the position
			return spawnList.count
		end
	end
	-- function:	setStartTimeIconPer
	-- purpose:		Updates the timer icon, how many percentage it should display
	local function setStartTimeIconPer(per)
		per = math.max(0.0,math.min(1.0,per))
		local height = targetPanel:getPanelContentPixelSize().y-4
		local perHeight = math.floor(height*per)
		startTimeIcone:resize(Vec2(getPixelsPerSecond()*DELAYOFFSET-2,2+(height-perHeight)),Vec2(4,perHeight))
		--startTimeIcone:setSize(Vec2(4,height*per))
		--startTimeIcone:setPosition( Vec2(getPixelsPerSecond()-2,2+(height-height*per)) )
	end
	-- function:	fixCurrentWave
	-- purpose:		adds/fixes everything that is needed to display/work the wave
	local function fixCurrentWave(param,restore,isFirstWave)
		currentWave = waves[param]
		--if we try to add (last wave + 1) then it should not crash
		if currentWave==nil then
			return false
		end
		local spawListExistingPosIterator	--this iterator is used if the wave already exists
		if not spawnListWaveIndex[param] then
			--load in the wave for the first time
			spawnListWaveIndex[param] = spawnList.count + 1
			currentIndex = 2
		elseif restore==false then
			--all icons should be there
			return true
		else
			--reload the wave and restore removed icons
			spawListExistingPosIterator = spawnListWaveIndex[param]
			currentIndex = 2--param==1 and 3 or 2--2==normal wave, 3 for first wave as it do not have an icon
		end
		currentWave.wave = param
		
		local currentUp = false
		local heightData = targetPanel:getPanelContentPixelSize().y
		local startIndex = currentIndex
		
		--initiated the countdown bar background, for when next npc spawns
		if not loadBarIcon1 then
			loadBarIcon1 = Gradient(Vec4(0.96,0.96,0.96,1.0),Vec4(0.30,0.34,0.37,1.0),Vec4(0.96,0.96,0.96,1.0),Vec4(0.30,0.34,0.37,1.0))
			loadBarIcon1:resize(Vec2(getPixelsPerSecond()*DELAYOFFSET-4,0),Vec2(8,targetPanel:getPanelContentPixelSize().y))
			selectedCamera:add2DScene(loadBarIcon1)
			--
			loadBarIcon2 = Gradient(Vec4(0.30,0.34,0.37,1.0),Vec4(0.96,0.96,0.96,1.0),Vec4(0.30,0.34,0.37,1.0),Vec4(0.96,0.96,0.96,1.0))
			loadBarIcon2:resize(Vec2(getPixelsPerSecond()*DELAYOFFSET-2,2),Vec2(4,targetPanel:getPanelContentPixelSize().y-4))
			selectedCamera:add2DScene(loadBarIcon2)
		end
		--initiated the red countdown bar, for when next npc spawns
		if not startTimeIcone then
			startTimeIcone = Gradient(Vec4(0.35,0.06,0.06,1.0),Vec4(0.70,0.09,0.09,1.0),Vec4(0.35,0.06,0.06,1.0),Vec4(0.70,0.09,0.09,1.0))
			setStartTimeIconPer(1.0)
			selectedCamera:add2DScene(startTimeIcone)
		end
		--
		--loop all items for the current wave
		for i=currentIndex, #currentWave do
			local npc2
			local npc
			if not spawListExistingPosIterator then
				--if none added npc then create everything
				npc = {
					delay = 0.0,
					startDelay = 0.0,
					startAlpha = 1.0,
					waveIndex = param,
					name = currentWave[i].npc,
					icon = Sprite(Core.getTexture("icon_table.tga"))
				}
			else
				--the already exist, then we reuse the existing icon
				npc = spawnList[spawListExistingPosIterator]
				npc.delay = 0.0
				npc.startDelay = 0.0
				npc.startAlpha = 1.0
				npc.waveIndex = param
				npc.name = currentWave[i].npc
				if not (npc.name=="none" and i==2 and param==1) then
					spawListExistingPosIterator = spawListExistingPosIterator + 1
				end
				if not npc.icon then
					npc.icon = Sprite(Core.getTexture("icon_table.tga"))
					selectedCamera:add2DScene(npc.icon)
				end
			end
			npc.icon:setRenderLevel(2)
			local height = heightData * getSize(npc)
			npc.yOffset = heightData - height 
			npc.currentUp = currentUp
			if height<heightData then
				if currentUp then
					npc.yOffset = 0.0
				end
				currentUp = not currentUp 
			end
			if npc.name=="turtle" then
				--
				--	Background
				--
				if not spawListExistingPosIterator then
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
				else
					npc2 = spawnList[spawListExistingPosIterator]
					spawListExistingPosIterator = spawListExistingPosIterator + 1
					if not npc2.icon then
						npc2.icon = Sprite(Core.getTexture("icon_table.tga"))
						selectedCamera:add2DScene(npc2.icon)
					end
				end
				updateNpcIcon(npc2)
			end
			if npc.name=="none" then
				startDelayBuff = startDelayBuff + currentWave[i].delay
				local isFirstItem = (i==2 and npc.waveIndex==1)
				if not isFirstItem then--spawnList.count>0 then
					currentUp = false
					--npc.waveIndex = npc.waveIndex - 1
					local indexPos = spawListExistingPosIterator and spawListExistingPosIterator or spawnList.count
					if i==2 then
						npc.noneType = "wave splitter"
						updateNpcIcon(npc)
						--wave splitter
						local sizeDelay = (height*0.5+(spawnList[indexPos].width or 0.0)+5.0)/getPixelsPerSecond()--shift for this icon
						local turtleDelay = param>1 and getMinDelayForTurtle(waves[param-1],#waves[param-1]) or getMinDelayForTurtle(waves[param],i)
						sizeDelay = turtleDelay>0.0 and turtleDelay or sizeDelay--turtleDelay>sizeDelay and turtleDelay or sizeDelay
						npc.delay = sizeDelay
						noneDelayBuff = (height*0.5+5.0)/getPixelsPerSecond()--shift for after comming npc
						local testDelayBuff = getStartDelayForTurtle(waves[param],i)
						if testDelayBuff>noneDelayBuff then
							noneDelayBuff = testDelayBuff
						end
						startDelayBuff = startDelayBuff - sizeDelay
						if isFirstWave and spawListExistingPosIterator then
							startDelayBuff = startDelayBuff + npc.delay
							npc.delay = -1.1
						end
					else
						npc.noneType = "group splitter"
						updateNpcIcon(npc)
						--group splitter
						noneDelayBuff = getStartDelayForTurtle(waves[param],i)
						noneDelayBuff = noneDelayBuff - (noneDelayBuff>0.0 and 0.25 or 0.0)--because of bad math somewhere
						local sizeDelay = (npc.width+(spawnList[indexPos].width or 0.0)+5.0)/getPixelsPerSecond()
						local turtleDelay = getMinDelayForTurtle(waves[param],i)
						sizeDelay = turtleDelay>0.0 and turtleDelay or sizeDelay--sizeDelay = turtleDelay>sizeDelay and turtleDelay or sizeDelay
						npc.delay = sizeDelay
						startDelayBuff = startDelayBuff - sizeDelay
					end
				end
			else
				updateNpcIcon(npc)
				--
				npc.delay = currentWave[i].delay
				--check if we need to add a delay to the first npc (to move it away from the left edge)
				local sizeDelay = math.max(0.5,(height*0.5+5.0)/getPixelsPerSecond() + noneDelayBuff)
				if npc.delay<sizeDelay and startDelayBuff>=sizeDelay then
					local missing = sizeDelay-npc.delay
					npc.delay = npc.delay + missing
					startDelayBuff = startDelayBuff - missing
				end
				if startDelayBuff>0.0 then
					npc.startDelay = startDelayBuff
					startDelayBuff = 0.0
				end
			end
			--update icon
			
			--if the icons did not exist from the begining then add tem
			if not spawListExistingPosIterator then
				addNpc(npc)
				if npc2 then
					addNpc(npc2)
				end
			end
		end
		return true
	end
	-- function:	isLongerThenMenu
	-- purpose:		Returns true if all acrive npcs are long enough to cover the entire menu
	local function isLongerThenMenu()
		local tDelay = 1.0--groups[groups.index].delay
		for i=spawnList.index, spawnList.count do
			if not spawnList[i].icon then
				return false
			else
				tDelay = tDelay + spawnList[i].delay
			end
		end
		return tDelay>(targetPanel:getPanelContentPixelSize().x*1.1/getPixelsPerSecond())
	end
	-- function:	fillMenu
	-- purpose:		fills the menu with enough npcs to cover it
	local function fillMenu(index,restore,first)
		if not isLongerThenMenu() then
			if fixCurrentWave(index,restore,first) then
				fillMenu(index+1,restore,false)
			end
		end
	end
	-- function:	handleStartWave
	-- purpose:		prepars waves from pWave
	function self.handleStartWave(param)
		local pWave,pReload = string.match(param, "(.*);(.*)")
		pWave = tonumber(pWave)		--what wave we are going to work from
		pReload = tonumber(pReload)	--if it should be restored
		npcToBeRemoved = npcToBeRemoved or {size=0}	--make sur the erase list exist
		spawnList = spawnList or {count=0,index=1}	--make sure that a spawn list exist
		--if we have gone back in time, set active index to the waves start index
		if currentWaveIndex>=pWave then
			spawnList.index = spawnListWaveIndex[pWave]
		end
		
		--fix all delays
		startDelayBuff = 0.0
		noneDelayBuff = 0.0
		--populate menu
		fillMenu(pWave,pReload>=1,true)
		updatePosition()
		--
		originalStartDelay = originalStartDelay or spawnList[1].startDelay
		assert(originalStartDelay, "An originalStartDelay must be set")
		currentWaveDelay = 0.0
		currentWaveIndex = pWave
		currentWave = waves[pWave]
		nextWave = waves[pWave+1]
		currentIndex = 2
	end
	-- function:	handleWaveInfo
	-- purpose:		callback to set base data for all waves
	function self.handleWaveInfo(paramTable)
		waves = paramTable
		self.handleStartWave("1;0")
		currentWaveIndex = 0
	end
	-- function:	handleSetWaveNpcIndex
	-- purpose:		
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
	-- function:	update
	-- purpose:		updates the panel every frame
	function self.update()
		if frameBufferSize ~= targetPanel:getPanelContentPixelSize() then
			frameBufferSize = targetPanel:getPanelContentPixelSize()
			--set frame buffer size
			--this will only change the buffer if the buffer size changes
			selectedCamera:setFrameBufferSize(frameBufferSize)
		end
		if spawnList then
			--make sure there is enough npc's to fill the menu
			fillMenu(currentWaveIndex,false,false)
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
				spawnList[npcToBeRemoved[i]].icon = nil
			end
			npcToBeRemoved.size = 0
		end
		
		--only render when the images changes
		selectedCamera:render()
	end
	
	
	return self
end