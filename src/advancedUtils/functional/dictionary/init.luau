--!strict

local TableUtils = require(script.Parent.Parent.core.table)

local DictionaryUtils = {}

export type GuardFn<T> = (value: unknown) -> T
export type AmbiguouslyNested<K, V> = V | { [K]: AmbiguouslyNested<K, V> }

export type OptionalSource = {
	root: Instance?,
	label: string?,
	warnOnMissing: boolean?,
	includeSelf: boolean?,
}

export type FlatIdDictionary<V> = {
	complete: { [string]: AmbiguouslyNested<string, V> },
	flat: { [string]: V },
	fromId: { [number]: string },
	toId: { [string]: number },
}

export type LoadFlatIdDictionaryOptions<V> = {
	sources: { OptionalSource },
	guard: GuardFn<V>,
	delimiter: string?,
	leafKeyOnly: boolean?,
	debug: boolean?,
}

local function warnMissingSource(source: OptionalSource): ()
	if source.warnOnMissing == false then
		return
	end

	local label = source.label or "unknown source"
	warn(`[DictionaryUtils] Missing dictionary source: {label}`)
end

-- =========================================================
-- Crawl a Lua table into a nested structure
-- =========================================================

local function crawlTable<V>(
	t: { [unknown]: unknown },
	guardElem: GuardFn<V>,
	insertInto: { [string]: AmbiguouslyNested<string, V> },
	path: { string },
	debug: boolean?
)
	for k, v in pairs(t) do
		if type(k) ~= "string" then
			error(`[DictionaryUtils.crawl] Expected string key but got {type(k)} ({tostring(k)}) at path "{table.concat(path, "/")}"`)
		end

		table.insert(path, k)

		if debug then
			print(`[crawl] table key="{k}" path="{table.concat(path, "/")}" valueType={type(v)}`)
		end

		local ok, result = pcall(guardElem, v)
		if ok then
			if debug then
				print(`[crawl] ✓ guard passed at "{table.concat(path, "/")}"`)
			end
			insertInto[k] = result
		else
			if debug then
				print(`[crawl] ✗ guard failed at "{table.concat(path, "/")}" reason={result}, trying as nested table`)
			end
			if type(v) ~= "table" then
				error(`[DictionaryUtils.crawl] Value at "{table.concat(path, "/")}" is not a valid element and not a table (got {type(v)}). Guard error: {result}`)
			end
			local sub = {} :: { [string]: AmbiguouslyNested<string, V> }
			insertInto[k] = sub
			crawlTable(v :: any, guardElem, sub, path, debug)
		end

		table.remove(path)
	end
end

local function crawlInstance<V>(
	i: Instance,
	guardElem: GuardFn<V>,
	path: { string },
	debug: boolean?
): AmbiguouslyNested<string, V>

	if i:IsA("ModuleScript") then
		if debug then
			print(`[crawl] requiring ModuleScript "{table.concat(path, "/")}"`)
		end

		local ok, res = pcall(require, i)
		if not ok then
			error(`[DictionaryUtils.crawl] Failed to require ModuleScript at "{table.concat(path, "/")}": {res}`)
		end

		if debug then
			print(`[crawl] required "{table.concat(path, "/")}" got type={type(res)}`)
		end

		local elemOk, elemResult = pcall(guardElem, res)
		if elemOk then
			if debug then
				print(`[crawl] ✓ guard passed for module at "{table.concat(path, "/")} -> {tostring(elemResult)}"`)
			end
			return elemResult
		else
			if debug then
				print(`[crawl] ✗ guard failed for module at "{table.concat(path, "/")}" reason={elemResult}, crawling as table`)
			end
			if type(res) ~= "table" then
				error(`[DictionaryUtils.crawl] ModuleScript at "{table.concat(path, "/")}" returned {type(res)}, expected element or table. Guard error: {elemResult}`)
			end
			local out = {} :: { [string]: AmbiguouslyNested<string, V> }
			crawlTable(res :: { [unknown]: unknown }, guardElem, out, path, debug)
			return out
		end
	else
		if debug then
			print(`[crawl] instance "{table.concat(path, "/")}" is not a ModuleScript, crawling children`)
		end
		local out = {} :: { [string]: AmbiguouslyNested<string, V> }
		for _, child in ipairs(i:GetChildren()) do
			table.insert(path, child.Name)
			if debug then
				print(`[crawl] visiting child "{table.concat(path, "/")}"`)
			end
			out[child.Name] = crawlInstance(child, guardElem, path, debug)
			table.remove(path)
		end
		return out
	end
end

function DictionaryUtils.crawl<V>(
	root: Instance,
	guardElem: GuardFn<V>,
	includeSelf: boolean?,
	debug: boolean?
): { [string]: AmbiguouslyNested<string, V> }

	if debug then
		print(`[crawl] starting at root="{root.Name}" includeSelf={tostring(includeSelf)}`)
	end

	if includeSelf then
		local path = { root.Name }
		local out = {} :: { [string]: AmbiguouslyNested<string, V> }
		out[root.Name] = crawlInstance(root, guardElem, path, debug)
		return out
	else
		local out = {} :: { [string]: AmbiguouslyNested<string, V> }
		for _, child in ipairs(root:GetChildren()) do
			local path = { root.Name, child.Name }
			if debug then
				print(`[crawl] visiting top-level child "{child.Name}"`)
			end
			out[child.Name] = crawlInstance(child, guardElem, path, debug)
		end
		return out
	end
