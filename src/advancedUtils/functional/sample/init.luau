--!strict
--!optimize 2
--!native

-- =========================
-- Types
-- =========================

export type CurveType = "uniform" | "bellCurve" | "skewLow" | "skewHigh"

export type SampleFn<T> = () -> T
export type Resolvable<T> = T | SampleFn<T>

export type RangeConfig = {
	min: number,
	max: number,
	curve: CurveType?,
	offset: number?,
}

export type OneOfConfig<T> = {
	values: { T },
	curve: CurveType?,
	offset: number?,
}

export type SampleShape<K, T> = { [K]: Resolvable<T> }

-- =========================
-- Seeded RNG
-- =========================

local _contextRng: (() -> number)? = nil

local function makeLcgRng(seed: number): () -> number
	local state = math.floor(seed) % (2 ^ 32)
	return function(): number
		state = (state * 1664525 + 1013904223) % (2 ^ 32)
		return state / (2 ^ 32)
	end
end

local function rngNext(): number
	if _contextRng then
		return _contextRng()
	end
	return math.random()
end

-- =========================
-- Internal
-- =========================

local function applyCurve(t: number, curve: CurveType, offset: number): number
	local o = math.clamp(offset, 0, 1)

	if curve == "uniform" then
		return t
	elseif curve == "bellCurve" then
		local bell = (rngNext() + rngNext()) / 2
		return math.clamp(bell + (o - 0.5), 0, 1)
	elseif curve == "skewLow" then
		local power = 1 + (1 - o) * 3
		return math.clamp(1 - (1 - t) ^ power, 0, 1)
	elseif curve == "skewHigh" then
		local power = 1 + o * 3
		return math.clamp(t ^ power, 0, 1)
	end

	return t
end

local function resolvedT(curve: CurveType?, offset: number?): number
	local raw = rngNext()
	return applyCurve(raw, curve or "uniform", offset or 0.5)
end

-- =========================
-- Module
-- =========================

local Sample = {}

function Sample.guardResolvable<T>(guard: (unknown) -> T): (unknown) -> Resolvable<T>
	return function(u: unknown): Resolvable<T>
		if type(u) == "function" then
			return u :: SampleFn<T>
		end
		return guard(u)
	end
end

function Sample.range(config: RangeConfig): SampleFn<number>
	return function()
		local t = resolvedT(config.curve, config.offset)
		return config.min + t * (config.max - config.min)
	end
end

function Sample.rangeInt(config: RangeConfig): SampleFn<number>
	return function()
		local t = resolvedT(config.curve, config.offset)
		return math.floor(config.min + t * (config.max - config.min + 1))
	end
end

function Sample.oneOf<T>(config: OneOfConfig<T>): SampleFn<T>
	assert(#config.values > 0, "Sample.oneOf requires at least one value")
	return function()
		local t = resolvedT(config.curve, config.offset)
		local index = math.clamp(math.floor(t * #config.values) + 1, 1, #config.values)
		return config.values[index]
	end
end

function Sample.resolve<T>(value: Resolvable<T>, seed: number?): T
	if type(value) == "function" then
		if seed ~= nil then
			local prev = _contextRng
			_contextRng = makeLcgRng(seed)
			local result = (value :: SampleFn<T>)()
			_contextRng = prev
			return result
		end
		return (value :: SampleFn<T>)()
	end
	return value :: T
end

function Sample.combine<K, T>(shape: SampleShape<K, T>): SampleFn<{ [K]: T }>
	return function()
		local result: { [K]: T } = {}
		for key, value in pairs(shape) do
			result[key] = Sample.resolve(value)
		end
		return result
	end
end

function Sample.intersection<T, U>(fn: SampleFn<T>, transform: (T) -> U): SampleFn<U>
	return function()
		return transform(fn())
	end
end

function Sample.merge<T>(a: SampleFn<{ [string]: T }>, b: SampleFn<{ [string]: T }>): SampleFn<{ [string]: T }>
	return function()
		local result: { [string]: T } = a()
		for k, v in pairs(b()) do
			result[k] = v
		end
		return result
	end
end

return Sample