require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()

TextureSelectionMenu = {}

function TextureSelectionMenu.new(inCallback)
	local self = {}
	local form = nil
	local callback = inCallback
	
	function self.destroy()
		if form then
			form:setVisible(false)
			form:destroy()
			form = nil
		end
	end
	
	local function textureChanged(button)
		callback(button:getTag():toString())
	end
	
	function self.setVisible(visible)
		form:setVisible(visible)
		print("update texture setVisible\n")
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
	
	local function addButtonTexture(buttonPanel, textureName)
		local texture = Core.getTexture(textureName)
		
		local button = buttonPanel:add(Button(PanelSize(Vec2(-1), Vec2(1)), ButtonStyle.SQUARE, texture, Vec2(), Vec2(1)))
		button:setInnerColor(Vec4(0))
		button:setInnerHoverColor(Vec4(1,1,1,0.25))
		button:setInnerDownColor(Vec4(0.2,0.2,0.2,0.7))
		
		button:setEdgeColor(Vec4(0))
		button:setEdgeHoverColor(Vec4(1,1,1,0.25))
		button:setEdgeDownColor(Vec4(0.2,0.2,0.2,0.7))

		button:setTag(textureName)
		button:addEventCallbackExecute(textureChanged)

		return button
	end
	
	local function init()
		local camera = ConvertToCamera( this:getRootNode():findNodeByName("MainCamera") )
		--camera = Camera()
	
		form = Form( camera, PanelSize(Vec2(1, 0.6),Vec2(2,3)), Alignment.MIDDLE_CENTER);
	
		form:getPanelSize():setFitChildren(false, false);
		form:setLayout(FallLayout(Alignment.TOP_CENTER));
		form:setRenderLevel(200)
		form:setVisible(false)
		form:setPadding(BorderSize(Vec4(0.003), true))
		form:setBackground(Gradient(Vec4(MainMenuStyle.backgroundTopColor:toVec3(), 0.9), Vec4(MainMenuStyle.backgroundDownColor:toVec3(), 0.75)))
		form:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize),true), MainMenuStyle.borderColor))
		
		
		
		--Header

		local headerPanel = form:add(Panel(PanelSize(Vec2(-1,0.025))))
		headerPanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		MainMenuStyle.createBreakLine(form)
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
		
		headerPanel:add( Label( PanelSize(Vec2(-1)), "Textures", MainMenuStyle.textColor, Alignment.TOP_CENTER) )
		
		--Body
		local bottomPanel = form:add(Panel(PanelSize(Vec2(-1))))
		bottomPanel:setLayout(FallLayout(Alignment.BOTTOM_CENTER))
		
		
		--create button panel
	 	local buttonPanel = bottomPanel:add(Panel(PanelSize(Vec2(-1,0.025))))
		--add break line
		MainMenuStyle.createBreakLine(bottomPanel)
		--add main text area
		local bodyPanel = bottomPanel:add(Panel(PanelSize(Vec2(-1))))
		bodyPanel:setEnableScroll()

		
		--Buttons
		
		buttonPanel:setLayout(FlowLayout(Alignment.BOTTOM_RIGHT))
		
		local cancelButton = buttonPanel:add(Button(PanelSize(Vec2(-1), Vec2(4,1)), "Cancel" ))
		cancelButton:addEventCallbackExecute(hideForm)
		
		
		
		--set textures
		
		local imageFolder = Core.getDataFolder("Images")
		--bodyPanel
		
		local files = imageFolder:getFiles()
		
		
		local texturePanel = bodyPanel:add(Panel(PanelSize(Vec2(1,500),Vec2(5,#files/5),PanelSizeType.ParentPercent)))
		
	
		local rowPanel = nil		
		
		
		local textures = 0
		for i=1, #files do
			if files[i]:isFile() and (string.find(files[i]:getPath(), "._d%.") or string.find(files[i]:getPath(), "._D%.")) then
				addButtonTexture(texturePanel, files[i]:getName())
				textures = textures + 1
			end
		end
		
		texturePanel:setLayout(GridLayout(textures/5,5, PanelSize(Vec2(0.002),Vec2(1))))
		texturePanel:getPanelSize():setScale(Vec2(5,math.ceil(textures/5)))
		
	end
	
	init()
	
	return self
end