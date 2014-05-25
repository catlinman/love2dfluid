math.randomseed(os.time())

require("fluidsystem")

local strayTime = 0
local timestep = 0.015

local fluid = {}

function love.load()
	fluid = fluidsystem.new()
	for i=1, 64 do
		fluid:addParticle(math.random(32, 1024 - 32), math.random(32, 256), math.random(-4,4), math.random(-4,4), nil, 16)
	end
end

function love.update(dt)
	strayTime = strayTime + dt

	while strayTime >= timestep do
		strayTime = strayTime - timestep

		fluid:simulate(timestep)
	end
end

function love.draw()
	fluid:draw()
end