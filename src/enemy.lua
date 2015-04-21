--[[
Copyright (C) 2015  Albert Diserholt

This file is part of Chroma Watcher.

Chroma Watcher is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Chroma Watcher is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Chroma Watcher. If not, see <http://www.gnu.org/licenses/>.
--]]

local class = require("lib.middleclass")

local Object = require("src.object")

local Enemy = class("Enemy", Object)

function Enemy:initialize(image, quad, particles, colour, shape)
	Object.initialize(self, Object.enemy, shape)
	self.image = image
	self.quad = quad
	self.particles = particles
	self.colour = colour
	self.velocityX = love.math.random(10,100)
	self.spin = love.math.random(1,10)

	self.amplitude = love.math.random(0.5, 2) --love.math.random(1,10)
	self.phase = 0--love.math.random(0,100)
	self.frequency = love.math.random(0.1, 10) --love.math.random(0.001,10)
	self.time = 0
	self.dead = false
end

function Enemy:update(dt)
	local dx, dy = 0, 0

	if not self:isDestroyed() then
		dx = -self.velocityX * dt

		self.time = self.time + dt
		dy = self.amplitude * math.sin(self.frequency * self.time + self.phase)

		self.shape:rotate(dt * self.spin)

		self.shape:move(dx, dy)
	else
		if not self.dead then
			self.dead = true
			local colour = self:getColour():getColour()
			self.particles:setColors(
				colour[1], colour[2], colour[3], 255,
				100, 100, 100, 255,
				100, 100, 100, 0
			)
			self.particles:emit(50)
		end
		self.particles:update(dt)
		if self.particles:getCount() == 0 then
			self:markFinished()
		end
	end
end

function Enemy:draw()
	love.graphics.setColor(self:getColour():getColour())
	if gDebug then
		Object.draw(self)
	end

	if not self:isDestroyed() then
		love.graphics.push()
		love.graphics.translate(self.shape:center())
		love.graphics.rotate(self.shape:rotation())
		love.graphics.draw(self.image, self.quad, -32, -32)
		love.graphics.pop()
	else
		love.graphics.draw(self.particles, self.shape:center())
	end
end

function Enemy:getColour()
	return self.colour
end

return Enemy
