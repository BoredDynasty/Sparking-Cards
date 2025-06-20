--!optimize 2
--!native
--!nolint

--# selene: allow(incorrect_standard_library_use)

local blackColor = Color3.fromRGB(0, 0, 0)

local function objectLerp(a, b, t)
	return a:Lerp(b, t)
end

local function commonPrefix(a, b)
	local aLength = utf8.len(a)
	local bLength = utf8.len(b)
	local minLength = if aLength < bLength then aLength else bLength

	for index = 1, minLength, 1 do
		local aPosition = utf8.offset(a, index)
		local bPosition = utf8.offset(b, index)

		if utf8.codepoint(a, aPosition) ~= utf8.codepoint(b, bPosition) then
			return index - 1
		end
	end
	return minLength
end
local function commonSuffix(a, b, prefixLen)
	local aLength = utf8.len(a)
	local bLength = utf8.len(b)
	local maxLength = if aLength < bLength then aLength - prefixLen else bLength - prefixLen

	for index = 1, maxLength, 1 do
		local aPosition = utf8.offset(a, -index)
		local bPosition = utf8.offset(b, -index)

		if utf8.codepoint(a, aPosition) ~= utf8.codepoint(b, bPosition) then
			return index - 1
		end
	end
	return maxLength
end

local function rgbToOklab(r: number, g: number, b: number)
	-- Gamma expansion.
	r = if r > 0.04045 then ((r + 0.055) / 1.055) ^ 2.4 else r / 12.92
	g = if g > 0.04045 then ((g + 0.055) / 1.055) ^ 2.4 else g / 12.92
	b = if b > 0.04045 then ((b + 0.055) / 1.055) ^ 2.4 else b / 12.92

	-- LMS conversion.
	local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
	local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
	local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

	-- Cube roots.
	l = l ^ 0.3333333333333333
	m = m ^ 0.3333333333333333
	s = s ^ 0.3333333333333333

	-- Return l, a, b.
	return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
		1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
		0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
end
local function oklabToRGB(l: number, a: number, b: number)
	-- Matrix transformation.
	local m = l - 0.1055613458 * a - 0.0638541728 * b
	local s = l - 0.0894841775 * a - 1.2914855480 * b
	local l = l + 0.3963377774 * a + 0.2158037573 * b

	-- Cube values.
	l = l * l * l
	m = m * m * m
	s = s * s * s

	-- RGB conversion.
	local r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
	local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
	b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

	-- Gamma compression.
	if r > 0.0031308 then
		r = 1.055 * (r ^ 0.4166666667) - 0.055
	else
		r = r * 12.92
	end
	if r < 0 then
		r = 0
	elseif r > 1 then
		r = 1
	end

	if g > 0.0031308 then
		g = 1.055 * (g ^ 0.4166666667) - 0.055
	else
		g = g * 12.92
	end
	if g < 0 then
		g = 0
	elseif g > 1 then
		g = 1
	end

	if b > 0.0031308 then
		b = 1.055 * (b ^ 0.4166666667) - 0.055
	else
		b = b * 12.92
	end
	if b < 0 then
		b = 0
	elseif b > 1 then
		b = 1
	end

	-- Return result as Color3.
	return Color3.new(r, g, b)
end

local function findKeypoints(source: string, targetTime: number)
	local low: number = 1
	local high: number = #source
	while low <= high do
		local x = (low + high) / 2
		local mid = math.floor(x)
		local midTime = source[mid].Time
		if midTime < targetTime then
			low = mid + 1
		elseif midTime > targetTime then
			high = mid - 1
		else
			return mid, mid
		end
	end
	return high, low
end
local function lerpSequence(a, b, t, createKeypoint, lerpValue)
	local keypoints = {}
	local exists = {}

	for _, keypoint in a.Keypoints do
		local time = keypoint.Time
		if not exists[time] then
			exists[time] = true
			local i0, i1 = findKeypoints(b.Keypoints, time)
			local b0 = b.Keypoints[i0]
			local b1 = b.Keypoints[i1]

			local bValue = nil
			local bEnvelope = nil
			if b0.Time == b1.Time then
				bValue = b0.Value
				bEnvelope = b0.Envelope
			else
				local p = (time - b0.Time) / (b1.Time - b0.Time)
				bValue = b0.Value + (b1.Value - b0.Value) * p
				bEnvelope = b0.Envelope + (b1.Envelope - b0.Envelope) * p
			end

			table.insert(
				keypoints,
				createKeypoint(
					time,
					lerpValue(keypoint.Value, bValue, t),
					keypoint.Envelope + (bEnvelope - keypoint.Envelope) * t
				)
			)
		end
	end

	for _, keypoint in b.Keypoints do
		local time = keypoint.Time
		if not exists[time] then
			exists[time] = true

			local i0, i1 = findKeypoints(a.Keypoints, time)
			local a0 = a.Keypoints[i0]
			local a1 = a.Keypoints[i1]

			local aValue = nil
			local aEnvelope = nil
			if a0.Time == a1.Time then
				aValue = a0.Value
				aEnvelope = a0.Envelope
			else
				local p = (time - a0.Time) / (a1.Time - a0.Time)
				aValue = a0.Value + (a1.Value - a0.Value) * p
				aEnvelope = a0.Envelope + (a1.Envelope - a0.Envelope) * p
			end

			table.insert(
				keypoints,
				createKeypoint(
					time,
					lerpValue(aValue, keypoint.Value, t),
					aEnvelope + (keypoint.Envelope - aEnvelope) * t
				)
			)
		end
	end

	-- Sort and return.
	table.sort(keypoints, function(a, b)
		return a.Time < b.Time
	end)
	return keypoints
