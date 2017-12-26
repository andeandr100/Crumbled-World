require("Menu/MainMenu/mainMenuStyle.lua")
--this = SceneNode()
InfoScreen = {}
function InfoScreen.new(camera)
	local self = {}
	local mainForm
	local isVisible = false
	local labelTab = {}
	local client
	local otherClientConnectionIssue = {}
	local startTime = Core.getTime()
	
	local players = {}
	
	function self.update()
		mainForm:update()
		--update clients
		for clientId,tab in pairs(players) do
			if client:isClientConnected(clientId)==true then
				if Core.getTime()-players[clientId].lastUpdated>3.0 then
					if Core.getTime()-startTime<=30.0 then
						--User is probably in loading screen
						local labels = labelTab[tab.listPos]
						labels.icon:setUvCoord(Vec2(0.5,0.625),Vec2(0.62,0.75))
						labels.ping:setText("Loading")
					else
						--user is losing connection
						local labels = labelTab[tab.listPos]
						labels.icon:setUvCoord(Vec2(0.375,0.625),Vec2(0.5,0.75))
						labels.ping:setText(tostring(math.floor(Core.getTime()-players[clientId].lastUpdated)).."s" )
					end
				end
			else
				local labels = labelTab[tab.listPos]
				labels.icon:setUvCoord(Vec2(0.5,0.625),Vec2(0.62,0.75))
				labels.name:setText(tab.name)
				labels.gold:setText("-")
				labels.kills:setText("-")
				labels.totalDamage:setText("-")
				labels.damage:setText("-")
				labels.speed:setText("-")
				labels.ping:setText("-")
				labels.name:setTextColor(Vec4(1,1,1,0.2))
				labels.gold:setTextColor(Vec4(1,1,1,0.2))
				labels.kills:setTextColor(Vec4(1,1,1,0.2))
				labels.totalDamage:setTextColor(Vec4(1,1,1,0.2))
				labels.damage:setTextColor(Vec4(1,1,1,0.2))
				labels.speed:setTextColor(Vec4(1,1,1,0.2))
				labels.ping:setTextColor(Vec4(1,1,1,0.2))
			end
		end
	end
	function self.manageConnectionIssues()
		if self.isAnyClientLosingConnection() and not(client and client:isConnected() and client:isLosingConnection()) then
			--another user has lost connection to the server
			if not otherClientConnectionIssue.speed then
				otherClientConnectionIssue.speed = Core.getBillboard("stats"):getInt("speed")
				Core.getNetworkClient():writeSafe("CMD-GameSpeed:0")
			end
			if self.isVisible()==false then
				self.togleVisible()
			end
		else
			if otherClientConnectionIssue.speed then
				--it has returned to normal, after someone was losing connection
				if self.isVisible()==true then
					self.togleVisible()
				end
				Core.getNetworkClient():writeSafe("CMD-GameSpeed:"..otherClientConnectionIssue.speed)
				--
				otherClientConnectionIssue = {}
			end
		end
	end
	function self.isAnyClientLosingConnection()
		if Core.getTime()-startTime>30.0 then
			for clientId,tab in pairs(players) do
				if client:getClientId()~=clientId and client:isClientConnected(clientId)==true then
					if Core.getTime()-players[clientId].lastUpdated>3.0 then
						return true
					end
				end
			end
		end
		return false
	end
	function self.isVisible()
		return isVisible
	end
	function self.togleVisible()
		if self.isAnyClientLosingConnection() then
			isVisible = true
		else
			isVisible = not isVisible
		end
		mainForm:setVisible(isVisible)
	end
	local function updateConnectedUsers()
		local tab = client:getConnected()
		local index = 1
		while tab[index] do
			players[tab[index].clientId] = {ping=tab[index].ping, totalDamage=0.0, damage=0.0, gold=0.0, speed=0, name=tab[index].name, playerId=tab[index].playerId}
			index = index + 1
		end
	end
	local function setDefaultLineColor(label,mNum)
		if mNum%2 == 0 then
			label:setBackground(Sprite(Vec4(1,1,1,0.05)))
		else
			label:setBackground(Sprite(Vec4(0)))
		end
	end
	function self.updateClientInfo(param)
		
		local dataTab = totable(param)
		local clientId = dataTab.clientId
		
		--update client damage info
		if players[tonumber(clientId)] then
			local labels = labelTab[players[tonumber(clientId)].listPos]
			labels.averageDamage = tonumber(dataTab.averageDamage)
			labels.totalDamageValue = tonumber(dataTab.totalDamage)
		end
		
		--get sum of total damage and sum of average damage
		local sumTotalAverageDamage = 1
		local sumTotalDamage = 1
		for clientId,tab in pairs(players) do
			local labels = labelTab[tab.listPos]
			sumTotalAverageDamage = sumTotalAverageDamage + labels.averageDamage
			sumTotalDamage = sumTotalDamage + labels.totalDamageValue
		end
		
