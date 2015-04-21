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

local Object = class("Object")

Object.static.floor = "Floor"
Object.static.enemy = "Enemy"
Object.static.player = "Player"
Object.static.projectile = "Projectile"

function Object:initialize(type, shape)
	self.shape = shape
	self.shape.owner = self
	self.type = type
	self.destroyed = false
	self.finished = false -- + Death animation
end

function Object:update(dt)
end

function Object:draw()
	--love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	self.shape:draw("fill")
end

function Object:setDeathSound(sound)
	self.deathSound = sound
end

function Object:onCollision(other, dx, dy, dt)
	-- Unoverridden it simply passes the event to the other object.
	other:onCollision(self, -dx, -dy, dt)
end

function Object:onCollisionEnded(other)
	if other.type == Object.player then
		other:onCollisionEnded(self)
	end
end

function Object:markDestroyed()
	self.destroyed = true
	if self.deathSound then
		self.deathSound:play()
	end
	Object.collider:setGhost(self.shape)
end
function Object:isDestroyed()
	return self.destroyed
end

function Object:markFinished()
	self.finished = true
end
function Object:isFinished()
	return self.finished
end

return Object
