local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local explosion = require(ReplicatedStorage.Combat.framework.effects.explosion)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- Cmdr Command
-- Explosion.luau

-- for creating explosions

return {
	Name = "Explosion",
	Aliases = { "Explode", "Kaboom" },
	Description = "Creates an explosion effect",
	Group = "Utility",
	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "The player to center the explosion on",
			Default = Players.LocalPlayer,
		},
		{
			Type = "number",
			Name = "duration",
			Description = "The duration of the explosion",
			Default = 1.5,
		},
		{
			Type = "string",
			Name = "colors",
			Description = "Comma-separated RGB values for the explosion colors (e.g., '255,89,0,255,0,0')",
			Default = "255,89,0,255,0,0,255,255,0",
		},
	},
	ClientRun = function(_, target: Player, duration: number, colorsStr: string)
		local character = target.Character
		if not character or not character.PrimaryPart then
			return "Target character not found"
		end

		local colors = {}
		local colorValues = colorsStr:split(",")
		for i = 1, #colorValues, 3 do
			local r = tonumber(colorValues[i])
			local g = tonumber(colorValues[i + 1])
			local b = tonumber(colorValues[i + 2])
			if r and g and b then
				table.insert(colors, Color3.fromRGB(r, g, b))
			end
		end

		explosion.kaboom({
			position = character.PrimaryPart.Position,
			duration = duration,
			colors = colors,
		})

		return "Explosion created!"
	end,
}
