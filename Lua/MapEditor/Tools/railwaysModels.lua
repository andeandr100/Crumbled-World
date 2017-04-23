--this = SceneNode()
RailwaysModels = {}

function RailwaysModels.getModelTable()
	local railways = {}
	railways[1] = {model = Core.getModel("Constructions/railroad/railroad_odeg1"), offset = Matrix(Vec3(0,0,2))}
	railways[2] = {model = Core.getModel("Constructions/railroad/railroad_0deg6m"), offset = Matrix(Vec3(0,0,6))}
	railways[3] = {model = Core.getModel("Constructions/railroad/railroad_22deg_left1"), offset = Matrix(Vec3(2,0,0))}
	railways[4] = {model = Core.getModel("Constructions/railroad/railroad_22deg_right1"), offset = Matrix(Vec3(2,0,0))}
	railways[5] = {model = Core.getModel("Constructions/railroad/railroad_45deg_left1"), offset = Matrix(Vec3(2,0,0))}
	railways[6] = {model = Core.getModel("Constructions/railroad/railroad_45deg_right1"), offset = Matrix(Vec3(2,0,0))}
	railways[7] = {model = Core.getModel("Constructions/railroad/railroad_90deg_left1"), offset = Matrix(Vec3(2,0,0))}
	railways[8] = {model = Core.getModel("Constructions/railroad/railroad_90deg_right1"), offset = Matrix(Vec3(2,0,0))}
	
	
	local rad = math.degToRad(22.5)
	for i=1, 3 do
		for n=1, 2 do
			local direction = ( n==2 and -1 or 1 )
			
			print("mat: "..(i*2+n)..", dire: "..direction.."\n")
			
			local mat = Matrix()
			mat:setRotation(Vec3(0,rad,0))
			mat:setPosition(Vec3(-(1-math.sin(math.pi/2 - rad)) * direction, 0, math.cos(math.pi/2 - rad) * direction) * 2.6)
			railways[i*2+n].offset = mat
			
			rad = -rad
		end
		rad = rad * 2
	end
	
	return railways
end