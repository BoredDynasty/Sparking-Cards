--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local CombatModule = require(script.Parent.Parent.CombatModule)
local Promise = require(ReplicatedStorage.Packages.promise)

local Frost = CombatModule.new("Frost")

function Frost:Skill(character, trove, targetPosition, range, position)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return Promise.reject("No HumanoidRootPart found")
	end

	local startPosition = CFrame.new(rootPart.Position, position)
	local shardsNum = 10
	local shard = Instance.new("Part")
	shard.Size = Vector3.new(1, 1, 3)
	shard.Color = Color3.new(0.5, 0.8, 1)
	shard.Material = Enum.Material.Ice
	shard.Anchored = true
	shard.CanCollide = false

	for i = 1, shardsNum do
		local newShard = trove:Add(shard:Clone())
		newShard.CFrame = startPosition * CFrame.new(math.random(-5, 5), math.random(-5, 5), -i * 5)
		newShard.Parent = Workspace

		local tweenInfo = TweenInfo.new(0.5)
		local tween = TweenService:Create(newShard, tweenInfo, { CFrame = newShard.CFrame * CFrame.new(0, 0, -20) })
		trove:Add(tween)
		tween:Play()

		trove:Add(Promise.delay(1):andThen(function()
			newShard:Destroy()
		end))
	end

	return Promise.resolve()
end

return Frost
