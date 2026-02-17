--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local trove = require(ReplicatedStorage.Packages.trove).new()

-- joint-controller.luau
-- a module for making the character animation (lag)
-- just like Spider-Man into the spider-verse.

local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()

local joints = {} :: { [number]: Motor6D }

local frameRate = 24
local totalStep = 0

local lastJointCFrames = {} :: { CFrame }

local function getJoints(part: Instance)
	for _, child in part:GetChildren() do
		if child:IsA("Motor6D") then
			table.insert(joints, child)
		end
	end
	return joints
end

local function updateJoints()
	for i, inst in pairs(character:GetDescendants()) do
		getJoints(inst)
	end

	trove:Connect(character.DescendantAdded, function(descendant: Instance)
		getJoints(descendant)
	end)
end

updateJoints()

player.CharacterAdded:Connect(updateJoints)

trove:Connect(RunService.Stepped, function(_, deltaTime: number)
	local frame_rate = math.clamp(frameRate, 0, 60)

	local frame_time = 1 / frame_rate

	if totalStep > 0 then
		for i, transform in ipairs(lastJointCFrames) do
			local j = joints[i]

			if not j then
				continue
			end

			j.Transform = transform
		end
	elseif totalStep <= 0 then
		for i, motor in ipairs(joints) do
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
