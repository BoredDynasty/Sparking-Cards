--!strict
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local random = require(ReplicatedStorage.Utility.random)

--[[
	url
	utility functions for encoding and decoding urls
]]

export type SpaceEncoding = "+" | "%20"

local function CHAR_TO_CODE(char: string): string
	return string.format("%%%02X", string.byte(char))
end

local function CODE_TO_CHAR(code: string): string
	return string.char(tonumber(code, 16) :: any)
end

-- modified from:
-- https://devforum.roblox.com/t/233570/2
local function DECODE(url: string): string
	return (string.gsub(string.gsub(url, "+", " "), "%%(%x%x)", CODE_TO_CHAR))
end

local function ENCODE(url: string, encode_spaces_as: SpaceEncoding?): string
	local space_encode_char = if encode_spaces_as == "+" then "+" else "%%20"
	local chars_encoded = (string.gsub(url, "([^%w _%%%-%.~])", CHAR_TO_CODE))
	local new_line_encoded = (string.gsub(chars_encoded, "\n", "\r\n"))

	return (string.gsub(new_line_encoded, "%s+", space_encode_char))
end

local url = {
	encode = ENCODE,
	decode = DECODE,
}

-- modified from: https://stackoverflow.com/questions/28916182/parse-parameters-out-of-url-in-lua
function url.read_query(url: string): { [string]: string }
	local query_tbl = {}

	for key, value: any in string.gmatch(DECODE(url), "([^&=?]-)=([^&=?]+)") do
		query_tbl[key] = value
	end
	return query_tbl
end

function url.queryify(t: { [string]: string }, encode_spaces_as: SpaceEncoding?): string
	local query_strings = {} :: { string }

	for key, value in t do
		local encoded_value = ENCODE(value, encode_spaces_as)
		local encoded_key = ENCODE(key, encode_spaces_as)
		table.insert(query_strings, `{encoded_key}={encoded_value}`)
	end
	return `?{table.concat(query_strings, "&")}`
end

function url.encodeNumber(num: number)
	--a simplified concept of Sqids (not a full implementation)
	local alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

	local encoded = ""

	repeat
		encoded = string.sub(alphabet, (num % #alphabet) + 1, (num % #alphabet) + 1) .. encoded

		num = math.floor(num / #alphabet)
	-- num = num // #alphabet
	until num == 0

	return encoded
end

function url.generateShortUniqueId()
	local timestamp = os.time()
	local randomNumber = random.integer(1, 9999)

	return url.encodeNumber(timestamp) .. url.encodeNumber(randomNumber)
end

return table.freeze(url)
