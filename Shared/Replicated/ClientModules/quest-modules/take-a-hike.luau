--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- take-a-hike.luau

local constants = {
	distance = 200,
}

return function(player: Player, progress: number)
	local character = player.Character
	if not character then
		warn("no character")

		return progress
	end

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	local primary_part = character.PrimaryPart :: BasePart

	local initial_position = primary_part.Position

	local max_position = 1

	task.spawn(function()
		while humanoid.WalkSpeed > 0 do
			-- while we are still walking,

			RunService.Heartbeat:Wait()

			if humanoid.WalkSpeed <= 0 then
				-- if we stopped walking, stop.

				break
			end

			local current_position = primary_part.Position
			local distance_traveled = (current_position - initial_position).Magnitude

			max_position = math.clamp(distance_traveled, 1, 100)

			if distance_traveled > constants.distance then
				-- if we traveled more than the distance, we are done.

				max_position = math.clamp(distance_traveled, 1, 100)

				break
			end
		end
	end)

	return max_position
end
