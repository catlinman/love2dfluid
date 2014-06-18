
## Passing parameters ##
To pass parameters to the fluid system to make use of you will have to create a new table. Within this table you will have to include all desired variables which can be seen below. It should be taken into account that these have to be named properly for the system to make use of them. The system will otherwise ignore these values and simply default to the predefined ones included in the `fluidsystem.new()` function.

## Table of parameters ##

<table>
  <tr align="center">
	<td><b>Variable
	<td><b>Type
	<td><b>Description
	<td><b>Default value
  </tr>
  <tr align="center">
	<td>x
	<td>Number
	<td>x-position of the fluid system
	<td>0
  </tr>
  <tr align="center">
	<td>y
	<td>Number
	<td>y-position of the fluid system
	<td>0
  </tr>
  <tr align="center">
	<td>w
	<td>Number
	<td>Width of the fluid system
	<td>love.graphics.getWidth()
  </tr>
  <tr align="center">
	<td>h
	<td>Number
	<td>Height of the fluid system
	<td>love.graphics.getHeight()
  </tr>
  <tr align="center">
	<td>c / color
	<td>Table
	<td>Color of particles (RGBA)
	<td>{255, 255, 255, 255}
  </tr>
  <tr align="center">
	<td>g / gravity
	<td>Number
	<td>Global fluid system gravity
	<td>0.0981
  </tr>
  <tr align="center">
	<td>m / mass
	<td>Number
	<td>Particle mass
	<td>1.0
  </tr>
  <tr align="center">
	<td>d / damping
	<td>Number
	<td>Particle movement dampening
	<td>1.0
  </tr>
  <tr align="center">
	<td>cd / collisiondamping
	<td>Number
	<td>Loss of particle velocity on collision
	<td>1.1
  </tr>
  <tr align="center">
	<td>fr / friction
	<td>Number
	<td>Ground friction
	<td>1.0
  </tr>
  <tr align="center">
	<td>r / radius
	<td>Number
	<td>Particle radius
	<td>10.0
  </tr>
  <tr align="center">
	<td>drawshader
	<td>Boolean
	<td>If the shader should be applied
	<td>true
  </tr>
  <tr align="center">
	<td>drawquads
	<td>Boolean
	<td>If quads should be drawn
	<td>false
  </tr>
  <tr align="center">
	<td>drawaffectors
	<td>Boolean
	<td>If affectors should be drawn
	<td>false
  </tr>
</table>

## Setup and passing of the parameter table ##

Creating the parameter table is rather simple. It can either be stored in a separate variable or immediately supplied to the `fluidsystem.new(parameters)` function. An example implementation can be seen below.

	
	local parameters = {
		radius = 16,
		color = {125, 125, 255, 255},
	}
	
	local fluid = fluidsystem.new(parameters)

	-- OR --

	local parameters = {}
	parameters.radius = 16
	parameters.color = {125, 125, 255, 255}

	local fluid = fluidsystem.new(parameters)

	-- OR --

	local fluid = fluidsystem.new({
		radius = 16,
		color = {125, 125, 255, 255},
	})

Either way passing parameters and supplying them to the system is as easy as any other task in Lua.