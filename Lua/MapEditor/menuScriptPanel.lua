require("MapEditor/listener.lua")
--this = SceneNode()
MenuScriptPanel = {}

function openAndShowScriptFile(button)
	if not comUnit then
		comUnit = Core.getComUnit()
	end
	comUnit:sendTo("LuaTextEditor","showFile",button:getTag():toString())
	
	editorListener:pushEvent("window", "TextEditor:Show")
end

local function splitString(str,sep)
	--str = string()
	--sep = string()
	local array = {}
	local reg = string.format("([^%s]+)",sep)
	local numElement = 0
	for mem in string.gmatch(str,reg) do
		table.insert(array, mem)
		numElement = numElement + 1
	end	
	return array, numElement
end

function openAFileWindow(button)
	local camera = this:getRootNode():findNodeByName("MainCamera")
	--camera = Camera()
	fileWindow = FileWindow( camera, Text("Open script"), Text("Data/") )
	fileWindow:setDefaultFileData(Text("function create()\n\t\nend\n\nfunction update()\n\t\n\treturn false\nend\n"))
	fileWindow:addLuaScriptCallbackExecute("addLuaScriptFile")
	
	print("open File Window\n")
end

function addLuaScriptFile(fileName)
	--fileName = Text()
	print("Script file name: "..fileName:toString().."\n")

	local subString = splitString(fileName:toString(), "/")
	local scriptName = subString[#subString]:gsub(".lua","")
	print("Script name: "..scriptName.."\n")
	
	MenuScriptPanel.addScript(scriptName,fileName:toString())
	if MenuScriptPanel.functionAddCallback ~= nil then
		MenuScriptPanel.functionAddCallback(fileName:toString())
	end
end

function removeScript(button)
	
	if MenuScriptPanel.functionRemoveCallback ~= nil then
		MenuScriptPanel.functionRemoveCallback(button:getParent():getTag():toString())
	end
	
	scriptPanel:removePanel(button:getParent())
end

function MenuScriptPanel.createScriptPanel( panel, functionAddCallback, functionRemoveCallback )
	panel:add(Label(PanelSize(Vec2(-1, 0.025)), "Scripts:", Vec3(1)))
	scriptPanel = panel:add(Panel(PanelSize(Vec2(-1,1))))
	scriptPanel:getPanelSize():setFitChildren(false, true)
	scriptPanel:setBackground(Sprite(Vec4(0.3)))
	scriptPanel:setPadding(BorderSize(Vec4(0.00125)))
	scriptPanel:setBorder(Border(BorderSize(Vec4(0.00125)), Vec3(0)))
	addScriptButton = panel:add(Button(PanelSize(Vec2(1,0.025), Vec2(3,1)),"Add"))
	
	MenuScriptPanel.functionAddCallback = functionAddCallback
	MenuScriptPanel.functionRemoveCallback = functionRemoveCallback
	addScriptButton:addEventCallbackExecute(openAFileWindow)

end

function MenuScriptPanel.setScriptListString(fileNameList)

	print("Set script list\n")
	for i=1, #fileNameList do
		
		local fileName = fileNameList[i]
		local subString = splitString(fileName, "/")
		local scriptName = subString[#subString]:gsub(".lua","")
		
		print("script: "..scriptName.."\n")
		local panelIndex = i-1
		if scriptPanel:getNumPanel() > panelIndex then
			scriptPanel:getPanel(panelIndex):setText(scriptName)
			scriptPanel:getPanel(panelIndex):setTag(fileName)
		else
			MenuScriptPanel.addScript(scriptName, fileName)
		end
	end
	for i=scriptPanel:getNumPanel()-1, #fileNameList, -1 do
		print("remove script text row\n")
		scriptPanel:removePanel(scriptPanel:getPanel(i))
	end
end

function MenuScriptPanel.setScriptList(scriptList)

	print("Set script list, size: "..tostring(#scriptList).."\n")
	for i=1, #scriptList do
		print("script: "..scriptList[i]:getName().."\n")
		local panelIndex = i-1
		if scriptPanel:getNumPanel() > panelIndex then
			scriptPanel:getPanel(panelIndex):setText(scriptList[i]:getName())
			scriptPanel:getPanel(panelIndex):setTag(scriptList[i]:getFileName())
		else
			MenuScriptPanel.addScript(scriptList[i]:getName(), scriptList[i]:getFileName())
		end
	end
	for i=scriptPanel:getNumPanel()-1, #scriptList, -1 do
		print("remove script text row\n")
		scriptPanel:removePanel(scriptPanel:getPanel(i))
	end
end

function MenuScriptPanel.addScript(scriptName, fileName)

	local aButton = scriptPanel:add(Button(PanelSize(Vec2(-1, 0.025)), scriptName, ButtonStyle.SQUARE))
	aButton:setTag(fileName)
	aButton:setTextAnchor(Anchor.MIDDLE_LEFT)
	aButton:setEdgeColor(Vec4())
	aButton:setEdgeHoverColor(Vec4())
	aButton:setEdgeDownColor(Vec4())
	aButton:setInnerColor(Vec4())
	aButton:setTextColor(Vec3(1))
	aButton:setInnerHoverColor(Vec4(0,0,0,0.5))	
	aButton:setInnerDownColor(Vec4(0,0,0,1))
	aButton:addEventCallbackExecute(openAndShowScriptFile)
	--aButton:addEventCallbackExecute("togleTextEditor")
	
	aButton:setLayout(FlowLayout(Alignment.TOP_RIGHT))
	local xButton = aButton:add(Button(PanelSize(Vec2(-1), Vec2(1)), "X", ButtonStyle.SQUARE))
	xButton:setEdgeColor(Vec4())
	xButton:setEdgeHoverColor(Vec4())
	xButton:setEdgeDownColor(Vec4())
	xButton:setInnerColor(Vec4())	
	xButton:setTextColor(Vec3(1))	
	xButton:setInnerHoverColor(Vec4(0.35,0.35,0.35,1))	
	xButton:setInnerDownColor(Vec4(0,0,0,1))
	xButton:addEventCallbackExecute(removeScript)	
end