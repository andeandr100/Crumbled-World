require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/npcPanel.lua")

--this = SceneNode()

local toolTips = {}
local gameMode = ""

function createStat(minUvCoord, maxUvCoor, startValue, toolTipText)
	
	local panel = topPanelRight:add(Panel(PanelSize(Vec2(1,-1), Vec2(4,1))))
	
	local image = panel:add(Image(PanelSize(Vec2(1,-1),Vec2(1, 1)), Text("icon_table.tga")));
	image:setUvCoord(minUvCoord,maxUvCoor);
	image:setCanHandleInput(false)
	
	local label = panel:add(Label(PanelSize(Vec2(1,-1),Vec2(3,1)),Text(startValue)));
	label:setTextColor(Vec3(1));
	label:setBackground(Sprite(Vec4(0,0,0,0.5)));
	label:setTextAlignment(Alignment.MIDDLE_LEFT)
	label:setPadding(BorderSize(Vec4(0.001)));
	label:setBorder(Border(BorderSize(Vec4(0.001)), Vec4(0,0,0,1)));
	label:setMargin(BorderSize(Vec4(0.001)));
	label:setCanHandleInput(false)
	
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

function restartMap()
	update = destroyUpdate
	
	if comUnit then
		comUnit:setName("statsMenuDead")
		print("Stats menu set com unit name statsMenuDead ---- restartMap")
	end
	
	this:loadLuaScript(this:getCurrentScript():getFileName());
end
function restartWave(wave)
end

function languageChanged()
	MenuButton:setText(language:getText(MenuButton:getTag()))
	
	for i=1, #toolTips do
		toolTips[i].panel:setToolTip( language:getText(toolTips[i].text))
	end
end

function create()
	--Protection in multiplayer environment where multiple instances of this script is loaded
	local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
	if ( node == nil and this:getSceneName() ~= "Stats menu" ) or ( node and node:getClientId() ~= 0 ) then
		return false
	end
	
	local mapInfo = MapInfo.new()
	gameMode = mapInfo.getGameMode()
	
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
			timeLabel = createStat(Vec2(0.125, 0.25),Vec2(0.25,0.3125), tostring(time).."x", "game speed")
--			--Score
--			to be used When implemented
			if gameMode~="rush" then
				score = statsBilboard:getInt("score")
				scoreLabel = createStat(Vec2(0.125,0.0),Vec2(0.25,0.0625), tostring(score), "score")
				scoreLabel:setToolTip(Text("Score"))
			else
				timerStr = "0s"
				scoreLabel = createStat(Vec2(0.625,0.5),Vec2(0.75,0.5625), "0s", "timer")
				scoreLabel:setToolTip(Text("Timer"))
			end
--			--Enemies
--			numEnemies = statsBilboard:getInt("alive enemies")
--			numEnemiesLabel = createStat(Vec2(0.25,0.0),Vec2(0.375,0.0625), tostring(numEnemies), "enemies remaining")
			--money
			money = statsBilboard:getInt("gold")
			moneyLabel = createStat(Vec2(0.0, 0.0),Vec2(0.125, 0.0625), tostring(money), "money")
			
			--Life
			life = statsBilboard:getInt("life")
			lifeLabel = createStat(Vec2(0.375, 0.0),Vec2(0.5,0.0625), tostring(life), "life remaining")
			
			npcPanel.addTargetPanel()
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
		end
	else
		if timerStr ~= statsBilboard:getString("timerStr") then
			timerStr = statsBilboard:getString("timerStr")
			scoreLabel:setText(timerStr)
		end
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
	if money ~= statsBilboard:getDouble("gold") then
		money = statsBilboard:getDouble("gold")
		moneyLabel:setText(numberToSmalString(math.max(0,money)))
		for i=1, #toolTips do
			toolTips[i].text =	Text("goldGainedTotal: "..tostring(statsBilboard:getDouble("goldGainedTotal"))..
									"\ngoldGainedTotal: "..tostring(statsBilboard:getDouble("goldGainedTotal"))..
									"\ngoldGainedFromKills: "..tostring(statsBilboard:getDouble("goldGainedFromKills"))..
									"\ngoldGainedFromInterest: "..tostring(statsBilboard:getDouble("goldGainedFromInterest"))..
									"\ngoldGainedFromWaves: "..tostring(statsBilboard:getDouble("goldGainedFromWaves"))..
									"\ngoldGainedFromSupportTowers: "..tostring(statsBilboard:getDouble("goldGainedFromSupportTowers"))..
									"\ngoldLostFromSelling: "..tostring(statsBilboard:getDouble("goldLostFromSelling")))
			toolTips[i].panel:setToolTip(toolTips[i].text)
		end
	end

	form:update();
	
	
	npcPanel.update()
	
	return true;
end