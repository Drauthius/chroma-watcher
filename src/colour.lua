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

local Colour = class("Colour")

Colour.static.red = 1
Colour.static.green = 2
Colour.static.blue = 3
Colour.static.white = 4
Colour.static.whiteComponent = 255/2
Colour.static.colourComponent = 255

Colour.static.mix = function(colour1, colour2)
	if colour1 == nil then
		return nil
	end
	local colour = { Colour.whiteComponent, Colour.whiteComponent, Colour.whiteComponent }
	if colour1 == Colour.white then
		if colour2 ~= nil and colour2 ~= Colour.white then
			colour[colour2] = Colour.colourComponent
		else
			colour = { Colour.colourComponent, Colour.colourComponent, Colour.colourComponent }
		end
	elseif colour2 == Colour.white then
		colour[colour1] = Colour.colourComponent
	else
		colour = { 0, 0, 0 }
		colour[colour1] = Colour.colourComponent
		if colour2 ~= nil then
			colour[colour2] = Colour.colourComponent
		end
	end

	return Colour:new(colour)
end

function Colour:initialize(colour)
	self.colour = colour
end

function Colour:getColour()
	return self.colour
end

function Colour:__eq(other)
	return self:matches(other)
end

function Colour:matches(other)
	for i=1,3 do
		if self.colour[i] ~= other.colour[i] then
			return false
		end
	end
	return true
end

return Colour
