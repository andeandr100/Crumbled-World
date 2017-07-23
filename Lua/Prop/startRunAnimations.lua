--this = Model()
function create()
	if this:getAnimation() then
		this:getAnimation():play("run",1,PlayMode.stopSameLayer)
		this:setEnableUpdates(true)
	else
		error("no animations found for this=="..tostring(this).."\n")
	end
	return true
end
function update()
	this:getAnimation():update(Core.getDeltaTime())
	return true
end