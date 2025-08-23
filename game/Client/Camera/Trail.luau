--!strict

--[=[
	Trail
	@class Trail

	Adds a trailing effect to the camera based on the character's velocity.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)

local Trail = {}
Trail.__index = Trail

function Trail.new(cameraController)
	local self = setmetatable({}, Trail)

	self._cameraController = cameraController
	self._config = CameraConfig.Trail
	self._character = playerMarshaller.get().Character
	self._humanoid = self._character:WaitForChild("Humanoid")
	self._rootPart = self._humanoid.RootPart

	return self
end

function Trail:Update(deltaTime: number, cframe: CFrame): CFrame
	if not self._rootPart then
		return cframe
	end

	local velocity = self._rootPart.AssemblyLinearVelocity
	local speed = self._humanoid.WalkSpeed
	local newOffset = self._config.Offset * velocity.Magnitude / (speed * 2)
	local cameraOffset = self._humanoid.CameraOffset:Lerp(newOffset, self._config.TrailAlpha)
	self._humanoid.CameraOffset = cameraOffset

	return cframe
end

function Trail:Destroy()
	-- Nothing to clean up
end

return Trail
