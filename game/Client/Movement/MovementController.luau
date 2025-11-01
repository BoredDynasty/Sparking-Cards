--!nonstrict
--[=[
	MovementController
	@class MovementController

	Orchestrates character movement by requiring and initializing various movement modules.
	It manages a central Trove instance for cleanup and operates on a single Heartbeat connection
	for performance. It also handles the state of the character's movement.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local promise = require(ReplicatedStorage.Packages.promise)
local trove = require(ReplicatedStorage.Packages.trove)

local controller = {}
controller.__index = controller

export type self = {
	_trove: typeof(trove.new()),
	_movements: { [string]: any },
}

function controller.new(): setmetatable<self, typeof(controller)>
	local self = setmetatable({
		_trove = trove.new(),
		_movements = {},
	}, controller)

	return self
end

function controller:Add(self: self, movementName: string, movementModule: any)
	if movementModule.new then
		local movement = movementModule.new(self)
		self._movements[movementName] = movement
		self._trove:Add(movement)
	end
end

function controller:Get(self: self, movementName: string): any
	return self._movements[movementName]
end

function controller:Start(self: self)
	return promise
		.new(function(resolve)
			self._trove:Connect(RunService.Heartbeat, function(deltaTime)
				debug.profilebegin("movement")

				for i, movement in pairs(self._movements :: { [string]: { Update: (number) -> ()? } }) do
					if movement.Update then
						debug.profilebegin("movement-" .. i)
						movement:Update(deltaTime)
						debug.profileend()
					end
				end

				debug.profileend()
			end)

			resolve()
		end)
		:catch(print)
end

function controller:Destroy(self: self)
	self._trove:Destroy()
end

return controller
