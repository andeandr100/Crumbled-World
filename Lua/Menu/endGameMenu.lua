require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/graphDrawer.lua")
require("Game/mapInfo.lua")
require("Game/campaignData.lua")
require("Game/soundManager.lua")
require("Game/scoreCalculater.lua")
--this = SceneNode()

local data
local menuItems = {}
local index = 1
local indexMax = 0
local initEventDone = false
local indexSpeed = 1
local PLAYTIME = 1.5
local SCOREPERLIFE = 100
local bilboardStats = Core.getBillboard("stats")
local graph
local input = Core.getInput()
local comUnitTable = {}
local mapInfo = MapInfo.new()
local isVictory

local soundManager = SoundManager.new(nil)

local campaignData = CampaignData.new()
local files = campaignData.getMaps()


-- function:	destroy
-- purpose:		called on the destruction of this script
function destroy()
	if comUnit then
		comUnit:sendTo("SteamStats","SaveStats","")
	end
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end
-- function:	restartMap
-- purpose:		called when restart button is pressed (only available on losing the game)
function restartMap()
	restartListener:pushEvent("restart")
	update = endScript
end
-- function:	restartWave
-- purpose:		called whne restart wave is clicked (only available on losing the game)
function restartWave()
	restartWaveListener:pushEvent("EventBaseRestartWave")
	comUnit:sendTo("EventManager","EventBaseRestartWave","")
	update = endScript
end
-- function:	waveRetarted
-- purpose:		called when another script has restarted a wave
function waveRestartedElsewhere()
	update = endScript
end
local function getMapIndex(filePath)
	for i=1, #files do	
		local file = files[i].file
		if file:isFile() and file:getPath()==filePath then
			return i
		end
	end
	return 0
end
function isNextCampaignMapAvailable()
	local files = campaignData.getMaps()
	return #files>=mapInfo.getMapNumber()+1
end
-- function:	startNextMap
-- purpose:		will leave game, launch loading screen and throw you into the next map for the campaign (only available for campaign maps)
function startNextMap()
	if isNextCampaignMapAvailable() then
		local files = campaignData.getMaps()
		local mNum = mapInfo.getMapNumber()+1
		local mapFile = files[mNum].file
			
		if mapFile:isFile() then
			--
			local mapInformation = MapInformation.getMapInfoFromFileName(mapFile:getName(), mapFile:getPath())
			if mapInformation then
				mapInfo.setMapNumber(mNum)
				mapInfo.setMapName(mapFile:getName())
				mapInfo.setSead(files[mNum].sead)
			
				mapInfo.setIsCartMap(mapInformation.gameMode=="Cart")
				mapInfo.setAddPerLevel(mapInformation.difficultyIncreaseMax)
				mapInfo.setDifficultyBase(mapInformation.difficultyBase)
				mapInfo.setWaveCount(mapInformation.waveCount)
								mapInfo.setMapSize(mapInformation.mapSize)
				mapInfo.setLevel(1)
				--changing default selected map
				menuPrevSelect = Config("menuPrevSelect")
				menuPrevSelect:get("campaign"):get("selectedMap"):setString(files[mNum].file:getPath())
				menuPrevSelect:save()
				--
				local worker = Worker("Menu/loadingScreen.lua", true)
				worker:start()
				Core.startNextMap(files[mNum].file:getPath())
			else
				LOG("ERROR no mapInformation")
				buttonRow:removePanel(nextMapButton)
			end
		else
			LOG("file not available")
			buttonRow:removePanel(nextMapButton)
		end
	end
end
function addheader(panel, text)
	local background = panel:add(Panel(PanelSize(Vec2(-1,0.025))))
	background:setBackground(Sprite(Vec4(1,1,1,0.15)))
	background:setBackground(Gradient(	Vec4(1,0.5,0,0.2),		Vec4(1,0.75,0.45,0.0),
										Vec4(1,0.6,0.2,0.2),	Vec4(1,0.90,0.60,0.0)))
	local textLabel = background:add(Label( PanelSize(Vec2(-0.5,-1)), Text(text), Vec3(1,0.7,0) ))
	--
	local label = background:add( Label(PanelSize(Vec2(-1)), Text("")) )
	label:setTextColor(Vec3(1))
	return label
