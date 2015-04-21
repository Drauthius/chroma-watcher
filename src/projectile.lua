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
require("lib.math")

local Object = require("src.object")

local Projectile = class("Projectile", Object)

Projectile.static.speed = 400
Projectile.static.explosionDistance = 25 -- Squared

function Projectile:initialize(image, animation, colour, player, shape)
	Object.initialize(self, Object.projectile, shape)
	self.image = image
	self.animation = {
		flying = animation["flying"]:clone(),
		colliding = animation["colliding"]:clone()
	}
	self.colour = colour
	self.player = player
	self.offset = { -25, -24 }
end

function Projectile:update(dt)
	local dx, dy = 0, 0

	if not self:isDestroyed() then
		dx = self.travelVector[1] * Projectile.speed * dt
		dy = self.travelVector[2] * Projectile.speed * dt

		self.shape:move(dx, dy)

		if math.distancesquared(self.targetX, self.targetY, self.shape:center()) <= Projectile.explosionDistance then
			self:markDestroyed()
		end
	end

	if not self:isDestroyed() then
		self.animation["flying"]:update(dt)
	else
		self.animation["colliding"]:update(dt)
	end
end

function Projectile:draw()
	love.graphics.setColor(self:getColour():getColour())
	--Object.draw(self)

	love.graphics.push()
	love.graphics.translate(self.shape:center())
	love.graphics.rotate(math.atan2(self.travelVector[2], self.travelVector[1]))

	if not self:isDestroyed() then
		self.animation["flying"]:draw(self.image, self.offset[1], self.offset[2])
	else
		local ani = self.animation["colliding"]
		if ani.status ~= "paused" then
			ani:draw(self.image, self.offset[1], self.offset[2])
		else
			self:markFinished()
		end
	end

	love.graphics.pop()
end

function Projectile:onCollision(other, dx, dy)
	if other.type == Object.floor then
		self:markDestroyed()
	elseif other.type == Object.enemy then
		self:markDestroyed()
		if self.colour == other:getColour() then
			self.player.score = self.player.score + 10
			other:markDestroyed()
		end
	end
end

function Projectile:setTarget(x, y)
	self.targetX, self.targetY = x, y
	local vector = {
		self.targetX - (self.shape:center()),
		self.targetY - select(2, self.shape:center())
	}
	local magnitude = math.sqrt(vector[1]^2 + vector[2]^2)
	self.travelVector = {
		vector[1] / magnitude,
		vector[2] / magnitude
	}
end

function Projectile:getColour()
	return self.colour
end

return Projectile
