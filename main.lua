math.randomseed(os.time())

require("fluidsystem")

local strayTime = 0
local timestep = 0.015

local fluid = {}

function love.load()
	fluid = fluidsystem.new()

	for i=1, 64 do
		for j=1, 4 do
			fluid:addParticle(i * 16, j * 16, math.random(-1,1), 0, nil, 8)
		end
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