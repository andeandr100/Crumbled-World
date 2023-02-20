require("NPC/state.lua")
require("Game/mapInfo.lua")
SHIELD_RANGE = 3.5

TargetSelector = {}
function TargetSelector.new(pteam)
	local self = {}
	
	local FORCEUPDATE = true
	local UPDATEIFNEEDED = false
	
	local soulManagerBillboard = Core.getBillboard("SoulManager")
	local position = Vec3()
	local range = 0.0
	local binaryNumPos = {[1]=1,[2]=2,[4]=3,[8]=4,[16]=5,[32]=6,[64]=7,[128]=8,[256]=9,[512]=10,[1024]=11,[2048]=12}
	local team = -1
	local isThisReal = this:findNodeByTypeTowardsRoot(NodeId.island)
	local isCircleMap = MapInfo.new().isCricleMap()
	---
	local soulTableLastUpdatedFrame = 0
	local soulTable = {}
	local shieldGenTableLastUpdated = 0
	local shieldGenTable = {}
	--
	local targetTable = {}
	local targetTableCount = 0
	local currentTarget = 0
	local defaultPipeAt = Vec3()
	local defaultAngleLimit = math.pi*3
	local soulTableNamesToUse = {}
	--
	local storedSettings
	--
	--
	--
	-- function:	updateTablesToUse
	-- purpose:		updates table(updateTablesToUse) with all areas that can be used,(areas that are reachable from position with range and angles)
	function updateTablesToUse(forceUpdate)
		soulManagerBillboard = soulManagerBillboard or Core.getBillboard("SoulManager")
		if soulManagerBillboard then
			if forceUpdate or (worldMin==nil or worldMin~=soulManagerBillboard:getVec2("min")) or (worldMax==nil or worldMax~=soulManagerBillboard:getVec2("max")) then
