--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)

-- Cmdr Command
-- blow-firwork-command.luau

return {
	Name = "BlowFirework",
	Aliases = { "Firework", "Boom", "Fire", "Sky", "Light", "Work" },
	Description = "Blows a set amount of fireworks",
	Group = "Fun",
	Args = {
		{
			Type = "string",
			Name = "position",
			Description = "Position to blow fireworks at",
			Default = "0,0,0",
		},
		{
			Type = "number",
			Name = "amount",
			Description = "Amount of fireworks to blow",
			Default = 10,
		},
	},
	ClientRun = function(_, position: string, amount: number)
		local coords = string.split(position, ",")
		local vec_position =
			Vector3.new(tonumber(coords[1]) or 0, tonumber(coords[2]) or 0, tonumber(coords[3]) or 0)

		Packet.BlowFirework.send({ amount = amount, position = vec_position })

		return "Blowing " .. tostring(amount) .. " fireworks!"
	end,
}
