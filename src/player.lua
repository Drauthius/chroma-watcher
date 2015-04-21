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

local anim8 = require("lib.anim8")
local class = require("lib.middleclass")

local Colour = require("src.colour")
local Object = require("src.object")

local Player = class("Player", Object)

Player.static.speedX = 150
Player.static.gravity = 400
Player.static.jumpBurst = 22
Player.static.jumpDecay = 50
Player.static.maxHealth = 1

Player.static.minWeaponRotation = -0.4
Player.static.maxWeaponRotation = 0.6

function Player:_updateState(state)
	if self.state ~= state then
		self.state = state
		self.animations[state]:gotoFrame(1)
		self.animations[state]:resume()
	end
end

function Player:initialize(particles, shape)
	Object.initialize(self, Object.player, shape)
	self.particles = { particles }
	self.grounded = false
	self.state = "falling"
	self.velocityX = 0
	self.velocityY = 0
	self.health = Player.maxHealth
	self.coloursSelected = {}

	self.image = love.graphics.newImage("gfx/player.png")
	self.imageOffset = { -80/2, -self.image:getHeight()/2 - 4 }
	self.weaponOffset = { 0, self.imageOffset[2] + 2 }
	local grid = anim8.newGrid(80, self.image:getHeight(), self.image:getWidth(), self.image:getHeight())
	self.animations = {
		walking = anim8.newAnimation(grid('1-3',1), 0.2),
		jumping = anim8.newAnimation(grid('4-5',1), 0.21, "pauseAtEnd"),
		falling = anim8.newAnimation(grid('6-7',1), 0.15, "pauseAtEnd"),
		weapon = anim8.newAnimation(grid('9-9',1), 1, "pauseAtEnd")
	}

	self.muzzleFlash = {
		image = love.graphics.newImage("gfx/muzzleflash.png"),
		time = 1000
	}
end

function Player:update(dt)
	local dx, dy = 0, 0

	if not self:isDestroyed() then
		if self.health <= 0 then
			self:markDestroyed()
		end

		self.velocityX = self.velocityX + dt
		dx = (math.min(self.velocityX,150) + Player.speedX) * dt

		-- We can't always apply gravity, because we might end up in a scenario
		-- where the player collides with the floor tile to the right, then with
		-- the floor tile below, getting stuck on a flat surface...
		if not self.grounded then
			if self.velocityY < 0 then
				self.velocityY = self.velocityY + Player.jumpDecay * dt
			else
				self:_updateState("falling")
			end
			dy = self.velocityY + Player.gravity * dt
			--print("Applying gravity")
		end

		self.muzzleFlash.time = self.muzzleFlash.time + dt

		--print("move")
		self.shape:move(dx, dy)

		for _,ani in pairs(self.animations) do
			ani:update(dt)
		end
	else
		if self.particles[2] == nil then
			local master = self.particles[1]
			master:setSpeed(-100, 300)
			master:setAreaSpread("normal", 40, 40)
			master:setLinearAcceleration(-300, -300, 300, 300)
			master:setRadialAcceleration(10, 1000)
			master:setParticleLifetime(2,3)
			local pos = {
				self.imageOffset[1]+5,self.imageOffset[2]+5, -(self.imageOffset[1]+5),self.imageOffset[2]+5,
				self.imageOffset[1]+5,0, -(self.imageOffset[1]+5),0,
				self.imageOffset[1]+5,-(self.imageOffset[2]+5), -(self.imageOffset[1]+5),-(self.imageOffset[2]+5)
			}
			for i=1,6 do
				if self.particles[i] == nil then
					self.particles[i] = self.particles[1]:clone()
				end
				local part = self.particles[i]
				local colour
				if i <= 3 then
					colour = Colour.mix(i):getColour()
				else
					colour = Colour.mix(i-3, i-2):getColour()
				end
				part:setColors(
					colour[1], colour[2], colour[3], 255,
					colour[1]-50, colour[2]-50, colour[3]-50, 255,
					colour[1]-100, colour[2]-100, colour[3]-100, 255,
					100, 100, 100, 0)
				part:setPosition(pos[i*2-1], pos[i*2])
				part:emit(50)
			end
			self.time = 0

			love.event.push("screenshake")
		else
			self.time = self.time + dt
			local count = 0
			for _,part in ipairs(self.particles) do
				part:update(dt)
				count = count + part:getCount()
			end
			--if count == 0 then
			if self.time >= 1.5 and not self:isFinished() then
				self:markFinished()
			end
		end
	end
