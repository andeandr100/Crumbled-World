--this = SceneNode()

function createKeyboardBind(groupName, subGroupName, name, ctrlKey, key1, key2)
	local keyBind = KeyBind(groupName, subGroupName, name)
	keyBind:setKeyBindKeyboard(0, ctrlKey, key1 )
	if key2 then
		keyBind:setKeyBindKeyboard(1, ctrlKey, key2 )
	end
	pKeyBinds:setKeyBind( name, keyBind )
	return keyBind
end

function createKeyboardBind2(groupName, subGroupName, name, ctrlKey1, ctrlKey2, key1, key2)
	local keyBind = KeyBind(groupName, subGroupName, name)
	keyBind:setKeyBindKeyboard(0, ctrlKey1, ctrlKey2, key1 )
	if key2 then
		keyBind:setKeyBindKeyboard(1, ctrlKey, key2 )
	end
	pKeyBinds:setKeyBind( name, keyBind )
	return keyBind
end

function createMouseBind(groupName, subGroupName, name, ctrlKey, key)
	local keyBind = KeyBind(groupName, subGroupName, name)
	keyBind:setKeyBindMouse(0, ctrlKey, key)
	pKeyBinds:setKeyBind( name, keyBind )
	return keyBind
end

function create()
	
	pKeyBinds = Core.getGlobalBillboard("keyBind")
	
	createKeyboardBind("BuildHeader", "hotKey", "Building 1", -1, Key.k1);
	createKeyboardBind("BuildHeader", "hotKey", "Building 2", -1, Key.k2);
	createKeyboardBind("BuildHeader", "hotKey", "Building 3", -1, Key.k3);
	createKeyboardBind("BuildHeader", "hotKey", "Building 4", -1, Key.k4);
	createKeyboardBind("BuildHeader", "hotKey", "Building 5", -1, Key.k5);
	createKeyboardBind("BuildHeader", "hotKey", "Building 6", -1, Key.k6);
	createKeyboardBind("BuildHeader", "hotKey", "Building 7", -1, Key.k7);
	createKeyboardBind("BuildHeader", "hotKey", "Building 8", -1, Key.k8);
	createKeyboardBind("BuildHeader", "hotKey", "Building 9", -1, Key.k9);
	createMouseBind("BuildHeader", "placment", "Place", -1, MouseKey.left);
	createMouseBind("BuildHeader", "placment", "Deselect", -1, MouseKey.right);
	createKeyboardBind("BuildHeader", "placment", "Locked rotation", -1, Key.lctrl);
	createKeyboardBind("BuildHeader", "placment", "Sell", -1, Key.delete);
	createKeyboardBind("BuildHeader", "upgrade", "Upgrade", -1, Key.u, Key.y);
	
	createKeyboardBind("Abilities", "hotKey", "BoostAbility", -1, Key.b, Key.n);
	createKeyboardBind("Abilities", "hotKey", "SlowAbility", -1, Key.v);
	createKeyboardBind("Abilities", "hotKey", "AttackAbility", -1, Key.c);
	
	
	createKeyboardBind("NPC input", "controll", "Ignore target", -1, Key.t);
	createKeyboardBind("NPC input", "controll", "High priority", -1, Key.r);
	
	createKeyboardBind("Camera", "group 1", "Speed", -1, Key.f);
	createKeyboardBind("Camera", "group 1", "Forward", -1, Key.w, Key.up);
	createKeyboardBind("Camera", "group 1", "Backward", -1, Key.s, Key.down);
	createKeyboardBind("Camera", "group 1", "Left", -1, Key.a, Key.left);
	createKeyboardBind("Camera", "group 1", "Right", -1, Key.d, Key.right);
	createKeyboardBind("Camera", "group 2", "Rotate left", -1, Key.q);
	createKeyboardBind("Camera", "group 2", "Rotate right", -1, Key.e);
	createKeyboardBind("Camera", "group 3", "Camera raise", -1, Key.pageup);
	createKeyboardBind("Camera", "group 3", "Camera lower", -1, Key.pagedown);
	
	createKeyboardBind("WaveHeader", "Revert wave", "Revert wave", -1, Key.backSpace);

	createKeyboardBind("Multiplayer", "Info screen", "Info screen", -1, Key.tab);



	createKeyboardBind("Map editor", "group 1", "save", Key.lctrl, Key.s);
	createKeyboardBind2("Map editor", "group 1", "save as", Key.lctrl, Key.lshift, Key.s);
	createKeyboardBind("Map editor", "group 1", "load", Key.lctrl, Key.l);
	createKeyboardBind("Map editor", "group 1", "export", Key.lctrl, Key.e);
	createKeyboardBind("Map editor", "group 1", "Change mode", Key.lctrl, Key.space);
	
	
	pOptions = Core.getGlobalBillboard("options");

	pOptions:setBool("Shadow", true);
	pOptions:setBool("Soft shadow", true);
	pOptions:setFloat("Shadow resolution", 1.5);

	pOptions:setBool("Ambient occlusion", true);
	pOptions:setBool("GLow", true);
	pOptions:setBool("Dynamic lights", true);
	pOptions:setBool("Post procesing", true);

	pOptions:setBool("Fullscreen", false);
	pOptions:setVec2("Screen resolution", Vec2(2560.0, 1440.0));

	pOptions:setFloat("Scroll speed", 1.0);

	pOptions:setFloat("Item resolution", 1.0);
	pOptions:setBool("Healt bar", true);
	pOptions:setBool("NPC path", true);
	
	return false
end

function update()
	
	return false
end