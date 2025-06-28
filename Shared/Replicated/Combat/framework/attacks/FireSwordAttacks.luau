--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local orion = require(ReplicatedStorage.Combat.orion)
local clientcast = require(ReplicatedStorage.ClientModules.clientcast)
local Maid = require(ReplicatedStorage.Utility.Maid)
local Players = game:GetService("Players")
local PlaceholderEffects = require(ReplicatedStorage.Combat.framework.effects.PlaceholderEffects)

-- Fire Sword M1 - Attack 1
local FireSword_M1_1: orion.AttackData = {
	Name = "FireSword_M1_1",
	Type = "M1",
	InputType = "Action",
	InputAction = "PrimaryAttack",

	Damage = 14,
	Cooldown = 0.6,
	Range = 9,
	ActiveDuration = 0.3,

	AnimationId = "rbxassetid://YOUR_FIRE_SWORD_SLASH1_ANIM",
	SoundId = "rbxassetid://YOUR_SWORD_SWOOSH_SOUND",

	MaxCombo = 4,
	NextComboAttack = "FireSword_M1_2",

	HitboxProvider = function(player: Player, attackData: orion.AttackData): clientcast.HitboxConfig
		local char = player.Character
		if not char or not char.PrimaryPart then return {} end
		-- Example: A wide, arcing hitbox for a sword slash
		return {
			Shape = "Box", -- Could be a custom shape or multiple boxes for better arc
			Size = Vector3.new(2, 5, 7), -- Thin, tall, long
			CFrame = char.PrimaryPart.CFrame * CFrame.new(0, 0, -3.5) * CFrame.Angles(0, math.rad(-15), 0), -- Slightly angled forward slash
			Filter = {char},
		}
	end,
	VisualEffectClient = function(player, ad, maid) PlaceholderEffects.PlaySimpleSpark(player, ad, maid) end,
	OnHitServer = function(sourcePlayer, targetPlayer, damage, ad)
		print(sourcePlayer.Name .. " landed " .. ad.Name .. " on " .. targetPlayer.Name)
		-- TODO: Apply a small burn DoT
	end,
}

-- Fire Sword M1 - Attack 2
local FireSword_M1_2: orion.AttackData = {
	Name = "FireSword_M1_2",
	Type = "M1",
	InputType = "Action",
	InputAction = "PrimaryAttack",
	Damage = 15,
	Cooldown = 0,
	Range = 9.5,
	ActiveDuration = 0.35,
	AnimationId = "rbxassetid://YOUR_FIRE_SWORD_SLASH2_ANIM",
	SoundId = "rbxassetid://YOUR_SWORD_SWOOSH_SOUND",
	NextComboAttack = "FireSword_M1_3",
	HitboxProvider = function(player: Player, attackData: orion.AttackData): clientcast.HitboxConfig
		local char = player.Character
		if not char or not char.PrimaryPart then return {} end
		return {
			Shape = "Box",
			Size = Vector3.new(2, 5.5, 7.5),
			CFrame = char.PrimaryPart.CFrame * CFrame.new(0, 0, -3.75) * CFrame.Angles(0, math.rad(15), 0), -- Opposite angle
			Filter = {char},
		}
	end,
	VisualEffectClient = function(player, ad, maid) PlaceholderEffects.PlaySimpleSpark(player, ad, maid) end,
	OnHitServer = function(sourcePlayer, targetPlayer, damage, ad) print(sourcePlayer.Name .. " landed " .. ad.Name .. " on " .. targetPlayer.Name) end,
}

-- Fire Sword M1 - Attack 3
local FireSword_M1_3: orion.AttackData = {
	Name = "FireSword_M1_3",
	Type = "M1",
	InputType = "Action",
	InputAction = "PrimaryAttack",
	Damage = 16,
	Cooldown = 0,
	Range = 10,
	ActiveDuration = 0.3,
	AnimationId = "rbxassetid://YOUR_FIRE_SWORD_THRUST_ANIM", -- Example: a thrust
	SoundId = "rbxassetid://YOUR_SWORD_THRUST_SOUND",
	NextComboAttack = "FireSword_M1_4",
	HitboxProvider = function(player: Player, attackData: orion.AttackData): clientcast.HitboxConfig
		local char = player.Character
		if not char or not char.PrimaryPart then return {} end
		return {
			Shape = "Box",
			Size = Vector3.new(2, 2, 8), -- Long and narrow for a thrust
			CFrame = char.PrimaryPart.CFrame * CFrame.new(0, 0, -4),
			Filter = {char},
		}
	end,
	VisualEffectClient = function(player, ad, maid) PlaceholderEffects.PlaySimpleSpark(player, ad, maid) end,
	OnHitServer = function(sourcePlayer, targetPlayer, damage, ad) print(sourcePlayer.Name .. " landed " .. ad.Name .. " on " .. targetPlayer.Name) end,
}

-- Fire Sword M1 - Attack 4 (Finisher)
local FireSword_M1_4: orion.AttackData = {
	Name = "FireSword_M1_4",
	Type = "M1",
	InputType = "Action",
	InputAction = "PrimaryAttack",
	Damage = 22,
	Cooldown = 0,
	Range = 11,
	ActiveDuration = 0.5,
	AnimationId = "rbxassetid://YOUR_FIRE_SWORD_SPIN_ANIM", -- Example: a spinning slash
	SoundId = "rbxassetid://YOUR_FIRE_SWORD_HEAVY_SOUND",
	NextComboAttack = nil, -- End of this combo chain
	HitboxProvider = function(player: Player, attackData: orion.AttackData): clientcast.HitboxConfig
		local char = player.Character
		if not char or not char.PrimaryPart then return {} end
		return { -- Example: A sphere for a spin attack
			Shape = "Sphere",
			Radius = 6,
			Position = char.PrimaryPart.Position,
			Filter = {char},
		}
	end,
	VisualEffectClient = function(player, ad, maid)
		PlaceholderEffects.PlaySimpleSpark(player, ad, maid)
		print("Client VFX: FireSword_M1_4 finisher FLAME SPIN")
	end,
	OnHitServer = function(sourcePlayer, targetPlayer, damage, ad)
		print(sourcePlayer.Name .. " landed finisher " .. ad.Name .. " on " .. targetPlayer.Name)
		-- Apply a strong burn or knockback
	end,
	Knockback = {Force = 30, Duration = 0.25, Mode = "Omni", SourcePosition = player:GetPrimaryPartCFrame().Position},
}


