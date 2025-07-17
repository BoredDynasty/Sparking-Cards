--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)

-- Cmdr Command
-- Payout.luau

-- for giving players Cards

return {
	Name = "Payout",
	Aliases = { "Pay", "GiveBigCards", "Award", "Card" },
	Description = "Give a player Cards.",
	Group = "Utility",
	Args = {
		{
			Type = "number",
			Name = "amount",
			Description = "The amount of Cards to give.",
			Default = 1,
		},
		{
			Type = "player",
			Name = "player",
			Description = "The player to give Cards to.",
			Default = Players.LocalPlayer,
		},
	},
	ClientRun = function(_, amount: number, player: Player)
		Packet.PayBigCards.send({ amount = amount, recipientUsername = player.Name })

		return "Payout executed"
	end,
}
