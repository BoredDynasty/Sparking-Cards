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
	{
		Name = "Anemo",
		Price = 11.99,
		ExperimentsEnabled = true,
		NewRelease = false,
		Availability = true,
		Details = CardLibrary.AnemoTwinBlades,
	},
	{
		Name = "Light",
		Price = 49.99,
		ExperimentsEnabled = true,
		NewRelease = true,
		Availability = true,
		Details = CardLibrary.LightStaff,
	},
	{
		Name = "Electro",
		Price = 34.99,
		ExperimentsEnabled = true,
		NewRelease = false,
		Availability = true,
		Details = CardLibrary.ElectroPolearm,
	},
	{
		Name = "Poison",
		Price = 24.99,
		ExperimentsEnabled = true,
		NewRelease = true,
		Availability = true,
		Details = CardLibrary.PoisonDagger,
	},
} :: { Item }
