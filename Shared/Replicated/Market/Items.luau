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
		-- Icon = "rbxassetid://1234567890",
		Color = "Irish-Moss",
		NewRelease = true,
	},
	["Frost"] = {
		Name = "Frost",
		Description = "Frost damage",
		Price = 13.99,
		ExperimentsEnabled = true,
		-- Icon = "rbxassetid://1234567890",
		-- Color = "Irish-Moss",
		NewRelease = true,
	},
	["Healthy"] = {
		Name = "Healthy",
		Description = "+5% Additional Health",
		Price = 44.99,
		ExperimentsEnabled = false,
		NewRelease = true,
		Tags = {
			"Passive",
		},
	},
} :: dataType
