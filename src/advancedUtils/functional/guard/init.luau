--!strict
-- Guard.lua
-- Type-safe chainable guards with composition.

local Guard = {}

export type GuardFn<T> = (value: unknown) -> T

-- =========================================================
-- Primitive guards (asserting)
-- =========================================================

function Guard.string(value: unknown): string
	assert(type(value) == "string", "Expected string")
	return value
end

function Guard.fn(value: unknown): (...any) -> ...any
	assert(typeof(value) == "function", "expected fucntion")
	return value :: (...any) -> ...any
end

function Guard.color3(value: unknown): Color3
	assert(typeof(value) == "Color3", `Expected Color3, got {typeof(value)}`)
	return value :: Color3
end

function Guard.number(value: unknown): number
	assert(type(value) == "number", "Expected number")
	return value
end

function Guard.any(value: unknown): any
	return value
end

function Guard.boolean(value: unknown): boolean
	assert(type(value) == "boolean", "Expected boolean")
	return value
end

function Guard.table(value: unknown): {}
	assert(type(value) == "table", "Expected table")
	return value :: {}
end

function Guard.literal<T>(literal: T): GuardFn<T>
	return function(v: unknown)
		assert(literal == v, "not literal")
		return v :: any
	end
end

function Guard.enum<E>(enums: { E }): GuardFn<E & any>
	local hash = {} :: { [E]: true }
	for _, e in enums do
		hash[e] = true
	end
	return function(v: unknown): E
		local c = v :: E
		assert(hash[c], `Value '{tostring(v)}' is not a valid enum. Expected one of: {table.concat(enums, ", ")}`)
		return c
	end
end

function Guard.vector2(value: unknown): Vector2
	assert(typeof(value) == "Vector2", "Not a Vector2")
	return value
end

function Guard.vector3(value: unknown): Vector3
	assert(typeof(value) == "Vector3", "Not a vector3")
	return value
end

function Guard.cframe(value: unknown): CFrame
	assert(typeof(value) == "CFrame", "Not a cframe: " .. tostring(value))
	return value
end

function Guard.tweenInfo(value: unknown): TweenInfo
	assert(typeof(value) == "TweenInfo", "Not a vector3")
	return value
end

-- =========================================================
-- Guard composition
-- =========================================================

function Guard.optional<T>(g: GuardFn<T>): GuardFn<T | nil>
	return function(v: unknown): T | nil
		if v == nil then
			return nil
		end
		return g(v)
	end
end

function Guard.oneOf<T>(...: GuardFn<T>): GuardFn<T>
	local guards = { ... }
	return function(v: unknown): T
		for _, g in guards do
			local ok, res = pcall(g, v)
			if ok then
				return res :: T
			end
		end
		error("Value did not match any guard in union")
	end
end

function Guard.all<T>(...: GuardFn<T | any>): GuardFn<T>
	local guards = { ... }
	return function(v: unknown): T
		for _, g in ipairs(guards) do
			v = g(v)
		end
		return v :: T
	end
end

-- =========================================================
-- Map: key-value dictionary guard
-- =========================================================

function Guard.map<K, V>(guardKey: GuardFn<K>, guardValue: GuardFn<V>): GuardFn<{ [K]: V }>
	return function(v: unknown): { [K]: V }
		assert(type(v) == "table", "Expected table for map")

		local out = {} :: { [K]: V }

		for rawK, rawV in pairs(v :: any) do
			local k = guardKey(rawK)
			local val = guardValue(rawV)
			out[k] = val
		end

		return out
	end
end

function Guard.array<V>(guardValue: GuardFn<V>): GuardFn<{ V }>
	return Guard.map(Guard.number, guardValue)
end

function Guard.mapExcluding<K, V>(
	guardKey: GuardFn<K>,
	guardValue: GuardFn<V>,
	exludeKeys: { [any]: true }
): GuardFn<{ [K]: V }>
	return function(v: unknown): { [K]: V }
		local toTable = Guard.table(v)
		for rawK, rawV in toTable do
			if exludeKeys[rawK] then
				continue
			end
			guardKey(rawK)
			guardValue(rawV)
		end
		return toTable
	end
end

-- =========================================================
-- Property: validate a single property on a table
-- =========================================================

function Guard.property<T, P>(key: P, valueGuard: GuardFn<T>): GuardFn<{ [P]: T } & { [any]: any }>
	return function(v: unknown): any
		assert(type(v) == "table", "Expected table for property guard")

		local t = v :: any
		local raw = t[key]

		-- Run the guard and set the validated/coerced value
		t[key] = valueGuard(raw)

		return t
	end
end

-- =========================================================
-- Enum: validate value exists in set
-- =========================================================

function Guard.enumInSet<E>(hash: { [E]: any }): GuardFn<E>
	return function(e: unknown): E
		assert(e ~= nil, "Enum must not be nil")
		assert(hash[e :: E] ~= nil, `Value not in enum set`)
		return e :: E
	end
end

return Guard
