--!strict

-- NumberFormatter.lua
-- A universal number formatting module for Roblox
-- Supports: short / comma / dot / space
local abbreviation = {}
-- Suffix lookup table for short format
local suffixes = {
	{ value = 1e15, suffix = "Q" },
	{ value = 1e12, suffix = "T" },
	{ value = 1e9, suffix = "B" },
	{ value = 1e6, suffix = "M" },
	{ value = 1e3, suffix = "K" },
}

export type formatType = string | "short" | "comma" | "space" | "dot"

function abbreviation.ToShort(number: number)
	local absNum = math.abs(number)

	for i, data in ipairs(suffixes) do
		if absNum >= data.value then
			local formatted = string.format("%.1f", number / data.value)

			formatted = formatted:gsub("%.0$", "") -- remove trailing .0

			return formatted .. data.suffix
		end
	end

	return tostring(number)
end

function abbreviation.ToComma(number: number)
	local formatted = tostring(math.floor(number))

	while true do
		local newFormatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")

		formatted = newFormatted

		if k == 0 then
			break
		end
	end

	return formatted
end

function abbreviation.ToDot(number: number)
	local formatted = tostring(math.floor(number))

	while true do
		local newFormatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1.%2")

		formatted = newFormatted

		if k == 0 then
			break
		end
	end

	return formatted
end

function abbreviation.ToSpace(number: number)
	local formatted = tostring(math.floor(number))

	while true do
		local newFormatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1 %2")

		formatted = newFormatted

		if k == 0 then
			break
		end
	end

	return formatted
end

function abbreviation:Format(number: number, formatType: formatType)
	if type(number) ~= "number" then
		warn("invalid number input", tostring(number))

		return tostring(number)
	end

	formatType = string.lower(formatType or "short")

	if formatType == "short" then
		return abbreviation.ToShort(number)
	elseif formatType == "comma" then
		return abbreviation.ToComma(number)
	elseif formatType == "dot" then
		return abbreviation.ToDot(number)
	elseif formatType == "space" then
		return abbreviation.ToSpace(number)
	else
		warn("uknown format type:", formatType)

		return tostring(number)
	end
end
return abbreviation
