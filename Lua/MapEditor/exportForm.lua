require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()
ExportForm = {}

function ExportForm.new()
	local self = {}
	local form
	local optionsForm
	local exportPanel
	local loadingSprite
	local pathTextField
	
	function self.hide()
		form:setVisible(false)
	end
	
	function self.show()
--		form:setVisible(true)
	end
	
	function self.export(filePath)
		local bilboard = Core.getGlobalBillboard("MapEditor")
		bilboard:setString("exportToFile", filePath)
		pathTextField:setText(filePath)
		form:update()--force the text to be updated
	
		optionsForm:setVisible(true)
	end
	
	
	function self.update()
		if optionsForm:getVisible() then
			optionsForm:update()
		elseif form:getVisible() then
			
			local height = Core.getScreenResolution().y * 0.035
--			print("\nheight: "..height.."\n")
--			print("pos: "..(exportPanel:getMaxPos().x-height*0.5)..", "..(exportPanel:getMaxPos().y-height*0.5).."\n")
			loadingSprite:setSize(Vec2(height))
			
			local localMat = Matrix(Vec3(exportPanel:getMaxPos().x-height*0.7 - exportPanel:getMinPos().x, exportPanel:getMaxPos().y-height*0.7 - exportPanel:getMinPos().y, 0))
			localMat:rotate(Vec3(0,0,1), Core.getGameTime() * math.pi)
			loadingSprite:setLocalMatrix(localMat)
			
			form:update()
		end
	end
	
	local function startExport()
		local bilboard = Core.getGlobalBillboard("MapEditor")
		bilboard:setString("exportToFile", pathTextField:getText():toString())
		bilboard:setBool("exportLuaFiles",checkBoxAddLuaFiles:getSelected())
	
		local worker = Worker("MapEditor/exportScript.lua",false)
		worker:addCallbackFinished(self.hide)
		form:setVisible(true)
		optionsForm:setVisible(false)
	end

	local function quitExport()
		optionsForm:setVisible(false)
	end
	
	local function init()
		--camera = Camera()
		local camera = this:getRootNode():findNodeByName("MainCamera")
		
		--export question form
		optionsForm = Form( camera, PanelSize(Vec2(-1,0.15), Vec2(2.8,1)), Alignment.MIDDLE_CENTER);
		optionsForm:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor));
		optionsForm:setLayout(FallLayout(PanelSize(Vec2(MainMenuStyle.borderSize))));
		optionsForm:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor));
		optionsForm:setPadding(BorderSize(Vec4(MainMenuStyle.borderSize * 3)));
		optionsForm:setFormOffset(PanelSize(Vec2(0.005), Vec2(1)));
		optionsForm:setRenderLevel(1)
		
		optionsForm:add(Label(PanelSize(Vec2(-1,0.03)), "Export", MainMenuStyle.textColorHighLighted, Alignment.MIDDLE_CENTER))
		MainMenuStyle.createBreakLine(optionsForm)
		
		local optionsPanel = optionsForm:add(Panel(PanelSize(Vec2(-1))))
		optionsPanel:setLayout(FallLayout(Alignment.BOTTOM_RIGHT))	
		
		local bottomPanel = optionsPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
		MainMenuStyle.createBreakLine(optionsPanel)
		local mainPanel = optionsPanel:add(Panel(PanelSize(Vec2(-1))))
		mainPanel:setLayout(FallLayout(Alignment.TOP_LEFT))
		
		--Button Panel
		bottomPanel:setLayout(FlowLayout(Alignment.TOP_CENTER))
		local exportButton = bottomPanel:add(MainMenuStyle.createButton(Vec2(-1), Vec2(4,1), "Export"))
		local quitExportButton = bottomPanel:add(MainMenuStyle.createButton(Vec2(-1), Vec2(4,1), "Cancel"))
		exportButton:addEventCallbackExecute(startExport)
		quitExportButton:addEventCallbackExecute(quitExport)
		
		--Main Options form Panel
		
	 	local row = mainPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
		row:add(Label(PanelSize(Vec2(-1),Vec2(4.5,1)), "Export path: ", MainMenuStyle.textColor, Alignment.MIDDLE_RIGHT ))
		local endOfRow = row:add(Panel(PanelSize(Vec2(-1))))
		endOfRow:setLayout(FlowLayout(Alignment.TOP_RIGHT))
--		local changeFileButton = endOfRow:add(MainMenuStyle.createButton(Vec2(-1),Vec2(2,1),"..."))
		pathTextField = endOfRow:add(MainMenuStyle.createTextField(Vec2(-1),Vec2(), "Path/Path"))
		pathTextField:setWhiteList("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ._-/")
		
		row = mainPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
		row:add(Label(PanelSize(Vec2(-1),Vec2(4.5,1)), "Include lua: ", MainMenuStyle.textColor, Alignment.MIDDLE_RIGHT ))
		checkBoxAddLuaFiles = row:add(CheckBox(PanelSize(Vec2(-1), Vec2(1)), false))
		
		
		--Exporting form 
		form = Form( camera, PanelSize(Vec2(1, 1)), Alignment.TOP_LEFT);
	
		form:getPanelSize():setFitChildren(false, false);
		form:setLayout(FlowLayout(Alignment.MIDDLE_CENTER));
		form:setRenderLevel(50)
		form:setVisible(false)
		form:setBackground(Sprite(Vec4(0,0,0,0.6)))
	
		exportPanel = form:add(Panel(PanelSize(Vec2(1,0.15),Vec2(4,1))))
		
		exportPanel:setPadding(BorderSize(Vec4(0.003), true))
		exportPanel:setBackground(Gradient(Vec4(MainMenuStyle.backgroundTopColor:toVec3(), 0.9), Vec4(MainMenuStyle.backgroundDownColor:toVec3(), 0.75)))
		exportPanel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize),true), MainMenuStyle.borderColor))
		
		local label = exportPanel:add(Label(PanelSize(Vec2(-1)), "Exporting the map.\nThis can take a few minutes.",Alignment.MIDDLE_CENTER))
		label:setTextColor(MainMenuStyle.textColor)
		label:setTextHeight(0.02)
		
		local texture = Core.getTexture("icon_table")
		loadingSprite = Sprite(texture)
		loadingSprite:setAnchor(Anchor.MIDDLE_CENTER)
		loadingSprite:setUvCoord(Vec2(0.775,0.125), Vec2(1.0,0.375))

		local height = Core.getScreenResolution().y * 0.035
		loadingSprite:setSize(Vec2(height))
		
		
		exportPanel:addRenderObject(loadingSprite)
		

		local localMat = Matrix(Vec3(loadingSprite:getLocalPosition(),0))
		localMat:rotate(Vec3(0,0,1), Core.getGameTime())
		loadingSprite:setLocalMatrix(localMat)
	end
	
	init()
	
	return self
end