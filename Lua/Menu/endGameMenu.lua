require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/graphDrawer.lua")
require("Game/mapInfo.lua")
require("Game/campaignData.lua")
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

local campaignData = CampaignData.new()
local files = campaignData.getMaps()
local currentMapData = files[mapInfo.getMapNumber()]
local diffPerLevelBase = math.floor( ((currentMapData.maxScore-currentMapData.minScore)*0.33)/1000 )
local diffPerLevel = diffPerLevelBase*1000
local scoreLimits = {
	{score=0, 										index=1, minPos=Vec2(0.25,0.75),		maxPos=Vec2(0.5,0.8125), 	color=Vec3(0.65,0.65,0.65)},
	{score=currentMapData.minScore, 				index=2, minPos=Vec2(0.0,0.5625),	maxPos=Vec2(0.25,0.625), 	color=Vec3(0.86,0.63,0.38)},
	{score=currentMapData.maxScore-diffPerLevel,	index=3, minPos=Vec2(0.0,0.625),		maxPos=Vec2(0.25,0.6875), 	color=Vec3(0.64,0.70,0.73)},
	{score=currentMapData.maxScore,					index=4, minPos=Vec2(0.0,0.6875),	maxPos=Vec2(0.25,0.75), 	color=Vec3(0.93,0.73,0.13)},
	{score=currentMapData.maxScore+diffPerLevel,	index=5, minPos=Vec2(0.0,0.75),		maxPos=Vec2(0.25,0.8125), 	color=Vec3(0.5,0.92,0.92)}
}

-- function:	destroy
-- purpose:		called on the destruction of this script
function destroy()
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
end
-- function:	restartWave
-- purpose:		called whne restart wave is clicked (only available on losing the game)
function restartWave()
	restartWaveListener:pushEvent("EventBaseRestartWave")
	form:setVisible(false)
	comUnit:sendTo("EventManager","EventBaseRestartWave","")
end
-- function:	waveRetarted
-- purpose:		called when another script has restarted a wave
function waveRestarted()
	form:setVisible(false)
end

local function getScoreItem(score)
	for i=#scoreLimits, 1, -1 do
		if score>=scoreLimits[i].score then
			return scoreLimits[i]
		end
	end
	return nil
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
	menuItems[4] = { label=addLine(panel,5,language:getText("From interest")), key=4}
	menuItems[5] = { label=addLine(panel,6,language:getText("From waves")), key=5}
	menuItems[6] = { label=addLine(panel,7,language:getText("From towers")), key=6}
	menuItems[7] = { label=addLine(panel,8,language:getText("Spent in towers")), key=7}
	menuItems[8] = { label=addLine(panel,9,language:getText("Lost from selling")), key=8}
	--
	menuItems[9] = { label=addheader(panel,"Score"), key=9}
	menuItems[10] = { label=addLine(panel,9,"From gold:")}
	menuItems[11] = { label=addLine(panel,10,"Total tower value:"), key=10}
	menuItems[12] = { label=addLine(panel,11,"From life left:"), key=11, multiplyer=SCOREPERLIFE}
	--
	addheader(panel,"Towers")
	menuItems[13] = { label=addLine(panel,10,"Built:"), key=12}
	menuItems[14] = { label=addLine(panel,11,"walls:"), key=13}
	menuItems[15] = { label=addLine(panel,12,"sold:"), key=14}
	menuItems[16] = { label=addLine(panel,13,"Upgrades:"), key=15}
	menuItems[17] = { label=addLine(panel,14,"Sub upgrades:"), key=16}
	menuItems[18] = { label=addLine(panel,15,"Boosted:"), key=17}
	--
	addheader(panel,"Enemies")
	menuItems[19] = { label=addLine(panel,16,"Spawned:"), key=18}
	menuItems[20] = { label=addLine(panel,17,"Killed:"), key=19}
	menuItems[21] = { label=addLine(panel,18,"Damage:"), key=20}
end
function setGraphLayout()
	
end
function initiate()
	local d1 = bilboardStats:getTable("scoreHistory")
	data = d1
	local endWaveData = data[#data]
	local maxScore = endWaveData[#endWaveData][9]
	local scoreItem = getScoreItem(maxScore)
	local crystalReward = (mapInfo.getReward()<=1 and 1 or mapInfo.getReward()) + math.max(scoreItem.index-1,0)
	
	index = 1
	indexMax = #data+0.9999					--+0.9999 because it is not real indexes 20 wave games have 20.96 indexes
	indexSpeed = indexMax/PLAYTIME+1
	
	restartListener = Listener("Restart")
	restartWaveListener = Listener("EventBaseRestartWave")
	
	restartWaveListener = Listener("RestartWave")
	restartWaveListener:registerEvent("restartWave", waveRestarted)
	
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
	graph = #data>1 and GraphDrawer.new(graphPanel, bilboardStats:getInt("life"), SCOREPERLIFE, scoreLimits) or nil
	
	--
	--	Bottom section with button options
	--
	MainMenuStyle.createBreakLine(form)
	
	buttonRow = form:add(Panel(PanelSize(Vec2(-0.9, 1),Vec2(20,1))))
	buttonRow:setLayout(FlowLayout(PanelSize(Vec2(0.001,0))))
	
	form:add(Panel(PanelSize(Vec2(-0.9,0.002))))
	
	run = true
	
	--BUTTONS
	if mapInfo.isCampaign() and isVictory then
		nextMapButton = buttonRow:add( MainMenuStyle.createButton( Vec2(-0.5,-1), nil, "NextMap"))
		nextMapButton:addEventCallbackExecute(startNextMap)
	end
	--
	if not isVictory then
		restartWaveButton = buttonRow:add( MainMenuStyle.createButton( Vec2(-0.5,-1), nil, language:getText("revert wave")))
		restartWaveButton:addEventCallbackExecute(restartWave)
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
-- function:	update
-- purpose:		updates the script every frame
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