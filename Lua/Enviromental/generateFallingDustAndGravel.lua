--this = SceneNode()
function create()
--	local islands = this:getRootNode():findAllNodeByNameTowardsLeaf("*island*")
--
--	for i=0, islands:size()-1, 1 do
--		generateFallingDustAndGravel(islands:item(i))
--	end
	return false
end
function generateFallingDustAndGravel(island)
	local list = island:findAllNodeByNameTowardsLeaf("*worldedge*")

	for i=0, list:size()-1, 1 do
		if math.randomFloat()>0.5 then
			list:item(i):loadLuaScript("Enviromental/fallingDustAndGravel.lua")
		end
	end
end
function update()
	return false
end