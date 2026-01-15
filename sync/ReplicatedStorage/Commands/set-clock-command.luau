--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)

-- Cmdr Command
-- set-clock-command.luau

return {
	Name = "Set)Time",
	Aliases = { "Time", "Lighting", "Clock", "Set", "Sun", "Moon" },
	Description = "Set the clock time",
	Group = "Utility",
	Args = {
		{
			Type = "number",
			Name = "time",
			Description = "Clock time",
			Default = 12,
		},
	},
	ClientRun = function(_, amount: number)
		Packet.SetTime.send({ clock_time = amount })

		return "Set the time to: " .. tostring(amount)
	end,
}
