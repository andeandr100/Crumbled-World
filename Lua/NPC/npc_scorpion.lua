require("NPC/npcBase.lua")
--this = SceneNode()
local npcBase
function destroy()
	print("Destroy = "..tostring(Core.getNetworkName()) )
	npcBase.destroy()
end
function create()
	
	npcBase = NpcBase.new()
	npcBase.init("scorpion","npc_scorpion1.mym",0.225,0.6,0.45,2.0)
	npcBase.getSoul().enableBlood("BloodSplatterSphere",1.75,Vec3(0,0.25,0))
	local tableAnimationInfo = {{duration = 0.65, length = 0.44, blendTime=0.25},
								{duration = 0.75, length = 0.98, blendTime=0.25},
								{duration = 0.71, length = 1.08, blendTime=0.25},
								{duration = 0.67, length = 1.00, blendTime=0.25}}
	local tableFrame = {startFrame = 0,
						endFrame = 18,
						framePositions = {5,14,10,1}}
	npcBase.addDeathAnimation(tableAnimationInfo,tableFrame)
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
function update()
	error("this should not be used!!!")
	return true
end
function soulSetCantDie()
	npcBase.getSoul().soulSetCanDie(false)
end
function reachedWaypointCallback(param)
	npcBase.reachedWaypointCallback()
end