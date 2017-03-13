# Crumbled-World

This source code is open source under mit-license and can be freely used.
To be able to run the code you have to buy the [Crumbled World](http://store.steampowered.com/app/542910/) or either build your own Lua environment with the same api specified at http://crumbledworld.com/wiki/index.php?title=Lua.

This is the Lua source code used in the Crumbled world game and all commits to this repo will find there way to the live version of the game.

###So what can you do with this?
Almost anything, the lua have access to everything in the game engine, You could even create a first person shooter game if you wanted. Mostly this is will be used by those who want to fix bugs, build new game mods or want to enhance the game in some way.

###IDE?
You can use any IDE you want. We at Clone Corps uses the internal editor from the game. This is a very crude editor supplying you with a basic intelligence of the games API.
On windows the editor can be found side by side of the Crumbled world exe file.
Note on the develop branch we uses the latest version of the game this version can be found on the “Experimental branch” on steam. 
This IDE uses the Crumbled World wiki as it’s intelligence database and to update the intelligence of the editor delete the file “Data/LuaConfig/LuaInteligence.lua” and the latest info from the wiki is downloaded.
