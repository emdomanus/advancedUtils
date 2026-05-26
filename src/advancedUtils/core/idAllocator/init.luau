--!strict

export type IdAllocator = {
	_min: number,
	_max: number,
	_next: number,
	_free: { number },
	_freeSet: { [number]: true },
	_allocated: { [number]: true },

	acquire: (self: IdAllocator) -> number?,
	claim: (self: IdAllocator, id: number) -> boolean,
	release: (self: IdAllocator, id: number) -> (),
	contains: (self: IdAllocator, id: number) -> boolean,
	isAllocated: (self: IdAllocator, id: number) -> boolean,
	deconstruct: (self: IdAllocator) -> (),
}

local IdAllocator = {}
IdAllocator.__index = IdAllocator

function IdAllocator.new(min: number, max: number): IdAllocator
	assert(max >= min, "IdAllocator: max must be >= min")
	return setmetatable({
		_min = min,
		_max = max,
		_next = min,
		_free = {},
		_freeSet = {},
		_allocated = {},
	}, IdAllocator) :: any
end

function IdAllocator:acquire(): number?
	while #self._free > 0 do
		local id = table.remove(self._free) :: number
		if self._freeSet[id] and not self._allocated[id] then
			self._freeSet[id] = nil
			self._allocated[id] = true
			return id
		end
	end

	while self._next <= self._max do
		local id = self._next
		self._next += 1
		if not self._allocated[id] then
			self._allocated[id] = true
			return id
		end
	end

	return nil
end

function IdAllocator:claim(id: number): boolean
	assert(self:contains(id), "IdAllocator: claimed id out of range")
	if self._allocated[id] then
		return false
	end

	self._freeSet[id] = nil
	self._allocated[id] = true
	return true
end

function IdAllocator:release(id: number)
	assert(self:contains(id), "IdAllocator: released id out of range")
	if not self._allocated[id] then
		warn(`IdAllocator: ignored release for unallocated id {id}`)
		return
	end

	self._allocated[id] = nil
	if self._freeSet[id] then
		return
	end

	self._freeSet[id] = true
	table.insert(self._free, id)
end

function IdAllocator:contains(id: number): boolean
	return id >= self._min and id <= self._max
end

function IdAllocator:isAllocated(id: number): boolean
	return self._allocated[id] == true
end

function IdAllocator:deconstruct()
	table.clear(self._free)
	table.clear(self._freeSet)
	table.clear(self._allocated)
end

return IdAllocator
