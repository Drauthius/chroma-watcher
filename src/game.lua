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
local collider = require("lib.hardoncollider")
local queue = require("lib.queue")

local State = require("src.state")

local Colour = require("src.colour")
local Enemy = require("src.enemy")
local Floor = require("src.floor")
local Object = require("src.object")
local Player = require("src.player")
local Projectile = require("src.projectile")

local Game = class("Game", State)

local function onCollide(dt, shapeOne, shapeTwo, dx, dy)
	shapeOne.owner:onCollision(shapeTwo.owner, dx, dy, dt)
end

local function onCollideEnded(dt, shapeOne, shapeTwo)
	shapeOne.owner:onCollisionEnded(shapeTwo.owner, dt)
end

function Game:_addFloors(flat)
	while self.nextFloor < self.camera.x + love.window.getWidth() do
		if flat ~= nil and flat > 0 then
			self.prevHeight = Floor.generateHeight(nil)
			flat = flat - 1
		else
			self.prevHeight = Floor.generateHeight(self.prevHeight)
		end
		local width
		if self.prevHeight > 0 then
			width = 32 * love.math.random(2,4)
			local floor = Floor:new(
				self.coll:addRectangle(
					self.nextFloor,
					love.window.getHeight()-self.prevHeight,
					width,
					self.prevHeight + 10))
			floor.right = self.nextFloor + width
			self.coll:setPassive(floor.shape)
			self.floors:pushBack(floor)
		else
			width = 32 * love.math.random(2,3)
		end
		self.nextFloor = self.nextFloor + width
	end
end

