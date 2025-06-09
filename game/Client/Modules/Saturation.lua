--!strict

-- freaky function to generate bright HSV colors
local function generateBrightColor(): Color3
	-- Use HSV (Hue, Saturation, Value) for better control
	-- Random hue (0-1), high saturation (0.8-1), high value (0.9-1)
	local hue = math.random()
	local saturation = 0.8 + (math.random() * 0.2) -- 0.8 to 1.0
	local value = 0.9 + (math.random() * 0.1) -- 0.9 to 1.0

	-- Convert HSV to RGB Color3
	local h = hue * 6
	local c = value * saturation
	local x = c * (1 - math.abs((h % 2) - 1))
	local m = value - c

	local r, g, b = 0, 0, 0

	if h < 1 then -- hi
		r, g, b = c, x, 0
	elseif h < 2 then
		r, g, b = x, c, 0
	elseif h < 3 then
		r, g, b = 0, c, x
	elseif h < 4 then
		r, g, b = 0, x, c
	elseif h < 5 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end

	return Color3.new(r + m, g + m, b + m)
end

local function generateRandomColors(count: number): { Color3 }
	local colors = {}

	-- Generate the requested number of colors
	for _ = 1, count do
		table.insert(colors, generateBrightColor())
	end

	return colors
end

return {
	generateBrightColor = generateBrightColor,
	generateRandomColors = generateRandomColors,
}
