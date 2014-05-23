--[[

	LOVEFluid was created by Catlinman and can be forked on GitHub

	-> https://github.com/Catlinman/LOVE2D-FluidSystem

	This file contains the needed code to use and incorporate real time fluid dynamics for your 2D sidescroller. The
	system itself is still work in progress which means that improvements and additional functionality is still to come.

	Feel free to modify the file to your liking as long as I am credited for the original work. For more information please
	refer to the following link:

	-> https://github.com/Catlinman/LOVE2D-FluidSystem/blob/master/LICENSE.md
	
	I have attempted to comment most of the code to allow those not familiar with LOVE to jump faster into modifying the code.
	To remove all comments simply use a program like Sublime Text 2 and replace everything with whitespace using the following regex lines:

	--"[^\[\]"]*?$

	I have added quotation marks to the previous line to avoid the breaking of this comment block. You will need to remove those to parse the regex.

--]]

--[[
	These variables are local and only bound to the scope of this file.
	Use the fluid.get() function to return a reference to one of the currently loaded fluid systems.
-]]

local systems = {} -- Table containing the fluid systems
local id = 1 -- Fluid system reference identification

fluidsystem = {} -- Global variable containing the functions used to create and modify the fluid system

-- Calling this function instantiates a new fluid system
function fluidsystem.new()
	local system = {}

	-- This value defaults to 9.81 since the system is intended for sidescrolling games. A value of zero might be useful for top down based games.
	system.gravity = 9.81

	system.damping = 1 -- How much particles lose velocity when not colliding

	-- Assign the current system id and increment it
	system.id = id
	id = id + 1

	system.particles = {} -- Table containing the fluid particles
	system.particleId = 1 -- Each particle is given an id to track it in the particle table. This value increments as more particles are created.

	system.colliders = {} -- Table containing a set of objects that particles can collide with
	system.affectors = {} -- Table containing objects that affect the flow of particles

	-- Add and remove particles using the following two methods
	function system:addParticle(x, y, vx, vy, color, size)
		local particle = {} -- Create a new particle contained in a table

		-- Assign values that we will use to track certain states of the particle
		particle.x = x or 0
		particle.y = y or 0

		-- Velocity values
		particle.vx = vx or 0
		particle.vy = vy or 0

		-- Color and size
		particle.color = color or {255, 255, 255, 255} -- Colors: {RED, GREEN, BLUE, ALPHA/OPACITY}

		particle.id = self.particleId
		self.particleId = self.particleId + 1

		-- Add the particle to this system's particle table
		self.particles[particle.id] = particle

		return particle
	end

	function system:removeParticle(id)
		-- Lookup the particle by it's id in the particle table
		if self.particles[id] then
			self.particles[id] = nil -- Destory the particle reference
		end
	end

	-- Removes all particles from the fluid system
	function system:removeAllParticles()
		for i, particle in pairs(self.particles) do
			particle = nil
		end
	end

	-- Apply an impulse at the given coordinates using the following method
	function system:applyImpulse(x, y, strength)

	end

	-- Method to simulate a frame of the simulation. This is where the real deal takes place.
	function system:simulate(dt)

	end

	-- Method to draw the current state of the fluid simulation
	function system:draw()
		for i, particle in pairs(self.particles) do
			love.graphics.setColor(particle.color)
			love.graphics.circle("fill", particle.x, particle.y, particle.size, 8)
		end

		love.graphics.setColor(255, 255, 255, 255) -- We reset the global color so we don't affect any other game drawing events
	end

	-- Add this new fluid system to the table of all currently instantiated systems
	systems[system.id] = system

	-- Return the system so the user has the option of saving a reference to it if necessary
	return system
end

-- Get a fluid system by it's id or name from the systems table
function fluidsystem.get(id)
	if systems[id] then
		return systems[id]
	end
end

-- Destroy an entire fluid system by it's id or name from the systems table
function fluidsystem.destroy()
	if systems[id] then
		systems[id].removeAllParticles()

		systems[id] = nil
	end
end