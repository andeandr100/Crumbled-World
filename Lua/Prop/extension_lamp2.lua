--this = SceneNode()
--this = SceneNode()
function create()
	local pLight = PointLight(Vec3(0.0,0.94,0.4),Vec3(1.5,1.1,0.0),4.0)
	pLight:addFlicker(Vec3(0.1,0.07,0.0)*0.75,0.1,0.2)
	pLight:addSinCurve(Vec3(0.1,0.07,0.0),2.0)
	pLight:setCutOff(0.1)
	this:addChild(pLight)
	return false
end