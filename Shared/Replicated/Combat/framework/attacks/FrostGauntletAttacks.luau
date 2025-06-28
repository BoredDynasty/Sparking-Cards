--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local orion = require(ReplicatedStorage.Combat.orion)
local clientcast = require(ReplicatedStorage.ClientModules.clientcast)
local Maid = require(ReplicatedStorage.Utility.Maid)
local Players = game:GetService("Players")
local PlaceholderEffects = require(ReplicatedStorage.Combat.framework.effects.PlaceholderEffects) -- Assuming this path

-- Frost Gauntlet M1 - Attack 1
local FrostGauntlet_M1_1: orion.AttackData = {
	Name = "FrostGauntlet_M1_1",
	Type = "M1",
	InputType = "Action",
	InputAction = "PrimaryAttack", -- Base M1

	Damage = 10,
	Cooldown = 0.7, -- Cooldown for initiating the M1 sequence
	Range = 7,
	ActiveDuration = 0.35,

	AnimationId = "rbxassetid://YOUR_FROST_GAUNTLET_PUNCH1_ANIM",
	SoundId = "rbxassetid://YOUR_FROST_PUNCH_SOUND",

	MaxCombo = 3, -- Max combo count for this weapon type (defined in CardLibrary too)
	NextComboAttack = "FrostGauntlet_M1_2", -- Next attack in the chain

	HitboxProvider = function(player: Player, attackData: orion.AttackData): clientcast.HitboxConfig
		local char = player.Character
		if not char or not char.PrimaryPart then return {} end
		return {
			Shape = "Box",
			Size = Vector3.new(3.5, 4, 4.5),
			CFrame = char.PrimaryPart.CFrame * CFrame.new(0, 0, -2.25),
			Filter = {char},
			Visualize = false,
		}
	end,

	OnExecuteClient = PlaceholderEffects.PlaySimpleSpark, -- Example client execution effect
	VisualEffectClient = nil, -- Can be more specific if needed

	OnHitServer = function(sourcePlayer, targetPlayer, damage, ad)
		print(sourcePlayer.Name .. " landed " .. ad.Name .. " on " .. targetPlayer.Name)
		-- TODO: Apply a minor slow effect
	end,
}

-- Frost Gauntlet M1 - Attack 2
local FrostGauntlet_M1_2: orion.AttackData = {
	Name = "FrostGauntlet_M1_2",
	Type = "M1", -- Still an M1 type for combo logic
	InputType = "Action",
	InputAction = "PrimaryAttack", -- Triggered by subsequent M1 presses

	Damage = 12,
	Cooldown = 0, -- No separate cooldown, relies on combo window and sequence
	Range = 7.5,
	ActiveDuration = 0.4,

	AnimationId = "rbxassetid://YOUR_FROST_GAUNTLET_PUNCH2_ANIM",
	SoundId = "rbxassetid://YOUR_FROST_PUNCH_SOUND_HEAVIER",

	NextComboAttack = "FrostGauntlet_M1_3",

	HitboxProvider = function(player: Player, attackData: orion.AttackData): clientcast.HitboxConfig
		local char = player.Character
		if not char or not char.PrimaryPart then return {} end
		return {
			Shape = "Box",
			Size = Vector3.new(4, 4, 5),
			CFrame = char.PrimaryPart.CFrame * CFrame.new(0, 0, -2.5),
			Filter = {char},
		}
	end,
	OnExecuteClient = PlaceholderEffects.PlaySimpleSpark,
	OnHitServer = function(sourcePlayer, targetPlayer, damage, ad)
		print(sourcePlayer.Name .. " landed " .. ad.Name .. " on " .. targetPlayer.Name)
		-- TODO: Apply a slightly stronger slow or brief freeze
	end,
}

