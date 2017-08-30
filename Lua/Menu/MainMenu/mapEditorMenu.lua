require("Menu/MainMenu/mainMenuStyle.lua")

--this = SceneNode()
MapEditorMenu = {}
MapEditorMenu.labels = {}

function MapEditorMenu.languageChanged()
	for i=1, #MapEditorMenu.labels do
		MapEditorMenu.labels[i]:setText(language:getText(MapEditorMenu.labels[i]:getTag()))
	end
end

function MapEditorMenu.create(panel)
	
	MapEditorMenu.selectedFile = ""
	
	--Options panel
	local mapEditorPanel = panel:add(Panel(PanelSize(Vec2(-1))))
	mapEditorPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
	--Top menu button panel
	MapEditorMenu.labels[1] = mapEditorPanel:add(Label(PanelSize(Vec2(-1,0.04)), language:getText("map editor"), Vec3(0.94), Alignment.MIDDLE_CENTER))
	MapEditorMenu.labels[1]:setTag("map editor")
	
	--Add BreakLine
	local breakLinePanel = mapEditorPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
	local gradient = Gradient()
	gradient:setGradientColorsHorizontal({Vec3(0.45),Vec3(0.66),Vec3(0.45)})
	breakLinePanel:setBackground(gradient)
	
	local mainPanel = mapEditorPanel:add(Panel(PanelSize(Vec2(-0.9, -0.95))))
	mainPanel:setLayout(FallLayout(Alignment.BOTTOM_RIGHT))
	
	local newMapRowPanel = mainPanel:add(Panel(PanelSize(Vec2(-1, 0.035))))
	local mainAreaPanel = mainPanel:add(Panel(PanelSize(Vec2(-1))))
	mainAreaPanel:setBorder(Border( BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
	
	--Add map panel
	MapEditorMenu.addMapsPanel(mainAreaPanel)
	
	--add midle Border line
	mainAreaPanel:add(Panel(PanelSize(Vec2(MainMenuStyle.borderSize,-1),PanelSizeType.WindowPercentBasedOny))):setBackground(Sprite(MainMenuStyle.borderColor))
	
	--Add info panel
	MapEditorMenu.addMapInfoPanel(mainAreaPanel)
	
	newMapRowPanel:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
	local createNewMapButton = newMapRowPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(5.4,1), language:getText("create a new map")))
	createNewMapButton:addEventCallbackExecute(MapEditorMenu.createNewMap)
	MapEditorMenu.labels[2] = createNewMapButton
	MapEditorMenu.labels[2]:setTag("create a new map")
	
	--set ther first map as selected
	if MapEditorMenu.firstButton then
		MapEditorMenu.changedMap(MapEditorMenu.firstButton)
	end
	
	mapEditorPanel:setVisible(false)
	return mapEditorPanel	
end

function MapEditorMenu.addMapInfoPanel(panel)
	local infoPanel = panel:add(Panel(PanelSize(Vec2(-1, -1))))
--	infoPanel:getPanelSize():setFitChildren(false, true)
	infoPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.005))))
	infoPanel:setPadding(BorderSize(Vec4(0.005),true))
	infoPanel:setBackground(Gradient(Vec4(0,0,0,0.9), Vec4(0,0,0,0.9)))
	
	MapEditorMenu.iconImage = infoPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("noImage")))
	MapEditorMenu.iconImage:setBorder(Border( BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
	
	MapEditorMenu.mapLabel = infoPanel:add(Label(PanelSize(Vec2(-1, 0.03)), "The island world", Vec3(0.7)))
	
	local startAGameButton = infoPanel:add(MainMenuStyle.createButton(Vec2(-1,0.03), Vec2(5,1), language:getText("edit map")))
	startAGameButton:addEventCallbackExecute(MapEditorMenu.loadmap)
	MapEditorMenu.labels[3] = startAGameButton
	MapEditorMenu.labels[3]:setTag("edit map")
end

function MapEditorMenu.changedMap(button)
	MapEditorMenu.selectedFile = button:getTag():toString()
	local mapFile = File(button:getTag():toString())
	local changeImage = false
	if mapFile:isFile() then
		MapEditorMenu.mapLabel:setText( mapFile:getName() )
		local image = File(button:getTag():toString(), "icon.jpg")
		if image:exist() then
			local texture = Core.getTexture(image)
			if texture then
				MapEditorMenu.iconImage:setTexture(texture)
				changeImage = true
			end
		end
	end
	
	if not changeImage then
		MapEditorMenu.iconImage:setTexture(Core.getTexture("noImage"))
	end
end

function MapEditorMenu.createNewMap()
	Core.startMapEditor("")
	local worker = Worker("Menu/loadingScreen.lua", true)
	worker:start()
end

function MapEditorMenu.loadmap()
	Core.startMapEditor(MapEditorMenu.selectedFile)
	local worker = Worker("Menu/loadingScreen.lua", true)
	worker:start()
end

function MapEditorMenu.addMapsPanel(panel)
	local mapFolder = Core.getDataFolder("MapEditor")
	local files = mapFolder:getFiles()
	
	local mapsPanel = panel:add(Panel(PanelSize(Vec2(-0.6, -1))))
	
	local headerPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, 0.035))))
	headerPanel:setBackground(Gradient(Vec4(1,1,1,0.05), Vec4(1,1,1,0.1)))
	headerPanel:add(Label(PanelSize(Vec2(-0.65, -1)), "Name", Vec4(0.95)))
		
	local mapListPanel = mapsPanel:add(Panel(PanelSize(Vec2(-1, -1))))
	mapListPanel:setEnableYScroll()	
			
	local count = 0
	for i=1, #files do
		
		local file = files[i]
		--file = File()
		
		if file:isFile() then
			count = count + 1

			local button = mapListPanel:add(Button(PanelSize(Vec2(-1,0.03)), "", ButtonStyle.SQUARE))
			button:setTag(file:getPath())
			
			button:setTextColor(Vec3(0.7))
			button:setTextHoverColor(Vec3(0.92))
			button:setTextDownColor(Vec3(1))
			
			if count%2 == 0 then
				button:setEdgeColor(Vec4(1,1,1,0.05), Vec4(1,1,1,0.05))
				button:setInnerColor(Vec4(1,1,1,0.05), Vec4(1,1,1,0.05), Vec4(1,1,1,0.05))
			else
				button:setEdgeColor(Vec4(0), Vec4(0))
				button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
			end
			button:setEdgeHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
			button:setEdgeDownColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
		
			
			button:setInnerHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.45), Vec4(1,1,1,0.4))
			button:setInnerDownColor(Vec4(1,1,1,0.3), Vec4(1,1,1,0.4), Vec4(1,1,1,0.3))	
			
			button:setLayout(FlowLayout(Alignment.TOP_LEFT))
			local label = button:add(Label(PanelSize(Vec2(-0.65, -1)), file:getName(), Vec4(0.85)))
			label:setCanHandleInput(false)
			

			button:addEventCallbackExecute(MapEditorMenu.changedMap)
			
			if count == 1 then
				MapEditorMenu.firstButton = button
			end
		end
	end
end

function MapEditorMenu.update()
	
end