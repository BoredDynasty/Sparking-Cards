--!strict

--[=[
	Sway
	@class Sway

	Applies a sway effect to the camera based on mouse movement.
]=]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)

local function lerp(a: number, b: number, t: number)
	return a + (b - a) * math.clamp(t, 0, 1)
end

local Sway = {}
Sway.__index = Sway

function Sway.new(cameraController)
	local self = setmetatable({}, Sway)

	self._cameraController = cameraController
	self._config = CameraConfig.Sway
	self._swayTurn = 0

	return self
end

function Sway:Update(deltaTime: number, cframe: CFrame): CFrame
	local mouseDelta = UserInputService:GetMouseDelta()
	self._swayTurn = lerp(self._swayTurn, math.clamp(mouseDelta.X, -self._config.MaxSway, self._config.MaxSway), self._config.SwayLerpSpeed * deltaTime)
	return cframe * CFrame.Angles(0, 0, math.rad(self._swayTurn))
end

function Sway:Destroy()
	-- Nothing to clean up
end

return Sway
