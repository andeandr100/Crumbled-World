require("Menu/loadingInfo.lua")
--this = SceneNode()

function destroy()
	camera:destroy()
	camera = nil
end

function create()
	
	camera = Camera.new("loading screen camera", false)
	Core.setMainCamera(camera)
	
	local files = File("Data/Images/LoadingScreen"):getFiles()
		
	
	texture = Core.getTexture("Black")
	if #files > 0 then
		local file = nil
		for i=1, 5 do
			file = files[math.randomInt(1,#files)]
			if file:isFile() then
				--break
				i=6
			end
		end
		if file:isFile() then
			texture = Core.getTexture(file:getPath())
		end
	end
	

	
	background = Sprite(texture)
	borderTop = Sprite(Vec3(0))
	borderBottom = Sprite(Vec3(0))


	movingObj = Sprite(Core.getTexture("icon_table"))
	movingObj:setAnchor(Anchor.MIDDLE_CENTER)
	movingObj:setUvCoord(Vec2(0.775,0.0625), Vec2(1.0,0.1875))
	
	
	info = {
		"Turtles shield will stop incoming projectile",
		"Missile and swarm balls will detonate upon the turtles shield",
		"Swarm tower takes about 8 seconds of continuously firing to do maximum damage",
		"Mingun, arrow and cutter tower can't shot thru skeletons tower shield",
		"Boost towers to clear hard waves",
		"Gold saved is increased when an enemy is killed",
		"Swarm tower can't attack fire spirit",
		"Electric tower don't attack electric spirit"
	}
	
	textNode = TextNode()
	textNode:setColor(Vec3(1.0))
--	textNode:setAnchor(Anchor.MIDDLE_CENTER)
--	textNode:setAlignment(Anchor.MIDDLE_CENTER)
	textNode:setText(info[ math.randomInt(1, #info)])
	
	
	local scene = Scene2DNode()
	scene:addChild( background )
	scene:addChild( borderTop )
	scene:addChild( borderBottom )
	scene:addChild( movingObj )
--	scene:addChild( textNode )
	camera:add2DScene(scene)
	
	resize()
	
	
	
	return true
end

function resize()
	
	
	winResolution = Core.getScreenResolution()
	
	--set background image position and size
	local backgroundSize = Vec2(winResolution.x, winResolution.x * (texture:getSize().y/texture:getSize().x));
	local backgroundStartPos = Vec2(0.0, winResolution.y * 0.5 - backgroundSize.y * 0.5);
	background:setPosition(backgroundStartPos);
	background:setSize( backgroundSize);
	
	--ether set border height to 14% of render resolution or to remainging size after backgrounden is remomed
	local borderHeight = math.max( (winResolution.y-backgroundSize.y) * 0.5, winResolution.y * 0.14)
	
	borderTop:setLocalPosition(Vec2())
	borderTop:setSize(Vec2(winResolution.x, borderHeight))
	borderBottom:setLocalPosition(Vec2(0.0, winResolution.y - borderHeight))
	borderBottom:setSize(Vec2(winResolution.x, borderHeight))
	

	local winRes = Core.getScreenResolution()
	local height = winRes.y * 0.07
	movingObj:setSize(Vec2(height))
	movingObj:setPosition(winRes - Vec2(height))
	
	
	
	textNode:setTextHeight(math.max(8, winRes.y * 0.025 ))
	textNode:setSize(Vec2(winRes.x * 0.8, height))	
	textNode:setLocalPosition(Vec2(winRes.x * 0.5, winRes.y - height) - textNode:getTextSize() * 0.5)
	
end

function update()
	
	if Core.getMainCamera() ~= camera then
		return false
	end
	
	local rad = Core.getGameTime() * math.pi
	local localMat = Matrix(Vec3(movingObj:getLocalPosition(), 0))
	localMat:rotate(Vec3(0,0,1), rad - (rad % (math.pi / 6)))
	movingObj:setLocalMatrix(localMat)
	
	camera:render()
	
	return true
end