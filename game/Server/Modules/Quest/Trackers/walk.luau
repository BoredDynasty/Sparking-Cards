--!strict
local players = game:GetService("Players")

-- walk.luau

local module = {}

local lastPositions = {}

function module.run(player)
	local character = player.Character
	if not character then
		return 0
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.MoveDirection.Magnitude == 0 then
		return 0
	end

	local currentPosition = character:GetPrimaryPartCFrame().Position
	local lastPosition = lastPositions[player.UserId]

	if not lastPosition then
		lastPositions[player.UserId] = currentPosition
		return 0
	end

	local distance = (currentPosition - lastPosition).Magnitude
	lastPositions[player.UserId] = currentPosition

	return distance
end

return module