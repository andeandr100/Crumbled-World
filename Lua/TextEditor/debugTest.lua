--this = SceneNode()

--this function is called when the test world is loaded
function create()
	local island = this:findNodeByTypeTowardsLeafe(NodeId.island)		
	box = Core.getModel("box1.mym")
	island:addChild(box:toSceneNode());
	return true
end

--called when a new run/execution of a script is called
function run()
	box:loadLuaScript("jump")
end

--called after a run when lua script has crashed, shutdown or manualy stop or reRun is called
function cleanUp()
	box:removeScript(Text("jump"))
	box:setLocalPosition(Vec3())
	--return false if the world should be destroyed else
	--return true if world is ready for another script
	return true	
end

function update()
	box:render();
	--always return true
	return true
end