require("Game/particleEffect.lua")
--this = SceneNode()
local waveData = {}
local statsBilboard = Core.getBillboard("stats")

local CRYSTAL_STATUS_ALIVE		= 1
local CRYSTAL_STATUS_DETONATED	= 2

-- function:	destroyCrystal
-- purpose:		makes a nice effect where the crystal is shattered inti several pices
function destroyCrystal()
	crystalStatus = CRYSTAL_STATUS_DETONATED
	if not model then
		--particle effect
		destroyNode = SceneNode.new()
		destroyNode:setLocalPosition(localPos)
		this:getParent():addChild(destroyNode)
	 	local effect = ParticleSystem.new(ParticleEffect.endCrystalExplosion)
		destroyNode:addChild(effect:toSceneNode())
		effect:activate(Vec3(0,0.75,0))
		--physic
		model=Core.getModel("end_crystal_cracked.mym")
		this:getParent():addChild(model:toSceneNode())
		model:setLocalMatrix(this:getLocalMatrix())
		model:setVisible(false)
		
		for i=1, 24 do
			local atVec = model:getMesh("crystal"..i):getLocalPosition()-Vec3(0.0,0.3,0.0)
			atVec = Vec3(atVec.x*6,atVec.y*4,atVec.z*6)
			rigidBodies[#rigidBodies+1] = RigidBody.new(this:findNodeByType(NodeId.island),model:getMesh("crystal"..i),atVec)
		end
	end
	this:getChildNode(0):setVisible(false)
end
-- function:	cleanUpDestroyedCrystal
-- purpose:		cleares up all debri when the crystal detonates
function cleanUpDestroyedCrystal()
	if model then
		--destroy model
		if model then
			model:destroyTree()
			model = nil
		end
		
		--pEffect node
		if destroyNode then
			destroyNode:destroyTree()
		end
		
		--physic node
		for i=1, #rigidBodies do
			rigidBodies[i]:destroyTree()
		end
		rigidBodies={}
	end
end
-- function:	defeated
-- purpose:
function create()
	--comUnit
	rigidBodies = {}
	model = nil
	
	--crystal
	crystalStatus = CRYSTAL_STATUS_ALIVE
	timer = 0.0
	localPos = this:getLocalPosition()
	pLight = PointLight.new(Vec3(2.0,0.4,0.0),3.5)
	pLight:setLocalPosition(Vec3(0,0.5,0))
	this:addChild(pLight:toSceneNode())
	
	particleNode = SceneNode.new()
	this:addChild(particleNode)
	
	--spirits
	TOTAL_SPIRIT_COUNT = 20
	spiritCount = TOTAL_SPIRIT_COUNT
	spirits = {}
	for i=1, spiritCount do
		spirits[i] = {time1=math.randomFloat()*16.0,time2=math.randomFloat()*16.0,timeMul1=math.randomFloat(0.30,0.50),timeMul2=math.randomFloat(0.075,0.15),mat1=Matrix(),mat2=Matrix(),axis=math.randomVec3(),posVec=math.randomVec3()*0.78,effect=ParticleSystem.new(ParticleEffect.endCrystalSpirit)}
		local spirit = spirits[i]
		spirit.mat1:createMatrix(math.randomVec3(),math.randomVec3())
		spirit.mat2:createMatrix(math.randomVec3(),math.randomVec3())
		particleNode:addChild(spirit.effect:toSceneNode())
		spirit.effect:activate(Vec3())
	end
	explosion = {size=0}

	return true
end
-- function:	update
-- purpose:		updates the script every frame
function update()
	if crystalStatus == CRYSTAL_STATUS_DETONATED then
		local count = (statsBilboard and statsBilboard:getInt("life")) or TOTAL_SPIRIT_COUNT
		if count>0 then
			cleanUpDestroyedCrystal()
			this:setLocalPosition(localPos)
			this:getChildNode(0):setVisible(true)
			crystalStatus = CRYSTAL_STATUS_ALIVE
		end
	end
	if crystalStatus == CRYSTAL_STATUS_ALIVE then
		statsBilboard = statsBilboard or Core.getBillboard("stats")
		local count = (statsBilboard and statsBilboard:getInt("life")) or TOTAL_SPIRIT_COUNT
		--manage if spirit count have changed
		if count~=spiritCount then
			if count==0 and spiritCount>0 then
				--destroy crystal
				destroyCrystal()
			end
			if count<spiritCount and count+1==spiritCount then
				--we lost spirit(s)
				doSpiritExplosion(spirits[spiritCount].effect:getLocalPosition())
				spirits[spiritCount].effect:setVisible(false)
			end
			spiritCount = count
			--set visability on spirits
			for i=1, TOTAL_SPIRIT_COUNT do
				spirits[i].effect:setVisible(i<=spiritCount)
			end
		end
		--update spirits and crystal
		if spiritCount>0 then
			--spirits
			for i=1, spiritCount do
				local spirit = spirits[i]
				spirit.time1 = spirit.time1 + Core.getDeltaTime()*spirit.timeMul1
				spirit.time2 = spirit.time2 + Core.getDeltaTime()*spirit.timeMul2
				spirit.mat1:rotate(spirit.axis,spirit.time1)
				spirit.mat2:rotate(spirit.mat1:getUpVec(),spirit.time2)
				spirit.effect:setLocalPosition(spirit.mat2*spirit.posVec+Vec3(0.0,1.05,0.0))
			end
			--crystal
			timer = timer + (Core.getDeltaTime()*0.75)
			this:setLocalPosition(Vec3(0,0.25+0.1*math.sin(timer),0)+localPos)
		end
	end
	return true
end
-- function:	doSpiritExplosion
-- purpose:		generats the particle effect for the detonation of the spirit
function doSpiritExplosion(pos)
	for i=1, explosion.size do
		if explosion[i]:isActive()==false then
			explosion[i]:activate(pos)
			return
		end
	end
	explosion.size = explosion.size + 1
	explosion[explosion.size] = ParticleSystem.new(ParticleEffect.endCrystalSpiritExplosion)
	this:addChild(explosion[explosion.size]:toSceneNode())
	explosion[explosion.size]:activate(pos)
end