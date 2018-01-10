--this = SceneNode()

function destroy()
--	if soulManager then
--		soulManager:removeThis()
--	end
end
local function setNetOwner(param)
	if param=="YES" then
		billboard:setBool("isNetOwner",true)
	else
		billboard:setBool("isNetOwner",false)
	end
end

function create()
	----this:setIsStatic(true)
	--upgrade 1
	model = Core.getModel("tower_wall.mym");
	this:addChild(model:toSceneNode());
	model:getMesh("hull"):setVisible(false)
	--model:setIsStatic(true)
	--model:render()
	
	Core.setUpdateHz(15)

	--Hull
	local hullModel = Core.getModel("tower_resource_hull.mym")
	hull3d = createHullList3d(hullModel:getMesh("hull"));
	hull2d = createHullList2d(hullModel:getMesh("hull"));

	--ComUnit
	comUnit = Core.getComUnit()
	comUnit:setCanReceiveTargeted(true)
	comUnit:setPos(this:getGlobalPosition())
	comUnit:broadCast(this:getGlobalPosition(),3.0,"shockwave","")
	--
	comUnitTable = {}
	comUnitTable["NetOwner"] = setNetOwner
	--
	billboard = comUnit:getBillboard()
	billboard:setFloat("value",35)--can never lose money on this tower(only intrest that could have been collected)
	billboard:setFloat("cost",35)
	billboard:setFloat("upgradeCost",100)
	billboard:setString("modelName","tower_wall.mym")
	billboard:setString("hullName","hull")
	billboard:setVectorVec3("hull3d",hull3d)
	billboard:setVectorVec2("hull2d",hull2d)
	billboard:setModel("tower",model)
	billboard:setString("Name", "Wall tower")
	billboard:setString("FileName", "Tower/WallTower.lua")
	billboard:setString("TargetArea","none")
	billboard:setBool("isNetOwner",true)
	

--	--soulManager
--	soulManager = this:findNodeByType(NodeId.soulManager)
--	if soulManager~=nil then--some tower will be placed in the void
--		--real world
--		soulManager:addSoul(1,this)
--		soulManager:updateSoul(this:getGlobalPosition(),Vec3(),1.0)
--	--else--some tower will be placed in the void
--	end
	return true
end
function update()
	while comUnit:hasMessage() do
		local msg = comUnit:popMessage()
		if comUnitTable[msg.message]~=nil then
			 comUnitTable[msg.message](msg.parameter,msg.fromIndex)
		end
	end
	return true
end