--this = SceneNode()
resolutions = {}
resolutions[1] = {Name="4x3",Vec2i(640,480),Vec2i(800,600),Vec2i(1024,768),Vec2i(1152,864),Vec2i(1280,960),Vec2i(1400,1050),Vec2i(1600,1200),Vec2i(2048,1536),Vec2i(3200,2400),Vec2i(4000,3000),Vec2i(6400,4800)}
resolutions[5] = {Name="8x5",Vec2i(1920,1200),Vec2i(1680,1050),Vec2i(1440,900),Vec2i(1200,8000)}
resolutions[2] = {Name="16x9",Vec2i(1280,720),Vec2i(1366,768),Vec2i(1600,900),Vec2i(1920,1080),Vec2i(2048,1152),Vec2i(2560,1440),Vec2i(2880,1620),Vec2i(3200,1800),Vec2i(3840,2160),Vec2i(4096,2304),Vec2i(5120,2880),Vec2i(7680,4320),Vec2i(15360,8640)}
resolutions[3] = {Name="16x10",Vec2i(1280,800),Vec2i(1440,900),Vec2i(1680,1050),Vec2i(1920,1200),Vec2i(2560,1600),Vec2i(3840,2400),Vec2i(7680,4800)}
resolutions[5] = {Name="21x9",Vec2i(2560,1080),Vec2i(3440,1440),Vec2i(5120,2160)}


function resolutions.getResolutionList()
	local nativResolution = Core.getNativScreenResolution()
	
	--try to find the resolution inside the data table
	for i=1, #resolutions do
		for n=1, #resolutions[i] do
			if resolutions[i][n] == nativResolution then
				return resolutions[i]
			end
		end
	end
	
	--the resolution was not found
	--Create a new resolution table based on the nativ resolution
	local outResolution = {}
	outResolution[#outResolution+1] = Vec2i(math.round(nativResolution.x/2), math.round(nativResolution.y/2))
	outResolution[#outResolution+1] = Vec2i(math.round((nativResolution.x/4)*3), math.round((nativResolution.y/4)*3))
	outResolution[#outResolution+1] = nativResolution
	return outResolution
end


function resolutions.getResolutionListString()
	local nativResolution = Core.getNativScreenResolution()
	local resList = resolutions.getResolutionList()
	local outList = {}
	
	for i=1, #resList do
		outList[#outList+1] = tostring(resList[i].x).."x"..tostring(resList[i].y)
		if resList[i] == nativResolution then
			return outList
		end
	end
	return outList
end