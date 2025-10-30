--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local Trove = require(ReplicatedStorage.Packages.trove)

-- Joint.luau
-- a module for making the character animation (lag)
-- just like Spider-Man into the spider-verse.

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local class = {}
class.__index = class

export type self = {
	_trove: Trove.Trove,
	_joints: { [number]: Motor6D },
	_frameRate: number,
	_totalStep: number,
	_lastJointCFrames: { CFrame },
}

function class.new(movementController): setmetatable<self, typeof(class)>
	local self = setmetatable({
		_trove = Trove.new(),
		_joints = {},
		_frameRate = 60,
		_totalStep = 0,
		_lastJointCFrames = {},
	}, class)

	self:_updateJoints()
	characterMarshaller.added(player, function()
		self:_updateJoints()
	end)

	return self
end

function class:_getJoints(self: self, part: Instance)
	for _, child in part:GetChildren() do
		if child:IsA("Motor6D") then
			table.insert(self._joints, child)
		end
	end
end

function class:_updateJoints(self: self)
	for _, inst in pairs(character:GetDescendants()) do
		self:_getJoints(inst)
	end

	character.DescendantAdded:Connect(function(descendant)
		self:_getJoints(descendant)
	end)
end

function class:update(self: self, deltaTime: number)
	local frame_rate = math.clamp(self._frameRate, 0, 60)

	local frame_time = 1 / frame_rate

	if frame_rate >= 60 then
		return
	end

	if self._totalStep > 0 then
		for i, transform in pairs(self._lastJointCFrames) do
			local j = self._joints[i]

			if not j then
				continue
			end

			j.Transform = transform
		end
	elseif self._totalStep <= 0 then
		for i, motor in pairs(self._joints) do
			self._lastJointCFrames[i] = motor.Transform
		end
	end

	if self._totalStep < frame_time then
		self._totalStep += deltaTime

		return
	end

	self._totalStep = 0
end

function class:destroy(self: self)
	self._trove:Destroy()
end

return class
