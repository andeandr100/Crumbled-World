require("MapEditor/Tools/Tool.lua")
--this = SceneNode()

function create()
	Tool.create()
	
	return true
end

--Called when the tool has been activated
function activated()
	
end

--Called when tool is being deactivated
function deActivated()
	
end

function update()
	
	Tool.trySelectNewScene()
	
	Tool.update()
	
	return true
end