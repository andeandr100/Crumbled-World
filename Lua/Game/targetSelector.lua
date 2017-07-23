require("NPC/state.lua")
SHIELD_RANGE = 3.5

TargetSelector = {}
function TargetSelector.new(pteam)
	local self = {}
	local soulManagerBillboard = Core.getBillboard("SoulManager")
	local position = Vec3()
	local range = 0.0
	local binaryNumPos = {[1]=1,[2]=2,[4]=3,[8]=4,[16]=5,[32]=6,[64]=7,[128]=8,[256]=9,[512]=10,[1024]=11,[2048]=12}
	local team = -1
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	---
	local soulTableLastUpdatedFrame = 0
	local soulTable = {}
	local shieldGenTableLastUpdatedFrame = 0
	local shieldGenTable = {}
	--
	local targetTable = {}
	local targetTableCount = 0
	local currentTarget = 0
	local defaultPipeAt = Vec3()
	local defaultAngleLimit = math.pi*3
	local soulTableNamesToUse = {}
	--
	--
	--
	function updateTablesToUse(forceUpdate)
		soulManagerBillboard = soulManagerBillboard or Core.getBillboard("SoulManager")
		if soulManagerBillboard then
			if forceUpdate or (worldMin==nil or worldMin~=soulManagerBillboard:getVec2("min")) or (worldMax==nil or worldMax~=soulManagerBillboard:getVec2("max")) then
