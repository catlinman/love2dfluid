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

local drawQuads = true

fluidsystem = {} -- Global variable containing the functions used to create and modify the fluid system

-- Calling this function instantiates a new fluid system
function fluidsystem.new()
	local system = {}

	system.x = 0
	system.y = 0
	system.w = screenWidth
	system.h = screenHeight
	system.gravity = 0.0981 -- This value defaults to 0.0981 since the system is intended for sidescrolling games. A value of zero might be useful for top down based games.
	system.mass = 1 -- Global mass of particles in this system.
	system.damping = 1.0 -- How much particles lose velocity when not colliding. Velocity is divided by this number.
	system.collisionDamping = 1.0 -- How much velocity is divided by when a collision occurs. Useful for particle clumping.
	system.particleFriction = 1.0 -- How much x-velocity is lost when colliding with the top of flat surfaces. Values are multiplied.
	system.quadtree = {} -- Table containing the partitioned quadtrees
	system.quadtreeMaxObjects = 16 -- The amount of objects needed in a cell before it splits
	system.quadtreeMaxRecursion = 5
	system.quadtreeIndex = 1

	if drawQuads == true then
		system.drawQuads = {} -- Table containing all quads to draw for debugging purposes
	end

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

		-- Last position values
		particle.lastx = particle.x
		particle.lasty = particle.y

		-- Table containing particles already collided with this one.
		particle.collided = {}
		particle.collisionTable = {}

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
			self.particles[id] = nil -- Destroy the particle reference
		end
	end

	-- Removes all particles from the fluid system
	function system:removeAllParticles()
		for i, particle in pairs(self.particles) do
			particle = nil
		end
	end

	-- Apply an impulse at the given coordinates using the following method
	function system:applyImpulse(x, y, force)
		for i, particle in pairs(self.particles) do
			local dx, dy = particle.x - x, particle.y - y
			local lenght = math.sqrt((dx * dx) + (dy * dy)) 
			local dist = math.sqrt((x - particle.x)^2 + (y - particle.y)^2)
			local x2, y2 = dx / lenght, dy / lenght
			particle.vx = particle.vx + x2 * force / dist
			particle.vy = particle.vy + y2 * force / dist
		end
	end

	function system:newQuad(x, y, w, h, l, p)
		local quad = {}
		quad.x, quad.y, quad.w, quad.h = x, y, w, h
		quad.particles = {}
		quad.valid = true
		quad.level = l
		quad.parent = p
		quad.collider = fluidsystem.createBoxCollider(quad.w, quad.h)
		quad.id = self.quadtreeIndex

		if drawQuads == true then
			self.quads[self.quadtreeIndex] = quad
		end
	
		self.quadtreeIndex = self.quadtreeIndex + 1
			
		return quad
	end

	-- Divide a quad into four new quads
	function system:splitQuad(quad)
		quad.valid = false
		quad.childQuads = {}
		quad.childQuads[1] = self:newQuad(quad.x, quad.y, quad.w / 2, quad.h / 2, quad.level + 1, quad)
		quad.childQuads[2] = self:newQuad(quad.x + (quad.w / 2), quad.y, quad.w / 2, quad.h / 2, quad.level + 1, quad)
		quad.childQuads[3] = self:newQuad(quad.x, quad.y + (quad.h / 2), quad.w / 2, quad.h / 2, quad.level + 1, quad)
		quad.childQuads[4] = self:newQuad(quad.x + (quad.w / 2), quad.y + (quad.h / 2), quad.w / 2, quad.h / 2, quad.level + 1, quad)

		for i, childQuad in pairs(quad.childQuads) do
			local containing = 0
			for j, particle in pairs(quad.particles) do
				if fluidsystem.boxCollision(childQuad, particle) then
					childQuad.particles[particle.id] = particle
					particle.collider.quads[childQuad.id] = childQuad
					containing = containing + 1
				end
			end
				
			if containing >= self.quadtreeMaxObjects then
				if childQuad.level < self.quadtreeMaxRecursion then
					self:splitQuad(childQuad)
				end
			end
		end

		-- Clear the table of particles
		quad.particles = {}
	end

	-- Function used to generate first time quadtrees. Currently only generates for particles.
	function system:generateQuadtree()
		self.quads = {}

		self.quadtreeIndex = 1

		self.quadtree = self:newQuad(self.x, self.y, self.w, self.h, 1)
		self.quadtree.particles = self.particles

		if #self.particles > self.quadtreeMaxObjects then
			for i, particle in pairs(self.particles) do
				particle.collider.quads = {}
			end

			self:splitQuad(self.quadtree)
		else
			for i, particle in pairs(self.particles) do
				self.quadtree.particles[particle.id] = particle
				particle.collider.quads[self.quadtree.id] = self.quadtree
			end
		end
	end

	-- Used to revalidate a colliders quad if it moved out of it during the last frame
	function system:validateQuadtreeCollider(c)
		for i, quad in pairs(self.quads) do
			if quad.valid then
				if fluidsystem.boxCollision(quad, c) then
					c.collider.quads[quad.id] = quad
				end
			end
		end
	end

	-- Method to simulate a frame of the simulation. This is where the real deal takes place.
	function system:simulate(dt)
		self:generateQuadtree()

		for i, particle in pairs(self.particles) do
			-- Make sure the particle does not leave the fluidsystem
			fluidsystem.screenResolution(particle, self.particleFriction, self.x, self.y, self.w, self.h)

			-- Add the system's gravity to the particles velocity
			particle.vy = particle.vy + self.gravity

			-- Damp the velocity. Good for when top down simulations are needed.
			particle.vx = particle.vx / self.damping
			particle.vy = particle.vy / self.damping

			-- We apply each particles velocity to it's current position
			particle.x = particle.x + particle.vx
			particle.y = particle.y + particle.vy

			local collided = false

			particle.collisionTable = {}

			self:validateQuadtreeCollider(particle)

			-- Perform collision detection and resolution here
			for j, quad in pairs(particle.collider.quads) do
				for k, particle2 in pairs(quad.particles) do
					-- Make sure we are not checking against an already checked particle
					if particle2 ~= particle and not particle.collisionTable[particle2.id] then
						if fluidsystem.circleCollision(particle, particle2) then
							fluidsystem.circleResolution(particle, particle2, self.collisionDamping)
							
							particle.collisionTable[particle2.id] = true
							particle2.collisionTable[particle.id] = true
							collided = true
						end
					end
				end
			end

			if not collided then
				-- We save the last position this particle was in before it collided to avoid intersection issues
				particle.lastx = particle.x - particle.vx
				particle.lasty = particle.y - particle.vy
			else
				particle.x = particle.lastx 
				particle.y = particle.lasty
			end
		end

		for i, particle in pairs(self.particles) do
			particle.collisionTable = {}
		end
	end

	-- Method to draw the current state of the fluid simulation
	function system:draw()
		-- love.graphics.setPixelEffect(metaeffect)

		for i, particle in pairs(self.particles) do
			love.graphics.setColor(particle.color)
			love.graphics.circle("fill", particle.x, particle.y, particle.r)
			--love.graphics.rectangle("line", particle.x - particle.r + particle.collider.ox, particle.y - particle.r + particle.collider.oy, particle.r * 2, particle.r * 2)
		end

		if drawQuads == true then
			for i, quad in pairs(self.quads) do
				love.graphics.rectangle("line", quad.x, quad.y, quad.w, quad.h)	
			end
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

