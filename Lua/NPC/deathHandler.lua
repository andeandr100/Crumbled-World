require("Menu/settings.lua")
--this = SceneNode()
local listner = Listener("DeathHandler")
DeathHandler = {}
function DeathHandler.new()
	local self = {}
	local BodyType = {animation=1,rigidBody=3}
	
	local animations = {}
	
	local deadBodyDecayTime =		15
	local deadBodyStartTime =		20 + deadBodyDecayTime
	
	local function getDeadBodyDecayTime()
		return deadBodyDecayTime*Settings.corpseTimer.getInt()*0.25
	end
	local function getDeadBodyStartTime()
		return deadBodyStartTime*Settings.corpseTimer.getInt()*0.25
	end
	
	
	local function addAnimation( data )
--		local island = data.model:findNodeByTypeTowardsRoot(NodeId.island)
--		local globalMatrix = data.model:getGlobalMatrix()
--		island:addChild( data.model )
--		data.model:setLocalMatrix( island:getGlobalMatrix():inverseM() * globalMatrix )
		 
		animations[#animations+1] = {
			type =					BodyType.animation,
			groundTestTimer	=		-0.1,
			model = 				data.model,
			lifeTime =				math.max(data.deathAnimationTimer,getDeadBodyStartTime()),
			color =					Vec4(1,1,1,1),
			deathAnimationTimer = 	data.deathAnimationTimer,
			deathAnimationTimerStart = data.deathAnimationTimer,
			deathAnimationDistance = data.deathAnimationDistance,
			deathPos = 				data.deathPos,
			deathVec = 				data.deathVec,
			deathSpeed = 			data.deathSpeed,
			higthOverGround = 		-1
		}
	end
	
	local function init()
		listner:registerEvent("addDeathAnimation", addAnimation)
	end
	
	function self.destroy()
		abort()
	end
	
	-- ============================================================== --
	-- ==================== RUN TIME FUCNCTIONS  ==================== --
	-- ============================================================== --
	--scale and darken the body untill it is gone
	local function decayBodyAnimation(body)
		-- TEST CODE
--		if enableSelfDestruct then
--			Core.setUpdateHzRealTime(15)--
--		end
		-- END OF TEST CODE
		if body.higthOverGround==-1 then
			local line = Line3D(body.model:getGlobalPosition()+Vec3(0,10,0), body.model:getGlobalPosition()-Vec3(0,10,0))
			if body.model:getPlayerNode():collisionTree(line,NodeId.islandMesh) then
				body.higthOverGround = math.abs(body.model:getGlobalPosition().y-line.endPos.y)*2.0+0.1
			else
				body.higthOverGround = 1
			end
		end
		--lower the decaying body towards the earth
		local position = body.model:getLocalPosition() - Vec3(0,Core.getDeltaTime()/getDeadBodyDecayTime()*body.higthOverGround,0)
		
		--set decay y compression
		local scaleYMat = Matrix()
		scaleYMat:setUpVec( scaleYMat:getUpVec() * math.max(0.1, body.lifeTime/getDeadBodyDecayTime()))
		scaleYMat = scaleYMat * body.startDeadMatrix
		scaleYMat:setPosition(position)
		body.model:setLocalMatrix(scaleYMat)
		
		--set decay color
		local color = body.color:toVec3()*(0.2 + 0.8*math.max(0.0,body.lifeTime/getDeadBodyDecayTime()))
		--color = Vec3()
		if body.model and body.type==BodyType.animation then
			body.model:setColor(Vec4(color, body.color.w))
		else
			--something is wrong
			body.lifeTime = -1
		end
	end
	
	local function collisionAginstTheWorldGlobal(parent, globalPosition)
		local localPosition = Vec3()
		local globalMatrix = parent:getGlobalMatrix()
		local line = Line3D(globalPosition + globalMatrix:getUpVec(), globalPosition -  globalMatrix:getUpVec() )
		--Core.addDebugLine(line.startPos, line.endPos, 0.01, Vec3(1,1,0))
		local collisionNode = parent:getPlayerNode():collisionTree(line, {NodeId.islandMesh, NodeId.collisionMesh})
		--Core.addDebugSphere(Sphere( line.endPos, 0.3), 0.01, Vec3(1,0,0))
		if collisionNode then
			localPosition = parent:getGlobalMatrix():inverseM() * line.endPos
		end
		return collisionNode, localPosition 
	end
	
	local function collisionAginstTheWorldLocal(parent, localPosition)
		local globalPos = parent:getGlobalMatrix() * localPosition
		return collisionAginstTheWorldGlobal(parent, globalPos)
	end
	
	local function manageDeathAnimations(body, deltaTime)

		body.lifeTime = body.lifeTime - deltaTime 
		print("lifetime "..body.lifeTime)
		if body.lifeTime<0.0 then
			--remove animation
			return
		else
			body.deathAnimationTimer = body.deathAnimationTimer - deltaTime
			--position test
			local localPos = body.model:getLocalPosition()
			--localPos = Vec3()
			if body.deathAnimationTimer>0 and not body.fallingAnimationVelocity then
				--animation still running on a ground and we are moving
				localPos = body.deathPos + (body.deathVec * ( math.sin(math.pi*0.5*(1.0-(body.deathAnimationTimer/body.deathAnimationTimerStart))) * body.deathAnimationDistance))

				--update position with ground collision
				if body.groundTestNode then
					localPos = Vec3(localPos.x,body.groundTestYPos.y,localPos.z)
				end
			end
			--is on what ground
			body.groundTestTimer = body.groundTestTimer - deltaTime
			if body.groundTestTimer<0.0 then
				--test ground collision
