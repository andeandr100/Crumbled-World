require("Menu/settings.lua")

--this = SceneNode()
function create()
	
	print("1")
	local language = Language()
	language:setGlobalLanguage(Settings.Language.getSettings())

	print("2")
	this:loadLuaScriptAndRunOnce("settings.lua")
	
	print("3")
	Core.setSounMasterGain(Settings.soundMasterGain.getGain())
	Core.setSounEffectGain(Settings.soundEffectGain.getGain())
	Core.setSoundMusicGain(Settings.soundMusicGain.getGain())
	print("4")
	--load main menu world
	this:loadScene("Data/Map/hidden/menuWorld.map")
	print("5")
	
	--load main menu camera
	this:loadLuaScript("Camera/mainMenuCamera.lua")
	
	print("6")
	local mainMenuNode = this:addChild(SceneNode.new())
	mainMenuNode:createWork()
	
	print("7")
		
	mainMenuNode:loadLuaScript("Menu/MainMenu/mainMenu.lua")
	mainMenuNode:loadLuaScript("Menu/MainMenu/version.lua")

	--shut down script
	return false
end

function update()
	
	return false
end