-- COLLIDER CREATION FUNCTIONS

--[[
	Collider data structure:
	x and y are handled from the object the collider is a parent of.
	The parent of the collider is passed to the collsion functions. NOT THE COLLIDER.
	
	->	Collision detection will fail if there is no x and y variable attached to the parent.
	->	Collision detection will fail if there mass variable attached to the parent.
	
	Every collider has either a 'w,h' and or a 'r' variable.
	If it doesn't have one of these each function will generate one of the fly.

	Colliders also have 'ox' and 'oy' members. These represent the collider's offset in terms of
	the x- and y-coordinates in relation to the parents position.

	-> Collision detection will fail if there are no ox and oy members in the collider table.

	Note:
		To resolve collisions without the use of TOI at the moment it is suggested to save the collider's
		position before the collision and to restore it after the collision. Take a look at the particle code above
		for further reference.
--]]

function fluidsystem.createBoxCollider(w, h, ox, oy)
	local collider = {}

	collider.collisionType = "box"
	collider.w = w or 16
	collider.h = h or 16
	collider.ox, collider.oy = ox or 0, oy or 0
	collider.quads = {}

	return collider
end

function fluidsystem.createCircleCollider(r, ox, oy)
	local collider = {}

	collider.collisionType = "circle"
	collider.r = r or 8
	collider.ox, collider.oy = ox or 0, oy or 0
	collider.quads = {}

	return collider
