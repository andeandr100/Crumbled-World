require("Mod/camera.lua")

Player = {}
function Player.new()
	local self = {}
	local movementSpeed = 5
	local position = Vec3()
	local matrix = Matrix()
	local player = SceneNode()
	local model = Core.getModel("npc_human.mym")
	local activeMoveAnimation = ""
	local pi = math.pi
	
	local function init()
		this:addChild(player)
		player:addChild(model)
		position = player:getLocalPosition()
		camera = NodeCamera.new(player)
	end
	init()
	
	local function setMoveAnimation(runAnimation)
		if activeMoveAnimation~=runAnimation then
			model:getAnimation():stop(activeMoveAnimation)
			activeMoveAnimation = runAnimation
			if runAnimation~="" then
				print("setMoveAnimation("..runAnimation..")")
				model:getAnimation():play(runAnimation,2.0,PlayMode.stopSameLayer)
			else
				print("setMoveAnimation()")
			end
		end
	end
	
	function self.update()
		--xz movement
		local direction = Vec3()
		if Core.getInput():getKeyHeld(Key.w) then
			direction = direction + Vec3(0,0.0,1)
		end
		if Core.getInput():getKeyHeld(Key.s) then
			direction = direction + Vec3(0,0,-1)
		end
		if Core.getInput():getKeyHeld(Key.a) then
			direction = direction + Vec3(1,0,0)
		end
		if Core.getInput():getKeyHeld(Key.d) then
			direction = direction + Vec3(-1,0,0)
		end
		direction:normalize()
		position = position + (direction*Core.getDeltaTime()*movementSpeed)

		--targeting position
		local aline3D = camera.getWorldLineFromScreen()
		local collPos = Vec3()
		if aline3D then
			Collision.lineSegmentPlaneIntersection(collPos, aline3D, Vec3(0,1,0), Vec3() )
		else
			Core.addDebugLine(Vec3(),Vec3(0,2,0),0,Vec3(1,0,0))
		end
		local targetVec = collPos-position
		if targetVec:length()>0.1 then
			targetVec:normalize()
			matrix:createMatrix(targetVec,Vec3(0.0, 1.0, 0.0))
		end
		
		--animation
		if direction:length()>0.1 and targetVec:length()>0.1 then
			local angle = math.atan2((direction.x*targetVec.z)-(direction.z*targetVec.x),(direction.x*targetVec.x)+(direction.z*targetVec.z))
			if angle>pi*-0.25 and angle<pi*0.25 then
				setMoveAnimation("walkForward")
			elseif angle<pi*-0.75 or angle>pi*0.75 then
				setMoveAnimation("walkBackward")
			elseif angle<-0.1 then
				setMoveAnimation("walkRight")
			elseif angle>0.1 then
				setMoveAnimation("walkLeft")
			end
		else
			setMoveAnimation("")
		end
		model:getAnimation():update(Core.getDeltaTime())
		

		--update positions
		matrix:setPosition(position)
		matrix:normalize()
		camera.setLocalPosition(position)
		model:setLocalMatrix(matrix)
		camera.update()
		return true
	end
	
	return self
end

function create()
	player = Player.new()
	update = player.update
	return true
end