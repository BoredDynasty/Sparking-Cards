--!strict

-- typeformatter.luau

return {
	Color3 = function(Object: Color3): string
		return `rgb({math.floor(Object.R * 255)},{math.floor(Object.G * 255)},{math.floor(Object.B * 255)})`
	end,
	BrickColor = function(Object: BrickColor): string
		return `rgb({math.floor(Object.r * 255)},{math.floor(Object.g * 255)},{math.floor(Object.b * 255)})`
	end,
	EnumItem = function(Object: EnumItem): string
		return Object.Name
	end,
} :: { [string]: (any) -> string }
