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
local ROMAN_NUMERAL_CACHE: { [number]: string } = {}
local ROMAN_NUMERALS = {
	{ value = 50, label = "L" },
	{ value = 40, label = "XL" },
	{ value = 10, label = "X" },
	{ value = 9, label = "IX" },
	{ value = 5, label = "V" },
	{ value = 4, label = "IV" },
	{ value = 1, label = "I" },
}

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

function TextUtils.formatDisplayNumber(value: number, decimals: number?, integerThreshold: number?): string
	if value % 1 == 0 then
		return tostring(value)
	end

	if math.abs(value) >= (integerThreshold or 100) then
		return tostring(math.round(value))
	end

	local places = math.max(0, math.floor(decimals or 1))
	return trimTrailingZeros(string.format("%." .. places .. "f", value))
end

function TextUtils.formatDamageNumber(value: number): string
	return tostring(math.max(1, math.round(value)))
end

function TextUtils.formatRomanNumeral(value: number): string
	local rounded = math.max(math.floor(value), 0)
	if rounded <= 0 then
		return ""
	end

	local cached = ROMAN_NUMERAL_CACHE[rounded]
	if cached ~= nil then
		return cached
	end

	local remaining = rounded
	local parts = {}

	for _, numeral in ROMAN_NUMERALS do
		while remaining >= numeral.value do
			table.insert(parts, numeral.label)
			remaining -= numeral.value
		end
	end

	local result = table.concat(parts)
	ROMAN_NUMERAL_CACHE[rounded] = result
	return result
end

return TextUtils
