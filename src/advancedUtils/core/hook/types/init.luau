--!strict
--!optimize 2
--!native

export type Callback<T...> = (T...) -> ()

export type HookHandle<T...> = {
	add: (self: any, callback: Callback<T...>) -> number,
	remove: (self: any, id: number) -> boolean,
	fire: (self: any, T...) -> (),
	clear: (self: any) -> (),
	size: (self: any) -> number,
	has: (self: any, id: number) -> boolean,
	deconstruct: (self: any) -> (),
}

export type Hook<T...> = HookHandle<T...> & {
	_nextId: number,
	_count: number,
	_activeCount: number,
	_firing: number,
	_dirty: boolean,
	_callbacks: { Callback<T...>? }?,
	_ids: { number }?,
	_indicesById: { [number]: number }?,
}

return {}