end

-- Data type functions.
return table.freeze({
	-- Normal data types.
	Normal = {
		number = math.lerp,

		Vector3 = objectLerp,
		UDim2 = objectLerp,
		Vector2 = objectLerp,
		CFrame = objectLerp,

		UDim = function(a, b, t)
			return UDim.new(math.lerp(a.Scale, b.Scale, t), math.lerp(a.Offset, b.Offset, t))
		end,

		boolean = function(a, b, t)
			return if t < 0.5 then a else b
		end,

		string = function(a, b, t)
			if t == 0 then
				return a
			end
			if t == 1 then
				return b
			end

			-- Find common elements.
			local prefixLen = commonPrefix(a, b)
			local suffixLen = commonSuffix(a, b, prefixLen)

			-- Calculate middle segments.
			local aMiddleStart = prefixLen + 1
			local aMiddleEnd = #a - suffixLen
			local bMiddleStart = prefixLen + 1
			local bMiddleEnd = #b - suffixLen

			local aMiddle, bMiddle
			if aMiddleStart <= aMiddleEnd then
				aMiddle = a:sub(aMiddleStart, aMiddleEnd)
			else
				aMiddle = ""
			end

			if bMiddleStart <= bMiddleEnd then
				bMiddle = b:sub(bMiddleStart, bMiddleEnd)
			else
				bMiddle = ""
			end

			-- Calculate visible portions.
			local aVisible = math.floor(#aMiddle * (1 - t) + 0.5)
			local bVisible = math.floor(#bMiddle * t + 0.5)

			-- Clamp visible portions.
			if aVisible < 0 then
				aVisible = 0
			else
				if aVisible > #aMiddle then
					aVisible = #aMiddle
				end
			end
			if bVisible < 0 then
				bVisible = 0
			else
				if bVisible > #bMiddle then
					bVisible = #bMiddle
				end
			end

			-- Build final string.
			local buffer = { a:sub(1, prefixLen) }

			if aVisible ~= 0 then
				table.insert(buffer, aMiddle:sub(1, aVisible))
			end
			if bVisible ~= 0 then
				table.insert(buffer, bMiddle:sub(1, bVisible))
			end
			if suffixLen ~= 0 then
				table.insert(buffer, a:sub(-suffixLen))
			end

			return table.concat(buffer)
		end,

		Color3 = function(c0, c1, t)
			local l0, a0, b0 = rgbToOklab(c0.R, c0.G, c0.B)
			local l1, a1, b1 = rgbToOklab(c1.R, c1.G, c1.B)

			return oklabToRGB(l0 + (l1 - l0) * t, a0 + (a1 - a0) * t, b0 + (b1 - b0) * t)
		end,

		NumberRange = function(a, b, t)
			return NumberRange.new(math.lerp(a.Min, b.Min, t), math.lerp(a.Max, b.Max, t))
		end,

		NumberSequence = function(a, b, t)
			return NumberSequence.new(lerpSequence(a, b, t, NumberSequenceKeypoint.new, math.lerp))
		end,
		ColorSequence = function(a, b, t)
			return ColorSequence.new(lerpSequence(a, b, t, ColorSequenceKeypoint.new, objectLerp))
		end,
	},

	-- Advanced data types.
	Advanced = {
		--[[
		NAME = {
			Target = "CLASS_NAME",
			Set = function(instance, a, b, t)
				
			end,
			Get = function(instance)
				
			end
		}
		]]
		--
		Pivot = {
			Target = "PVInstance",
			Set = function(instance, a, b, t)
				instance:PivotTo(objectLerp(a, b, t))
			end,
			Get = function(instance)
				return instance:GetPivot()
			end,
		},
		Scale = {
			Target = "Model",
			Set = function(instance, a, b, t)
				instance:ScaleTo(math.lerp(a, b, t))
			end,
			Get = function(instance)
				return instance:GetScale()
			end,
		},
	},
})
