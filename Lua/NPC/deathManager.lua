require("Menu/settings.lua")
--this = SceneNode()
DeathManager = {}
function DeathManager.new()
	local self = {}
	
	local BodyType = {animation=1,softBody=2,rigidBody=3,gold=4}
	
	local debugActiveDeathTimer =	0.0
	
--	local physicManager
	local deadBodyDecayTime =		15
	local deadBodyStartTime =		20 + deadBodyDecayTime
	local deadBodyPhysicTimeOut =	2
	local bodyTable = 				{}
	local bodyTableSize = 			0
	local goldTable =				{}
	local goldTableSize =			0
	local enableSelfDestruct = 		true
	local groundTestEvery = 		0.1
	--data
	local animation =				nil
	local effectList =				{size=0}
	local pointLigthList =			{size=0}
	
	local useAnimatedDeath =		true
	

	function self.getUseAnimatedDeath()
		return useAnimatedDeath
	end

	function self.setUsePhysicDeathAnimation()
		useAnimatedDeath = false
	end

	function self.getDeadBodyDecayTime()
		return deadBodyDecayTime*Settings.corpseTimer.getInt()*0.25
	end
	function self.getDeadBodyStartTime()
		return deadBodyStartTime*Settings.corpseTimer.getInt()*0.25
	end
	function self.setAnimation(theModel,theDeathAnimationTimer,theDeathAnimationDistance,pDeathPos,pDeathVec,pDeathSpeed)
		--theModel:setIsStatic(true)
		animation = {
			type =					BodyType.animation,
			groundTestTimer	=		-0.1,
			model = 				theModel,
			sceneNode = 			theModel,
			lifeTime =				math.max(theDeathAnimationTimer,self.getDeadBodyStartTime()),
			color =					Vec4(1,1,1,1),
			deathAnimationTimer = 	theDeathAnimationTimer,
			deathAnimationTimerStart = theDeathAnimationTimer,
			deathAnimationDistance = theDeathAnimationDistance,
			deathPos = 				pDeathPos,
			deathVec = 				pDeathVec,
			deathSpeed = 			pDeathSpeed,
			higthOverGround = 		-1
		}
	end

	
	function self.addRigidBody(island, splitedMesh, velocity, rotation, rotationSpeed)
		local mesh = Mesh.new(splitedMesh)
		local islandInverseM = island:getGlobalMatrix():inverseM()
		--Connect the mesh to the island
		mesh:setLocalMatrix( islandInverseM * mesh:getLocalMatrix() )
		island:addChild(mesh:toSceneNode())
		
		self.addRigidBodyMesh(mesh, velocity, rotation, rotationSpeed)
	end
	
	function self.addRigidBodyMesh(mesh, velocity, rotation, rotationSpeed)
		bodyTableSize = bodyTableSize + 1
		
		bodyTable[bodyTableSize] = {
			type =				BodyType.rigidBody,
			groundTestTimer	=	-0.1,
			startDeadMatrix =	Matrix(),
			physicEnabled =		true,
			lifeTime =			self.getDeadBodyStartTime(),
			meshNode = 			mesh,
			color =				mesh:getColor(),
			velocity = 			velocity,
			rotation = 			rotation,
			rotationSpeed = 	rotationSpeed,
			higthOverGround =	-1
		}
	end
	function self.throwGold(amount)
		for i=1, amount do
			goldTableSize = goldTableSize + 1
			goldTable[goldTableSize] = {
				type =				BodyType.gold,
				model =				Core.getModel("gold_coin.mym"),
				position =			Vec3(),
				atVec =				Vec3(math.randomFloat()*0.25,math.randomFloat()*2.0,math.randomFloat()*0.25),
				bounce =			0
			}
			this:addChild(goldTable[goldTableSize].model:toSceneNode())
		end
	end
	function self.addParticleEffect(pEffect,deathTimer)
		effectList.size = effectList.size + 1
		effectList[effectList.size] = {effect=pEffect, timer=deathTimer, startTimer=deathTimer}
	end
	function self.addPointLight(pPointLight,deathTimer)
		pointLigthList.size = pointLigthList.size + 1
		pointLigthList[pointLigthList.size] = {pointLight=pPointLight, timer=deathTimer, startTimer=deathTimer, startRange=math.max(0.1,pPointLight:getRange())}
	end
	function self.hasDeathAnimation()
		return animation~=nil
	end
	function self.closestTo(startFrame,endFrame,currentFrame,targets)
		local closest = 1
		local dist = endFrame-startFrame+1.0
		for index=1, #targets, 1 do
			local currentDistUp = endFrame
			local currentDistDown = endFrame
			if currentFrame>targets[index] then
				--10>5 (we are above it) dist = (0->targets[index]) + (currentFrame->endFrame)
				currentDistUp = targets[index] + (endFrame-currentFrame)
				currentDistDown = currentFrame-targets[index]
			else
				--5>10 (we are bellow it) dist = (0->currentFrame) + (endFrame->targets[index])
				currentDistDown = currentFrame + (endFrame-targets[index])
				currentDistUp = targets[index]-currentFrame
			end
			if currentDistDown<dist or currentDistUp<dist then
				dist = math.min(currentDistDown,currentDistUp)
				closest = index
			end
		end
		return closest
	end
	local function collisionAginstTheWorldGlobal(globalPosition)
		local localPosition = Vec3()
		local parent = this:getParent()
		local globalMatrix = parent:getGlobalMatrix()
		local line = Line3D(globalPosition + globalMatrix:getUpVec(), globalPosition -  globalMatrix:getUpVec() )
		--Core.addDebugLine(line.startPos, line.endPos, 0.01, Vec3(1,1,0))
		local collisionNode = this:getPlayerNode():collisionTree(line, {NodeId.islandMesh, NodeId.ropeBridge})
		--Core.addDebugSphere(Sphere( line.endPos, 0.3), 0.01, Vec3(1,0,0))
		if collisionNode then
			localPosition = parent:getGlobalMatrix():inverseM() * line.endPos
		end
		return collisionNode, localPosition 
	end
	--send in a local position, and a sceneNode is returned if collision was found
	function self.collisionAginstTheWorldLocal(localPosition)
		local parent = this:getParent()
		local globalPos = parent:getGlobalMatrix() * localPosition
		return collisionAginstTheWorldGlobal(globalPos)
	end
	--fade the body out of existance (like the repaer)
	local function fadeOut(body,deltaTime,type)
		if type=="animated" then
			if not body.fadeOutTime then
				--mod = Model()
				Core.setUpdateHzRealTime(24)
				for i=0, body.model:getNumMesh()-1 do
					if body.model:getMesh(i):getShader() then
						--change shader to fade out
						body.model:getMesh(i):setShader(Core.getShader("animatedForward"))
						--remove the shadow
						body.model:getMesh(i):setEnableShadow(false)
						--Change render level to 9
						body.model:getMesh(i):setRenderLevel(9)
					end
				end
				--Set the body to fade out over 1.5seconds
				body.fadeOutTime = 1.5
				body.fadeOutTimeTotal = body.fadeOutTime
			end
		
			body.fadeOutTime = body.fadeOutTime - deltaTime
			if body.fadeOutTime > 0 then
				--Check all mesh connected to the model
				for i=0, body.model:getNumMesh()-1 do
					if body.model:getMesh(i):getShader() then
						--Fade both alpha and color
						local fadeoutAlpha = body.fadeOutTime/body.fadeOutTimeTotal
						--start on 0.8 in color to hide ambient oclusion effects
						body.model:getMesh(i):setColor(Vec4( Vec3(0.2+fadeoutAlpha*0.6), fadeoutAlpha))
					end
				end
			else
				body.lifeTime = -1.0
			end
		else
			if not body.fadeOutTime then
				--mod = Model()
				Core.setUpdateHzRealTime(24)
				if body.sceneNode:getShader() then
					--change shader to fade out
					body.sceneNode:setShader(Core.getShader("normalForward"))
					--remove the shadow
					body.sceneNode:setEnableShadow(false)
					--Change render level to 9
					body.sceneNode:setRenderLevel(9)
				end
				--Set the body to fade out over 1.5seconds
				body.fadeOutTime = 1.5
				body.fadeOutTimeTotal = body.fadeOutTime
			end
		
			body.fadeOutTime = body.fadeOutTime - deltaTime
			if body.fadeOutTime > 0 then
				--Check all mesh connected to the model
				if body.sceneNode:getShader() then
					--Fade both alpha and color
					local fadeoutAlpha = body.fadeOutTime/body.fadeOutTimeTotal
					--Core.addDebugLine(globalPos,globalPos+Vec3(0,6,0),0.1,Vec3(fadeoutAlpha,1,0))
					--start on 0.8 in color to hide ambient oclusion effects
					body.sceneNode:setColor(Vec4( Vec3(0.2+fadeoutAlpha*0.6), fadeoutAlpha))
				end
			else
				--Remove the dead body from the game
				body.lifeTime = -1.0
			end
		end
	end
	local function manageDeathParticles(deltaTime)
		if effectList.size>0 then
			local index=1
			while index<=effectList.size do
				local item = effectList[index]
				item.timer = item.timer - deltaTime
				if item.timer>0.0 then
					--scale down living particle effects into obscurity
					item.effect:setScale(item.timer/item.startTimer)
				else
					--remove dead particle effects
					item.effect:setVisible(false)
					--
					effectList[index],effectList[effectList.size] = effectList[effectList.size],effectList[index]
					effectList[effectList.size] = nil
					effectList.size = effectList.size - 1
					index = index - 1
				end
				index = index + 1
			end
		end
	end
	local function manageDeathLights(deltaTime)
		if pointLigthList.size>0 then
			local index=1
			while index<=pointLigthList.size do
				local item = pointLigthList[index]
				item.timer = item.timer - deltaTime
				if item.timer>0.0 then
					--scale down living pointLights into obscurity
					item.pointLight:setRange(item.startRange*(item.timer/item.startTimer))
				else
					--remove dead pointLights
					item.pointLight:setVisible(false)
					--
					pointLigthList[index],pointLigthList[pointLigthList.size] = pointLigthList[pointLigthList.size],pointLigthList[index]
					pointLigthList[pointLigthList.size] = nil
					pointLigthList.size = pointLigthList.size - 1
					index = index - 1
				end
				index = index + 1
			end
		end
	end
	--scale and darken the body untill it is gone
	local function deathAnimation(body)
		-- TEST CODE
		if enableSelfDestruct then
			Core.setUpdateHzRealTime(15)--
		end
		-- END OF TEST CODE
		if body.higthOverGround==-1 then
			local line = Line3D(body.sceneNode:getGlobalPosition()+Vec3(0,10,0), body.sceneNode:getGlobalPosition()-Vec3(0,10,0))
			if body.sceneNode:getPlayerNode():collisionTree(line,NodeId.islandMesh) then
				body.higthOverGround = math.abs(body.sceneNode:getGlobalPosition().y-line.endPos.y)*2.0+0.1
			else
				body.higthOverGround = 1
			end
		end
		--lower the decaying body towards the earth
		local position = body.sceneNode:getLocalPosition() - Vec3(0,Core.getDeltaTime()/self.getDeadBodyDecayTime()*body.higthOverGround,0)
		
		--set decay y compression
		local scaleYMat = Matrix()
		scaleYMat:setUpVec( scaleYMat:getUpVec() * math.max(0.1, body.lifeTime/self.getDeadBodyDecayTime()))
		scaleYMat = scaleYMat * body.startDeadMatrix
		scaleYMat:setPosition(position)
		body.sceneNode:setLocalMatrix(scaleYMat)
		
		--set decay color
		local color = body.color:toVec3()*(0.2 + 0.8*math.max(0.0,body.lifeTime/self.getDeadBodyDecayTime()))
		if body.renderNode then
			body.renderNode:setColor(Vec4(color, body.color.w))
		elseif body.sceneNode and body.type==BodyType.animation then
			body.sceneNode:setColor(Vec4(color, body.color.w))
		else
			--something is wrong
			body.lifeTime = -1
		end
	end
	local function manageDeathAnimations(deltaTime)
		if animation and animation.lifeTime then
			local body = animation 
			body.lifeTime = body.lifeTime - deltaTime 
			if body.lifeTime<0.0 then
				animation = nil--removes the animation from the list
			else
				body.deathAnimationTimer = body.deathAnimationTimer - deltaTime
				--position test
				local localPos = this:getLocalPosition()
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
					local gPos = this:getGlobalPosition()
					--Core.addDebugLine(gPos,gPos+Vec3(0,3,0),2,Vec3(1))
					body.groundTestNode, body.groundTestYPos = self.collisionAginstTheWorldLocal(localPos)
					--set the timer for next update
					if body.groundTestNode and not body.groundTestNode:getNodeType()==NodeId.ropeBridge then
						body.groundTestTimer = body.groundTestTimer + groundTestEvery
					else
						body.groundTestTimer = body.groundTestTimer + 0.05
					end
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
					this:getPlayerNode():addChild(body.model:toSceneNode())--global space for (performance)
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
					elseif body.lifeTime > self.getDeadBodyDecayTime() then--stage 2 (waiting)
						--groundTestNode can be failed because the animation is done and it was an edge case, [RESAULT is failed ground test but the npc is still mostly on ground]
						if body.groundTestNode and body.groundTestNode:getNodeType()==NodeId.ropeBridge then--(if on bridge)
							--waiting for the body to start decaying, keep moving because we are on a bridge
							this:setLocalPosition( localPos )
							--Core.addDebugLine(this:getGlobalPosition(),this:getGlobalPosition()+Vec3(0,2,0),0.1,Vec3(1,0,0))
						else
							body.groundTestTimer = 100.0--we are on solid ground no more test needed
							--Core.addDebugLine(this:getGlobalPosition(),this:getGlobalPosition()+Vec3(0,2,0),0.1,Vec3(0,1,0))
						end
					else--stage 3 (decay)
						--The body is old time to decay away or get delete
						--The body is ether on a bride or an island
						if body.groundTestNode and body.groundTestNode:getNodeType()==NodeId.ropeBridge then
							--body is on a bridge
							--fade the model away with alpha
							this:setLocalPosition( localPos )
							fadeOut(body,deltaTime,"animated")
						else
							--The dead body is on a island. use deafault decay
							--this:setLocalPosition( localPos ), position is updated by the next function
							deathAnimation(body)
						end
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
						body.model:getParent():removeChild(body.model:toSceneNode())--this is in global space, must be deleted
						animation = nil--removes the animation from the list,lets other death obeject to die
						local comUnit = Core.getComUnit()
						comUnit:sendTo("SteamAchievement","Falling","")
					end
				end
			end
		end
		return true
	end
	local function manageDeathPhysic(deltaTime)
		local index=1
		local playerNode = this:getPlayerNode()
		while index<=bodyTableSize do
			local body = bodyTable[index]
			local meshNode = body.meshNode
			body.lifeTime = body.lifeTime - deltaTime
			
			if body.lifeTime<0.0 or meshNode:getLocalPosition().y < -100.0 then
				--this body part is dead, delete it
				meshNode:destroy()--getParent():removeChild(body.sceneNode)--body.sceneNode:setParent(nil)
				if index<bodyTableSize then
					bodyTable[index],bodyTable[bodyTableSize] = bodyTable[bodyTableSize],bodyTable[index]
				end
				bodyTable[bodyTableSize] = nil
				bodyTableSize = bodyTableSize - 1
				index = index - 1
			else
				if bodyTable[index].physicEnabled then
					local globalPosition = meshNode:getGlobalPosition() + body.velocity * Core.getDeltaTime()
					body.velocity = body.velocity + Vec3(0,-9.8,0) * Core.getDeltaTime()
					
					local collisionLine = Line3D(meshNode:getGlobalPosition(), globalPosition)
					
					if playerNode:collisionTree(collisionLine,NodeId.islandMesh) then
						globalPosition = collisionLine.endPos
						
						local velocityXZ = Vec3(body.velocity.x,0,body.velocity.z):length()
						
						body.velocity = body.velocity * Vec3(0.8,(velocityXZ < 1.5 and -0.1 or -0.4), 0.8)
						body.rotationSpeed = body.rotationSpeed * math.randomFloat(0.3,1.4)
						
						if body.velocity:length() < 0.7 then
							body.velocity = Vec3()
							body.rotationSpeed = 0
							bodyTable[index].physicEnabled = false
						end
					end
					
					meshNode:setLocalPosition(meshNode:getParent():getGlobalMatrix():inverseM() * globalPosition)
					
					local rotMat = Matrix()
					rotMat:rotate( body.rotation, body.rotationSpeed * Core.getDeltaTime())
					meshNode:setLocalMatrix( meshNode:getLocalMatrix() * rotMat )
				elseif body.lifeTime < deadBodyDecayTime then
					
					local colorScale = math.max(body.lifeTime,0)/deadBodyDecayTime
					meshNode:setLocalPosition(meshNode:getLocalPosition() + Vec3(0,-0.35 * deltaTime/deadBodyDecayTime,0))
					meshNode:setColor(body.color * colorScale)
				end
				
