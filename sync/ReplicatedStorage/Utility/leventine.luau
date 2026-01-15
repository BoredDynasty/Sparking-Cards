--!native
--!strict

-- levintine
-- a port of fastest-levinstein to luau, with added functions for convenience
-- https://github.com/ka-weihe/fastest-levenshtein

type MapInfo = {
	case_sensitive: boolean?,
	min_score: number?,
}

-- sixty-five thousand five hundred and thirty-six
local PEQ = table.create(0x10000, 0)

local DEFAULT_MIN_SCORE = -math.huge

local function APPLY_CASE_SENSITIVITY(is_case_sensitive: boolean?, a: string, b: string): (string, string)
	if is_case_sensitive then
		return a, b
	else
		return string.lower(a), string.lower(b)
	end
end

local function GET_BYTES(s: string, len: number): { number }
	return { string.byte(s, 1, len) }
end

local function myers_32(a: string, b: string, a_len: number, b_len: number): number
	local lst = bit32.lshift(1, a_len - 1)
	local a_bytes = GET_BYTES(a, a_len)
	local b_bytes = GET_BYTES(b, b_len)
	local sc = a_len
	local pv = -1
	local mv = 0

	-- Set the bits for characters in string a
	for j, a_byte in a_bytes do
		PEQ[a_byte] = bit32.bor(PEQ[a_byte], bit32.lshift(1, j))
	end

	for _, byte in b_bytes do
		local eq = PEQ[byte]
		local xv = bit32.bor(eq, mv)
		local new_eq = bit32.bor(eq, bit32.bxor(bit32.band(eq, pv) + pv, pv))
		local mv2 = bit32.bor(mv, bit32.bnot(bit32.bor(new_eq, pv)))
		local pv2 = bit32.band(pv, new_eq)

		if bit32.band(mv2, lst) ~= 0 then
			sc += 1
		end

		if bit32.band(pv2, lst) ~= 0 then
			sc -= 1
		end

		local mv3 = bit32.bor(bit32.lshift(mv2, 1), 1)
		pv = bit32.bor(bit32.lshift(pv2, 1), bit32.bnot(bit32.bor(xv, mv3)))
		mv = bit32.band(mv3, xv)
	end

	-- Reset the PEQ array
	for _, a_byte in a_bytes do
		PEQ[a_byte] = 0
	end

	return sc
end

