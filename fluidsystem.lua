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

	-- This value defaults to 0.981 since the system is intended for sidescrolling games. A value of zero might be useful for top down based games.
	system.gravity = 0.981

	system.damping = 1 -- How much particles lose velocity when not colliding

	-- Assign the current system id and increment it
	system.id = id
	id = id + 1

	system.particles = {} -- Table containing the fluid particles
	system.particleId = 1 -- Each particle is given an id to track it in the particle table. This value increments as more particles are created.

	system.colliders = {} -- Table containing a set of objects that particles can collide with
	system.affectors = {} -- Table containing objects that affect the flow of particles

	-- Add and remove particles using the following two methods
	function system:addParticle(x, y, vx, vy, color, r)
		local particle = {} -- Create a new particle contained in a table

		-- Assign values that we will use to track certain states of the particle
		particle.x = x or 0
		particle.y = y or 0

		-- Velocity values
		particle.vx = vx or 0
		particle.vy = vy or 0

		-- Color, radius and collider
		particle.color = color or {255, 255, 255, 255} -- Colors: {RED, GREEN, BLUE, ALPHA/OPACITY}
		particle.r = r or 1
		particle.collider = fluidsystem.createCircleCollider(particle.r)

		-- Id assignment
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
		for i, particle in pairs(self.particles) do
			-- Add the system's gravity to the particles velocity
			particle.vy = particle.vy + self.gravity

			-- We apply each particles velocity to it's current position
			particle.x = particle.x + particle.vx
			particle.y = particle.y + particle.vy

			-- Check if the particle is out of bounds and resolve the collision
			if particle.y + particle.r > 768 then
				particle.y = 768 - particle.r
				particle.vy = -particle.vy / 2
			end

			-- Perform collision detection and resolution here
			for j, particle2 in pairs(self.particles) do
				-- Make sure we are not checking against an already checked particle
				if particle2 ~= particle then
					if particle.collider:circleCollision(particle2.collider) then print("Detected collision") end
				end
			end
		end
	end

	-- Method to draw the current state of the fluid simulation
	function system:draw()
		for i, particle in pairs(self.particles) do
			love.graphics.setColor(particle.color)
			love.graphics.circle("fill", particle.x, particle.y, particle.r, 16)
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

-- Fluid system collider classes. The fluid system takes in any of these and uses them to interact with the particle system.

-- Base collider class - only contains functions used to handle conversion between collider types.
function fluidsystem.createBaseCollider(x, y)
	local collider = {}

	collider.x = x or 0
	collider.y = y or 0

	-- The 'c' argument is the collider that this one is to check for collision against

	-- Basic box collision detection
	function collider:boxCollision(c)
		-- Convert this and the selected colliders types to those usable by box collision
		local w = self.w or self.r or 16
		local h = self.h or self.r or 16

		local w2 = c.w or c.r or 16
		local h2 = c.h or c.r or 16

		local x2, y2, cx2, cy2 = self.x + w, self.y + h, c.x + w2, c.y + h2

		-- Returns true if a box collision was detected
		return self.x < cx2 and x2 > c.x and self.y < cy2 and y2 > c.y
	end

	-- Circle collision without the use of math.sqrt
	function collider:circleCollision(c)
		local r = self.w or self.r or 8
		local r2 = c.w or c.r or 8

		local dist = (c.x - self.x)^2 + (c.y - self.y)^2

		-- Returns true if a circle collision was detected
		return (dist + r2^2) < r^2
	end

	function collider:pixelCollision(c)
		-- Still needs code
	end

	return collider
end

-- The most basic collider type. Simple box intersection collider.
function fluidsystem.createBoxCollider(x, y, w, h)
	local collider = fluidsystem.createBaseCollider(x, y)

	collider.w = w or 16
	collider.h = h or 16

	return collider
end

-- Circle collider uses radius based calculation to detect and resolve collision
function fluidsystem.createCircleCollider(x, y, r)
	local collider = fluidsystem.createBaseCollider(x, y)

	collider.r = r or 8

	return collider
end

-- Image collider takes in an image to calculate pixel perfect collision
function fluidsystem.createImageCollider(x, y, sx, sy, imagedata)
	local collider = fluidsystem.createBaseCollider(x, y)

	return collider
end