--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

-- regeneration.luau

return function(player: playerMarshaller.player, interval: number, increment: number?): string?
	local _trove = trove.new()
	local connection: RBXScriptConnection? = nil

	local character = player.Character
	if not character then
		print("theres no character to regen for lol")
		return nil
	end
	local humanoid = character.Humanoid
	increment = (increment :: number) or 6

	character:SetAttribute("Regenerating", true)

	connection = RunService.Heartbeat:Connect(function()
		task.wait(interval)
		if humanoid.Health > 0 and character then
			if not character:GetAttribute("Regenerating") then
				_trove:Clean()
				return
			end
			humanoid.Health += increment :: number
		end
	end)

	_trove:Add(connection)

	return "Regenerating"
end
