# LÖVE 2D Fluid #

love2dfluid is a real time fluid simulation framework for [LÖVE2D](http://love2d.org/)

![Screenshot](https://private-user-images.githubusercontent.com/1859270/293908453-93ef4ae9-e966-4718-ab37-f4696083b7d8.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MDQyODM4NTEsIm5iZiI6MTcwNDI4MzU1MSwicGF0aCI6Ii8xODU5MjcwLzI5MzkwODQ1My05M2VmNGFlOS1lOTY2LTQ3MTgtYWIzNy1mNDY5NjA4M2I3ZDgucG5nP1gtQW16LUFsZ29yaXRobT1BV1M0LUhNQUMtU0hBMjU2JlgtQW16LUNyZWRlbnRpYWw9QUtJQVZDT0RZTFNBNTNQUUs0WkElMkYyMDI0MDEwMyUyRnVzLWVhc3QtMSUyRnMzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LURhdGU9MjAyNDAxMDNUMTIwNTUxWiZYLUFtei1FeHBpcmVzPTMwMCZYLUFtei1TaWduYXR1cmU9MmU1MGU4ZTZkYjNjMDhhMzkyMTE5ZmJiNDk3YTdhMzQ0NzNkOTlmODc0ZTZmNWI2YTk2MGEzZmU1NjI1YTU3YSZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QmYWN0b3JfaWQ9MCZrZXlfaWQ9MCZyZXBvX2lkPTAifQ.wlrhE1-qFPJct--MJDkaZ3zUH9L7cIpJQg9r3gVKbPo)

## About ##

The fluid system in this repository was originally created as a self decided school project. The main idea is to allow easy fluid particle integration in two-dimensional environments for the LÖVE2D framework while still maintaining a steady performance for normal game related processing. The repository is still work in progress meaning that all of the current developments are subject to change.

## Implementation ##

To add the fluid framework to your LÖVE2D project all you have to do is to insert the `fluidsystem.lua` file into your love-project's root folder. From there you will have to add `require("fluidsystem")` to the start of your main.lua file. Creating new fluid systems is quite simple. The module allows developers to easily create new systems by calling `fluidsystem.new(parameters)`. The function takes in a table containing named variables which will be assigned to the newly created system. The system is then returned as a reference and can then be directly manipulated. There are also a set of other functions that can be used to more closely manage the entire fluid system.

For more information on these please refer to [FUNCTIONS.md](https://github.com/catlinman/lovefluid/blob/master/FUNCTIONS.md). For a list of  variables that can be passed when creating a new system have a look at [PARAMETERS.md](https://github.com/catlinman/lovefluid/blob/master/PARAMETERS.md).

## License ##

This repository is released under the MIT license. For more information please refer to [LICENSE](https://github.com/catlinman/lovefluid/blob/master/LICENSE)
