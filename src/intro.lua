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

local State = require("src.state")
local Colour = require("src.colour")

local Intro = class("Intro", State)

function Intro:initialize()
	self.textFont = love.graphics.newFont("ttf/Volter__28Goldfish_29.ttf", 18)
	self.boldFont = love.graphics.newFont("ttf/Fipps-Regular.otf", 16)

	self.background = {
		image = love.graphics.newImage("gfx/backgrounds.png")
	}
	self.background.quad = love.graphics.newQuad(0, 0, 940, 580, self.background.image:getDimensions())
	self.logo = love.graphics.newImage("gfx/logo.png")
end

function Intro:draw()
	local windowWidth, windowHeight = love.window.getDimensions()

	love.graphics.setColor(255, 255, 255, 80)
	love.graphics.draw(self.background.image, self.background.quad, 0, 0)
	love.graphics.setColor(255, 255, 255, 255)

	love.graphics.draw(self.logo, (windowWidth-self.logo:getWidth())/2, 0)

	local leftColEnd = windowWidth/2-20
	love.graphics.setFont(self.boldFont)
	love.graphics.print("How to play:", 30, 120)
	love.graphics.setFont(self.textFont)
	love.graphics.printf([[
		Match colours to neutralize the radioactive shapes coming towards you. Don't let them touch you, and don't fall down.]],
		45, 170, leftColEnd - 45, "left")

	love.graphics.setFont(self.boldFont)
	love.graphics.print("Controls:", 30, 270)
	love.graphics.setFont(self.textFont)
	love.graphics.printf([[
		Combine up to two colours using the numbers 1, 2, 3 & 4.
		Press the same number twice to get the base colour.
		Use the left mouse button to shoot a coloured projectile.
		Use the right mouse button to jump.]],
		45, 320, leftColEnd - 45, "left")

	local rightCol = windowWidth/2+20
	love.graphics.setFont(self.boldFont)
	love.graphics.print("Story:", rightCol, 160)
	love.graphics.setFont(self.textFont)
	love.graphics.printf([[
		Radioactive waste is heading for the capitol. You, a soldiers of the Chroma Watch, need to neutralize as many of these "shapes" as possible, to minimize the loss of innocent lives. We're all counting on you.]],
		rightCol+15, 210, windowWidth-(rightCol+15), "left")

	love.graphics.setFont(self.boldFont)
	love.graphics.print("Colours:", rightCol, 330)
	love.graphics.setFont(self.textFont)
	local size = 30
	-- Don't look; madness follows.
	for i=1,3 do
		for j=i+1,4 do
			local x = rightCol+15
			local y
			if i ~= 1 then
				x = x + 220
				y = 265 + (i-1+j)*size/3 + (i+j-2)*size
			else
				y = 305 + (i+j)*size/3 + (i+j-1)*size
			end

			love.graphics.setColor(Colour.mix(i):getColour())
			love.graphics.circle("fill", x + size/2, y, size/2)

			x = x + size + 10
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.print("+", x, y - size/3)

			x = x + 40
			love.graphics.setColor(Colour.mix(j):getColour())
			love.graphics.circle("fill", x, y, size/2)

			x = x + size
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.print("=", x, y - size/3)

			x = x + 40
			love.graphics.setColor(Colour.mix(i,j):getColour())
			love.graphics.circle("fill", x, y, size/2)
		end
	end

	love.graphics.setFont(self.boldFont)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.printf("Press any key to start", 0, windowHeight - 75, windowWidth, "center")
	love.graphics.printf("Press ESC at any time to exit", 0, windowHeight - 45, windowWidth, "center")
end

function Intro:keypressed()
	love.event.push("statechange", "game")
end

return Intro
