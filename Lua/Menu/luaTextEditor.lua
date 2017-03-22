--this = SceneNode()

function destroy()
	if form then
		form:setVisible(false)
		form:destroy()
		form = nil
	end
end


function create()
	
	local camera = ConvertToCamera( this.getRootNode(this):findNodeByName("MainCamera") )
	
	--This node must have a private work to not create deadlock
	--local localWork = this:createWork()
	
	if camera then
		form = Form(camera, PanelSize(Vec2(0.7,1.0)), Alignment.TOP_RIGHT)
		form:setLayout(FlowLayout())
		form:setRenderLevel(12)
		
		textArea = form:add(TextArea(PanelSize(Vec2(-1,-1))))
		
		textArea:setOptionPanelVisible(true)
		textArea:setReloadCallback(reload)


		local tab = getCrashTable()
		local tableSize = #tab
		if tableSize > 0 then
			filePath, row = splitFirst(tab[tableSize],":")
			textArea:openFile(Text(filePath))
			textArea:setOpenedFile(filePath)
			textArea:setFirstVisibleRow(row - textArea:getNumVisibleRows() / 2 )
		end
		
		timeSpeed = Core.getTimeSpeed()
		Core.setTimeSpeed(0)
--		local formList = form.getAllFormFromCamera(camera)
--		
--		for i=0, formList:size()-1 do
--			localWork:addDependency( formList:item(i):getWorkUpdater() )
--		end
	end
	return true
end

function splitFirst(str,sep)
	local text1 = ""
	local text2 = ""
	local size = 0
	local reg = string.format("([^%s]+)",sep)
	for mem in string.gmatch(str,reg) do
		if size == 2 then
			text2 = text2 .. sep .. mem;
		elseif size == 1 then
			text2 = mem
			size = size + 1
		else
			text1 = mem
			size = size + 1
		end
	end	
	return text1, text2
end

function reload(button)
	
end

function update()
	
	if  Core.getInput():getKeyPressed(Key.F8) then
		form:setVisible( not form:getVisible() )
		if form:getVisible() then
			--get the time speed
			timeSpeed = Core.getTimeSpeed()
			--Pause the game
			Core.setTimeSpeed(0)
		else
			--Unpause the game and set previous time speed
			Core.setTimeSpeed(timeSpeed)
		end
	end
	
	form:update();
	
	return true;
end