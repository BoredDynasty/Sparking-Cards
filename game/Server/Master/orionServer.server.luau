--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local orion = require(ReplicatedStorage.Combat.orion)

-- Wait for Orion to be initialized if this script runs very early
if not orion.RegisterAttack then
	warn("OrionAttackRegistry: Orion module not fully loaded or InitServer not called yet. Waiting...")
	repeat
		task.wait()
	until orion.RegisterAttack
end

-- Placeholder for a custom visual effect function (defined further down or in a separate module)
local function placeholderVisualEffect(player: Player, attackData: table)
	print("Orion VFX: Playing placeholder visual effect for", attackData.Name, "triggered by", player.Name)
	local char = player.Character
	if char and char.PrimaryPart then
		local part = Instance.new("Part")
		part.BrickColor = BrickColor.Random()
		part.Material = Enum.Material.Neon
		part.Size = Vector3.new(3, 3, 3)
		part.Position = char.PrimaryPart.Position + char.PrimaryPart.CFrame.LookVector * 5
		part.Anchored = true
		part.CanCollide = false
		part.Parent = workspace
		Debris:AddItem(part, 1) -- Effect lasts 1 second
	end
end

-- M1 Attack Example
local m1_BasicPunch = {
	Name = "BasicPunch_M1", -- Added a name for easier reference in VFX etc.
	Type = "M1",
	Input = Enum.UserInputType.MouseButton1, -- Orion's client input handler will check this
	Damage = 10,
	Range = 6, -- Used by simple hitbox check in current Orion.ExecuteAttack
	Cooldown = 0.5,
	AnimationId = "rbxassetid://YOUR_PUNCH_ANIMATION_ID", -- Replace with actual ID
	SoundId = "rbxassetid://YOUR_PUNCH_SOUND_ID", -- Replace with actual ID
	Hitbox = { Shape = "Box", Size = Vector3.new(3, 3, 5), Offset = Vector3.new(0, 0, 2.5) }, -- More detailed hitbox
	OnExecute = function(player: Player, attackData: table)
		print(player.Name, "is executing M1 Punch (via Orion OnExecute callback)")
	end,
	OnHit = function(sourcePlayer: Player, targetPlayer: Player, damageAmount: number, attackData: table)
		print(sourcePlayer.Name, "landed BasicPunch_M1 on", targetPlayer.Name, "for", damageAmount, "damage.")
	end,
	OnBlock = function(sourcePlayer: Player, targetPlayer: Player, attackData: table)
		print(targetPlayer.Name, "blocked BasicPunch_M1 from", sourcePlayer.Name)
	end,
}
orion.RegisterAttack("BasicPunch_M1", m1_BasicPunch)

-- Skill ('E') Attack Example
local skill_Fireball = {
	Name = "Fireball_Skill",
	Type = "Skill",
	Input = Enum.KeyCode.E, -- Orion's client input handler will check this
	Damage = 25,
	Range = 30, -- For targeting or projectile max distance
	Cooldown = 5,
	AnimationId = "rbxassetid://YOUR_FIREBALL_CAST_ANIM_ID",
	SoundId = "rbxassetid://YOUR_FIREBALL_SOUND_ID",
	VisualEffect = placeholderVisualEffect, -- Assigning the placeholder VFX function
	-- Projectile logic would typically be in OnExecute or a separate system called by it
	Hitbox = { Shape = "Sphere", Radius = 2 }, -- For the fireball projectile
	OnExecute = function(player: Player, attackData: {})
		print(player.Name, "is casting Fireball_Skill")
		-- Placeholder for projectile creation:
		-- local projectile = Instance.new("Part") -- create and configure projectile
		-- projectile.Velocity = player.Character.HumanoidRootPart.CFrame.LookVector * 50
		-- Add to Debris, connect Touched event for HandleDamage
	end,
	OnHit = function(sourcePlayer: Player, targetPlayer: Player, damageAmount: number, attackData: table)
		print(sourcePlayer.Name, "hit", targetPlayer.Name, "with Fireball_Skill for", damageAmount, "damage.")
		-- Apply burning status effect, etc.
	end,
}
orion.RegisterAttack("Fireball_Skill", skill_Fireball)

