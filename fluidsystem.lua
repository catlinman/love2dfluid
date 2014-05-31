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

-- Currently used to keep particles in the screen area
local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()

local systems = {} -- Table containing the fluid systems
local id = 1 -- Fluid system reference identification

fluidsystem = {} -- Global variable containing the functions used to create and modify the fluid system

-- Calling this function instantiates a new fluid system
function fluidsystem.new()
	local system = {}

	-- This value defaults to 0.981 since the system is intended for sidescrolling games. A value of zero might be useful for top down based games.
	system.gravity = 0.0981
	system.mass = 1
	system.damping = 1 -- How much particles lose velocity when not colliding

	-- Assign the current system id and increment it
	system.id = id
	id = id + 1

	system.particles = {} -- Table containing the fluid particles
	system.particleId = 1 -- Each particle is given an id to track it in the particle table. This value increments as more particles are created.

	system.colliders = {} -- Table containing a set of objects that particles can collide with
	system.affectors = {} -- Table containing objects that affect the flow of particles

	-- Add and remove particles using the following two methods
	function system:addParticle(x, y, vx, vy, color, r, mass)
		local particle = {} -- Create a new particle contained in a table

		-- Assign values that we will use to track certain states of the particle
		particle.x = x or 0
		particle.y = y or 0

		-- Velocity values
		particle.vx = vx or 0
		particle.vy = vy or 0

		-- Table containing particles already collided with this one.
		particle.collided = {}

		-- Color, radius, mass and collider
		particle.color = color or {255, 255, 255, 255} -- Colors: {RED, GREEN, BLUE, ALPHA/OPACITY}
		particle.r = r or 8
		particle.mass = mass or self.mass
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

			-- We save the last position this particle was in before it collided to avoid intersection issues
			local safex = particle.x
			local safey = particle.y

			-- We apply each particles velocity to it's current position
			particle.x = particle.x + particle.vx
			particle.y = particle.y + particle.vy

			-- Perform collision detection and resolution here
			for j, particle2 in pairs(self.particles) do
				-- Make sure we are not checking against an already checked particle
				if particle2 ~= particle and not particle[particle2.id] then
					if fluidsystem.circleCollision(particle, particle2) then
						fluidsystem.circleResolution(particle, particle2)

						-- The particle has collided so we can assume that it's last position was outside of the collision. We reset the position.
						particle.x = safex + particle.vx
						particle.y = safey + particle.vy

						-- Add the particles to the table of already resolutioned particles

					end
				end
			
				-- Check if the particle is out of bounds and resolve the collision
				fluidsystem.screenResolution(particle2)
			end
		end

		-- Clean up particle collision tables
		for i, particle in pairs(self.particles) do
			particle.collided = {}
		end
	end

	-- Method to draw the current state of the fluid simulation
	function system:draw()
		-- love.graphics.setPixelEffect(metaeffect)

		for i, particle in pairs(self.particles) do
			love.graphics.setColor(particle.color)
			love.graphics.circle("fill", particle.x, particle.y, particle.r)
		end

		love.graphics.setColor(255, 255, 255, 255) -- We reset the global color so we don't affect any other game drawing events

		-- love.graphics.setPixelEffect()
	end

	-- Add this new fluid system to the table of all currently instantiated systems
	systems[system.id] = system

	-- Return the system so the user has the option of saving a reference to it if necessary
	return system
end

-- Fuction to update all fluidsystems
function fluidsystem.update(dt)
	for i, system in pairs(systems) do
		system:simulate(dt)
	end
end

-- Function to draw all fluidsystems
function fluidsystem.draw()
	for i, system in pairs(systems) do
		system:draw()
	end
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

-- Fluid system collision handling
function fluidsystem.createBoxCollider(w, h)
	local collider = {}

	collider.w = w or 16
	collider.h = h or 16

	return collider
end

function fluidsystem.createCircleCollider(r)
	local collider = {}

	collider.r = r or 8

	return collider
end

-- Image collider takes in an image to calculate pixel perfect collision
function fluidsystem.createPixelCollider(sx, sy, imagedata)
	local collider = {}

	return collider
end

-- Basic box collision detection (c1/c2 arguments are the two colliders that should be checked for collision)
function fluidsystem.boxCollision(c1, c2)
	-- Convert this and the selected colliders types to those usable by box collision
	local c1w = c1.collider.w or c1.collider.r or 16
	local c1h = c1.collider.h or c1.collider.r or 16

	local c2w = c2.collider.w or c2.collider.r or 16
	local c2h = c2.collider.h or c2.collider.r or 16

	local c1x2, c1y2, c2x2, c2y2 = c1.x + c1w, c1.y + c1h, c2.x + c2w, c2.y + c2h

	-- Returns true if a box collision was detected
	if c1.x < c2x2 and c1x2 > c2.x and c1.y < c2y2 and c1y2 > c2.y then
		return {c1.x, c1x2, c1.y, c1y2, c2.y, c2x2, c2.y, c2y2}
	else
		-- Return the new collision box
		return {}
	end
end

-- Circle collision without the use of math.sqrt
function fluidsystem.circleCollision(c1, c2)
	local c1r = c1.collider.w or c1.collider.r or 8
	local c2r = c2.collider.w or c2.collider.r or 8

	local dist = (c2.x - c1.x)^2 + (c2.y - c1.y)^2

	-- Returns true if a circle collision was detected
	return (dist + (c2r^2 - c1r^2)) < (c1r*2)^2
end

function fluidsystem.pixelCollision(c1, c2)

end

-- Collision resolution functions
function fluidsystem.boxResolution(c1, c2)

end

function fluidsystem.circleResolution(c1, c2)
	local c1r = c1.collider.w or c1.collider.r or 8
	local c2r = c2.collider.w or c2.collider.r or 8

	local collisionPointX = ((c1.x * c2r) + (c2.x * c1r)) / (c1r + c2r)
	local collisionPointY = ((c1.y * c2r) + (c2.y * c1r)) / (c1r + c2r)

	local jointMass = c1.mass + c2.mass
	local differenceMass = c1.mass - c2.mass

	local c1vx = (((c1.vx * differenceMass) + (2 *c2.mass * c2.vx)) / jointMass)
	local c1vy = (((c1.vy * differenceMass) + (2 *c2.mass * c2.vy)) / jointMass)
	local c2vx = (((c2.vx * differenceMass) + (2 *c1.mass * c1.vx)) / jointMass)
	local c2vy = (((c2.vy * differenceMass) + (2 *c1.mass * c1.vy)) / jointMass)

	c1.vx = c1vx
	c1.vy = c1vy
	c2.vx = c2vx
	c2.vy = c2vy

	return collisionPointX, collisionPointY
end

function fluidsystem.pixelResolution(c1, c2)

end

function fluidsystem.screenResolution(c)
	local cw = c.collider.w or c.collider.r or 16
	local ch = c.collider.h or c.collider.r or 16

	if c.y + ch > screenHeight then
		c.y = screenHeight - cw
		c.vy = -(c.vy / 2)
		c.vx = c.vx / 1.005
	elseif c.y - ch < 0 then
		c.y = 0 + ch
		c.vy = -(c.vy / 2)
	end

	if c.x - cw < 0 then
		c.x = 0 + cw
		c.vx = -(c.vx / 2)
	elseif c.x + cw > screenWidth then
		c.x = screenWidth - cw
		c.vx = -(c.vx / 2)
	end
end