-- Frost Gauntlet M1 - Attack 3 (Combo Finisher)
local FrostGauntlet_M1_3: orion.AttackData = {
	Name = "FrostGauntlet_M1_3",
	Type = "M1",
	InputType = "Action",
	InputAction = "PrimaryAttack",

	Damage = 18,
	Cooldown = 0, -- Cooldown is on the base M1_1
	Range = 8,
	ActiveDuration = 0.5,

	AnimationId = "rbxassetid://YOUR_FROST_GAUNTLET_FINISHER_ANIM",
	SoundId = "rbxassetid://YOUR_FROST_IMPACT_SOUND",

	NextComboAttack = nil, -- End of combo chain

	HitboxProvider = function(player: Player, attackData: orion.AttackData): clientcast.HitboxConfig
		local char = player.Character
		if not char or not char.PrimaryPart then return {} end
		return {
			Shape = "Sphere", -- Example: Finisher is an AoE punch
			Radius = 4,
			Position = char.PrimaryPart.Position + char.PrimaryPart.CFrame.LookVector * 3,
			Filter = {char},
		}
	end,
	VisualEffectClient = function(player, ad, maid)
		PlaceholderEffects.PlaySimpleSpark(player,ad,maid)
		-- Add a bigger frost explosion effect
		print("Client VFX: FrostGauntlet_M1_3 finisher EXPLOSION")
	end,
	OnHitServer = function(sourcePlayer, targetPlayer, damage, ad)
		print(sourcePlayer.Name .. " landed finisher " .. ad.Name .. " on " .. targetPlayer.Name)
		-- TODO: Apply a definite freeze or strong knockback
	end,
	Knockback = { Force = 35, Duration = 0.3, Mode = "Directional" },
}

-- Frost Gauntlet E Skill - Ice Shard
local FrostGauntlet_IceShard_Skill: orion.AttackData = {
	Name = "FrostGauntlet_IceShard_Skill",
	Type = "Skill",
	InputType = "Action",
	InputAction = "PrimarySkill", -- Mapped from 'E' key

	Damage = 25,
	Cooldown = 8,
	Range = 40, -- Max range of projectile
	ActiveDuration = 0.2, -- Cast time / initial hitbox before projectile takes over

	AnimationId = "rbxassetid://YOUR_FROST_ICESHARD_CAST_ANIM",
	SoundId = "rbxassetid://YOUR_ICESHARD_LAUNCH_SOUND",

	IsProjectile = true, -- Mark that this needs projectile logic
	ProjectileSpeed = 70,
	-- ProjectileModule = ReplicatedStorage.Combat.Projectiles.IceShardProjectile, -- Path to a module handling this projectile

	HitboxProvider = nil, -- Projectile will have its own hitbox logic via ProjectileModule

	OnExecuteServer = function(player, ad, targetInfo)
		print(player.Name .. " casting Ice Shard skill: " .. ad.Name)
		-- Server should spawn the projectile here or tell a projectile manager to do so.
		-- For now, we'll just log. Actual projectile system is a TODO.
		local targetPos = targetInfo and targetInfo.targetPosition or (player.Character.PrimaryPart.Position + player.Character.PrimaryPart.CFrame.LookVector * ad.Range)
		print("  Targeting direction towards:", targetPos)
		-- Placeholder for projectile creation:
		-- local projectile = ProjectileManager.Create({ type="IceShard", player=player, targetPos=targetPos, speed=ad.ProjectileSpeed, range=ad.Range })
		-- This would then use Orion_PlayEffectNotif to show client projectile
		-- and projectile itself would detect hits and call orion.HandleDamage via server.
	end,
	VisualEffectClient = function(player, ad, maid)
		print("Client VFX: Ice Shard cast visual")
		PlaceholderEffects.PlaySimpleSpark(player, ad, maid) -- Casting spark
	end,
	OnHitServer = function(sourcePlayer, targetPlayer, damage, ad)
		-- This would be called by the projectile itself upon hitting a target
		print(sourcePlayer.Name .. " hit " .. targetPlayer.Name .. " with Ice Shard for " .. damage)
		-- Apply slow
	end,
}

