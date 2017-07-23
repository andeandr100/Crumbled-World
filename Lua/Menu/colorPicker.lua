require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()

ColorPickerForm = {}
function ColorPickerForm.new(inParentPanel, panelSize, inColor)
	--inParentPanel = Panel()
	local self = {}
	
	
	local camera = this:getRootNode():findNodeByName("MainCamera")
	--camera = Camera()
	local form = nil
	local colorPanel = nil
	local colorPicker = nil
	local colorButton = nil
	local onChangeCallback = nil
	local previousColor = Vec3(-1)
	
	function self.setChangeCallback(inFunction)
		onChangeCallback = inFunction
	end
	
	function changeColor(colorPicker)
		self.setColor(colorPicker:getColor())
	end
	
	function self.setColor(color)
		
		print("set Color: "..tostring(color).." previous color: "..tostring(colorPicker:getColor()).."\n")
		if previousColor ~= Vec3(color.x, color.y, color.z) then
			previousColor = Vec3(color.x, color.y, color.z)
			
			colorPanel:setBackground(Sprite(color))
			
			textFieldRed:setText(tostring(math.round(color.x*255)))
			textFieldGreen:setText(tostring(math.round(color.y*255)))
			textFieldBlue:setText(tostring(math.round(color.z*255)))
			
			colorButton:setBackground(Sprite(color))
			colorPicker:setColor(color)
			if onChangeCallback then
				print("Call color change callback\n")
				onChangeCallback(colorPicker)
			end
		end
	end
	
	function buttonChangeColor(button)
		colorPicker:setColor(totable(button:getTag():toString())[1])
		changeColor(colorPicker)
	end
	
	function tonumberSafe(text)
		if text and text ~= "" then
			return tonumber(text)
		else
			return 0
		end
	end
	
	function textFieldChanged(textField)
		local color = Vec3(tonumberSafe(textFieldRed:getText())/255, tonumberSafe(textFieldGreen:getText())/255, tonumberSafe(textFieldBlue:getText())/255)
		colorPicker:setColor(color)
		colorPanel:setBackground(Sprite(color))
	end
	
	function self.updatePosition()
		if form:getVisible() then
			local size = form:getMaxPos() - form:getMinPos()
			local position = Vec2()

			if colorButton:getMaxPos().y + size.y > camera:getResolution().y then
				position.y = colorButton:getMinPos().y - size.y
			else
				position.y = colorButton:getMaxPos().y
			end
			
			if colorButton:getMinPos().x + size.x > camera:getResolution().x then
				position.x = camera:getResolution().x - size.x
			else
				position.x = colorButton:getMinPos().x
			end
			print("Position "..position.x..", "..position.y.."\n")
			form:setFormOffset(PanelSize(position, PanelSizeType.Pixel))
		end
	end
	
	function self.toogleVisible()
		print("Togle visible")
		form:setVisible(not form:getVisible())
		self.updatePosition()
	end
	
	function init()
		
		if not inColor then
			inColor = Vec3(1)
		end
		
		local camera = this:getRootNode():findNodeByName("MainCamera")
	
		form = Form( camera, PanelSize(Vec2(0.17,1), Vec2(3,2.1)), Alignment.TOP_LEFT);
	
		form:getPanelSize():setFitChildren(false, false);
		form:setLayout(FallLayout( Alignment.TOP_LEFT, PanelSize(Vec2(0.003),Vec2(1))));
		form:setRenderLevel(8)
		form:setVisible(false)
		form:setPadding(BorderSize(Vec4(0.003), true))
		form:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
		form:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize),true), MainMenuStyle.borderColor))
		form:addEventCallbackResized(self.updatePosition)
		
		local TitlePanel = form:add(Panel(PanelSize(Vec2(1.0, 0.09), PanelSizeType.ParentPercent)))
		TitlePanel:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		local xButton = TitlePanel:add(Button(PanelSize(Vec2(-1),Vec2(1)), "X", ButtonStyle.SQUARE))
		TitlePanel:add(Label(PanelSize(Vec2(-1)), "Color picker", MainMenuStyle.textColor, Alignment.MIDDLE_CENTER))
		
		xButton:setTextColor(Vec3(0.7))
		xButton:setTextHoverColor(Vec3(0.92))
		xButton:setTextDownColor(Vec3(1))
	
		xButton:setEdgeColor(Vec4(0), Vec4(0))
		xButton:setEdgeHoverColor(Vec4(0), Vec4(0))
		xButton:setEdgeDownColor(Vec4(0), Vec4(0))
		
		xButton:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
		xButton:setInnerHoverColor(Vec4(0), Vec4(0), Vec4(0))
		xButton:setInnerDownColor(Vec4(0), Vec4(0), Vec4(0))
	
		xButton:addEventCallbackExecute(self.toogleVisible)
	
	
		
		local topPanel = form:add(Panel(PanelSize(Vec2(1.0, 0.79), PanelSizeType.ParentPercent)))
		topPanel:setLayout(FlowLayout(PanelSize(Vec2(0.003),Vec2(1))))
		colorPicker = topPanel:add(ColorPicker(PanelSize(Vec2(1), Vec2(1),PanelSizeType.ParentPercent)))
		colorPicker:setColor(inColor)
		colorPicker:addEventCallbackChanged(changeColor)
		
		
		local rightPanel = topPanel:add(Panel(PanelSize(Vec2(-1))))
		rightPanel:setLayout(FallLayout(PanelSize(Vec2(0.003),Vec2(1))))
		local fixedColorPanel = rightPanel:add(Panel(PanelSize(Vec2(-1,-0.8))))
		fixedColorPanel:setLayout(GridLayout(6,6,PanelSize(Vec2(0.003),Vec2(1))))
		
		--Color table
		local colorTable = {Vec3(1,0.5,0.5),Vec3(1,1,0.5),Vec3(0.5,1,0.5),Vec3(0.5,1,1),Vec3(0.5,0.5,1),Vec3(1,0.5,1),
							Vec3(1,0,0),Vec3(1,1,0),Vec3(0,1,0),Vec3(0,1,1),Vec3(0,0,1),Vec3(1,0,1),
							Vec3(0.5,0.25,0.25),Vec3(0.5,0.5,0.25),Vec3(0.25,0.5,0.25),Vec3(0.25,0.5,0.5),Vec3(0.25,0.25,0.5),Vec3(0.5,0.25,0.5),
							Vec3(0.5,0,0),Vec3(0.5,0.5,0),Vec3(0,0.5,0),Vec3(0,0.5,0.5),Vec3(0,0,0.5),Vec3(0.5,0,0.5),
							Vec3(0.25,0,0),Vec3(0.25,0.25,0),Vec3(0,0.25,0),Vec3(0,0.25,0.5),Vec3(0,0,0.25),Vec3(0.25,0,0.25),
							Vec3(1),Vec3(0.8),Vec3(0.6),Vec3(0.4),Vec3(0.2),Vec3(0)}
		for i=1, 36 do
			local button = fixedColorPanel:add(Button(PanelSize(Vec2(-1)),"",ButtonStyle.SIMPLE))
			button:setBackground(Sprite(colorTable[i]))
			
			button:setEdgeColor(Vec4(0), Vec4(0))
			button:setEdgeHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
			button:setEdgeDownColor(Vec4(1,1,1,0.3), Vec4(1,1,1,0.3))
		
			button:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
			button:setInnerHoverColor(Vec4(1,1,1,0.4), Vec4(1,1,1,0.4), Vec4(1,1,1,0.4))
			button:setInnerDownColor(Vec4(1,1,1,0.3), Vec4(1,1,1,0.3), Vec4(1,1,1,0.3))
			
			button:setTag("table = "..tostring({colorTable[i]}))
			button:addEventCallbackExecute(buttonChangeColor)
		end

		
		--########################################
		
		colorPanel = rightPanel:add(Panel(PanelSize(Vec2(-1))))
		colorPanel:setBackground(Sprite(Vec3(1,0,0)))
		
		local textPanel = form:add(Panel(PanelSize(Vec2(-1))))
		
		local textPanelRed = textPanel:add(Panel(PanelSize(Vec2(-0.333,-1))))
		textPanelRed:add(Label(PanelSize(Vec2(-1),Vec2(2,1)),"Red  ",MainMenuStyle.textColor, Alignment.MIDDLE_RIGHT))
		textFieldRed = textPanelRed:add(TextField(PanelSize(Vec2(-1)), "255"))
		textFieldRed:setWhiteList("0123456789")
		textFieldRed:addEventCallbackChanged(textFieldChanged)
		
		local textPanelGreen = textPanel:add(Panel(PanelSize(Vec2(-0.5,-1))))
		textPanelGreen:add(Label(PanelSize(Vec2(-1),Vec2(2.3,1)),"Green  ",MainMenuStyle.textColor, Alignment.MIDDLE_RIGHT))
		textFieldGreen = textPanelGreen:add(TextField(PanelSize(Vec2(-1)), "255"))
		textFieldGreen:setWhiteList("0123456789")
		textFieldGreen:addEventCallbackChanged(textFieldChanged)
		
		local textPanelBlue = textPanel:add(Panel(PanelSize(Vec2(-1))))
		textPanelBlue:add(Label(PanelSize(Vec2(-1),Vec2(2,1)),"Blue  ",MainMenuStyle.textColor, Alignment.MIDDLE_RIGHT))
		textFieldBlue = textPanelBlue:add(TextField(PanelSize(Vec2(-1)), "255"))
		textFieldBlue:setWhiteList("0123456789")
		textFieldBlue:addEventCallbackChanged(textFieldChanged)
		
		changeColor(colorPicker)
	end

	colorButton = inParentPanel:add(Button(panelSize,"",ButtonStyle.SIMPLE))

	init()
	
	

	colorButton:setEdgeColor(Vec4(Vec3(0.6),1.0), Vec4(Vec3(0.6),1.0))
	colorButton:setEdgeHoverColor(Vec4(Vec3(0.8),1.0), Vec4(Vec3(0.8),1.0))
	colorButton:setEdgeDownColor(Vec4(Vec3(0.7),1.0), Vec4(Vec3(0.7),1.0))
	
	colorButton:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
	colorButton:setInnerHoverColor(Vec4(Vec3(0.6),0.4), Vec4(Vec3(0.6),0.4), Vec4(Vec3(0.6),0.4))
	colorButton:setInnerDownColor(Vec4(0), Vec4(0), Vec4(0))
	
	colorButton:addEventCallbackExecute(self.toogleVisible)
	
	
	function self.setVisible(visible)
		form:setVisible(visible)
	end
	
	function self.getColor()
		return colorPicker:getColor()
	end
	
	
	
	function self.update()
		
		if form:getVisible() then
			
			--check if the a mouse click was done outside the color picker and it's parent panel
			if Core.getInput():getMouseDown(MouseKey.left) then
				local mousePos = Core.getInput():getMousePos()
				if colorButton:getMinPos().x > mousePos.x or colorButton:getMinPos().y > mousePos.y or colorButton:getMaxPos().x < mousePos.x or colorButton:getMaxPos().y < mousePos.y then
					if form:getMinPos().x > mousePos.x or form:getMinPos().y > mousePos.y or form:getMaxPos().x < mousePos.x or form:getMaxPos().y < mousePos.y then
						--hide the color picker
						form:setVisible(false)					
					end					
				end
			end
			form:update()
		end
	end
		
	return self, colorButton
end