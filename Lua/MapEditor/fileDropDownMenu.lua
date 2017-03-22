require("Menu/MainMenu/mainMenuStyle.lua")
require("MapEditor/createNewMap.lua")
require("MapEditor/listener.lua")
require("Menu/MainMenu/optionsMenu.lua")
require("Menu/questionForm.lua")
--this = SceneNode()

FileDropDownMenu = {}
function FileDropDownMenu.new(inButton)
	--inButton = Button()
	local self = {}
	
	
	local camera = this:getRootNode():findNodeByName("MainCamera")
	--camera = Camera()
	local form = nil
	local fileButton = nil	
	local optionsForm = nil
	local questionForm = QuestionForm.new("Quit to mainmenu", "Are you sure you want to quit.\n All unsaved changes will be lost.", true, true, "Yes", "No")
		
	function self.destroy()
		if form then
			form:setVisible(false)
			form:destroy()
			form = nil
		end
		questionForm.destroy()
	end
	
	function self.updatePosition()
		if form:getVisible() then
			form:setFormOffset(PanelSize(Vec2(fileButton:getMinPos().x, fileButton:getMaxPos().y), PanelSizeType.Pixel))
		end
	end
	
	function self.toogleVisible()
		print("Togle visible")
		form:setVisible(not form:getVisible())
		self.updatePosition()
	end	
	
	function hideAllWindows()
		--inform all windows to hide
		editorListener:pushEvent("window", "hide")
	end
	
	
	function showSaveWindow()
		editorListener:pushEvent("window", "save")
	end
	
	function showSaveAsWindow()
		editorListener:pushEvent("window", "saveWindow")
	end
	
	function showExportWindow()
		editorListener:pushEvent("window", "export")
	end
	
	function showLoadWindow()
		editorListener:pushEvent("window", "loadWindow")
	end
	
	function self.showOptionsForm(panel)
		optionsForm:setVisible( true )
	end
	
	function self.showQuitToMenuQuestionForm(panel)
		questionForm.setVisible(true)
		--Core.quitToMainMenu()
	end
	
	function self.quitToMenu()
		Worker("Menu/loadingScreen.lua", true)
		Core.quitToMainMenu()
	end
	
	function init()
		
		fileButton = inButton
		fileButton:addEventCallbackExecute(self.toogleVisible)
		
		local camera = this:getRootNode():findNodeByName("MainCamera")
		--camera = Camera()
		
		if not inColor then
			inColor = Vec3(1)
		end
		
		local rowHeight = 0.035
		form = Form( camera, PanelSize(Vec2(1, rowHeight),Vec2(8.3,1)), Alignment.TOP_LEFT);
	
		form:getPanelSize():setFitChildren(false, true);
		form:setLayout(FallLayout( Alignment.TOP_LEFT, PanelSize(Vec2(0.003),Vec2(1))));
		form:setRenderLevel(8)
		form:setVisible(false)
		form:setPadding(BorderSize(Vec4(0.003), true))
		form:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
		form:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize),true), MainMenuStyle.borderColor))
		form:addEventCallbackResized(self.updatePosition)
			
		local newButton = form:add( MainMenuStyle.createMenuButton( Vec2(-1,rowHeight), Vec2(0,0), "New"))
		local openButton = form:add( MainMenuStyle.createMenuButton( Vec2(-1,rowHeight), Vec2(0,0), "Open"))
		local saveButton = form:add( MainMenuStyle.createMenuButton( Vec2(-1,rowHeight), Vec2(0,0), "Save"))
		local saveAsButton = form:add( MainMenuStyle.createMenuButton( Vec2(-1,rowHeight), Vec2(0,0), "Save as"))
		local exportButton = form:add( MainMenuStyle.createMenuButton( Vec2(-1,rowHeight), Vec2(0,0), "Export"))
		local OptionButton = form:add( MainMenuStyle.createMenuButton( Vec2(-1,rowHeight), Vec2(0,0), "Options"))
		local quitToMenuButton = form:add( MainMenuStyle.createMenuButton( Vec2(-1,rowHeight), Vec2(0,0), "Quit to menu"))
		
		newButton:setTextAnchor(Anchor.MIDDLE_LEFT)
		openButton:setTextAnchor(Anchor.MIDDLE_LEFT)
		saveButton:setTextAnchor(Anchor.MIDDLE_LEFT)
		saveAsButton:setTextAnchor(Anchor.MIDDLE_LEFT)
		exportButton:setTextAnchor(Anchor.MIDDLE_LEFT)
		OptionButton:setTextAnchor(Anchor.MIDDLE_LEFT)
		quitToMenuButton:setTextAnchor(Anchor.MIDDLE_LEFT)
		
		keyBinds = Core.getBillboard("keyBind");
		keybindSave = keyBinds:getKeyBind("save")
		keybindSaveAs = keyBinds:getKeyBind("save as")
		keybindLoad = keyBinds:getKeyBind("load")
		keybindExport = keyBinds:getKeyBind("export")
		
		openButton:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		saveButton:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		saveAsButton:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		exportButton:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		openButton:add(Label(PanelSize(Vec2(-1),Vec2(3.8,1)), keybindLoad:getKeyBindName(0), MainMenuStyle.textColor * 0.75, Alignment.MIDDLE_LEFT)):setCanHandleInput(false)
		saveButton:add(Label(PanelSize(Vec2(-1),Vec2(3.8,1)), keybindSave:getKeyBindName(0), MainMenuStyle.textColor * 0.75, Alignment.MIDDLE_LEFT)):setCanHandleInput(false)
		saveAsButton:add(Label(PanelSize(Vec2(-1),Vec2(3.8,1)), keybindSaveAs:getKeyBindName(0), MainMenuStyle.textColor * 0.75, Alignment.MIDDLE_LEFT)):setCanHandleInput(false)
		exportButton:add(Label(PanelSize(Vec2(-1),Vec2(3.8,1)), keybindExport:getKeyBindName(0), MainMenuStyle.textColor * 0.75, Alignment.MIDDLE_LEFT)):setCanHandleInput(false)
		
		
		
		newButton:addEventCallbackExecute(CreateNewMap.newMap)
		openButton:addEventCallbackExecute(showLoadWindow)
		saveButton:addEventCallbackExecute(showSaveWindow)
		saveAsButton:addEventCallbackExecute(showSaveAsWindow)
		exportButton:addEventCallbackExecute(showExportWindow)
		
		newButton:addEventCallbackExecute(self.toogleVisible)
		openButton:addEventCallbackExecute(self.toogleVisible)
		saveButton:addEventCallbackExecute(self.toogleVisible)
		saveAsButton:addEventCallbackExecute(self.toogleVisible)
		exportButton:addEventCallbackExecute(self.toogleVisible)
		OptionButton:addEventCallbackExecute(self.toogleVisible)
		OptionButton:addEventCallbackExecute(self.showOptionsForm)
		quitToMenuButton:addEventCallbackExecute(self.showQuitToMenuQuestionForm)
		
		
		--Options form
		optionsForm = Form( camera, PanelSize(Vec2(-1,-0.8), Vec2(4,4)), Alignment.MIDDLE_CENTER);
		optionsForm:setLayout(FallLayout( Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))));
		optionsForm:setRenderLevel(12)
		optionsForm:setVisible(false)
		optionsForm:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
		optionsForm:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		
		
		local optionsPanel = OptionsMenu.create(optionsForm)
		optionsPanel:setVisible(true)
		
		
		questionForm.setOkCallback(self.quitToMenu)
		
		
	end


	init()
	
	function self.setVisible(visible)
		form:setVisible(visible)
	end
	
	function self.update()
		
		if form:getVisible() then
			
			--check if the a mouse click was done outside the color picker and it's parent panel

			local mousePos = Core.getInput():getMousePos()
			if fileButton:getMinPos().x > mousePos.x or fileButton:getMinPos().y > mousePos.y or fileButton:getMaxPos().x < mousePos.x or fileButton:getMaxPos().y < mousePos.y then
				if form:getMinPos().x > mousePos.x or form:getMinPos().y > mousePos.y or form:getMaxPos().x < mousePos.x or form:getMaxPos().y < mousePos.y then
					--hide the color picker
					form:setVisible(false)					
				end					
			end
			form:update()
			
		end
		
		if optionsForm:getVisible() then
			OptionsMenu.update()
			optionsForm:update()
			
			if Core.getInput():getKeyDown(Key.escape) then
				optionsForm:setVisible(false)
			end
		end
		
		questionForm.update()
	end
		
	return self
end