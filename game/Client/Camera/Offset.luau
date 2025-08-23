--!strict

--[=[
	Offset
	@class Offset

	Manages the camera's offset from the character's head.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)

local Offset = {}
Offset.__index = Offset

function Offset.new(cameraController)
	local self = setmetatable({}, Offset)

	self._cameraController = cameraController
	self._config = CameraConfig.Offset
	self._character = playerMarshaller.get().Character
	self._head = self._character:WaitForChild("Head")

	return self
end

function Offset:Update(deltaTime: number, cframe: CFrame): CFrame
	local headPosition = self._head.CFrame.Position
	local cameraPosition = headPosition + self._config.Offset
	local targetCFrame = CFrame.new(cameraPosition, headPosition)

	return cframe:Lerp(targetCFrame, self._config.Smoothness)
end

function Offset:Destroy()
	-- Nothing to clean up
end

return Offset
