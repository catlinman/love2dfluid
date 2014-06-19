#LÖVEFluid#
LÖVEFluid is a real time fluid simulation framework for [LÖVE2D](http://love2d.org/)

## About ##
The fluid system in this repository was originally created for as a self decided school project by [Catlinman](https://github.com/Catlinman). The main idea is to allow easy fluid particle integration in two-dimensional environments for the Love2d framework while still maintaining a steady performance for normal game related processing. The repository is still work in progress meaning that all of the current developments are subject to change.

## Implementation ##

To add the fluid framework to your Love2d project all you have to do is to insert the fluidsystem.lua file into your love-project's root folder. From there you will have to add `require("fluidsystem")` to the start of your main.lua file. Creating new fluid systems is quite simple. The module allows developers to easily create new systems by calling `fluidsystem.new(parameters)`. The function takes in a table containing named variables which will be assigned to the newly created system. The system is then returned as a reference and can then be directly manipulated. There are also a set of other functions that can be used to more closely manage the entire fluid system. For more information on these please refer to [FUNCTIONS.md](https://github.com/Catlinman/LOVEFluid/blob/master/FUNCTIONS.md). For a list of  variables that can be passed when creating a new system have a look at [PARAMETERS.md](https://github.com/Catlinman/LOVEFluid/blob/master/PARAMETERS.md).

## Collaborators ##

**[Catlinman](http://catlinman.com/)**

## Licence ##

This repository is released under the MIT license. For more information please refer to [LICENSE.md](https://github.com/Catlinman/LOVEFluid/blob/master/LICENSE.md)
