require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/npcPanel.lua")

--this = SceneNode()

local toolTips = {}
local gameMode = ""
local toolTipsIndexGold = 0
local toolTipsIndexScore = 0
local gameSpeed = 1.0
local start_time = 0

function createLabel( panel, startValue)
	
	local label = panel:add(Label(PanelSize(Vec2(1,-1),Vec2(3,1)),Text(startValue)));
	label:setTextColor(Vec3(1));
	label:setBackground(Sprite(Vec4(0,0,0,0.5)));
	label:setTextAlignment(Alignment.MIDDLE_LEFT)
	label:setPadding(BorderSize(Vec4(0.001)));
	label:setBorder(Border(BorderSize(Vec4(0.001)), Vec4(0,0,0,1)));
	label:setMargin(BorderSize(Vec4(0.001)));
	label:setCanHandleInput(false)

	return label
end

function createStat(minUvCoord, maxUvCoor, startValue, toolTipText)
	
	local panel = topPanelRight:add(Panel(PanelSize(Vec2(1,-1), Vec2(4,1))))
	
	local tutorialBillboard = Core.getGameSessionBillboard("tutorial")
	tutorialBillboard:setPanel(toolTipText, panel)
	
	local image = panel:add(Image(PanelSize(Vec2(1,-1),Vec2(1, 1)), Text("icon_table.tga")))
	image:setUvCoord(minUvCoord,maxUvCoor);

	image:setCanHandleInput(false)
	
	local label = createLabel( panel, startValue )
	
	panel:setToolTip(language:getText(toolTipText))
	
	toolTips[#toolTips + 1] = {panel=panel, text=toolTipText}
	
	return label, image
end

function createSpeedButton(minUvCoord, maxUvCoor, startValue, toolTipText, func)
	
	local panel = topPanelRight:add(Panel(PanelSize(Vec2(1,-1), Vec2(4,1))))
	
	local tutorialBillboard = Core.getGameSessionBillboard("tutorial")
	tutorialBillboard:setPanel("speed", panel)
	
	local icon = Core.getTexture("icon_table.tga")
	customButton = panel:add(Button(PanelSize(Vec2(1,-1),Vec2(1, 1)), ButtonStyle.SIMPLE, icon, Vec2(0.375,0.25), Vec2(0.50, 0.3125)))
	customButton:addEventCallbackExecute(func)
	customButton:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
	customButton:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
	customButton:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
	customButton:setEdgeColor(Vec4(0), Vec4(0))
	customButton:setEdgeHoverColor(Vec4(0), Vec4(0))
	customButton:setEdgeDownColor(Vec4(0), Vec4(0))
	customButton:setToolTip(language:getText(toolTipText))
	
	local label = createLabel( panel, startValue )
	
	panel:setToolTip(language:getText(toolTipText))
	
	toolTips[#toolTips + 1] = {panel=panel, text=toolTipText}
	
	return label
end

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
	print("Destroy stats menu")
end


local function destroyUpdate()
	print("Event destroy()")
	return false	 
end

function updateGameSpeed()
	start_time = Core.getGameTime()
	if Core.isInMultiplayer() then
		Core.getNetworkClient():writeSafe("CMD-GameSpeed:"..gameSpeed)
		comUnit = Core.getComUnit()
		comUnit:sendTo("stats","setBillboardInt","speed;"..tostring(gameSpeed))
	else
		Core.setTimeSpeed(gameSpeed)
	end
end

function restartMap()
	
	gameSpeed = 1.0
	updateGameSpeed()
	
	--script can only be restarted once
	if update~=destroyUpdate then
		update = destroyUpdate
		
		if comUnit then
			comUnit:setName("statsMenuDead")
			print("Stats menu set com unit name statsMenuDead ---- restartMap")
		end
		
		this:loadLuaScript(this:getCurrentScript():getFileName())
	end
end
function restartWave(wave)
	
end



local function numberToSmalString(num)
--	1				= 1			1	1
--	11				= 11		2	2
--	101				= 101		3	0
--	1001			= 1001		4	1
--	10001			= 10001		5	2
--	100001			= 100001	6	0
--	1000001			= 1000001	7	1
--	10000001		= 10000K	8	2	1	2
--	100000001		= 100000K	9	0	1	2
--	1000000001		= 1000.1M	10	1	2	5
--	10000000001		= 10000M	11	2	2	5
--	100000000001	= 100000M	12	0	2	5
--	1000000000001	= 1000.1B	13	1	3	8
--	10000000000001	= 10000B	14	2	3	8
--	100000000000001	= 100000B	15	0	3	8
	numberLetterTable = numberLetterTable or {"K","M","G","T","P","E","Z","Y",size=8}--?("H" == hella)
	local  digitCount = math.floor(math.log10(num)+1)
	local i = math.floor((digitCount-7)/3)+1
	if digitCount<8 then
		return string.format("%.0f",math.floor(num))
	elseif i<=numberLetterTable.size then
		if num<math.pow(10,6+i*3) then
			if i>1 and math.floor(math.log10(num)+1)%3==1 then
				return string.format("%.1f%s",num/math.pow(10,i*3),numberLetterTable[i])
			else
				return string.format("%.0f%s",num/math.pow(10,i*3),numberLetterTable[i])
			end
		end
		--end
	end
	local exp = digitCount-3
	return string.format("%.0fe+%.0f",math.floor(num/math.pow(10,exp)),exp)
end

local function getBillboardStr(billboardName)
	return numberToSmalString(statsBilboard:getDouble(billboardName))
end

local function updateGoldToolTip()

	local goldTextList = {	{text=language:getText("Total gold earned"),	billName="goldGainedTotal", color="40,255,40" }, 
							{text=language:getText("From kills"), 			billName="goldGainedFromKills", color="40,255,40" }, 
							{text=language:getText("From interest"), 		billName="goldGainedFromInterest", color="40,255,40" }, 
							{text=language:getText("From waves"), 			billName="goldGainedFromWaves", color="40,255,40" }, 
							{text=language:getText("From towers"), 			billName="goldGainedFromSupportTowers", color="40,255,40" }, 
							{text=language:getText("Spent in towers"), 		billName="goldInsertedToTowers", color="255,255,40" }, 
							{text=language:getText("Lost from selling"),	billName="goldLostFromSelling", color="255,40,40"},
							{text=language:getText("Iterest rate"),			billName="activeInterestrate", color="40,255,40"},
--							{text="towersBuilt",		billName="towersBuilt", color="40,255,40"},
--							{text="wallTowerBuilt",		billName="wallTowerBuilt", color="40,255,40"},
--							{text="towersSold",		billName="towersSold", color="40,255,40"},
--							{text="towersUpgraded",		billName="towersUpgraded", color="40,255,40"},
--							{text="towersSubUpgraded",		billName="towersSubUpgraded", color="40,255,40"},
--							{text="towersBoosted",		billName="towersBoosted", color="40,255,40"},
						}
	local toolPanel = Panel(PanelSize(Vec2(1)))
	toolPanel:setLayout(FlowLayout())
	local textPanel = toolPanel:add(Panel(PanelSize(Vec2(-1))))
	local goldPanel = toolPanel:add(Panel(PanelSize(Vec2(-1))))
	textPanel:setLayout(FallLayout())
	goldPanel:setLayout(FallLayout())
	local textSize = Vec2()
	local goldSize = Vec2()
	for i=1, #goldTextList do

		local textLabel = textPanel:add(Label( PanelSize(Vec2(1)), Text(goldTextList[i].text) ))
		textLabel:setTextHeight(Core.getScreenResolution().y * 0.0125)
		textLabel:setTextColor(Vec3(1))
		local pixelSize = textLabel:getTextSizeInPixel() + Vec2(4,2)
		textSize.x = math.max(textSize.x, pixelSize.x)

		
		local goldLabel
		if goldTextList[i].billName=="activeInterestrate" then
			local out = string.format("%.2f",statsBilboard:getDouble(goldTextList[i].billName)*100.0)
			goldLabel = goldPanel:add(Label( PanelSize(Vec2(1)), Text("<font color=rgb("..goldTextList[i].color..")>"..out.."%</font>") ))
		else
			goldLabel = goldPanel:add(Label( PanelSize(Vec2(1)), Text("<font color=rgb("..goldTextList[i].color..")>"..getBillboardStr(goldTextList[i].billName).."</font>") ))
		end
		goldLabel:setTextHeight(Core.getScreenResolution().y * 0.0125)
		local goldPixelSize = goldLabel:getTextSizeInPixel() + Vec2(4,2)
		goldSize.x = math.max(goldSize.x, goldPixelSize.x)
		
		
		--set panelSize
		local rowHeight = math.max( goldPixelSize.y, pixelSize.y )
		textSize.y = textSize.y + rowHeight
		goldSize.y = goldSize.y + rowHeight
		textLabel:setPanelSize(PanelSize(Vec2(pixelSize.x, rowHeight),PanelSizeType.Pixel))
		goldLabel:setPanelSize(PanelSize(Vec2(goldPixelSize.x, rowHeight),PanelSizeType.Pixel))
	end
	
	textPanel:setPanelSize(PanelSize(textSize,PanelSizeType.Pixel))
	goldPanel:setPanelSize(PanelSize(goldSize,PanelSizeType.Pixel))
	toolPanel:setPanelSize(PanelSize(Vec2(textSize.x+goldSize.x,math.max(textSize.y,goldSize.y)),PanelSizeType.Pixel))

	toolTips[toolTipsIndexGold].text = nil
	toolTips[toolTipsIndexGold].panel:setToolTip(toolPanel)
end
local function updateScoreToolTip()
	local scoreTextList = {	{text="Score from total tower value",	billName="totalTowerValue", 		color="40,255,40" }, 
							{text="Score from gold", 				billName="gold", 					color="40,255,40" }, 
							{text="Score from interest", 			billName="goldGainedFromInterest", 	color="40,255,40" }, 
							{text="Score from life", 				billName="life", 					color="40,255,40" }
						}
	if statsBilboard:getInt("scorePreviousBestGame")>=0 then
		scoreTextList[#scoreTextList+1] = {text="Score in your best game",		billName="scorePreviousBestGame", 	color="40,255,40" }
	end
	local toolPanel = Panel(PanelSize(Vec2(1)))
	toolPanel:setLayout(FlowLayout())
	local textPanel = toolPanel:add(Panel(PanelSize(Vec2(-1))))
	local scorePanel = toolPanel:add(Panel(PanelSize(Vec2(-1))))
	textPanel:setLayout(FallLayout())
	scorePanel:setLayout(FallLayout())
	local textSize = Vec2()
	local scoreSize = Vec2()
	for i=1, #scoreTextList do

		local textLabel = textPanel:add(Label( PanelSize(Vec2(1)), Text(scoreTextList[i].text) ))
		textLabel:setTextHeight(Core.getScreenResolution().y * 0.0125)
		textLabel:setTextColor(Vec3(1))
		local pixelSize = textLabel:getTextSizeInPixel() + Vec2(4,2)
		textSize.x = math.max(textSize.x, pixelSize.x)

		
		local scoreLabel
		if scoreTextList[i].billName=="life" then
			scoreLabel = scorePanel:add(Label( PanelSize(Vec2(1)), Text("<font color=rgb("..scoreTextList[i].color..")>"..tostring(statsBilboard:getInt(scoreTextList[i].billName)*100).."%</font>") ))
		elseif scoreTextList[i].billName=="scorePreviousBestGame" then
			local scoreDiff = statsBilboard:getInt("score")-statsBilboard:getInt(scoreTextList[i].billName)
			scoreLabel = scorePanel:add(Label( PanelSize(Vec2(1)), Text("<font color=rgb("..(scoreDiff>=0 and "40,255,40" or "255,40,40")..")>"..tostring(scoreDiff).."</font>") ))
		else
			scoreLabel = scorePanel:add(Label( PanelSize(Vec2(1)), Text("<font color=rgb("..scoreTextList[i].color..")>"..getBillboardStr(scoreTextList[i].billName).."</font>") ))
		end
		scoreLabel:setTextHeight(Core.getScreenResolution().y * 0.0125)
		local scorePixelSize = scoreLabel:getTextSizeInPixel() + Vec2(4,2)
		scoreSize.x = math.max(scoreSize.x, scorePixelSize.x)
		
		
		--set panelSize
		local rowHeight = math.max( scorePixelSize.y, pixelSize.y )
		textSize.y = textSize.y + rowHeight
		scoreSize.y = scoreSize.y + rowHeight
		textLabel:setPanelSize(PanelSize(Vec2(pixelSize.x, rowHeight),PanelSizeType.Pixel))
		scoreLabel:setPanelSize(PanelSize(Vec2(scorePixelSize.x, rowHeight),PanelSizeType.Pixel))
	end
	
	textPanel:setPanelSize(PanelSize(textSize,PanelSizeType.Pixel))
	scorePanel:setPanelSize(PanelSize(scoreSize,PanelSizeType.Pixel))
	toolPanel:setPanelSize(PanelSize(Vec2(textSize.x+scoreSize.x,math.max(textSize.y,scoreSize.y)),PanelSizeType.Pixel))

	toolTips[toolTipsIndexScore].text = nil
	toolTips[toolTipsIndexScore].panel:setToolTip(toolPanel)
	
	--UPDATE ICON
	updateScoreIcon()
end

function languageChanged()
	MenuButton:setText(language:getText(MenuButton:getTag()))
	
	for i=1, #toolTips do
		if toolTips[i].text then
			toolTips[i].panel:setToolTip( language:getText(toolTips[i].text))
		end
	end
	
	updateGoldToolTip()
	updateScoreToolTip()
end

function toogleSpeed()
	gameSpeed = gameSpeed<=1.5 and 3.0 or 1.0
	updateGameSpeed()
end

function create()
	--Protection in multiplayer environment where multiple instances of this script is loaded
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	if ( node == nil and this:getSceneName() ~= "Stats menu" ) or ( node and node:getClientId() ~= 0 ) then
		return false
	end
	
	local mapInfo = MapInfo.new()
	gameMode = mapInfo.getGameMode()
	start_time = Core.getGameTime()
	
	if this:getNodeType() == NodeId.playerNode then
		local menuNode = this:getRootNode():addChild(SceneNode())
		--camera = Camera()
		menuNode:setSceneName("Stats menu")
		menuNode:createWork()
				
		--Move this script to the camera node
		--this:removeScript(this:getCurrentScript():getName());
		menuNode:loadLuaScript(this:getCurrentScript():getFileName());
		menuNode:loadLuaScript("Menu/inGameChat.lua")
		return false
	else
		
		restartListener = Listener("Restart")
		restartListener:registerEvent("restart", restartMap)
		
		comUnit = Core.getComUnit()
		comUnit:setCanReceiveTargeted(true)
		comUnit:setName("statsMenu")
		print("Stats menu set com unit name statsMenu")
		
		
		keyBinds = Core.getBillboard("keyBind");
		keyBindSpeed = keyBinds:getKeyBind("Speed")
		
		
		settingsListener = Listener("Settings")
		settingsListener:registerEvent("LanguageChanged",languageChanged)
		
		local rootNode = this:getRootNode()
		local cameras = rootNode:findAllNodeByNameTowardsLeaf("MainCamera")
	
		if #cameras == 1 then
			local camera = ConvertToCamera(cameras[1])
			form = Form( camera, PanelSize(Vec2(-1,-1)), Alignment.TOP_LEFT)
			form:setName("StatsMenu form")
			form:setLayout(FallLayout(PanelSize(Vec2(0.01,0))))
			form:setRenderLevel(0)
			form:setVisible(true)
			local topPanel = MainMenuStyle.createTopMenu(form, PanelSize(Vec2(1,0.019),PanelSizeType.WindowPercentBasedOnX))
			topPanel:getPanelSize():setMinSize(PanelSize(Vec2(1,0.022),PanelSizeType.WindowPercent))
			topPanel:setPadding(BorderSize(Vec4(0.0015),true))
			
			--filler Panel
			local mainPanel = form:add(Panel(PanelSize(Vec2(-1))))
			
			MenuButton = MainMenuStyle.addTopMenuButton( topPanel, Vec2(4,1), language:getText("menu"))
			MenuButton:addEventCallbackExecute(toggleInGameMenu)
			MenuButton:setTag("menu")
			
			--create NPC panel
			npcPanel = NpcPanel.new(topPanel)
			topPanelRight = npcPanel.getTopPanelRight()
--			replaced by
--			topPanelRight = topPanel:add(Panel(PanelSize(Vec2(-1,-1))))
--			topPanelRight:setLayout(FlowLayout(Alignment.TOP_RIGHT))

			statsBilboard = Core.getBillboard("stats")
			statsBilboard:setPanel("MainPanel", mainPanel)
			local panel = nil
			
			--Wave
			wave = statsBilboard:getInt("wave")
			maxWave = statsBilboard:getInt("maxWave")
			waveLabel = createStat(Vec2(0.0,0.1885),Vec2(0.083984,0.231445), tostring(wave).."/"..maxWave, "current wave")
			--Game speed
			time = Core.getTimeSpeed()			
			timeLabel = createSpeedButton(Vec2(0.125, 0.25),Vec2(0.25,0.3125), tostring(time).."x", "game speed", toogleSpeed)
--			timeLabel = createStat(Vec2(0.125, 0.25),Vec2(0.25,0.3125), tostring(time).."x", "game speed")
--			--Score
--			to be used When implemented
			if gameMode~="rush" then
				score = statsBilboard:getInt("score")
				scoreLabel, scoreImage = createStat(Vec2(0.125,0.0),Vec2(0.25,0.0625), tostring(score), "score")
				scoreLabel:setToolTip(Text("Score"))
			else
				timerStr = "0s"
				scoreLabel, scoreImage = createStat(Vec2(0.625,0.5),Vec2(0.75,0.5625), "0s", "timer")
				updateScoreIcon()
				scoreLabel:setToolTip(Text("Timer"))
			end
			toolTipsIndexScore = #toolTips
--			--Enemies
--			numEnemies = statsBilboard:getInt("alive enemies")
--			numEnemiesLabel = createStat(Vec2(0.25,0.0),Vec2(0.375,0.0625), tostring(numEnemies), "enemies remaining")
			--money
			money = statsBilboard:getInt("gold")
			moneyLabel = createStat(Vec2(0.0, 0.0),Vec2(0.125, 0.0625), tostring(money), "money")

			toolTipsIndexGold = #toolTips
			
			
			--Life
			life = statsBilboard:getInt("life")
			lifeLabel = createStat(Vec2(0.375, 0.0),Vec2(0.5,0.0625), tostring(life), "life remaining")
			
			npcPanel.addTargetPanel()
			

			updateGoldToolTip()
			updateScoreToolTip()
		end
		
		comUnitTable = {}
		comUnitTable["waveInfo"] = npcPanel.handleWaveInfo
		comUnitTable["startWave"] = npcPanel.handleStartWave
		comUnitTable["setWaveNpcIndex"] = npcPanel.handleSetWaveNpcIndex
		
	end
	return true
end
function toggleInGameMenu(panel)
	comUnit:sendTo("InGameMenu", "toggleMenuVisibility", "")
end

function updateScoreIcon()
	local val = statsBilboard:getInt("hasMoreScoreThanPreviousBestGame")
	if val==-1 then
		scoreImage:setUvCoord(Vec2(0.25,0.5625),Vec2(0.375,0.625))
	elseif val==0 then
		scoreImage:setUvCoord(Vec2(0.25,0.625),Vec2(0.375,0.6875))
	elseif val==1 then
		scoreImage:setUvCoord(Vec2(0.25,0.6875),Vec2(0.375,0.75))
	end
end

function update()
	--Handle communication
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message]~=nil then
			comUnitTable[msg.message](msg.parameter)
		end
	end	
	
	statsBilboard = Core.getBillboard("stats")
	if wave ~= statsBilboard:getInt("wave") or maxWave ~= statsBilboard:getInt("maxWave") then
		wave = statsBilboard:getInt("wave")
		maxWave = statsBilboard:getInt("maxWave")
		waveLabel:setText(tostring(wave).."/"..maxWave)
	end
--	to be used When implemented
	if gameMode~="rush" then
		if score ~= statsBilboard:getDouble("score") then
			score = statsBilboard:getDouble("score")
			scoreLabel:setText(numberToSmalString(score))
			updateScoreToolTip()
		end
	else
		if timerStr ~= statsBilboard:getString("timerStr") then
			timerStr = statsBilboard:getString("timerStr")
			scoreLabel:setText(timerStr)
			updateScoreToolTip()
		end
	end
	
	
	if keyBindSpeed:getPressed() then
		toogleSpeed()
	end
	--Achievements
	if gameSpeed==3.0 and Core.getGameTime()-start_time>300.0 and Core.isInMultiplayer()==false then
		start_time = Core.getGameTime()
		comUnit:sendTo("SteamAchievement","Speed","")
	end
	
--	if numEnemies ~= statsBilboard:getInt("alive enemies") then
--		numEnemies = statsBilboard:getInt("alive enemies")
--		numEnemiesLabel:setText(tostring(numEnemies))
--	end
	if life ~= statsBilboard:getInt("life") then
		life = statsBilboard:getInt("life")
		lifeLabel:setText(tostring(life))
	end
	if time ~= Core.getTimeSpeed() or (Core.isInMultiplayer() and setSpeed~=statsBilboard:getInt("speed")) then
		time = Core.getTimeSpeed()
		if Core.isInMultiplayer()==false then
			timeLabel:setText(tostring(time).."x")
		else
			setSpeed = math.max(1,statsBilboard:getInt("speed"))
			timeLabel:setText(tostring(time).."x("..setSpeed.."x)")
		end
	end
	if money ~= getBillboardStr("gold") then
		money = getBillboardStr("gold")
		moneyLabel:setText(numberToSmalString(math.max(0,tonumber(money))))
		updateGoldToolTip()
		updateScoreToolTip()--Building towers will not change the score directly just shift it
	end

	form:update();
	
	
	npcPanel.update()
	
	return true;
end