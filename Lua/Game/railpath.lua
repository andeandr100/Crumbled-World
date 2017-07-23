--this = SceneNode()
function create()
	
	railpoints = nil
	
	grassListener = Listener("Railpath")
	grassListener:registerEvent("path", changed)
		
	print("\nCreated rail path node\n\n")
		
	return true
end

function changed(inData)
	railpoints = inData
end

function save()
	return "table="..tabToStrMinimal(railpoints)
end

function load(inData)
	railpoints = inData
end

function update()
	return true
end