-- Frost Gauntlet Q Ultimate - Blizzard Rush
local FrostGauntlet_BlizzardRush_Ultimate: orion.AttackData = {
	Name = "FrostGauntlet_BlizzardRush_Ultimate",
	Type = "Ultimate",
	InputType = "Action",
	InputAction = "UltimateSkill", -- Mapped from 'Q' key

	Damage = 20, -- Per hit, this is a multi-hit rush
	Cooldown = 75,
	Range = 15, -- Range of each rush segment / hitbox check
	ActiveDuration = 2.5, -- Total duration of the ultimate

	AnimationId = "rbxassetid://YOUR_BLIZZARD_RUSH_LOOP_ANIM",
	SoundId = "rbxassetid://YOUR_BLIZZARD_RUSH_SOUND_LOOP",

	OnExecuteServer = function(player, ad, targetInfo)
		print(player.Name .. " unleashing ULTIMATE: " .. ad.Name)
		-- This is a complex ultimate, likely involves multiple stages / timed effects / movement changes
		-- For now, just a placeholder. Could change player speed, create damaging aura, etc.
		-- Server would need to manage the duration and periodic damage/hit checks.
		local char = player.Character
		if char and char.PrimaryPart then
			char.PrimaryPart:SetAttribute("IsRushing", true)
			task.delay(ad.ActiveDuration, function()
				if char and char.PrimaryPart then
					char.PrimaryPart:SetAttribute("IsRushing", nil)
				end
			end)
		end
	end,
	VisualEffectClient = function(player, ad, maid)
		print("Client VFX: Blizzard Rush STARTING!")
		-- Play looping frost aura around player
		PlaceholderEffects.PlaySimpleSpark(player, ad, maid) -- Intense sparks
	end,
	-- OnHit for this would be more complex, likely handled by periodic AoE checks during the ultimate's duration
}

-- Frost Gauntlet R Support - Cryo Barrier
local FrostGauntlet_CryoBarrier_Support: orion.AttackData = {
	Name = "FrostGauntlet_CryoBarrier_Support",
	Type = "Support", -- Or "WeaponAbility"
	InputType = "Action",
	InputAction = "SupportSkill", -- Mapped from 'R' key

	Damage = 0, -- No damage, it's a utility skill
	Cooldown = 30,
	Range = 0, -- Self or placed ability
	ActiveDuration = 0.5, -- Cast time

	AnimationId = "rbxassetid://YOUR_CRYO_BARRIER_CAST_ANIM",
	SoundId = "rbxassetid://YOUR_CRYO_BARRIER_CREATE_SOUND",

	OnExecuteServer = function(player, ad, targetInfo)
		print(player.Name .. " deploying Cryo Barrier: " .. ad.Name)
		-- Logic to create an ice wall or a temporary shield for the player/allies
		-- Example: Create a wall in front of the player
		local char = player.Character
		if char and char.PrimaryPart then
			local wall = Instance.new("Part", workspace)
			wall.Size = Vector3.new(10, 8, 2)
			wall.CFrame = char.PrimaryPart.CFrame * CFrame.new(0, wall.Size.Y/2, -wall.Size.Z/2 - 3)
			wall.BrickColor = BrickColor.new(" institucional")
			wall.Material = Enum.Material.Ice
			wall.Anchored = true
			game:GetService("Debris"):AddItem(wall, 10) -- Wall lasts 10 seconds
		end
	end,
	VisualEffectClient = function(player, ad, maid)
		print("Client VFX: Cryo Barrier casting effect")
	end,
}


return {
	FrostGauntlet_M1_1,
	FrostGauntlet_M1_2,
	FrostGauntlet_M1_3,
	FrostGauntlet_IceShard_Skill,
	FrostGauntlet_BlizzardRush_Ultimate,
	FrostGauntlet_CryoBarrier_Support,
}