--				--this body part is still alive
--				if body.physicBody:getPhysicEnable() then
--					--if physic is active wait for time out or stop in motion
--					if body.physicBodyTimeOut < deadBodyPhysicTimeOut then
--						local globalPos = body.physicBody:getGlobalPosition()
--						body.groundTestTimer = body.groundTestTimer - deltaTime
--						if body.groundTestTimer<0.0 then
--							local collisionPoint
--							body.groundTestNode, collisionPoint = collisionAginstTheWorldGlobal(globalPos)	
--							body.groundTestTimer = body.groundTestTimer + groundTestEvery
--						end
--						if body.groundTestNode and body.groundTestNode:getNodeType() == NodeId.ropeBridge then
--							--is on a bridge. time to die
--							--stop there physical activities, so they can fade out of existance
--							body.lifeTime = self.getDeadBodyDecayTime()+0.1
--							body.physicBody:tryToDestroyPhysic()
--							--
--							local collisionPoint
--							body.groundTestNode, collisionPoint = collisionAginstTheWorldGlobal(globalPos)	
--							--
--							body.startDeadMatrix = body.sceneNode:getLocalMatrix()
--							body.startDeadMatrix:setPosition(Vec3())
--						elseif body.groundTestNode then
--							--on an island
--							if body.physicBodyTimeOut < 0.0 then
--								body.physicBody:tryToDestroyPhysic()
--								--
--								local collisionPoint
--								body.groundTestNode, collisionPoint = collisionAginstTheWorldGlobal(globalPos)	
--								--
--								body.startDeadMatrix = body.sceneNode:getLocalMatrix()
--								body.startDeadMatrix:setPosition(Vec3())
--							elseif body.type==BodyType.softBody then
--								body.physicBody:damping(math.clamp(1.0-(body.physicBodyTimeOut/deadBodyPhysicTimeOut),0.0,1.0))
--							end
--						else
--							--falling, wait to reach a safe distance
--							body.lifeTime = self.getDeadBodyDecayTime() + 1--so we don't destroy it to early
--							if globalPos.y<100.0 then
--								--destroy this physic
--								body.lifeTime = - 1
--								local comUnit = Core.getComUnit()
--								comUnit:sendTo("SteamAchievement","Falling","")
--							end
--						end
--					elseif body.physicBody:getVelocity() < 0.1 then
--						--soft body is moving to slow save physic calculation by force stop the body
--						body.physicBodyTimeOut = deadBodyPhysicTimeOut
--					end
--				end
--				--decay away the dead bodies
--				if body.lifeTime < self.getDeadBodyDecayTime() then
--					--we do not want remaining(falling)) softbody to surface
--					if body.physicBody:getPhysicEnable() or not body.groundTestNode then
--						--something is wrong, destroy the issue
--						body.lifeTime = -1
--					else
--						--body.groundTest not needed as body should be stationary
--						if body.type==BodyType.rigidBody or body.groundTestNode:getNodeType()~=NodeId.ropeBridge then
--							--on an island
--							deathAnimation(body)
--						else
--							--on a bridge
--							--fade the model away with alpha
--							fadeOut(body,deltaTime,"normal")
--						end
--					end
--				end
			end
			index = index + 1
		end
		return true
	end
	
	function manageGold(deltaTime)