--					local gPos = this:getGlobalPosition()
				--Core.addDebugLine(gPos,gPos+Vec3(0,3,0),2,Vec3(1))
				body.groundTestNode, body.groundTestYPos = collisionAginstTheWorldLocal(body.model:getParent(), localPos)
				--set the timer for next update
				body.groundTestTimer = body.groundTestTimer + 0.1
				
				--update position
				if body.groundTestNode then
					localPos = Vec3(localPos.x,body.groundTestYPos.y,localPos.z)
				end
			end
			--update animation
			if body.deathAnimationTimer>-4.0 then--deathAnimationTimer==stop time of x,z movment not animation
				body.model:getAnimation():update(Core.getDeltaTime())
			end
			--
			if body.deathAnimationTimer>0.0 and not body.groundTestNode and not body.fallingAnimationVelocity then
				--we have started to fall over the world edge
				body.groundTestTimer = 100.0--no futher testing is needed. our fate is sealed
				body.fallingAnimationVelocity = body.deathVec * ( math.sin(math.pi*0.5*(1.0-(body.deathAnimationTimer/body.deathAnimationTimerStart))) * body.deathAnimationDistance)--just so we can acelerate the fall
				body.fallingAnimationPosition = body.model:getGlobalPosition()--we must know where it is falling
				body.fallingAnimationRotationSpeed = 0.0--rotation to hide the loack of animation
				local gMatrix = body.model:getGlobalMatrix()
				body.model:getParent():removeChild(body.model:toSceneNode())
				body.model:getPlayerNode():addChild(body.model:toSceneNode())--global space for (performance)
				body.model:setLocalMatrix(gMatrix)
				if body.lifeTime < 5.0 then
					body.lifeTime = 5.0
				end
			end
			--
			if not body.fallingAnimationVelocity then
				--we are on a bridge or an island
				if body.deathAnimationTimer>0.0 then--stage 1 (still movment from the death blow)
					--we are still moving
					this:setLocalPosition( localPos )
					body.startDeadMatrix = body.model:getLocalMatrix()
				elseif body.lifeTime > getDeadBodyDecayTime() then--stage 2 (waiting)
					--groundTestNode can be failed because the animation is done and it was an edge case, [RESAULT is failed ground test but the npc is still mostly on ground]
					
					body.groundTestTimer = 100.0--we are on solid ground no more test needed
					--Core.addDebugLine(this:getGlobalPosition(),this:getGlobalPosition()+Vec3(0,2,0),0.1,Vec3(0,1,0))
					
				else--stage 3 (decay)
					--The body is old time to decay away or get delete

					--The dead body is on a island. use deafault decay
					--this:setLocalPosition( localPos ), position is updated by the next function
					decayBodyAnimation(body)
				end
			else
				--we have fallen over the world, continue falling
				body.fallingAnimationVelocity = body.fallingAnimationVelocity + (Vec3(0,-9.82,0) * deltaTime)
				local keep = (1.0-(0.09*deltaTime))--9% falloff
				body.fallingAnimationVelocity = Vec3(body.fallingAnimationVelocity.x*keep*keep,body.fallingAnimationVelocity.y*keep,body.fallingAnimationVelocity.z*keep*keep)--update speed
				body.fallingAnimationRotationSpeed = (body.fallingAnimationRotationSpeed + (math.pi*0.003*deltaTime))*keep--update rotation speed
				body.fallingAnimationPosition = body.fallingAnimationPosition + (body.fallingAnimationVelocity*deltaTime)--update position
				body.model:setLocalPosition( body.fallingAnimationPosition )
				body.model:rotate(body.model:getLocalMatrix():getRightVec(),body.fallingAnimationRotationSpeed*deltaTime)--rotate model to hide animation weakness
				if body.fallingAnimationPosition.y>100.0 then
					
					body.lifeTime = -1.0
					Core.getComUnit():sendTo("SteamAchievement","Falling","")
				end
			end
		end

		return true
	end

	
	function self.update()
		for n=1, #animations do
			manageDeathAnimations(animations[n], Core.getDeltaTime())
			if animations[n].lifeTime < 0 then
				--Delete this dead body from the handler
				animations[n].model:getParent():removeChild(animations[n].model:toSceneNode())--this is in global space, must be deleted
				animations[n] = animations[#animations]
				animations[#animations] = nil
				n = n - 1
			end
		end
		print("Update Death Handler <----------")
		return true
	end
	
	init()
	
	return self
end

function destroy()
	
	if handler then
		handler.destroy()
		handler = nil
		update = nil
	end
	abort()
end

function create()
	handler = DeathHandler.new()
	update = handler.update
	return true
end