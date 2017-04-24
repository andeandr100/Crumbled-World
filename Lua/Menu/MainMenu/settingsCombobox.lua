require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/settings.lua")
--this = SceneNode()
SettingsComboBox = {}

function SettingsComboBox.new(parentPanel, panelSize, inItems, tag, settings, aCallback, aTooltips)
	local self = {}
	local comboBox
	local items = inItems
	local index = 1
	local callback = aCallback
	local tooltips = aTooltips
	
	function self.getIndex()
		return index
	end
	
	function self.getIndexText()
		return items[index]
	end
	
	function self.setIndex(inIndex)
		if index ~= inIndex and index > 0 and index <= #items then
			index = inIndex
			local text = language:getText(items[index])
			comboBox:setText( (text == Text("")) and items[index] or text )
		end
	end
	
	function self.setItems(inItems)
		items = inItems
		if index < #items then
			index = #items
		end
		self.updateLanguage()
	end
	
	function self.setEnabled(enable)
		comboBox:setEnabled(enable)
	end
	
	function self.isEnabled()
		return comboBox:getEnabled()
	end

	function self.getComboBox()
		return comboBox
	end
	
	local function changeIndex(button)
		local newIndex = tonumber(button:getTag():toString())
		if index ~= newIndex then
			index = newIndex
			comboBox:setText(button:getText())
			
			if callback then
				callback(tag, index, inItems)
			end
		end
	end
	
	function self.updateLanguage()
		local text = language:getText(items[index])
		comboBox:setText( (text == Text("")) and items[index] or text )
		comboBox:clearItems()
		
		for i=1, #items do
			text = language:getText(items[i])
			local itemButton = comboBox:addItem( MainMenuStyle.createMenuButton(Vec2(-1,0.03), Vec2(), (text == Text("")) and items[i] or text ) )
			itemButton:setTag(tostring(i))
			if tooltips and tooltips[i] then
				itemButton:setToolTip(language:getText(tooltips[i]))
			end
			itemButton:addEventCallbackExecute(changeIndex)
		end
	end
	
	local function init()
		comboBox = ComboBox(panelSize, "")
		parentPanel:add(comboBox)
		
		for i=1, #items do
			if items[i] == settings then
				index = i
			end
		end
		
		self.updateLanguage()
	end
	
	init()
	
	return self
end
