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

local State = class("State")

function State:initialize()
end

function State:onEnter()
end

function State:onExit()
end

function State:update(dt)
end

function State:draw()
end

-- Includes mouse
function State:keypressed(key)
end

function State:textinput(t)
end

return State
