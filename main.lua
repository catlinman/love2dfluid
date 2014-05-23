require("fluidsystem")

local fluid = {}

function love.load()
	fluid = fluidsystem.new()
	fluid:addParticle(32,32,0,0,nil,16)
	fluid:addParticle(128,128,0,0,nil,16)
end

function love.update(dt)
	fluid:simulate(dt)
end

function love.draw()
	fluid:draw()
end