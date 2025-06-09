--!strict

--[[
    operations for dictionaries and perhaps arrays.
    written by Dynasty
--]]

local function copy<T>(t: T, deep: boolean?): T
	if not deep then
		return (table.clone(t :: any) :: any) :: T
	end
	local function DeepCopy(tbl: { any })
		local tCopy = table.clone(tbl)
		for k, v in tCopy do
			if type(v) == "table" then
				tCopy[k] = DeepCopy(v)
			end
		end
		return tCopy
	end
	return DeepCopy(t :: any) :: T
end

local function findKeyIndex(tbl: { any }, keyToFind: any): number?
	local index = 1
	for key, _ in pairs(tbl) do
		if key == keyToFind then
			return index
		end
		index = index + 1
	end
	return nil
end

local function findKey(tbl: { any }, valueToFind: any): (number?, any)
	-- Handle array-like tables
	if #tbl > 0 then
		for i, value in ipairs(tbl) do
			if value == valueToFind then
				return i, value
			end
		end
	end

	-- Handle dictionary-like tables
	for key, value in pairs(tbl) do
		if value == valueToFind then
			return key, value
		end
	end

	return nil
end

local function hasKey(tbl: { any }, keyToFind: any): boolean
	return tbl[keyToFind] ~= nil
end

local function reconcile<S, T>(src: S, template: T): S & T
	assert(type(src) == "table", "First argument must be a table")
	assert(type(template) == "table", "Second argument must be a table")

	local tbl = table.clone(src)

	for k, v in template do
		local sv = src[k]
		if sv == nil then
			if type(v) == "table" then
				tbl[k] = copy(v, true)
			else
				tbl[k] = v
			end
		elseif type(sv) == "table" then
			if type(v) == "table" then
				tbl[k] = reconcile(sv, v)
			else
				tbl[k] = copy(sv, true)
			end
		end
	end

	return (tbl :: any) :: S & T
end

local function merge<T, K>(dictionary1: {}, dictionary2: {}): T & K
	local newTable = table.clone(dictionary1)

	for key, value in dictionary2 do
		newTable[key] = value
	end

	return newTable
end

function shuffle(t: { any })
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

local function empty(t: { any? })
	return next(t) == nil
end

return table.freeze({
	findKeyIndex = findKeyIndex,
	findKey = findKey,
	hasKey = hasKey,
	copy = copy,
	reconcile = reconcile,
	empty = empty,
	merge = merge,
})
