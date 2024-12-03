--this = SceneNode()

TowerBarPanel = {}
function TowerBarPanel.new(inParentPanel)
	local self = {}
	local parentPanel = inParentPanel
	local energyBar
	local overHeatBar
	local buildingBillBoard
	
	local function updateOverHeatBar()
		if overHeatBar:getVisible() then
			local enegrgy = buildingBillBoard:getFloat("overHeatPer")
			
			overHeatBar:setValue(enegrgy)
		end
	end
	
	local function updateEnergyBar()
		if energyBar:getVisible() then
			
			local enegrgy = buildingBillBoard:getInt("energy")
			local maxEnergy = buildingBillBoard:getInt("energyMax")
			energyBar:setText(Text(enegrgy.."/"..maxEnergy))
			energyBar:setValue(enegrgy/maxEnergy)
		end
	end
	
	function self.update(currentBuildingBillBoard)
		updateEnergyBar()
		updateOverHeatBar()
	end
	
	
	function self.updateBars(currentBuildingBillBoard)
		buildingBillBoard = currentBuildingBillBoard
		energyBar:setVisible(buildingBillBoard:exist("energy") and buildingBillBoard:exist("energyMax") );
		overHeatBar:setVisible(buildingBillBoard:exist("overHeatPer"))
	end
	
	
	local function init()
		energyBar = ProgressBar(PanelSize(Vec2(-1.0,0.1),PanelSizeType.ParentPercent), Text("0 / 0"), 0.0)
		energyBar:setTextColor(Vec3(1.0));
		energyBar:setInnerColor(Vec4(0,0,0,0.3), Vec4(0.1,0.1,0.1,0.6))
		energyBar:setColor(Vec4(0.5,0.5,1.1,0.75), Vec4(0,0,0.65,0.75))
		energyBar:setVisible(false)
	
		overHeatBar = ProgressBar(PanelSize(Vec2(-1.0,0.1),PanelSizeType.ParentPercent), Text(""), 0.0)
		overHeatBar:setTextColor(Vec3(1.0));
		overHeatBar:setInnerColor(Vec4(0,0,0,0.3), Vec4(0.1,0.1,0.1,0.6))
		overHeatBar:setColor(Vec4(1.0,0.5,0,0.75), Vec4(0.5,0.2,0.,0.75))
		overHeatBar:setVisible(false)
		
		parentPanel:add(energyBar)
		parentPanel:add(overHeatBar)
	end
	
	
	init()
	
	return self
end