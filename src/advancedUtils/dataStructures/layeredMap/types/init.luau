--!strict
--!optimize 2
--!native

-- ============================================================================
-- TYPES
-- ============================================================================

export type AllKeysCallback<K, V> = (key: K, value: V?) -> ()
export type KeyCallback<V> = (value: V?) -> ()

export type AllKeysCallbackEnsured<K, V> = (key: K, value: V) -> ()
export type KeyCallbackEnsured<V> = (value: V) -> ()

-- Base — all internal state and write API, reads are generic over return nullability
export type LayeredMapBase<K, V> = {
	--// PRIVATE STATE
	_layerRange: {
		min: number,
		max: number,
	},
	_layers: { [K]: { [number]: V? }? },
	_resolved: { [K]: V? },

	--// BINDINGS
	_bindings: {
		allKeys: { [AllKeysCallback<K, V>]: true? },
		byKey: { [K]: { [KeyCallback<V>]: true? }? },
	},

	--// HELPERS
	_resolveKey: (self: LayeredMapBase<K, V>, key: K) -> V?,
	_notifyKey: (self: LayeredMapBase<K, V>, key: K, value: V?) -> (),

	--// WRITE API (shared by both variants)
	set: (self: LayeredMapBase<K, V>, key: K, layer: number, value: V?) -> (),
	forEachNonNil: (self: LayeredMapBase<K, V>, fn: (key: K, value: V) -> ()) -> (),

	deconstruct: (self: LayeredMapBase<K, V>) -> (),
}

-- Unensured — reads return V? (nullable), standard behavior
export type LayeredMap<K, V> = LayeredMapBase<K, V> & {
	get: (self: LayeredMap<K, V>, key: K) -> V?,
	watch: (self: LayeredMap<K, V>, key: K, callback: KeyCallback<V>, runInitially: boolean?) -> () -> (),
	watchAllKeys: (self: LayeredMap<K, V>, callback: AllKeysCallback<K, V>, runInitially: boolean?) -> () -> (),
	ensure: (self: LayeredMap<K, V>, ensurance: { [K]: V }) -> EnsuredLayeredMap<K, V>,
}

-- Ensured — reads return V (non-nil), callers are guaranteed a value exists
-- Achieved by seeding all keys with defaults at layer min before handing out
export type EnsuredLayeredMap<K, V> = LayeredMapBase<K, V> & {
	get: (self: EnsuredLayeredMap<K, V>, key: K) -> V,
	watch: (self: EnsuredLayeredMap<K, V>, key: K, callback: KeyCallbackEnsured<V>, runInitially: boolean?) -> () -> (),
	watchAllKeys: (
		self: EnsuredLayeredMap<K, V>,
		callback: AllKeysCallbackEnsured<K, V>,
		runInitially: boolean?
	) -> () -> (),
}

return {}
