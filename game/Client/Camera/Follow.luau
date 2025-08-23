--!strict

--[=[
	Follow
	@class Follow

	Tilts the camera based on the mouse position on the screen.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)

local Follow = {}
Follow.__index = Follow

function Follow.new(cameraController)
	local self = setmetatable({}, Follow)

	self._cameraController = cameraController
	self._config = CameraConfig.Follow
	self._player = playerMarshaller.get()
	self._mouse = self._player:GetMouse()

	return self
end

function Follow:Update(deltaTime: number, cframe: CFrame): CFrame
	local newPosition = CFrame.Angles(
		math.rad(((self._mouse.Y - self._mouse.ViewSizeY / 2) / self._mouse.ViewSizeY) * -self._config.MaxTilt),
		math.rad(((self._mouse.X - self._mouse.ViewSizeX / 2) / self._mouse.ViewSizeX) * -self._config.MaxTilt),
		0
	)
	return cframe * newPosition
end

function Follow:Destroy()
	-- Nothing to clean up
end

return Follow
