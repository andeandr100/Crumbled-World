--this = SceneNode()


TowerImage = {}
TowerImage.rootNodes = {}

MenuIconTowerCameras = {}
MenuIconTowerCameras.reRenderCounter = 5

buildingImages = {}
buildingImagesSize = 1

function TowerImage.destroy()
	for i=1, #TowerImage.rootNodes do
		TowerImage.rootNodes[i]:destroyTree()
	end
	TowerImage.rootNodes = nil
	MenuIconTowerCameras = nil
	
end

function TowerImage.createTowerImage(towerScriptName)
	--World Node
	local rootNode = RootNode()
	TowerImage.rootNodes[#TowerImage.rootNodes+1] = rootNode
	
	--Tower Node
	local towerNode = rootNode:addChild( SceneNode() )
	--towerNode:setIsStatic(true)

	local luaScript = towerNode:loadLuaScript(towerScriptName)
	towerNode:update()--execute lua functions

	--Camera
	local towerCamera =  rootNode:addChild( Camera(Text("TowerCamera"),true,200,200) )
	towerCamera:setAmbientLight(AmbientLight(Vec3(1.0)))	
	
	--Camera Matrix
	local buildingModel = towerNode:findNodeByType(NodeId.model)
	local modelBounds = buildingModel:getGlobalModelBounds()
	local lookAt = Vec3(0,1.5,0)
	local camPos = lookAt + Vec3(1,1,1):normalizeV() * 4
	local camMatrix = Matrix();
	camMatrix:createMatrix((camPos-lookAt):normalizeV(), Vec3(0,1,0))
	camMatrix:setPosition(camPos )
	towerCamera:setLocalMatrix(camMatrix)
	
	if luaScript then
		luaScript:setName("tower");
		towerCamera:render()
	else
		return nil
	end

	buildingImages[buildingImagesSize] = towerCamera
	buildingImagesSize = buildingImagesSize + 1
	
	MenuIconTowerCameras[#MenuIconTowerCameras+1] = towerCamera
	
	return towerCamera:getTexture()
end

function TowerImage.update()
	if MenuIconTowerCameras.reRenderCounter > 0 then
		MenuIconTowerCameras.reRenderCounter = MenuIconTowerCameras.reRenderCounter - 1
		for i=1, #MenuIconTowerCameras do
			MenuIconTowerCameras[i]:render()
		end
	end
end