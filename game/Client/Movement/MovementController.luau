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

local Trove = require(ReplicatedStorage.Packages.trove)

local class = {}
class.__index = class

export type self = {
	_trove: Trove.Trove,
	_movements: { [string]: any },
}

function class.new(): setmetatable<self, typeof(class)>
	local self = setmetatable({
		_trove = Trove.new(),
		_movements = {},
	}, class)

	return self
end

function class:add(self: self, movementName: string, movementModule: any)
	if movementModule.new then
		local movement = movementModule.new(self)
		self._movements[movementName] = movement
		self._trove:Add(movement)
	end
end

function class:get(self: self, movementName: string): any
	return self._movements[movementName]
end

function class:start(self: self)
	self._trove:Connect(RunService.Heartbeat, function(deltaTime)
		debug.profilebegin("movement")

		for i, movement in pairs(self._movements :: { [string]: { update: (number) -> ()? } }) do
			if movement.update then
				debug.profilebegin("movement-" .. i)
				movement:update(deltaTime)
				debug.profileend()
			end
		end

		debug.profileend()
	end)
end

function class:destroy(self: self)
	self._trove:Destroy()
end

return class
