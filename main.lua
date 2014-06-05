math.randomseed(os.time())

require("fluidsystem")

local strayTime = 0
local timestep = 0.02 -- 70 FPS - Increasing this value will make simulating faster at the exspense of accuracy

local fluid = {}
local loops = 0

function love.load()
	fluid = fluidsystem.new()

	local num = 128
	local actual = math.ceil(math.sqrt(num))
	
	for i=1, actual do
		for j=1, actual do
			fluid:addParticle(i * 64, 64 + j * 64, math.random(-1000,1000) / 100, math.random(-1000,1000) / 100, nil, 8)
		end
	end

	collectgarbage("setstepmul", 200)
	collectgarbage("setpause", 105)
end

function love.update(dt)
	love.window.setTitle("FPS: " .. love.timer.getFPS())

	strayTime = strayTime + dt

	-- This while loop makes updates occur in set increments
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