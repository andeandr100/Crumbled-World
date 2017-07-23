--this = SceneNode()
function create()
	local pLight = PointLight(Vec3(0.0,0.3,0.0),Vec3(1.4,1.0,0.0),2.0)
	this:addChild(pLight)
--	pLight:addFlicker(Vec3(0.2,0.15,0.0)*0.75,0.05,0.1)--can be flickering the entire world
--	pLight:addSinCurve(Vec3(0.2,0.15,0.0),1.0)
	return false
end