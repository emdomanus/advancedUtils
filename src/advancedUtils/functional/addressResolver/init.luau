--!strict
--!optimize 2
--!native

local Types = require(script.types)

export type PathNode<PathKey> = Types.PathNode<PathKey>
export type AddressConfig<PathKey> = Types.AddressConfig<PathKey>
export type AddressResolver<PathKey> = Types.AddressResolver<PathKey>
export type OffsetNode = Types.OffsetNode

--==============================================================
-- INTERNAL: Build a nested offset tree
--==============================================================
-- Every node stores its own offset + quantity (total span),
-- so parent lookups are O(depth) with no string work.

local function buildOffsetTree<PathKey>(node: PathNode<PathKey>, currentOffset: number): OffsetNode
	local children: { [string]: OffsetNode } = {}
	local offset = currentOffset

	for key, value in pairs(node) do
		local keyStr = tostring(key)

		if type(value) == "number" then
			-- Leaf: N slots, no children
			children[keyStr] = {
				offset = offset,
				quantity = value,
				children = nil,
			}
			offset += value
		elseif type(value) == "table" then
			-- Branch: recurse, child tracks its own span
			local child = buildOffsetTree(value :: PathNode<PathKey>, offset)
			children[keyStr] = child
			offset += child.quantity
		end
	end

	return {
		offset = currentOffset,
		quantity = offset - currentOffset,
		children = children,
	}
end

--==============================================================
-- INTERNAL: Walk the tree by key segments
--==============================================================

local function walkTree(root: OffsetNode, args: { any }, count: number): OffsetNode
	local current = root
	for i = 1, count do
		local children = current.children
		assert(children, `expected branch node, got leaf`)
		local key = tostring(args[i])
		local next = children[key]
		assert(next, `unrecognized key: {key}`)
		current = next
	end
	return current
end

--==============================================================
-- PROTOTYPE
--==============================================================

local AddressResolver = {}
AddressResolver.__index = AddressResolver

--==============================================================
-- CONSTRUCTOR
--==============================================================

function AddressResolver.new<PathKey>(config: Types.AddressConfig<PathKey>): AddressResolver<PathKey>
	local self: AddressResolver<PathKey> = setmetatable({}, AddressResolver) :: any

	self.config = config

	if type(config.root) == "number" then
		self._isBareRoot = true
		self._rootNode = {
			offset = 0,
			quantity = config.root,
			children = nil,
		}
		self._totalSize = config.root
	else
		self._isBareRoot = false
		local tree = buildOffsetTree(config.root :: PathNode<PathKey>, 0)
		self._rootNode = tree
		self._totalSize = tree.quantity
	end

	return self
end

--==============================================================
-- resolve(...path, leafIndex) -> flat address
--==============================================================

function AddressResolver.resolve<PathKey>(self: AddressResolver<PathKey>, ...: PathKey | number): number
	local args = { ... }

	-- ✅ Handle bare root (no path, just index)
	if self._isBareRoot then
		assert(#args == 1, "bare root resolver expects exactly 1 argument (the index)")
		local index = args[1]
		assert(type(index) == "number", "argument must be a number")
		assert(
			index >= 0 and index < self._rootNode.quantity,
			`index {index} out of range [0, {self._rootNode.quantity})`
		)
		return index
	end

	assert(#args >= 1, "resolve requires at least one argument")

	local current = self._rootNode

	for i = 1, #args do
		local arg = args[i]
		local keyStr = tostring(arg)
		local children = current.children

		-- If this arg matches a child key, walk into it
		if children and children[keyStr] then
			current = children[keyStr]

		-- Otherwise it must be a numeric leaf index and the last arg
		elseif type(arg) == "number" then
			assert(i == #args, "leaf index must be the last argument")
			assert(not children, "numeric index does not match any child key")
			assert(arg >= 0 and arg < current.quantity, `leaf index {arg} out of range [0, {current.quantity})`)
			return current.offset + arg
		else
			error(`unrecognized key: {keyStr}`)
		end
	end

	-- All args were path keys — return the node's base offset
	return current.offset
end

--==============================================================
-- toPath(address) -> { key, key, ..., localIndex }
--==============================================================

function AddressResolver.toPath<PathKey>(self: AddressResolver<PathKey>, address: number): Types.AddressPath<PathKey>?
	assert(address >= 0 and address < self._totalSize, "address out of range")

	if self._isBareRoot then
		return { address }
	end

	local result: Types.AddressPath<PathKey> = {}
	local current = self._rootNode

	while current.children do
		local found = false
		for key, child in pairs(current.children) do
			if address >= child.offset and address < child.offset + child.quantity then
				local asNumber = tonumber(key)
				result[#result + 1] = asNumber or key :: any
				current = child
				found = true
				break
			end
		end
		assert(found, `could not resolve address: {address}`)
	end

	-- Append local leaf index
	result[#result + 1] = address - current.offset
	return result
end

--==============================================================
-- getRange(...path) -> min, max
-- Works at ANY depth: getRange("formInnate") returns the
-- full span, getRange("weapon", 1) returns weapon 1's span, etc.
--==============================================================

function AddressResolver.getRange<PathKey>(self: AddressResolver<PathKey>, ...: PathKey | number): (number, number)
	local args = { ... }

	if self._isBareRoot then
		assert(#args == 0, "bare root getRange expects no arguments")
		return 0, self._rootNode.quantity - 1
	end

	assert(#args >= 1, "getRange requires at least one path key")

	local node = walkTree(self._rootNode, args, #args)
	return node.offset, node.offset + node.quantity - 1
end

--==============================================================

function AddressResolver.getTotalSize<PathKey>(self: AddressResolver<PathKey>): number
	return self._totalSize
end

return AddressResolver
