local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
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
	Fire = {
		Name = "Fire",
		Description = "Fire damage",
		Price = 9.99,
		ExperimentsEnabled = false,
		NewRelease = true,
		Availability = true,
		Details = CardLibrary.FireSword,
	},
	Cryo = {
		Name = "Cryo",
		Description = "Cryo damage",
		Price = 13.99,
		ExperimentsEnabled = true,
		NewRelease = true,
		Availability = true,
		Details = CardLibrary.CryoGauntlet,
	},
	Hydro = {
		Name = "Hydro",
		Description = "Hydro damage",
		Price = 40.99,
		ExperimentsEnabled = true,
		Icon = "rbxassetid://1234567890",
		NewRelease = true,
		Availability = true,
		Details = nil,
	},
	Shadow = {
		Name = "Shadow",
		Description = "Shadow Damage",
		Price = 199.99,
		NewRelease = true,
		Availability = false,
		Details = CardLibrary.ShadowPolearm,
	},
	Stone = {
		Name = "Stone",
		Description = "Stone Damage",
		Price = 139.99,
		NewRelease = true,
		Availability = false,
		Details = CardLibrary.StoneClaymore,
	},
} :: dataType
