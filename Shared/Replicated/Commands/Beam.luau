local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local beam = require(ReplicatedStorage.Combat.framework.gameplay.beam)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- Cmdr Command
-- Beam.luau

-- for creating beams

return {
	Name = "Beam",
	Aliases = {},
	Description = "Fires a beam",
	Group = "Utility",
	Args = {
		{
			Type = "player",
			Name = "source",
			Description = "The player to fire the beam from",
			Default = Players.LocalPlayer,
		},
		{
			Type = "number",
			Name = "damage",
			Description = "The amount of damage the beam deals",
			Default = 10,
		},
		{
			Type = "number",
			Name = "width",
			Description = "The width of the beam",
			Default = 0.25,
		},
		{
			Type = "string",
			Name = "color",
			Description = "RGB values for the beam color (e.g., '255,200,100')",
			Default = "255,200,100",
		},
	},
	Run = function(_, source: Player, damage: number, width: number, colorStr: string)
		local character = source.Character
		if not character or not character.PrimaryPart then
			return "Source character not found"
		end

		local colorValues = colorStr:split(",")
		local r = tonumber(colorValues[1])
		local g = tonumber(colorValues[2])
		local b = tonumber(colorValues[3])
		local color = (r and g and b) and Color3.fromRGB(r, g, b) or Color3.new(1, 1, 1)

		beam.Fire({
			origin = character.PrimaryPart.Position,
			direction = character.PrimaryPart.CFrame.LookVector,
			damage = damage,
			width = width,
			color = color,
			source = character,
		})

		return "Beam fired!"
	end,
}
