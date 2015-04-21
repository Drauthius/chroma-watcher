local queue = {}

local function iter(q, i)
	i = i + 1
	if i <= q.last then
		return i, q[i]
	end
end

function queue.new()
	return setmetatable({first = 0, last = -1}, { __index = queue })
end

function queue:front()
	return self[self.first]
end

function queue:back()
	return self[self.last]
end

function queue:pushFront(value)
	local first = self.first - 1
	self.first = first
	self[first] = value
end

function queue:pushBack(value)
	local last = self.last + 1
	self.last = last
	self[last] = value
end

function queue:popFront()
	local first = self.first
	if first > self.last then
		error("queue is empty")
	end
	local value = self[first]
	self[first] = nil
	self.first = first + 1
	return value
end

function queue:popBack()
	local last = self.last
	if list.first > last then
		error("queue is empty")
	end
	local value = self[last]
	self[last] = nil
	self.last = last - 1
	return value
end

function queue:iterate()
	return iter, self, self.first - 1
end

function queue:len()
	return self.last + 1 - self.first
end

return queue
