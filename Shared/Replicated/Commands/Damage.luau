local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local damage = require(ReplicatedStorage.Combat.Strike.damage)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
-- Cmdr Command
-- Damage.luau

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
		local character = playerMarshaller.getByName(target.Name).Character
		if character then
			-- local humanoid = character.Humanoid
			damage.__call({
				amount = amount,
				source = Players.LocalPlayer,
				target = target, -- lol
			})
		end

		return "Damage dealt, youch!"
	end,
}