end
function addLine(panel,index,text)
	local background = panel:add(Panel(PanelSize(Vec2(-1,0.02))))
	if index%2==1 then
		--background:setBackground(Sprite(index%2==1 and Vec4(1,1,1,0.1) or Vec4(0,0,0,0.1)))
		background:setBackground(Gradient(	Vec4(1,1,1,0.1),	Vec4(1,1,1,0.0),
											Vec4(1,1,1,0.1),	Vec4(1,1,1,0.0)))
	end
	--
	local textLabel = background:add(Label( PanelSize(Vec2(-0.5,-1)), Text(text) ))
	textLabel:setTextColor(Vec3(1))
	--
	local label = background:add( Label(PanelSize(Vec2(-1)), Text("")) )
	label:setTextColor(Vec3(1))
	return label
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
function setStatsLayout(panel)
	menuItems[1] = { label=addheader(panel,"Gold"), key=1}
	menuItems[2] = { label=addLine(panel,2,language:getText("Total gold earned")), key=2}
	menuItems[3] = { label=addLine(panel,4,language:getText("From kills")), key=3}
	menuItems[4] = { label=addLine(panel,5,language:getText("From waves")), key=4}
	menuItems[5] = { label=addLine(panel,6,language:getText("From towers")), key=5}
	menuItems[6] = { label=addLine(panel,7,language:getText("Spent in towers")), key=6}
	menuItems[7] = { label=addLine(panel,8,language:getText("Lost from selling")), key=7}
	--
	menuItems[8] = { label=addheader(panel,"Score"), key=8}
	menuItems[9] = { label=addLine(panel,9,"From gold:")}
	menuItems[10] = { label=addLine(panel,10,"Total tower value:"), key=9}
	menuItems[11] = { label=addLine(panel,11,"From life left:"), key=10, multiplyer=SCOREPERLIFE}
	--
	addheader(panel,"Towers")
	menuItems[12] = { label=addLine(panel,10,"Built:"), key=11}
	menuItems[13] = { label=addLine(panel,11,"walls:"), key=12}
	menuItems[14] = { label=addLine(panel,12,"sold:"), key=13}
	menuItems[15] = { label=addLine(panel,13,"Upgrades:"), key=14}
	menuItems[16] = { label=addLine(panel,14,"Sub upgrades:"), key=15}
	menuItems[17] = { label=addLine(panel,15,"Boosted:"), key=16}
	--
	addheader(panel,"Enemies")
	menuItems[18] = { label=addLine(panel,16,"Spawned:"), key=17}
	menuItems[19] = { label=addLine(panel,17,"Killed:"), key=18}
	menuItems[20] = { label=addLine(panel,18,"Damage:"), key=19}
end
function setGraphLayout()
	