end

-- Image collider takes in an image to calculate pixel perfect collision
function fluidsystem.createPixelCollider(sx, sy, imagedata, ox, oy)
	local collider = {}

	collider.collisionType = "pixel"
	collider.ox, collider.oy = ox or 0, oy or 0
	collider.quads = {}

	return collider
end

-- COLLISION DETECTION FUNCTIONS
-- Basic box collision detection (c1/c2 arguments are the two colliders that should be checked for collision)
function fluidsystem.boxCollision(c1, c2)
	local r1offset = c1.collider.r or 0
	local r2offset = c2.collider.r or 0

	-- Convert this and the selected colliders types to those usable by box collision
	local c1w = c1.collider.w or c1.collider.r * 2 or 16
	local c1h = c1.collider.h or c1.collider.r * 2 or 16

	local c2w = c2.collider.w or c2.collider.r * 2 or 16
	local c2h = c2.collider.h or c2.collider.r * 2 or 16

	local c1x2, c1y2, c2x2, c2y2 = c1.x + c1w, c1.y + c1h, c2.x + c2w, c2.y + c2h

	-- Returns true if a box collision was detected
	if c1.x - r1offset < c2x2 - r2offset and c1x2 - r1offset > c2.x - r2offset and c1.y - r1offset < c2y2 - r2offset and c1y2 - r1offset > c2.y - r2offset then
		return {c1.x, c1x2, c1.y, c1y2, c2.y, c2x2, c2.y, c2y2}
	end

	return false
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

-- COLLISION RESOLUTION FUNCTIONS
function fluidsystem.boxResolution(c1, c2, f, d)
	-- Offset calculation. Often used if the origins need to be repositioned.
	-- Circles automatically receive offset calculations since their origins are at their center.
	local c1radiusOffset = c1.collider.r or 0
	local c2radiusOffset = c2.collider.r or 0

	local frictionForce = f or 1
	local damping = d or 1

	local c1w = c1.collider.w or c1.collider.r * 2 or 16
	local c1h = c1.collider.h or c1.collider.r * 2 or 16
	local c2w = c2.collider.w or c2.collider.r * 2 or 16
	local c2h = c2.collider.h or c2.collider.r * 2 or 16

	local jointMass = c1.mass + c2.mass
	local differenceMass = c1.mass - c2.mass

	local c1vx = (((c1.vx * differenceMass) + (2 * c2.mass * c2.vx)) / jointMass)
	local c1vy = (((c1.vy * differenceMass) + (2 * c2.mass * c2.vy)) / jointMass)
	local c2vx = (((c2.vx * differenceMass) + (2 * c1.mass * c1.vx)) / jointMass)
	local c2vy = (((c2.vy * differenceMass) + (2 * c1.mass * c1.vy)) / jointMass)

	-- Check if the box could possibly have hit one of the sides.
	-- These are overwritten if the last position method is used.
	if c1.x - c1.vx + c1w > c2.x and c1.x - c1.vx < c2.x + c2w then
		if c1.y - c1.vy + c1h < c2.y and c1.vy > 0 then
			c1.y = c2.y - c1h
			c1.vx = c1.vx * frictionForce
		elseif c1.y - c1.vy > c2.y + c2h and c1.vy < 0 then
			c1.y = c2.y + c2h
		end
	elseif c1.y - c1.vy + c1h > c2.y and c1.y - c1.vy < c2.y + c2h then
		if c1.x - c1.vx + c1w < c2.x and c1.vx > 0 then
			c1.x = c2.x - c1w
		elseif c1.x - c1.vx > c2.x + c2w and c1.vx < 0 then
			c1.x = c2.x + c2w
		end
	end

	c1.vx = c1vx / damping
	c1.vy = c1vy / damping
	c2.vx = c2vx / damping
	c2.vy = c2vy / damping

	c1.x = c1.x + c1.vx
    c1.y = c1.y + c1.vy
    c2.x = c2.x + c2.vx
    c2.y = c2.y + c2.vy
