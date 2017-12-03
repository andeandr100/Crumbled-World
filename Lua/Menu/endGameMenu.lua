require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/graphDrawer.lua")
require("Game/mapInfo.lua")
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
-- function:	victory
-- purpose:		called on victory, will show the victory screen
function victory()
	victoryImage:setVisible(true)
	--restartWaveButton:setEnabled(false)
	form:setVisible(true)
	comUnit:sendTo("InGameMenu","hide","")
end
-- function:	defeated
-- purpose:		called on defeat, will show the defeat screen
function defeated()
	
--	if not Core.isInMultiplayer() then
--		continueButton:setText("Restart")
--	end
	
	defeatedImage:setVisible(true)
	--restartWaveButton:setEnabled(true)
	form:setVisible(true)
	comUnit:sendTo("InGameMenu","hide","")
end
-- function:	startNextMap
-- purpose:		will leave game, launch loading screen and throw you into the next map for the campaign (only available for campaign maps)
function startNextMap()
	local worker = Worker("Menu/loadingScreen.lua", true)
	worker:start()
	Core.startNextMap(selectedFile)
end
function addheader(panel, text)
	local background = panel:add(Panel(PanelSize(Vec2(-1,0.025))))
	background:setBackground(Sprite(Vec4(1,1,1,0.15)))
	background:setBackground(Gradient(	Vec4(1,0.5,0,0.2),		Vec4(1,0.75,0.45,0.0),
										Vec4(1,0.6,0.2,0.2),	Vec4(1,0.90,0.60,0.0)))
	local textLabel = background:add(Label( PanelSize(Vec2(-1,-1)), Text(text), Vec3(1,0.7,0) ))
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
	addheader(panel,"Gold")
	menuItems[1] = { label=addLine(panel,2,language:getText("Total gold earned")), key=2}
	menuItems[2] = { label=addLine(panel,3,"Gold available:"), key=1}
	menuItems[3] = { label=addLine(panel,4,language:getText("From kills")), key=3}
	menuItems[4] = { label=addLine(panel,5,language:getText("From interest")), key=4}
	menuItems[5] = { label=addLine(panel,6,language:getText("From waves")), key=5}
	menuItems[6] = { label=addLine(panel,7,language:getText("From towers")), key=6}
	menuItems[7] = { label=addLine(panel,8,language:getText("Spent in towers")), key=7}
	menuItems[8] = { label=addLine(panel,9,language:getText("Lost from selling")), key=8}
	addheader(panel,"Score")
	menuItems[9] = { label=addLine(panel,9,"From gold:")}
	menuItems[10] = { label=addLine(panel,10,"Total tower value:"), key=10}
	menuItems[11] = { label=addLine(panel,11,"From life left:"), key=11, multiplyer=SCOREPERLIFE}
	addheader(panel,"Towers")
	menuItems[12] = { label=addLine(panel,10,"Built:"), key=12}
	menuItems[13] = { label=addLine(panel,11,"walls:"), key=13}
	menuItems[14] = { label=addLine(panel,12,"sold:"), key=14}
	menuItems[15] = { label=addLine(panel,13,"Upgrades:"), key=15}
	menuItems[16] = { label=addLine(panel,14,"Sub upgrades:"), key=16}
	menuItems[17] = { label=addLine(panel,15,"Boosted:"), key=17}
	addheader(panel,"Enemies")
	menuItems[18] = { label=addLine(panel,16,"Spawned:"), key=18}
	menuItems[19] = { label=addLine(panel,17,"Killed:"), key=19}
	menuItems[20] = { label=addLine(panel,18,"Damage:"), key=20}
end
function setGraphLayout()
	
end
function initiate()
	data = bilboardStats:getTable("scoreHistory")
	
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
	form = Form( camera, PanelSize(Vec2(0.8,0.9), Vec2(1,1)), Alignment.MIDDLE_CENTER);
	form:setName("EndGameMenu form")
	form:getPanelSize():setFitChildren(false, true);
	form:setLayout(FallLayout( Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))));
	form:setRenderLevel(11)
	form:setVisible(false)
	form:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
	form:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
	--
	--	Top image
	--
	victoryImage = form:add(Image(PanelSize(Vec2(-1,0.20), Vec2(8,1)), "victory"))
	victoryImage:setVisible(false)
	
	defeatedImage = form:add(Image(PanelSize(Vec2(-1,1), Vec2(8,1)), "defeated"))
	defeatedImage:setVisible(false)
	--
	--	Section with all stats
	--
	MainMenuStyle.createBreakLine(form)
	
	local baseStatsPanel = form:add(Panel(PanelSize(Vec2(-0.9,-1), Vec2(5,3.5))))
	local leftPanel = baseStatsPanel:add(Panel(PanelSize(Vec2(-0.4,-1))))
	rightPanel = baseStatsPanel:add(Panel(PanelSize(Vec2(-1,-1))))
	leftPanel:setEnableYScroll()
	
	setStatsLayout(leftPanel,true)
	--setGraphLayout(rightPanel)
	graph = GraphDrawer.new(rightPanel, bilboardStats:getInt("life"), SCOREPERLIFE)
	
	--
	--	Bottom section with button options
	--
	MainMenuStyle.createBreakLine(form)
	
	local row = form:add(Panel(PanelSize(Vec2(-0.9, 1),Vec2(20,1))))
	row:setLayout(FlowLayout(PanelSize(Vec2(0.001,0))))
	
	form:add(Panel(PanelSize(Vec2(-0.9,0.002))))
	
	run = true
	
	
	--continueButton = row:add( MainMenuStyle.createButton( Vec2(-0.33,-1), Vec2(5,1), language:getText("continue")))
	restartWaveButton = row:add( MainMenuStyle.createButton( Vec2(-0.5,-1), Vec2(12,1), language:getText("revert wave")))
	local quitToMenuButton = row:add( MainMenuStyle.createButton( Vec2(-1,-1), Vec2(12,1), language:getText("quit to menu")))


	--continueButton:addEventCallbackExecute(returnToGame)
	restartWaveButton:addEventCallbackExecute(restartWave)
	quitToMenuButton:addEventCallbackExecute(quitToMainMenu)
end
-- function:	create
-- purpose:		initiates the script
function create()
	comUnit = Core.getComUnit()
	comUnit:setCanReceiveTargeted(true)
	comUnit:setCanReceiveBroadcast(false)
	
	comUnitTable["victory"] = victory
	comUnitTable["defeated"] = defeated
	
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
	
	local kill = math.clamp( math.floor(max*per+0.5), 1, max)
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
		if form:getVisible() then
			if initEventDone==false and index~=indexMax then
				index = math.min(index+(indexSpeed*Core.getRealDeltaTime()),indexMax)
				graph.setDisplayedIndex(index)
				updateAllMenuLabels()
			elseif input:getMouseHeld(MouseKey.left) and graph.isMouseInsidePanel() then
				if initEventDone==false then
					initEventDone = true
					graph.setCallbackOnDisplayIndexChange(waveIndexHasChanged)
				end
				graph.mouseClicked()
			end
			form:update()
		else
			--Handle communication
			while comUnit:hasMessage() do
				local msg = comUnit:popMessage()
				if comUnitTable[msg.message]~=nil then
					comUnitTable[msg.message](msg.parameter,msg.fromIndex)
				end
			end
			if form:getVisible() then
				comUnit:setCanReceiveTargeted(false)
			end
		end
		return run
	elseif bilboardStats:exist("scoreHistory") then
		initiate()
	end
	return true
end