--!nocheck

-- Da Dubious Dynasty

-- Literally BrickColor library :skull:

local Color = {}

local colors = {
	["Green"] = Color3.fromHex("#55ff7f"),
	["Red"] = Color3.fromHex("#ff4e41"),
	["Light Blue"] = Color3.fromHex("#136aeb"),
	["Blue"] = Color3.fromHex("#335fff"),
	["Yellow"] = Color3.fromHex("#ffff7f"),
	["Orange"] = Color3.fromHex("#ff8c3a"),
	["Pink"] = Color3.fromHex("#ff87ff"),
	["Brown"] = Color3.fromHex("#3f3025"),
	["Hot Pink"] = Color3.fromHex("#ff59d8"),
	["White"] = Color3.fromHex("#FFFFFF"),
	["Black"] = Color3.fromHex("#111216"),
	["Absolute Black"] = Color3.fromHex("#000000"),
	["Grey"] = Color3.fromHex("#9e9e9e"),
}

function Color.getColor(color)
	local final: Color3 | nil
	if type(color) ~= "string" then
		if colors[color] then
			final = colors[color]
		end
		return final
	end
end

function Color.rawget()
	return colors
end

function Color.rawset(color, value: Color3)
	colors[color] = value
end

function Color.fromHex(hex: string)
	return Color3.fromHex(hex)
end

function Color.fromHex_ToRGB(hex: string)
	hex = hex:gsub("#", "")
	local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	return Color3.fromRGB(r, g, b)
end

function Color.fromRGB_ToHex(rgb)
	local hex = string.format("#%02X%02X%02X", rgb.R * 255, rgb.G * 255, rgb.B * 255)
	return hex
end

function Color.fromHSV_ToHex(hsv)
	local hex = Color3.fromHSV(hsv.H, hsv.S, hsv.V):ToHex()
	return hex
end

function Color.fromHSV_ToRGB(hsv)
	local rgb = Color3.fromHSV(hsv.H, hsv.S, hsv.V)
	return rgb
end

function Color:lighter(color: Color3?)
	if color == colors["White"] then
		return
	end
	if type(color) == "string" then
		color = Color.fromHex_ToRGB(color)
	end
	local H, S, V = color:ToHSV()
	V = math.clamp(V + 0.1, 0, 1)
	return Color3.fromHSV(H, S, V)
	--[[
		return color:Lerp(Color3.new(1, 1, 1), 0.1)
	--]]
end

function Color:darker(color: Color3?)
	if color == colors["Absolute Black"] then
		return
	end
	local H, S, V = color:ToHSV()
	V = math.clamp(V - 0.1, 0, 1)
	return Color3.fromHSV(H, S, V)
end

return Color
