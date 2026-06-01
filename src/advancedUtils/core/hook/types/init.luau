--!strict
--!optimize 2
--!native

export type Callback<T...> = (T...) -> ()

export type Hook<T...> = {
	add: (self: any, callback: Callback<T...>) -> number,
	remove: (self: any, id: number) -> boolean,
	fire: (self: any, T...) -> (),
	clear: (self: any) -> (),
	size: (self: any) -> number,
	has: (self: any, id: number) -> boolean,
	deconstruct: (self: any) -> (),
}

export type HookHandle<T...> = Hook<T...>

export type HookImpl<T...> = Hook<T...> & {
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