end

-- =========================================================
-- Find an optional child path without yielding
-- =========================================================

function DictionaryUtils.findChildPath(root: Instance?, path: { string }, label: string?): Instance?
	if not root then
		if label then
			warn(`[DictionaryUtils] Missing dictionary source root: {label}`)
		end
		return nil
	end

	local current: Instance = root
	for _, childName in path do
		local child = current:FindFirstChild(childName)
		if not child then
			if label then
				warn(`[DictionaryUtils] Missing dictionary source: {label}/{table.concat(path, "/")}`)
			end
			return nil
		end
		current = child
	end

	return current
end

-- =========================================================
-- Load optional sources into one merged nested dictionary
-- =========================================================

function DictionaryUtils.loadNested<V>(
	sources: { OptionalSource },
	guardElem: GuardFn<V>,
	debug: boolean?
): { [string]: AmbiguouslyNested<string, V> }
	local complete = {} :: { [string]: AmbiguouslyNested<string, V> }

	for _, source in sources do
		if source.root then
			local crawled = DictionaryUtils.crawl(source.root, guardElem, source.includeSelf, debug)
			complete = TableUtils.merge(complete, crawled)
		else
			warnMissingSource(source)
		end
	end

	return complete
end

-- =========================================================
-- Flatten a nested structure into a flat dict with delimited keys
-- =========================================================

local function flattenNested<V>(
	nested: AmbiguouslyNested<string, V>,
	guardElem: GuardFn<V>,
	delimiter: string,
	bucket: { [string]: V },
	path: { string },
	leafKeyOnly: boolean
)
	local elemOk, elem = pcall(guardElem, nested)
	if elemOk and elem ~= nil then
		local key = if leafKeyOnly then path[#path] else table.concat(path, delimiter)
		if key and key ~= "" then
			bucket[key] = elem
		end
		return
	end

	if type(nested) ~= "table" then
		return
	end

	for k, v in pairs(nested :: { [string]: AmbiguouslyNested<string, V> }) do
		table.insert(path, k)
		flattenNested(v, guardElem, delimiter, bucket, path, leafKeyOnly)
		table.remove(path)
	end
end

function DictionaryUtils.flattenNested<V>(
	nested: AmbiguouslyNested<string, V>,
	guardElem: GuardFn<V>,
	delimiter: string?,
	leafKeyOnly: boolean?
): { [string]: V }
	local tDelimiter = delimiter or "."
	local bLeafKeyOnly = leafKeyOnly or false
	local bucket = {} :: { [string]: V }
	local path = {} :: { string }
	flattenNested(nested, guardElem, tDelimiter, bucket, path, bLeafKeyOnly)
	return bucket
end

-- =========================================================
-- Convert a flat delimited dict back into nested structure
-- Keys are processed in sorted order for client/server consistency
-- =========================================================

function DictionaryUtils.nestFlattened<V>(
	flat: { [string]: V },
	delimiter: string?
): { [string]: AmbiguouslyNested<string, V> }
	local tDelimiter = delimiter or "."
	local root = {} :: { [string]: AmbiguouslyNested<string, V> }

	-- Sort keys alphabetically for deterministic order on client and server
	local keys = {} :: { string }
	for k in flat do
		table.insert(keys, k)
	end
	table.sort(keys)

	-- Build nested structure by iterating in sorted order
	for _, flatKey in ipairs(keys) do
		local value = flat[flatKey]
		local parts = string.split(flatKey, tDelimiter)

		local current = root :: any
		-- Navigate/create all intermediate tables
		for i = 1, #parts - 1 do
			local part = parts[i]
			if current[part] == nil then
				current[part] = {} :: any
			end
			current = current[part] :: any
		end

		-- Set the leaf value
		current[parts[#parts]] = value
	end

	return root
end

-- =========================================================
-- Create numeric ID mappings for flattened keys
-- Efficiently converts between string names and numeric IDs
-- Keys are sorted alphabetically for client/server consistency
-- =========================================================

function DictionaryUtils.createKeyIdMapping<V>(
	flat: { [string]: V }
): ({ [number]: string }, { [string]: number })
	local keys = {} :: { string }
	for k in flat do
		table.insert(keys, k)
	end
	table.sort(keys)

	local idToKey = {} :: { [number]: string }
	local keyToId = {} :: { [string]: number }

	for id, key in ipairs(keys) do
		idToKey[id] = key
		keyToId[key] = id
	end

	return idToKey, keyToId
end

-- =========================================================
-- Load, flatten, and build stable numeric ID mappings
-- =========================================================

function DictionaryUtils.loadFlatIdDictionary<V>(options: LoadFlatIdDictionaryOptions<V>): FlatIdDictionary<V>
	local complete = DictionaryUtils.loadNested(options.sources, options.guard, options.debug)
	local flat = DictionaryUtils.flattenNested(complete, options.guard :: any, options.delimiter, options.leafKeyOnly)
	local fromId, toId = DictionaryUtils.createKeyIdMapping(flat)

	return {
		complete = complete,
		flat = flat,
		fromId = fromId,
		toId = toId,
	} :: any
end

return DictionaryUtils
