--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)

-- Cmdr Command
-- Payout.luau

-- for giving players Prisms

return {
	Name = "Payout",
	Aliases = { "Pay", "GivePrisms", "Award", "Card", "Money", "Cash" },
	Description = "Give a player Prisms.",
	Group = "Utility",
	Args = {
		{
			Type = "number",
			Name = "amount",
			Description = "The amount of Prisms to give.",
			Default = 1,
		},
		{
			Type = "player",
			Name = "player",
			Description = "The player to give Prisms to.",
			Default = Players.LocalPlayer,
		},
	},
	ClientRun = function(_, amount: number, player: Player)
		Packet.PayPrisms.send({ amount = amount, recipientUsername = player.Name })

		return "Payout executed"
	end,
}
