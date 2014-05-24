require("fluidsystem")

local fluid = {}

function love.load()
	fluid = fluidsystem.new()
	for i=1, 4, 1 do
		for j=1, 4 do
			fluid:addParticle(64 * i, 64 * j, 0, 0, nil, 16)
		end
	end
end

function love.update(dt)
	fluid:simulate(dt)
end

function love.draw()
	fluid:draw()
end