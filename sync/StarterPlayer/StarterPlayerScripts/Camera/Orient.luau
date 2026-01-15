--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraConfig = require(ReplicatedStorage.Structures.CameraConfig)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local input = require(ReplicatedStorage.Packages.input)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

--[[
   Orient
   @class Orient

   Turns the head or character to where the cursor is pointing.
]]

local Orient = {}
Orient.__index = Orient

function Orient.new<a>(cameraController: a) -- im not typechecking ts
	local self = setmetatable({}, Orient)

	self._cameraController = cameraController
	self._config = CameraConfig.Orient
	self._player = playerMarshaller.get()
	self._character = characterMarshaller.get(self._player)
	self._head = self._character:FindFirstChild("Head", true)
	self._rootPart = self._character:FindFirstChild("HumanoidRootPart") :: BasePart
	self._torso = self._character:FindFirstChild("Torso") :: BasePart
	self._mouse = input.Mouse.new()
	self._neck = self._character:FindFirstChild("Neck", true) :: Motor6D

	self._neck_origin_C0 = self._neck.C0

	self._neck.MaxVelocity = 1 / 3 -- reapeting 0.33

	return self
end

function Orient:Update(deltaTime: number, coordinate: CFrame): CFrame
	local torso_look = self._torso.CFrame.LooKVector :: Vector3
	local head_position = self._head.Position :: Vector3
	if not self._neck then
		return coordinate
	end

	local distance = nil
	local difference = nil

	local point = self._mouse:Project() :: Vector3
	distance = (head_position - point).Magnitude
	difference = head_position.Y - point.Y

	local interpolation = (self._neck.C0 :: CFrame):Lerp(
		(self._neck_origin_C0) :: CFrame
			* CFrame.Angles(
				(math.atan(difference / distance) * self._config.HeadVerticalFactor :: number),
				0,
				(head_position - point).Unit:Cross(torso_look)
			).Y
			* self._config.HeadHorizontalFactor :: number,
		(self._config.UpdateSpeed :: number) / 2
	)

	self._neck.C0 = interpolation

	return coordinate
end

return Orient
