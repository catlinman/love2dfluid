math.randomseed(os.time())

require("fluidsystem")

local strayTime = 0
local timestep = 0.015

local fluid = {}

function love.load()
	fluid = fluidsystem.new()

	for i=1, 16 do
		for j=1, 16 do
			fluid:addParticle(32 + i * 32, j * 32, math.random(-100,100) / 100, math.random(-100,100) / 100, nil, 8)
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