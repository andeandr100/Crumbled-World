require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/towerImage.lua")
require("Game/mapInfo.lua")
require("Game/campaignData.lua")
--this = SceneNode()
IslandInfo = {}
function IslandInfo.new(camera)
	--mainAreaPanel = Panel()
	local self = {}
	--camera = Camera()
	local form = nil
	local mainPanel = nil
	local mapNameLabel = nil
	local gameDifficultyComboBox = nil
	local iconImage = nil
	local activeMapFile = ""
	local mapInfo = MapInfo.new()
	local cData = CampaignData.new()
	
	function self.destroy()
		if form then
			form:setVisible(false)
			form:destroy()
			form = nil
		end
	end
	
	function self.toggleVisible()
		form:setVisible( not form:getVisible() )
	end
	
	function self.setVisible(visible)
		form:setVisible(visible)
	end
	
	function self.getVisible()
		return form:getVisible()
	end
	
	function self.isPosInsideForm(pos)
		return pos.x >= mainPanel:getMinPos().x and pos.y >= mainPanel:getMinPos().y and pos.x <= mainPanel:getMaxPos().x and pos.y <= mainPanel:getMaxPos().y
	end
	
	
	function addTitle()
		
		local titlePanel = mainPanel:add(Panel(PanelSize(Vec2(-1,0.037))))
		
		titlePanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0))))
		--Top menu button panel
		mapNameLabel = titlePanel:add(Label(PanelSize(Vec2(-1,0.035)), "Map name", Vec3(0.94), Alignment.MIDDLE_CENTER))
		
		--Add BreakLine
		local breakLinePanel = titlePanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
		breakLinePanel:setBackground(Sprite(Vec3(0.45)))
	end
	
	function addItem(text)
		local button = gameDifficultyComboBox:addItem(MainMenuStyle.createMenuButton(Vec2(-1,0.03), Vec2(), text))
		button:setTag(text)
		button:addEventCallbackExecute(changeItem)
	end
	
	function changeItem(button)
		gameDifficultyComboBox:setText(button:getTag())
	end
	--
	--	Callback
	--
	local function difficultyChanged()
		local difficult = {Easy=1,Normal=2,Hard=3,Extreme=4,Insane=5}--"Impossible #"
		if difficult[gameDifficultyComboBox:getText()] then
			mapInfo.setLevel(tonumber(difficult[gameDifficultyComboBox:getText()]))
			--print("difficulty == "..difficult[gameDifficultyComboBox:getText()].."\n")
		else
			mapInfo.setLevel(5+tonumber(string.match(gameDifficultyComboBox:getText(), " (.*)")))
			--print("difficulty == "..5+tonumber(string.match(gameDifficultyComboBox:getText(), " (.*)")).."\n")
		end
	end
	local function gameModeNormalClick()
		mapInfo.setGameMode("Normal")
	end
	local function gameModeSurvivalClick()
		mapInfo.setGameMode("survival")
	end
	local function gameModeTrainingClick()
		mapInfo.setGameMode("training")
	end
	local function gameModeInterestClick()
		mapInfo.setGameMode("interest")
	end
	local function gameModeProjectilesClick()
		mapInfo.setGameMode("Projectiles")
	end
	local function gameModeLowTowersClick()
		mapInfo.setGameMode("NoRedTowers")
	end
	local function gameModeDeadlyCursorClick()
		mapInfo.setGameMode("DeadlyCursor")
	end
	--
	local function startMap()
		if activeMapFile then
			Core.startMap(activeMapFile)
			--start the loading screen
			Worker("Menu/loadingScreen.lua", true)
		else
			--do someThing
		end
	end
	--
	--
	--
	function init()
		
		local panelSpacing = 0.005
		local panelSpacingVec2 = Vec2(panelSpacing, panelSpacing)
		
		form = Form(camera, PanelSize(Vec2(0.55,0.45), Vec2(1.4,1)), Alignment.TOP_LEFT);
		form:setLayout(FlowLayout(PanelSize(panelSpacingVec2)));
		form:setRenderLevel(9)	
		form:setVisible(false)
		
		form:setFormOffset(PanelSize(Vec2(0.3)))
		
		mainPanel = form:add(Panel(PanelSize(Vec2(-1,-1))))
		--mainPanel:setLayout(FlowLayout(PanelSize(Vec2(0.01,0))))
		mainPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
		mainPanel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)),MainMenuStyle.borderColor))
		
		addTitle()
		
		local leftPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.5,-1))))
		local rightPanel = mainPanel:add(Panel(PanelSize(Vec2(-1,-1))))
		
