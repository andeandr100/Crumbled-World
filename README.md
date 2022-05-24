# Crumbled-World Lua code

This source code is open source under mit-license and can be freely used.
To be able to run the code you have to buy the [Crumbled World](http://store.steampowered.com/app/542910/) or either build your own Lua environment with the same api specified at https://wiki.crumbledworld.com/index.php?title=Lua.

## Why open source?
There is no need to keep this code under lock and key. With access to this code anyone can develop and update the game and creating new maps or mods.

## So what can you do with this?
Almost anything, the lua have access to the game engine, You could even create a first person shooter game if you wanted. This repo is for users who want to create new game mods, map editor tools, update game or add new features for the game. 
If you only want to create a custom map you can do that local on your computer and the source code is distributed with the map. But if you want to share your game code you can add your code to a subfolder under the Custom folder. 

## How to use
Release branch is the code used by the latest version of the Crumbled world.
Develop branch is the develop branch and is not connected to the experimental version of Crumbled world.
When developing place this code under the Custom Lua folder this folder is not reseted when a new release on the steam happens.

## Develop tools
You can use any IDE you want. We at Clone Corps uses the internal editor from the game. This is a very crude editor supplying you with a basic intelligence of the games API.
On windows the editor can be found side by side of the Crumbled world exe file.
Note on the develop branch we uses the latest version of the game this version can be found on the “Experimental branch” on steam. 
This IDE uses the Crumbled World [wiki](http://crumbledworld.com/wiki/index.php?title=Lua) as it’s intelligence database and to update the intelligence of the editor delete the file “Data/LuaConfig/LuaInteligence.lua” and the latest info from the wiki is downloaded.


