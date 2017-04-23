--this = SceneNode()
function create()
	local towerList = {}
	towerList[0] = "WallTower"
	towerList[1] = "MinigunTower"
	towerList[2] = "ArrowTower"
	towerList[3] = "SwarmTower"
	towerList[4] = "ElectricTower"
	towerList[5] = "BladeTower"
	towerList[6] = "missileTower"
	local towerListSize = 1
	local island = this:getRootNode():findAllNodeByNameTowardsLeaf("island1")
	island:loadLuaScript()
	return true
end

function update()
	return false;   
end