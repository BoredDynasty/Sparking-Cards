local packer = {}

-- Types
type UInt128 = {
	low: number,
	high: number,
}

-- Estimate bits needed for a value
function packer.getBitSize(value: number): number
	assert(value >= 0, "Value must be non-negative")
	local bits = 0
	repeat
		value = math.floor(value / 2)
		bits += 1
	until value == 0
	return bits
end

--[[
```luau

local packer = require(path.to.packer)

-- Define schema: key = field name, value = bit width
local schema = {
	UserType = 2,      -- up to 3
	Level = 10,        -- up to 1023
	Health = 8,        -- up to 255
	Armor = 7,         -- up to 127
	CritChance = 6,    -- 0-63 (percent * 100 / 1.56)
}

-- Validate total bits
local totalBits = packer.getSchemaBitTotal(schema)
assert(totalBits <= 53, "Too many bits! Must stay under 53-bit safe integer range")
```
]]
function packer.getSchemaBitTotal(schema: { [string]: number }): number
	local total = 0
	for _, width in pairs(schema) do
		total += width
	end
	return total
end

--[[ 
64-bit generic packing
```luau
local packer = require(path.to.packer)

-- Define the bit widths per value
local widths = {8, 10, 14} -- Total = 32 bits

-- Values must be within range: 8-bit max is 255, 10-bit max is 1023, etc.
local values = {123, 512, 1023}

-- Pack them
local packed = packer.pack(values, widths)
print("Packed:", packed)

-- Unpack
local unpacked = packer.unpack(packed, widths)
print("Unpacked:", table.unpack(unpacked))
```
]]
function packer._packGeneric(values: { number }, widths: { number }): number
	local packed = 0
	local shift = 0
	for i, value in ipairs(values) do
		local width = widths[i]
		assert(value < 2 ^ width, `Value {value} exceeds width {width} at index {i}`)
		packed += value * 2 ^ shift
		shift += width
	end
	return packed
end
--[[ 
64-bit generic unpacking
```luau
local packer = require(path.to.packer)

-- Define the bit widths per value
local widths = {8, 10, 14} -- Total = 32 bits

-- Values must be within range: 8-bit max is 255, 10-bit max is 1023, etc.
local values = {123, 512, 1023}

-- Pack them
local packed = packer.pack(values, widths)
print("Packed:", packed)

-- Unpack
local unpacked = packer.unpack(packed, widths)
print("Unpacked:", table.unpack(unpacked))
```
]]
function packer._unpackGeneric(packed: number, widths: { number }): { number }
	local values = {}
	local shift = 0
	for _, width in ipairs(widths) do
		local mask = 2 ^ width - 1 -- gee i wonder what this is for
		local value = math.floor(packed / 2 ^ shift) % (2 ^ width)
		table.insert(values, value)
		shift += width
	end
	return values
end

--[[
Named field support
```luau
local packer = require(path.to.packer)

-- Data to encode
local playerData = {
	UserType = 1,
	Level = 512,
	Health = 255,
	Armor = 100,
	CritChance = 42
}

-- Pack data into one number
local packed = packer.packNamed(playerData, schema)
print("Packed value:", packed)

-- Unpack it
local decoded = packer.unpackNamed(packed, schema)
print("Decoded:")
for k, v in pairs(decoded) do
	print(k, v)
end
```
- You can store complex state in a single number (useful for compression, networking, DataStore keys).

- You can transmit multiple values over RemoteEvents as a single number.

- It helps you compact large tables into less memory and fewer keys.
]]
function packer.packNamed(data: { [string]: number }, schema: { [string]: number }): number
	local values, widths = {}, {}
	for key, width in pairs(schema) do
		assert(data[key] ~= nil, `Missing field {key}("key")`)
		table.insert(values, data[key])
		table.insert(widths, width)
	end
	return packer._packGeneric(values, widths)
end

--[[
Named field support
```luau
local packer = require(path.to.packer)

-- Data to encode
local playerData = {
	UserType = 1,
	Level = 512,
	Health = 255,
	Armor = 100,
	CritChance = 42
}

-- Pack data into one number
local packed = packer.packNamed(playerData, schema)
print("Packed value:", packed)

-- Unpack it
local decoded = packer.unpackNamed(packed, schema)
print("Decoded:")
for k, v in pairs(decoded) do
	print(k, v)
end
```
- You can store complex state in a single number (useful for compression, networking, DataStore keys).

- You can transmit multiple values over RemoteEvents as a single number.

- It helps you compact large tables into less memory and fewer keys.
]]
function packer.unpackNamed(packed: number, schema: { [string]: number }): { [string]: number }
	local widths, keys = {}, {}
	for key, width in pairs(schema) do
		table.insert(keys, key)
		table.insert(widths, width)
	end

	local unpacked = packer._unpackGeneric(packed, widths)
	local result = {}
	for i, key in ipairs(keys) do
		result[key] = unpacked[i]
	end
	return result
end

-- 128-bit Packing
function packer.pack128(values: { number }, widths: { number }): UInt128
	local result = { low = 0, high = 0 }
	local shift = 0

	for i, value in ipairs(values) do
		local width = widths[i]
		assert(value < 2 ^ width, `Value {value} exceeds width {width} at index {i}`)

		local chunk = value * 2 ^ shift
		if shift < 64 then
			result.low += chunk % 2 ^ 64
			result.high += math.floor(chunk / 2 ^ 64)
		else
			result.high += chunk / 2 ^ 64
		end

		shift += width
	end

	result.low = result.low % 2 ^ 64
	result.high = result.high % 2 ^ 64
	return result
end

function packer.unpack128(packed: UInt128, widths: { number }): { number }
	local result = {}
	local shift = 0

	for _, width in ipairs(widths) do
		local totalShift = shift
		local combined = packed.low + packed.high * 2 ^ 64
		local masked = math.floor(combined / 2 ^ totalShift) % 2 ^ width
		table.insert(result, masked)
		shift += width
	end

	return result
end

function packer.packNamed128(data: { [string]: number }, schema: { [string]: number }): UInt128
	local values, widths = {}, {}
	for key, width in pairs(schema) do
		table.insert(values, data[key])
		table.insert(widths, width)
	end
	return packer.pack128(values, widths)
end

function packer.unpackNamed128(packed: UInt128, schema: { [string]: number }): { [string]: number }
	local values = packer.unpack128(packed, table.pack(table.unpack(schema)))
	local result = {}
	local i = 1
	for key, _ in pairs(schema) do
		result[key] = values[i]
		i += 1
	end
	return result
end

-- Bitfield Visualizer
function packer.visualize(packed: number, width: number?): string
	width = width or 32
	local out = {}
	for i = width - 1, 0, -1 do
		table.insert(out, bit32.band(bit32.rshift(packed, i), 1))
	end
	return table.concat(out)
end

function packer.visualize128(packed: UInt128, width: number?): string
	width = width or 128
	local function toBits(n)
		local bits = {}
		for i = 63, 0, -1 do
			table.insert(bits, bit32.band(bit32.rshift(n, i), 1))
		end
		return table.concat(bits)
	end
	local highBits = toBits(packed.high)
	local lowBits = toBits(packed.low)
	return string.sub(highBits .. lowBits, -width)
end

return packer
