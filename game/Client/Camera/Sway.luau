--!nonstrict

--[=[
	Sway
	@class Sway

	Applies a sway effect to the camera based on mouse movement.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)
local lerp = require(StarterPlayer.StarterPlayerScripts.Utilities.lerp)

local Sway = {}
Sway.__index = Sway

function Sway.new(cameraController)
	local self = setmetatable({}, Sway)

	self._cameraController = cameraController
	self._config = CameraConfig.Sway
	self._swayTurn = 0

	return self
end

function Sway:Update(deltaTime: number, coordinate: CFrame): CFrame
	local mouseDelta = UserInputService:GetMouseDelta()
	self._swayTurn = lerp(
		self._swayTurn :: number,
		math.clamp(mouseDelta.X, -self._config.MaxSway, self._config.MaxSway),
		self._config.SwayLerpSpeed * deltaTime
	)
	return coordinate * CFrame.Angles(0, 0, math.rad(self._swayTurn))
end

function Sway:Destroy()
	-- Nothing to clean up
end

return Sway
