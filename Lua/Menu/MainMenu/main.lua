require("Menu/settings.lua")

--this = SceneNode()
function create()
	
	local language = Language()
	language:setGlobalLanguage(Settings.Language.getSettings())

	
	this:loadLuaScriptAndRunOnce("settings.lua")
	

	Core.setSounMasterGain(Settings.soundMasterGain.getGain())
	Core.setSounEffectGain(Settings.soundEffectGain.getGain())
	Core.setSoundMusicGain(Settings.soundMusicGain.getGain())
	
	--load main menu world
	this:loadScene("Data/Map/hidden/menuWorld.map")
	--load main menu camera
	this:loadLuaScript("Camera/mainMenuCamera.lua")
	
	local mainMenuNode = this:addChild(SceneNode())
	mainMenuNode:createWork()
	
	mainMenuNode:loadLuaScript("Menu/MainMenu/mainMenu.lua")
	mainMenuNode:loadLuaScript("Menu/MainMenu/version.lua")

	--shut down script
	return false
end

function update()
	
	return false
end