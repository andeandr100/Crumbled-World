require("Menu/MainMenu/mainMenuStyle.lua")
require("Game/Abilities/boostAbility.lua")
require("Game/Abilities/slowfieldAbility.lua")
require("Game/Abilities/attackAbility.lua")
--this = SceneNode()

AbilitesMenu = {}
function AbilitesMenu.new()
	local self = {}
	local boostAbility = nil
	local slowfieldAbility = nil
	local slowFieldAbilityList = {}
	local attackAbility = nil
	local attackAbilityList = {}
	local posterForm	
	
	local comUnit
	local camera
	
	local comUnitTable = {}
	local boostButton
	local slowButton
	local attackButton
	local keyBinds = Core.getBillboard("keyBind");
	local keyBindRevertWave = keyBinds:getKeyBind("Revert wave")
	
	function self.destroy()
		if posterForm then
			print("Destroy posterForm\n")
			posterForm:setVisible(false)
			posterForm:destroy()
			posterForm = nil
		end
	end
	
	local function init()
		local rootNode = this:getRootNode();
		local cameras = rootNode:findAllNodeByNameTowardsLeaf("MainCamera")
		
		Core.setScriptNetworkId("AbilitiesMenu")
		comUnit = Core.getComUnit();
		comUnit:setName("AbilitiesMenu")
		comUnit:setCanReceiveTargeted(true);
		comUnit:setCanReceiveBroadcast(true);
		comUnitTable["waveChanged"] = self.waveChanged	
		comUnitTable["NetActivateSlowAbility"] = self.netSlowFieldEnabled
		comUnitTable["NetActivateAttackAbility"] = self.netAttackEnabled
		
		if #cameras == 1 then
			camera = ConvertToCamera(cameras[1])

			slowfieldAbility = SlowfieldAbility.new(camera, comUnit, true)
			boostAbility = BoostAbility.new(camera, comUnit)
			attackAbility = AttackAbility.new(camera, comUnit, true)
			posterForm = Form(camera, PanelSize(Vec2(1,0.1), Vec2(3.4,1)));
			
			posterForm:setName("Abilities form")
			posterForm:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor));
			posterForm:setLayout(FlowLayout());
			posterForm:getLayout():setPanelSpacing(PanelSize(Vec2(0.001)));
			posterForm:setRenderLevel(1)
			posterForm:setVisible(true)
			posterForm:getPanelSize():setFitChildren(true, true);
			posterForm:setFormOffset(PanelSize(Vec2(0.0, 0.0025)))
			posterForm:setAlignment(Alignment.BOTTOM_CENTER)
			
			
			--
			-- Add buttons  for the 3 abbilities 
			--
			local towerTexture = Core.getTexture("abilities.tga")
				
			boostButton = posterForm:add(Button(PanelSize(Vec2(1,0.07), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, Vec2(0.5,0.0), Vec2(1,0.5) ))
			--BoostButton:setBackground( Sprite( towerTexture ));
			boostButton:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
			boostButton:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			boostButton:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
			boostButton:addEventCallbackExecute(self.buttonPressed)		
			boostButton:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
			boostButton:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
			boostButton:setToolTip(Text("Boos tower, [<b>" .. boostAbility.getBoostKeyBind():getKeyBindName(0) .. "</b>]"))
			boostButton:setTag("boost")
			
			slowButton = posterForm:add(Button(PanelSize(Vec2(1,0.07), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, Vec2(0,0), Vec2(0.5,0.5) ))
			slowButton:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
			slowButton:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			slowButton:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))
			slowButton:addEventCallbackExecute(self.buttonPressed)		
			slowButton:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
			slowButton:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
			slowButton:setToolTip(Text("Slowfield, [<b>" .. slowfieldAbility.getSlowFieldKeyBind():getKeyBindName(0) .. "</b>]"))
			slowButton:setTag("slow")
			
			attackButton = posterForm:add(Button(PanelSize(Vec2(1,0.07), Vec2(1,1)), ButtonStyle.SIMPLE, towerTexture, Vec2(0.5,0.5), Vec2(1,1) ))
			attackButton:setInnerColor(Vec4(0,0,0,0.15),Vec4(0.2,0.2,0.2,0.35), Vec4(0.1,0.1,0.1,0.3))
			attackButton:setInnerHoverColor(Vec4(0,0,0,0),Vec4(0.2,0.2,0.2,0.5), Vec4(0.1,0.1,0.1,0.5))
			attackButton:setInnerDownColor(Vec4(0,0,0,0.3),Vec4(0.2,0.2,0.2,0.7), Vec4(0.1,0.1,0.1,0.6))	
			attackButton:addEventCallbackExecute(self.buttonPressed)	
			attackButton:setEdgeHoverColor(Vec4(1,1,1,1),Vec4(0.8,0.8,0.8,1))
			attackButton:setEdgeDownColor(Vec4(0.8,0.8,0.8,1),Vec4(0.6,0.6,0.6,1))
			attackButton:setToolTip(Text("Attack, [<b>" .. attackAbility.getAttackKeyBind():getKeyBindName(0) .. "</b>]"))
			attackButton:setTag("attack")
			
			posterForm:update();
		end
		
		
		restartListener = Listener("Restart")
		restartListener:registerEvent("restart", self.restartWave)
		
	end
	
	function self.restartWave()
		boostAbility.restartWave()
		boostButton:setEnabled(true)
		
		slowfieldAbility.restartWave()
		slowButton:setEnabled(true)
		
		attackAbility.restartWave()
		attackButton:setEnabled(true)
	end
	
	
	function self.buttonPressed(button)
		--button = Button()
		
		boostAbility.setAnotherAbilityButtonPressed()
		slowfieldAbility.setAnotherAbilityButtonPressed()
		attackAbility.setAnotherAbilityButtonPressed()
		
		if button:getTag():toString() == "boost" then
			boostAbility.setBoostButtonPressed()
		elseif button:getTag():toString() == "slow" then
			slowfieldAbility.setSlowFieldButtonPressed()
		elseif button:getTag():toString() == "attack" then
			attackAbility.setAttackButtonPressed()
		end
	end
	
	function self.netSlowFieldEnabled(param)
		local position = tovec3(param)
		
		for i=1, #slowFieldAbilityList do
			if slowFieldAbilityList[i].isActive() == false then
				slowFieldAbilityList[i].activate(position)
				return
			end
		end
		
		local index = #slowFieldAbilityList + 1
		slowFieldAbilityList[index] = SlowfieldAbility.new(camera, comUnit, false)
		slowFieldAbilityList[index].activate(position)
	end
	
	function self.netAttackEnabled(param)
		local position = tovec3(param)
		
		for i=1, #attackAbilityList do
			if attackAbilityList[i].isActive() == false then
				attackAbilityList[i].activate(position)
				return
			end
		end
		
		local index = #attackAbilityList + 1
		attackAbilityList[index] = AttackAbility.new(camera, comUnit, false)
		attackAbilityList[index].activate(position)
	end
	
	function self.waveChanged(param)
		boostAbility.waveChanged()
		boostButton:setEnabled(true)
		
		slowfieldAbility.waveChanged()
		slowButton:setEnabled(true)
		
		attackAbility.waveChanged()
		attackButton:setEnabled(true)
	end

	
	local function posterUpdate()
		if posterForm:getVisible() then
			posterForm:update();
		end
	end
	
	
	function self.restore(data)
		if data.posterForm then
			data.posterForm:setVisible(false)
			data.posterForm:destroy()
			data.posterForm = nil
		end
	end
	
	
	
	function self.update()
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			--print("selectedMenu: msg="..msg.message)
			if comUnitTable[msg.message]~=nil then
			 	comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			end
		end
		
		if keyBindRevertWave:getPressed() and (not Core.isInMultiplayer()) then
			self.restartWave()
		end
		
		if posterForm:getVisible() then
			posterUpdate()
			posterForm:update()
		end
		
		boostAbility.update()
		slowfieldAbility.update()
		attackAbility.update()
		
		for i=1, #slowFieldAbilityList do
			slowFieldAbilityList[i].update()
		end
		
		for i=1, #attackAbilityList do
			attackAbilityList[i].update()
		end
	
	
		if boostButton:getEnabled() == boostAbility.getBoostHasBeenUsedThisWave() then
			boostButton:setEnabled(not boostButton:getEnabled())
		end
		
		if slowButton:getEnabled() == slowfieldAbility.getSlowFieldHasBeenUsedThisWave() then
			slowButton:setEnabled(not slowButton:getEnabled())
		end
		
		if attackButton:getEnabled() == attackAbility.getAttackHasBeenUsedThisWave() then
			attackButton:setEnabled(not attackButton:getEnabled())
		end
		
	
		
		return true
	end
	
	
	
	
	init()
	return self
end
function create()
	abilitesMenu = AbilitesMenu.new()
	update = abilitesMenu.update
	destroy = abilitesMenu.destroy
	restore = abilitesMenu.restore
	return true
end