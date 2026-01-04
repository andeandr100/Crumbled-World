--this = SceneNode()

SpawnGroups = {}
function SpawnGroups.new()
	local self = {}
	
	function self.getNPCValueList()
		npc = 	{	rat =			{hp=275,	size=0.8,	script="NPC/npc_rat.lua"},--fast units
					skeleton =		{hp=450,	size=0.8,	script="NPC/npc_skeleton.lua"},
					scorpion =		{hp=600,	size=0.8,	script="NPC/npc_scorpion.lua"},
					rat_tank =		{hp=600,	size=0.8,	script="NPC/npc_rat_tank.lua"},--fast units
					fireSpirit =	{hp=750,	size=0.8,	script="NPC/npc_fireSpirit.lua"},--imune to fire, and restore some amount of hp by fire damage
					electroSpirit =	{hp=750,	size=0.8,	script="NPC/npc_electroSpirit.lua"},--imune to electricity, and restore some amount of hp by fire damage
					skeleton_cf =	{hp=1000,	size=0.8,	script="NPC/npc_skeleton_champion_front.lua"},--blocks physical damage
					skeleton_cb =	{hp=1000,	size=0.8,	script="NPC/npc_skeleton_champion_back.lua"},--blocks physical damage
					turtle =		{hp=2750,	size=0.8,	script="NPC/npc_turtle.lua"},--shield that abosorb all incoming damage
					dino =			{hp=1200,	size=0.8,	script="NPC/npc_dino.lua"},--heal itself if untoutched
					reaper =		{hp=1200,	size=0.8,	script="NPC/npc_reaper.lua"},--spawns npc_skeleton
					stoneSpirit =	{hp=2500,	size=0.8,	script="NPC/npc_stonespirit.lua"},
					hydra1 =		{hp=300,	size=0.8,	script="NPC/npc_hydra1.lua"},
					hydra2 =		{hp=350,	size=0.8,	script="NPC/npc_hydra2.lua"},--L2 totalHP = 350+(300*2) == 950
					hydra3 =		{hp=400,	size=0.8,	script="NPC/npc_hydra3.lua"},--L3 totalHP = 400+(350*2)+(300*4) == 2300
					hydra4 =		{hp=450,	size=0.8,	script="NPC/npc_hydra4.lua"},--L4 totalHP = 450+(400*2)+(350*4)+(300*8) == 5050
					hydra5 =		{hp=550,	size=0.8,	script="NPC/npc_hydra5.lua"},--L5 totalHP = 550+(450*2)+(400*4)+(350*8)+(300*16) == 9050
				}
		return npc
	end
	
	function self.getNPCGroupList()
		local groupCompOriginal = {
			--===
			--===	parameters fir the Group
			--===
			--waveMin				== can only spawn from this wave and after
			--waveMax				== can only spawn before this wave
			--waveUseLimit			== how many can spawn per wave
			--groupSpawnBefore		== number of group that need to spawn before this one
			--groupSpawnAfter		== number of group that need to spawn after this group
			
			--===
			--===	parameters for each NPC
			--===
			--npc					== Name of NPC to spawn
			--pathOffset			== offset from the path center line, Default 0.2 offset and flips left to right automaticly
			--npcScale				== Scale of the NPC default 1.0
			--count					== how many times the same unit will be repeated
			--delay					== delay bettwen npc, Note first spwan NPC in each group ignores this value
			
			
			--(450*8)/(4.5+7*0.25) == 576 hp/s
			{waveMax=13, {npc="skeleton",delay=0.25,count=8}},
			--(600*6)/(4.5+5*0.45) == 576 hp/s
			{waveMax=13, {npc="scorpion",delay=0.45,count=6}},
			--(275*8)/(4.5+7*0.25) == 352 hp/s
			{waveMin=2, waveMax=13, waveUseLimit=2, groupSpawnBefore=1,{npc="rat",delay=0.25,count=8}},
			--(600*3 + 450*4)/(4.5 + 2*0.45 + 4*0.25) == 580 hp/s
			{waveMin=2, {npc="scorpion",delay=0.45,count=3},{npc="skeleton",delay=0.25,count=4}},
			--(600*3 + 750 + 450*4)/(4.5 + 2*0.45 + 0.4 + 5*0.25) == 635 hp/s
			{waveMin=3, {npc="scorpion",delay=0.45,count=3},{npc="fireSpirit",delay=0.4},{npc="skeleton",delay=0.25,count=4}},
			--(600*3 + 750 + 450*4)/(4.5 + 2*0.45 + 0.4 + 5*0.25) == 635 hp/s
			{waveMin=3, {npc="scorpion",delay=0.45,count=3},{npc="electroSpirit",delay=0.4},{npc="skeleton",delay=0.25,count=4}},
			
			--(750*5)/(4.5 + 4*0.5) == 576 hp/s
			{waveMin=6,{npc="fireSpirit", pathOffset=0,delay=0.5,count=5}},
			--(750*5)/(4.5 + 4*0.5) == 576 hp/s
			{waveMin=6,{npc="electroSpirit", pathOffset=0,delay=0.5,count=5}},
			--(1000 + 450*8)/(4.5 + 8*0.25) == 707 hp/s
			{waveMin=6, {npc="skeleton_cf", pathOffset=0},{npc="skeleton",delay=0.25,count=8}},
			--(1000 + 450*8 + 1000)/(4.5 + 8*0.25+0.25) == 829 hp/s
			{waveMin=7, {npc="skeleton_cf", pathOffset=0},{npc="skeleton",delay=0.25,count=8},{npc="skeleton_cb",delay=0.25, pathOffset=0}},
			--(450*6 + (1200 + 450*3))/(4.5 + 5*0.25 + 0.4) == 853 hp/s
			{waveMin=8, {npc="skeleton",delay=0.25,count=6},{npc="reaper",delay=0.4,pathOffset=0}},
			--(2500)/(4.5) == 555 hp/s 
			{waveMin=11, waveMax=21, waveUseLimit=1, {npc="stoneSpirit", pathOffset=0, delay=0.0}},
			
			{waveMin=11,{npc="skeleton",delay=0.25,count=10,upgrade={count=2,npcScale=1.5,delay=0.35,pathOffset=0.0,hpScale=2,animationSpeed=0.75}}, },
			--(600*6)/(4.5+5*0.45) == 576 hp/s
			{waveMin=11,{npc="scorpion",delay=0.45,count=8,upgrade={count=2,npcScale=1.5,pathOffset=0.0,hpScale=2,animationSpeed=0.75}}},
			--(275*8)/(4.5+7*0.25) == 352 hp/s
			{waveMin=12, waveUseLimit=2, groupSpawnBefore=1,{npc="rat",delay=0.25,count=8,upgrade={count=2,npcScale=1.5,pathOffset=0.0,hpScale=2,animationSpeed=0.75}}},
			
			--((3*600)+(6*275))/((4.5 + 0.4*2 + 0.3*6) == 485 hp/s 
			{waveMin=12, waveUseLimit=1, groupSpawnBefore=1,{npc="rat_tank",delay=0.4,count=3},{npc="rat",delay=0.3,count=6}},
			--(450*8+2750)/(4.5+0.4+0.25*7) == 954 hp/s 
			{waveMin=16, waveUseLimit=1, groupSpawnBefore=1, groupSpawnAfter=1, {npc="skeleton",delay=0.25,count=4},{npc="turtle", pathOffset=0, delay=0.4},{npc="skeleton",delay=0.25,count=4}},
			--(600*6+2750)/(4.5+0.45+0.45*5) == 992 hp/s 
			{waveMin=16, waveUseLimit=1, groupSpawnBefore=1, groupSpawnAfter=1, {npc="scorpion",delay=0.45,count=3},{npc="turtle", pathOffset=0, delay=0.45},{npc="scorpion",delay=0.45,count=3}},
			--(6*600)/(4.5+0.4*5) == 553 hp/s 
			{waveMin=16, waveUseLimit=1, groupSpawnBefore=1,{npc="rat_tank",delay=0.4,count=6}},
			--(2500+4*750)/(4.5+0.5*3+1) == 785 hp/s 
			{waveMin=16, waveUseLimit=1,{npc="fireSpirit",delay=0.5,count=2}, {npc="stoneSpirit",delay=1.0},{npc="electroSpirit",delay=0.5,count=2}},
			--(1000*6)/(4.5+0.4*5) == 923 hp/s 
			{waveMin=16, waveUseLimit=1,{npc="skeleton_cf",delay=0.4,count=6}},
			--(1000*2+750*4)/(4.5+0.4*1+0.5*4) == 724 hp/s 
			{waveMin=16, waveUseLimit=1,{npc="skeleton_cf",delay=0.4,count=2},{npc="fireSpirit", pathOffset=0,delay=0.5,count=4}},
			
			
			
			
			--(1200*4)/(4.5+0.75*4) == 640 hp/s 
			{waveMin=21, waveUseLimit=1, groupSpawnBefore=1, groupSpawnAfter=1,{npc="dino",pathOffset=0,delay=0.75,count=4}},
			--(275*16)/(4.5+15*0.25) == 533 hp/s
			{waveMin=21, waveUseLimit=1,groupSpawnBefore=2,{npc="rat",delay=0.25,count=16}},
			--(2500*2)/(4.5+1) == 909 hp/s 
			{waveMin=21, waveUseLimit=1, {npc="stoneSpirit", pathOffset=0, delay=1.0,count=2}},
			--(2500+450*8)/(4.5+8*0.25) == 938 hp/s
			{waveMin=21, waveUseLimit=1,{npc="stoneSpirit", pathOffset=0, delay=0.0}, {npc="skeleton",delay=0.25,count=8}},
			--(2500+600*7)/(4.5+7*0.45) == 964 hp/s
			{waveMin=21, waveUseLimit=1,{npc="stoneSpirit", pathOffset=0, delay=0.0}, {npc="scorpion",delay=0.45,count=7}},
			--(1000+450*4+(1200 + 450*3)*2)/(4.5+0.25*4+0.75*2) == 1128 hp/s
			{waveMin=22, waveUseLimit=1,{npc="skeleton_cf", pathOffset=0,delay=0.0},{npc="skeleton",delay=0.25,count=4},{npc="reaper", pathOffset=0,delay=0.75,count=2}},
			
			{waveMin=21,{npc="skeleton",delay=0.25,count=10,upgrade={count=4,npcScale=1.5,delay=0.35,pathOffset=0.0,hpScale=2,animationSpeed=0.75}}, },
			--(600*6)/(4.5+5*0.45) == 576 hp/s
			{waveMin=21,{npc="scorpion",delay=0.45,count=8,upgrade={count=4,npcScale=1.5,pathOffset=0.0,hpScale=2,animationSpeed=0.75}}},
			--(275*8)/(4.5+7*0.25) == 352 hp/s
			{waveMin=21, waveUseLimit=2, groupSpawnBefore=1,{npc="rat",delay=0.25,count=8,upgrade={count=4,npcScale=1.5,pathOffset=0.0,hpScale=2,animationSpeed=0.75}}},
			
	
			--(2500*2+2750)/(4.5+1+1) == 1192 hp/s 
			{waveMin=26, waveUseLimit=1,{npc="stoneSpirit",delay=0.0},{npc="turtle",delay=1.0},{npc="stoneSpirit",delay=1.0}},
			--(2500+1200*4)/(4.5+0.75*3+1) == 941 hp/s 
			{waveMin=26, waveUseLimit=1,{npc="dino",pathOffset=0,delay=0.75,count=2},{npc="turtle",pathOffset=0,delay=1.0},{npc="dino",pathOffset=0,delay=0.75,count=2}},
			--(10*600)/(4.5+0.4*9) == 740 hp/s 
			{waveMin=26, waveUseLimit=1, groupSpawnBefore=2,{npc="rat_tank",delay=0.4,count=10}},
			--(9050)/(4.5) == 2011 hp/s 
			{waveMin=27, waveUseLimit=1,groupSpawnDepthMax=2,{npc="hydra5", pathOffset=0,delay=0.0}},

		}
		return groupCompOriginal
	end
	
	function self.getBossGroupList()
		local bossGroupCompOriginal = {
			--===
			--===	parameters fir the Group
			--===
			--waveMin				== can only spawn from this wave and after
			--waveMax				== can only spawn before this wave
			--waveUseLimit			== how many can spawn per wave
			--groupSpawnBefore		== number of group that need to spawn before this one
			--groupSpawnAfter		== number of group that need to spawn after this group
			
			--===
			--===	parameters for each NPC
			--===
			--npc					== Name of NPC to spawn
			--pathOffset			== offset from the path center line, Default 0.2 offset and flips left to right automaticly
			--npcScale				== Scale of the NPC default 1.0
			--count					== how many times the same unit will be repeated
			--delay					== delay bettwen npc, Note first spwan NPC in each group ignores this value
			--hpScale				== scale the HP default 1
			--animationSpeed 		== set the animation speed default 1
			
			
			--(450*8)/(4.5+7*0.25) == 576 hp/s
			{{npc="skeleton",delay=0.25,count=7,upgrade={count=1,npcScale=2.0,pathOffset=0.0,delay=0.5,hpScale=6,animationSpeed=0.65}}},
			{{npc="scorpion",delay=0.45,count=5,upgrade={count=1,npcScale=1.75,pathOffset=0.0,delay=0.95,hpScale=6,animationSpeed=0.5}}},
			{waveMin=9,{npc="rat",delay=0.25,count=7,upgrade={count=1,npcScale=2.0,pathOffset=0.0,delay=0.5,hpScale=8,animationSpeed=0.5}}},
			{waveMin=14,{npc="skeleton",delay=0.25,count=3}, {npc="skeleton_cf",npcScale=2.0,pathOffset=0.0,delay=0.5,count=1,hpScale=3,animationSpeed=0.65},{npc="skeleton",delay=0.5,count=1},{npc="skeleton",delay=0.25,count=3}},
		}
		return bossGroupCompOriginal
			
	end
	
	
	function self.getEndWaveList()
		
		local endWave = {
			maxScriptedGroups = 2,
			selected = 0,
			count=0,
			{	waves={[1]=true,[2]=true},
				odds=function() return 0.4 end,
				group={
					{{npc="hydra5",delay=0.0}}
					},
				},
				followupOdds=function() return 1.0 end,
				followup={
					{{npc="dino",delay=0.0},{npc="dino",delay=0.75},{npc="turtle",delay=0.75},{npc="dino",delay=0.75},{npc="dino",delay=0.75}},
					{{npc="dino",delay=0.0},{npc="dino",delay=0.75},{npc="dino",delay=0.75},{npc="dino",delay=0.75}},
					{{npc="stoneSpirit",delay=0.0},{npc="turtle",delay=1.0},{npc="stoneSpirit",delay=1.0}},
					{{npc="stoneSpirit",delay=0.0},{npc="stoneSpirit",delay=1.0}},
				},
			{	waves={[3]=true,[4]=true},
				odds=function(selected) local ret={[0]=1.0, 0.25, 0.0} return ret[math.clamp(selected,0,#ret)] end,
				group={
					{{npc="skeleton_cf",delay=0.0},{npc="reaper",delay=0.75},{npc="reaper",delay=0.75}},
					{{npc="skeleton_cf",delay=0.0},{npc="reaper",delay=0.75},{npc="reaper",delay=0.75},{npc="reaper",delay=0.75}}
					},
				followupOdds=function(selected) local ret={1.0, 0.5, 0.0} return ret[math.clamp(selected,1,#ret)] end,
				followup={
					{{npc="dino",delay=0.0},{npc="dino",delay=0.75},{npc="turtle",delay=0.75},{npc="dino",delay=0.75},{npc="dino",delay=0.75}},
					{{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="turtle",delay=0.4},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25},{npc="skeleton",delay=0.25}},
					{{npc="skeleton_cf",delay=0.0},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="turtle",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton",delay=0.4},{npc="skeleton_cb",delay=0.4}}
					},
				},
			{	waves={[4]=true,[5]=true},
				odds=function(selected) return 0.1 end,
				group={
					{{npc="rat_tank",delay=0.0},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40}},
					{{npc="rat",delay=0.0},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25},{npc="rat",delay=0.25}}
					}
				},
			["LAST"] ={	
				waves={["LAST"]=true},
				odds=function() return 1.0 end,
				group={
					{{npc="stoneSpirit",delay=0.0},{npc="turtle",delay=1.0},{npc="stoneSpirit",delay=1.0}},
					{{npc="stoneSpirit",delay=0.0},{npc="stoneSpirit",delay=1.0}},
					{{npc="dino",delay=0.0},{npc="dino",delay=0.75},{npc="turtle",delay=0.75},{npc="dino",delay=0.75},{npc="dino",delay=0.75}},
					{{npc="rat_tank",delay=0.0},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40},{npc="rat_tank",delay=0.40}}
					},
				},
				
		}
		return endWave
	end
	
	function self.getWaveUnitLimit()
		
		local waveUnitLimitOriginal = {
			rat = 16,
			skeleton =	math.huge,
			scorpion =	math.huge,
			rat_tank =	10,
			fireSpirit = 8,
			electroSpirit =	8,
			skeleton_cf = 2,
			skeleton_cb = 2,
			turtle = 2,
			dino =	5,
			reaper = 2,
			stoneSpirit = 2,
			hydra1 = 1,
			hydra2 = 1,
			hydra3 = 1,
			hydra4 = 1,
			hydra5 = 1,
			superHeavy = 4		--superheavys are valued as following hydra=1, stonespirit=1, turtle=1, reaper=0.51, dino=0.26
		}
		return waveUnitLimitOriginal
	end
			
			
	return self
end