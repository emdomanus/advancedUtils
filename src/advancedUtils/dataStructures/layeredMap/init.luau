--!strict
--!optimize 2
--!native

local Types = require(script.types)

export type LayeredMap<K, V> = Types.LayeredMap<K, V>
export type EnsuredLayeredMap<K, V> = Types.EnsuredLayeredMap<K, V>
export type AllKeysCallback<K, V> = Types.AllKeysCallback<K, V>
export type KeyCallback<V> = Types.KeyCallback<V>
export type AllKeysCallbackEnsured<K, V> = Types.AllKeysCallbackEnsured<K, V>
export type KeyCallbackEnsured<V> = Types.KeyCallbackEnsured<V>

-- ============================================================================
-- CLASS
-- ============================================================================

local LayeredMap = {}
LayeredMap.__index = LayeredMap

function LayeredMap.new<K, V>(minLayer: number, maxLayer: number): LayeredMap<any, any>
	local self: LayeredMap<K, V> = setmetatable({}, LayeredMap) :: any

	self._layerRange = {
		min = minLayer,
		max = maxLayer,
	}

	self._layers = {}
	self._resolved = {}

	self._bindings = {
		allKeys = {},
		byKey = {},
	}

	return self
end

-- ============================================================================
-- HELPERS
-- ============================================================================

function LayeredMap._resolveKey<K, V>(self: LayeredMap<K, V>, key: K): V?
	local keyLayers = self._layers[key]
	if not keyLayers then
		return nil
	end

	for layer = self._layerRange.max, self._layerRange.min, -1 do
		local value = keyLayers[layer]
		if value ~= nil then
			return value
		end
	end

	return nil
end

function LayeredMap.forEachNonNil<K, V>(self: LayeredMap<K, V>, fn: (key: K, value: V) -> ()): ()
	for k, v in self._resolved do
		if not v then continue end
		fn(k, v)
	end
end

function LayeredMap._notifyKey<K, V>(self: LayeredMap<K, V>, key: K, newValue: V?)
	local prev = self._resolved[key]
	if prev == newValue then
		return
	end
	self._resolved[key] = newValue

	local byKey = self._bindings.byKey[key]
	if byKey then
		for cb in byKey do
			cb(newValue)
		end
	end

	for cb in self._bindings.allKeys do
		cb(key, newValue)
	end
end

-- ============================================================================
-- API
-- ============================================================================

function LayeredMap.set<K, V>(self: LayeredMap<K, V>, key: K, layer: number, value: V?)
	assert(
		layer >= self._layerRange.min and layer <= self._layerRange.max,
		`LayeredMap: layer {layer} out of range [{self._layerRange.min}, {self._layerRange.max}]`
	)

	local keyLayers
	local existingKeyLayers = self._layers[key]
	if existingKeyLayers then
		keyLayers = existingKeyLayers
	else
		keyLayers = {}
		self._layers[key] = keyLayers
	end

	keyLayers[layer] = value

	local newResolved = self:_resolveKey(key)
	self:_notifyKey(key, newResolved)
end

function LayeredMap.ensure<K, V>(self: LayeredMap<K, V>, ensurance: { [K]: V }): EnsuredLayeredMap<K, V>
	for key, value in ensurance do
		self:set(key, self._layerRange.min, value)
	end
	return self :: any
end

function LayeredMap.get<K, V>(self: LayeredMap<K, V>, key: K): V?
	return self._resolved[key]
end

function LayeredMap.watch<K, V>(
	self: LayeredMap<K, V>,
	key: K,
	callback: Types.KeyCallback<V>,
	runInitially: boolean?
): () -> ()
	local existingByKey = self._bindings.byKey[key]
	local byKey
	if existingByKey then
		byKey = existingByKey
	else
		byKey = {}
		self._bindings.byKey[key] = byKey
	end

	byKey[callback] = true

	if runInitially then
		callback(self._resolved[key])
	end

	return function()
		local bindings = self._bindings.byKey[key]
		if bindings then
			bindings[callback] = nil
			if not next(bindings) then
				self._bindings.byKey[key] = nil
			end
		end
	end
end

function LayeredMap.watchAllKeys<K, V>(
	self: LayeredMap<K, V>,
	callback: Types.AllKeysCallback<K, V>,
	runInitially: boolean?
): () -> ()
	self._bindings.allKeys[callback] = true

	if runInitially then
		for key, value in self._resolved do
			callback(key, value)
		end
	end

	return function()
		self._bindings.allKeys[callback] = nil
	end
end

function LayeredMap.deconstruct<K, V>(self: LayeredMap<K, V>)
	table.clear(self._layers)
	table.clear(self._resolved)
	table.clear(self._bindings.allKeys)
	table.clear(self._bindings.byKey)
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return LayeredMap
