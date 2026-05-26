--!strict
--!optimize 2
--!native

local TextUtils = {}

export type CompactNumberOptions = {
	decimals: number?,
	caps: boolean?,
}

local DEFAULT_DECIMALS = 3
local DEFAULT_CAPS = true

local SUFFIXES = { "", "K", "M", "B", "T", "Q", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function isLetter(character: string): boolean
	return string.match(character, "%a") ~= nil
end

local function trimTrailingZeros(text: string): string
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return text
end

local function roundToDecimals(value: number, decimals: number): number
	local multiplier = 10 ^ decimals
	return math.round(value * multiplier) / multiplier
end

function TextUtils.capitalizeWords(text: string): string
	local result = table.create(#text)
	local capitalizeNext = true

	for index = 1, #text do
		local character = string.sub(text, index, index)

		if capitalizeNext and isLetter(character) then
			character = string.upper(character)
			capitalizeNext = false
		elseif isLetter(character) then
			character = string.lower(character)
		end

		if character ~= "'" and not isLetter(character) then
			capitalizeNext = true
		end

		result[index] = character
	end

	return table.concat(result)
end

function TextUtils.capitalizeSentences(text: string): string
	local result = table.create(#text)
	local capitalizeNext = true

	for index = 1, #text do
		local character = string.sub(text, index, index)

		if isLetter(character) then
			if capitalizeNext then
				character = string.upper(character)
				capitalizeNext = false
			else
				character = string.lower(character)
			end
		end

		if character == "." or character == "!" or character == "?" then
			capitalizeNext = true
		end

		result[index] = character
	end

	return table.concat(result)
end

function TextUtils.formatCompactNumber(value: number, decimals: number?, caps: boolean?): string
	local tDecimals = math.max(0, math.floor(decimals or DEFAULT_DECIMALS))
	local tCaps = if caps == nil then DEFAULT_CAPS else caps

	if value ~= value then
		return "nan"
	end

	if value == math.huge then
		return "inf"
	end

	if value == -math.huge then
		return "-inf"
	end

	local absValue = math.abs(value)
	local sign = if value < 0 then "-" else ""

	local scale = 0
	while absValue >= 1000 and scale < #SUFFIXES - 1 do
		absValue /= 1000
		scale += 1
	end

	local rounded = roundToDecimals(absValue, tDecimals)
	if rounded >= 1000 and scale < #SUFFIXES - 1 then
		absValue /= 1000
		scale += 1
		rounded = roundToDecimals(absValue, tDecimals)
	end

	local numberText = trimTrailingZeros(string.format("%." .. tDecimals .. "f", rounded))
	local suffix = SUFFIXES[scale + 1]
	if not tCaps then
		suffix = string.lower(suffix)
	end

	return sign .. numberText .. suffix
end

return TextUtils
