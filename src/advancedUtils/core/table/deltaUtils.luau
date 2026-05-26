--!strict

local deltaUtils = {}

-- Exported type
export type DeltaChainEntry = {
	keys: { string },
	value: any?,
	keyIsString: { boolean },
}

function deltaUtils.getDif_NonNested<K, V>(base: { [K]: V }, compare: { [K]: V }): { [K]: V }
	local diff: { [K]: V } = {}
	for k, v in pairs(base) do
		if compare[k] ~= v :: V? then
			diff[k] = v
		end
	end
	return diff
end

function deltaUtils.getDif_Nested<K, V>(base: { [K]: V }, compare: { [K]: V }): { [K]: V }
	local diff: { [K]: V } = {}

	local seen = {}
	for k, v in pairs(base) do
		local other = compare[k]
		seen[k] = true
		if type(v) == "table" and type(other) == "table" then
			local subDiff = deltaUtils.getDif_Nested(v, other) :: any
			if next(subDiff) ~= nil then
				diff[k] = subDiff
			end
		elseif v :: V? ~= other then
			diff[k] = v
		end
	end
	-- Traverse compare to catch new keys
	for k, compVal in pairs(compare) do
		if not seen[k] then
			diff[k] = compVal
		end
	end

	return diff
end

function deltaUtils.flattenDiffToChains(
	diff: { [string | number]: any },
	parentKeys: { string }?,
	parentTypes: { boolean }?
): { DeltaChainEntry }
	local result: { DeltaChainEntry } = {}
	local keysAcc = parentKeys or {}
	local typeAcc = parentTypes or {}

	for key, value in pairs(diff) do
		local strKey = tostring(key)
		local isStringKey = typeof(key) == "string"

		local currentKeys = { table.unpack(keysAcc) }
		local currentTypes = { table.unpack(typeAcc) }

		table.insert(currentKeys, strKey)
		table.insert(currentTypes, isStringKey)

		if type(value) == "table" and next(value) ~= nil then
			local children = deltaUtils.flattenDiffToChains(value, currentKeys, currentTypes)
			for _, child in ipairs(children) do
				table.insert(result, child)
			end
		else
			table.insert(result, {
				keys = currentKeys,
				keyIsString = currentTypes,
				value = value,
			})
		end
	end

	return result
end

--[[
takes a key chain and sets the value at the end of the key chain to be the value param passed
]]
deltaUtils.ChainSet = function(t: { [any]: any }, keys: { any }, value: any)
	local current = t
	local curKeyIndex = 1
	while curKeyIndex < #keys do
		current = current[keys[curKeyIndex]]
		curKeyIndex += 1
	end
	current[keys[curKeyIndex]] = value
end

--[[
takes a key chain and sets the value at the end of the key chain to be the value param passed
]]
deltaUtils.ChainSetFusion = function(t: { [any]: any }, keys: { any }, value: any)
	local current = t
	local curKeyIndex = 1
	while curKeyIndex < #keys do
		current = current[keys[curKeyIndex]]
		curKeyIndex += 1
	end
	current[keys[curKeyIndex]]:set(value)
end

deltaUtils.UpdateWithDif = function(t: { [any]: any }, deltaChains: { DeltaChainEntry }, isFusion: boolean?)
	for _, v in deltaChains do
		local formatedKeys = v.keys :: { any }
		for i, isString in v.keyIsString do
			if not isString then
				formatedKeys[i] = tonumber(formatedKeys[i])
			end
		end
		if isFusion then
			deltaUtils.ChainSetFusion(t, formatedKeys, v.value)
		else
			deltaUtils.ChainSet(t, formatedKeys, v.value)
		end
	end
end

return deltaUtils
