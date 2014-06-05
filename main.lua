math.randomseed(os.time())

require("fluidsystem")

local strayTime = 0
local timestep = 0.01565 -- 70 FPS - Increasing this value will make simulating faster at the exspense of accuracy

local fluid = {}

function love.load()
	fluid = fluidsystem.new()

	local num = 256
	local actual = math.ceil(math.sqrt(num))

	collectgarbage("setstepmul", 200)
	collectgarbage("setpause", 105)

	love.keyboard.setKeyRepeat("+")
	love.keyboard.setKeyRepeat("kp+")
end

function love.update(dt)
	love.window.setTitle("FPS: " .. love.timer.getFPS())

	strayTime = strayTime + dt

	-- This while loop makes updates occur in set increments
	while strayTime >= timestep do
		strayTime = strayTime - timestep

		fluidsystem.update(timestep)

		if love.mouse.isDown("l") then
			local x, y = love.mouse.getPosition()
			fluid:applyImpulse(x, y, 5)
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
	fluid:draw()
end

function love.mousepressed(x, y, button)
	if button == "l" then
		fluid:applyImpulse(x, y, 250)
	elseif button == "r" then
		if #fluid.particles < 512 then
			fluid:addParticle(x, y, math.random(-1000,1000) / 100, math.random(-1000,1000) / 100, nil, 8)
		end
	end
end

function love.keypressed(keycode)
	if #fluid.particles < 512 then
		if keycode == "+" or keycode == "kp+" then
			fluid:addParticle(math.random(32, 1024 - 32), math.random(32, 768 - 32), math.random(-1000,1000) / 100, math.random(-1000,1000) / 100, nil, 8)
		end
	end

	if keycode == "delete" then
		fluid:removeAllParticles()
	end

	if keycode == "s" then
		if fluid.useShader == true then 
			fluid.useShader = false
		else
			fluid.useShader = true
			if #fluid.particles > 0 then
				fluid:generateFluidshader()
			end
		end
	end

	if keycode == "q" then
		if fluid.showQuads == true then 
			fluid.showQuads = false
		else
			fluid.showQuads = true
		end
	end
end