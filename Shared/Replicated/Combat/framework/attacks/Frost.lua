--!nonstrict

--[[
	Frost.lua
	Combat module for Frost-based abilities (e.g., FrostGauntlet).
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Orion = require(ReplicatedStorage.Combat.orion) -- For AttackData type and Packet
local Packet = require(ReplicatedStorage.Packet) -- For sending effects
local PlayerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local debounce = require(ReplicatedStorage.Combat.framework.utils.debounce).new({
	M1 = 0.23,
	Skill = 10,
	Ultimate = 14,
	Support = 15,
})
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local nearest = require(ReplicatedStorage.Combat.framework.utils.nearest)
local orion = require(ReplicatedStorage.Combat.orion)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local random = require(ReplicatedStorage.Utility.random)
local timer = require(ReplicatedStorage.Modules.timer)

type Player = PlayerMarshaller.player

local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
if not assetsFolder or not assetsFolder:IsA("Folder") then
	error("Frost.lua: Assets folder not found in ReplicatedStorage.")
end

-- ==== Private Helper Functions for Frost Abilities ====

-- ==== Moveset Implementation ====
-- Frost.moveset[move](player, ...)
local Frost = {
	moveset = {
		M1 = nil, -- Gauntlet
		Skill = nil, -- Ice Shards
		Ultimate = nil, -- Blizzard Rush (Placeholder)
		Support = nil, -- Cryo Barrier (Placeholder)
	},
}

-- Skill: Ice Shards
function Frost.moveset.Skill(
	player: playerMarshaller.player,
	targetPosition: Vector3,
	range: number,
	position: Vector3
)
	if not debounce.__call("Skill") then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	local rootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	if not targetPosition then
		targetPosition = rootPart.Position + rootPart.CFrame.LookVector * (range or 25)
		-- warn(player.Name .. " Frost.Skill (IceShards): No targetPosition provided, using default.")
	end

	-- print(player.Name .. " executing Frost Skill (IceShards) towards", targetPosition)

	local multiplier = 70

	local startPosition = CFrame.new(rootPart.Position, position)
	-- local goal = startPosition.LookVector * multiplier

	local shardsNum = random.integer(8, 15)

	local shardIncrements = multiplier / shardsNum

	local shard = fetchAsset("IceShard") :: BasePart
	promise.delay(10):andThen(function()
		shard:Destroy()
	end)

	local TInfo = TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut)

	for i = 1, shardsNum do
		local newShard = shard:Clone()
		newShard.Anchored = true
		newShard.CanCollide = false

		local x, y, z =
			random.integer(30, 50) / 30 * i,
			random.integer(30, 50) / 30 * i * 2,
			random.integer(30, 50) / 30 * i

		newShard.Size = Vector3.new(0, 0, 0)

		local orientation =
			Vector3.new(random.integer(-30, 30), random.integer(-180, 180), random.integer(-30, 30))
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
					local otherPlayer = Players[humanoid_.Parent.Name] :: playerMarshaller.player
					local otherIdentification = otherPlayer.UserId
					damage.__call({
						amount = damagePoints,
						target = otherIdentification,
					})
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

-- Ultimate: Blizzard Rush (Placeholder)
function Frost.moveset.Ultimate(player: Player, attackData, targetInfo)
	--
end

-- Support: Cryo Barrier (Placeholder)
function Frost.moveset.Support(player: Player, attackData, targetInfo)
	--
end

return Frost
