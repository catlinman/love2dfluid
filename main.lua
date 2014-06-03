math.randomseed(os.time())

require("fluidsystem")

local strayTime = 0
local timestep = 0.01565

local fluid = {}
local loops = 0

function love.load()
	fluid = fluidsystem.new()

	for i=1, 12 do
		for j=1, 8 do
			fluid:addParticle(64 + i * 64, j * 64, math.random(-100,100) / 100, math.random(-100,100) / 100, nil, 8)
		end
	end
end

function love.update(dt)
	strayTime = strayTime + dt

	while strayTime >= timestep do
		strayTime = strayTime - timestep

		fluidsystem.update(timestep)

		loops = loops + 1
	end
end

function love.draw()
	fluid:draw()
end

function love.keypressed(key)
	print(loops)
end

function love.mousepressed(x, y, button)
	fluid:applyImpulse(x, y, 1000)
end