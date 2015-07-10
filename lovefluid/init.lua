
--[[

	LOVEFluid was created by Catlinman and can be forked on GitHub

	-> https://github.com/catlinman/lovefluid

	This file contains the needed code to use and incorporate real time fluid dynamics for your 2D sidescroller. The
	system itself is still work in progress which means that improvements and additional functionality is still to come.

	Feel free to modify the file to your liking as long as I am credited for the original work. For more information please
	refer to the following link:

	-> https://github.com/catlinman/lovefluid/blob/master/LICENSE
	
	I have attempted to comment most of the code to allow those not familiar with LOVE to jump faster into modifying the code.
	To remove all comments simply use a program like Sublime Text 2 and replace everything with whitespace using the following regex line:

	--"[^\[\]"]*?$

	I have added quotation marks to the previous line to avoid the breaking of this comment block. You will need to remove those to parse the regex.

--]]

--[[
	These variables are local and only bound to the scope of this file.
	Use the fluid.get() function to return a reference to one of the currently loaded fluid systems.
--]]

local systems = {} -- Table containing the fluid systems
local id = 1 -- Fluid system reference identification

local fluidsystem = {} -- Variable containing the functions used to create and modify the fluid system

-- Calling this function instantiates a new fluid system. The Arugment is a table containing all the information needed for the particlesystem.
function fluidsystem.new(parameters)
	local system = {}
	local params = parameters or {} -- Make sure we don't cause null reference errors if there were no paramaters supplied.

	system.x = params.x or 0
	system.y = params.y or 0
	system.w = params.w or love.graphics.getWidth()
	system.h = params.h or love.graphics.getHeight()

	system.color = params.c or params.color or {255, 255, 255, 255} -- Colors are in RGB. These are converted for GLSL in the generateFluidshader function.
	system.gravity = params.g or params.gravity or 0.0981 -- This value defaults to 0.0981 since the system is intended for sidescrolling games. A value of zero might be useful for top down based games.
	system.mass = params.m or params.mass or 1.0 -- Global mass of particles in this system.
	system.damping = params.d or params.damping or 1.0 -- How much particles lose velocity when not colliding. Velocity is divided by this number.
	system.collisionDamping = params.cd or params.collisiondamping or 1.1 -- How much velocity is divided by when a collision occurs. Useful for particle clumping.
	system.particleFriction = params.fr or params.friction or 1.0 -- How much x-velocity is lost when colliding with the top of flat surfaces. Values are multiplied.
	system.radius = params.r or params.radius or 10.0 -- Global size of particles
	system.fluidmargin = params.fm or params.fluidmargin or params.margin or 1.25 -- Distance margin between particle connections through the shader.

	system.quadtree = {} -- Table containing the partitioned quadtrees
	system.quads = {}
	system.quadtreeMaxObjects = params.maxquadobjects or 64 -- The amount of objects needed in a cell before it splits. 48 seems to be the sweet spot
	system.quadtreeMaxRecursion = params.maxquadrecursion or 5 
	system.quadtreeIndex = 1

	system.drawshader = params.drawshader or true
	system.drawquads = params.drawquads or false
	system.drawaffectors = params.drawaffectors or false

	-- Assign the current system id and increment it
	system.id = id
	id = id + 1

	system.particles = {} -- Table containing the fluid particles.
	system.particleid = 1 -- Each particle is given an id to track it in the particle table. This value increments as more particles are created.

	system.colliders = {} -- Table containing a set of objects that particles can collide with.
	system.colliderid = 1 -- Indexing for colliders.

	system.affectors = {} -- Table containing objects that affect the flow of particles.
	system.affectorid = 1 -- Indexing for affectors.

	-- Add and remove particles using the following two methods.
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

		-- Color, radius, mass and collider
		particle.color = color or self.color or {255, 255, 255, 255} -- Colors: {RED, GREEN, BLUE, ALPHA/OPACITY}
		particle.r = r or self.radius or 8
		particle.fluidcollider = fluidsystem.assignCircleCollider(particle, particle.r)

		-- Id assignment
		particle.id = self.particleid
		self.particleid = self.particleid + 1

		-- Add the particle to this system's particle table
		self.particles[particle.id] = particle

		-- The quadtree has to be rebuilt. The same must be done with the shader if needed.
		self:generateQuadtree()
		if self.drawshader == true then
			self:generateFluidshader()
		end

		return particle
	end

	-- Removes a single particle by the particle's id
	function system:removeParticle(id)
		-- Lookup the particle by it's id in the particle table
		if self.particles[id] then
			self.particles[id] = nil -- Destroy the particle reference

			-- The quadtree has to be rebuilt. The same must be done with the shader if needed.
			self:generateQuadtree()
			if self.drawshader == true then
				self:generateFluidshader()
			end
		end
	end

	-- Removes all particles from the fluid system
	function system:removeAllParticles()
		for i, particle in pairs(self.particles) do
			self.particles[particle.id] = nil
		end

		-- Reset the particle index to one.
		self.particleid = 1

		-- The quadtree has to be rebuilt. The same must be done with the shader if needed.
		self:generateQuadtree()

		if self.drawshader == true then
			self.fluideffect = nil
		end
	end

	function system:returnParticleCount()
		return #self.particles
	end

	-- Apply an impulse at the given coordinates using the following method.
	function system:applyImpulse(x, y, force, radius)
		for i, particle in pairs(self.particles) do
			local dx, dy = particle.x - x, particle.y - y
			local lenght = math.sqrt((dx * dx) + (dy * dy)) 
			local dist = math.sqrt((x - particle.x)^2 + (y - particle.y)^2)
			local radius = radius or math.huge
			
			if dist < radius then
				local x2, y2 = dx / lenght, dy / lenght
				particle.vx = particle.vx + x2 * force / dist
				particle.vy = particle.vy + y2 * force / dist
			end
		end
	end

	-- Affector object creation.
	function system:addAffector(x, y, force, radius)
		local affector = {}
		affector.x = x or 0
		affector.y = y or 0
		affector.force = force or 1
		affector.radius = radius or math.huge
		affector.id = self.affectorid

		self.affectors[self.affectorid] = affector

		self.affectorid = self.affectorid + 1

		return self.affectors[self.affectorid]
	end

	function system:removeAffector(id)
		-- Check if the affector exists
		if self.affectors[id] then
			self.affectors[id] = nil -- Destroy the reference
		end
	end

	function system:removeAllAffectors()
		for i, affector in pairs(self.affectors) do
			self.affectors[affector.id] = nil
		end

		-- Reset the affector index to one.
		self.affectorid = 1
	end

	function system:returnAffectorCount()
		return #self.affectors
	end

	-- Collider object insertion. Colliders have to be created beforehand.
	function system:addCollider(c)
		-- Fluid colliders have a set of ids depending on the systems they belong to.
		c.fluidcollider.ids[self.id] = self.colliderid

		self.colliders[self.colliderid] = c

		self.colliderid = self.colliderid + 1

		return self.colliders[self.colliderid]
	end

	function system:removeCollider(c)
		-- Check if the collider exists
		if self.colliders[c.fluidcollider.ids[self.id]] then
			self.colliders[c.fluidcollider.ids[self.id]] = nil -- Destroy the reference
		end
	end

	function system:removeAllColliders()
		for i, c in pairs(self.colliders) do
			self.colliders[c.fluidcollider.ids[self.id]] = nil
		end

		-- Reset the collider index to one.
		self.colliderid = 1
	end

	function system:returnColliderCount()
		return #self.colliders
	end

	-- Generates a new quad used by the quadtree
	function system:newQuad(x, y, w, h, l, p)
		local quad = {}
		quad.x, quad.y, quad.w, quad.h = x, y, w, h
		quad.particles = {}
		quad.valid = true
		quad.level = l
		quad.parent = p
		quad.fluidcollider = fluidsystem.assignBoxCollider(quad, quad.w, quad.h)
		quad.id = self.quadtreeIndex

		self.quads[self.quadtreeIndex] = quad
	
		self.quadtreeIndex = self.quadtreeIndex + 1
			
		return quad
	end

	-- Divide a quad into four new quads.
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
					particle.fluidcollider.quads[childQuad.id] = childQuad
					containing = containing + 1
				end
			end
				
			if containing >= self.quadtreeMaxObjects then
				if childQuad.level < self.quadtreeMaxRecursion then
					self:splitQuad(childQuad)
				end
			end
		end

		-- Clear the table of particles for this invalidated quad.
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
				particle.fluidcollider.quads = {}
			end

			self:splitQuad(self.quadtree)
		else
			for i, particle in pairs(self.particles) do
				self.quadtree.particles[particle.id] = particle
				particle.fluidcollider.quads[self.quadtree.id] = self.quadtree
			end
		end
	end

	-- Used to revalidate a colliders quad if it moved out of it during the last frame
	function system:updateQuadtreeCollider(c)
		for i, quad in pairs(self.quads) do
			if quad.valid then
				if fluidsystem.boxCollision(quad, c) then
					c.fluidcollider.quads[quad.id] = quad
				end
			end
		end
	end

	-- Takes in a table and filters out the x and y variables into a new table. Screen coordinates are also changed to real coordiantes for use in shaders.
	function system:constructVectorTable(table)
		local t = {}

		for k, v in pairs(table) do
			t[k] = {v.x, love.graphics.getHeight() - v.y}
		end

		return t
	end

	-- Needs to be done when a new particle is added or removed
	function system:generateFluidshader()
		if self.particles then
			if #self.particles < 400 then
				self.fluideffect = love.graphics.newShader(([[
					#define NPARTICLES %d
					extern vec2[NPARTICLES] particles;
					extern vec4 color;
					extern float margin;
					extern float radius;

					float metaball(vec2 x){
						x /= radius * margin;
						return 1.0 / (dot(x, x));
					}

					vec4 effect(vec4 c, Image tex, vec2 tc, vec2 pc){
						float p = 0.0;
						for (int i = 0; i < NPARTICLES; ++i) p += metaball(pc - particles[i]);
						p = floor(p);
						return vec4(color.r, color.g, color.b, p);
					}
				]]):format(#self.particles))

				-- Convert the particles to a plain vector table.
				local vectorTable = self:constructVectorTable(self.particles)

				self.fluideffect:send("particles", unpack(vectorTable))
				self.fluideffect:send("color", {self.color[1] / 255, self.color[2] / 255, self.color[3] / 255, self.color[4] / 255})
				self.fluideffect:send("radius", self.radius)
				self.fluideffect:send("margin", self.fluidmargin)
			else
				self.fluideffect = nil
			end
		end
	end

	-- Update the shader by giving it the new particle positions
	function system:updateFluidshader()
		if self.particles[1] and self.fluideffect then
			local vectorTable = self:constructVectorTable(self.particles)

			self.fluideffect:send("particles", unpack(vectorTable))
		end
	end

	-- Method to simulate a frame of the simulation. This is where the real deal takes place.
	function system:simulate(dt)
		self:generateQuadtree()
		self:updateFluidshader()

		for i, affector in pairs(self.affectors) do
			self:applyImpulse(affector.x, affector.y, affector.force, affector.radius)
		end

		for i, particle in pairs(self.particles) do
			-- Make sure the particle does not leave the fluidsystem
			fluidsystem.confineResolution(particle, self.particleFriction, self.x, self.y, self.w, self.h)

			-- Add the system's gravity to the particles velocity
			particle.vy = particle.vy + self.gravity

			-- Damp the velocity. Good for when top down simulations are needed.
			particle.vx = particle.vx / self.damping
			particle.vy = particle.vy / self.damping

			-- We apply each particles velocity to it's current position
			particle.x = particle.x + particle.vx
			particle.y = particle.y + particle.vy

			-- This variable stores if a single collision was detected
			local collided = false

			self:updateQuadtreeCollider(particle)

			for i, colliderObject in pairs(self.colliders) do
				if colliderObject.fluidcollider.collision(colliderObject, particle) then
					colliderObject.fluidcollider.resolve(colliderObject, particle)
					collided = true
				end
			end

			-- Perform collision detection and resolution here
			for j, quad in pairs(particle.fluidcollider.quads) do
				for k, particle2 in pairs(quad.particles) do
					-- Make sure we are not checking against an already checked particle
					if particle2 ~= particle then
						if fluidsystem.circleCollision(particle, particle2) then
							fluidsystem.circleResolution(particle, particle2, self.collisionDamping)
							
							collided = true -- A collision was detected and so the collided variable must be set to true.
						end
					end
				end
			end

			if not collided then
				-- We save the last position this particle was in before it collided to avoid intersection issues.
				particle.lastx = particle.x - particle.vx
				particle.lasty = particle.y - particle.vy
			else
				-- We reset the particle's position to one outside of any collisions.
				particle.x = particle.lastx 
				particle.y = particle.lasty
			end
		end
	end

	-- Method to draw the current state of the fluid simulation
	function system:draw()
		if self.fluideffect and self.drawshader == true then
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.setShader(self.fluideffect)
			love.graphics.rectangle('fill', 0,0, love.graphics.getWidth(), love.graphics.getHeight())
		else
			for i, particle in pairs(self.particles) do
				love.graphics.setColor(self.color)
				love.graphics.circle("fill", particle.x, particle.y, particle.r)
				-- love.graphics.rectangle("line", particle.x - particle.r + particle.fluidcollider.ox, particle.y - particle.r + particle.fluidcollider.oy, particle.r * 2, particle.r * 2)
			end
		end

		-- Reset the shader so it does not influence other systems and draw calls.
		love.graphics.setShader()

		love.graphics.setColor(255, 255, 255, 255)

		-- Draw quads if it is desired.
		if self.drawquads == true then
			if self.quads then
				for i, quad in pairs(self.quads) do
					love.graphics.rectangle("line", quad.x, quad.y, quad.w, quad.h)	
				end
			end
		end

		-- Draw affectors if it is desired.
		if self.drawaffectors == true then
			if self.affectors then
				for i, affector in pairs(self.affectors) do
					if affector.radius > ((love.graphics.getWidth() + love.graphics.getHeight()) / 2) then
						love.graphics.circle("line", affector.x, affector.y, 128)
					else
						love.graphics.circle("line", affector.x, affector.y, affector.radius)
					end
				end
			end
		end

		-- We reset the global color so we don't affect any other game drawing events
		love.graphics.setColor(255, 255, 255, 255)
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
function fluidsystem.destroy(id)
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

-- Creates a new box collider. The Arguments ox and oy are the base offset from the parent object's position values.
function fluidsystem.assignBoxCollider(object, w, h, mass, static, ox, oy)
	if object then
		local collider = {}

		collider.collision = fluidsystem.boxCollision
		collider.resolve = fluidsystem.boxResolution
		collider.w = w or 16
		collider.h = h or 16
		collider.mass = mass or 1
		collider.static = static or false
		collider.ox, collider.oy = ox or 0, oy or 0
		collider.quads = {}
		collider.ids = {}

		object.fluidcollider = collider

		return object.fluidcollider
	end
end

-- Creates a new circle collider. The Arguments ox and oy are the base offset from the parent object's position values.
function fluidsystem.assignCircleCollider(object, r, mass, static, ox, oy)
	if object then
		local collider = {}

		collider.collision = fluidsystem.circleCollision
		collider.resolve = fluidsystem.circleResolution
		collider.r = r or 8
		collider.mass = mass or 1
		collider.static = static or false
		collider.ox, collider.oy = ox or 0, oy or 0
		collider.quads = {}
		collider.ids = {}

		object.fluidcollider = collider

		return object.fluidcollider
	end
end

-- Image collider takes in an image to calculate pixel perfect collision. The Arguments ox and oy are the base offset from the parent object's position values.
function fluidsystem.assignPixelCollider(object, sx, sy, imagedata, mass, static, ox, oy)
	if object then
		local collider = {}

		collider.collisionDetection = fluidsystem.boxCollision
		collider.collisionResolution = fluidsystem.boxResolution
		collider.mass = mass or 1
		collider.static = static or false
		collider.ox, collider.oy = ox or 0, oy or 0
		collider.quads = {}
		collider.ids = {}

		object.fluidcollider = collider

		return object.fluidcollider
	end
end

-- COLLISION DETECTION FUNCTIONS
-- Basic box collision detection (c1/c2 arguments are the two colliders that should be checked for collision)
function fluidsystem.boxCollision(c1, c2)
	-- We make sure that all possible variables are defined. Cross collision type handling is also done here.
	local c1x = c1.x or c1.position.x or 0
	local c1y = c1.y or c1.position.y or 0
	local c2x = c2.x or c2.position.x or 0
	local c2y = c2.y or c2.position.y or 0
	local c1w = c1.fluidcollider.w or c1.fluidcollider.r * 2 or 16
	local c1h = c1.fluidcollider.h or c1.fluidcollider.r * 2 or 16
	local c2w = c2.fluidcollider.w or c2.fluidcollider.r * 2 or 16
	local c2h = c2.fluidcollider.h or c2.fluidcollider.r * 2 or 16
	local r1offset = c1.fluidcollider.r or 0
	local r2offset = c2.fluidcollider.r or 0

	local c1x2, c1y2, c2x2, c2y2 = c1.x + c1w, c1.y + c1h, c2.x + c2w, c2.y + c2h

	-- Returns true if a box collision was detected
	if c1.x - r1offset < c2x2 - r2offset and c1x2 - r1offset > c2.x - r2offset and c1.y - r1offset < c2y2 - r2offset and c1y2 - r1offset > c2.y - r2offset then
		return {c1.x, c1x2, c1.y, c1y2, c2.y, c2x2, c2.y, c2y2}
	end

	return false
end

-- Circle collision without the use of math.sqrt
function fluidsystem.circleCollision(c1, c2)
	local c1x = c1.x or c1.position.x or 0
	local c1y = c1.y or c1.position.y or 0
	local c2x = c2.x or c2.position.x or 0
	local c2y = c2.y or c2.position.y or 0
	local c1r = c1.fluidcollider.w or c1.fluidcollider.r or 8
	local c2r = c2.fluidcollider.w or c2.fluidcollider.r or 8

	local dist = (c2x - c1x)^2 + (c2y - c1y)^2

	-- Returns true if a circle collision was detected
	return (dist + (c2r^2 - c1r^2)) < (c1r*2)^2
end

function fluidsystem.pixelCollision(c1, c2) end -- TODO

-- COLLISION RESOLUTION FUNCTIONS
function fluidsystem.boxResolution(c1, c2, f, d)
	local frictionForce = f or 1
	local damping = d or 1

	-- We make sure that all possible variables are defined. Cross collision type handling is also done here.
	local c1x = c1.x or c1.position.x or 0
	local c1y = c1.y or c1.position.y or 0
	local c2x = c2.x or c2.position.x or 0
	local c2y = c2.y or c2.position.y or 0
	local c1w = c1.fluidcollider.w or c1.fluidcollider.r * 2 or 16
	local c1h = c1.fluidcollider.h or c1.fluidcollider.r * 2 or 16
	local c2w = c2.fluidcollider.w or c2.fluidcollider.r * 2 or 16
	local c2h = c2.fluidcollider.h or c2.fluidcollider.r * 2 or 16
	local c1vx = c1.vx or 0
	local c1vy = c1.vy or 0
	local c2vx = c2.vx or 0
	local c2vy = c2.vy or 0
	local c1mass = c1.fluidcollider.mass or 1
	local c2mass = c2.fluidcollider.mass or 1
	local c1radiusOffset = c1.fluidcollider.r or 0
	local c2radiusOffset = c2.fluidcollider.r or 0

	local jointMass = c1mass + c2mass
	local differenceMass = c1mass - c2mass

	local c1vxNew = (((c1vx * differenceMass) + (2 * c2mass * c2vx)) / jointMass)
	local c1vyNew = (((c1vy * differenceMass) + (2 * c2mass * c2vy)) / jointMass)
	local c2vxNew = (((c2vx * differenceMass) + (2 * c1mass * c1vx)) / jointMass)
	local c2vyNew = (((c2vy * differenceMass) + (2 * c1mass * c1vy)) / jointMass)

	-- Check if the box could possibly have hit one of the sides.
	-- Position values are overwritten for particles by resetting them to their old positions.
	if c1x - c1vx + c1w > c2x and c1x - c1vx < c2x + c2w then
		if c1y - c1vy + c1h < c2y and c1vy > 0 then
			c1.y = c2y - c1h
			if c1.fluidcollider.static == false then
				c1.vx = c1vx * frictionForce
			end

		elseif c1y - c1vy > c2y + c2h and c1vy < 0 then
			c1.y = c2.y + c2h
		end

	elseif c1y - c1vy + c1h > c2y and c1y - c1vy < c2y + c2h then
		if c1x - c1vx + c1w < c2x and c1vx > 0 then
			c1.x = c2x - c1w

		elseif c1x - c1vx > c2x + c2w and c1vx < 0 then
			c1.x = c2x + c2w
		end
	end

	if c1.fluidcollider.static == false then
		c1.vx = c1vxNew / damping
		--c1.vy = c1vyNew / damping
		c1.x = c1x + c1vx
		c1.y = c1y + c1vy
	end

	if c2.fluidcollider.static == false then
		c2.vx = c2vxNew / damping
		c2.vy = c2vyNew / damping
		c2.x = c2x + c2vx
		c2.y = c2y + c2vy
	end
end

function fluidsystem.innerBoxResolution(c1, c2, f)
	local friction = f or 1

	-- We make sure that all possible variables are defined. Cross collision type handling is also done here.
	local c1x = c1.x or c1.position.x or 0
	local c1y = c1.y or c1.position.y or 0
	local c2x = c2.x or c2.position.x or 0
	local c2y = c2.y or c2.position.y or 0
	local c1w = c1.fluidcollider.w or c1.fluidcollider.r * 2 or 16
	local c1h = c1.fluidcollider.h or c1.fluidcollider.r * 2 or 16
	local c2w = c2.fluidcollider.w or c2.fluidcollider.r * 2 or 16
	local c2h = c2.fluidcollider.h or c2.fluidcollider.r * 2 or 16
	local c1vx = c1.vx or 0
	local c1vy = c1.vy or 0
	local c2vx = c2.vx or 0
	local c2vy = c2.vy or 0
	local c1radiusOffset = c1.fluidcollider.r or 0
	local c2radiusOffset = c2.fluidcollider.r or 0

	-- Position values are overwritten for particles by resetting them to their old positions.
	if c1x + c1w - c1radiusOffset > c2x + c2w then
		c1.x = c2x + c2w - c1w + c1radiusOffset
		c1.vx = -(c1vx / 2)

	elseif c1x - c1radiusOffset < c2x then
		c1.x = c2x + c1radiusOffset
		c1.vx = -(c1vx / 2)
	end

	if c1y + c1h - c1radiusOffset > c2y + c2h then
		c1.y = c2y + c2h - c1h + c1radiusOffset
		c1.vy = -(c1vy / 2)

		-- We are colliding from the top. Add friction.
		c1.vx = c1vx * friction

	elseif c1y - c1radiusOffset < c2y then
		c1.y = c2y + c1radiusOffset
		c1.vy = -(c1vy / 2)
	end
end

-- TODO: Add offset handling
function fluidsystem.circleResolution(c1, c2, d)
	local damping = d or 1

	-- We make sure that all possible variables are defined. Cross collision type handling is also done here.
	local c1x = c1.x or c1.position.x or 0
	local c1y = c1.y or c1.position.y or 0
	local c2x = c2.x or c2.position.x or 0
	local c2y = c2.y or c2.position.y or 0
	local c1vx = c1.vx or 0
	local c1vy = c1.vy or 0
	local c2vx = c2.vx or 0
	local c2vy = c2.vy or 0
	local c1r = c1.fluidcollider.w or c1.fluidcollider.r or 8
	local c2r = c2.fluidcollider.w or c2.fluidcollider.r or 8
	local c1mass = c1.fluidcollider.mass or 1
	local c2mass = c2.fluidcollider.mass or 1

	-- Position at which the collision occured
	local collisionPointX = ((c1x * c2r) + (c2x * c1r)) / (c1r + c2r)
	local collisionPointY = ((c1y * c2r) + (c2y * c1r)) / (c1r + c2r)

	local nx = (c1x - c2x) / (c1r + c2r) 
	local ny = (c1y - c2y) / (c1r + c2r) 
	local a1 = c1vx * nx + c1vy * ny 
	local a2 = c2vx * nx + c2vy * ny 
	local p = 2 * (a1 - a2) / (c1mass + c2mass) 

	if c1.fluidcollider.static == false then
		c1.vx = (c1vx - p * nx * c2mass) / damping
		c1.vy = (c1vy - p * ny * c2mass) / damping
		c1.x = c1x + c1vx
		c1.y = c1y + c1vy
	end

	if c2.fluidcollider.static == false then
		c2.vx = (c2vx + p * nx * c1mass) / damping
		c2.vy = (c2vy + p * ny * c1mass) / damping
		c2.x = c2x + c2vx
		c2.y = c2y + c2vy
	end

	return collisionPointX, collisionPointY
end

function fluidsystem.pixelResolution(c1, c2) end -- TODO

-- Keeps a collider inside a specified area
function fluidsystem.confineResolution(c, f, x, y, w, h)
	-- Offset calculation. Often used if the origins need to be repositioned.
	-- Circles automatically receive offset calculations since their origins are at their center.
	local offsetx = c.fluidcollider.ox or 0
	local offsety = c.fluidcollider.oy or 0

	local radiusOffset = c.fluidcollider.r or 0

	local frictionForce = f or 1

	local cw = c.fluidcollider.w or c.fluidcollider.r * 2 or 16
	local ch = c.fluidcollider.h or c.fluidcollider.r * 2 or 16

	local cvx = c.vx or 0
	local cvy = c.vy or 0

	local sx = x or 0
	local sy = y or 0
	local sw = w or love.graphics.getWidth() or 0
	local sh = h or love.graphics.getHeight() or 0

	if (c.x + offsetx) + cw - radiusOffset > sx + sw then
		c.x = sx + sw - cw - offsetx + radiusOffset
		c.vx = -(cvx / 2)

	elseif (c.x + offsetx) - radiusOffset < sx + offsetx then
		c.x = sx + offsetx + radiusOffset
		c.vx = -(cvx / 2)
	end

	if (c.y + offsety) + ch - radiusOffset > sy + sh then
		c.y = sy + sh - ch - offsety + radiusOffset
		c.vy = -(cvy / 2)

		-- We are colliding from the top. Add friction.
		c.vx = cvx * frictionForce

	elseif (c.y + offsety) - radiusOffset < sy + offsety then
		c.y = sy + offsety + radiusOffset
		c.vy = -(cvy / 2)
	end
end

return fluidsystem