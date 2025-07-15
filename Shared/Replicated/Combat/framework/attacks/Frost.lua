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

type Player = PlayerMarshaller.player
type TargetInfoParams = { targetPosition: Vector3?, targetInstanceId: number? }

local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
if not assetsFolder or not assetsFolder:IsA("Folder") then
	error("Frost.lua: Assets folder not found in ReplicatedStorage.")
end

-- ==== Private Helper Functions for Frost Abilities ====

local function _getAsset(name: string): Instance?
	local asset = assetsFolder:FindFirstChild(name)
	if not asset then
		warn("Frost module: Asset not found -", name)
		return nil
	end
	return asset:Clone()
end

-- ==== Moveset Implementation ====
local Frost = {
	moveset = {
		M1 = nil, -- Snowball Attack
		Skill = nil, -- Ice Shards
		Ultimate = nil, -- Blizzard Rush (Placeholder)
		Support = nil, -- Cryo Barrier (Placeholder)
	},
}

-- M1: Snowball Attack

function Frost.moveset.M1(player: Player, attackData, targetInfo: TargetInfoParams?)
	--
end

-- Skill: Ice Shards
function Frost.moveset.Skill(player: Player, attackData, targetInfo: TargetInfoParams?)
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

	local targetPosition = targetInfo and targetInfo.targetPosition
	if not targetPosition then
		targetPosition = rootPart.Position + rootPart.CFrame.LookVector * (attackData.Range or 25)
		-- warn(player.Name .. " Frost.Skill (IceShards): No targetPosition provided, using default.")
	end

	-- print(player.Name .. " executing Frost Skill (IceShards) towards", targetPosition)

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
					damage({
						amount = damagePoints,
						target = Players[humanoid_.Parent.Name].UserId,
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
function Frost.moveset.Ultimate(player: Player, attackData: AttackData, targetInfo: TargetInfoParams?)
	local character = player.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	-- print(player.Name .. " executing Frost Ultimate (BlizzardRush) with targetInfo:", targetInfo)

	local targetPos = targetInfo and targetInfo.targetPosition
		or rootPart.Position + rootPart.CFrame.LookVector * (attackData.Range or 15)

	-- Example: Simple AoE damage at target position
	local explosion = Instance.new("Explosion")
	explosion.BlastPressure = 0 -- No physics force from this example
	explosion.BlastRadius = attackData.Range or 15
	explosion.Position = targetPos
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.DestroyJointRadiusPercent = 0
	explosion.Visible = false -- Visuals handled by effect notification
	explosion.Parent = Workspace

	-- Hit detection for AoE
	local hitModels = {} ---@type {[Model]:boolean}
	local region = Region3.new(
		targetPos - Vector3.one * explosion.BlastRadius,
		targetPos + Vector3.one * explosion.BlastRadius
	)
	local partsInRegion = Workspace:FindPartsInRegion3(region, character, math.huge)

	for _, partInRegion in ipairs(partsInRegion) do
		local model = partInRegion:FindFirstAncestorWhichIsA("Model")
		if model and model ~= character and not hitModels[model] then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				hitModels[model] = true
				local hitPlayer = game:GetService("Players"):GetPlayerFromCharacter(model)
				if hitPlayer then
					Orion.HandleDamage(
						player,
						PlayerMarshaller.get(hitPlayer),
						attackData.Damage,
						attackData.Name
					)
				else
					humanoid:TakeDamage(attackData.Damage) -- Non-player humanoid
				end
			end
		end
	end

	local effectParams: Packet.EffectParams =
		{ position = targetPos, customData = { radius = explosion.BlastRadius } }
	Packet.Orion_PlayEffectNotif.sendToAllClients({
		effectName = "FrostUltimateExplosion",
		effectParams = effectParams,
	})

	-- print("Frost Ultimate activated by", player.Name, "at", targetPos)
end

-- Support: Cryo Barrier (Placeholder)
function Frost.moveset.Support(player: Player, attackData: AttackData, targetInfo: TargetInfoParams?)
	local character = player.Character
	if not character then
		return
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	-- print(player.Name .. " executing Frost Support (CryoBarrier)")

	local barrier = _getAsset("IceWall") :: Part?
	if not barrier then
		warn("Frost Support: IceWall asset not found.")
		return
	end

	barrier.Anchored = true
	barrier.CanCollide = true
	local barrierSize = Vector3.new(12, 8, 1.5)
	barrier.Size = barrierSize

	local spawnPos = rootPart.CFrame
		* CFrame.new(
			0,
			-rootPart.Size.Y / 2 + barrierSize.Y / 2,
			-(rootPart.Size.Z / 2 + barrierSize.Z / 2 + 2)
		)
	barrier.CFrame = spawnPos

	barrier.Transparency = 0.4
	barrier.Color = Color3.fromRGB(173, 216, 230)
	barrier.Material = Enum.Material.Ice
	barrier.Parent = Workspace

	Debris:AddItem(barrier, attackData.ActiveDuration or 8)
	-- print("Frost Support (CryoBarrier) created by", player.Name)

	local effectParams: Packet.EffectParams = {
		position = barrier.Position,
		customData = { size = barrier.Size, orientation = barrier.Orientation },
	}
	Packet.Orion_PlayEffectNotif.sendToAllClients({
		effectName = "CryoBarrierSpawn",
		effectParams = effectParams,
	})
end

return Frost
