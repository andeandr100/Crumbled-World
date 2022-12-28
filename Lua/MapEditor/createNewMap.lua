require("MapEditor/listener.lua")
--this = SceneNode()
CreateNewMap = {}


function CreateNewMap.newMap()
	
	--Destroy the old world when create a new
	local oldPlayerNode = this:findNodeByType(NodeId.playerNode)
	if oldPlayerNode then
		oldPlayerNode:destroy()
	end
		
		
	print("\n\nNew map event\n")
	--Push event a new map has been created
	editorListener:pushEvent("newMap")	
			
	--Create a new world
	local playerNode = Editor.createNewMap()
	
	--load all script to the world
	playerNode:loadLuaScript("Game/camera.lua");					--In game camera
	playerNode:loadLuaScript("Game/builder.lua");					--Builder script, allows user to build towers
	playerNode:loadLuaScript("Game/stats.lua");						
	playerNode:loadLuaScript("Menu/towerMenu.lua");					--tower menu shows on the left
	playerNode:loadLuaScript("Menu/statsMenu.lua");					--Top menu
	playerNode:loadLuaScript("Menu/selectedMenu.lua");				--Selected tower menu show in down right corner of the screen
	playerNode:loadLuaScript("Menu/FPS.lua");						--DEBUG shows FPS, default Invisible in release 
	playerNode:loadLuaScript("Menu/WorkMonitor.lua");				--Debug monitor shows CPSU usage for ingame threads
	playerNode:loadLuaScript("Game/event.lua");						--event system, spawns npc from protals
	playerNode:loadLuaScript("Game/LifeBars.lua");					--update and render lifeBars for all npc's
	playerNode:loadLuaScript("Menu/log.lua");						--DEBUG
	playerNode:loadLuaScript("Menu/logCrash.lua");					--DEBUG
	playerNode:loadLuaScript("Game/soulManager.lua");				--targeting system
	playerNode:loadLuaScript("Menu/runningScripts.lua");			--debug logger show all running scripts
	playerNode:loadLuaScript("Menu/console.lua");					--In game console not used any more really
	playerNode:loadLuaScript("Menu/inGameMenu.lua");				--Menu for option, quit to menu, and quit to game
	playerNode:loadLuaScript("Enviromental/sunLight.lua");			--Sunlight script
	playerNode:loadLuaScript("Game/timeSync.lua");					--Used in multiplayer to sync up time, when frame rate goes under 10FPS
	
	
	local grassNode = playerNode:addChild(SceneNode.new("Grass node"))
	local script = grassNode:loadLuaScript("Enviromental/grass.lua")	--Enable grass to be loaded and edited
	script:update()
	
	local navmeshDirectionNode = playerNode:addChild(SceneNode.new("Navmesh direction node"))
	local NavmhesDirectionscript = navmeshDirectionNode:loadLuaScript("Enviromental/navmeshDirection.lua")	--Enable navmesh direction to be loaded and edited
	NavmhesDirectionscript:update()
	
	local pathNode = playerNode:addChild(SceneNode.new("Path node"))
	local pathScript = pathNode:loadLuaScript("MapEditor/pathNode.lua")	--Path node system. keeps inforamtion about spawn, end crystal waypoints, paths and mine cart path.
	pathScript:update()
	
	
end