end

function fluidsystem.innerBoxResolution(c1, c2, f, d)
	local c1radiusOffset = c1.collider.r or 0
	local c2radiusOffset = c2.collider.r or 0

	local frictionForce = f or 1

	local c1w = c1.collider.w or c1.collider.r * 2 or 16
	local c1h = c1.collider.h or c1.collider.r * 2 or 16
	local c2w = c2.collider.w or c2.collider.r * 2 or 16
	local c2h = c2.collider.h or c2.collider.r * 2 or 16

	if c1.x + cw - c1radiusOffset > c2.x + c2w then
		c1.x = c2.x + c2w - c1w + c1radiusOffset
		c1.vx = -(c1.vx / 2)

	elseif c1.x - c1radiusOffset < c2.x then
		c1.x = c2.x + c1radiusOffset
		c1.vx = -(c1.vx / 2)
	end

	if c1.y + c1h - c1radiusOffset > c2.y + c2h then
		c1.y = c2.y + c2h - c1h + c1radiusOffset
		c1.vy = -(c1.vy / 2)

		-- We are colliding from the top. Add friction.
		c1.vx = c1.vx * frictionForce

	elseif c1.y - c1radiusOffset < c2.y then
		c1.y = c2.y + c1radiusOffset
		c1.vy = -(c1.vy / 2)
	end
end

-- TODO: Add offset handling
function fluidsystem.circleResolution(c1, c2, d)
	local damping = d or 1

	local c1r = c1.collider.w or c1.collider.r or 8
	local c2r = c2.collider.w or c2.collider.r or 8

	local collisionPointX = ((c1.x * c2r) + (c2.x * c1r)) / (c1r + c2r)
	local collisionPointY = ((c1.y * c2r) + (c2.y * c1r)) / (c1r + c2r)

	local nx = (c1.x - c2.x) / (c1r + c2r) 
    local ny = (c1.y - c2.y) / (c1r + c2r) 
    local a1 = c1.vx * nx + c1.vy * ny 
    local a2 = c2.vx * nx + c2.vy * ny 
    local p = 2 * (a1 - a2) / (c1.mass + c2.mass) 

    c1.vx = (c1.vx - p * nx * c2.mass) / damping
    c1.vy = (c1.vy - p * ny * c2.mass) / damping
    c2.vx = (c2.vx + p * nx * c1.mass) / damping
    c2.vy = (c2.vy + p * ny * c1.mass) / damping

    -- These are overwritten if the last position method is used.
    c1.x = c1.x + c1.vx
    c1.y = c1.y + c1.vy
    c2.x = c2.x + c2.vx
    c2.y = c2.y + c2.vy

    return collisionPointX, collisionPointY
end

function fluidsystem.pixelResolution(c1, c2)

end

-- Screen collision resolution is based on box collision.
function fluidsystem.screenResolution(c, f, x, y, w, h)
	-- Offset calculation. Often used if the origins need to be repositioned.
	-- Circles automatically receive offset calculations since their origins are at their center.
	local offsetx = c.collider.ox or 0
	local offsety = c.collider.oy or 0

	local radiusOffset = c.collider.r or 0

	local frictionForce = f or 1

	local cw = c.collider.w or c.collider.r * 2 or 16
	local ch = c.collider.h or c.collider.r * 2 or 16

	local sx = x or 0
	local sy = y or 0
	local sw = w or screenWidth or 0
	local sh = h or screenHeight or 0

	if (c.x + offsetx) + cw - radiusOffset > sx + sw then
		c.x = sx + sw - cw - offsetx + radiusOffset
		c.vx = -(c.vx / 2)

	elseif (c.x + offsetx) - radiusOffset < sx + offsetx then
		c.x = sx + offsetx + radiusOffset
		c.vx = -(c.vx / 2)
	end

	if (c.y + offsety) + ch - radiusOffset > sy + sh then
		c.y = sy + sh - ch - offsety + radiusOffset
		c.vy = -(c.vy / 2)

		-- We are colliding from the top. Add friction.
		c.vx = c.vx * frictionForce

	elseif (c.y + offsety) - radiusOffset < sy + offsety then
		c.y = sy + offsety + radiusOffset
		c.vy = -(c.vy / 2)
	end
end	