--!nocheck

-- Da Dubious Dynasty

-- Note this module is not done yet.

local Style = {}
Style.__index = Style

-- // Requires
local Color = require(script.Parent:WaitForChild("Color"))

local CurrentStyle: nil? = nil
local CurrentTheme: string

local styles = {
	["Material 3"] = {
		["Frame"] = Color.getColor("Black"),
		["Font"] = Enum.Font.BuilderSans,
		["Buttons"] = {
			["Chip"] = {
				["Color"] = Color.getColor("Black"),
				["Outlined"] = true,
				["FontColor"] = Color.fromHex("#675496"),
				["CornerRadius"] = UDim.new(0.2, 0),
			},
			["Accept"] = {
				["Color"] = Color.fromHex("#675496"),
				["Outlined"] = false,
				["FontColor"] = Color.getColor("White"),
				["CornerRadius"] = UDim.new(0.2, 0),
			},
			["NoneImportance"] = {
				["Color"] = nil,
				["Outlined"] = true,
				["FontColor"] = Color.fromHex("#675496"),
				["CornerRadius"] = UDim.new(0.2, 0),
			},
		},
		["Frames"] = {
			["Default"] = {
				["Color"] = Color.getColor("Black"),
				["Outlined"] = false,
				["FontColor"] = nil,
				["CornerRadius"] = UDim.new(0, 8),
			},
		},
	},
}

function Style.setGameStyle(style, theme)
	local newStyle = styles[style]
	CurrentStyle = newStyle
	CurrentTheme = theme
	return CurrentStyle, theme
end

function Style.getGameStyle()
	return CurrentStyle, CurrentTheme
end

return Style
