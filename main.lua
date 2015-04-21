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

local Intro = require("src.intro")
local Game = require("src.game")
local Highscore = require("src.highscore")

gDebug = false

local states
local currentState

function love.load()
	-- Change the cursor.
	local cursor = love.mouse.newCursor("gfx/crosshair.png", 15, 16)
	love.mouse.setCursor(cursor)

	-- Create the states.
	states = {
		intro = Intro:new(),
		game = Game:new(),
		highscore = Highscore:new()
	}
	-- Enter the 'Intro' state.
	currentState = states.intro
	currentState:onEnter()
end

function love.update(dt)
	if currentState == states.highscore then
		states.game:update(dt)
	end
	currentState:update(dt)
end

function love.draw()
	if currentState == states.highscore then
		states.game:draw()
	end
	currentState:draw()
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	elseif key == "tab" then
		gDebug = not gDebug
	else
		-- Only current state gets event.
		currentState:keypressed(key)
	end
end

function love.textinput(t)
	currentState:textinput(t)
end

function love.mousepressed(x, y, button)
	-- Only current state gets event.
	currentState:keypressed("mouse_"..button, x, y)
end

function love.handlers.statechange(nextState, arg)
	currentState:onExit()
	currentState = states[nextState]
	currentState:onEnter(arg)
end

function love.handlers.screenshake()
	states.game:screenshake()
end
