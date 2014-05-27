math.randomseed(os.time())

require("fluidsystem")

local strayTime = 0
local timestep = 0.015

local fluid = {}

function love.load()
	fluid = fluidsystem.new()
	for i=1, 30 do
		fluid:addParticle(i * 32, 32, 0, 0, nil, 16)
	end
	for i=1, 30 do
		fluid:addParticle(i * 32, 128, 0, 0, nil, 16)
	end

	fluid:addParticle(95, 75, 0, 0, nil, 16)
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