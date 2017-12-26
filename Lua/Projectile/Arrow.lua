require("Game/targetSelector.lua")
--this = SceneNode()

Arrow = {name="Arrow"}
function Arrow.new()
	local self = {}
	local targetIndex = 0
	local startPos = Vec3()
	local currentPos = Vec3()
	local speed = 24.0
	local damage
	local weakenTimer
	local markOfDeathPer 
	local prevAtVec
	local range
	local shieldAreaIndex = 0
	local hittStrength = 1
	local comUnit = Core.getComUnit()
	local billboard = Core.getBillboard()
	local activeTeam = 1
	local activeTeam = 1
	local targetSelector = TargetSelector.new(activeTeam)
	--scenNode
	local node = SceneNode()
	this:findNodeByTypeTowardsRoot(NodeId.playerNode):addChild(node)
	--model
	local model = Core.getModel("arrow.mym")
	node:addChild(model)
	
	function self.init()
		targetSelector.setPosition(this:getGlobalPosition())
		targetSelector.setTarget(billboard:getInt("targetIndex"))
		if targetSelector.isTargetAlive(targetSelector.getTarget())==false then
			targetSelector.deselect()
		end
		startPos = billboard:getVec3("bulletStartPos")
		damage = billboard:getFloat("damage")
		weakenTimer = billboard:getFloat("weakenTimer")
		markOfDeathPer = billboard:getFloat("weaken")
		pretAvVec = billboard:getVec3("pipeAtVector")
		range = billboard:getFloat("range")
		hittStrength = billboard:getDouble("hittStrength")
		currentPos = startPos
		
		shieldAreaIndex = targetSelector.getIndexOfShieldCovering(currentPos)
	
		local atVec = Vec3( (targetSelector.getTargetPosition()-currentPos) )
		atVec = atVec:normalizeV()
		local matrix = Matrix()
		matrix:createMatrix(atVec,Vec3(0.0, 0.0, 1.0))
		matrix:scale(Vec3(1.5,1.5,1.5))
		
		model:setLocalMatrix(matrix)
		node:setLocalPosition(currentPos)
		model:setVisible(true)
	end
	function self.destroy()
		if node:getParent() then--as the parrent can already be destroyed, if end of the map
			node:getParent():removeChild(node)
		end
	end
	function self.stop()
		model:setVisible(false)
	end
	function self.update()
		comUnit:clearMessages()
		local atVec = Vec3( targetSelector.getTargetPosition()-currentPos )
		local lengthLeft = atVec:length()
		atVec:normalize()
		local frameMovment = speed * Core.getDeltaTime()
		--
		currentPos = currentPos + (atVec * frameMovment)
		if targetSelector.isTargetAlive(targetSelector.getTarget())==false then
			--ops target died on the route, let's see if there is some one else to kill [this can increase damage output by upto 30%, minimizing damage fluctuation on low/high wave level]
			local per = (startPos-currentPos):length()/8.0
			per = (per>1.0) and 1.0 or per
			prevAtVec = prevAtVec or atVec	--prevAtVec = Vec3()
			targetSelector.setPosition(currentPos)
			targetSelector.setAngleLimits(prevAtVec,math.pi*(0.10+(0.25*per)))
			targetSelector.setRange((range+1.0)-(startPos-currentPos):length())
			if targetSelector.selectAllInRange() then
				targetSelector.scoreClosestToVector(prevAtVec,10)
				if targetSelector.selectTargetAfterMaxScore()>0 then
					atVec = Vec3( targetSelector.getTargetPosition()-currentPos )
					lengthLeft = atVec:length()
					if lengthLeft<1.0 then
						lengthLeft=frameMovment--just insta hitt instead of doing strange movments
					end
					comUnit:sendTo(LUA_INDEX,"retargeted","")
				end
			end
		else
			prevAtVec = atVec
		end
		if lengthLeft-frameMovment<0.25 then
			--direct hit on enemy target
			--mark of death,first so that it can be used by our own attack
			if markOfDeathPer>0.001 then
			 	comUnit:sendTo(targetSelector.getTarget(),"markOfDeath",{per=markOfDeathPer,timer=weakenTimer,type="targeted"})
			end
			--do the attack
			comUnit:sendTo(targetSelector.getTarget(),"attackPhysical",tostring(damage))
			self.stop()
			return false
		elseif shieldAreaIndex~=targetSelector.getIndexOfShieldCovering(currentPos) then
			--shield hitt
			local targetIndex = shieldAreaIndex>0 and shieldAreaIndex or targetSelector.getIndexOfShieldCovering(currentPos)
			comUnit:sendTo(targetIndex,"attack",tostring(damage))
			local oldPosition = currentPos - atVec
			local futurePosition = currentPos + atVec
			local hitTime = tostring(0.5+(hittStrength*0.15))
			comUnit:sendTo(targetIndex,"addForceFieldEffect",tostring(oldPosition.x)..";"..oldPosition.y..";"..oldPosition.z..";"..futurePosition.x..";"..futurePosition.y..";"..futurePosition.z..";"..hitTime)
			--
			self.stop()
			return false
		end
		if targetSelector.isTargetAlive(targetSelector.getTarget())==false then
			self.stop()
			return false
		end
		--Core.addDebugLine(this:getGlobalPosition(),this:getGlobalPosition()+Vec3(0,1,0),0.001,Vec3(0,0,1))
		
		local matrix = Matrix()
		matrix:createMatrix(atVec,Vec3(0.0, 0.0, 1.0))
		matrix:scale(Vec3(1.5,1.5,1.5))
		model:setLocalMatrix(matrix)
		node:setLocalPosition(currentPos)
	
		--
		--  graphic part of the code
		--
	
		--model:render()
		return true
	end
	
	return self
end