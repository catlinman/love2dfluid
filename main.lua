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
			fluid:addParticle(64 + i * 32, 64 + j * 32, 0, 0, nil, 8)
		end
	end

	fluid:generateQuadtree()

	collectgarbage("setstepmul", 200)
	collectgarbage("setpause", 105)
end

function love.update(dt)
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

function love.keypressed(key)
	print(loops)
end

function love.mousepressed(x, y, button)
	fluid:applyImpulse(x, y, 250)
end