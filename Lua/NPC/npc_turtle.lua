require("NPC/npcBase.lua")
require("Enviromental/forceField.lua")
--this = SceneNode()
local npcBase
local soul
local soundForceFieldHitt
local shieldNode
function destroy()
	npcBase.destroy()
	if shieldNode then
		this:removeChild(shieldNode:toSceneNode())
		shieldNode = nil
	end
end
function create()
	
	npcBase = NpcBase.new()
	soul = npcBase.getSoul()
	soundForceFieldHitt = nil
	shieldNode = nil
	
	npcBase.init("turtle","npc_turtle.mym",1.4,0.6,1.35,2.0)
	npcBase.getSoul().enableBlood("BloodSplatterSphere",1.45,Vec3(0,0.15,0))
	npcBase.setDefaultState(state.shieldGenerator)
	--npcBase.getSoul().setResistance(0.0,true,true,0.0)
	local mat = npcBase.getModel():getLocalMatrix()
	mat:scale(Vec3(1.5,1.5,1.5))
	npcBase.getModel():setLocalMatrix(mat)
	--death animations
	local tableAnimationInfo = {{length = 2.5, duration = 1.5, blendTime=0.25},
								{length = 2.0, duration = 1.5, blendTime=0.25},
								{length = 2.0, duration = 1.5, blendTime=0.25}}
	local tableFrame = {startFrame = 5, endFrame = 70,
						framePositions = {10,35,60}}
	npcBase.addDeathAnimation(tableAnimationInfo,tableFrame)
	--physic animated death
	--npcBase.addDeathSoftBody(genereateSoftBody)
	--shield
	shieldRange = 3.5

	shieldNode = SceneNode.new()
	this:addChild(shieldNode:toSceneNode())
	ForceField.create(shieldNode,shieldRange,Vec3(0,0.75,0))
	npcBase.getComUnitTable()["addForceFieldEffect"] = handleAddForceFieldEffect

	soundForceFieldHitt = SoundNode.new("forceField_hitt")
	soundForceFieldHitt:setSoundPlayLimit(6)
	soundForceFieldHitt:setLocalSoundPLayLimit(4)
	
	
	debugHitTime = 0
	
	return true
end
function update()
	local ret = npcBase.update()
	if soul.getHp()<=0 and shieldNode then
		this:removeChild(shieldNode:toSceneNode())
		shieldNode = nil
	end
	
	
	debugHitTime = debugHitTime - Core.getDeltaTime()
--	while debugHitTime < 0 do
--		debugHitTime = debugHitTime + 0.1
--		local centerPos = Vec3(0,0.75,0)
--		local collPos = Vec3()
--		local atVec = Vec3(math.randomFloat(-1,1),-math.randomFloat(0.1,0.9),math.randomFloat(-1,1))
--		while atVec:length() < 0.3 do
--			atVec = Vec3(math.randomFloat(-1,1),-math.randomFloat(0.1,0.9),math.randomFloat(-1,1))
--		end
--		local line = Line3D( centerPos - atVec:normalizeV() * 6, centerPos )
--		local collPos, collisionPos =  Collision.lineSegmentSphereIntersection(line, Sphere( centerPos, 3.5))
--		if collision then
--			ForceField.addForceFieldHit( collPos, math.randomFloat(0.3,1))
--		end
--	end
	ForceField.update()
	
	return ret
end
function handleAddForceFieldEffect(param,fromIndex)
	--print("\nTurtle pos: "..param.."\n\n")
	local x,y,z,tX,tY,tZ,time = string.match(param, "(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
	local globalAttackPos = Vec3(tonumber(x),tonumber(y),tonumber(z))
	local globalTargetPos = Vec3(tonumber(tX),tonumber(tY)+0.75,tonumber(tZ))
	--attackPos = (this:getGlobalMatrix():inverseM()*attackPos):normalizeV()*256.0

	local globalPosition = this:getGlobalPosition()
	local centerPos = globalPosition + Vec3(0,0.75,0)
	local collPos = Vec3()
	
	--Core.addDebugLine(globalAttackPos, globalTargetPos, 0.5, Vec3(1,0,0))
	--sound
	soundForceFieldHitt:play(1.5,false)
	
	--Randomize the hit location looks better
	local atVec = (globalTargetPos-globalAttackPos):normalizeV()
	local upVec = atVec:crossProductV(Vec3(0,1,0))
	local rightVec = upVec:crossProductV(atVec)
	upVec = atVec:crossProductV(rightVec)
	upVec = upVec * math.randomFloat(-0.4,0.4)
	rightVec = rightVec * math.randomFloat(-0.4,0.4)
	--create the global collision line
	local line = Line3D( globalAttackPos, globalTargetPos + upVec + rightVec)
	
	--Core.addDebugSphere(Sphere( centerPos, 3.5), 0.05, Vec3(1,1,0))
	local collision, collPos = Collision.lineSegmentSphereIntersection(line, Sphere( centerPos, 3.5))
	if collision then
		--Core.addDebugSphere(Sphere(collPos, 0.1), 0.5, Vec3(1,1,1))
		ForceField.addForceFieldHit( collPos - globalPosition, tonumber(time))
	end
end
function genereateSoftBody()
	local softBody = SoftBody(npcBase.getModel():getMesh(0))
	softBody:setKDF( 1.0 )  --Dynamic friction coefficient [0,1]
	softBody:setKDG( 0.0 ) --Drag coefficient [0,+inf]
	softBody:setKLF( 0.0 ) --Lift coefficient [0,+inf]
	softBody:setKPR( 0.0 )
	softBody:setKVC( 0.0 )--Veolume conversation coefficient [0,+inf]
	softBody:setKMT( 0.0 ) --Pose matching coefficient [0,1]	
	softBody:setKDP( 0.1 )  --Damping coefficient [0,1]

	local material = softBody:appendMaterial()
	material:setKLST(0.2)-- Linear stiffness coefficient [0,1]
	material:setKAST(0.1)-- Area/Angular stiffness coefficient [0,1]
	material:setKVST(0.1)-- Volume stiffness coefficient [0,1]

	softBody:generateBendingConstraints(6, material)
	--softBody:randomizeConstraints()
	softBody:setTotalMass(30, false)
	softBody:generateClusters(24, 1024)
	softBody:setPose(false, false)
	softBody:addSoftBodyToPhysicWorld()
	softBody:setVelocity(npcBase.getMover():getCurrentVelocity() * 1 + Vec3(0,0,0))

	softBody:update()
	return softBody
end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end