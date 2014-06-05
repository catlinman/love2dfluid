#LÖVEFluid#
LÖVEFluid is a real time fluid simulation framework for [LÖVE2D](http://love2d.org/)

## About ##
The fluid system in this repository was originally created for as a self decided school project by [Catlinman](https://github.com/Catlinman). The main idea is to allow easy fluid particle integration in two-dimensional environments for the Love2d framework while still maintaining a steady performance for normal game related processing. The repository is still work in progress meaning that all of the current developments are subject to change.

## Implementation ##

To add the fluid framework to your Love2d project all you have to do is to insert the fluidsystem.lua file into your projects root folder. From there you will have to add `require("fluidsystem")` to the start of your main.lua file. Creating new fluid systems is quite simple. The module allows developers to easily create new systems by calling `fluidsystem.new()`. More information on the parameters of the function will be added soon. As of now, calling the function also returns a reference to the newly created fluid system which you can use to modify it to your liking. 

## Collaborators ##

**[Catlinman](http://catlinman.com/)**

## Licence ##

This repository is released under the MIT license. For more information please refer to [LICENSE.md](https://github.com/Catlinman/LOVEFluid/blob/master/LICENSE.md)
