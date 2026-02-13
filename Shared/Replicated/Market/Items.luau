local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
-- Items.luau

export type Item = {
	Name: string,
	Description: string,
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
		Description = "Pyro damage",
		Price = 9.99,
		ExperimentsEnabled = false,
		NewRelease = true,
		Availability = true,
		Details = CardLibrary.PyroKatana,
	},
	{
		Name = "Cryo",
		Description = "Cryo damage",
		Price = 13.99,
		ExperimentsEnabled = true,
		NewRelease = true,
		Availability = true,
		Details = CardLibrary.CryoGauntlet,
	},
	{
		Name = "Hydro",
		Description = "Hydro damage",
		Price = 40.99,
		ExperimentsEnabled = true,
		NewRelease = true,
		Availability = true,
		Details = CardLibrary.HydroCatalyst,
	},
	{
		Name = "Shadow",
		Description = "Shadow Damage",
		Price = 199.99,
		NewRelease = true,
		Availability = false,
		Details = CardLibrary.ShadowScythe,
	},
	{
		Name = "Geo",
		Description = "Geo Damage",
		Price = 139.99,
		NewRelease = true,
		Availability = false,
		Details = CardLibrary.GeoClaymore,
	},
}
