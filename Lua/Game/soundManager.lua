SoundManager = {}
function SoundManager.new(pNode)
	local self = {}
	local node=pNode
	local available = {}
	local stopping = {}
	local active = {}
	
	local isAllStopped = true
	
	--
	--Private
	--
	local function moveFromTo(fromTable, toTable, fromIndex, moveFunc)
		moveFunc = moveFunc or function(item) return item end
		if fromIndex>=1 then
			toTable[#toTable+1] = moveFunc(fromTable[fromIndex])
			if fromIndex~=#fromTable then
				fromTable[fromIndex] = fromTable[#fromTable]
			end
			fromTable[#fromTable] = nil
			return toTable[#toTable]
		end
	end
	local function cleanTable(table)
		for k,v in pairs(table) do
			local i=1
			while i<=#v do
				if type(v[i])=="table" then
					if v[i].start+v[i].fadeTime+0.1<Core.getTime() then
						moveFromTo(table[k], available[k], i, function(item) return item.sound end)
					else
						i = i + 1
					end
				else
					if v[i]:isPlaying()==false then
						moveFromTo(table[k], available[k], i)
					else
						i = i + 1
					end
				end
			end
		end
	end
	local function addSound(soundName)
		print("SoundManager - addSound("..soundName..")")
		available[soundName][#available[soundName]+1] = SoundNode.new(soundName)
		node:addChild( available[soundName][#available[soundName]]:toSceneNode() )
	end
	local function isSoundAvailable(soundName)
		return #available[soundName]>0
	end
	local function getSound(soundName)
		if not isSoundAvailable(soundName) then
			addSound(soundName)
		end
		return moveFromTo(available[soundName], active[soundName], #available[soundName])
	end
	
	--
	--Public
	--
	function self.play(soundName, level, onRepeat)
		if node then
			isAllStopped = false
			--make sure it exist
			available[soundName] = available[soundName] or {}
			stopping[soundName] = stopping[soundName] or {}
			active[soundName] = active[soundName] or {}
			--clear all stopped sounds
			cleanTable(active)
			cleanTable(stopping)
			--play the sound
			local sound = getSound(soundName)
			sound:play(level,onRepeat)
			print("SoundManager - PLAY() Ac:"..tostring(#active[soundName]).." Av:"..tostring(#available[soundName]).." St:"..tostring(#stopping[soundName]))
			return sound
		else
			backgroundSound = Sound(soundName,SoundType.EFFECT)
			soundSource = backgroundSound:playSound(1.0, onRepeat)
		end
	end
	
	function self.stopAll(fadeTime)
		if node then
			isAllStopped = true
			for k,v in pairs(active) do
				local i=1
				while i<=#v do
					if active[k][i]:isPlaying() then
						if active[k][i]:isPlaying() then
							--the sound is playing
							--move it to the holding table
							active[k][i]:stopFadeOut(fadeTime)
							moveFromTo(active[k], stopping[k], i, function(item) return {sound=item, start=Core.getTime(), fadeTime=fadeTime} end)
						else
							--the sound is not playing
							--move it to the available table
							moveFromTo(active[k], available[k], i)
						end
					else
						i = i + 1
					end
				end
			end
		end
	end
	function self.isAllStopped()
		if node then
			return isAllStopped
		else
			return true
		end
	end
	
	--
	--Declaration
	--
	return self
end