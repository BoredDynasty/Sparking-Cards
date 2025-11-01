--!nonstrict

--[=[
	DynamicFOV
	@class DynamicFOV

	Manages the camera's Field of View (FOV) with smooth transitions.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local observer = require(ReplicatedStorage.Utility.observer)
local spr = require(ReplicatedStorage.Modules.spr)

local DynamicFOV = {}
DynamicFOV.__index = DynamicFOV

function DynamicFOV.new(cameraController)
	local self = setmetatable({}, DynamicFOV)

	self._cameraController = cameraController
	self._camera = workspace.CurrentCamera
	self._config = CameraConfig
	self._baseFOV = self._config.BaseFOV
	self._currentTween = nil
	self._last_position = observer.new(Vector3.one)
	self._can_spring = observer.new(true)

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

	self._can_spring:Set(false)
	self._currentTween:Wait()
	self._can_spring:Set(false)
end

function DynamicFOV:Update(deltaTime: number, cframe: CFrame): CFrame
	if not self._can_spring:Get() then
		return cframe
	end

	local current_position = cframe.Position
	local displacement = (self._last_position :: Vector3) - current_position

	local distance = displacement.Magnitude

	spr.stop(self._camera, "FieldOfView")
	spr.target(self._camera, 1, 8, {
		FieldOfView = (self._baseFOV :: number) + math.clamp(distance * 0.1, 60, 120),
	})

	return cframe
end

function DynamicFOV:Destroy()
	if self._currentTween then
		self._currentTween:Cancel()
	end
end

return DynamicFOV
