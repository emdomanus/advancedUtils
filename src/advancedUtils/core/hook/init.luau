--!strict
--!optimize 2
--!native

local Types = require(script.types)

export type Callback<T...> = Types.Callback<T...>
export type Hook<T...> = Types.Hook<T...>
export type HookImpl<T...> = Types.HookImpl<T...>

local HookClass = {}
HookClass.__index = HookClass

local function ensureStorage<T...>(
	self: Types.HookImpl<T...>
): ({ Callback<T...>? }, { number }, { [number]: number })
	local callbacks = self._callbacks
	local ids = self._ids
	local indicesById = self._indicesById

	if callbacks and ids and indicesById then
		return callbacks, ids, indicesById
	end

	callbacks = {}
	ids = {}
	indicesById = {}

	self._callbacks = callbacks
	self._ids = ids
	self._indicesById = indicesById

	return callbacks :: any, ids :: any, indicesById :: any
end

local function swapRemove<T...>(self: Types.HookImpl<T...>, index: number)
	local count = self._count
	local callbacks = self._callbacks :: { Callback<T...>? }
	local ids = self._ids :: { number }
	local indicesById = self._indicesById :: { [number]: number }

	local removedId = ids[index]
	indicesById[removedId] = nil

	if index ~= count then
		local movedCallback = callbacks[count]
		local movedId = ids[count]

		callbacks[index] = movedCallback
		ids[index] = movedId
		indicesById[movedId] = index
	end

	callbacks[count] = nil
	ids[count] = 0
	self._count = count - 1
	self._activeCount -= 1
end

local function compact<T...>(self: Types.HookImpl<T...>)
	local callbacks = self._callbacks
	local ids = self._ids
	local indicesById = self._indicesById

	if not callbacks or not ids or not indicesById then
		self._count = 0
		self._activeCount = 0
		self._dirty = false
		return
	end

	local count = self._count
	local writeIndex = 1

	for readIndex = 1, count do
		local callback = callbacks[readIndex]
		if callback then
			local id = ids[readIndex]

			callbacks[writeIndex] = callback
			ids[writeIndex] = id
			indicesById[id] = writeIndex
			writeIndex += 1
		end
	end

	for index = writeIndex, count do
		callbacks[index] = nil
		ids[index] = 0
	end

	self._count = writeIndex - 1
	self._activeCount = self._count
	self._dirty = false
end

function HookClass.new<T...>(): Types.Hook<T...>
	return setmetatable({
		_nextId = 1,
		_count = 0,
		_activeCount = 0,
		_firing = 0,
		_dirty = false,
	}, HookClass) :: any
end

function HookClass.add<T...>(self: Types.HookImpl<T...>, callback: Callback<T...>): number
	local callbacks, ids, indicesById = ensureStorage(self)
	local id = self._nextId
	self._nextId += 1

	local index = self._count + 1
	self._count = index
	callbacks[index] = callback
	ids[index] = id
	indicesById[id] = index
	self._activeCount += 1

	return id
end

function HookClass.remove<T...>(self: Types.HookImpl<T...>, id: number): boolean
	local indicesById = self._indicesById
	if not indicesById then
		return false
	end

	local index = indicesById[id]
	if not index then
		return false
	end

	if self._firing > 0 then
		local callbacks = self._callbacks :: { Callback<T...>? }
		local ids = self._ids :: { number }

		indicesById[id] = nil
		callbacks[index] = nil
		ids[index] = 0
		self._activeCount -= 1
		self._dirty = true
		return true
	end

	swapRemove(self, index)
	return true
end

function HookClass.fire<T...>(self: Types.HookImpl<T...>, ...: T...)
	if self._activeCount == 0 then
		return
	end

	self._firing += 1

	local callbacks = self._callbacks :: { Callback<T...>? }
	local count = self._count

	for index = 1, count do
		local callback = callbacks[index]
		if callback then
			callback(...)
		end
	end

	self._firing -= 1

	if self._firing == 0 and self._dirty then
		compact(self)
	end
end

function HookClass.clear<T...>(self: Types.HookImpl<T...>)
	local callbacks = self._callbacks
	local ids = self._ids
	local indicesById = self._indicesById

	if not callbacks or not ids or not indicesById then
		self._count = 0
		self._activeCount = 0
		self._dirty = false
		return
	end

	if self._firing > 0 then
		for index = 1, self._count do
			callbacks[index] = nil
			ids[index] = 0
		end

		table.clear(indicesById)

		self._activeCount = 0
		self._dirty = true
		return
	end

	table.clear(callbacks)
	table.clear(ids)
	table.clear(indicesById)

	self._count = 0
	self._activeCount = 0
	self._dirty = false
end

function HookClass.size<T...>(self: Types.HookImpl<T...>): number
	if self._dirty and self._firing == 0 then
		compact(self)
	end

	return self._activeCount
end

function HookClass.has<T...>(self: Types.HookImpl<T...>, id: number): boolean
	local indicesById = self._indicesById

	return indicesById ~= nil and indicesById[id] ~= nil
end

function HookClass.deconstruct<T...>(self: Types.HookImpl<T...>)
	self:clear()
end

return {
	new = HookClass.new :: <T...>() -> Types.Hook<T...>,
}
