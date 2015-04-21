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

local Floor = class("Floor", Object)

Floor.static.step = 16

Floor.static.generateHeight = function(prev)
	--[[ Flat surface for collision problems:
	if true then
		if prev ~= nil and prev > 0 and love.math.random(1,10) >= 9 then
			return 0
		end
		return 16
	end--]]

	if prev == nil then -- Starting floor
		return 64
	elseif prev <= 0 then -- Previous was a gap
		return Floor.step * love.math.random(1,5)
	end

	local type = love.math.random(1,10)
	if type >= 9 then
		return 0 -- Gap
	else
		local change = love.math.random(1,5)
		if change == 1 or change == 5 then
			-- Greater chance getting a flat surface
			return prev
		elseif type >= 1 and type <= 4 then
			return prev - Floor.step * change
		else
			return prev + Floor.step * change
		end
	end

	--[[ More jagged and uneven:
	if prev == nil then -- Starting
		return 64
	elseif prev <= 0 then -- Previous was a gap
		return love.math.random(32, 54)
	else
		local rand = love.math.random(1,10)
		if rand >= 1 and rand <= 4 then
			return prev - love.math.random(0, 20)
		elseif rand >= 5 and rand <= 8 then
			return prev + love.math.random(0, 20)
		else
			return 0 -- Gap
		end
	end
	--]]
end

function Floor:initialize(shape)
	Object.initialize(self, Object.floor, shape)
end

return Floor