--				local r = range
--				local p = position
				soulTableNamesToUse = {}
				local rangeLimit = range+5.66--pytagoras y = sqrt((4^2)+(4^2)) = 5.65685 == 5.66 (the distance from center of a  8w square to a corner
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
						--Core.addDebugLine(Vec3(lx,0,ly),Vec3(lx,2,ly),0.1,Vec3(1))
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
	-- function:	setPosition
	-- purpose:		sets the placement of the targetSelecter
	function self.setPosition(pos)
		--assert(pos, "When TargetSelector.setPosition(pos), pos must be a Vec3()")
		position = pos
		updateTablesToUse(FORCEUPDATE)
	end
	function self.storeSettings()
		storedSettings = {
			position = position,
			range = range,
			currentTarget = currentTarget,
			defaultPipeAt = defaultPipeAt,
			defaultAngleLimit = defaultAngleLimit
		}
	end
	function self.restoreSettings()
		if storedSettings then
			position = storedSettings.position
			range = storedSettings.range
			currentTarget = storedSettings.currentTarget
			defaultPipeAt = storedSettings.defaultPipeAt
			defaultAngleLimit = storedSettings.defaultAngleLimit
			storedSettings = nil
		end
	end
	-- function:	setAngleLimits
	-- purpose:		limits the target angle. [used by arrowTower]
	function self.setAngleLimits(pipeAt,angleLimit)
		defaultPipeAt = pipeAt
		defaultAngleLimit = angleLimit
	end
	function self.getDefaultAngleLimits()
		return defaultPipeAt,defaultAngleLimit
	end
	-- function:	setRange
	-- purpose:		set the raduius where we can attack
	function self.setRange(pRange)
		range = pRange
		updateTablesToUse(FORCEUPDATE)
	end
	-- function:	disableRealityCheck
	-- purpose:		improves performance and used by lifebar
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
	-- function:	toBits
	-- purpose:		returns a table like 9 = {1,0,0,1} where [1]=1 [2]=2 [3]=4 [4]=8
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
	-- function:	updateSoulsTable
	-- purpose:		updates all npcs that can be targeted and lists them in table(soulTable) wich uses area keys
	local function updateSoulsTable()
		if isThisReal and Core.getFrameNumber()~=soulTableLastUpdatedFrame then
			soulTableLastUpdatedFrame = Core.getFrameNumber()
			--soulManagerBillboard = soulManagerBillboard or Core.getBillboard("SoulManager")
			soulTable = {}
			for i=1, #soulTableNamesToUse do
				local input = soulManagerBillboard:getTable(soulTableNamesToUse[i])
				for i=1, #input do
					soulTable[input[i][1]] = {
						position=Vec3(input[i][2],input[i][3],input[i][4]),
						distanceToExit=input[i][5],
						hp=input[i][6],
						hpMax=input[i][7],
						team=input[i][8],
						state=input[i][9],
						name=input[i][10],
						index=input[i][1],
						defaultState=input[i][11]
					}
				end
			end
		end
	end
	-- function:	updateShieldGenTable
	-- purpose:		lists all shile carring units (turtle). max 3
	local function updateShieldGenTable()
		if isThisReal and Core.getGameTime()-shieldGenTableLastUpdated>1.0 then
			shieldGenTableLastUpdatedFrame = Core.getGameTime()
			local input = soulManagerBillboard:getTable("shieldGenerators")
			shieldGenTable = {}
			for i=1, #input do
				local target = input[i]
				shieldGenTable[target] = self.getTargetPosition(target)
			end
		end
	end
	--
	--	getters
	--
	-- function:	isInRange
	-- purpose:		returns true if target or selected if no target is given, is in range
	local function isInRange(target)
		if self.isTargetAlive(target) then
			local effectiveRange = range + (self.isTargetInStateAShieldGenerator(target) and SHIELD_RANGE or 0.0)
			local pos = self.getTargetPosition(target)
			local inRange = (pos-position):length()<=effectiveRange
			if inRange and defaultAngleLimit<math.pi then
				local diff = pos-position
				local targetAt = Vec2(diff.x,diff.z)
				local angle = Vec2(defaultPipeAt.x,defaultPipeAt.z):angle(targetAt)
				return defaultAngleLimit>angle
			end
			return inRange
		end
		return false
	end
	-- function:	isAnyInRange
	-- purpose:		returns true if any enemy is in range
	function self.isAnyInRange()
		for index,soul in pairs(soulTable) do
			if isInRange(index) then
				return true
			end
		end
		return false
	end
	-- function:	isAnyInCapsule
	-- purpose:		returns true if any enemy is inside the capsule
	function self.isAnyInCapsule(line,lineRange)
		--get all souls on the map
		updateSoulsTable()
		--
		for index,soul in pairs(soulTable) do
			if soul.team~=team and Collision.lineSegmentPointLength2(line,soul.position)<(lineRange+(self.isTargetInStateAShieldGenerator(index) and SHIELD_RANGE or 0.0)) then
				return true
			end
		end
		return false
	end
	--
	-- function:	getIndexOfShieldCovering
	-- purpose:		returns one shiled that covers that area or returns 0 if no shield covers it
	function self.getIndexOfShieldCovering(globalPosition)
		updateShieldGenTable()
		--
		for index,position in pairs(shieldGenTable) do
			if (globalPosition-self.getTargetPosition(index)):length()<=SHIELD_RANGE then
				return index
			end
		end
		return 0
	end
	--
	-- function:	getIndexOfShieldCovering
	-- purpose:		returns one shiled that covers that area or returns 0 if no shield covers it
	function self.getShieldPositionFromShieldIndex(shieldIndex)
		return self.getTargetPosition(shieldIndex)
	end
	-- function:	isTargetAlive
	-- purpose:		returns true if target npc is alive
	function self.isTargetAlive(target)
		local soulBillboard = Core.getBillboard(target or currentTarget)
		return soulBillboard and soulBillboard:getBool("isAlive")==true or false
	end
	-- function:	isTargetInStateAShieldGenerator
	-- purpose:		returns true if target is a turtle
	function self.isTargetInStateAShieldGenerator(target)
		local soul = soulTable[target or currentTarget]
		return soul and toBits(soul.state)[binaryNumPos[state.shieldGenerator]]==1
	end
	-- function:	isTargetInState
	-- purpose:		returns true if target is i state
	function self.isTargetInState(target, state)
		local soul = soulTable[target or currentTarget]
		return soul and toBits(soul.state)[binaryNumPos[state]]==1
	end
	-- function:	isTargetInState
	-- purpose:		returns true if soul is in state but not by default
	function isInStateNoneDefault(soul,state)
		local bPos = binaryNumPos[state]
		return toBits(soul.state)[bPos]==1 and toBits(soul.defaultState)[bPos]==0
	end
	-- function:	isTargetInState
	-- purpose:		returns state value used in the lifebar
	function self.getTargetStateValue(target)
		local soul = soulTable[target or currentTarget]
		local value = 0.0
		if soul then
			value = value + ( isInStateNoneDefault(soul,state.markOfGold) and state.markOfGold or 0 )
			value = value + ( isInStateNoneDefault(soul,state.ignore) and state.ignore or 0 )
			value = value + ( isInStateNoneDefault(soul,state.highPriority) and state.highPriority or 0 )
			value = value + ( isInStateNoneDefault(soul,state.markOfDeath) and state.markOfDeath or 0 )
			value = value + ( isInStateNoneDefault(soul,state.electrecuted) and state.electrecuted or 0 )
			value = value + ( isInStateNoneDefault(soul,state.burning) and state.burning or 0 )
		end
		return value
	end
	-- function:	isTargetNamed
	-- purpose:		returns true if target is named name
	function self.isTargetNamed(name)
		local soul = soulTable[currentTarget]
		return (soul and soul.name==name)
	end
	-- function:	isTargetAvailable
	-- purpose:		retruns true if current target is in range
	function self.isTargetAvailable()
		return (currentTarget>0 and soulTable[currentTarget] and isInRange(currentTarget))--hp has nothing to do with if the npc can be targeted
	end
	-- function:	getTargetPosition
	-- purpose:		returns the current position of the target if alive
	function self.getTargetPosition(target)
		local soulBillboard = Core.getBillboard(target or currentTarget)
		local retPos = Vec3()
		if soulBillboard then
			local mover = soulBillboard:getNodeMover("nodeMover")
			if mover and soulBillboard:getBool("isAlive") then
				retPos = mover:getCurrentPosition() + soulBillboard:getVec3("aimHeight")
			end
		end
		return retPos
	end
	-- function:	getTargetVelocity
	-- purpose:		returns the current valocity of the target if alive
	function self.getTargetVelocity(target)
		local retVec = Vec3()
		local soulBillboard = Core.getBillboard(target or currentTarget)
		if soulBillboard then
			local mover = soulBillboard:getNodeMover("nodeMover")
			if mover and soulBillboard:getBool("isAlive") then
				retVec = mover:getCurrentVelocity()
			end
		end
		return retVec
	end
	-- function:	getFuturePos
	-- purpose:		returns the future position of a target x time from now if alive
	function self.getFuturePos(target,time)
		local retPos = Vec3()
		local soulBillboard = Core.getBillboard(target or currentTarget)
		if soulBillboard then
			local mover = soulBillboard:getNodeMover("nodeMover")
			if mover and soulBillboard:getBool("isAlive") then
				retPos = mover:getFuturePosition(time) + soulBillboard:getVec3("aimHeight")
			end
		end
		return retPos
	end
	-- function:	getTargetHP
	-- purpose:		returns the current hp od the target
	function self.getTargetHP(target)
		local hp = -1.0
		local soulBillboard = Core.getBillboard(target or currentTarget)
		if soulBillboard and soulBillboard:getBool("isAlive") then
			hp = soulBillboard:getDouble("hp")
		end
		return hp
	end
	
	function self.getTargetMaxHP(target)
		local hpMax = -1.0
		local soulBillboard = Core.getBillboard(target or currentTarget)
		if soulBillboard and soulBillboard:getBool("isAlive") then
			hpMax = soulBillboard:getDouble("hpMax")
		end
		return hpMax
	end

	function self.getTargetHPPercentage(target)
		local hpPercentage = 0.0
		local soulBillboard = Core.getBillboard(target or currentTarget)
		if soulBillboard and soulBillboard:getBool("isAlive") then
			hpPercentage = soulBillboard:getDouble("hp") / soulBillboard:getDouble("hpMax")
		end
		return hpPercentage
	end
	
	
	-- function:	getTarget
	-- purpose:		returns the currently active target(currentTarget)
	function self.getTarget()
		return currentTarget
	end
	-- function:	getTargetIfAvailable
	-- purpose:		returns the currently active target if available
	function self.getTargetIfAvailable()
		if self.isTargetAvailable() then
			return currentTarget
		end
		currentTarget = 0
		return currentTarget
	end
	
	
--	local function isInRange(target)
--		if self.isTargetAlive(target) then
--			local effectiveRange = range + (self.isTargetInStateAShieldGenerator(target) and SHIELD_RANGE or 0.0)
--			local pos = self.getTargetPosition(target)
--			local inRange = (pos-position):length()<=effectiveRange
--			if inRange and defaultAngleLimit<math.pi then
--				local diff = pos-position
--				local targetAt = Vec2(diff.x,diff.z)
--				local angle = Vec2(defaultPipeAt.x,defaultPipeAt.z):angle(targetAt)
--				return defaultAngleLimit>angle
--			end
--			return inRange
--		end
--		return false
--	end

	
	--
	--	Selecter functions
	--
	-- function:	selectAllInRange
	-- purpose:		seleact all enemies in range
	function self.selectAllInRangeCalculateDisatance()
		local ret = false
		--
		updateTablesToUse(UPDATEIFNEEDED)
		--print("soulTableNamesToUse == "..tostring(soulTableNamesToUse))
		--clear old data
		targetTable = {}
		targetTableCount = 0
		currentTarget = 0
		--get all souls on the map
		updateSoulsTable()
		--go threw them all and test the range. if in range add to targetTable
		for index,soul in pairs(soulTable) do
			if soul.team~=team and self.isTargetAlive(index) then--hp does not matter(they are alive on this list), they can have close to 0 health and it will 
				local pos = self.getTargetPosition(index)
				local distance = (pos-position):length()
				if distance < range then
					targetTable[index] = math.max(0.1, 1-(distance/range))
					targetTableCount = targetTableCount + 1
					ret = true
				end
			end
		end
		return ret
	end

	
	--
	--	Selecter functions
	--
	-- function:	selectAllInRange
	-- purpose:		seleact all enemies in range
	function self.selectAllInRange()
		local ret = false
		--
		updateTablesToUse(UPDATEIFNEEDED)
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
	-- function:	selectAllInCapsule
	-- purpose:		selects all enemies in capsule
	function self.selectAllInCapsule(line,lineRange)
		local ret = false
		--
		updateTablesToUse(UPDATEIFNEEDED)
		--clear old data
		targetTable = {}
		targetTableCount = 0
		currentTarget = 0
		--get all souls on the map
		updateSoulsTable()
		--
		for index,soul in pairs(soulTable) do
			--Core.addDebugLine(soul.position, soul.position+Vec3(0,4,0), 0.05, Vec3(1))
			if soul.team~=team and Collision.lineSegmentPointLength2(line,soul.position)<(lineRange+(self.isTargetInStateAShieldGenerator(index) and SHIELD_RANGE or 0.0)) then
				targetTable[index] = 0
				targetTableCount = targetTableCount + 1
				ret = true
			end
		end
		return ret
	end
	-- function:	selectTargetAfterMaxScore
	-- purpose:		selects  the target with max score, with a minimum of minimumScore
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
	-- function:	selectTargetAfterMaxScorePer
	-- purpose:		selects the target with minimum score of minimumScore and is places places closed in percentage on the table
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
	-- function:	selectTargetCountAfterMaxScore
	-- purpose:
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
	-- function:	getAllTargets
	-- purpose:		returns all targets index and score
	function self.getAllTargets()
		return targetTable
	end
	-- function:	getAllSouls
	-- purpose:		returns souls of all targets
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
	-- function:	getAllTargetCount
	-- purpose:		returns the number of targets
	function self.getAllTargetCount()
		return targetTableCount
	end
	-- function:	setTarget
	-- purpose:		manualy set what target to target
	function self.setTarget(target)
		currentTarget = target
	end
	-- function:	deselect
	-- purpose:		manually deselect selected target
	function self.deselect()
		currentTarget = 0
	end
	--
	--	filters
	--
	-- function:	filterSphere
	-- purpose:		filter all targets in sphere
	function self.filterSphere(sphere,filterAwayTargetsInSphere)
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
	-- function:	filterOutState
	-- purpose:		filter out all targets in state
	function self.filterOutState(state)
		for index,score in pairs(targetTable) do
			if toBits(soulTable[index].state)[binaryNumPos[state]]==1 then
				targetTable[index] = nil
			end
		end
	end
	--
	--	Score functions
	--
	-- function:	scoreSelectedTargets
	-- purpose:		add score to all souls in table 
	function self.scoreSelectedTargets(table,addScore)
		local scoredTable = {}
		for i,index in pairs(table) do
			if targetTable[index] and scoredTable[index]==nil then
				targetTable[index] = targetTable[index] + addScore
				scoredTable[index] = true
			end
		end
	end
	-- function:	scoreHP
	-- purpose:		score all souls by how much HP they have
	function self.scoreHP(amount)
		local maxHP = 1.0
		for index,score in pairs(targetTable) do
			maxHP = math.max(maxHP,soulTable[index].hp)
		end
		for index,score in pairs(targetTable) do
			targetTable[index] = score + (soulTable[index].hp/maxHP)*amount
		end
	end
	-- function:	scoreClosestToExit
	-- purpose:		add score based on how close they are to the exit 1*amount if litterly on the end and 0*amount if the furthest unit
	function self.scoreClosestToExit(amount)
		if not isCircleMap then
			local maxDist = 0.0
			for index,score in pairs(targetTable) do
				maxDist = math.max(maxDist,soulTable[index].distanceToExit)
			end
			for index,score in pairs(targetTable) do
				targetTable[index] = score + (1.0-(soulTable[index].distanceToExit/maxDist))*amount
			end
		end
	end
	-- function:	scoreName
	-- purpose:		add score to unit if name match
	function self.scoreName(name,addScore)
		for index,score in pairs(targetTable) do
			if soulTable[index].name==name then
				targetTable[index] = score + addScore
			end
		end
	end
	-- function:	scoreState
	-- purpose:		add score if state matches
	function self.scoreState(inState,addScore)
		for index,score in pairs(targetTable) do
			if toBits(soulTable[index].state)[binaryNumPos[inState]]==1 then
				targetTable[index] = score + addScore
			end
		end
	end
	-- function:	scoreClosest
	-- purpose:		add score to targets depending on how far awway they are
	function self.scoreClosest(amount)
		local maxDist = 0.0
		for index,score in pairs(targetTable) do
			maxDist = math.max(maxDist,(soulTable[index].position-position):length())
		end
		for index,score in pairs(targetTable) do
			targetTable[index] = score + (1.0-(soulTable[index].position-position):length()/maxDist)*amount
		end
	end
	-- function:	scoreDensity
	-- purpose:		adds score based on density
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
	-- function:	scoreRandom
	
	-- purpose:
	function self.scoreRandom(maxScoreToAdd)
		for index,score in pairs(targetTable) do
			targetTable[index] = score + math.randomFloat(0.0,maxScoreToAdd)
		end
	end
	-- function:	scoreClosestToVector
	-- purpose:		adds score depending on distant to line
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
	-- function:	expand
	-- purpose:
	local function init()
		team = pteam
	end
	init()
	
	return self
end