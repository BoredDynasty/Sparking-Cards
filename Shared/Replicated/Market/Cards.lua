-- Cards.lua

export type dataType = {
	[string]: {
		Name: string,
		Description: string,
		Price: number,
		ExperimentsEnabled: boolean,
		Icon: string?,
		Color: string,
		NewRelease: boolean?,
	},
}

return {
	["Fire"] = {
		Name = "Fire",
		Description = "Fire damage",
		Price = 9.99,
		ExperimentsEnabled = false, -- Can the Card be tested by players in the game?
		-- Icon = "rbxassetid://1234567890",
		Color = "Irish-Moss",
		NewRelease = true,
	},
	["Frost"] = {
		Name = "Frost",
		Description = "Frost damage",
		Price = 13.99,
		ExperimentsEnabled = true, -- Can the Card be tested by players in the game?
		-- Icon = "rbxassetid://1234567890",
		-- Color = "Irish-Moss",
		NewRelease = true,
	},
} :: dataType