-- Ultimate ('R') Attack Example
local ultimate_MeteorStrike = {
	Name = "MeteorStrike_Ultimate",
	Type = "Ultimate",
	Input = Enum.KeyCode.R, -- Orion's client input handler will check this
	Damage = 100,
	Range = 50, -- Area of effect radius
	Cooldown = 60,
	AnimationId = "rbxassetid://YOUR_METEOR_CHANNEL_ANIM_ID",
	SoundId = "rbxassetid://YOUR_METEOR_IMPACT_SOUND_ID",
	VisualEffect = function(player: Player, attackData: table)
		print("Orion VFX: Playing METEOR STRIKE visual effect for", player.Name)
		-- More complex VFX logic here
		local targetPos = player.Character.HumanoidRootPart.Position
			+ player.Character.HumanoidRootPart.CFrame.LookVector * 20
		local meteorEffect = Instance.new("Explosion")
		meteorEffect.BlastRadius = attackData.Range or 10
		meteorEffect.BlastPressure = 0 -- We handle damage via Orion.HandleDamage
		meteorEffect.Position = targetPos
		meteorEffect.Parent = workspace
	end,
	Cutscene = "MeteorStrike_IntroCutscene", -- Placeholder ID for a cutscene
	Hitbox = { Shape = "Cylinder", Radius = 15, Height = 10 }, -- Large AoE
	OnExecute = function(player: Player, attackData: {})
		print(player.Name, "is calling down a MeteorStrike_Ultimate!")
		if attackData.Cutscene then
			print("Orion: Triggering cutscene:", attackData.Cutscene)
			-- Fire a remote event to client to play cutscene
			-- game.ReplicatedStorage.RemoteEvents.PlayCutsceneEvent:FireClient(player, attackData.Cutscene)
		end
		-- After cutscene / channel time, trigger AoE damage
		task.delay(3, function() -- Placeholder for channel time or cutscene duration
			print("MeteorStrike_Ultimate impacting now!")
			-- AoE damage logic: find all players in range and call orion.HandleDamage
		end)
	end,
	OnHit = function(sourcePlayer: Player, targetPlayer: Player, damageAmount: number, attackData: table)
		print(
			sourcePlayer.Name,
			"'s MeteorStrike_Ultimate hit",
			targetPlayer.Name,
			"for",
			damageAmount,
			"damage."
		)
	end,
}
orion.RegisterAttack("MeteorStrike_Ultimate", ultimate_MeteorStrike)

print("OrionAttackRegistry: Example attacks registered.")

-- Example for a card-based skill (like Frost)
-- This would be registered similarly, but its 'Input' might be nil if not tied to a direct key.
-- It would be triggered by CombatHandler.server.lua calling orion.ExecuteAttack("Frost_Primary")
local cardSkill_FrostNova = {
	Name = "FrostNova_CardSkill",
	Type = "CardSkill", -- Custom type if desired, or just "Skill"
	Input = nil, -- Not directly from keyboard input via Orion client handler
	Damage = 20,
	Cooldown = 10,
	AnimationId = "rbxassetid://YOUR_FROSTNOVA_ANIM_ID",
	SoundId = "rbxassetid://YOUR_FROSTNOVA_SOUND_ID",
	VisualEffect = function(player: Player, attackData: table)
		print("Orion VFX: FrostNova visual effect for", player.Name)
		-- Create frost ring effect around player
	end,
	Hitbox = { Shape = "Sphere", Radius = 15 }, -- AoE around the caster
	OnExecute = function(player: Player, attackData: table)
		print(player.Name, "is casting FrostNova (Card Skill)")
		-- AoE damage logic around the player
		local playerPos = player.Character.HumanoidRootPart.Position
		for _, otherPlayer in ipairs(game.Players:GetPlayers()) do
			if
				otherPlayer ~= player
				and otherPlayer.Character
				and otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			then
				local distance = (otherPlayer.Character.HumanoidRootPart.Position - playerPos).Magnitude
				if distance <= (attackData.Hitbox.Radius or 15) then
					orion.HandleDamage(player, otherPlayer, attackData.Damage, attackData.Name)
				end
			end
		end
	end,
	OnHit = function(sourcePlayer: Player, targetPlayer: Player, damageAmount: number, attackData: table)
		print(
			sourcePlayer.Name,
			"'s FrostNova hit",
			targetPlayer.Name,
			"for",
			damageAmount,
			"and applied slow."
		)
		-- Apply slow status effect to targetPlayer
	end,
}
orion.RegisterAttack("FrostNova_CardSkill", cardSkill_FrostNova)

print("OrionAttackRegistry: FrostNova_CardSkill registered.")
