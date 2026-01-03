require("Game/SpawnSystem/spawnGroups.lua")
--this = SceneNode()

SpawnInfo = {}
function SpawnInfo.new()
	local self = {} 
	local spawnGroups = SpawnGroups.new()
	local npc = spawnGroups.getNPCValueList()
	local comUnit = Core.getComUnit()
	
	local goldPerHp = 0
	
	
	local function getTotalHpForThisWave(currentWave)
		local totalHP = 0
		for i=2, #currentWave do
			local npcName = currentWave[i].npc
			if npc[npcName] and npc[npcName].hp then
				totalHP = totalHP + npc[npcName].hp
			end
		end
		return totalHP
	end
	
	function self.updateNpcInfo(wave, currentWave)
		
		local totalhpForThisWave = getTotalHpForThisWave(currentWave)
		local goldForAllNpc = 300 + 20 * wave
		goldPerHp = goldForAllNpc / totalhpForThisWave
		
		local hpMul = currentWave[1].hpMul
		
		local npcList = {"rat","rat_tank","skeleton","scorpion","fireSpirit","electroSpirit","skeleton_cf","skeleton_cb","turtle","dino","reaper","stoneSpirit","hydra1","hydra2","hydra3","hydra4","hydra5"}
		
		for i=1, #npcList do
			local npcName = npcList[i]
			
			comUnit:sendTo("stats","setBillboardInt","npc_"..npcName.."_hp;"..npc[npcName].hp*hpMul)
			
			comUnit:sendTo("stats","setBillboardInt","npc_"..npcName.."_gold;"..(npc[npcName].hp * goldPerHp))
		end
		
		--Overide this settings sub level of a hydra do not generate Gold
		comUnit:sendTo("stats","setBillboardInt","npc_hydra2_gold;0")
		comUnit:sendTo("stats","setBillboardInt","npc_hydra3_gold;0")
		comUnit:sendTo("stats","setBillboardInt","npc_hydra4_gold;0")
		comUnit:sendTo("stats","setBillboardInt","npc_hydra5_gold;0")
		
	end
	
	
	return self
end