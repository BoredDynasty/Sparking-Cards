--!strict
--[=[
	Walk
	@class Walk

	Handles the basic walking animation.
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local animate = require(game.StarterPlayer.StarterPlayerScripts.Utilities.animate)
local Signal = require(ReplicatedStorage.Parent.Shared.Replicated.Dependencies.SignalPlus)

local Trove = require(ReplicatedStorage.Packages.trove)

local class = {}
class.__index = class

export type self = {
	_movementController: any,
	_trove: Trove.Trove,
	_character: Model,
	_humanoid: Humanoid,
	_isMoving: boolean,

	startedMoving: Signal.Signal,
	stoppedMoving: Signal.Signal,
}

function class.new(movementController): setmetatable<self, typeof(class)>
	local self = setmetatable({
		_movementController = movementController,
		_trove = Trove.new(),
		_character = playerMarshaller.get().Character,
		_humanoid = playerMarshaller.get().Character:WaitForChild("Humanoid"),
		_isMoving = false,

		startedMoving = Signal.new(),
		stoppedMoving = Signal.new(),
	}, class)

	animate.loadAnimation("walk", MovementConfig.Animations.Walk)

	return self
end

function class:update(self: self, deltaTime: number)
	local moveDirection = self._humanoid.MoveDirection
	local isMoving = moveDirection.Magnitude > 0.1

	if isMoving and not self._isMoving then
		-- Started moving
		self._isMoving = true
		animate.play("walk", 0.25)
		self.startedMoving:Fire()
	elseif not isMoving and self._isMoving then
		-- Stopped moving
		self._isMoving = false
		animate.stop("walk")
		self.stoppedMoving:Fire()
	end

	if self._isMoving then
		local track = animate.getTrack("walk")
		if track then
			if self._humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				track:AdjustSpeed(0.25)
			else
				track:AdjustSpeed(1)
			end
		end
	end
end

function class:destroy(self: self)
	self._trove:Destroy()
	self.startedMoving:Destroy()
	self.stoppedMoving:Destroy()
end

return class
