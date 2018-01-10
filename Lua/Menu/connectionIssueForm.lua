require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()

ConnectionIssueForm = {}
function ConnectionIssueForm.new()
	self = {}
	local headerText = "Connection issue"
	local bodyText = "Server is not responding.\nTrying to connect.\n"
	local client = Core.getNetworkClient()
	local loadingText = {token=0,timer=0.0,[1]=".",[2]="..",[3]="..."}
	local form = nil
	local okFunction = nil
	local isButtonEnabled = false
	local isFormHidden = false
	--panels
	local bottomPanel
	local buttonPanel
	local loadingLabel
	
	function self.destroy()
		if form then
			form:setVisible(false)
			form:destroy()
			form = nil
		end
	end
	
	function self.setVisible(visible)
		form:setVisible(visible)
		LOG("CONNECTION ISSUE "..tostring(visible))
--		if visible then
--			Core.setTimeSpeed(0.0)
--		else
--			Core.getNetworkClient():writeSafe("CMD-GameSpeed:"..1.0)
--			local comUnit = Core.getComUnit()
--			comUnit:sendTo("stats","setBillboardInt","speed;1")
--		end
	end
	
	local function okEvent()
		if okFunction then
			okFunction()
		end
	end
	
	function self.setOkCallback(func)
		okFunction = func
	end
	
	local function quitToMenu()
		Core.quitToMainMenu()
		local worker = Worker("Menu/loadingScreen.lua", true)
		worker:start()
	end
	
	local function hideForm()
		isFormHidden = true
		form:setVisible(false)
	end
	
	function self.getVisible()
		return form:getVisible()
	end
	
	local function enableButton()
	
		isButtonEnabled = true
		buttonPanel:setLayout(FlowLayout(Alignment.BOTTOM_CENTER))
		
		local cancelButton = buttonPanel:add( MainMenuStyle.createButton(Vec2(-1), Vec2(4,1), "Quit to menu" ) )
		cancelButton:addEventCallbackExecute(quitToMenu)
		
		local okButton = buttonPanel:add(MainMenuStyle.createButton(Vec2(-1), Vec2(4,1), "Continue alone" ))
		okButton:addEventCallbackExecute(hideForm)
		okButton:addEventCallbackExecute(okEvent)
	end
	
	function self.update()
		if form:getVisible() then
			--if isFormHidden==true then this window has allready been shown and dissmised
--			if client:isLosingConnection() then-- and isFormHidden==false 
				if isButtonEnabled==false and client:isConnected()==false then
					enableButton()
				end
				if Core.getInput():getMouseDown(MouseKey.left) then
					local mousePos = Core.getInput():getMousePos()
					if form:getMinPos().x > mousePos.x or form:getMinPos().y > mousePos.y or form:getMaxPos().x < mousePos.x or form:getMaxPos().y < mousePos.y then
						hideForm()
					end
				end
				if Core.getTime()-loadingText.timer>1.0 then
					loadingText.timer = Core.getTime()
					print("loadingText.token=="..loadingText.token.."\n")
					loadingText.token = loadingText.token==3 and 1 or loadingText.token + 1
					loadingLabel:setText(loadingText[loadingText.token])
				end
				
				form:update()
--			else
--				setVisible(false)
			--end
		end
	end
	
	local function init()
		local camera = ConvertToCamera( this:getRootNode():findNodeByName("MainCamera") )
		--camera = Camera()
		form = Form( camera, PanelSize(Vec2(1, 1)), Alignment.TOP_LEFT);
		
		form:getPanelSize():setFitChildren(false, false);
		form:setLayout(FlowLayout(Alignment.MIDDLE_CENTER));
		form:setRenderLevel(200)
		form:setVisible(false)
		form:setBackground(Sprite(Vec4(0,0,0,0.6)))
		form:addEventCallbackOnClick(hideForm)
		
		local mainPanel = form:add(Panel(PanelSize(Vec2(1,0.20),Vec2(2.5,1))))
			
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
		bottomPanel = mainPanel:add(Panel(PanelSize(Vec2(-1))))
		bottomPanel:setLayout(FallLayout(Alignment.BOTTOM_CENTER))
		
		--create button panel
	 	buttonPanel = bottomPanel:add(Panel(PanelSize(Vec2(-1,0.025))))
		--add break line
		MainMenuStyle.createBreakLine(bottomPanel)
		--add main text area
		local bodyPanel = bottomPanel:add(Panel(PanelSize(Vec2(-1))))
		
		loadingText.timer = Core.getTime()
		local bodyText = bodyPanel:add(Label(PanelSize(Vec2(-1,-0.66)), bodyText, MainMenuStyle.textColor, Alignment.MIDDLE_CENTER))
		bodyText:setTextHeight( 0.016 )
		loadingLabel = bodyPanel:add(Label(PanelSize(Vec2(-1)), ".", MainMenuStyle.textColor, Alignment.MIDDLE_CENTER))
		bodyText:setTextHeight( 0.016 )
	end
	
	init()
	
	return self
end