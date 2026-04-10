--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local bufferencoder = require(ReplicatedStorage.Packages.bufferencoder)

-- take-a-hike.luau

local constants = {
	distance = 200,
}

local events = ReplicatedStorage.Events
local report_progress = events.ReportQuestProgress

return function(player: Player, progress: number)
	local character = player.Character
	if not character then
		warn("no character")

		return progress
	end

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	local primary_part = character.PrimaryPart :: BasePart

	local initial_position = primary_part.Position

	local max_position = 0

	local conn = nil

	conn = RunService.Heartbeat:Connect(function()
		-- while we are still walking,
		if humanoid.WalkSpeed <= 0 then
			return
		end

		local current_position = primary_part.Position
		local distance_traveled = (current_position - initial_position).Magnitude

		max_position = math.clamp(distance_traveled, 1, 100)

		if distance_traveled >= constants.distance then
			-- if we traveled more than the distance, we are done.

			max_position = math.clamp(distance_traveled, 1, 100)

			print("completed take-a-hike.")

			local serialized = bufferencoder.write({ name = "Take a Hike", progress = max_position })
			report_progress:FireServer(serialized)

			if conn then
				conn:Disconnect()
			end
		end

		local serialized = bufferencoder.write({ name = "Take a Hike", progress = max_position })
		report_progress:FireServer(serialized)

		-- if we're doing this every frame, it'd not be a bad idea to serialize this
	end)
	return max_position
end
