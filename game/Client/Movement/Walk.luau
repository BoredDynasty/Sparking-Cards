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

local Walk = {}
Walk.__index = Walk

function Walk.new(movementController)
	local self = setmetatable({}, Walk)

	self._movementController = movementController
	self._trove = require(ReplicatedStorage.Packages.trove).new()
	self._character = playerMarshaller.get().Character
	self._humanoid = self._character:WaitForChild("Humanoid")
	self._isMoving = false

	animate.loadAnimation("walk", MovementConfig.Animations.Walk)

	return self
end

function Walk:Update(deltaTime: number)
	local moveDirection = self._humanoid.MoveDirection
	local isMoving = moveDirection.Magnitude > 0.1

	if isMoving and not self._isMoving then
		-- Started moving
		self._isMoving = true
		animate.play("walk", 0.25)
	elseif not isMoving and self._isMoving then
		-- Stopped moving
		self._isMoving = false
		animate.stop("walk")
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

function Walk:Destroy()
	self._trove:Destroy()
end

return Walk
