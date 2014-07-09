math.randomseed(os.time())

require("fluidsystem")

local strayTime = 0
local timestep = 0.018

local fluid = {}

local box = {x = 480, y = 710, mass = 1000}
fluidsystem.assignBoxCollider(box, 64, 64, 0, true)

function love.load()
	parameters = {}
	fluid = fluidsystem.new(parameters)
	fluid:addCollider(box)
	collectgarbage("setstepmul", 200)
	collectgarbage("setpause", 105)

	love.keyboard.setKeyRepeat("+")
	love.keyboard.setKeyRepeat("kp+")
end

function love.update(dt)
	love.window.setTitle("LOVEFluid Simulation Example - FPS: " .. love.timer.getFPS())

	strayTime = strayTime + dt

	-- This while loop makes updates occur in set increments
	while strayTime >= timestep do
		strayTime = strayTime - timestep

		fluidsystem.update(timestep)

		if love.mouse.isDown("l") then
			local x, y = love.mouse.getPosition()
			fluid:applyImpulse(x, y, 25)
		end
	end

	collectgarbage()
end

function love.draw()
	love.graphics.print("Press the left mouse button to apply force to the particles", 16, 20)
	love.graphics.print("Press '+' or the right mouse button to create new particles", 16, 40)
	love.graphics.print("Press 'delete' to remove all particles", 16, 60)
	love.graphics.print("Toggle the shader by pressing 's' / Toggle Quadtrees by pressing 'q'", 16, 80)
	love.graphics.print("Total particles: " ..#fluid.particles, 16, 100)
	fluidsystem:draw()
	love.graphics.rectangle("fill", box.x, box.y, 64, 64)
end

function love.mousepressed(x, y, button)
	if button == "l" then
		fluid:applyImpulse(x, y, 250)
	elseif button == "r" then
		fluid:addParticle(x, y, math.random(-1000,1000) / 100, math.random(-1000,1000) / 100)
	end
end

function love.keypressed(keycode)
	if keycode == "+" or keycode == "kp+" then
		fluid:addParticle(math.random(32, love.graphics.getWidth() - 32), math.random(32, love.graphics.getHeight() - 200), 0, 0)
	end

	if keycode == "delete" then
		fluid:removeAllParticles()
	end

	if keycode == "s" then
		if fluid.drawshader == true then 
			fluid.drawshader = false
		else
			fluid.drawshader = true
			if #fluid.particles > 0 then
				fluid:generateFluidshader()
			end
		end
	end

	if keycode == "q" then
		if fluid.drawquads == true then 
			fluid.drawquads = false
		else
			fluid.drawquads = true
		end
	end
end

function love.resize(w, h)
	fluid.w = love.graphics.getWidth()
	fluid.h = love.graphics.getHeight()
end