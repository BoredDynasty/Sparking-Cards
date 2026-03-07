--!strict
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local random = require(ReplicatedStorage.Utility.random)

-- pathfinding.luau

local module = {}

local randomseed = random.create()

function module:ChosenPath(path_array: { Vector3 })
	local chosen_path = randomseed:integer(1, #path_array)

	return path_array[chosen_path]
end

function module:MoveTo(primary_part: BasePart, location: Vector3): (Path?, { PathWaypoint }?)
	task.synchronize()

	local path = PathfindingService:CreatePath()

	path:ComputeAsync(primary_part.Position, location)

	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()

		return path, waypoints
	else
		warn("failed to find a path")

		return nil, nil
	end
end

return module
