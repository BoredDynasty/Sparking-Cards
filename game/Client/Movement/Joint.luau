--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove).new()

-- Joint.luau
-- a module for making the character animation (lag)
-- just like Spider-Man into the spider-verse.

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local joints = {} :: { [number]: Motor6D }

local frameRate = 60
local totalStep = 0

local lastJointCFrames = {} :: { CFrame }

local function getJoints(part: Instance)
	for _, child in part:GetChildren() do
		if child:IsA("Motor6D") then
			joints[#joints + 1] = child
		end
	end
	return joints
end

local function updateJoints()
	for _, inst in pairs(character:GetDescendants()) do
		getJoints(inst)
	end

	character.DescendantAdded:Connect(function(descendant)
		getJoints(descendant)
	end)
end

updateJoints()

characterMarshaller.added(player, updateJoints)

trove:Connect(RunService.Stepped, function(_, deltaTime: number)
	local frame_rate = math.clamp(frameRate, 0, 60)

	local frame_time = 1 / frame_rate

	if frame_rate >= 60 then
		return
	end

	if totalStep > 0 then
		for i, transform in pairs(lastJointCFrames) do
			local j = joints[i]

			if not j then
				continue
			end

			j.Transform = transform
		end
	elseif totalStep <= 0 then
		for i, motor in pairs(joints) do
			lastJointCFrames[i] = motor.Transform
		end
	end

	if totalStep < frame_time then
		totalStep += deltaTime

		return
	end

	totalStep = 0
end)

return {
	_trove = trove,
}