--		goldTableSize = goldTableSize + 1
--		goldTable[goldTableSize] = {
--			type =				BodyType.gold,
--			model =				Core.getModel("gold_coin.mym"),
--			position =			Vec3(),
--			atVec =				Vec3(math.randomFloat()*0.25,math.randomFloat()*2.0,math.randomFloat()*0.25)
--			bounce =			0
--		}
		local index=1
		local gFactor = 5.0
		local dragFactor = 0.1
		while index<=goldTableSize do
			local coin = goldTable[index]
			--gravity
			coin.atVec = coin.atVec + Vec3(0,gFactor*deltaTime,0)
			--air friction
			coin.atVec = coin.atVec * (1.0-dragFactor*deltaTime)
			coin.position = coin.position + (coin.atVec*deltaTime)
			if coin.position.y<=0.0 then
				bounce = bounce + 1
				if bounce<3 then
					coin.atVec.y = math.abs(coin.atVec.y)
					--bounce cost
					coin.atVec = coin.atVec * 0.5
				else
					coin.atVec = Vec3()
				end
			end
			coin.model:setLocalPosition(coin.position)
			index = index + 1
		end
	end
	
	function self.setEnableSelfDestruct(boolSet)
		enableSelfDestruct = boolSet
	end
	function self.hasWork()
		return (animation or bodyTableSize>0 or effectList.size>0 or pointLigthList.size>0)
	end
	function self.update()
		
		local deltaTime = Core.getDeltaTime()
		manageDeathParticles(deltaTime)
		manageDeathLights(deltaTime)
		manageDeathAnimations(deltaTime)
		manageDeathPhysic(deltaTime)
		manageGold(deltaTime)
--		if not manageDeathAnimations(deltaTime) or not manageDeathPhysic(deltaTime) then
--			return false
--		end
		--
		if animation==nil and bodyTableSize==0 and effectList.size==0 and pointLigthList.size==0 then
			local index = Core.getComUnit():getIndex()
			--destroy the script if there is nothing to update
			if enableSelfDestruct then
				this:destroy()
			end
			return false
		end
		return true
	end
	
	return self
end