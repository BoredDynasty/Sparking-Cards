local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local damage = require(ReplicatedStorage.Combat.Strike.damage)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
-- Cmdr Command

-- damage-command.luau

-- for dealing damage to a player's health

return {
	Name = "Damage",
	Aliases = { "Dmg", "DealDamage", "Health", "HP" },
	Description = "Deals damage to a player's health",
	Group = "Utility",
	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "The player to deal damage to",
			Default = Players.LocalPlayer,
		},
		{
			Type = "number",
			Name = "amount",
			Description = "The amount of damage to deal",
			Default = 10,
		},
	},
	ClientRun = function(_, target: Player, amount: number)
		damage:apply({
			target = target,
			amount = amount,
		})

		return "Damage dealt, youch!"
	end,
}
