-- Items.luau

export type dataType = {
	[string]: {
		Name: string,
		Description: string,
		Price: number,
		ExperimentsEnabled: boolean,
		Icon: string?,
		Color: string,
		NewRelease: boolean?,
		Tags: { string }?,
	},
}

return {
	["Fire"] = {
		Name = "Fire",
		Description = "Fire damage",
		Price = 9.99,
		ExperimentsEnabled = false,

		NewRelease = true,
	},
	["Frost"] = {
		Name = "Frost",
		Description = "Frost damage",
		Price = 13.99,
		ExperimentsEnabled = true,
		NewRelease = true,
	},
	["Hydro"] = {
		Name = "Hydro",
		Description = "Hydro damage",
		Price = 40.99,
		ExperimentsEnabled = true,
		Icon = "rbxassetid://1234567890",
		NewRelease = true,
	},
} :: dataType
