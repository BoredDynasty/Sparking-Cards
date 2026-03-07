--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local pathfinding = require(ReplicatedStorage.Modules.Logic.pathfinding)

-- ai-backend.luau

local module = {}
module.__index = module

function module.new(model: Model)
	local self = setmetatable({}, module)

	self.model = model
	self.primary_part = self.model.PrimaryPart :: BasePart
	self.humanoid = self.model:WaitForChild("Humanoid", 3)
	self.time_between_patrols = 3

	if self.primary_part ~= nil then
		self.primary_part:SetNetworkOwner(nil)
	end

	return self
end

function module:Patrol(path_array: { Vector3 })
	if not self.primary_part then
		return false
	end

	local location = pathfinding:ChosenPath(path_array)
	local path, waypoints: { PathWaypoint } = pathfinding:MoveTo(self.primary_part.Position, location)

	if path and waypoints then
		for _, waypoint in ipairs(waypoints) do
			local reached = false

			local waypoint_position = CFrame.new(waypoint.Position)

			task.synchronize()

			self.humanoid:MoveTo(waypoint.Position)
			self.humanoid.MoveToFinished:Connect(function(is_reached: boolean)
				if not is_reached then
					self.primary_part.CFrame = waypoint_position
				end

				reached = true
			end)

			task.desynchronize()

			repeat
				RunService.Heartbeat:Wait()
			until reached
		end
	end

	return true
end

return module