--		leftPanel:setBackground(Sprite(Vec3(1,0,0)))
--		rightPanel:setBackground(Sprite(Vec3(0,0,1)))
		rightPanel:setPadding(BorderSize(Vec4(panelSpacing),true))
		rightPanel:setLayout(FlowLayout(PanelSize(Vec2(panelSpacing))))
		
		local image = File("Data/Map/world3.map", "icon.jpg")
		if image:exist() then
			local texture = Core.getTexture(image)
			
			local imagePanel = rightPanel:add(Panel(PanelSize(Vec2(-1,-1), Vec2(1))))
			iconImage = imagePanel:add(Image(PanelSize(Vec2(-1, -0.75),Vec2(1,1)), texture))
			imagePanel:setBackground(Sprite(Vec3(0)))
			
			local row1 = rightPanel:add(Panel(PanelSize(Vec2(-1,0.025))))
			row1:add(Label(PanelSize(Vec2(-0.3,-1)), "Difficulty:", MainMenuStyle.textColor))
			gameDifficultyComboBox = row1:add(ComboBox(PanelSize(Vec2(-1)), "Normal"))
			gameDifficultyComboBox:addEventCallbackChanged(difficultyChanged)
			
			local StartGamePanel = rightPanel:add(Panel(PanelSize(Vec2(-1,-1))))
			StartGamePanel:setLayout(FallLayout(Alignment.BOTTOM_RIGHT))
			startButton = StartGamePanel:add(Button(PanelSize(Vec2(-1,0.03), Vec2(5,1)), "Start game"))
			startButton:addEventCallbackExecute(startMap)
		end
		
		--Scoreboard
		leftPanel:setMargin(BorderSize(Vec4(panelSpacing),true))
		leftPanel:setLayout(FallLayout(Alignment.TOP_CENTER))
		leftPanel:add(Label(PanelSize(Vec2(-1,0.03)), "Scoreboard", MainMenuStyle.textColor, Alignment.MIDDLE_CENTER))
		local scoreboardPanel = leftPanel:add(Panel(PanelSize(Vec2(-1,-0.3))))
		scoreboardPanel:setBorder(Border(BorderSize(Vec4(panelSpacing * 0.5),true), Vec3(0.65)))
		scoreboardPanel:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
		gameModeNormal = leftPanel:add(Button(PanelSize(Vec2(-1,0.025)), "Normal"))
		gameModeNormal:addEventCallbackExecute(gameModeNormalClick)
		gameModeSurvival = leftPanel:add(Button(PanelSize(Vec2(-1,0.025)), "Survival"))
		gameModeSurvival:addEventCallbackExecute(gameModeSurvivalClick)
		gameModeTraining = leftPanel:add(Button(PanelSize(Vec2(-1,0.025)), "15000g"))
		gameModeSurvival:addEventCallbackExecute(gameModeSurvivalClick)
		gameModeInterest = leftPanel:add(Button(PanelSize(Vec2(-1,0.025)), "only interest earned"))
		gameModeSurvival:addEventCallbackExecute(gameModeSurvivalClick)
		gameModeProjectiles = leftPanel:add(Button(PanelSize(Vec2(-1,0.025)), "only projectile towers"))
		gameModeSurvival:addEventCallbackExecute(gameModeSurvivalClick)
		gameModeLowTowers = leftPanel:add(Button(PanelSize(Vec2(-1,0.025)), "No red towers"))
		gameModeLowTowers:addEventCallbackExecute(gameModeLowTowersClick)
		gameModeDeadlyCursor = leftPanel:add(Button(PanelSize(Vec2(-1,0.025)), "deadly cursor"))
		gameModeDeadlyCursor:addEventCallbackExecute(gameModeDeadlyCursorClick)
	end
	
	function self.setData(filePath, name)
		activeMapFile = filePath
		mapInfo.setMapFileName(filePath)
		mapInfo.setIsCampaign(true)
		--add all difficulty levels available
		print("gameDifficultyComboBox:clear()\n")
		gameDifficultyComboBox:clearItems()
		addItem( "Easy")			--0.70
		addItem( "Normal")			--0.75
		addItem( "Hard" )			--0.80
		addItem( "Extreme" )		--0.85
		addItem( "Insane" )			--0.90
		for i=6, cData.getLevelCompleted(activeMapFile)+1 do
			addItem( "Impossible "..(i-5) )--Unlock the next dificulty level each time you beat the last
		end
		--load and set map icon
		local image = File(filePath, "icon.jpg")
		if image:exist() then
			iconImage:setTexture(Core.getTexture(image))
		else
			iconImage:setTexture(Core.getTexture("White"))
		end
		
		--set map name
		mapNameLabel:setText(name)
		
		--TODO
		--update scoreboard
	end
	
	function self.showData()
		
	end

	init()

	--Update the map panel
	function self.update()
		form:update()
		
	end
		
	return self
end