--!strict

local GuardUtils = require(script.Parent.Parent.functional.guard)

type GuardFn<T> = GuardUtils.GuardFn<T>

--// dutils
local deltaUtils = require(script:WaitForChild("deltaUtils"))

local TableUtils = {}

-- Type alias for generic table
export type AnyTable = { [any]: any }
export type NestedValueOrTable<K, V> = V | { [K]: NestedValueOrTable<K, V> }
export type NestedTable<K, V> = { [K]: NestedValueOrTable<K, V> }
export type DeltaChainEntry = deltaUtils.DeltaChainEntry

-- Deepcopy helper (internal use only)
local function deepcopyHelper<K, V>(orig: { [K]: V }): { [K]: V }
	local copy: { [K]: V } = {}
	for k, v in pairs(orig) do
		if type(v) == "table" then
			copy[k] = deepcopyHelper(v :: any) :: any
		else
			copy[k] = v
		end
	end
	return copy
end

function TableUtils.invert<K, V>(t: { [K]: V }): { [V]: K }
	local inverted = {}
	for k, v in t do
		inverted[v] = k
	end
	return inverted
end

function TableUtils.toSet<T>(array: { T }): { [T]: true }
	local set = {}
	for _, value in array do
		set[value] = true
	end
	return set :: any
end

-- Shuffle a shallow array table
function TableUtils.shuffle<T>(array: { T }): { T }
	local shuffled: { T } = TableUtils.shallowcopy(array)
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end
	return shuffled
end

-- Deep copy a nested table
function TableUtils.deepcopy<T>(t: T): T
	if type(t) ~= "table" then
		return t
	end
	return (deepcopyHelper(t) :: any) :: T
end

-- Shallow copy a table (1 level)
function TableUtils.shallowcopy<T>(t: { T }): { T }
	return table.clone(t)
end

-- Reconcile a table.
function TableUtils.reconcile<T>(target: AnyTable, template: T & AnyTable): T
	for k, v in pairs(template) do
		if type(k) == "string" then
			if target[k] == nil then
				if type(v) == "table" then
					target[k] = TableUtils.deepcopy(v)
				else
					target[k] = v
				end
			elseif type(target[k]) == "table" and type(v) == "table" then
				TableUtils.reconcile(target[k], v)
			end
		end
	end
	return (target :: any) :: T
end

function TableUtils.coalesce<K, V>(base: { [K]: V }, orderdSorces: { { [K]: V? } }): { [K]: V }
	local n: { [K]: V } = TableUtils.deepcopy(base)

	local coalescedKeys: { [K]: boolean } = {}

	for _, source in orderdSorces do
		for k, v in source do
			if not coalescedKeys[k] then
				coalescedKeys[k] = true
				n[k] = v :: V
			end
		end
	end

	return n
end

-- Merge two tables shallowly
function TableUtils.merge<T1, T2>(t1: T1 & {}, t2: T2 & {}): T1 & T2
	local merged: T1 & T2 & { [any]: any } = {} :: any

	local function merge(target: any, source: any)
		for key, value in source do
			if type(value) == "table" and type(target[key]) == "table" then
				-- Both are tables, recursively merge
				target[key] = merge(target[key], value)
			else
				-- Overwrite or add new value
				target[key] = value
			end
		end
		return target
	end

	-- Start with a copy of t1
	for key, value in t1 :: {} do
		if type(value) == "table" then
			(merged :: { any })[key :: any] = TableUtils.deepcopy(value) -- avoid mutating original
		else
			(merged :: { any })[key :: any] = value
		end
	end

	-- Merge t2 into the copy
	return merge(merged, t2)
end

function TableUtils.append<T>(...: { T }): { T }
	local result: { T } = {}
	for _, t in { ... } do
		for _, v in t do
			table.insert(result, v)
		end
	end
	return result
end

function TableUtils.getOrCreate<K, V>(subj: { [K]: V? }, key: K, default: V): V
	if not subj[key] then
		subj[key] = default
	end
	return subj[key] :: V
end

function TableUtils.mergeInto<T1, T2>(target: T1 & {}, source: T2 & {}): T1 & T2
	local cTarget: any = target :: any
	for k, v in source :: { [any]: any } do
		cTarget[k] = v
	end

	return cTarget
end

local function mapNestedHelper<K, V>(
	subj: NestedTable<K, V>,
	leafOperation: (path: { K }, value: V) -> (),
	guardValue: GuardFn<V>,
	path: { K }
): ()
	for k, v in subj do
		local idx = rawlen(path) + 1
		rawset(path, idx, k)
		local isLeaf, leaf = pcall(guardValue, v)
		if isLeaf then
			leafOperation(path, leaf)
		else
			mapNestedHelper(v :: any, leafOperation, guardValue, path)
		end
		rawset(path, idx, nil :: any)
	end
end

function TableUtils.mapNested<K, V>(
	base: NestedTable<K, V>,
	leafOperation: (path: { K }, value: V) -> (),
	guardValue: GuardFn<V>
): ()
	mapNestedHelper(base, leafOperation, guardValue, {})
end

function TableUtils.hashIsEmpty(hash: { [any]: any }): boolean
	for _, _ in hash do
		return false
	end
	return true
end

TableUtils.deltaUtils = deltaUtils

return TableUtils
