--this = SceneNode()
Settings = {}
Settings.config = Config("settings")

--#######################################################################
--#######################################################################
--#######################################################################

Settings.fullscreen = {}
Settings.fullscreen.options = {"fullscreen", "windowed"}
Settings.fullscreen.configName = "fullscreen"
function Settings.fullscreen.getSettings()
	if Settings.config:get(Settings.fullscreen.configName, true):getBool() then
		return Settings.fullscreen.options[1]
	else
		return Settings.fullscreen.options[2]
	end
end
function Settings.fullscreen.getIsVisible()
	return Settings.config:get(Settings.fullscreen.configName):getBool()
end




Settings.renderScale = {}
Settings.renderScale.options = {"50%", "75%", "100%", "150%", "200%"}
Settings.renderScale.configName = "RenderScale"
function Settings.renderScale.getSettings()
	print("Settings.renderScale.getSettings()\n")
	return Settings.config:get(Settings.renderScale.configName,"100%"):getString()
end

function Settings.renderScale.getValue()
	print("Settings.renderScale.getValue()\n")
	local option = Settings.renderScale.getSettings()
	print("text: "..option.."\n")
	if option == "50%" then
		return 0.5
	elseif option == "75%" then
		return 0.75
	elseif option == "150%" then
		return 1.5
	elseif option == "200%" then
		return 2.0
	else
		return 1.0
	end
end




Settings.vsync = {}
Settings.vsync.options = {"enabled", "disabled"}
Settings.vsync.configName = "vsync"
function Settings.vsync.getSettings()
	return Settings.config:get(Settings.vsync.configName,true):getBool() and "enabled" or "disabled"
end

function Settings.vsync.getValue()
	return (Settings.vsync.getSettings() == "Enabled")
end

--#######################################################################
--#######################################################################
--#######################################################################


Settings.shadow = {}
Settings.shadow.options = {"soft shadow", "hard shadow", "disabled"}
Settings.shadow.configName = "shadow"
function Settings.shadow.getSettings()
	return Settings.config:get(Settings.shadow.configName,"soft shadow"):getString()
end

function Settings.shadow.getShaderDefinition()
	local text = Settings.shadow.getSettings()
	print("Shadow: "..text.."\n")
	if text == "soft shadow" then
		return "SOFT_SHADOW"
	elseif text == "hard shadow" then
		return "SHADOW"
	else
		return nil
	end
end

function Settings.shadow.getIsEnabled()
	return Settings.shadow.getShaderDefinition() ~= nil
end




Settings.shadowResolution = {}
Settings.shadowResolution.options = {"highest", "high", "normal", "low", "lowest"}
Settings.shadowResolution.configName = "shadowResolution"
function Settings.shadowResolution.getSettings()
	return Settings.config:get(Settings.shadowResolution.configName, "normal"):getString()
end

function Settings.shadowResolution.getShaderDefinition()
	local text = Settings.shadowResolution.getSettings()

	if text == "low" or text == "lowest" then
		return "SHADOW_LOW"
	elseif text == "high" or text == "highest" then
		return "SHADOW_HIGH"
	else
		return "SHADOW_NORMAL"
	end
end

function Settings.shadowResolution.getValue()
	local text = Settings.shadowResolution.getSettings()
	if text == "normal" then
		return 1.0
	elseif text == "low" then
		return 0.5
	elseif text == "lowest" then
		return 0.25
	elseif text == "high" then
		return 1.5
	elseif text == "highest" then
		return 2.0
	else
		return 1.0
	end
end



Settings.ambientOcclusion = {}
Settings.ambientOcclusion.options = {"enabled", "disabled"}
Settings.ambientOcclusion.configName = "ambientOcclusion"
function Settings.ambientOcclusion.getSettings()
	return Settings.config:get(Settings.ambientOcclusion.configName, true):getBool() and Settings.ambientOcclusion.options[1] or Settings.ambientOcclusion.options[2]
end
function Settings.ambientOcclusion.getShaderDefinition()
	return Settings.config:get(Settings.ambientOcclusion.configName, true):getBool() and "AMBIENT_OCCLUSION" or nil
end

