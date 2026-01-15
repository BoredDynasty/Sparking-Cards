--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- regeneration.luau

return function(player: Player, interval: number, increment: number?): string?
	local _trove = trove.new()

	local character = player.Character :: typemarshaller.Character

	if not character then
		print("theres no character to regen for lol")
		return nil
	end

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	if not humanoid then
		print("no humanoid for regen")
		return nil
	end

	increment = (increment :: number) or 6

	character:SetAttribute("Regenerating", true)

	_trove:Connect(RunService.Heartbeat, function()
		task.wait(interval)
		if humanoid.Health > 0 and character then
			if not character:GetAttribute("Regenerating") then
				_trove:Destroy()
				return
			end

			if humanoid.Health >= humanoid.MaxHealth then
				humanoid.Health = humanoid.MaxHealth

				character:SetAttribute("Regenerating", false)

				_trove:Clean()
				_trove:Destroy()
				return
			end

			humanoid.Health += increment :: number
		end
	end)

	return "Regenerating"
end
