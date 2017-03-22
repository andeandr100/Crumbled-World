require("NPC/npcBase.lua")
--this = SceneNode()
local npcBase = NpcBase.new()
function destroy()
end
function create()
	npcBase.init("rat","npc_rat.mym",0.175,0.4,0.45,3.5)
	local mat = npcBase.getModel():getLocalMatrix()
	npcBase.getSoul().enableBlood("BloodSplatterSphere",1.0,Vec3(0,0.2,0))
	mat:scale(Vec3(0.75,0.75,0.75))
	npcBase.getModel():setLocalMatrix(mat)
	--death animations
	local tableAnimationInfo = {{length = 4.10, duration = 1.42, blendTime=0.25},
								{length = 1.95, duration = 1.00, blendTime=0.50},
								{length = 1.75, duration = 0.95, blendTime=0.50}}
	local tableFrame = {startFrame = 0,
						endFrame = 21,
						framePositions = {5,12,19}}
	npcBase.addDeathAnimation(tableAnimationInfo,tableFrame)
	--physic animated death
	npcBase.addDeathSoftBody(genereateSoftBody)
	if npcBase.update and type(npcBase.update)=="function" then
		update = npcBase.update
	else
		error("unable to set update function")
	end
	return true
end
function genereateSoftBody()
	local softBody = SoftBody(npcBase.getModel():getMesh(0))
	
	softBody:setKDF( 1.0 )  --Dynamic friction coefficient [0,1]
	softBody:setKDG( 4.0 ) --Drag coefficient [0,+inf]
	softBody:setKLF( 4.0 ) --Lift coefficient [0,+inf]
	softBody:setKPR( 2.0 )
	softBody:setKVC( 2.2 )--Volume conversation coefficient [0,+inf]
	softBody:setKMT( 0.075 ) --Pose matching coefficient [0,1]	
	softBody:setKDP( 0.0 )  --Damping coefficient [0,1]

	local material = softBody:appendMaterial()
	material:setKLST(0.1)-- Linear stiffness coefficient [0,1]
	material:setKAST(0.0)-- Area/Angular stiffness coefficient [0,1]
	material:setKVST(0.0)-- Volume stiffness coefficient [0,1]
	
	softBody:generateBendingConstraints(4, material)

	softBody:randomizeConstraints()
	softBody:setTotalMass(3, false)
	softBody:generateClusters(24, 1024)

	softBody:setPose(false, true)
	softBody:addSoftBodyToPhysicWorld()
	softBody:setVelocity(npcBase.getMover():getCurrentVelocity()+ Vec3(0,1,0))
	
	return softBody
end
function update()
	return true
end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end