--		print("\n\n")
--		print("sumTotalAverageDamage: "..sumTotalAverageDamage)
--		print("sumTotalDamage: "..sumTotalDamage)
		
		if players[tonumber(clientId)] then
			players[tonumber(clientId)].lastUpdated = Core.getTime()
			local labels = labelTab[players[tonumber(clientId)].listPos]			
			labels.icon:setUvCoord(Vec2(0.375,0.75),Vec2(0.5,0.875))
			labels.name:setText(dataTab.name)
			labels.gold:setText(tostring(dataTab.gold))
			labels.kills:setText(tostring(dataTab.kills))
			
--			print("------------------------")
--			print("totalDamage: "..dataTab.totalDamage)
--			print("averageDamage: "..dataTab.averageDamage)
--			print("------------------------\n")
			
			labels.totalDamage:setText(tostring( math.round(tonumber(dataTab.totalDamage)/sumTotalDamage*100.0)).."%") 
			labels.damage:setText(tostring( math.round(tonumber(dataTab.averageDamage)/sumTotalAverageDamage*100.0)).."%")
			labels.speed:setText(tostring(dataTab.speed))
			labels.ping:setText(tostring(dataTab.ping).."ms")
		else
--			local pList = players
--			error("ClientId not used")
--			abort()
		end
	end
	local function init()
		client = Core.getNetworkClient()
		
		
		local weight = {-0.35}
		for i=1, 6 do
			weight[i+1] = -1.0/(7-i)
		end
		weight[5] = weight[5] * 1.4
		
		updateConnectedUsers()
		
		mainForm = Form( camera, PanelSize(Vec2(-0.7,-0.45), Vec2(5,2.5)), Alignment.MIDDLE_CENTER);
		mainForm:setName("InfoScreen form")
		mainForm:setLayout(FallLayout( Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))));
		mainForm:setRenderLevel(11)
		mainForm:setBackground(Gradient(MainMenuStyle.backgroundTopColor, MainMenuStyle.backgroundDownColor))
		mainForm:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)), MainMenuStyle.borderColor))
		mainForm:setVisible(isVisible)
		
		mainPanel = mainForm:add(Panel(PanelSize(Vec2(-1))))
		mainPanel:setLayout(FallLayout(Alignment.TOP_CENTER, PanelSize(Vec2(0,0.01))))
		
		mainPanel:add(Panel(PanelSize(Vec2(-1, -0.05))))
		
		local contentPanel = mainPanel:add(Panel(PanelSize(Vec2(-0.9, -0.9474))))--95%
		--
		contentPanel:setBackground(Gradient(Vec4(1,1,1,0.01), Vec4(1,1,1,0.025)))
		
		local headerPanel = contentPanel:add(Panel(PanelSize(Vec2(-1, 0.035))))
		headerPanel:setBackground(Gradient(Vec4(1,1,1,0.05), Vec4(1,1,1,0.1)))
		
		
		headerPanel:add(Panel(PanelSize(Vec2(-1),Vec2(1))))
		local namePanel = headerPanel:add(Panel(PanelSize(Vec2(weight[1], -1))))
