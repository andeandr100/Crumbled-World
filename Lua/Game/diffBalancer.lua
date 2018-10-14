require("Game/mapInfo.lua")
require("Game/scoreCalculater.lua")

DiffBalancer = {}
function DiffBalancer.new()
	local self = {}
	local bilboardStats
	local mapInfo = MapInfo.new()
	local history = {}
	local isCrystal = mapInfo.isCrystalMap()
	local isCart = mapInfo.isCartMap()
	local maxWave = mapInfo.getWaveCount()
	local TL = 0				--Threat Level
	
	function saveRestorePoint(waveNum)
		history[waveNum] = {TL=TL}
	end
	function self.waveChanged(waveNum)
		TL = math.max((TL*0.9)-0.05,0)
		saveRestorePoint(waveNum)
	end
	function self.waveRestarted(waveNum)
		if waveNum>=1 then
			TL = history[waveNum].TL*1.05
			saveRestorePoint(waveNum)
		else
			TL = 0
			history = {}
		end
	end
	function self.lifeLost()
		TL = TL+0.25
	end
	
	function getLLP()
		return 1-(bilboardStats:getInt("life")/bilboardStats:getInt("maxLife"))
	end
	
	function calculateBaseValue(wave)
		local G = bilboardStats:getInt("gold")
		local S = bilboardStats:getInt("score")
		--Estimated Score to Achive Silver
		local ESAS = ScoreCalculater.estimatedScoreForIndexOnWave(3,wave)
		--Minimal Score
		local MS = bilboardStats:getInt("goldGainedFromKills")+bilboardStats:getInt("totalTowerValue")
		--Low Life Percentage
		local LLP = getLLP()
		--Close to End Wave Percentage
		local CEWP = wave/maxWave
		--Low on Gold Percentage
		local LGP = math.clamp(1-((G+1)/(300+math.min(wave*75,1500))),0,1)
		--Low Score Percentage
		local LSP = ESAS>=0 and 0 or math.clamp((ESAS-S)/(ESAS-MS),0,1)
		--Badness meter
		local B = 0
		if isCrystal then
			print("LLP = "..tostring(LLP))
			print("LGP = "..tostring(LGP))
			B = B + (0.5*LLP*LGP)
		elseif isCart then
			B = B + (0.5*LGP)
		end
		print("ESAS= "..tostring(ESAS))
		print("S= "..tostring(S))
		print("CEWP= "..tostring(CEWP))
		print("LSP = "..tostring(LSP))
		B = B + (0.5*CEWP*LSP)
		print("B = "..tostring(B))
		return B
	end
	
	function self.getHandicap(pWave)
		if mapInfo.isCampaign() and pWave>0 then
			print("============================")
			bilboardStats = bilboardStats or Core.getBillboard("stats")
			wave = pWave
			local LLP = getLLP()
			local B = calculateBaseValue(wave)
			local W = 0;
			if isCrystal then
				print("TL = "..tostring(TL))
				W = W + (0.4*TL*B*LLP)
			elseif isCart then
				W = W + (0.2*B)
			end
			return W
		end
		return 0.0
	end
	
	return self
end