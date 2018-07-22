require("NPC/state.lua")
require("Game/particleEffect.lua")
--this = SceneNode()

FireStorm = {}
function FireStorm.new(pNode)
	local self = {}
	local node = pNode
	local fireStorm1 = ParticleSystem.new( ParticleEffect.fireStormFlame )
	local fireStorm2 = ParticleSystem.new( ParticleEffect.fireStormSparks )
	local fireStorm3 = ParticleSystem.new( ParticleEffect.fireStormFire )
	local colorVariations = Vec3(0.35,0.35,0.05)
	local pLight = PointLight.new(Vec3(),Vec3(1.75,0.6,0.1),3.5)
	local comUnit = Core.getComUnit()
	local billboard = Core.getBillboard()
	local ATTACKUPDATETIMER = 0.25
	--
	local attackTimer = 0.0
	local fireStormTimer = 0.0
	local duration = 0.0
	local damage = 0.0
	local range = 0.0
	local slow = 0.0
	local position = Vec3()
	--
	local soundFireStorm = SoundNode.new("firestorm")
	function self.activate(pDuration,pPosition,pDamage,pSlow,pRange)
		fireStormTimer = pDuration
		duration = pDuration
		damage = pDamage
		range = pRange
		slow = pSlow
		position = pPosition
		attackTimer = 0.0
		--
		local line = Line3D(position+Vec3(0,2,0),position-Vec3(0,2,0))
		local collisionNode = this:getPlayerNode():collisionTree(line, {NodeId.islandMesh, NodeId.ropeBridge})
		if collisionNode then
			position = line.endPos+Vec3(0,0.1,0)
		end
		--
		fireStorm1:setSpawnRadius(range-0.4)
		fireStorm1:setSpawnRate(1.0)
		fireStorm1:activate(position)
		fireStorm2:setSpawnRadius(range-0.4)
		fireStorm2:setSpawnRate(1.0)
		fireStorm2:activate(position)
		fireStorm3:setSpawnRadius(range-0.4)
		fireStorm3:setSpawnRate(1.0)
		fireStorm3:activate(position)
		pLight:setLocalPosition(position)
		pLight:setRange(range+1.0)
		pLight:setAmplitude(2.5)
		pLight:setVisible(true)
		--
		soundFireStorm:setLocalPosition(position)
		soundFireStorm:playFadeIn(1,false,0.25)
		--
		comUnit:broadCast(position,range,"attackFireDPS",{DPS=damage,time=ATTACKUPDATETIMER,type="fire"})
		comUnit:broadCast(position,range,"slow",{per=slow,time=ATTACKUPDATETIMER,type="mineCart"})
	end
	function self.isActive()
		return (fireStorm1:isActive() or fireStorm2:isActive())
	end
	function self.stop()
		fireStorm1:deactivate(0.25)
		fireStorm2:deactivate(0.25)
		fireStorm3:deactivate(0.25)
		pLight:clear()
		pLight:setVisible(false)
		soundFireStorm:stopFadeOut(0.25)
	end
	function self.update()
		if self.isActive() then
			local deltaTime = Core.getDeltaTime()
			fireStormTimer = fireStormTimer-deltaTime
			attackTimer = attackTimer-deltaTime
			if fireStormTimer<0.25 and fireStormTimer+Core.getDeltaTime()>=0.25 then
				fireStorm1:deactivate(0.25)
				fireStorm2:deactivate(0.25)
				fireStorm3:deactivate(0.25)
				pLight:pushRangeChange(0.0,0.25)
				soundFireStorm:stopFadeOut(0.25)
			end
			if attackTimer<0.0 then
				attackTimer = attackTimer+ATTACKUPDATETIMER
				comUnit:broadCast(position,range,"attackFireDPS",{DPS=damage,time=0.1,type="fire"})
				comUnit:broadCast(position,range,"slow",{per=slow,time=0.1,type="mineCart"})
			end
			return true
		else
			pLight:setVisible(false)
		end
		return false
	end
	local function init()
		pLight:setVisible(false)
		pLight:addFlicker(Vec3(0.2,0.15,0.05)*0.75,0.05,0.1)
		pLight:addSinCurve(Vec3(0.2,0.15,0.05),1.0)
		node:addChild(fireStorm1:toSceneNode())
		node:addChild(fireStorm2:toSceneNode())
		node:addChild(fireStorm3:toSceneNode())
		node:addChild(pLight:toSceneNode())
		node:addChild(soundFireStorm:toSceneNode())
	end
	init()
	return self
end