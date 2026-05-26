--!strict
--!optimize 2
--!native

export type HeapEntry<T> = {
	priority: number,
	value: T,
}

export type MinHeap<T> = {
	_heap: { HeapEntry<T> },
	_indices: { [any]: number },

	push: (self: MinHeap<T>, priority: number, value: T) -> (),
	pop: (self: MinHeap<T>) -> (number?, T?),
	peek: (self: MinHeap<T>) -> (number?, T?),
	remove: (self: MinHeap<T>, value: T) -> boolean,
	size: (self: MinHeap<T>) -> number,
	deconstruct: (self: MinHeap<T>) -> (),
}

local MinHeap = {}
MinHeap.__index = MinHeap

local function swap<T>(heap: { HeapEntry<T> }, indices: { [any]: number }, i: number, j: number): ()
	local a = heap[i]
	local b = heap[j]
	heap[i] = b
	heap[j] = a
	indices[a.value] = j
	indices[b.value] = i
end

local function siftUp<T>(heap: { HeapEntry<T> }, indices: { [any]: number }, index: number): ()
	while index > 1 do
		local parent = index // 2
		if heap[parent].priority <= heap[index].priority then
			break
		end
		swap(heap, indices, parent, index)
		index = parent
	end
end

local function siftDown<T>(heap: { HeapEntry<T> }, indices: { [any]: number }, index: number): ()
	local heapSize = #heap
	while true do
		local left = index * 2
		local right = left + 1
		local smallest = index

		if left <= heapSize and heap[left].priority < heap[smallest].priority then
			smallest = left
		end
		if right <= heapSize and heap[right].priority < heap[smallest].priority then
			smallest = right
		end
		if smallest == index then
			break
		end

		swap(heap, indices, index, smallest)
		index = smallest
	end
end

function MinHeap.new<T>(): MinHeap<T>
	local self: MinHeap<T> = setmetatable({} :: any, MinHeap)
	self._heap = {}
	self._indices = {}
	return self
end

function MinHeap.push<T>(self: MinHeap<T>, priority: number, value: T): ()
	local existingIndex = self._indices[value]
	if existingIndex ~= nil then
		local entry = self._heap[existingIndex]
		local oldPriority = entry.priority
		entry.priority = priority
		if priority < oldPriority then
			siftUp(self._heap, self._indices, existingIndex)
		elseif priority > oldPriority then
			siftDown(self._heap, self._indices, existingIndex)
		end
		return
	end

	local entry: HeapEntry<T> = { priority = priority, value = value }
	local newIndex = #self._heap + 1
	self._heap[newIndex] = entry
	self._indices[value] = newIndex
	siftUp(self._heap, self._indices, newIndex)
end

function MinHeap.pop<T>(self: MinHeap<T>): (number?, T?)
	local heap = self._heap
	local heapSize = #heap
	if heapSize == 0 then
		return nil, nil
	end

	local root = heap[1]
	self._indices[root.value] = nil

	if heapSize == 1 then
		heap[1] = nil :: any
		return root.priority, root.value
	end

	local last = heap[heapSize]
	heap[heapSize] = nil :: any
	heap[1] = last
	self._indices[last.value] = 1
	siftDown(self._heap, self._indices, 1)

	return root.priority, root.value
end

function MinHeap.peek<T>(self: MinHeap<T>): (number?, T?)
	local root = self._heap[1]
	if root == nil then
		return nil, nil
	end
	return root.priority, root.value
end

function MinHeap.remove<T>(self: MinHeap<T>, value: T): boolean
	local index = self._indices[value]
	if index == nil then
		return false
	end

	local heap = self._heap
	local heapSize = #heap
	self._indices[value] = nil

	if index == heapSize then
		heap[heapSize] = nil :: any
		return true
	end

	local last = heap[heapSize]
	heap[heapSize] = nil :: any
	heap[index] = last
	self._indices[last.value] = index

	siftUp(heap, self._indices, index)
	siftDown(heap, self._indices, index)

	return true
end

function MinHeap.size<T>(self: MinHeap<T>): number
	return #self._heap
end

function MinHeap.deconstruct<T>(self: MinHeap<T>): ()
	table.clear(self._heap)
	table.clear(self._indices)
end

return MinHeap
