--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local playerMarshaller = require(script.Parent.Parent.Parent.ReplicatedStorage.Utility.playerMarshaller)

-- In construction

local cooldown: { Player? } = {}
local assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder

local TInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

local function checkDebounce()
	local result = true
	if table.find(cooldown, player) then
		print("cooldown")
		result = false
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
	return result
end

local function snowballed(player: playerMarshaller.player, position: Vector3)
	if not checkDebounce() then
		return
	end

	-- instead of using the availiable module,
	-- we'll make our own system
	local character = player.Character
	local rootPart = character.HumanoidRootPart :: BasePart

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	params.FilterDescendantsInstances = { character }

	local origin = rootPart.Position
	local mousePositition = position
	local direction = (mousePositition - origin).Unit
	local speed = 7 -- studs/s
	local gravity = Vector3.new(0, -workspace.Gravity, 0) * 0.5

	local isActive = false

	local projectile = assets:FindFirstChild("Snowball"):Clone() :: MeshPart
	projectile.CFrame = CFrame.new(origin, origin + direction)
	projectile.Size = Vector3.one
	projectile.CanCollide = false

	local velocity = direction * speed
	local currentPosition = origin
	local connection: RBXScriptConnection? = nil

	local maxDistance = 500
	local totalDistance = 0

	local function boom(hitPosition: Vector3)
		connection:Disconnect()
		projectile:Destroy()

		local alreadyHit = table.create(50)

		local hitbox = assets:FindFirstChild("Snowball"):Clone() :: MeshPart
		hitbox.Position = hitPosition
		hitbox.Size = Vector3.one
		hitbox.CanCollide = false
		hitbox.Parent = workspace

		local potentialHits = workspace:GetPartsInPart(projectile)
		for _, otherPart in pairs(potentialHits) do
			local otherHumanoid: Humanoid? = otherPart.Parent:FindFirstChildOfClass("Humanoid")
			if
				otherHumanoid
				and otherHumanoid ~= character.Humanoid
				and not table.find(alreadyHit, otherHumanoid)
			then
				table.insert(alreadyHit, otherHumanoid)
				otherHumanoid:TakeDamage(10)
			end
		end
	end

	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		local stepVelocity = velocity + gravity * deltaTime
		local stepDisplacement = (velocity + stepVelocity) / 2 * deltaTime -- avg. velocity
		velocity = stepVelocity -- upd. velocity for next frame

		local nextPosition = currentPosition + stepDisplacement
		local rayDirection = nextPosition - currentPosition

		local cast = workspace:Raycast(currentPosition, rayDirection, params)

		local potentialHits = workspace:GetPartsInPart(projectile)
		for _, otherPart in pairs(potentialHits) do
			local otherHumanoid: Humanoid? = otherPart.Parent:FindFirstChildOfClass("Humanoid")
			if otherHumanoid and otherHumanoid ~= character.Humanoid and isActive then
			end
		end

		if cast then
			local hitPosition = cast.Position
			boom(hitPosition)
		else
			currentPosition = nextPosition

			projectile.CFrame = CFrame.new(currentPosition, currentPosition + velocity.Unit)
			totalDistance += rayDirection.Magnitude
			if totalDistance >= maxDistance then
				boom(projectile.Position)
			end
		end
	end)
end

local function iceShards(player: Player, position: Vector3)
	if not checkDebounce() then
		return
	end
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart

	local multiplier = 70

	local startPosition = CFrame.new(rootPart.Position, position)
	-- local goal = startPosition.LookVector * multiplier

	local shardsNum = math.random(8, 15)

	local shardIncrements = multiplier / shardsNum

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
