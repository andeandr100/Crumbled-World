require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()

QuestionForm = {}
function QuestionForm.new(headerText, bodyText, enabelOkButton, enableCancelButton, okButtonText, cancelButtonText)
	self = {}
	local form = nil
	local okFunction = nil
	
	function self.destroy()
		if form then
			form:setVisible(false)
			form:destroy()
			form = nil
		end
	end
	
	function self.setVisible(visible)
		form:setVisible(visible)
	end
	
	local function okEvent()
		if okFunction then
			okFunction()
		end
	end
	
	function self.setOkCallback(func)
		okFunction = func
	end
	
	local function hideForm()
		form:setVisible(false)
	end
	
	function self.getVisible()
		return form:getVisible()
	end
	
	function self.update()
		if form:getVisible() then
			
			if Core.getInput():getMouseDown(MouseKey.left) then
				local mousePos = Core.getInput():getMousePos()
				if form:getMinPos().x > mousePos.x or form:getMinPos().y > mousePos.y or form:getMaxPos().x < mousePos.x or form:getMaxPos().y < mousePos.y then
					hideForm()
				end
			end
			
			form:update()
		end
	end
	
	local function init()
		local camera = ConvertToCamera( this:getRootNode():findNodeByName("MainCamera") )
		--camera = Camera()
		form = Form( camera, PanelSize(Vec2(1, 1)), Alignment.TOP_LEFT);
		form:setName("Question form")
		form:getPanelSize():setFitChildren(false, false);
		form:setLayout(FlowLayout(Alignment.MIDDLE_CENTER));
		form:setRenderLevel(200)
		form:setVisible(false)
		form:setBackground(Sprite(Vec4(0,0,0,0.6)))
		form:addEventCallbackOnClick(hideForm)
		
		mainPanel = form:add(Panel(PanelSize(Vec2(1,0.15),Vec2(2.5,1))))
			
		mainPanel:setPadding(BorderSize(Vec4(0.003), true))
		mainPanel:setBackground(Gradient(Vec4(MainMenuStyle.backgroundTopColor:toVec3(), 0.9), Vec4(MainMenuStyle.backgroundDownColor:toVec3(), 0.75)))
		mainPanel:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize),true), MainMenuStyle.borderColor))
		mainPanel:setLayout(FallLayout(Alignment.TOP_CENTER));	
		
		
		--Header

		local headerPanel = mainPanel:add(Panel(PanelSize(Vec2(-1,0.030))))
		headerPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		MainMenuStyle.createBreakLine(mainPanel)
		local quitButton = headerPanel:add( Button(PanelSize(Vec2(-1),Vec2(1)), "X", ButtonStyle.SQUARE ) )
		quitButton:addEventCallbackExecute(hideForm)
		
		quitButton:setTextColor(MainMenuStyle.textColor)
		quitButton:setTextHoverColor(MainMenuStyle.textColorHighLighted)
		quitButton:setTextDownColor(MainMenuStyle.textColorHighLighted)
		quitButton:setTextAnchor(Anchor.MIDDLE_LEFT)
	
		quitButton:setEdgeColor(Vec4(0), Vec4(0))
		quitButton:setEdgeHoverColor(Vec4(0), Vec4(0))
		quitButton:setEdgeDownColor(Vec4(0), Vec4(0))
	
		quitButton:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
		quitButton:setInnerHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
		quitButton:setInnerDownColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
		
		headerPanel:add( Label( PanelSize(Vec2(-1)), headerText, MainMenuStyle.textColor, Alignment.TOP_CENTER) )
		
		--Body
		local bottomPanel = mainPanel:add(Panel(PanelSize(Vec2(-1))))
		bottomPanel:setLayout(FallLayout(Alignment.BOTTOM_CENTER))
		
		
		--create button panel
	 	local buttonPanel = bottomPanel:add(Panel(PanelSize(Vec2(-1,0.025))))
		--add break line
		MainMenuStyle.createBreakLine(bottomPanel)
		--add main text area
		local bodyPanel = bottomPanel:add(Panel(PanelSize(Vec2(-1))))
		
		
		local bodyText = bodyPanel:add(Label(PanelSize(Vec2(-1)), bodyText, MainMenuStyle.textColor, Alignment.MIDDLE_CENTER))
		bodyText:setTextHeight( 0.016 )
		
		--Buttons
		
		buttonPanel:setLayout(FlowLayout(Alignment.BOTTOM_CENTER))
		
		
		if enableCancelButton then
			local cancelButton = buttonPanel:add( MainMenuStyle.createButton(Vec2(-1), Vec2(4,1), cancelButtonText and cancelButtonText or "Cancel" ) )
			cancelButton:addEventCallbackExecute(hideForm)
		end
		
		if enabelOkButton then
			local okButton = buttonPanel:add(MainMenuStyle.createButton(Vec2(-1), Vec2(4,1), okButtonText and okButtonText or "Ok" ))
			okButton:addEventCallbackExecute(hideForm)
			okButton:addEventCallbackExecute(okEvent)
		end
	end
	
	init()
	
	return self
end