math.randomseed(os.time())

require("fluidsystem")

local strayTime = 0
local timestep = 0.015

local fluid = {}

function love.load()
	fluid = fluidsystem.new()

	for i=1, 8 do
		for j=1, 8 do
			fluid:addParticle(64 + i * 64, j * 64, math.random(-1,1), 0, nil, 16)
		end
	end
end

function love.update(dt)
	strayTime = strayTime + dt

	while strayTime >= timestep do
		strayTime = strayTime - timestep

		fluidsystem.update(timestep)
	end
end

function love.draw()
	fluid:draw()
end