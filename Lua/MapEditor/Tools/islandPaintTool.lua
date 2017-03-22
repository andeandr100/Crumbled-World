require("MapEditor/Tools/Tool.lua")
require("MapEditor/menuStyle.lua")
require("MapEditor/Tools/circleModel.lua")
require("MapEditor/textureSelectionMenu.lua")

function destroy()
	if textureSelectionMenu then
		textureSelectionMenu.destroy()
	end
end

function replaceTexture(textureName)
	if paintConfig["Texture"..changeTextureId] == textureName then
		--Texture was not changed
		return
	end
	--Texture has been changed
	paintConfig["Texture"..changeTextureId] = textureName
	
	local texture = Core.getTexture(textureName)
	textureButton[changeTextureId]:setTexture( texture )
	
	toolConfig:get("islandPaintbrushTool"):setTable(paintConfig)
	toolConfig:save()
	
	--Replace all textures on all islands
	local islands = this:getRootNode():findAllNodeByTypeTowardsLeaf(NodeId.island)
	for i=1, #islands do
		islands[i]:setIslandTexture(changeTextureId, texture)
	end	
end

--this = SceneNode()
function changeTexture(button)
	textureId = tonumber(button:getTag():toString())
end

function showTextureSelectMenu(button)
	changeTextureId = tonumber(button:getTag():toString())
	textureSelectionMenu.setVisible(true)
end

function addButtonTexture(buttonPanel, textureName, tag)
	local texture = Core.getTexture(textureName)
	
	local panelWidthFor4 = toolAndSettingMenuSize - 0.005 * 3 - 0.005
	local buttonWidth = panelWidthFor4 * 0.25

	local button = buttonPanel:add(Button(PanelSize(Vec2(buttonWidth,1), Vec2(1)), ButtonStyle.SQUARE, texture, Vec2(), Vec2(1)))
	button:setInnerColor(Vec4(0),Vec4(0), Vec4(0))
	button:setInnerHoverColor(Vec4(0,0,0,0),Vec4(1,1,1,0.25), Vec4(1,1,1,0.25))
	button:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
	button:setTag(tag)
	button:addEventCallbackExecute(changeTexture);
	
	return button
end

function changeSettings(textField)
	if paintConfig[textField:getTag():toString()] then
		paintConfig[textField:getTag():toString()] = textField:getFloat()
	end
	
	if textField:getTag():toString() == "range" then
		CircleModel.create(paintConfig.range)
	end
	
	
	toolConfig:get("islandPaintbrushTool"):setTable(paintConfig)
	toolConfig:save()
end

function createMenu(panel)
	
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Range", Vec3(1)))
	textFieldRange = panel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), tostring(paintConfig.range)))
	textFieldRange:setWhiteList(".0123456789")
	textFieldRange:addEventCallbackExecute(changeSettings)
	textFieldRange:setTag("range")
	
	panel:add(Label(PanelSize(Vec2(-0.66, MenuStyle.rowHeight)),"Power", Vec3(1)))
	textFieldPower = panel:add(TextField(PanelSize(Vec2(-1, MenuStyle.rowHeight)), tostring(paintConfig.power)))
	textFieldPower:setWhiteList(".0123456789")
	textFieldPower:addEventCallbackExecute(changeSettings)
	textFieldPower:setTag("power")
	
	local buttonPanel = panel:add(Panel(PanelSize(Vec2(-1,-1),Vec2(4,1))))
	buttonPanel:setLayout(GridLayout(1,4,Alignment.TOP_RIGHT))
	
	textureButton = {}
	textureButton[1] = addButtonTexture(buttonPanel, paintConfig["Texture1"], "0")
	textureButton[2] = addButtonTexture(buttonPanel, paintConfig["Texture2"], "1")
	textureButton[3] = addButtonTexture(buttonPanel, paintConfig["Texture3"], "2")
	
	local buttonChangeTexturePanel = panel:add(Panel(PanelSize(Vec2(1,1),Vec2(4,0.3),PanelSizeType.ParentPercent)))
	buttonChangeTexturePanel:setLayout(GridLayout(1,4))
		
	for i=1, 3 do
		local button = buttonChangeTexturePanel:add(Button(PanelSize(Vec2(-1)), "Change"))
		button:addEventCallbackExecute(showTextureSelectMenu)
		button:setTag(tostring(i))
	end
	
	--Needed for an panel ERROR
	local buttonPanel = panel:add(Panel(PanelSize(Vec2(-1,-1),Vec2(8,1))))

