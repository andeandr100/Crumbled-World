require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()
MapSettings = {}

function setDeafultValue(name, value)
	if MapSettings[name] == nil then
		MapSettings[name] = value
	end
end

function changeItem(button)
	local playerId = tonumber(button:getTag():toString())
	
	if playerId > 0 then
		currentCameraToChange = playerId
		cameraPlayerComboBox:setText("player "..playerId)
		defaultCameraPos.changeCamera(playerId)
	else
		currentCameraToChange = 0
		cameraPlayerComboBox:setText("default")
		defaultCameraPos.changeCamera(0)
	end
end

function updateCameraPlayerComboBox()
	if not currentNumPlayersinBox or currentNumPlayersinBox ~=  MapSettings.players then
		currentNumPlayersinBox =  MapSettings.players
		cameraPlayerComboBox:setVisible(currentNumPlayersinBox > 1)
		
		cameraPlayerComboBox:clearItems()
		local button = cameraPlayerComboBox:addItem(MainMenuStyle.createMenuButton( Vec2(-1,0.025), Vec2(), "default"))
		button:setTag("0")
		button:addEventCallbackExecute(changeItem)
		
		for i=1, MapSettings.players do
			button = cameraPlayerComboBox:addItem(MainMenuStyle.createMenuButton( Vec2(-1,0.025), Vec2(), "player "..i))
			button:setTag(tostring(i))
			button:addEventCallbackExecute(changeItem)
		end
		
		currentCameraToChange = 0
		cameraPlayerComboBox:setText("default")
	end
end

function saveMapSettings()
	--ops this should not be here TODO
	MapSettings.name = nameField:getText()
	MapSettings.difficultyMin = tonumber(difficultyFieldMin:getText())
	MapSettings.difficultyMax = tonumber(difficultyFieldMax:getText())
	MapSettings.waveCount = tonumber(waveCountField:getText())
	MapSettings.gameMode = gameModeField:getText():toString()
	MapSettings.players = playersField:getInt()
	
	updateCameraPlayerComboBox()
	
	local nodeId = this:findNodeByType(NodeId.fileNode)
	if nodeId then
		nodeId:addFileData("info.txt", "table = "..tostring(MapSettings))
	end
end