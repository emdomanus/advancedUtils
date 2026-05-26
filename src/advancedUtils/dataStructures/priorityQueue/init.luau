--!strict
--!optimize 2
--!native

local MinHeap = require(script.Parent.minHeap)

export type PriorityQueue<T> = {
	_heap: MinHeap.MinHeap<T>,

	push: (self: PriorityQueue<T>, priority: number, value: T) -> (),
	pop: (self: PriorityQueue<T>) -> (number?, T?),
	peek: (self: PriorityQueue<T>) -> (number?, T?),
	remove: (self: PriorityQueue<T>, value: T) -> boolean,
	size: (self: PriorityQueue<T>) -> number,
	deconstruct: (self: PriorityQueue<T>) -> (),
}

local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue.new<T>(): PriorityQueue<T>
	local self: PriorityQueue<T> = setmetatable({} :: any, PriorityQueue)
	self._heap = MinHeap.new()
	return self
end

function PriorityQueue.push<T>(self: PriorityQueue<T>, priority: number, value: T): ()
	self._heap:push(priority, value)
end

function PriorityQueue.pop<T>(self: PriorityQueue<T>): (number?, T?)
	return self._heap:pop()
end

function PriorityQueue.peek<T>(self: PriorityQueue<T>): (number?, T?)
	return self._heap:peek()
end

function PriorityQueue.remove<T>(self: PriorityQueue<T>, value: T): boolean
	return self._heap:remove(value)
end

function PriorityQueue.size<T>(self: PriorityQueue<T>): number
	return self._heap:size()
end

function PriorityQueue.deconstruct<T>(self: PriorityQueue<T>): ()
	self._heap:deconstruct()
end

return PriorityQueue
