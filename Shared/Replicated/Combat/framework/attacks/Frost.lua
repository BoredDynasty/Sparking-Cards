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

-- M1: Gauntlet Punch

function Frost.moveset.M1(player: playerMarshaller.player, attackData, targetInfo)
	local character = player.Character
	local gauntlet = character:FindFirstChild("Gauntlet") :: Model
	local rightArm = character:WaitForChild("Right Arm", 3)
	local animatorController: AnimationController? = nil
	gauntlet = gauntlet:Clone()
	local function attachGauntlet()
		gauntlet.Parent = character
		local primaryPart = gauntlet.PrimaryPart :: BasePart
		-- align the gauntlet with the right arm visually
		local offset = CFrame.new(0, -1, 0)
		gauntlet:SetPrimaryPartCFrame(rightArm.CFrame * offset)

		if not animatorController then
			animatorController = Instance.new("AnimationController")
		end

		-- Create Motor6D
		local motor = Instance.new("Motor6D")
		motor.Name = "GloveMotor"
		motor.Part0 = rightArm
		motor.Part1 = primaryPart
		motor.C0 = CFrame.new(9.25, 0, 0) -- Position of the joint on Part0
		motor.C1 = CFrame.new(0, 0, 0, 0, -90, 0) -- Position of the joint on Part1 (adjust for glove alignment)
		motor.Parent = rightArm

		animatorController.Parent = gauntlet

		-- Set massless and unanchored
		for _, part in ipairs(gauntlet:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
				part.Massless = true
			end
		end
		return gauntlet
	end
	attachGauntlet()
	-- theres combos of 7
	local gauntletCombos = {
		[1] = { "normal", 81021084939952 }, -- normal for well... normal
		[2] = { "backward_throw", 107207958095996 }, -- throw for a throw...
		[3] = { "right_throw", 82258928842933 },
		[4] = { "downwards_throw", 109206938776854 },
		[5] = { "normal", 85269329835096 },
		[6] = { "right_throw", 85269329835096 },
		[7] = { "ultimate_cutscene", 131781435014944 },
	} ---@type {[number]: {string | number}}
	local comboDirections = {
		normal = Vector3.new(0, 0.2, 1),
		backward = Vector3.new(0, -1, -1),
		right = Vector3.new(1, 0, 0),
		downward = Vector3.new(0, -1, 0),
	}

	local identification = player.UserId
	local player_data = orion.player_data[identification]
	assert(player_data, `couldnt get player data in orion table : {orion.player_data}`)
	if not player_data["frost_combo"] then
		player_data["frost_combo"] = {
			combo = 0,
			clock = timer.new(),
		}
		player_data.frost_combo.clock:Start()
	end
	local currentCombo = player_data.frost_combo :: {
		combo: number,
		clock: timer.Timer,
	}
	if currentCombo.clock:GetTime() >= 3 then
		-- reset combo
		currentCombo.combo = 0
		currentCombo.clock:Reset()
	end
	if currentCombo.combo < 1 then
		currentCombo += 1
		currentCombo = currentCombo // 1 -- just to make sure no floats
	end
	if currentCombo.combo >= #gauntletCombos then
		-- reset combo
		currentCombo.combo = 0
		currentCombo.clock:Reset()
	end
	local comboConfig = gauntletCombos[currentCombo]
	assert(comboConfig, "no combo config???")
	Packet.ReplicateAnimation.sendTo({ identification = tostring(comboConfig[2]) }, player)

	-- grab the nearest player
	local nearestPlayer = nearest(character.HumanoidRootPart, 2)
	nearestPlayer = random.shuffle(nearestPlayer)
	nearestPlayer = nearestPlayer[random.integer(1, #nearestPlayer)] :: playerMarshaller.player
	print(nearestPlayer)
	-- teleport player in front of the nearest player
	if not nearestPlayer then
		print("No nearest player found.")
		return
	end
	local targetCharacter = nearestPlayer.Character
	if not targetCharacter then
		print("Target character not found.")
		return
	end
	local targetHumanoidRootPart = targetCharacter.HumanoidRootPart
	if not targetHumanoidRootPart then
		print("Target HumanoidRootPart not found.")
		return
	end
	-- Look vector angle * 180 means the direction the player is facing is infront of them
	local targetPosition = targetHumanoidRootPart.Position + targetHumanoidRootPart.CFrame.LookVector * 2
	local targetCFrame = CFrame.new(targetPosition, targetHumanoidRootPart.Position)
	character:SetPrimaryPartCFrame(targetCFrame)
end

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
					damage({
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