local function myers_x(b: string, a: string, a_len: number, b_len: number): number
	local h_size = math.ceil(a_len / 32)
	local v_size = math.ceil(b_len / 32)
	local phc = table.create(h_size, -1)
	local mhc = table.create(h_size, 0)
	local a_bytes = GET_BYTES(a, a_len)
	local b_bytes = GET_BYTES(b, b_len)
	local v_min = math.min(32, b_len)
	local j_outside = 1

	for j = 1, v_size - 1 do
		local previous_j = j - 1
		local v_len = (v_min + previous_j) * 32
		local start = previous_j * 32
		local pv = -1
		local mv = 0
		j_outside += 1

		-- Set the bits for characters in string b
		for k = start + 1, v_len, -start do
			local b_byte = b_bytes[k]
			PEQ[b_byte] = bit32.bor(PEQ[b_byte], bit32.lshift(1, k - start))
		end

		for index, byte in a_bytes do
			local index_32floor = (index // 32) + 1
			local index_32modulo = index % 32

			local phc_value = phc[index_32floor]
			local mhc_value = mhc[index_32floor]
			local eq = PEQ[byte]
			local pb = bit32.band(bit32.rshift(phc_value, index_32modulo), 1)
			local mb = bit32.band(bit32.rshift(mhc_value, index_32modulo), 1)
			local xv = bit32.bor(eq, mv)
			local xh =
				bit32.bor(bit32.bxor(bit32.band(bit32.bor(bit32.bor(eq, mb), pv), pv) + pv, pv), eq, mb)
			local ph = bit32.bor(mv, bit32.bnot(bit32.bor(xh, pv)))
			local mh = bit32.band(pv, xh)
			if bit32.bxor(bit32.rshift(ph, 31), pb) == 1 then
				phc[index_32floor] = bit32.bxor(phc_value, bit32.lshift(1, index_32modulo))
			end
			if bit32.bxor(bit32.rshift(mh, 31), mb) == 1 then
				mhc[index_32floor] = bit32.bxor(mhc_value, bit32.lshift(1, index_32modulo))
			end

			pv = bit32.bor(bit32.bor(bit32.lshift(mh, 1), mb), bit32.bnot(bit32.bor(xv, ph)))
			mv = bit32.band(bit32.bor(bit32.lshift(ph, 1), pb), xv)
		end

		-- Reset the PEQ array for the current block
		for k = start + 1, v_len do
			PEQ[b_bytes[k]] = 0
		end
	end

	local start = (j_outside - 1) * 32
	local v_len = math.min(32, b_len - start) + start
	local pv = -1
	local mv = 0

	-- Set the bits for characters in string b
	for k = start + 1, v_len, -start do
		local byte = b_bytes[k]
		PEQ[byte] = bit32.bor(PEQ[byte], bit32.lshift(1, k))
	end

	local score = b_len

	for index, byte in a_bytes do
		local index_32floor = (index // 32) + 1
		local index_32modulo = index % 32

		local phc_value = phc[index_32floor]
		local mhc_value = mhc[index_32floor]
		local eq = PEQ[byte]
		local pb = bit32.band(bit32.rshift(phc_value, index_32modulo), 1)
		local mb = bit32.band(bit32.rshift(mhc_value, index_32modulo), 1)
		local xv = bit32.bor(eq, mv)
		local xh = bit32.bor(bit32.bxor(bit32.band(bit32.bor(bit32.bor(eq, mb), pv), pv) + pv, pv), eq, mb)
		local ph = bit32.bor(mv, bit32.bnot(bit32.bor(xh, pv)))
		local mh = bit32.band(pv, xh)
		local b_subbed = b_len - 1
		score += bit32.band(bit32.rshift(ph, b_subbed), 1) - bit32.band(bit32.rshift(mh, b_subbed), 1)

		if bit32.bxor(bit32.rshift(ph, 31), pb) == 1 then
			phc[index_32floor] = bit32.bxor(phc_value, bit32.lshift(1, index_32modulo))
		end

		if bit32.bxor(bit32.rshift(mh, 31), mb) == 1 then
			mhc[index_32floor] = bit32.bxor(mhc_value, bit32.lshift(1, index_32modulo))
		end

		pv = bit32.bor(bit32.bor(bit32.lshift(mh, 1), mb), bit32.bnot(bit32.bor(xv, ph)))
		mv = bit32.band(bit32.bor(bit32.lshift(ph, 1), pb), xv)
	end

	-- Reset the PEQ array for the last block
	for k = start + 1, v_len do
		PEQ[b_bytes[k]] = 0
	end

	return score
end

--[[
	Scores `a` and `b` using levenstine distance to compare the strings
	```luau
	local score = leventine.score("meow", "mrrp")
	print(score) --> 4
	```
]]
local function score(a: string, b: string, case_sensitive: boolean?): number
	local a, b = APPLY_CASE_SENSITIVITY(case_sensitive, a, b)
	local a_len = #a
	local b_len = #b

	if a_len < b_len then
		a_len, b_len = b_len, a_len
		a, b = b, a
	end

	if b_len == 0 then
		return a_len
	elseif a_len <= 32 then
		return myers_32(a, b, a_len, b_len)
	else
		return myers_x(a, b, a_len, b_len)
	end
end

local leventine = {}

--[[
	Gives a copy of `t` sorted based on highest to lowest score when scored aginst `s`
	```luau
	local mapped = leventine.map("meow", { "mrrp", "mrow", "miaow" })
	print(table.concat(mapped, ", ")) --> "mrow, mrrp, miaow"
	```
]]
function leventine.map(s: string, t: { string }, info: MapInfo?): { string }
	local min_score = info and info.min_score or DEFAULT_MIN_SCORE
	local case_sensitive = info and info.case_sensitive or false
	local mapped = table.create(#t) :: { { string | number } }

	for index, ts in t do
		local score = (score(s, ts, case_sensitive))

		if score > min_score then
			mapped[index] = { score, ts } :: any
		end
	end

	table.sort(mapped, function(a, b)
		return a[1] < b[1]
	end)

	for index, info in mapped do
		mapped[index] = info[2] :: any
	end

	return mapped :: any
end

--[[
	Checks if `a` is a subsequence of `b`
	
	```luau
	local has_match = leventine.has_match("meow", "mrrp")
	print(has_match) --> false
	```
]]
function leventine.has_match(a: string, b: string, case_sensitive: boolean?): boolean
	local a, b = APPLY_CASE_SENSITIVITY(case_sensitive, a, b)
	local char_index: number? = 1

	for _, character in string.split(b) do
		char_index = string.find(a, character, char_index, true)

		if char_index then
			char_index += 1
		else
			return false
		end
	end
	return true
end

--[[
	Gives the closest string from `t` to `s`
	```luau
	local closest = leventine.closest("meow", { "mrrp", "mrow", "miaow" })
	print(closest) --> "mrow"
	```
]]
function leventine.closest(s: string, t: { string }, case_sensitive: boolean?): (string, number)
	local closest_score = math.huge
	local closest_string: string

	for _, ts in t do
		local score = score(s, ts, case_sensitive)

		if score < closest_score then
			closest_string = ts
			closest_score = score
		end
	end
	return closest_string, closest_score
end

leventine.score = score

return table.freeze(leventine)
