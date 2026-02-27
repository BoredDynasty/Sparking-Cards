local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
-- Items.luau

export type Item = {
	Name: string,
	Price: number,
	ExperimentsEnabled: boolean,
	Icon: string?,
	Color: string,
	NewRelease: boolean?,
	Tags: { string }?,
}

return {
	{
		Name = "Pyro",
		Price = 9.99,
		ExperimentsEnabled = false,
		NewRelease = true,
		Availability = true,
		Details = CardLibrary.PyroKatana,
	},
	{
		Name = "Cryo",
		Price = 13.99,
		ExperimentsEnabled = true,
		NewRelease = true,
		Availability = true,
		Details = CardLibrary.CryoGauntlet,
	},
	{
		Name = "Hydro",
		Price = 40.99,
		ExperimentsEnabled = true,
		NewRelease = true,
		Availability = true,
		Details = CardLibrary.HydroCatalyst,
	},
	{
		Name = "Shadow",
		Price = 199.99,
		NewRelease = true,
		ExperimentsEnabled = false,
		Availability = false,
		Details = CardLibrary.ShadowScythe,
	},
	{
		Name = "Geo",
		Price = 139.99,
		NewRelease = true,
		ExperimentsEnabled = false,
		Availability = false,
		Details = CardLibrary.GeoClaymore,
	},
} :: { Item }