--				local r = range
--				local p = position
				soulTableNamesToUse = {}
				local rangeLimit = range+5.66--pytagoras y = sqrt((4^2)+(4^2)) = 5.65685 == 5.66 (from the middle of a square is 4m down and right
				worldMin = soulManagerBillboard:getVec2("min")
				worldMax = soulManagerBillboard:getVec2("max")
				local xMin = math.max(worldMin.x, math.floor((position.x-rangeLimit)/8.0))
				local xMax = math.min(worldMax.x, math.floor((position.x+rangeLimit)/8.0))
				local yMin = math.max(worldMin.y, math.floor((position.z-rangeLimit)/8.0))
				local yMax = math.min(worldMax.y, math.floor((position.z+rangeLimit)/8.0))
				for x=xMin, xMax do
					for y=yMin, yMax do
						local lx = x*8.0+4.0--4.0 is to the middle
						local ly = y*8.0+4.0
						local dx = position.x-lx
						local dy = position.z-ly
						local dist = math.sqrt((dx*dx)+(dy*dy))
						if dist<rangeLimit then
							soulTableNamesToUse[#soulTableNamesToUse+1] = "souls"..x.."/"..y
						end
					end
				end
				soulTableLastUpdatedFrame = 0--forces the table to update
			end
		end
	end
	function self.setPosition(pos)
		--assert(pos, "When TargetSelector.setPosition(pos), pos must be a Vec3()")
		position = pos
		updateTablesToUse(true)
	end
	function self.setAngleLimits(pipeAt,angleLimit)
		defaultPipeAt = pipeAt
		defaultAngleLimit = angleLimit
	end
	function self.setRange(pRange)
		range = pRange
		updateTablesToUse(true)
	end
	function self.disableRealityCheck()
		if isThisReal then
			return true
		end
		soulManagerBillboard = Core.getBillboard("SoulManager")
		if soulManagerBillboard then
			isThisReal = true
			return true
		end
		return false
	end
	--
	--
	--
	local function toBits(num)
		local t={}
		while num>0 do
			rest=math.fmod(num,2)
			t[#t+1]=rest
			num=(num-rest)/2
		end
		for i=#t+1, 16 do
			t[i]=0
		end
		return t
	end
	local function updateSoulsTable()
		if isThisReal and Core.getFrameNumber()~=soulTableLastUpdatedFrame then
			soulTableLastUpdatedFrame = Core.getFrameNumber()
			--soulManagerBillboard = soulManagerBillboard or Core.getBillboard("SoulManager")
			soulTable = {}
			for i=1, #soulTableNamesToUse do
				local input = soulManagerBillboard:getString(soulTableNamesToUse[i])
				for str in string.gmatch(input, "([^|]+)") do
					local index,x1,y1,z1,x2,y2,z2,dist,hp,hpmax,team,state,name = string.match(str, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
					soulTable[tonumber(index)] = {
						position=Vec3(tonumber(x1),tonumber(y1),tonumber(z1)),
						velocity=Vec3(tonumber(x2),tonumber(y2),tonumber(z2)),
						distanceToExit=tonumber(dist), hp=tonumber(hp), hpMax=tonumber(hpmax), team=tonumber(team), state=tonumber(state), name=name, index=tonumber(index)
					}
				end
			end
		end
	end
	local function updateShieldGenTable()
		if isThisReal and Core.getFrameNumber()~=shieldGenTableLastUpdatedFrame then
			shieldGenTableLastUpdatedFrame = Core.getFrameNumber()
			local input = soulManagerBillboard:getString("shieldGenerators")
			shieldGenTable = {}
			for str in string.gmatch(input, "([^|]+)") do
				local index,x1,y1,z1 = string.match(str, "([^,]+),([^,]+),([^,]+),([^,]+)")
				shieldGenTable[tonumber(index)] = Vec3(tonumber(x1),tonumber(y1),tonumber(z1))
			end
		end
	end
	--
	--	getters
	--
	local function isInRange(target)
		updateSoulsTable()
		local soul = soulTable[target]
		if soul then
			local effectiveRange = range  + (self.isTargetInState(target,state.shieldGenerator) and SHIELD_RANGE or 0.0)
			local inRange = (soulTable[target] and (soulTable[target].position-position):length()<=effectiveRange)
			if inRange and defaultAngleLimit<math.pi then
				local diff = soul.position-position
				local targetAt = Vec2(diff.x,diff.z)
				local angle = Vec2(defaultPipeAt.x,defaultPipeAt.z):angle(targetAt)
				return defaultAngleLimit>angle
			end
			return inRange
		end
		return false
	end
	function self.isAnyInRange()
		for index,soul in pairs(soulTable) do
			if isInRange(index) then
				return true
			end
		end
		return false
	end
	function self.isAnyInCapsule(line,lineRange)
		--get all souls on the map
		updateSoulsTable()
		--
		for index,soul in pairs(soulTable) do
			if soul.team~=team and Collision.lineSegmentPointLength2(line,soul.position)<(lineRange+(self.isTargetInState(index,state.shieldGenerator) and SHIELD_RANGE or 0.0)) then
				return true
			end
		end
		return false
	end
	--
	function self.getIndexOfShieldCovering(globalPosition)
		updateShieldGenTable()
		updateSoulsTable()
		--
		for index,position in pairs(shieldGenTable) do
			--Core.addDebugLine(globalPosition,position,0.05,Vec3(1,0,0))
			if (globalPosition-position):length()<=SHIELD_RANGE then
				return index
			end
		end
		return 0
	end
--	function self.debug()
--		print("isThisReal = "..tostring(isThisReal))
--		print("range = "..tostring(range))
--		print("position = "..tostring(position))
--		print("soulTableNamesToUse == "..tostring(soulTableNamesToUse))
--		print("soulTable == "..tostring(soulTable))
--		abort()
--	end
	function self.isTargetAlive(target)
		updateSoulsTable()
		local soul = soulTable[target]
		return target>0 and soul~=nil
	end
	function self.isTargetInState(target,inState)
		--print("self.isTargetInState("..target..", "..inState..")")
		updateSoulsTable()
		local targetIndex = inState and  target or currentTarget
		local tstate = inState or target
		local soul = soulTable[targetIndex]
		local ret = (soul and toBits(soul.state)[binaryNumPos[tstate]]==1)
		return (soul and toBits(soul.state)[binaryNumPos[tstate]]==1)
	end
	function self.isTargetNamed(name)
		updateSoulsTable()
		local soul = soulTable[currentTarget]
		return (soul and soul.name==name)
	end
	function self.isTargetAvailable()
		updateSoulsTable()
		return (currentTarget>0 and soulTable[currentTarget] and isInRange(currentTarget))--hp has nothing to do with if the npc can be targeted
	end
	function self.getTargetPosition(target)
		updateSoulsTable()
		local soul = soulTable[target or currentTarget]
		return soul and soul.position or Vec3()
	end
	function self.getTargetVelocity(target)
		updateSoulsTable()
		local soul = soulTable[target or currentTarget]
		return soul and soul.velocity or Vec3()
	end
	function self.getFuturePos(target,time)
		updateSoulsTable()
		local soul = soulTable[target or currentTarget]
		local soulBillboard = Core.getBillboard(target or currentTarget)
		if soulBillboard then
			local mover = soulBillboard:getNodeMover("nodeMover")
			return mover and mover:getFuturePosition(time) or Vec3()
		end
		return Vec3()
	end
	function self.getTargetHP(target)
		updateSoulsTable()
		local soul = soulTable[target or currentTarget]
		return soul and soul.hp or 0.0
	end
	function self.getTarget()
		return currentTarget
	end
	function self.getTargetIfAvailable()
		if self.isTargetAvailable() then
			return currentTarget
		end
		currentTarget = 0
		return currentTarget
	end
	--
	--	Selecter functions
	--
	function self.selectAllInRange()
		local ret = false
		--
		updateTablesToUse(true)
		--print("soulTableNamesToUse == "..tostring(soulTableNamesToUse))
		--clear old data
		targetTable = {}
		targetTableCount = 0
		currentTarget = 0
		--get all souls on the map
		updateSoulsTable()
		--go threw them all and test the range. if in range add to targetTable
		for index,soul in pairs(soulTable) do
			if soul.team~=team and isInRange(index) then--hp does not matter(they are alive on this list), they can have close to 0 health and it will 
				targetTable[index] = 0
				targetTableCount = targetTableCount + 1
				ret = true
			end
		end
		return ret
	end
	function self.selectAllInCapsule(line,lineRange)
		local ret = false
		--clear old data
		targetTable = {}
		targetTableCount = 0
		currentTarget = 0
		--get all souls on the map
		updateSoulsTable()
		--
		for index,soul in pairs(soulTable) do
			if soul.team~=team and Collision.lineSegmentPointLength2(line,soul.position)<(lineRange+(self.isTargetInState(index,state.shieldGenerator) and SHIELD_RANGE or 0.0)) then
				targetTable[index] = 0
				targetTableCount = targetTableCount + 1
				ret = true
			end
		end
		return ret
	end
	function self.selectTargetAfterMaxScore(minimumScore)
		local maxScore
		currentTarget = 0
		for index,score in pairs(targetTable) do
			if not maxScore or score>maxScore then
				currentTarget = (minimumScore==nil or score>=minimumScore) and index or 0
				maxScore = score
			end
		end
		return currentTarget
	end
	function self.selectTargetAfterMaxScorePer(minimumScore,percentage)
		currentTarget = 0
		local tab = {}
		for index,score in pairs(targetTable) do
			if score>=minimumScore then
				tab[#tab+1] = {score=score, index=index}
			end
		end
		if #tab==0 then
			currentTarget = 0
			return currentTarget
		end
		local i=1
		while i<=#tab do
			local j=i+1
			while j<=#tab do
				if tab[i].score>tab[j].score then
					tab[i],tab[j] = tab[j],tab[i]
				end
				j = j + 1
			end
			i = i + 1
		end
		local a1 = math.floor(1+((#tab-0.01)*percentage))
		local a2 = math.clamp(a1,1,#tab)
		currentTarget = tab[a2].index
		return currentTarget
	end
	function self.selectTargetCountAfterMaxScore(minimumScore,count)
		currentTarget = 0
		local tab = {}
		for index,score in pairs(targetTable) do
			if score>=minimumScore then
				tab[#tab+1] = {score=score, index=index}
			end
		end
		if #tab==0 then
			currentTarget = 0
			return {currentTarget}
		end
		local i=1
		while i<=#tab do
			local j=1
			while j<=#tab do
				if tab[i].score<tab[j].score then
					tab[i],tab[j] = tab[j],tab[i]
				end
				j = j + 1
			end
			i = i + 1
		end
		if #tab==0 then
			currentTarget = 0
			return {0}
		end
		local ret={}
		for i=1, math.min(#tab,count) do
			ret[i] = tab[i].index
		end
		return ret
	end
	function self.getAllTargets()
		return targetTable
	end
	function self.getAllSouls()
		local tab = {}
		for index,score in pairs(targetTable) do
			local soul = soulTable[index]
			if soul then
				tab[#tab+1] = soul
			end
		end
		return tab
	end
	function self.getAllTargetCount()
		return targetTableCount
	end
	function self.setTarget(target)
		currentTarget = target
		if not self.isTargetAvailable() then
			currentTarget = 0
		end
	end
	function self.deselect()
		currentTarget = 0
	end
	--
	--	filters
	--
	function self.filterSphere(sphere,filterAwayTargetsInSphere)
		updateSoulsTable()
		for index,score in pairs(targetTable) do
			local soul = soulTable[index]
			if soul then
				if (soul.position-sphere:getPosition()):length()<sphere:getRadius() then
					--in sphere
					if filterAwayTargetsInSphere then
						targetTable[index] = nil
					end
				else
					--outside sphere
					if not filterAwayTargetsInSphere then
						targetTable[index] = nil
					end
				end
			end
		end
	end
	function self.filterOutState(state)
		updateSoulsTable()
		for index,score in pairs(targetTable) do
			if toBits(soulTable[index].state)[binaryNumPos[state]]==1 then
				targetTable[index] = nil
			end
		end
	end
	--
	--	Score functions
	--
	--add score to all souls in table 
	function self.scoreSelectedTargets(table,addScore)
		local scoredTable = {}
		for i,index in pairs(table) do
			if targetTable[index] and scoredTable[index]==nil then
				targetTable[index] = targetTable[index] + addScore
				scoredTable[index] = true
			end
		end
	end
	--score all souls by how much HP they have
	function self.scoreHP(amount)
		local maxHP = 1.0
		for index,score in pairs(targetTable) do
			maxHP = math.max(maxHP,soulTable[index].hp)
		end
		for index,score in pairs(targetTable) do
			targetTable[index] = score + (soulTable[index].hp/maxHP)*amount
		end
	end
	--add score based on how close they are to the exit 1*amount if litterly on the end and 0*amount if the furthest unit
	function self.scoreClosestToExit(amount)
		local maxDist = 0.0
		for index,score in pairs(targetTable) do
			maxDist = math.max(maxDist,soulTable[index].distanceToExit)
		end
		for index,score in pairs(targetTable) do
			targetTable[index] = score + (1.0-(soulTable[index].distanceToExit/maxDist))*amount
		end
	end
	--add score to unit if name match
	function self.scoreName(name,addScore)
		for index,score in pairs(targetTable) do
			if soulTable[index].name==name then
				targetTable[index] = score + addScore
			end
		end
	end
	--add score if state matches
	function self.scoreState(inState,addScore)
		for index,score in pairs(targetTable) do
			if toBits(soulTable[index].state)[binaryNumPos[inState]]==1 then
				targetTable[index] = score + addScore
			end
		end
	end
	--
	function self.scoreClosest(amount)
		local maxDist = 0.0
		for index,score in pairs(targetTable) do
			maxDist = math.max(maxDist,(soulTable[index].position-position):length())
		end
		for index,score in pairs(targetTable) do
			targetTable[index] = score + (1.0-(soulTable[index].position-position):length()/maxDist)*amount
		end
	end
	function self.scoreDensity(amount)
		local max = 0.0
		local npcCount = {}
		for index,score in pairs(targetTable) do
			for index2,score2 in pairs(targetTable) do
				npcCount[index] = (npcCount[index] or 0.0) + ((soulTable[index].position-soulTable[index2].position):length()<3.0 and 1.0 or 0.0)
				max = math.max(max,npcCount[index])
			end
		end
		for index,score in pairs(targetTable) do
			targetTable[index] = score + (npcCount[index]/max*amount)
		end
	end
	function self.scoreRandom(maxScoreToAdd)
		for index,score in pairs(targetTable) do
			targetTable[index] = score + math.randomFloat(0.0,maxScoreToAdd)
		end
	end
	--add score depending on distant to line
	function self.scoreClosestToVector(atVector,amount)
		local maxDist = 0.0
		for index,score in pairs(targetTable) do
			local dist = math.sqrt(Collision.linePointLength2(Line3D(position,position+(atVector*256.0)),soulTable[index].position))
			maxDist = math.max(dist,maxDist)
		end
		for index,score in pairs(targetTable) do
			local dist = math.sqrt(Collision.linePointLength2(Line3D(position,position+(atVector*256.0)),soulTable[index].position))
			targetTable[index] = score + (1.0-(dist/maxDist))*amount
		end
	end
	--
	--
	--
	local function init()
		team = pteam
	end
	init()
	
	return self
end