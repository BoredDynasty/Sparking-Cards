--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local orion = require(ReplicatedStorage.Combat.orion) -- Assuming orion.AttackData is the type
local clientcast = require(ReplicatedStorage.ClientModules.clientcast)
local Maid = require(ReplicatedStorage.Utility.Maid)
local Players = game:GetService("Players")

-- Placeholder effect functions (these would ideally be in their own effect modules)
local function playPunchVFXClient(player: Player, attackData: orion.AttackData, maid: Maid.Maid)
	print(player.Name .. " playing client VFX for " .. attackData.Name)
	-- Example: Create a quick flash effect
	local char = player.Character
	if char and char.PrimaryPart then
		local flash = Instance.new("Part", char.PrimaryPart)
		flash.BrickColor = BrickColor.Yellow()
		flash.Material = Enum.Material.Neon
		flash.Size = Vector3.new(1,1,1)
		flash.Position = char.PrimaryPart.Position + char.PrimaryPart.CFrame.LookVector * 2
		flash.Anchored = true
		flash.CanCollide = false
		flash.Transparency = 0.5
		maid:GiveTask(flash) -- So it gets destroyed with the maid

		local tweenInfo = TweenInfo.new(0.2)
		local tween = game:GetService("TweenService"):Create(flash, tweenInfo, {Transparency = 1})
		tween:Play()
		maid:GiveTask(tween) -- Add tween to maid for cleanup if interrupted
	end
end

local function playPunchImpactVFXClient(sourcePlayer: Player, targetPosition: Vector3, attackData: orion.AttackData, maid: Maid.Maid)
	print("Playing impact VFX for " .. attackData.Name .. " at " .. tostring(targetPosition))
	local impactEffect = Instance.new("Part", workspace)
	impactEffect.BrickColor = BrickColor.Red()
	impactEffect.Material = Enum.Material.Neon
	impactEffect.Size = Vector3.new(0.5, 0.5, 0.5)
	impactEffect.Position = targetPosition
	impactEffect.Anchored = true
	impactEffect.CanCollide = false
	impactEffect.Transparency = 0.2
	maid:GiveTask(impactEffect)

	local tweenInfo = TweenInfo.new(0.3)
	local tween = game:GetService("TweenService"):Create(impactEffect, tweenInfo, {Size = Vector3.new(1.5,1.5,1.5), Transparency = 1})
	tween:Play()
	maid:GiveTask(tween)
end


local ExamplePunch: orion.AttackData = {
	Name = "ExamplePunch_M1",
	Type = "M1",
	InputType = "Action", -- Will be triggered by an action like "PrimaryAttack"
	InputAction = "PrimaryAttack", -- This action name needs to be mapped from actual input in client script

	Damage = 12,
	Cooldown = 0.6,
	Range = 7, -- Used for server-side validation distance and potentially clientcast config

	AnimationId = "rbxassetid://YOUR_PUNCH_ANIM_ID", -- Replace with actual ID
	SoundId = "rbxassetid://YOUR_PUNCH_SOUND_ID",   -- Replace with actual ID

	ActiveDuration = 0.3, -- How long the hitbox is active and client effects might last

	HitboxProvider = function(player: Player, attackData: orion.AttackData): clientcast.HitboxConfig
		local char = player.Character
		if not char or not char.PrimaryPart then
			return {} -- Return empty or default config if character not ready
		end
		return {
			Shape = "Box",
			Size = Vector3.new(3, 4, 5), -- Width, Height, Depth relative to CFrame
			CFrame = char.PrimaryPart.CFrame * CFrame.new(0, 0, -2.5), -- Offset in front of player
			Filter = {char}, -- Ignore attacker's own character
			Visualize = false, -- Set to true for debugging
		}
	end,

	OnExecuteClient = function(player: Player, attackData: orion.AttackData, maid: Maid.Maid)
		print(player.Name .. " OnExecuteClient for " .. attackData.Name)
		-- Any immediate client-side logic when attack starts (e.g., play local animation through Humanoid:LoadAnimation)
	end,

	VisualEffectClient = playPunchVFXClient, -- Assign the function directly

	OnExecuteServer = function(player: Player, attackData: orion.AttackData, targetInfo: table?)
		print(player.Name .. " OnExecuteServer for " .. attackData.Name)
		-- Server-side logic when attack is confirmed (e.g., consume stamina)
	end,

	OnHitClient = playPunchImpactVFXClient, -- Assign the function directly

	OnHitServer = function(sourcePlayer: Player, targetPlayer: Player, damageAmount: number, attackData: orion.AttackData)
		print(sourcePlayer.Name .. " OnHitServer: Hit " .. targetPlayer.Name .. " with " .. attackData.Name .. " for " .. damageAmount .. " damage.")
		-- Apply additional server-side effects on hit, like status effects
	end,

	OnBlockServer = function(sourcePlayer: Player, targetPlayer: Player, attackData: orion.AttackData)
		print(targetPlayer.Name .. " OnBlockServer: Blocked " .. attackData.Name .. " from " .. sourcePlayer.Name)
		-- Play block sound/VFX for the blocker, notify attacker of block
	end,

	-- Example Knockback
	Knockback = {
		Force = 25,
		Duration = 0.2,
		Mode = "Directional",
	},
}

return { ExamplePunch } -- Return a list of attacks this module defines
