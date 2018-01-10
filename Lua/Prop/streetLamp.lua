--this = SceneNode()
function create()
	local pLight = PointLight.new(Vec3(1.2,1.95,0),Vec3(1.0,1.0,0.0),6.0)
	this:addChild(pLight:toSceneNode())
--	pLight:addFlicker(colorVariations*0.75,0.05,0.1)
--	pLight:addSinCurve(colorVariations,1.0)
	return false
end