end
function initiate()
	local d1 = bilboardStats:getTable("scoreHistory")
	data = d1
	local endWaveData = data[#data]
	local maxScore = endWaveData[#endWaveData][9]
	local scoreItem = ScoreCalculater.getScoreItemOnScore(maxScore)
	local crystalReward = (mapInfo.getReward()<=1 and 1 or mapInfo.getReward()) + math.max(scoreItem.index-1,0)
	--
	comUnit:sendTo("stats","setGameEnded",true)
	--
	
	index = 1
	indexMax = #data+0.9999					--+0.9999 because it is not real indexes 20 wave games have 20.96 indexes
	indexSpeed = indexMax/PLAYTIME+1
	
	restartListener = Listener("Restart")
	restartListener:registerEvent("restart", waveRestartedElsewhere)
	restartWaveListener = Listener("RestartWave")
	restartWaveListener:registerEvent("restartWave", waveRestartedElsewhere)
	
	local rootNode = this:getRootNode();
	local camera = rootNode:findNodeByName("MainCamera");

	local camera = ConvertToCamera(camera);
	form = Form( camera, PanelSize(Vec2(0.8,0.9), Vec2(1,1)), Alignment.MIDDLE_CENTER)
	form:setName("EndGameMenu form")
	form:getPanelSize():setFitChildren(false, true)
	form:setLayout(FallLayout( Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
	form:setRenderLevel(11)
	form:setVisible(true)
	form:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
	form:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
	--
	--	Top image
	--
	if Core.getCurrentLuaScript():getName()=="endGameMenuVictory" then
		topImage = form:add(Image(PanelSize(Vec2(-1,0.20), Vec2(8,1)), "victory"))
		if mapInfo.isCampaign() then
			campaignData.addCrystal( crystalReward )
			campaignData.setLevelCompleted(mapInfo.getMapNumber(),scoreItem.index,mapInfo.getGameMode())
		end
		isVictory = true
	else
		topImage = form:add(Image(PanelSize(Vec2(-1,1), Vec2(8,1)), "defeated"))
		isVictory = false
	end
	MainMenuStyle.createBreakLine(form)
	--
	--
	--
	if isVictory then
		local panel1 = form:add(Panel(PanelSize(Vec2(-0.9,0.025))))
		panel1:setBackground(Sprite(Vec4(1,1,1,0.15)))
		panel1:setBackground(Gradient(	Vec4(1,0.5,0,0.2),		Vec4(1,0.75,0.45,0.0),
												Vec4(1,0.6,0.2,0.2),	Vec4(1,0.90,0.60,0.0)))
		local totalScorePanel = panel1:add(Panel(PanelSize(Vec2(-0.4,-1))))
		local textLabel1 = totalScorePanel:add(Label( PanelSize(Vec2(-0.5,-1)), "Score:", Vec3(1,0.7,0) ))
		textLabel1:setTextColor(Vec3(1))
		local label1 = totalScorePanel:add( Label(PanelSize(Vec2(-0.5,-1)), tostring(maxScore)) )
		label1:setTextColor(Vec3(1))
		if scoreItem then
			local icon = Image(PanelSize(Vec2(-1), Vec2(2,1)), Text("icon_table.tga") )
			icon:setUvCoord(scoreItem.minPos,scoreItem.maxPos)
			totalScorePanel:add(icon)
		end
		local crystalPanel = panel1:add(Panel(PanelSize(Vec2(-1,-1))))
		local crystalPanelEmpty = crystalPanel:add(Panel(PanelSize(Vec2(-1,-1),Vec2(1,1))))
		local crystalPanelIcon = crystalPanel:add(Panel(PanelSize(Vec2(-1),Vec2(1,1.1))))
		local crystalPanelText = crystalPanel:add(Panel(PanelSize(Vec2(-1))))
		local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") )
		icon:setUvCoord(Vec2(0.5,0.375),Vec2(0.625,0.4375))
		crystalPanelIcon:add(icon)
		local label2 = crystalPanelText:add( Label(PanelSize(Vec2(-0.5,-1)), "+"..tostring(crystalReward)) )
		label2:setTextColor(Vec3(1))
		--
		MainMenuStyle.createBreakLine(form)
		if scoreItem.index==5 then
			soundManager.play("victory1-4", 1.0, false)
		else
			soundManager.play("victory5", 1.0, false)
		end
	else
		soundManager.play("defeat", 1.0, false)
	end
	--
	--	Section with all stats
	--
	
	local baseStatsPanel = form:add(Panel(PanelSize(Vec2(-0.9,-1), Vec2(5,3.5))))
	statsPanel = baseStatsPanel:add(Panel(PanelSize(Vec2(-0.4,-1))))
	graphPanel = baseStatsPanel:add(Panel(PanelSize(Vec2(-1,-1))))
	statsPanel:setEnableYScroll()
	
	setStatsLayout(statsPanel,true)
	--setGraphLayout(graphPanel)
	graph = #data>1 and GraphDrawer.new(graphPanel, bilboardStats:getInt("life"), SCOREPERLIFE, ScoreCalculater.getScoreLimits()) or nil
	
	--
	--	Bottom section with button options
	--
	MainMenuStyle.createBreakLine(form)
	
	buttonRow = form:add(Panel(PanelSize(Vec2(-0.9, 1),Vec2(20,1))))
	buttonRow:setLayout(FlowLayout(PanelSize(Vec2(0.001,0))))
	
	form:add(Panel(PanelSize(Vec2(-0.9,0.002))))
	
	run = true
	
	--Acievements
	if isVictory then
		manageVictoryAchievement(scoreItem)
	end
	
	--
	--BUTTONS
	--
	local buttonCount = 1
	if mapInfo.isCampaign() and isVictory then
		buttonCount = buttonCount + 1
	end
	if not isVictory then
		buttonCount = buttonCount + 1
		if mapInfo.isRestartWaveEnabled() then
			buttonCount = buttonCount + 1
		end
	end
	local count = -1
	local function calculateButtonSize()
		count = count + 1
		return Vec2( -1/(buttonCount-count), -1)
	end
	--
	--
	if mapInfo.isCampaign() and isVictory then
		nextMapButton = buttonRow:add( MainMenuStyle.createButton( calculateButtonSize(), nil, "NextMap"))
		nextMapButton:addEventCallbackExecute(startNextMap)
	end
	--
	if not isVictory then
		if mapInfo.isRestartWaveEnabled() then
			restartWaveButton = buttonRow:add( MainMenuStyle.createButton( calculateButtonSize(), nil, language:getText("restart last wave")))
			restartWaveButton:addEventCallbackExecute(restartWave)
		end
		if Core.isInMultiplayer()==false then
			restartMapButton = buttonRow:add( MainMenuStyle.createButton( calculateButtonSize(), nil, language:getText("restart map")))
			restartMapButton:addEventCallbackExecute(restartMap)
		end
	end
	--
	quitToMenuButton = buttonRow:add( MainMenuStyle.createButton( Vec2(-1,-1), nil, language:getText("quit to menu")))
	quitToMenuButton:addEventCallbackExecute(quitToMainMenu)
	--
	
end
-- function:	create
-- purpose:		initiates the script
function create()
	comUnit = Core.getComUnit()
	comUnit:setCanReceiveTargeted(false)
	comUnit:setCanReceiveBroadcast(false)
	return true
end
-- function:	quitToMainMenu
-- purpose:		launches the loading screen and leaves the game
function quitToMainMenu(panel)
	run = false
	local worker = Worker("Menu/loadingScreen.lua", true)
	worker:start()
	Core.quitToMainMenu()
end
function getKill(index)
	local wave = math.floor(index)
	local per = math.clamp(index-wave,0.0,1.0)
	local max = #data[wave]
	
	local kill = math.clamp( math.floor(max*per+0.5), 0, max)
	if data[wave][kill]==nil then
		local d0 = #data[wave]
		local d1 = data[wave]
		abort()
	end
	return data[wave][kill]
end
function updateAllMenuLabels()
	for i=1, #menuItems do
		local kill = getKill(index)
		if menuItems[i].key then
			menuItems[i].label:setText( tostring(math.floor( (kill[menuItems[i].key] or 0)*(menuItems[i].multiplyer or 1) )) )
		else
			local value = kill[1] + kill[4]
			menuItems[i].label:setText( tostring(math.floor( value )) )
		end
	end
end
local function waveIndexHasChanged(waveIndex)
	index = waveIndex
	updateAllMenuLabels()
end
function manageVictoryAchievement(scoreItem)
	--game modes
	if scoreItem.name=="dimond" and mapInfo.getGameMode()=="default" then
		comUnit:sendTo("SteamAchievement","BeatDefaultInsane","")
	end
	if scoreItem.name=="dimond"and mapInfo.getGameMode()=="training" then
		comUnit:sendTo("SteamAchievement","BeatTrainingInsane","")
	end
	if scoreItem.name=="dimond" and mapInfo.getGameMode()=="leveler" then
		comUnit:sendTo("SteamAchievement","BeatLevelerInsane","")
	end
	--Flawless game
	if scoreItem.name=="dimond" then
		comUnit:sendTo("SteamStats","MaxLifeAtEndOfMapOnInsane",bilboardStats:getInt("life"))
	end
	--over powered game (beat insane and not using any restarts
	if scoreItem.name=="dimond" and mapInfo.getGameMode()=="default" and bilboardStats:getBool("waveRestarted") then
	end
	if scoreItem.name=="gold" then
		print("Map: "..mapInfo.getMapName())
		if mapInfo.getMapName()=="Beginning" then
			comUnit:sendTo("SteamAchievement","MapBeginning","")
		elseif mapInfo.getMapName()=="Blocked path" then
			comUnit:sendTo("SteamAchievement","MapBlockedPath","")
		elseif mapInfo.getMapName()=="Bridges" then
			comUnit:sendTo("SteamAchievement","MapBridges","")
		elseif mapInfo.getMapName()=="Crossroad" then
			comUnit:sendTo("SteamAchievement","MapCrossroad","")
		elseif mapInfo.getMapName()=="Divided" then
			comUnit:sendTo("SteamAchievement","MapDivided","")
		elseif mapInfo.getMapName()=="Dock" then
			comUnit:sendTo("SteamAchievement","MapDock","")
		elseif mapInfo.getMapName()=="Expansion" then
			comUnit:sendTo("SteamAchievement","MapExpansion","")
		elseif mapInfo.getMapName()=="Intrusion" then
			comUnit:sendTo("SteamAchievement","MapIntrusion","")
		elseif mapInfo.getMapName()=="Long haul" then
			comUnit:sendTo("SteamAchievement","MapLongHaul","")
		elseif mapInfo.getMapName()=="Mine" then
			comUnit:sendTo("SteamAchievement","MapMine","")
		elseif mapInfo.getMapName()=="Nature" then
			comUnit:sendTo("SteamAchievement","MapNature","")
		elseif mapInfo.getMapName()=="Paths" then
			comUnit:sendTo("SteamAchievement","MapPaths","")
		elseif mapInfo.getMapName()=="Plaza" then
			comUnit:sendTo("SteamAchievement","MapPlaza","")
		elseif mapInfo.getMapName()=="Repair station" then
			comUnit:sendTo("SteamAchievement","MapRepairStation","")
		elseif mapInfo.getMapName()=="Rifted" then
			comUnit:sendTo("SteamAchievement","MapRifted","")
		elseif mapInfo.getMapName()=="Spiral" then
			comUnit:sendTo("SteamAchievement","MapSpiral","")
		elseif mapInfo.getMapName()=="Stockpile" then
			comUnit:sendTo("SteamAchievement","MapStockpile","")
		elseif mapInfo.getMapName()=="The end" then
			comUnit:sendTo("SteamAchievement","MapTheEnd","")
		elseif mapInfo.getMapName()=="The line" then
			comUnit:sendTo("SteamAchievement","MapTheLine","")
		elseif mapInfo.getMapName()=="Town" then
			comUnit:sendTo("SteamAchievement","MapTown","")
		elseif mapInfo.getMapName()=="Train station" then
			comUnit:sendTo("SteamAchievement","MapTrainStation","")
		elseif mapInfo.getMapName()=="Square" then
			comUnit:sendTo("SteamAchievement","MapSquare","")
		elseif mapInfo.getMapName()=="Co-op Crossfire" then
			comUnit:sendTo("SteamAchievement","MapCo-opCrossfire","")
		elseif mapInfo.getMapName()=="Co-op Hub world" then
			comUnit:sendTo("SteamAchievement","	MapCo-opHubWorld","")
		elseif mapInfo.getMapName()=="Co-op Outpost" then
			comUnit:sendTo("SteamAchievement","MapCo-opOutpost","")
		elseif mapInfo.getMapName()=="Co-op Survival beginnings" then
			comUnit:sendTo("SteamAchievement","MapCo-opSurvivalBeginnings","")
		elseif mapInfo.getMapName()=="Co-op Survival frontline" then
			comUnit:sendTo("SteamAchievement","MapCo-opSurvivalFrontline","")
		elseif mapInfo.getMapName()=="Co-op The road" then
			comUnit:sendTo("SteamAchievement","MapCo-opTheRoad","")
		elseif mapInfo.getMapName()=="Co-op The tiny road" then
			comUnit:sendTo("SteamAchievement","MapCo-opTheTinyRoad","")
		elseif mapInfo.getMapName()=="Co-op Triworld" then
			comUnit:sendTo("SteamAchievement","MapCo-opTriworld","")
		elseif mapInfo.getMapName()=="Broken mine" then
			comUnit:sendTo("SteamAchievement","MapBrokenMine","")
		elseif mapInfo.getMapName()=="Dump station" then
			comUnit:sendTo("SteamAchievement","MapDumpStation","")
		elseif mapInfo.getMapName()=="Desperado" then
			comUnit:sendTo("SteamAchievement","MapDesperado","")
		elseif mapInfo.getMapName()=="West river" then
			comUnit:sendTo("SteamAchievement","MapWestRiver","")
		end
	end
	comUnit:sendTo("SteamStats","SaveStats","")
end
-- function:	update
-- purpose:		updates the script every frame
function endScript()
	comUnit:sendTo("stats","setGameEnded",false)
	return false
end
function update()
	if data then
		if initEventDone==false and index~=indexMax then
			index = math.min(index+(indexSpeed*Core.getRealDeltaTime()),indexMax)
			if graph then
				graph.setDisplayedIndex(index)
			end
			updateAllMenuLabels()
		elseif graph and input:getMouseHeld(MouseKey.left) and graph.isMouseInsidePanel() then
			if initEventDone==false then
				initEventDone = true
				graph.setCallbackOnDisplayIndexChange(waveIndexHasChanged)
			end
			graph.mouseClicked()
		end
		form:update()
		return run
	elseif bilboardStats:exist("scoreHistory") then
		initiate()
	end
	return true
end