function Game:_addEnemies()
	-- Prevent "empty screens" and too many enemies.
	while self.lastEnemy > 5 or (self.lastEnemy > 0.15 and love.math.random(1,math.floor(self.enemyChance)) == 1) do
		local shape = math.random(1,#self.shapes.quads)
		local enemy = Enemy:new(
			self.shapes.image,
			self.shapes.quads[shape],
			self.shapes.particles:clone(),
			Colour.mix(love.math.random(1,4), love.math.random(1,4)),
			self.shapes.collisions[shape](
				self.camera.x + love.window.getWidth(),
				love.math.random(50, love.window.getHeight()-50)))
		enemy:setDeathSound(self.sounds.enemyDeath)
		self.coll:setPassive(enemy.shape)
		table.insert(self.objects, enemy)
		self.lastEnemy = 0
	end
end

function Game:initialize()
	-- Create the (animated) background image.
	self.background = {}
	self.background.image = love.graphics.newImage("gfx/backgrounds.png")
	local bgGrid = anim8.newGrid(940, 580, self.background.image:getDimensions())
	self.background.animation = anim8.newAnimation(bgGrid('1-2','1-3'), 0.5)

	self.actionbar = {
		bar = love.graphics.newImage("gfx/actionbar.png"),
		button = love.graphics.newImage("gfx/swatch.png")
	}

	self.defaultFont = love.graphics.newFont(12)
	self.scoreFont = love.graphics.newFont("ttf/Volter__28Goldfish_29.ttf", 20)

	-- Create the different enemy shapes.
	self.shapes = {}
	self.shapes.image = love.graphics.newImage("gfx/shapes.png")
	local sw, sh = self.shapes.image:getDimensions()
	self.shapes.quads = {}
	for i=1,7 do
		self.shapes.quads[i] = love.graphics.newQuad((i-1)*72, 0, 72, sh, sw, sh)
	end
	-- Smooth.
	local addCircle = function(x, y)
		return self.coll:addCircle(x + 38, y + 38, 34)
	end
	local addTriangle = function(x, y)
		return self.coll:addPolygon(x+30,y, x+60,y+60, x,y+60)
	end
	local addRectangle = function(x, y)
		return self.coll:addRectangle(x, y, 64, 64)
	end
	self.shapes.collisions = {
		addCircle,
		addCircle,
		addTriangle,
		addCircle,
		addCircle,
		addCircle,
		addRectangle
	}
	-- Create the particle system for the shapes death animation.
	self.shapes.particles = love.graphics.newParticleSystem(love.graphics.newImage("gfx/particle.png"), 128)
	self.shapes.particles:setSpeed(50, 450)
	self.shapes.particles:setAreaSpread("normal", 10, 10)
	self.shapes.particles:setParticleLifetime(2, 4)
	self.shapes.particles:setRotation(0, 3.14)
	self.shapes.particles:setSpin(0, 3.14)
	self.shapes.particles:setSizeVariation(1)
	self.shapes.particles:setSpinVariation(1)
	self.shapes.particles:setLinearAcceleration(-20, 10, 20, 100)

	self.sounds = {}
	self.sounds.projectileDeath = love.audio.newSource("sfx/89534__cgeffex__very-fast-bubble-pop1.mp3", "static")
	self.sounds.projectileDeath:setVolume(0.3)
	self.sounds.noColour = love.audio.newSource("sfx/142608__autistic-lucario__error.wav", "static")
	self.sounds.noColour:setVolume(0.3)
	self.sounds.enemyDeath = love.audio.newSource("sfx/265385__b-lamerichs__sound-effects-01-03-2015-8-pops-2.wav", "static")
	self.sounds.playerDeath = love.audio.newSource("sfx/50771__digital-system__boom-reverb.wav", "static")
	self.sounds.playerJump = love.audio.newSource("sfx/167045__drminky__slime-jump.wav", "static")
	self.sounds.playerShoot = love.audio.newSource("sfx/151022__bubaproducer__laser-shot-silenced.wav", "static")
	self.sounds.playerShoot:setVolume(0.2)
	self.sounds.shots = {
		self.sounds.playerShoot:clone(),
		self.sounds.playerShoot:clone(),
		self.sounds.playerShoot:clone(),
		self.sounds.playerShoot:clone(),
		self.sounds.playerShoot:clone()
	}
	self.sounds.music = love.audio.newSource("sfx/275713_Game_3_loop_test.mp3", "stream")
	self.sounds.music:setVolume(0.2)
	self.sounds.music:setLooping(true)
	self.sounds.music:play()

	-- Create the (animated) projectile image.
	self.projectiles = {}
	self.projectiles.image = love.graphics.newImage("gfx/projectile.png")
	local projectileGrid = anim8.newGrid(51, self.projectiles.image:getHeight(), self.projectiles.image:getDimensions())
	self.projectiles.animations = {
		flying = anim8.newAnimation(projectileGrid('1-1',1), 1, "pauseAtEnd"),
		colliding = anim8.newAnimation(projectileGrid('2-5',1), 0.07, "pauseAtEnd")
	}

	-- Create the collision system.
	self.coll = collider.new(64, onCollide, onCollideEnded)
	Object.static.collider = self.coll
end

function Game:onEnter()
	self.nextFloor = 0
	self.objects = {}
	self.floors = queue.new()

	self.coll:clear()

	self.enemyChance = 150 -- 1 in 150
	self.lastEnemy = 0
	self.exited = false

	self.player = Player:new(
		self.shapes.particles:clone(),
		self.coll:addRectangle(5, love.window.getHeight()-256, 60, 60))
	self.player.score = 0
	self.player:setDeathSound(self.sounds.playerDeath)
	self.player:setJumpSound(self.sounds.playerJump)
	self.camera = {
		x = 0,
		y = 0
	}

	self:_addFloors(5)
	self:_addEnemies()
end

function Game:onExit()
	self.exited = true
end

function Game:update(dt)
	if self.player:isFinished() and not self.exited then
		love.event.push("statechange", "highscore", self.player.score)
	elseif not self.player:isDestroyed() then
		-- Under the world
		-- (Player can start walking on an invisible platform down there?!)
		if select(2, self.player.shape:center())-38 > love.window.getHeight() then
			self.player:markDestroyed()
		end

		self.player.score = self.player.score + dt
	end

	self.background.animation:update(dt)

	self.player:update(dt)

	-- Update camera
	local px, py = self.player.shape:center()
	self.camera.x = px - 64
	local targetY = math.min(0,
		math.max(py - love.window.getHeight() + 128, -16))
	-- Smoothening
	if targetY > self.camera.y then
		self.camera.y = math.min(self.camera.y + dt * 50, targetY)
	else
		self.camera.y = math.max(self.camera.y - dt * 50, targetY)
	end

	if self.screenShake ~= nil and self.screenShake > 0 then
		self.screenShake = self.screenShake - dt
		self.camera.x = self.camera.x + love.math.random(-5, 5)
		self.camera.y = self.camera.y + love.math.random(-3, 3)
	end

	-- Update objects.
	local i = 1
	local len = #self.objects
	while i <= len do
		local obj = self.objects[i]
		obj:update(dt)
		if obj:isFinished() or (obj.shape:center())+200 < self.camera.x then
			self.coll:remove(obj.shape)
			self.objects[i] = self.objects[len]
			self.objects[len] = nil
			len = len - 1
		else
			i = i + 1
		end
	end

	-- Remove floor tiles that no longer are visible.
	if self.floors:front().right < self.camera.x then
		self.floors:popFront()
	end

	-- Add new floor tiles if required.
	self:_addFloors()
	-- Add new enemies.
	self:_addEnemies()
	self.lastEnemy = self.lastEnemy + dt
	-- Increase the chance a little every update.
	self.enemyChance = self.enemyChance - dt * 0.9

	-- Update the collision system (firing collision checks).
	self.coll:update(dt)
end

function Game:draw()
	-- Background
	do
		love.graphics.setColor(255, 255, 255, 255)
		local imgWidth = 940
		local offset = -(self.camera.x % imgWidth)
		self.background.animation:draw(self.background.image, offset, 0)
		self.background.animation:draw(self.background.image, offset + imgWidth, 0)
	end

	-- Objects
	do
		love.graphics.push()

		local x, y = self.player.shape:center()

		love.graphics.translate(-self.camera.x, -self.camera.y)

		-- Floor
		love.graphics.setColor(0, 0, 0, 255)
		for _,floor in self.floors:iterate() do
			floor:draw()
		end

		-- Player
		love.graphics.setColor(0, 255, 0)
		self.player:draw(self.camera.x, self.camera.y)

		-- Enemies & projectiles
		for _,obj in ipairs(self.objects) do
			obj:draw()
		end

		love.graphics.pop()
	end

	-- GUI
	do
		love.graphics.setFont(self.defaultFont)

		local margin = 17
		local padding = 5
		local size = 50
		local clrs = {
			{ 255, 0, 0 },
			{ 0, 255, 0 },
			{ 0, 0, 255 },
			{ 255, 255, 255 }
		}

		-- Colour buttons
		-- Background to avoid bleed through.
		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.rectangle("fill", 13, 10, self.actionbar.bar:getWidth()-6, self.actionbar.bar:getHeight())

		-- Action bar.
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(self.actionbar.bar, 10, 10)

		-- Action buttons.
		for i=1,4 do
			local left = margin + (i-1)*(size + padding)

			if self.player:hasSelected(i) then
				love.graphics.setColor(150, 150, 150)
			else
				love.graphics.setColor(0, 0, 0)
			end
			love.graphics.rectangle("fill", left, margin+1, size, size)
			love.graphics.setColor(100, 100, 100)
			love.graphics.rectangle("line", left, margin+1, size, size)

			love.graphics.setColor(clrs[i])
			love.graphics.draw(self.actionbar.button, left+3, margin+3)

			love.graphics.setColor(0, 0, 0)
			love.graphics.rectangle("fill", left + 1, margin+size-16, 12, 15)
			love.graphics.setColor(100, 100, 100)
			love.graphics.rectangle("line", left, margin+size-16, 12, 16)
			love.graphics.setColor(255, 255, 255)
			love.graphics.print(i, left + 2, margin+size-14)
		end

		-- HP text + bar
		local top = margin + size + padding + 8

		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.print("HP", margin, top)

		local left = margin + padding + 24
		local height = 12
		local width = margin + 3*(size + padding) + size - left

		love.graphics.setColor(50, 50, 50)
		love.graphics.rectangle("fill", left, top, width, height)
		love.graphics.setColor(100, 255, 100)
		love.graphics.rectangle("fill", left, top, width * (math.max(self.player.health,0)) / Player.maxHealth, height)
		if self.player.health > 0 then
			love.graphics.setColor(150, 150, 150)
		else
			love.graphics.setColor(255, 0, 0)
		end
		love.graphics.rectangle("line", left, top, width, height)

		-- Score
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.setFont(self.scoreFont)
		love.graphics.printf(math.floor(self.player.score), 0, 10, love.window.getWidth()-10, "right")
	end
end

function Game:keypressed(key, x, y)
	if self.player:isDestroyed() then
		return
	end

	if key == "mouse_l" then
		local colour = Colour.mix(self.player:getColours())
		if colour ~= nil then
			local startX, startY = self.player.shape:center()
			local weaponLength = 91 - 10 -- ( - kick)
			startX = startX + weaponLength * math.cos(self.player.muzzleDirection)
			startY = startY + weaponLength * math.sin(self.player.muzzleDirection) + 8

			local projectile = Projectile:new(
				self.projectiles.image,
				self.projectiles.animations,
				colour,
				self.player,
				self.coll:addCircle(startX, startY, 15))

			projectile:setTarget(self.camera.x + x, self.camera.y + y)
			projectile:setDeathSound(self.sounds.projectileDeath)
			table.insert(self.objects, projectile)

			self.player:shotFrom(startX, startY)
			for _,source in ipairs(self.sounds.shots) do
				if not source:isPlaying() then
					source:play()
					break
				end
			end
		else
			self.sounds.noColour:play()
		end
	elseif key == "mouse_r" then
		self.player:jump()
	elseif key == "1" or key == "2" or key == "3" or key == "4" then
		self.player:select(tonumber(key))
	end
end

function Game:screenshake()
	self.screenShake = 0.05
end

return Game
