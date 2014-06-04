math.randomseed(os.time())

require("fluidsystem")

local strayTime = 0
local timestep = 0.01565

local fluid = {}
local loops = 0

function love.load()
	fluid = fluidsystem.new()

	for i=1, 22 do
		for j=1, 22 do
			fluid:addParticle(i * 42, 32 + j * 32, math.random(-1000,1000) / 100, math.random(-1000,1000) / 100, nil, 8)
		end
	end

	collectgarbage("setstepmul", 200)
	collectgarbage("setpause", 105)
end

function love.update(dt)
	love.window.setTitle("FPS: " .. love.timer.getFPS())

	strayTime = strayTime + dt

	while strayTime >= timestep do
		strayTime = strayTime - timestep

		fluidsystem.update(timestep)

		loops = loops + 1
	end

	collectgarbage()
end

function love.draw()
	love.graphics.print("Click to apply force to the particles", 16, 16)
	fluid:draw()
end

function love.mousepressed(x, y, button)
	fluid:applyImpulse(x, y, 250)
end