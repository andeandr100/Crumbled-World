require("Game/spawnManager.lua")
--this = SceneNode()

EventBase = {}
function EventBase.new()
	local self = {}
	
	local spawnManager = SpawnManager.new()
	
	local EVENT_WAIT_FOR_TOWER_TO_BE_BUILT =		1
	local EVENT_WAIT_FOR_START_BUTTON_BUILT =		2
	local EVENT_WAIT_UNTILL_ALL_ENEMIS_ARE_DEAD =	3
	local EVENT_CHANGE_WAVE =						4
	local EVENT_START_SPAWN =						5 
	local EVENT_END_GAME =							6
	local EVENT_END_MENU =							7
	
	local currentState = 0
	
	local waveRestarted = false
	local previousWaveCounter = 0			--smount of time that we has gone back in time
	
	
	local mapInfo = MapInfo.new()
	local STARTWAVE = mapInfo.getStartWave()
	local waveCount = STARTWAVE		--what wave we are currently playing
	local waveCountState = 0
	local comUnit = Core.getComUnit()--"EventManager"
	local comUnitTable = {}
	local bilboardStats = Core.getBillboard("stats")
	--local soulmanager
	local waveUnitIndex = 0
	local numTowers = 0
	local wavePoints = 0
	local pWaveFinishedBonus = 200
	local wait = 15			--gives the player more time to setup the first defense
	local waitBase = wait
	local state = 0
	local mapFinishingLevel = 0
	local mapStatId = ""
	local steamStatMinPlayedTime = 0.0
	local cData = CampaignData.new()
	--local soundWind = Sound("wind1",SoundType.STEREO)
	local spawnPattern = SPAWN_PATTERN.Random
	--keybinds
	local keyBinds = Core.getBillboard("keyBind")
	local keyBindRevertWave
	--
	local currentPortalId = 1
	local currentSpawn
	local restartListener
	local destroyInNFrames = nil
	local restartInWaves = nil
	local restartTimer = Core.getGameTime()
	--this:addChild(soundWind)
	--
	--
	
	local function sendNetworkSyncSafe(msg,param)
		local tab = Core.getNetworkClient():getConnected()
		for index=1, Core.getNetworkClient():getConnectedPlayerCount() do
			if tab[index] then
				comUnit:sendNetworkSyncSafeTo("Event"..tostring(tab[index].clientId),msg,param)
			end
		end
	end
	
	local function destroyEventBase()
		if destroyInNFrames <= 0 then
			this:loadLuaScript(this:getCurrentScript():getFileName());
			print("Event destroy()")
			return false	 
		else
			destroyInNFrames = destroyInNFrames - 1
			return true
		end
	end
	
	function self.getSpawnManager()
		return spawnManager
	end
	
	--Gold options
	local function setGold(gold)
		if not Core.isInMultiplayer() then
			local gMul = 1.0 + ( (mapInfo.getPlayerCount()-1)*0.5 )
			comUnit:sendTo("stats", "setGold", tostring(gold*gMul))
		else
			comUnit:sendTo("stats", "setGold", tostring(gold))
		end
	end
	function restartMapCalledFromTheOutSide()
		--set to first wave
		waveCount = STARTWAVE+1
		--go back one wave (this will restart the map)
		self.doRestartWave(true)
	end
	function doRestartMap()
		--set to first wave
		--waveCount = STARTWAVE+1
		--go back one wave (this will restart the map)
		self.doRestartWave(false)
	end
	
	
	--Towers
	local function isPlayerReady()
		local buildingBillboard = Core.getBillboard("buildings")
		return buildingBillboard:getBool("Ready")
	end
	
	local function getCopyOfTable(table)
		if type(table)~="table" then
			return table
		end
		--it is a table
		local ret = {}
		for k,v in pairs(table) do
			ret[k] = getCopyOfTable(v)
		end
		return ret
	end
	local function calculateGoldForWave(waveNumber)
		if waveFinishedBonus then
			if type(waveFinishedBonus)=="function" then
				return waveFinishedBonus()
			else
				return tonumber(waveFinishedBonus)
			end
		else
			return 0
		end
	end
	local function waveFinishedMoneyBonus()
		local waveBonus = calculateGoldForWave(waveCount)
		comUnit:sendTo("log","println",string.format("WaveBonus(%.1f)",waveBonus))
		comUnit:sendTo("stats", "addGoldWaveBonus", tostring(waveBonus))	--earned a static gold amount
	end
	local function setWaveNumber(waveNumber)
		waveCount = waveNumber
		if waveCount <= spawnManager.getWavesSize() then
			--first the most important gold (because it needs to be registered when going back in history
			local waveInfo = spawnManager.getWaveInfo()
			if waveInfo[waveCount] then
				comUnit:sendTo("stats", "setTotalHp", waveInfo[waveCount].totalHp)
				comUnit:sendTo("stats", "addWaveGold", waveInfo[waveCount].waveGold-calculateGoldForWave(waveCount))
			end
		end
	end
	local function changeWave()
		if waveCount+1<=spawnManager.getNumWaves() then
			comUnit:sendTo("SteamStats","MaxWaveFinished",waveCount)
			if waveCount==20 then
				local towerBuilt = bilboardStats:getInt("minigunTowerBuilt") + bilboardStats:getInt("arrowTowerBuilt") + bilboardStats:getInt("swarmTowerBuilt") + bilboardStats:getInt("electricTowerBuilt") + bilboardStats:getInt("bladeTowerBuilt") + bilboardStats:getInt("quakeTowerBuilt") + bilboardStats:getInt("missileTowerBuilt")
				if towerBuilt<=5 then
					comUnit:sendTo("SteamAchievement","TinySystem","")
				end
			end
			if waveCount>0 then
				--local waveStart = math.floor((waveCount-1)/5)
				comUnit:broadCast(Vec3(),512,"waveChanged",tostring(waveCount)..";"..waveCount)
			end
			--
			--
			--
			if mapInfo.getGameMode()=="survival" then
				comUnit:sendTo("stats","setBillboardInt","survivalBonus;"..math.floor(waveCount/10))
			end
			--
			--
			--
			comUnit:sendTo("log","println", "========= Wave "..waveCount.." =========")
			if waveCount>0 then
				if waveRestarted==false then
					waveFinishedMoneyBonus()
				end
			end
			setWaveNumber( waveCount + 1 )
			return true
		end
		return false
	end
	local function syncChangeWave(param)
		local waveNum = tonumber(param)
		while waveNum>waveCount do
			endGameMenuScreen = nil
			eventBaserunOnlyOnce = nil
			currentState = EVENT_CHANGE_WAVE
			self.update()
		end
	end
	local function startButtonPressed()
		if currentState == EVENT_WAIT_FOR_START_BUTTON_BUILT then
			currentState = EVENT_CHANGE_WAVE
		end
	end
	function self.init(pStartGold,pWaveFinishedBonus,pInterestMulOnKill,pLives,pLevel)
		--make sure that only one event script is running
		if Core.getScriptOfNetworkName("Event"..(Core.isInMultiplayer() and Core.getNetworkClient():getClientId() or "-")) then
			return false
		end
		Core.setScriptNetworkId("Event"..(Core.isInMultiplayer() and Core.getNetworkClient():getClientId() or "-"))
		
		keyBindRevertWave = keyBinds:getKeyBind("Revert wave")
		
		restartListener = Listener("Restart")
		restartListener:registerEvent("restart", restartMapCalledFromTheOutSide)
		
		comUnitTable["ChangeWave"] = syncChangeWave
		comUnitTable["EventBaseRestartWave"] = doRestartMap
		spawnManager.init(comUnitTable, pWaveFinishedBonus)
		--
		mapFinishingLevel = pLevel
		comUnit:setName("EventManager")
		comUnit:setCanReceiveTargeted(true)
		comUnit:setCanReceiveBroadcast(false)
	
		--mapp setttings for initiating the waves
		waveFinishedBonus = pWaveFinishedBonus
		comUnit:sendTo("stats","setInteresetMultiplyerOnKill",tonumber(pInterestMulOnKill))
		setGold(pStartGold)
		comUnit:sendTo("stats", "setMaxLife", tostring(pLives))
		local tab = {startGold=pStartGold,WaveFinishedBonus=pWaveFinishedBonus,lives=pLives,level=pLevel}
		--comUnit:sendNetworkSyncSafe("NetInitData",tabToStrMinimal(tab))
		sendNetworkSyncSafe("NetInitData",tabToStrMinimal(tab))
		--
		--	SteamStat id
		--
		local fileName = mapInfo.getMapFileName()
		local index1 = fileName:match(".*/()")
		index1 = index1 and index1 or 1
		local index2 = fileName:match(".*%.()")
		if index1 and index2 then
			fileName = fileName:sub(index1,index2-2)
			local i=1
			local len = fileName:len()
			local count=0
			repeat
				i = fileName:find("%s")
				if i then
					local str = fileName:sub(1,i-1)
					if i<=fileName:len() then
						str = str..string.upper(fileName:sub(i+1,i+1))
					end
					fileName = str..fileName:sub(i+2,fileName:len())
				end
			until not i
		end
		mapStatId = fileName
		
		--
		--
		--
		
		--soundWind:playSound(0.055,true)
		--
		--Special case first wave
		if mapInfo.getGameMode()~="training" then
			currentState = EVENT_WAIT_FOR_TOWER_TO_BE_BUILT
		else
			currentState = EVENT_WAIT_FOR_START_BUTTON_BUILT
		end
		return true
	end
	function self.setDefaultGold(pStartGold,pWaveFinishedBonus,pInterestMulOnKill,pGoldMultiplayerOnKills)
		waveFinishedBonus = pWaveFinishedBonus
		spawnManager.setGoldMultiplayerOnKills(pGoldMultiplayerOnKills)
		comUnit:sendTo("stats","setInteresetMultiplyerOnKill",tonumber(pInterestMulOnKill))
		setGold(pStartGold)
	end
	function self.doRestartWave(restartedFromTheOutSide)
		if waveCount>=(STARTWAVE+1) then
			waveRestarted = true
			restartTimer = Core.getGameTime()
			waveCount = math.max(STARTWAVE, spawnManager.isFirstNpcOfWaveSpawned() and (waveCount - 1) or (waveCount - 2) )
			comUnit:sendTo("SteamStats","ReverseTimeCount",1)
			previousWaveCounter = previousWaveCounter + 1		--acievment stat counter
			spawnManager.clearActiveSpawn()
			endGameMenuScreen = nil
			eventBaserunOnlyOnce = nil
			if waveCount==STARTWAVE then
				--if restart was by backspace then send message to other script
				if not restartedFromTheOutSide then
					local restartListener = Listener("Restart")
					restartListener:pushEvent("restart")
				end
				--Special case first wave
				if mapInfo.getGameMode()~="training" then
					currentState = EVENT_WAIT_FOR_TOWER_TO_BE_BUILT
					local buildingBillboard = Core.getBillboard("buildings")
					buildingBillboard:setBool("Ready",false)
				else
					currentState = EVENT_WAIT_FOR_START_BUTTON_BUILT
				end
			else
				currentState = EVENT_CHANGE_WAVE
				comUnit:broadCast(Vec3(),math.huge,"disappear","")
				
				--
				local restartWaveListener = Listener("RestartWave")
				restartWaveListener:pushEvent("restartWave",waveCount+1)
				print("======== DO_WAVE_RESTART_"..tostring(waveCount+1).." ========")
			end
			comUnit:sendTo(0,"clear","")
		end
	end
	function victoryDefeatProcedure()
		comUnit:sendTo("SteamAchievement","MaxWaveFinished",waveCount)
		comUnit:sendTo("stats","showScore","")
		--
		if mapInfo.getGameMode()=="survival" then
			local crystalGain = waveCount/10--bilboardStats:getInt("score")
			if crystalGain>0 then
				comUnit:sendTo("stats","setBillboardInt","survivalBonus;"..0)
				cData.addCrystal( crystalGain )
			end
		end
	end
	function self.update()
		--Handle communication
		while comUnit:hasMessage() do
			local msg = comUnit:popMessage()
			if comUnitTable[msg.message]~=nil then
		 	   comUnitTable[msg.message](msg.parameter,msg.fromIndex)
			else
				LOG("self.update() - failed message=\""..msg.message.."\")")
			end
		end
		--
		--
		--
		if spawnManager.isSpawnListPopulated() and currentState ~= EVENT_END_MENU then
			--handle the event restart wave
			if (mapInfo.getGameMode()=="default" or mapInfo.getGameMode()=="survival" or mapInfo.getGameMode()=="rush" or mapInfo.getGameMode()=="training") then
				if keyBindRevertWave:getPressed() and (not Core.isInMultiplayer()) then
					self.doRestartWave()
				end
			end
			if currentState == EVENT_WAIT_FOR_TOWER_TO_BE_BUILT then
				if isPlayerReady() and (Core.isInMultiplayer()==false or Core.getNetworkClient():isAdmin())  then
					currentState = EVENT_CHANGE_WAVE
				end
			elseif currentState == EVENT_WAIT_UNTILL_ALL_ENEMIS_ARE_DEAD then
				spawnManager.spawnUnits()
				if spawnManager.isAnythingSpawning()==false and spawnManager.isAnyEnemiesAlive()==false then
					currentState = EVENT_CHANGE_WAVE
					waveRestarted = false
				end
			elseif currentState == EVENT_CHANGE_WAVE then
				if changeWave() then
					spawnManager.changeWave(waveCount)
					comUnit:sendTo("SteamStats",mapStatId.."LaunchedCount",1.0)
					steamStatMinPlayedTime = Core.getTime()
					--
					local timeDiff = (Core.getTime()-steamStatMinPlayedTime)/60.0
					if timeDiff>0.0 and timeDiff<10.0 then
						comUnit:sendTo("SteamStats",mapStatId.."MinPlayed",timeDiff)
						steamStatMinPlayedTime = Core.getTime()
					end
					comUnit:sendTo("SteamStats","MaxGoldEarnedDuringSingleGame",bilboardStats:getInt("goldGainedTotal"))
					comUnit:sendTo("SteamStats","MaxGoldInterestEarned",bilboardStats:getInt("goldGainedFromInterest"))
					comUnit:sendTo("SteamStats","MaxGoldGainedFromSupportSingeGame",bilboardStats:getInt("goldGainedFromSupportTowers"))
					--comUnit:sendNetworkSyncSafe("ChangeWave",tostring(waveCount))
					sendNetworkSyncSafe("ChangeWave",tostring(waveCount))
					comUnit:sendTo("SteamStats","SaveStats","")
					currentState = EVENT_START_SPAWN
				else
					currentState = EVENT_END_GAME
				end
			elseif currentState == EVENT_START_SPAWN then
				--diff
				spawnManager.spawnWave(waveRestarted)
				currentState = EVENT_WAIT_UNTILL_ALL_ENEMIS_ARE_DEAD
			elseif currentState == EVENT_END_GAME then
				if this:getPlayerNode() then
					victoryDefeatProcedure()
					--stats
					local highScoreBillBoard = Core.getGlobalBillboard("highScoreReplay")
					highScoreBillBoard:setBool("victory", bilboardStats:getInt("life") > 0)
					highScoreBillBoard:setInt("score", bilboardStats:getInt("score"))
					highScoreBillBoard:setInt("life", bilboardStats:getInt("life"))
					highScoreBillBoard:setDouble("gold", bilboardStats:getInt("gold"))
					
					
					if highScoreBillBoard:getBool("replay") then
						--it is a replay
						local worker = Worker("Menu/loadingScreen.lua", true)
						worker:start()
						Core.quitToMainMenu()
					else
						--it is a real game
						if bilboardStats:getInt("life")>0 then 
							--
							--
							-- victory
							--
							--
							-- save score/data
							local node = this:findNodeByTypeTowardsRoot(NodeId.playerNode)
							comUnit:sendTo("builder"..node:getClientId(), "sendHightScoreToTheServer","")
							comUnit:sendTo("SteamStats","MaxGoldEarnedDuringSingleGame",bilboardStats:getInt("goldGainedTotal"))
							comUnit:sendTo("SteamStats","MaxGoldAtEndOfMap",bilboardStats:getInt("gold"))
							comUnit:sendTo("SteamStats","MaxGoldInterestEarned",bilboardStats:getInt("goldGainedFromInterest"))
							--
							-- Achievements
							--
							--game modes
							if mapInfo.getLevel()>=5 and mapInfo.getGameMode()=="default" then
								comUnit:sendTo("SteamAchievement","BeatDefaultInsane","")
							end
							if mapInfo.getLevel()>=5 and mapInfo.getGameMode()=="training" then
								comUnit:sendTo("SteamAchievement","BeatTrainingInsane","")
							end
							if mapInfo.getLevel()>=5 and mapInfo.getGameMode()=="leveler" then
								comUnit:sendTo("SteamAchievement","BeatLevelerInsane","")
							end
							if mapInfo.getLevel()>=5 and mapInfo.getGameMode()=="only interest" then
								comUnit:sendTo("SteamAchievement","BeatInflationInsane","")
							end
							--Flawless game
							if mapInfo.getLevel()>=5 then
								comUnit:sendTo("SteamStats","MaxLifeAtEndOfMapOnInsane",bilboardStats:getInt("life"))
							end
							--over powered game (beat insane and not using any restarts
							if mapInfo.getLevel()>=5 and mapInfo.getGameMode()=="default" and previousWaveCounter==0 then
							end
							--purity
							local minigunBuilt = bilboardStats:exist("minigunTowerBuilt")
							local arrowBuilt = bilboardStats:exist("arrowTowerBuilt")
							local swarmBuilt = bilboardStats:exist("swarmTowerBuilt")
							local electricBuilt = bilboardStats:exist("electricTowerBuilt")
							local bladeBuilt = bilboardStats:exist("bladeTowerBuilt")
							local quakeBuilt = bilboardStats:exist("quakeTowerBuilt")
							local missileBuilt = bilboardStats:exist("missileTowerBuilt")
							local supportBuilt = bilboardStats:exist("supportTowerBuilt")
							local soldTowers = bilboardStats:getInt("towersSold")
							local towerBuilt = bilboardStats:getInt("minigunTowerBuilt") + bilboardStats:getInt("arrowTowerBuilt") + bilboardStats:getInt("swarmTowerBuilt") + bilboardStats:getInt("electricTowerBuilt") + bilboardStats:getInt("bladeTowerBuilt") + bilboardStats:getInt("quakeTowerBuilt") + bilboardStats:getInt("missileTowerBuilt") + bilboardStats:getInt("supportTowerBuilt") - soldTowers
							if minigunBuilt and not (arrowBuilt or swarmBuilt or electricBuilt or quakeBuilt or bladeBuilt or missileBuilt or supportBuilt) then
								comUnit:sendTo("SteamAchievement","MinigunOnly","")
							elseif arrowBuilt and not (minigunBuilt or swarmBuilt or electricBuilt or quakeBuilt or bladeBuilt or missileBuilt or supportBuilt) then
								comUnit:sendTo("SteamAchievement","CrossbowOnly","")
							elseif swarmBuilt and not (minigunBuilt or arrowBuilt or electricBuilt or quakeBuilt or bladeBuilt or missileBuilt or supportBuilt) then
								comUnit:sendTo("SteamAchievement","SwarmOnly","")
							elseif electricBuilt and not (minigunBuilt or arrowBuilt or swarmBuilt or quakeBuilt or bladeBuilt or missileBuilt or supportBuilt) then
								comUnit:sendTo("SteamAchievement","ElectricOnly","")
							elseif quakeBuilt and not (minigunBuilt or arrowBuilt or swarmBuilt or electricBuilt or bladeBuilt or missileBuilt or supportBuilt) then
								comUnit:sendTo("SteamAchievement","QuakeOnly","")
							elseif bladeBuilt and not (minigunBuilt or arrowBuilt or swarmBuilt or electricBuilt or quakeBuilt or missileBuilt or supportBuilt) then
								comUnit:sendTo("SteamAchievement","BladeOnly","")
							elseif missileBuilt and not (minigunBuilt or arrowBuilt or swarmBuilt or electricBuilt or quakeBuilt or bladeBuilt or supportBuilt) then
								comUnit:sendTo("SteamAchievement","MissileOnly","")
							end
							if minigunBuilt and arrowBuilt and swarmBuilt and electricBuilt and quakeBuilt and bladeBuilt and missileBuilt and supportBuilt then
								comUnit:sendTo("SteamAchievement","OneOfEverything","")
							end
							if soldTowers==0 then
								comUnit:sendTo("SteamAchievement","NoSelling","")
							end
							if towerBuilt>=25 then
								comUnit:sendTo("SteamAchievement","Army","")
							end
							--
							if bilboardStats:getInt("level3")==0 and bilboardStats:getInt("level2")==0 then
								comUnit:sendTo("SteamAchievement","OnlyGreen","")
							end
							if bilboardStats:getInt("level3")==towerBuilt then
								comUnit:sendTo("SteamAchievement","OnlyRed","")
							end
							if mapInfo.isCartMap() and bilboardStats:exist("mineCartIsMoved")==false then
								comUnit:sendTo("SteamAchievement","MineCartUntouched","")
							end
							--
							if waveCount==20 and towerBuilt<=5 then
								comUnit:sendTo("SteamAchievement","TinySystem","")
							end
							if mapInfo.getLevel()>=3 then
								print("Map: "..mapInfo.getMapName())
								if mapInfo.getMapName()=="Beginning" then
									comUnit:sendTo("SteamAchievement","MapBeginning","")
								elseif mapInfo.getMapName()=="Blocked path" then
									comUnit:sendTo("SteamAchievement","MapBlockedPath","")
								elseif mapInfo.getMapName()=="Bridges" then
									comUnit:sendTo("SteamAchievement","MapBridges","")
								elseif mapInfo.getMapName()=="Crossroad" then
									comUnit:sendTo("SteamAchievement","MapCrossroad","")
								elseif mapInfo.getMapName()=="Divided" then
									comUnit:sendTo("SteamAchievement","MapDivided","")
								elseif mapInfo.getMapName()=="Dock" then
									comUnit:sendTo("SteamAchievement","MapDock","")
								elseif mapInfo.getMapName()=="Expansion" then
									comUnit:sendTo("SteamAchievement","MapExpansion","")
								elseif mapInfo.getMapName()=="Intrusion" then
									comUnit:sendTo("SteamAchievement","MapIntrusion","")
								elseif mapInfo.getMapName()=="Long haul" then
									comUnit:sendTo("SteamAchievement","MapLongHaul","")
								elseif mapInfo.getMapName()=="Mine" then
									comUnit:sendTo("SteamAchievement","MapMine","")
								elseif mapInfo.getMapName()=="Nature" then
									comUnit:sendTo("SteamAchievement","MapNature","")
								elseif mapInfo.getMapName()=="Paths" then
									comUnit:sendTo("SteamAchievement","MapPaths","")
								elseif mapInfo.getMapName()=="Plaza" then
									comUnit:sendTo("SteamAchievement","MapPlaza","")
								elseif mapInfo.getMapName()=="Repair station" then
									comUnit:sendTo("SteamAchievement","MapRepairStation","")
								elseif mapInfo.getMapName()=="Rifted" then
									comUnit:sendTo("SteamAchievement","MapRifted","")
								elseif mapInfo.getMapName()=="Spiral" then
									comUnit:sendTo("SteamAchievement","MapSpiral","")
								elseif mapInfo.getMapName()=="Stockpile" then
									comUnit:sendTo("SteamAchievement","MapStockpile","")
								elseif mapInfo.getMapName()=="The end" then
									comUnit:sendTo("SteamAchievement","MapTheEnd","")
								elseif mapInfo.getMapName()=="The line" then
									comUnit:sendTo("SteamAchievement","MapTheLine","")
								elseif mapInfo.getMapName()=="Town" then
									comUnit:sendTo("SteamAchievement","MapTown","")
								elseif mapInfo.getMapName()=="Train station" then
									comUnit:sendTo("SteamAchievement","MapTrainStation","")
								elseif mapInfo.getMapName()=="Square" then
									comUnit:sendTo("SteamAchievement","MapSquare","")
								elseif mapInfo.getMapName()=="Co-op Crossfire" then
									comUnit:sendTo("SteamAchievement","MapCo-opCrossfire","")
								elseif mapInfo.getMapName()=="Co-op Hub world" then
									comUnit:sendTo("SteamAchievement","	MapCo-opHubWorld","")
								elseif mapInfo.getMapName()=="Co-op Outpost" then
									comUnit:sendTo("SteamAchievement","MapCo-opOutpost","")
								elseif mapInfo.getMapName()=="Co-op Survival beginnings" then
									comUnit:sendTo("SteamAchievement","MapCo-opSurvivalBeginnings","")
								elseif mapInfo.getMapName()=="Co-op Survival frontline" then
									comUnit:sendTo("SteamAchievement","MapCo-opSurvivalFrontline","")
								elseif mapInfo.getMapName()=="Co-op The road" then
									comUnit:sendTo("SteamAchievement","MapCo-opTheRoad","")
								elseif mapInfo.getMapName()=="Co-op The tiny road" then
									comUnit:sendTo("SteamAchievement","MapCo-opTheTinyRoad","")
								elseif mapInfo.getMapName()=="Co-op Triworld" then
									comUnit:sendTo("SteamAchievement","MapCo-opTriworld","")
								elseif mapInfo.getMapName()=="Broken mine" then
									comUnit:sendTo("SteamAchievement","MapBrokenMine","")
								elseif mapInfo.getMapName()=="Dump station" then
									comUnit:sendTo("SteamAchievement","MapDumpStation","")
								elseif mapInfo.getMapName()=="Desperado" then
									comUnit:sendTo("SteamAchievement","MapDesperado","")
								elseif mapInfo.getMapName()=="West river" then
									comUnit:sendTo("SteamAchievement","MapWestRiver","")
								end
							end
							--
							if not endGameMenuScreen then
								endGameMenuScreen = this:getPlayerNode():loadLuaScript("Menu/endGameMenu.lua")
								endGameMenuScreen:setName("endGameMenuVictory")
							end
						end
						comUnit:sendTo("SteamStats","SaveStats","")
					end
				end
				currentState = EVENT_END_MENU
				return true
			end
		end
--		if Core.isInMultiplayer() and Core.getNetworkClient():isConnected()==false then
--			local script = this:getPlayerNode():loadLuaScript("Menu/endGameMenu.lua")
--			if script and bilboardStats then 
--				script:callFunction("victory")
--			end
--		end
		
		if bilboardStats then
			--print("if "..tostring(bilboardStats:getInt("life")).."<=0 and "..tostring(waveCount)..">="..tostring(STARTWAVE).." and "..tostring(waveRestarted).."==false and "..tostring(Core.getGameTime()-restartTimer)..">4.0 then")
			if bilboardStats:getInt("life") <= 0 and waveCount>=STARTWAVE and waveRestarted==false and (Core.getGameTime()-restartTimer) > 4.0 then
				local highScoreBillBoard = Core.getGlobalBillboard("highScoreReplay")
				local isAReplay = highScoreBillBoard:getBool("replay")
				if not eventBaserunOnlyOnce and isAReplay == false then
					eventBaserunOnlyOnce = true
					victoryDefeatProcedure()
					currentState = EVENT_END_MENU
					if this:getPlayerNode() then
						
						highScoreBillBoard:setBool("victory", false)
						highScoreBillBoard:setInt("score", bilboardStats:getInt("score"))
						highScoreBillBoard:setInt("life", bilboardStats:getInt("life"))
						highScoreBillBoard:setDouble("gold", bilboardStats:getInt("gold"))
						
						if not endGameMenuScreen then
							endGameMenuScreen = this:getPlayerNode():loadLuaScript("Menu/endGameMenu.lua")
							endGameMenuScreen:setName("endGameMenuDefeat")
						end
					end
					return true
				end
			end
		else
			bilboardStats = Core.getBillboard("stats")
		end
		
		--
		--	Cheat for development
		--
--		if Core.getInput():getKeyPressed(Key.r) then
--			comUnit:sendTo("stats","showScore","")
--			local script = this:getPlayerNode():loadLuaScript("Menu/endGameMenu.lua")
--			script:setName("endGameMenuVictory")
--		end
--		if DEBUG or true then
--		 	if Core.getInput():getKeyPressed(Key.p) then
--				comUnit:sendTo("log", "println", "cheat-addGold")
--				statsBilboard = Core.getBillboard("stats")
--				comUnit:sendTo("stats", "addGold", tostring(statsBilboard:getDouble("gold")+500.0))
--				saveStats = false
--				Core.getGlobalBillboard("highScoreReplay"):setBool("saveHighScore",saveStats)
--			end
--			if Core.getInput():getKeyPressed(Key.o) then
--				spawnNextGroup()
--			end
----			local a = 1
----			if Core.getInput():getKeyPressed(Key.m) then
----				for i=1, 50000000 do
----					a = a + Core.getDeltaTime() + i
----				end
----			end
--		end
		--
		--
		--
		return true
	end
	return self
end