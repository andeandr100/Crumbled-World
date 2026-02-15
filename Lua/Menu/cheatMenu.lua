require("Menu/MainMenu/mainMenuStyle.lua")
require("Game/mapInfo.lua")

--this = SceneNode()
CheatMenu = {}
function CheatMenu.new()
	local self = {}
	
	local form
	local comUnit = Core.getComUnit()
	local listener = Listener("cheatEvent")
	local difficultTextField
	local difficultIncTextField
	--
	
	function self.destroy()
		
		return true
	end
	
	function self.update()
		
		if Core.getInput():getKeyDown(Key.p) then
			form:setVisible(form:getVisible() and true or false)
		end
		
		form:update()
		
		return true
	end
	
	
	local function addGold()
	
		comUnit:sendTo("log", "println", "cheat-addGold")
		statsBilboard = Core.getBillboard("stats")
		comUnit:sendTo("stats", "addGold", tostring(500.0))
		saveStats = false
		Core.getGlobalBillboard("highScoreReplay"):setBool("saveHighScore",saveStats)
	end
	
	local function removeGold()
	
		comUnit:sendTo("log", "println", "cheat-addGold")
		statsBilboard = Core.getBillboard("stats")
		comUnit:sendTo("stats", "addGold", tostring(-500.0))
		saveStats = false
		Core.getGlobalBillboard("highScoreReplay"):setBool("saveHighScore",saveStats)
	end
	
	local function reloadFirstWave()
		local data = {difficulty=tonumber(difficultTextField:getText()), difficultIncreaser=tonumber(difficultIncTextField:getText())}
		listener:pushEvent("ReloadWaves",data)
	end
	
	local function reloadEndWaves()
		local data = {difficulty=tonumber(difficultTextField:getText()), difficultIncreaser=tonumber(difficultIncTextField:getText())}
		listener:pushEvent("ReloadWaves",data)
	end
	
	
	--
	local function init()
		local rootNode = this:getRootNode();
		--camera = Camera()
		local camera = ConvertToCamera( rootNode:findNodeByName("MainCamera") )
		
		local panelSpacing = PanelSize(Vec2(0.005),Vec2(1))
		form = Form( camera, PanelSize(Vec2(0.225,-1),PanelSizeType.WindowPercentBasedOnY), Alignment.TOP_LEFT, "SelectedTowerMenuForm");
		form:setName("Cheat form")
		form:getPanelSize():setFitChildren(false,true)
		form:setBackground(Gradient(Vec4(Vec3(0),0.85), Vec4(Vec3(0),0.7)));
		form:setLayout(FallLayout(panelSpacing));
		form:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor));
		form:setPadding(BorderSize(Vec4(MainMenuStyle.borderSize * 3)));
		form:setFormOffset(PanelSize(Vec2(0.05, 0.05)));
		form:setRenderLevel(99)
		form:setVisible(true)
		
		local rowPanel = form:add(Panel(PanelSize(Vec2(-1,0.03),PanelSizeType.WindowPercentBasedOnY)))
		
		rowPanel:add( MainMenuStyle.createMenuButton( Vec2(-0.5,-1), nil, "+500") ):addEventCallbackExecute(addGold)
		rowPanel:add( MainMenuStyle.createMenuButton( Vec2(-1,-1), nil, "-500") ):addEventCallbackExecute(removeGold)
		
		rowPanel = form:add(Panel(PanelSize(Vec2(-1,0.02),PanelSizeType.WindowPercentBasedOnY)))
		
		rowPanel:add(Label(PanelSize(Vec2(-0.5,-1)), "Base Difficulty", Vec3(1)))
		rowPanel:add(Label(PanelSize(Vec2(-1,-1)), "Difficulty Inc", Vec3(1)))
		
		rowPanel = form:add(Panel(PanelSize(Vec2(-1,0.03),PanelSizeType.WindowPercentBasedOnY)))
		
		
		local mapInfo = MapInfo.new()
		
		difficultTextField = rowPanel:add( TextField(PanelSize(Vec2(-0.5,-1)), tostring(mapInfo.getDifficulty()) ))
		difficultIncTextField = rowPanel:add( TextField(PanelSize(Vec2(-1,-1)), tostring(mapInfo.getDifficultyIncreaser()) ))
		
		rowPanel = form:add(Panel(PanelSize(Vec2(-1,0.03),PanelSizeType.WindowPercentBasedOnY)))
		rowPanel:add( MainMenuStyle.createMenuButton( Vec2(-0.5,-1), nil, "Reload First") ):addEventCallbackExecute(reloadFirstWave)
		rowPanel:add( MainMenuStyle.createMenuButton( Vec2(-1,-1), nil, "Reload End") ):addEventCallbackExecute(reloadEndWaves)
	end
	init()

	--
	return self
end

function create()
	cheatMenu = CheatMenu.new()
	update = cheatMenu.update
	destroy = cheatMenu.destroy
	return true
end