end

function setDefaultValue(name, value)
	if not paintConfig[name] then
		paintConfig[name] = value
	end
end


function create()
	
	textureId = 1

	Tool.create()
	Tool.enableChangeOfSelectedScene = false
	
	textureSelectionMenu = TextureSelectionMenu.new(replaceTexture)

	--Get billboard for the map editor
	local mapEditor = Core.getBillboard("MapEditor")
	--Get the Tool panel
	local toolPanel = mapEditor:getPanel("ToolPanel")
	--Get the setting panel
	local settingsPanel = mapEditor:getPanel("SettingPanel")
	
	camera = this:getRootNode():findNodeByType(NodeId.camera)
		
	--Load config
	toolConfig = Config("ToolsSettings")
	--Get the ligt tool config settings
	paintConfig = toolConfig:get("islandPaintbrushTool"):getTable()
	
	setDefaultValue("range", 2)
	setDefaultValue("power", 2.5)
	setDefaultValue("Texture1", "gt_grass_d.dds")
	setDefaultValue("Texture2", "gt_dirtgrass_d.dds")
	setDefaultValue("Texture3", "gt_dirt_d.dds")

	
	CircleModel.init()
	CircleModel.create( paintConfig.range )
	CircleModel.mesh:setVisible(false)
	
	if settingsPanel then
		titlePanel, bodyPanel =  MenuStyle.createTitleAndBody(settingsPanel, "Paint tool")
		
		--body = Panel()
		titlePanel:setVisible(false)
		createMenu(bodyPanel)
	end
	
	
	editorListener = Listener("Editor")
	editorListener:registerEvent("newMap", newMap)
	editorListener:registerEvent("loadedMap", loadedMap)
	return true
end

function newMap()

end

function loadedMap()
	local island = this:getRootNode():findNodeByTypeTowardsLeafe(NodeId.island)
	--island = Island()
	if island then
		for i=1, 3 do
			local texture = island:getIslandTexture(i)
			changeTextureId = i
			replaceTexture(texture:getName():toString())
		end
	end
end

function Loaded(inTable)
	deActivated()
end



--Called when the tool has been activated
function activated()
	titlePanel:setVisible(true)
	CircleModel.mesh:setVisible(true)
end

--Called when tool is being deactivated
function deActivated()
	titlePanel:setVisible(false)
	CircleModel.mesh:setVisible(false)
	
end

--As long as the tool is active update is caled
function update()
	textureSelectionMenu.update()

	--Do collision check
	local island, collisionPos, collisionNormal = Tool.getCollision(false, false)
	--island = Island()
	
	if island then
		CircleModel.setPosition(collisionPos, Vec3(0,1,0))
		CircleModel.mesh:setVisible(true)
	else
		CircleModel.mesh:setVisible(false)
	end
	

	if island and Core.getInput():getMouseHeld(MouseKey.left) then
		

		
		if textureId == 0 then
			island:setPaintBrushColor(Vec3(1,0,0))
		elseif textureId == 1 then
			island:setPaintBrushColor(Vec3(0,1,0))
		elseif textureId == 2 then
			island:setPaintBrushColor(Vec3(0,0,1))
		end
		island:paint(collisionPos, paintConfig.range, Core.getDeltaTime() * paintConfig.power)
	elseif island then
		
	end
	
	
	--Update basic tool
	Tool.update()
		
	return true
end