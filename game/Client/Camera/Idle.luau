--!strict

--[=[
	Idle
	@class Idle

	Applies a gentle sway to the camera when the player is idle.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)

local Idle = {}
Idle.__index = Idle

function Idle.new(cameraController)
	local self = setmetatable({}, Idle)

	self._cameraController = cameraController
	self._config = CameraConfig.Idle
	self._character = playerMarshaller.get().Character
	self._humanoid = self._character:WaitForChild("Humanoid")
	self._lastMoveTime = os.clock()
	self._isIdle = false

	return self
end

function Idle:Update(deltaTime: number, cframe: CFrame): CFrame
	if self._humanoid.MoveDirection.Magnitude > 0 then
		self._lastMoveTime = os.clock()
		self._isIdle = false
		return cframe
	end

	if not self._isIdle and os.clock() - self._lastMoveTime > self._config.IdleTime then
		self._isIdle = true
	end

	if self._isIdle then
		local t = os.clock()
		local x = math.noise(t * self._config.Speed, 0, 0) * 2 - 1
		local y = math.noise(0, t * self._config.Speed, 0) * 2 - 1
		local offset = Vector3.new(x, y, 0) * self._config.Intensity
		return cframe * CFrame.new(offset)
	end

	return cframe
end

function Idle:Destroy()
	-- Nothing to clean up
end

return Idle
