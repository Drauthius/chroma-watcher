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

local Highscore = class("Highscore", State)

function Highscore:_save()
	self.highscore[self.pos][2] = self.entering
	self.pos = -1

	self.highscoreFile:open("w")
	for _,entry in ipairs(self.highscore) do
		self.highscoreFile:write(("%d %s\n"):format(entry[1], entry[2]))
	end
	self.highscoreFile:close()
end

function Highscore:initialize()
	self.bigFont = love.graphics.newFont("ttf/Volter__28Goldfish_29.ttf", 72)
	self.boldFont = love.graphics.newFont("ttf/Fipps-Regular.otf", 16)
	self.textFont = love.graphics.newFont("ttf/Volter__28Goldfish_29.ttf", 18)

	self.highscoreFile = love.filesystem.newFile("highscore")
	if love.filesystem.exists("highscore") then
		self.highscore = {}

		self.highscoreFile:open("r")
		for line in self.highscoreFile:lines() do
			local score, name = line:match("(%d+) (.*)")
			table.insert(self.highscore, { tonumber(score), name })
		end
		self.highscoreFile:close()
	else
		-- Some nice "goals"
		self.highscore = {
			{ 1000, "Legend" },
			{ 500, "Saviour" }
		}
	end

	self.credits = {
		{ "Programmer", "Albert Diserholt" },
		{ "Graphics", "Sunisa Thongdaengdee" },
		{ "", "" },
		{ "Created for Ludum Dare 32:" },
		{ '"An unconventional weapon"' },
		{ "" },
		{ "Music by howardt12345 @ newground.org" },
		{ "Sound effects from freesound.org by: Autistic Lucario, bubaproducer, DrMinky, B_Lamerichs, Digital System & CGEffex" }
	}
end

function Highscore:onEnter(score)
	self.time = 0
	self.score = math.floor(score)

	self.entering = ""

	self.pos = -1
	for i=1,#self.highscore do
		if self.highscore[i][1] < self.score then
			table.insert(self.highscore, i, { self.score, "" })
			self.pos = i
			break
		end
	end
	if self.pos == -1 then
		table.insert(self.highscore, { self.score, "" })
		self.pos = #self.highscore
	end

	for i=10,#self.highscore do
		self.highscore[i] = nil
	end
	if self.pos >= 10 then
		self.pos = -1
		self.entering = nil
	end
end

function Highscore:update(dt)
	self.time = self.time + dt
end

function Highscore:draw()
	local windowWidth, windowHeight = love.window.getDimensions()

	love.graphics.setColor(0, 0, 0, math.min(self.time*125, 125))
	love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)

	love.graphics.setColor(255, 255, 255, math.min(self.time*125, 255))
	love.graphics.setFont(self.bigFont)
	love.graphics.printf("Game over", 0, 20, windowWidth, "center")
	love.graphics.setFont(self.textFont)
	love.graphics.printf("Your score was "..self.score, 0, 100, windowWidth, "center")

	love.graphics.setFont(self.boldFont)
	love.graphics.setColor(255, 255, 255, math.min(self.time*125, 255))
	if self.entering == nil then
		love.graphics.printf("Press any key to continue", 0, windowHeight - 75, windowWidth, "center")
	else
		love.graphics.printf("Type in your name and press Enter", 0, windowHeight - 75, windowWidth, "center")
	end
	love.graphics.printf("Press ESC at any time to exit", 0, windowHeight - 45, windowWidth, "center")

	if self.time >= 1.5 then
		love.graphics.setColor(255, 255, 255, 255)

		love.graphics.setFont(self.boldFont)
		love.graphics.print("High score:", 30, 120)

		local rightCol = love.window.getWidth()/2 + 20
		love.graphics.setFont(self.boldFont)
		love.graphics.print("Credits:", rightCol, 120)

		love.graphics.setFont(self.textFont)
		local advance = math.floor(((self.time - 1.5) * 10) / 5)
		local info = false
		for i=1,math.min(advance,9) do
			local y = 170 + (i-1)*25
			if self.highscore[i] then
				love.graphics.print(i, 45, y)
				love.graphics.printf(self.highscore[i][1], 60, y, 100, "right")
				if self.pos == i then
					love.graphics.print(self.entering, 200, y)
					if math.floor(self.time * 10) % 2 == 0 then
						local width = self.textFont:getWidth(self.entering)
						local oneWidth = self.textFont:getWidth("w")
						if #self.entering == 10 then
							width = width - oneWidth
						end
						love.graphics.rectangle("fill",
							200 + width,
							y + self.textFont:getHeight()-1,
							oneWidth+1,
							4)
					end
				else
					love.graphics.print(self.highscore[i][2], 200, y)
				end
			end

			if self.credits[i] then
				if self.credits[i][1] == "" then
					info = true
				end

				if not info then
					love.graphics.printf(self.credits[i][1], rightCol+15, y, 100, "right")
					love.graphics.print(self.credits[i][2], rightCol+15+140, y)
				else
					love.graphics.printf(self.credits[i][1], rightCol+15, y, windowWidth - rightCol - 15, "center")
				end
			end
		end
	end
end

function Highscore:textinput(t)
	if self.entering == nil then
		love.event.push("statechange", "intro")
	else
		self.entering = string.sub(self.entering, 1, 9) .. t
	end
end

function Highscore:keypressed(key)
	if self.entering == nil then
		love.event.push("statechange", "intro")
	else
		if key == "backspace" then
			self.entering = self.entering:sub(1, #self.entering-1)
		elseif key == "return" or key == "enter" then
			self:_save()
			self.entering = nil
		end
	end
end

return Highscore
