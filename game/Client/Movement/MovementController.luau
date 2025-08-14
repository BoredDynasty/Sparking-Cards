--!strict
--[=[
	MovementController
	@class MovementController

	Orchestrates character movement by requiring and initializing various movement modules.
	It manages a central Trove instance for cleanup and operates on a single Heartbeat connection
	for performance. It also handles the state of the character's movement.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MovementController = {}
MovementController.__index = MovementController

function MovementController.new()
	local self = setmetatable({}, MovementController)

	self._trove = require(ReplicatedStorage.Packages.trove).new()
	self._movements = {}

	return self
end

function MovementController:Add(movementName: string, movementModule: any)
	local movement = movementModule.new(self)
	self._movements[movementName] = movement
	self._trove:Add(movement)
end

function MovementController:Start()
	self._trove:Connect(RunService.Heartbeat, function(deltaTime)
		for _, movement in pairs(self._movements) do
			if movement.Update then
				movement:Update(deltaTime)
			end
		end
	end)
end

function MovementController:Destroy()
	self._trove:Destroy()
end

return MovementController
