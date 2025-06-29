--!strict
--[[
	Frost.lua
	Combat module for Frost-based abilities (e.g., FrostGauntlet).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local PlayerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local Orion = require(ReplicatedStorage.Combat.orion) -- For AttackData type and Packet
local Packet = require(ReplicatedStorage.Packet) -- For sending effects

type Player = PlayerMarshaller.player
type AttackData = Orion.AttackData -- Use the exported type from orion.luau
type TargetInfoParams = { targetPosition: Vector3?, targetInstanceId: number? }

local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
if not assetsFolder or not assetsFolder:IsA("Folder") then
	error("Frost.lua: Assets folder not found in ReplicatedStorage.")
end

local TWEEN_INFO_QUINT_1S = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
local TWEEN_INFO_LINEAR_0_3S = TweenInfo.new(0.3, Enum.EasingStyle.Linear)

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
local Frost = {}
Frost.moveset = {}

-- M1: Snowball Attack
function Frost.moveset.M1(player: Player, attackData: AttackData, targetInfo: TargetInfoParams?)
	local character = player.Character
	if not character then return end
	local rootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	local targetPosition = targetInfo and targetInfo.targetPosition
	if not targetPosition then
		-- Default to looking forward if no targetPosition (e.g. server initiated without specific target point)
		targetPosition = rootPart.Position + rootPart.CFrame.LookVector * (attackData.Range or 30)
		-- warn(player.Name .. " Frost.M1: No targetPosition provided, using default.")
	end

	-- print(player.Name .. " executing Frost M1 (Snowball) towards", targetPosition)

	local projectile = _getAsset("Snowball") :: MeshPart?
	if not projectile then return end

	projectile.CanCollide = false
	projectile.Anchored = false
	projectile.Size = Vector3.one * 1.5 -- Slightly larger snowball
	local spawnOffset = Vector3.new(0, 2, 0) + rootPart.CFrame.LookVector * 3
	projectile.CFrame = CFrame.new(rootPart.Position + spawnOffset, targetPosition)
	projectile.Parent = Workspace
	Debris:AddItem(projectile, 5) -- Auto-cleanup after 5 seconds

	local direction = (targetPosition - projectile.Position).Unit
	local speed = attackData.ProjectileSpeed or 60 -- Adjusted speed

	projectile.AssemblyLinearVelocity = direction * speed

	local alreadyHit = {} ---@type { [Instance]: boolean }
	local connection: RBXScriptConnection?

	local function cleanupProjectile()
		if connection then connection:Disconnect() connection = nil end
		if projectile and projectile.Parent then projectile:Destroy() end
	end

	local lifeTimer = task.delay(5, cleanupProjectile) -- Max lifetime for projectile

	connection = projectile.Touched:Connect(function(otherPart: BasePart)
		if alreadyHit[otherPart] or alreadyHit[otherPart.Parent] then return end

		local otherModel = otherPart:FindFirstAncestorWhichIsA("Model")
		local otherPlayerCharacter = otherModel and game:GetService("Players"):GetPlayerFromCharacter(otherModel)

		-- Prevent self-damage or hitting already processed parts/models
		if otherModel == character then return end

		local otherHumanoid: Humanoid? = otherModel and otherModel:FindFirstChildOfClass("Humanoid")

		if otherHumanoid then
			if alreadyHit[otherHumanoid] then return end
			alreadyHit[otherHumanoid] = true
			alreadyHit[otherModel] = true

			-- Damage is now primarily handled by Orion's client-side hit reporting (if used for this attack)
			-- or by server-side validation if clientcast is not used for this specific projectile.
			-- If this is a purely server-created and server-authoritative projectile, then:
			-- otherHumanoid:TakeDamage(attackData.Damage)
			-- For now, we assume HandleDamage in Orion will be called via client hit notif or a server-side raycast.
			-- This server-side .Touched is a fallback or for environment interaction.
			print("Frost M1 (Snowball) hit humanoid:", otherModel.Name)
			-- Orion.HandleDamage(player, Players:GetPlayerFromCharacter(otherModel), attackData.Damage, attackData.Name)
			-- ^ This would be if Orion had a direct way to inject a server-detected hit.
			-- For now, client is expected to report this hit if it's client-cast.
			-- If it's server-cast, then this .Touched is the primary detection.

			-- Let's assume for a server projectile, we do minimal effect here and expect client hit notif for damage.
			-- Or, if this M1 is NOT client-cast, then this is where damage would occur.
			-- For simplicity of example, let's assume this M1 is server-authoritative for hits.
			if PlayerMarshaller.get(otherPlayerCharacter) then
				Orion.HandleDamage(player, PlayerMarshaller.get(otherPlayerCharacter), attackData.Damage, attackData.Name)
			else
				otherHumanoid:TakeDamage(attackData.Damage) -- Non-player humanoid
			end

			task.cancel(lifeTimer)
			cleanupProjectile()
		elseif otherPart.CanCollide and not otherPart:IsDescendantOf(character) then
			-- Hit an environment part
			-- print("Frost M1 (Snowball) hit environment part:", otherPart.Name)
			task.cancel(lifeTimer)
			cleanupProjectile()
		end
	end)
end

-- Skill: Ice Shards
function Frost.moveset.Skill(player: Player, attackData: AttackData, targetInfo: TargetInfoParams?)
	local character = player.Character
	if not character then return end
	local rootPart: BasePart? = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	local targetPosition = targetInfo and targetInfo.targetPosition
	if not targetPosition then
		targetPosition = rootPart.Position + rootPart.CFrame.LookVector * (attackData.Range or 25)
		-- warn(player.Name .. " Frost.Skill (IceShards): No targetPosition provided, using default.")
	end

	-- print(player.Name .. " executing Frost Skill (IceShards) towards", targetPosition)

	local baseShard = _getAsset("IceShard") :: UnionOperation?
	if not baseShard then return end

	local numShards = 5
	local spreadAngle = math.rad(25)
	local baseLookDirection = (targetPosition - (rootPart.Position + Vector3.new(0,2,0))).Unit -- Aim from eye level

	for i = 1, numShards do
		local shard = baseShard:Clone()
		shard.Anchored = true
		shard.CanCollide = false -- Shards themselves don't collide, rely on raycasting or Touched for hitbox parts
		shard.Parent = Workspace
		Debris:AddItem(shard, 2) -- Auto-cleanup

		local currentAngle = 0
		if numShards > 1 then
			currentAngle = (-spreadAngle / 2) + (spreadAngle * (i - 1) / (numShards - 1))
		end

		local shardDirection = CFrame.Angles(0, currentAngle, 0) * baseLookDirection
		local startPosition = rootPart.Position + Vector3.new(0,2,0) + shardDirection * 2

		shard.CFrame = CFrame.new(startPosition, startPosition + shardDirection)
		shard.Size = Vector3.new(0.2, 0.2, 1) -- Initial small size

		local endSize = Vector3.new(0.8, 0.8, 3)
		local travelDistance = attackData.Range or 25
		local endPosition = startPosition + shardDirection * travelDistance

		local growTween = TweenService:Create(shard, TWEEN_INFO_QUINT_1S, { Size = endSize, CFrame = CFrame.new(endPosition, endPosition + shardDirection) })
		growTween:Play()

		-- Hit detection for server-created shards:
		-- This simple Touched event is okay for basic effects.
		-- For more precise hit detection, especially for fast projectiles, raycasting (e.g., ClientCast or a server raycast) is better.
		-- If this skill uses client-side hit detection via HitboxProvider in AttackData, this server .Touched might be for environment only or not needed.
		local hitHumanoids = {} ---@type {[Humanoid]: boolean}
		local shardConnection: RBXScriptConnection?
		shardConnection = shard.Touched:Connect(function(hitPart)
			if hitPart:IsDescendantOf(character) then return end -- Don't hit self

			local model = hitPart:FindFirstAncestorWhichIsA("Model")
			if model then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid and not hitHumanoids[humanoid] then
					hitHumanoids[humanoid] = true
					-- Assuming damage is per shard that hits.
					-- If client-cast, client reports hits to Orion.HandleDamage.
					-- If server-authoritative like this, call Orion.HandleDamage.
					local hitPlayer = game:GetService("Players"):GetPlayerFromCharacter(model)
					if hitPlayer then
						Orion.HandleDamage(player, PlayerMarshaller.get(hitPlayer), attackData.Damage / numShards, attackData.Name)
					else
						humanoid:TakeDamage(attackData.Damage / numShards) -- Non-player humanoid
					end

					-- Small visual effect for shard hit
					local effectParams: Packet.EffectParams = { position = shard.Position }
					Packet.Orion_PlayEffectNotif.sendToAllClients({effectName = "FrostShardImpact", effectParams = effectParams})

					shard:Destroy() -- Shard breaks on impact with humanoid
					if shardConnection then shardConnection:Disconnect() shardConnection = nil end
				elseif humanoid == nil and hitPart.CanCollide then -- Hit environment
					shard:Destroy()
					if shardConnection then shardConnection:Disconnect() shardConnection = nil end
				end
			end
		end)

		growTween.Completed:Connect(function()
			if shardConnection then shardConnection:Disconnect() shardConnection = nil end
			if shard and shard.Parent then shard:Destroy() end
		end)

		if numShards > 1 then task.wait(0.03) end
	end
end

-- Ultimate: Blizzard Rush (Placeholder)
function Frost.moveset.Ultimate(player: Player, attackData: AttackData, targetInfo: TargetInfoParams?)
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	-- print(player.Name .. " executing Frost Ultimate (BlizzardRush) with targetInfo:", targetInfo)

	local targetPos = targetInfo and targetInfo.targetPosition or rootPart.Position + rootPart.CFrame.LookVector * (attackData.Range or 15)

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
	local region = Region3.new(targetPos - Vector3.one * explosion.BlastRadius, targetPos + Vector3.one * explosion.BlastRadius)
	local partsInRegion = Workspace:FindPartsInRegion3(region, character, math.huge)

	for _, partInRegion in ipairs(partsInRegion) do
		local model = partInRegion:FindFirstAncestorWhichIsA("Model")
		if model and model ~= character and not hitModels[model] then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				hitModels[model] = true
				local hitPlayer = game:GetService("Players"):GetPlayerFromCharacter(model)
				if hitPlayer then
					Orion.HandleDamage(player, PlayerMarshaller.get(hitPlayer), attackData.Damage, attackData.Name)
				else
					humanoid:TakeDamage(attackData.Damage) -- Non-player humanoid
				end
			end
		end
	end

	local effectParams: Packet.EffectParams = { position = targetPos, customData = { radius = explosion.BlastRadius } }
	Packet.Orion_PlayEffectNotif.sendToAllClients({effectName = "FrostUltimateExplosion", effectParams = effectParams})

	-- print("Frost Ultimate activated by", player.Name, "at", targetPos)
end

-- Support: Cryo Barrier (Placeholder)
function Frost.moveset.Support(player: Player, attackData: AttackData, targetInfo: TargetInfoParams?)
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

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

	local spawnPos = rootPart.CFrame * CFrame.new(0, -rootPart.Size.Y/2 + barrierSize.Y/2, -(rootPart.Size.Z/2 + barrierSize.Z/2 + 2))
	barrier.CFrame = spawnPos

	barrier.Transparency = 0.4
	barrier.Color = Color3.fromRGB(173, 216, 230)
	barrier.Material = Enum.Material.Ice
	barrier.Parent = Workspace

	Debris:AddItem(barrier, attackData.ActiveDuration or 8)
	-- print("Frost Support (CryoBarrier) created by", player.Name)

	local effectParams: Packet.EffectParams = { position = barrier.Position, customData = { size = barrier.Size, orientation = barrier.Orientation } }
	Packet.Orion_PlayEffectNotif.sendToAllClients({effectName = "CryoBarrierSpawn", effectParams = effectParams})
end

return Frost
