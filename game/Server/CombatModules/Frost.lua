--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- In construction

local cooldown: { Player? } = {}

local TInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

local function iceShards(player: Player, position: Vector3)
	if table.find(cooldown, player) then
		print("ice shard cooldown")
		return
	end
	table.insert(cooldown, player)
	task.delay(5, function()
		local needle = table.find(cooldown, player)
		if needle then
			print("removing cooldown for: ", player)
			table.remove(cooldown, needle)
		end
	end)
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart

	local multiplier = 70

	local startPosition = CFrame.new(rootPart.Position, position)
	-- local goal = startPosition.LookVector * multiplier

	local shardsNum = math.random(8, 15)

	local shardIncrements = multiplier / shardsNum

	local assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder

	local shard = assets:FindFirstChild("IceShard") :: UnionOperation

	for i = 1, shardsNum do
		local newShard = shard:Clone()
		newShard.Anchored = true
		newShard.CanCollide = false

		local x, y, z =
			math.random(30, 50) / 30 * i, math.random(30, 50) / 30 * i * 2, math.random(30, 50) / 30 * i

		newShard.Size = Vector3.new(0, 0, 0)

		local orientation = Vector3.new(math.random(-30, 30), math.random(-180, 180), math.random(-30, 30))
		newShard.Orientation = orientation

		local shardPosition = rootPart.Position + startPosition.LookVector * (shardIncrements * i)
		newShard.Position = Vector3.new(shardPosition.X, shardPosition.Y or position.Y, shardPosition.Z)
		print("shard position 1: ", shardPosition.Y, "shard position 2: ", position.Y)
		local newSize = Vector3.new(x, y, z)
		local divisor = 2.5
		local newPosition = newShard.Position + Vector3.new(0, y / divisor, 0)

		local tween = TweenService:Create(newShard, TInfo, { Size = newSize, Position = newPosition })

		newShard.Parent = Workspace
		tween:Play()

		local charactersHit = {}

		newShard.Touched:Connect(function(otherPart: BasePart)
			local parent = otherPart.Parent :: BasePart
			if parent:FindFirstChild("Humanoid") and parent ~= character and not charactersHit[parent] then
				charactersHit[otherPart.Parent] = true

				local humanoid_ = parent:FindFirstChild("Humanoid") :: Humanoid
				local damagePoints = 30
				if humanoid_ then
					humanoid_:TakeDamage(damagePoints)
				end
			end
		end)
		task.spawn(function()
			local reverseTween = TweenService:Create(
				newShard,
				TInfo,
				{ Size = Vector3.new(0, 0, 0), Position = Vector3.new(shardPosition.X, 0, shardPosition.Z) }
			)
			task.wait(3)
			reverseTween:Play()

			reverseTween.Completed:Wait()
			newShard:Destroy()
		end)
		local delayInt = math.random(1, 100) / 1000
		task.wait(delayInt)
	end
	print("frost done")
end

return iceShards