--		namePanel:add(Panel(PanelSize(Vec2(-0.1, -1))))
		namePanel:add(Label(PanelSize(Vec2(-1.0)), language:getText("name"), Vec4(0.95)))
		--
		local killsPanel = headerPanel:add(Panel(PanelSize(Vec2(weight[2], -1))))--language:getText("Total damage")
		local icon = killsPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") ))
		icon:setUvCoord(Vec2(0.625,0.4375),Vec2(0.75,0.5))
		icon:setToolTip(Text("Kills"))
		--
		local totalDamagePanel = headerPanel:add(Panel(PanelSize(Vec2(weight[3], -1))))--language:getText("Total damage")
		local icon = totalDamagePanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") ))
		icon:setUvCoord(Vec2(0.25,0.0),Vec2(0.375,0.0625))
		icon:setToolTip(Text("Total damage"))
		--
		local damagePanel = headerPanel:add(Panel(PanelSize(Vec2(weight[4], -1))))--language:getText("Average damage")
		local icon = damagePanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") ))
		icon:setUvCoord(Vec2(0.25,0.0),Vec2(0.375,0.0625))
		icon:setToolTip(Text("Average damge per wave"))
		--
		local goldPanel = headerPanel:add(Panel(PanelSize(Vec2(weight[5], -1))))--language:getText("gold")
		local icon = goldPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") ))
		icon:setUvCoord(Vec2(0,0),Vec2(0.125,0.0625))
		--
		local speedPanel = headerPanel:add(Panel(PanelSize(Vec2(weight[6], -1))))
		local icon = speedPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") ))
		icon:setUvCoord(Vec2(0.375,0.25),Vec2(0.5,0.3125))
		--
		local pingPanel = headerPanel:add(Panel(PanelSize(Vec2(weight[7], -1))))--language:getText("ping")
		local icon = pingPanel:add(Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") ))
		icon:setUvCoord(Vec2(0.125,0.375),Vec2(0.25,0.4375))
		--
		--
		--
		local listPanel = contentPanel:add(Panel(PanelSize(Vec2(-1, -1))))
		for clientId,tab in pairs(players) do
			local line = listPanel:add(Panel(PanelSize(Vec2(-1,0.03))))
			local icon = Image(PanelSize(Vec2(-1), Vec2(1)), Text("icon_table.tga") )
			setDefaultLineColor(line,1)
			line:setLayout(FlowLayout(Alignment.TOP_LEFT))
			tab.lastUpdated = Core.getTime()
			tab.listPos = #labelTab+1
			labelTab[tab.listPos] = {}
			local labels = labelTab[tab.listPos]
			labels.averageDamage = 0
			labels.totalDamageValue = 0
			
			labels.icon = 		line:add(icon)
			labels.name = 		line:add(Label(PanelSize(Vec2(weight[1], -1)), tab.name, Vec4(0.95)))
			labels.kills =		line:add(Label(PanelSize(Vec2(weight[2], -1)), "0", Vec3(0.95)))--language:getText("score")
			labels.totalDamage =line:add(Label(PanelSize(Vec2(weight[3], -1)), "0%", Vec3(0.95)))--language:getText("score")
			labels.damage = 	line:add(Label(PanelSize(Vec2(weight[4], -1)), "0%", Vec3(0.95)))--language:getText("score")
			labels.gold = 		line:add(Label(PanelSize(Vec2(weight[5], -1)), tostring(tab.gold), Vec3(0.95)))--language:getText("gold")
			labels.speed = 		line:add(Label(PanelSize(Vec2(weight[6], -1)), tostring(tab.speed), Vec3(0.95)))
			labels.ping = 		line:add(Label(PanelSize(Vec2(weight[7], -1)), tostring(tab.ping), Vec3(0.95)))--language:getText("ping")
		end
	end
	init()
	
	return self
end