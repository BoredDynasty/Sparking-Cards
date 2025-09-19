local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local impact = require(ReplicatedStorage.Combat.framework.effects.impact)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- Cmdr Command
-- Impact.luau

-- for creating impact effects

return {
	Name = "Impact",
	Aliases = {},
	Description = "Creates an impact effect",
	Group = "Utility",
	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "The player to center the impact on",
			Default = Players.LocalPlayer,
		},
		{
			Type = "string",
			Name = "name",
			Description = "The name of the impact effect (e.g., 'Impact', 'CraterDust', 'Wind')",
			Default = "Impact",
		},
		{
			Type = "number",
			Name = "magnitude",
			Description = "The magnitude of the impact",
			Default = 1,
		},
		{
			Type = "number",
			Name = "duration",
			Description = "The duration of the impact",
			Default = 1,
		},
	},
	Run = function(_, target: Player, name: string, magnitude: number, duration: number)
		local character = target.Character
		if not character or not character.PrimaryPart then
			return "Target character not found"
		end

		impact({
			name = name,
			position = character.PrimaryPart.Position,
			direction = character.PrimaryPart.CFrame.LookVector,
			magnitude = magnitude,
			duration = duration,
		})

		return "Impact effect created!"
	end,
}
