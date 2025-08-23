--!strict

--[=[
	Recoil
	@class Recoil

	Applies a procedural recoil effect to the camera.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)
local Spring = require(ReplicatedStorage.Utility.Spring)

local Recoil = {}
Recoil.__index = Recoil

function Recoil.new(cameraController)
	local self = setmetatable({}, Recoil)

	self._cameraController = cameraController
	self._config = CameraConfig.Recoil
	self._recoilSpring = Spring.new(Vector3.new())

	return self
end

function Recoil:Recoil(strength: number?)
	local recoilStrength = strength or self._config.DefaultStrength
	self._recoilSpring:Impulse(Vector3.new(
		math.random() * recoilStrength,
		math.random() * recoilStrength,
		0
	))
end

function Recoil:Update(deltaTime: number, cframe: CFrame): CFrame
	local recoilOffset = self._recoilSpring:Update(deltaTime)
	return cframe * CFrame.new(recoilOffset)
end

function Recoil:Destroy()
	self._recoilSpring:Destroy()
end

return Recoil
