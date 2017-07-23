require("Menu/MainMenu/mainMenuStyle.lua")
require("Menu/MainMenu/inputPanel.lua")
require("Menu/MainMenu/videoPanel.lua")
require("Menu/MainMenu/audioPanel.lua")
--this = SceneNode()

CreditsMenu = {}

function CreditsMenu.create(panel)
	--Options panel
	local creditsPanel = panel:add(Panel(PanelSize(Vec2(-1))))
	creditsPanel:setLayout(FlowLayout(Alignment.TOP_CENTER))
	--Top menu titel
	creditsPanel:add(Label(PanelSize(Vec2(-1,0.04)), "Credits", Vec3(0.94), Alignment.MIDDLE_CENTER))
	
	--Add BreakLine
	local breakLinePanel = creditsPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
	breakLinePanel:setBackground(Sprite(Vec3(0.45)))
	

	CreditsMenu.createPage(creditsPanel)
	
	creditsPanel:setVisible(false)
	return creditsPanel
end



function CreditsMenu.createPage(creditPanel)
	
	local mainArea = creditPanel:add(Panel(PanelSize(Vec2(1,-1),PanelSizeType.ParentPercent)))
	mainArea:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
	
	
	local panelArea = mainArea:add(Panel(PanelSize(Vec2(-0.85,-0.95))))
	panelArea:setPadding(BorderSize(Vec4(0.005,0,0.005,0),true))
	panelArea:setEnableYScroll()
	panelArea:setBackground(Sprite(Vec4(0,0,0,0.6)))
	panelArea:setBorder(Border(BorderSize(Vec4(MainMenuStyle.borderSize)),MainMenuStyle.borderColor))
	panelArea:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
	
--	local panelArea = panel:add(Panel(PanelSize(Vec2(-1,-1))))
--	panelArea:setLayout(FlowLayout(Alignment.MIDDLE_CENTER))
--	panelArea:setEnableYScroll()
	
	CreditsMenu.creditsPanel = panelArea
	
	panelArea:add(Label(PanelSize(Vec2(-1, 0.025)),"Music", Vec3(0.94)))
	CreditsMenu.addBreakLine()
	
	--Music by Eric Matyas
	local MusicByEricmatyasString = {"\"Ancient Troops\"",
	"\"Forward Assault\"",
	"\"Ocean Floor\"",
	"\"Tower Defense\"",
	"By Eric Matyas",
	"www.soundImage.org",
	""}
	
	local VirtutesInstrumentiString = {"\"Virtutes Instrumenti\"",
	"License Creative Commons Attribution 3.0 Unported license",
	"https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100801",
	""}
	
	CreditsMenu.addLicense(MusicByEricmatyasString)
	CreditsMenu.addLicense(VirtutesInstrumentiString)
	
	CreditsMenu.addBreakLine()
	
	panelArea:add(Label(PanelSize(Vec2(-1, 0.025)), "This application uses Open Source components. ", Vec3(0.94), Alignment.MIDDLE_LEFT ))
	panelArea:add(Label(PanelSize(Vec2(-1, 0.025)), "You can find the source code of their open source projects along with license information below. ", Vec3(0.94), Alignment.MIDDLE_LEFT ))
	panelArea:add(Label(PanelSize(Vec2(-1, 0.025)), "We acknowledge and are grateful to these developers for their contributions to open source.", Vec3(0.94), Alignment.MIDDLE_LEFT ))
	
	CreditsMenu.addBreakLine()
		
	--Bullet physic
	local bulletString = {"Project: Bullet Collision Detection and Physics Library",
	"Copyright (c) 2012 Advanced Micro Devices, Inc. http://bulletphysics.org",
	"License (zlib) https://opensource.org/licenses/zlib-license.php"}
	  
	--SDL
	local SDLString = {"Project: Simple DirectMedia Layer, https://www.libsdl.org ",
	"Copyright (C) 1997-2014 Sam Lantinga <slouken@libsdl.org>",
	"License (zlib) http://www.zlib.net/zlib_license.html"}
	
	--Lua
	local LuaString = {"Project: LuaJit, http://luajit.org/",
	"Copyright (C) 2005-2016 Mike Pall, released under the MIT open source license.", 
	"License (MIT) https://opensource.org/licenses/mit-license.php"}
	
	--Luabind
	local LuaBindString = {"Project: Luabind, http://www.rasterbar.com/products/luabind.html",
	"Copyright (c) 2003 Daniel Wallin and Arvid Norberg",
	"License (MIT) https://github.com/luabind/luabind/blob/master/LICENSE"}
	
	--FreeImage
	local FreeImageString = {"This software uses the FreeImage open source image library.",
	"See http://freeimage.sourceforge.net for details.",
	"FreeImage is used under the FIPL, version 1.0."}
	
	--FreeType
	local FreeTypeString = {"Portions of this software are copyright 2015 The FreeType.",
	"Project (www.freetype.org).  All rights reserved."}
	
	--Curl
	local curlString = {"Project: Curl, https://curl.haxx.se",
	"Copyright (c) 1996 - 2016, Daniel Stenberg, daniel@haxx.se, and many contributors, see ",
	"\t\tthe THANKS file.",
	"License (MIT/X derivate license) https://curl.haxx.se/docs/copyright.html",
	"",
	"",
	""}
	
	CreditsMenu.addLicense(bulletString)
	CreditsMenu.addLicense(SDLString)
	CreditsMenu.addLicense(LuaString)
	CreditsMenu.addLicense(LuaBindString)
	CreditsMenu.addLicense(FreeImageString)
	CreditsMenu.addLicense(FreeTypeString)
	CreditsMenu.addLicense(curlString)
	

end

function CreditsMenu.addBreakLine()

	local breakLinePanel = CreditsMenu.creditsPanel:add(Panel(PanelSize(Vec2(-0.9,0.002))))
	breakLinePanel:setBackground(Sprite(Vec3(0.45)))
	CreditsMenu.creditsPanel:add(Panel(PanelSize(Vec2(-1, 0.025))))
end

function CreditsMenu.addLicense(licenseTable)
	CreditsMenu.creditsPanel:add(Panel(PanelSize(Vec2(-1, 0.025))))
	for i=1, #licenseTable do
		CreditsMenu.creditsPanel:add(Label(PanelSize(Vec2(-1, 0.025)), licenseTable[i], Vec3(0.94), Alignment.MIDDLE_LEFT ))
	end
end