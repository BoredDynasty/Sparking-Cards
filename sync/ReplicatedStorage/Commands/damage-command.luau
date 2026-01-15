local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
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
		local player = playerMarshaller.getByName(target.Name)
		local character = characterMarshaller.get(player)

		if character then
			-- local humanoid = character.Humanoid
			damage.__call({
				amount = amount,
				source = Players.LocalPlayer,
				target = target, -- lol
			})
		else
			return "Couldn't get character"
		end

		return "Damage dealt, youch!"
	end,
}
