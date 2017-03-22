
require("MapEditor/exportForm.lua")
require("MapEditor/listener.lua")
--this = SceneNode()

function quitForm(button)
	form:setVisible(false)
end

function okButtonPressed(button)
	local fileName = fileNameTextField:getText():toString()
	if fileName:len() > 0 then
		saveFileName = fileName
		if stateIsSaveToFile then
			Editor.save("Data/MapEditor/"..saveFileName..".map")
		else
			Editor.load("Data/MapEditor/"..saveFileName..".map")
			editorListener:pushEvent("loadedMap")
		end
		
		form:setVisible(false)
	end
end

function selectFile(button)
	fileNameTextField:setText(button:getText())
end

function showSave()
	stateIsSaveToFile = true
	loadFileList()
	label:setText("Save to File")
	form:setVisible(true)
end

function showLoad()
	stateIsSaveToFile = false
	loadFileList()
	label:setText("Load from File")
	form:setVisible(true)
end

function save()
	if string.len(saveFileName) > 0 then
		Editor.save("Data/MapEditor/"..saveFileName..".map")
	else
		showSave()
	end
end


function openExportWindow()
	
	local bilboard = Core.getGlobalBillboard("MapEditor")
	bilboard:setSceneNode("RootNode", this:getRootNode())
	
	print("openExportWindow fileName: "..saveFileName.."\n")
	if string.len(saveFileName) > 0 then
		if not export then
			export = ExportForm.new()
		end
		export.export("Data/Map/"..saveFileName..".map")
	end

end

function loadFileList()
	local saveFolder = Core.getDataFolder("MapEditor")
	fileList = saveFolder:getFiles()
	filePanel:clear()

	for i=1, #fileList do
		local fileButton = filePanel:add(Button(PanelSize(Vec2(-1,0.025)), fileList[i]:getName()))
		fileButton:setTextColor(Vec3(1))
		fileButton:setEdgeColor(Vec4(0), Vec4(0))
		fileButton:setEdgeHoverColor(Vec4(0), Vec4(0))
		fileButton:setEdgeDownColor(Vec4(0), Vec4(0))

		fileButton:setInnerColor(Vec4(0), Vec4(0), Vec4(0))
		fileButton:setInnerHoverColor(Vec4(0.4,0.4,0.4,0.95), Vec4(0,0,0,0.975), Vec4(0.4,0.4,0.4,0.95))
		fileButton:setInnerDownColor(Vec4(0.4,0.4,0.4,0.95), Vec4(0,0,0,0.99), Vec4(0.4,0.4,0.4,0.95))

		fileButton:addEventCallbackExecute(selectFile)
	end
end

function showWindow(windoName)
	if windoName == "saveWindow" then
		showSave()
	elseif windoName == "loadWindow" then
		showLoad()
	elseif windoName == "save" then
		save()
	elseif windoName == "export" then
		openExportWindow()
	else
		form:setVisible(false)
	end
end

function setMapPath(path)
	saveFileName = path
end


function newMap()
	--new map has been created no file save location has been chocsen
	print("\n\n\n ==== NEW MAP ==== n\n\n\n")
	saveFileName = ""
end
	
function create()
	
	editorListener:registerEvent("newMap", newMap)
	editorListener:registerEvent("window", showWindow)
	editorListener:registerEvent("setMapPath", setMapPath)
	
	local keyBinds = Core.getBillboard("keyBind");
	keybindSave = keyBinds:getKeyBind("save")
	keybindSaveAs = keyBinds:getKeyBind("save as")
	keybindLoad = keyBinds:getKeyBind("load")
	keybindExport = keyBinds:getKeyBind("export")	
	

	--camera = Camera()
	local camera = this:getRootNode():findNodeByName("MainCamera")
	
	input = Core.getInput()

	saveFileName = ""

	stateIsSaveToFile = true

	if camera then
		form = Form( camera, PanelSize(Vec2(0.2,-1)), Alignment.MIDDLE_CENTER);
		form:setBackground(Sprite(Vec4(0.17, 0.17, 0.17, 0.7)));
		form:setLayout(FlowLayout());
		form:setBorder(Border(BorderSize(Vec4(0.005)), Vec4(0,0,0,0),Vec4(0,0,0,1)));
		form:setPadding(BorderSize(Vec4(0.005)));
		form:getLayout():setPanelSpacing(PanelSize(Vec2(0.005)));
		form:getPanelSize():setFitChildren(false, true);
		form:setVisible(false)


		label = form:add(Label(PanelSize(Vec2(-1,0.025)), "Save to File", Vec3(1)))
		label:setLayout(FlowLayout(Alignment.TOP_RIGHT))
		quitButton = label:add(Button(PanelSize(Vec2(-1),Vec2(1)),"X", ButtonStyle.SQUARE))
		filePanel = form:add(Panel(PanelSize(Vec2(-1,0.025 * 12))))
		filePanel:setLayout(FallLayout())
		filePanel:setEnableYScroll()
		filePanel:setBorder(Border(BorderSize(Vec4(0.002)), Vec4(0,0,0,1)))
		filePanel:setBackground(Sprite(Vec4(0.4,0.4,0.4,0.95)))
		fileNameTextField = form:add(TextField(PanelSize(Vec2(0.15,0.025))))
		okButton = form:add(Button(PanelSize(Vec2(-1,0.025)),"okej"))

		quitButton:addEventCallbackExecute(quitForm)
		okButton:addEventCallbackExecute(okButtonPressed)
	end
	return true
end

function update()
	if not Core.getPanelWithKeyboardFocus() then
		if keybindSaveAs:getPressed() then
			showSave()
		elseif keybindSave:getPressed() then
			save()
		elseif keybindExport:getPressed() then
			openExportWindow()
		elseif keybindLoad:getPressed() then
			showLoad()
		end
	end
	
	form:update()
	
	if export then
		export.update()
	end

	return true
end