function Settings.getDeferredShader()
	local definitions = {}
	
	local definition = Settings.ambientOcclusion.getShaderDefinition()
	if definition then
		definitions[#definitions+1] = definition
	end
	
	definition = Settings.shadow.getShaderDefinition()
	if definition then
		definitions[#definitions+1] = definition
	end
	
	definition = Settings.shadowResolution.getShaderDefinition()
	if definition then
		definitions[#definitions+1] = definition
	end
		
	print("Shader definition: "..tostring(definitions).."\n")
	return Core.getShader("mainShader", definitions)
end



Settings.Antialiasing = {}
Settings.Antialiasing.options = {"enabled", "disabled"}
Settings.Antialiasing.configName = "Antialiasing"
function Settings.Antialiasing.getSettings()
	return Settings.config:get(Settings.Antialiasing.configName, true):getBool() and Settings.Antialiasing.options[1] or Settings.Antialiasing.options[2]
end
function Settings.Antialiasing.getEnabled()
	return Settings.config:get(Settings.Antialiasing.configName, true):getBool()
end



Settings.glow = {}
Settings.glow.options = {"enabled", "disabled"}
Settings.glow.configName = "glow"
function Settings.glow.getSettings()
	return Settings.config:get(Settings.glow.configName, true):getBool() and Settings.glow.options[1] or Settings.glow.options[2]
end
function Settings.glow.getEnabled()
	return Settings.config:get(Settings.glow.configName, true):getBool()
end


Settings.dynamicLights = {}
Settings.dynamicLights.options = {"enabled", "disabled"}
Settings.dynamicLights.configName = "dynamicLights"
function Settings.dynamicLights.getSettings()
	return Settings.config:get(Settings.dynamicLights.configName, true):getBool() and Settings.dynamicLights.options[1] or Settings.dynamicLights.options[2]
end
function Settings.dynamicLights.getEnabled()
	return Settings.config:get(Settings.dynamicLights.configName, true):getBool()
end


--#######################################################################
--#######################################################################
--#######################################################################


Settings.islandSmoke = {}
Settings.islandSmoke.options = {"visible", "hidden"}
Settings.islandSmoke.configName = "islandSmoke"
function Settings.islandSmoke.getSettings()
	return Settings.config:get(Settings.islandSmoke.configName, true):getBool() and Settings.islandSmoke.options[1] or Settings.islandSmoke.options[2]
end
function Settings.islandSmoke.getIsVisible()
	return Settings.config:get(Settings.islandSmoke.configName, true):getBool()
end




Settings.towerMenu = {}
Settings.towerMenu.options = {"visible", "hidden"}
Settings.towerMenu.configName = "towerMenu"
function Settings.towerMenu.getSettings()
	return Settings.config:get(Settings.towerMenu.configName, true):getBool() and Settings.towerMenu.options[1] or Settings.towerMenu.options[2]
end
function Settings.towerMenu.getIsVisible()
	return Settings.config:get(Settings.towerMenu.configName, true):getBool()
end



Settings.floatingStones = {}
Settings.floatingStones.options = {"visible", "hidden"}
Settings.floatingStones.configName = "floatingStones"
function Settings.floatingStones.getSettings()
	return Settings.config:get(Settings.floatingStones.configName, true):getBool() and Settings.floatingStones.options[1] or Settings.floatingStones.options[2]
end
function Settings.floatingStones.getIsVisible()
	return Settings.config:get(Settings.floatingStones.configName, true):getBool()
end
--
-- NO OPTION IN MENU
function Settings.getFloatingStonesDensity()
	return Settings.config:get("floatingStonesDensity",2.25):getInt()
end
function Settings.isTutorial1Done()
	return Settings.config:get("Tutorial_1_Done",false):getBool()
end
function Settings.setTutorial1Done()
	Settings.config:get("Tutorial_1_Done"):setBool(true)
	Settings.config:save()
end
function Settings.isTutorial2Done()
	return Settings.config:get("Tutorial_2_Done",false):getBool()
end
function Settings.setTutorial2Done()
	Settings.config:get("Tutorial_2_Done"):setBool(true)
	Settings.config:save()
end
function Settings.isTutorial3Done()
	return Settings.config:get("Tutorial_3_Done",false):getBool()
end
function Settings.setTutorial3Done()
	Settings.config:get("Tutorial_3_Done"):setBool(true)
	Settings.config:save()
end
function Settings.overideShowTutorial()
	local out = Settings.config:get("Tutorials_how",false):getBool()
	if out then
		Settings.config:get("Tutorials_how"):setBool(false)
		Settings.config:save()
	end
	return out
end
function Settings.setShowTutorial()
	Settings.config:get("Tutorials_how"):setBool(true)
	Settings.config:save()
end
--
--



Settings.healthBar = {}
Settings.healthBar.options = {"always", "when damaged", "hidden"}
Settings.healthBar.configName = "healthBar"
function Settings.healthBar.getSettings()
	return Settings.config:get(Settings.healthBar.configName, "when damaged"):getString()
end
function Settings.healthBar.getIsVisibleOnlyWhenDamaged()
	return Settings.config:get(Settings.healthBar.configName, "when damaged"):getString()=="when damaged"
end
function Settings.healthBar.getIsVisible()
	return Settings.config:get(Settings.healthBar.configName, "when damaged"):getString()~="hidden"
end



Settings.DeathAnimation = {}
Settings.DeathAnimation.options = {"enabled", "fast", "disabled"}
Settings.DeathAnimation.configName = "DeathAnimation"
function Settings.DeathAnimation.getSettings()
	return Settings.config:get(Settings.DeathAnimation.configName, "fast"):getString()
end
function Settings.DeathAnimation.getValue()
	return Settings.config:get(Settings.DeathAnimation.configName, "fast"):getString()
end

Settings.corpseTimer = {}
Settings.corpseTimer.options = {"long", "medium", "short", "none"}
Settings.corpseTimer.optionsInt = {High=8, Normal=3, Low=1, None=0}
Settings.corpseTimer.configName = "corpseTimer"
function Settings.corpseTimer.getSettings()
	return Settings.config:get(Settings.corpseTimer.configName, "medium"):getString()
end
function Settings.corpseTimer.getValue()
	return Settings.config:get(Settings.corpseTimer.configName, "medium"):getString()
end
function Settings.corpseTimer.getInt()
	local str = Settings.corpseTimer.getValue()
	return Settings.corpseTimer.optionsInt[str] or 1
end



Settings.modelDensity = {}
Settings.modelDensity.options = {"100%", "80%", "60%", "40%", "20%"}
Settings.modelDensity.configName = "modelDensity"
function Settings.modelDensity.getSettings()
	return Settings.config:get(Settings.modelDensity.configName, "100%"):getString()
end

function Settings.modelDensity.getValue()
	local text = Settings.modelDensity.getSettings()
	if text == "100%" then
		return 1
	elseif text == "80%" then
		return 0.75
	elseif text == "60%" then
		return 0.5
	elseif text == "40%" then
		return 0.25
	elseif text == "20%" then
		return 0
	end
	return 1
end


--#######################################################################
--#######################################################################
--#######################################################################

Settings.soundMasterGain = {}
Settings.soundMasterGain.configName = "soundMasterGain"
function Settings.soundMasterGain.getGain()
	return math.clamp( Settings.config:get(Settings.soundMasterGain.configName, 1.0):getFloat(), 0, 1)
end

function Settings.soundMasterGain.setGain(value)
	Settings.config:get(Settings.soundMasterGain.configName):setFloat(value)
	Settings.config:save()
end



Settings.soundMusicGain = {}
Settings.soundMusicGain.configName = "soundMusicGain"
function Settings.soundMusicGain.getGain()
	return math.clamp( Settings.config:get(Settings.soundMusicGain.configName, 1.0):getFloat(), 0, 1)
end

function Settings.soundMusicGain.setGain(value)
	Settings.config:get(Settings.soundMusicGain.configName):setFloat(value)
	Settings.config:save()
end



Settings.soundEffectGain = {}
Settings.soundEffectGain.configName = "soundEffectGain"
function Settings.soundEffectGain.getGain()
	return math.clamp( Settings.config:get(Settings.soundEffectGain.configName, 1.0):getFloat(), 0, 1)
end

function Settings.soundEffectGain.setGain(value)
	Settings.config:get(Settings.soundEffectGain.configName):setFloat(value)
	Settings.config:save()
end

--#######################################################################
--#######################################################################
--#######################################################################

Settings.multiplayerName = {}
Settings.multiplayerName.configName = "multiplayerName"
function Settings.multiplayerName.getSettings()
	return Settings.config:get(Settings.multiplayerName.configName, "Player"):getString()
end

--#######################################################################
--#######################################################################
--#######################################################################

Settings.Language = {}
Settings.Language.configName = "Language"
function Settings.Language.getSettings()
	return Settings.config:get(Settings.Language.configName, "English"):getString()
end