end

function Player:draw(offsetX, offsetY)
	local x, y = self.shape:center()
	love.graphics.setColor(255, 255, 255, 255)
	if gDebug then
		Object.draw(self)
	end

	love.graphics.push()
	love.graphics.translate(x, y)

	if not self:isDestroyed() then
		self.animations[self.state]:draw(self.image, self.imageOffset[1], self.imageOffset[2])

		local mx, my = love.mouse.getPosition()
		self.muzzleDirection = math.min(Player.maxWeaponRotation,
			math.max(Player.minWeaponRotation,
				math.atan2(my - y + offsetY, mx - x + offsetX)))

		love.graphics.rotate(self.muzzleDirection)

		-- Gun kick
		local kick = (1 - math.min(self.muzzleFlash.time, 1)) * 8
		local colours = Colour.mix(self:getColours())
		if colours == nil then
			colours = { 255, 255, 255, 255 }
		else
			colours = colours:getColour()
			love.graphics.setColor(colours)
			love.graphics.rectangle("fill",
				19 - kick, 0,
				60, 12)
			love.graphics.setColor(255, 255, 255, 255)

			--[[love.graphics.setColor(
				math.min(colours[1] + 40, 255),
				math.min(colours[2] + 40, 255),
				math.min(colours[3] + 40, 255),
				255
			)]]
		end

		self.animations["weapon"]:draw(self.image, self.weaponOffset[1] - kick, self.weaponOffset[2])

		if self.muzzleFlash.time < 0.1 then
			love.graphics.setColor(colours)
			love.graphics.draw(self.muzzleFlash.image,
				75 - kick, -12) -- Trial and terror
		end
	else
		for _,part in ipairs(self.particles) do
			love.graphics.draw(part)
		end
	end

	love.graphics.pop()
end

function Player:jump()
	if self.grounded and self.velocityY >= 0 then
		self.grounded = false
		self:_updateState("jumping")
		self.jumpSound:play()
		self.velocityY = -Player.jumpBurst
	end
end

function Player:setJumpSound(sound)
	self.jumpSound = sound
end

function Player:shotFrom(x, y)
	self.muzzleFlash.x = x
	self.muzzleFlash.y = y
	self.muzzleFlash.rot = self.muzzleDirection
	self.muzzleFlash.time = 0
end

function Player:select(colour)
	if #self.coloursSelected == 2 then
		self.coloursSelected[1] = self.coloursSelected[2]
		if colour == self.coloursSelected[2] then
			colour = nil -- Compact two identical colours into one
		end
		self.coloursSelected[2] = colour
	else
		table.insert(self.coloursSelected, colour)
	end
end

function Player:hasSelected(colour)
	return self.coloursSelected[1] == colour or self.coloursSelected[2] == colour
end

function Player:getColours()
	return unpack(self.coloursSelected)
end

function Player:markDestroyed()
	Object.markDestroyed(self)
	self.health = 0
end

function Player:onCollision(other, dx, dy, dt)
	if other.type == Object.floor then
		--print("player",dx,dy)
		if dy ~= 0 and self.velocityY >= 0 then -- Hit the floor below.
			--print("hit something", dx, dy)
			self:_updateState("walking")
			self.grounded = true
			self.velocityY = 0
		end
		self.shape:move(dx, dy)
	elseif other.type == Object.enemy then
		love.event.push("screenshake")
		self.health = self.health - dt
	end
end

function Player:onCollisionEnded(other)
	if other.type == Object.floor then
		-- A bit silly, but to avoid getting stuck between two flat floor
		-- tiles, we first check if there is a floor underneath the player
		-- before applying gravity.
		local x, y = self.shape:center()
		x, y = self.shape:support(x+1,y+1)
		for _,shape in ipairs(Object.collider:shapesAt(x, y+1)) do
			if shape.owner.type == Object.floor then
				-- There is floor underneath the player
				-- (to the far right)
				return
			end
		end

		self.grounded = false
	end
end

return Player
