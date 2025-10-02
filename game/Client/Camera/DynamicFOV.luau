--!strict

--[=[
	DynamicFOV
	@class DynamicFOV

	Manages the camera's Field of View (FOV) with smooth transitions.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)

local DynamicFOV = {}
DynamicFOV.__index = DynamicFOV

function DynamicFOV.new(cameraController)
	local self = setmetatable({}, DynamicFOV)

	self._cameraController = cameraController
	self._camera = workspace.CurrentCamera
	self._config = CameraConfig
	self._baseFOV = self._config.BaseFOV
	self._currentTween = nil

	return self
end

function DynamicFOV:GetBaseFOV(): number
	return self._baseFOV
end

function DynamicFOV:TweenFOV(targetFOV: number, duration: number, override: boolean?)
	if self._currentTween and not override then
		return
	end

	if self._currentTween then
		self._currentTween:Cancel()
	end
	self._currentTween = TweenPlus(self._camera, {
		FieldOfView = targetFOV,
	}, {
		Time = duration,
		EasingStyle = "Circular",
		EasingDirection = "Out",
	})
	self._currentTween:Start()
end

function DynamicFOV:Update(deltaTime: number, cframe: CFrame): CFrame
	return cframe
end

function DynamicFOV:Destroy()
	if self._currentTween then
		self._currentTween:Cancel()
	end
end

return DynamicFOV
