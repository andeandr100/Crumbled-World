require("Menu/settings.lua")

--this = SceneNode()
function create()
	
	LOG("=== LOAD LANGUAGE ===")
	local language = Language()
	language:setGlobalLanguage(Settings.Language.getSettings())

	LOG("=== LOAD SETTINGS ===")
	this:loadLuaScriptAndRunOnce("settings.lua")
	
	LOG("=== FIX SOUND SETTINGS ===")
	Core.setSounMasterGain(Settings.soundMasterGain.getGain())
	Core.setSounEffectGain(Settings.soundEffectGain.getGain())
	Core.setSoundMusicGain(Settings.soundMusicGain.getGain())
	LOG("=== FIX SOUND SETTINGS ===")
	--load main menu world
	this:loadScene("Data/Map/hidden/menuWorld.map")
	LOG("=== FIX MAIN MENU CAMERA ===")
	
	--load main menu camera
	this:loadLuaScript("Camera/mainMenuCamera.lua")
	
	LOG("=== CREATE MAIN SCENENODE ===")
	local mainMenuNode = this:addChild(SceneNode.new())
	mainMenuNode:createWork()
	
	LOG("=== LOAD MENU ===")
		
	mainMenuNode:loadLuaScript("Menu/MainMenu/mainMenu.lua")
	mainMenuNode:loadLuaScript("Menu/MainMenu/version.lua")
	
	LOG("=== DONE ===")

	--shut down script
	return false
end

function update()
	
	return false
end