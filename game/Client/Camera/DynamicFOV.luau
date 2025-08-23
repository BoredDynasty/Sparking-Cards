--!strict

--[=[
	DynamicFOV
	@class DynamicFOV

	Manages the camera's Field of View (FOV) with smooth transitions.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)

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

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
	self._currentTween = TweenService:Create(self._camera, tweenInfo, { FieldOfView = targetFOV })
	self._currentTween:Play()
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
