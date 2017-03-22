--this = SceneNode()
function create()
	--this:setIsStatic(true)

	TIMERS_COUNT = 5

	timersBig = {}
	timersSmall = {}
	axles = {}

	gravels = {}
	gravelsSize = {}
	pos = {}
	gravelCount = 0

	local islands = this:getRootNode():findAllNodeByNameTowardsLeaf("*island*")


	for i=0, islands:size()-1, 1 do
		generateGravel(islands:item(i))
	end
	return true
end
function generateGravel(island)
	local list = island:findAllNodeByNameTowardsLeaf("*worldedge*")

	for i = 0, TIMERS_COUNT-1, 1 do
		timersBig[i] = {time=math.randomFloat()*10.0, pos=Vec3()}
		timersSmall[i] = {time=math.randomFloat()*10.0, pos=Vec3()}
		axles[i] = math.randomVec3()
	end

	for i=0, list:size()-1, 1 do
		for j=0, 10, 1 do
			local rand = 1+(math.randomFloat()*5.5)

			local x = (1.4 * ((2.0*math.randomFloat())-1.0))--along side the wall
			local y = (2.25 * math.randomFloat())--height
			local z = 0.30+(1.1 * math.randomFloat())--distance away from wall

			if z<y+0.4 then--0.4 so there is alwas a chanse for spawn
				if math.randomFloat()>0.25 then
					gravels[gravelCount] = Core.getModel( string.format("Data/Models/nature/stone/gravel%d.mym", rand) )
					gravelsSize[gravelCount] = 0.0
				else
					gravels[gravelCount] = Core.getModel( string.format("Data/Models/nature/stone/stone%d.mym", rand) )
					local mat = gravels[gravelCount]:getLocalMatrix()
					mat:scale(0.1+(math.randomFloat()*0.6))
					gravels[gravelCount]:setLocalMatrix(mat)
					--special tretment large rocks
					y = y + 1.0--+1.0 places the bigger stones lower then the small ones
					z = (z*0.3) + 0.10--(z*0.3) makes the big rock come close to the edge + 0.15 sets a minimum distance

					gravelsSize[gravelCount] = 1.0
				end
				
				pos[gravelCount] =  Vec3(x,-y,z) 
				gravels[gravelCount]:setLocalPosition( pos[gravelCount] )
				list:item(i):addChild(gravels[gravelCount])
				gravels[gravelCount]:DisableBoundingVolumesDynamicUpdates()
				--gravels[gravelCount]:setIsStatic(true)
				gravelCount = gravelCount + 1
			end
		end
	end
end
function update()
	local deltaTime = Core.getDeltaTime()*0.25
	for i = 0, TIMERS_COUNT-1, 1 do
		timersBig[i].time = timersBig[i].time + (deltaTime*0.6)
		timersBig[i].pos = Vec3(math.sin(timersBig[i].time),0.0,math.cos(timersBig[i].time))*0.3
		timersSmall[i].time = timersSmall[i].time + (deltaTime*0.2)
		timersSmall[i].pos = Vec3(math.sin(timersSmall[i].time),0.0,math.cos(timersSmall[i].time))*0.3
	end
	local counter = 0
	local tim = 0.0
	for i = 0, gravelCount-1, 1 do
		counter = counter + 1
		if counter==TIMERS_COUNT then counter = 0 end

		if gravelsSize[i]>0.99 then
			gravels[i]:rotate(axles[counter], deltaTime)
			gravels[i]:setLocalPosition( pos[i] + timersBig[counter].pos )
		else
			gravels[i]:setLocalPosition( pos[i] + timersSmall[counter].pos )
		end
		--gravels[i]:render()
	end
	
	return true
end