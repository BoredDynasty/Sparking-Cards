--!strict

--[=[
	Shake
	@class Shake

	Applies a shake effect to the camera.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)

local Shake = {}
Shake.__index = Shake

function Shake.new(cameraController)
	local self = setmetatable({}, Shake)

	self._cameraController = cameraController
	self._config = CameraConfig.Shake
	self._shakeStrength = 0
	self._elapsedTime = 0

	return self
end

function Shake:Shake(strength: number, duration: number)
	self._shakeStrength = strength
	-- TODO: Implement duration
end

function Shake:Update(deltaTime: number, cframe: CFrame): CFrame
	if self._shakeStrength == 0 then
		return cframe
	end

	self._elapsedTime += deltaTime

	local x = math.noise(self._elapsedTime * 20, 0, 0) * 2 - 1
	local y = math.noise(0, self._elapsedTime * 20, 0) * 2 - 1

	local offset = Vector3.new(x, y, 0) * self._shakeStrength
	self._shakeStrength = math.max(0, self._shakeStrength - deltaTime * 5)

	return cframe * CFrame.new(offset)
end

function Shake:Destroy()
	-- Nothing to clean up
end

return Shake