-- Fire Sword E Skill - Burning Blade
local FireSword_BurningBlade_Skill: orion.AttackData = {
	Name = "FireSword_BurningBlade_Skill",
	Type = "Skill",
	InputType = "Action",
	InputAction = "PrimarySkill",
	Damage = 30,
	Cooldown = 10,
	Range = 12,
	ActiveDuration = 0.6,
	AnimationId = "rbxassetid://YOUR_BURNING_BLADE_ANIM",
	SoundId = "rbxassetid://YOUR_FIRE_IGNITE_SOUND",
	HitboxProvider = function(player: Player, attackData: orion.AttackData): clientcast.HitboxConfig
		local char = player.Character
		if not char or not char.PrimaryPart then return {} end
		return { -- Wide cone or multi-box for a sweeping fire attack
			Shape = "Box",
			Size = Vector3.new(8, 5, 8), -- Wide
			CFrame = char.PrimaryPart.CFrame * CFrame.new(0,0,-4),
			Filter = {char},
		}
	end,
	VisualEffectClient = function(player, ad, maid)
		print("Client VFX: Burning Blade activated!")
		-- Create fire particles on the player's sword or a firey slash effect
		PlaceholderEffects.PlayImpactEffect(player.Character.PrimaryPart.Position, ad, maid)
	end,
	OnHitServer = function(sourcePlayer, targetPlayer, damage, ad)
		print(sourcePlayer.Name .. " hit " .. targetPlayer.Name .. " with Burning Blade for " .. damage)
		-- Apply burning DoT
	end,
}

-- Fire Sword Q Ultimate - Inferno Slash
local FireSword_InfernoSlash_Ultimate: orion.AttackData = {
	Name = "FireSword_InfernoSlash_Ultimate",
	Type = "Ultimate",
	InputType = "Action",
	InputAction = "UltimateSkill",
	Damage = 75,
	Cooldown = 90,
	Range = 20, -- Long-range dash/slash
	ActiveDuration = 0.8, -- Duration of the dash/attack
	AnimationId = "rbxassetid://YOUR_INFERNO_SLASH_ANIM",
	SoundId = "rbxassetid://YOUR_FIRE_ULTIMATE_SOUND",

	OnExecuteServer = function(player, ad, targetInfo)
		print(player.Name .. " unleashing ULTIMATE: " .. ad.Name)
		-- Server logic: Rapidly move player forward, create large hitbox or series of hitboxes
		-- For simplicity, hitbox provider could create a long box, or this could trigger custom movement logic
	end,
	HitboxProvider = function(player: Player, attackData: orion.AttackData): clientcast.HitboxConfig
		local char = player.Character
		if not char or not char.PrimaryPart then return {} end
		return { -- Long box for a dashing slash
			Shape = "Box",
			Size = Vector3.new(4, 6, 20),
			CFrame = char.PrimaryPart.CFrame * CFrame.new(0,0,-10), -- Centered on the dash path
			Filter = {char},
		}
	end,
	VisualEffectClient = function(player, ad, maid)
		print("Client VFX: Inferno Slash! FIERY DASH!")
		PlaceholderEffects.PlaySimpleSpark(player, ad, maid)
	end,
	OnHitServer = function(sourcePlayer, targetPlayer, damage, ad)
		print(sourcePlayer.Name .. " hit " .. targetPlayer.Name .. " with Inferno Slash for " .. damage)
	end,
	Knockback = {Force = 50, Duration = 0.4, Mode = "Directional"},
}

-- Fire Sword R Support - Heat Aura
local FireSword_HeatAura_Support: orion.AttackData = {
    Name = "FireSword_HeatAura_Support",
    Type = "Support",
    InputType = "Action",
    InputAction = "SupportSkill",
    Damage = 0, -- Buff/Debuff
    Cooldown = 45,
    Range = 25, -- Aura Radius
    ActiveDuration = 10, -- Aura Duration
    AnimationId = "rbxassetid://YOUR_HEAT_AURA_CAST_ANIM",
    SoundId = "rbxassetid://YOUR_HEAT_AURA_ACTIVATE_SOUND",
    OnExecuteServer = function(player, ad, targetInfo)
        print(player.Name .. " activating Heat Aura: " .. ad.Name)
        -- Server logic: Apply buff to self/allies in range, or debuff to enemies
        -- This would likely involve iterating players in range and applying a temporary modifier/status effect
        -- For now, just a log. Could use a StatusEffectManager.
		PlaceholderEffects.PlayImpactEffect(player.Character.PrimaryPart.Position, ad) -- Visual cue
    end,
    VisualEffectClient = function(player, ad, maid)
        print("Client VFX: Heat Aura pulsing!")
        -- Create a pulsing fire aura visual around the player
    end,
}


return {
	FireSword_M1_1,
	FireSword_M1_2,
	FireSword_M1_3,
	FireSword_M1_4,
	FireSword_BurningBlade_Skill,
	FireSword_InfernoSlash_Ultimate,
    FireSword_HeatAura_Support,
}
