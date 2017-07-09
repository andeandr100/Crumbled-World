require("NPC/npcBase.lua")
require("NPC/hydraBase.lua")
--this = SceneNode()
local npcBase
function destroy()
	npcBase.destroy()
end
function create()
	
	npcBase = NpcBase.new()
		
	createHydra(1,0.5,npcBase)
	--
	local tableAnimationInfo = {{duration = 0.75, length = 1.0, blendTime=0.25},
								{duration = 0.75, length = 1.0, blendTime=0.25},
								{duration = 0.75, length = 1.0, blendTime=0.25}}
	local tableFrame = {startFrame = 5,
						endFrame = 45,
						framePositions = {10,23,36}}
	npcBase.addDeathAnimation(tableAnimationInfo,tableFrame)
	--npcBase.addDeathSoftBody(genereateSoftBody)
	--
	createPushFunctions()
	if updatePush and type(updatePush)=="function" then
		update = updatePush
	else
		error("unable to set update function")
	end
	return true
end
function genereateSoftBody()
	local softBody = SoftBody(npcBase.getModel():getMesh(0))

	softBody:setKDF( 2.0 )  --Dynamic friction coefficient [0,1]
	softBody:setKDG( 5.0 ) --Drag coefficient [0,+inf]
	softBody:setKLF( 0.05 ) --Lift coefficient [0,+inf]
	softBody:setKPR( 1.0 )
	softBody:setKVC( 2.0 )--Volume conversation coefficient [0,+inf]
	softBody:setKMT( 0.01 ) --Pose matching coefficient [0,1]	
	softBody:setKDP( 0.01 )  --Damping coefficient [0,1]

	local material = softBody:appendMaterial()
	material:setKLST(0.1)-- Linear stiffness coefficient [0,1]
	material:setKAST(0.005)-- Area/Angular stiffness coefficient [0,1]
	material:setKVST(0.1)-- Volume stiffness coefficient [0,1]
	
	softBody:generateBendingConstraints(6, material)

	--softBody:randomizeConstraints()
	softBody:setTotalMass(3, false)
	softBody:generateClusters(32, 512)

	softBody:setPose(true, false)
	softBody:addSoftBodyToPhysicWorld()
	softBody:setVelocity(npcBase.getMover():getCurrentVelocity() * 1.2 + Vec3(0,1,0))

	softBody:update()
	return softBody
end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end