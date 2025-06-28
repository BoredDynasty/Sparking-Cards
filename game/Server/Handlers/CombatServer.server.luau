--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatStructure = require(ReplicatedStorage.Structures.CombatStructure)
local playerMarshaller = require(script.Parent.Parent.Parent.ReplicatedStorage.Utility.playerMarshaller)
-- local Frost = require(ServerScriptService.CombatModules.Frost) -- Commented out, Orion will handle attacks

local orion = require(ReplicatedStorage.Combat.orion) -- Require Orion framework
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
orion.InitServer() -- Initialize Orion on the server

-- // Types

type skill_parameters = {
	Position: CFrame | Vector3,
}

-- // Requires

-- // Variables

print("Running combat handler server (now with Orion integration)")

local assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") :: Folder -- Orion creates its own if not present

-- // Util

-- The existing 'SkillEvents' RemoteEvent can be repurposed or replaced by Orion's 'Orion_ExecuteAttack' event.
-- For this integration, let's assume the client will now use Orion's events for M1, Skill, Ultimate.
-- However, if 'SkillEvents' is used for other purposes or by legacy systems, it might need specific handling.
-- For now, we'll focus on how card-based skills could trigger Orion attacks.

local skillEvent = remoteEvents:FindFirstChild("SkillEvents") :: RemoteEvent -- This might be legacy or for specific non-Orion skills
if not skillEvent then
	warn(
		"CombatHandler: 'SkillEvents' RemoteEvent not found. Card-specific skills might not work unless migrated to Orion."
	)
end

local getProfile = remoteEvents:FindFirstChild("GetProfile") :: BindableFunction
if not getProfile then
	warn("CombatHandler: 'GetProfile' BindableFunction not found. Cannot determine current card.")
end

local function getCurrentCard(player: Player): string?
	if not getProfile then
		return nil
	end
	local profile: typeof(profilestructure) = getProfile:Invoke(player) -- Corrected Invoke call
	if profile and profile.EquippedCard then
		local equipped: string = profile.EquippedCard
		print(player.Name .. " has an equipped card of", equipped)
		return equipped
	else
		print(player.Name .. " has no profile or equipped card found.")
		return nil
	end
end

-- This function will now translate a card-specific skill activation into an Orion attack.
-- The client should ideally send an attackName directly if using Orion's input system.
-- This handler remains for card-based skill triggers if they are separate from Orion's direct M1/Skill/Ultimate inputs.
local function handleCardSkillEvent(
	player: playerMarshaller.player,
	skillIdentifier: string,
	params: skill_parameters?
)
	print(player.Name, "triggered card skill event:", skillIdentifier, params)

	local currentCard = getCurrentCard(player)
	if not currentCard then
		warn("CombatHandler: No current card for", player.Name, "- cannot execute card skill via Orion.")
		return
	end

	-- Example: Map card and skillIdentifier to an Orion attackName
	-- This mapping logic would need to be defined based on your game's design.
	local attackName -- string?

	if currentCard == "Frost" and skillIdentifier == "PrimaryAbility" then -- Example identifier
		-- Let's assume "Frost_Primary" is an attack registered in Orion
		attackName = "Frost_Primary"
		-- The 'Frost' module's logic ( Frost(player, data.Position) ) would need to be
		-- encapsulated within an Orion attack definition for "Frost_Primary".
		-- Orion's ExecuteAttack doesn't directly take 'params' in its current generic form,
		-- but attack-specific logic within Orion (OnExecute, OnHit) can use data passed during registration or from player state.
		-- If 'params' like a target position are needed, the Orion attack definition would need to handle it,
		-- possibly by reading from a player's target or mouse hit managed by a client-side script that calls Orion.
		-- For now, we'll assume 'params' might be used by a more advanced Orion setup or specific attacks.
		if params and params.Position then
			-- This is tricky. Orion's ExecuteAttack is generic.
			-- Attack-specific data like target position needs to be handled by the attack's own logic,
			-- potentially set via a separate mechanism before ExecuteAttack, or the attack itself determines targets.
			-- For simplicity, we're showing that 'params' might exist, but direct usage in orion.ExecuteAttack is not standard.
			print(
				"CombatHandler: Skill",
				skillIdentifier,
				"for card",
				currentCard,
				"requires position:",
				params.Position
			)
		end
	else
		warn("CombatHandler: No Orion attack mapped for card", currentCard, "and skill", skillIdentifier)
		return
	end

	if attackName then
		print("CombatHandler: Executing Orion attack", attackName, "for", player.Name, "due to card skill.")
		-- Note: orion.ExecuteAttack as defined takes (player, attackName).
		-- If 'params' are essential for the execution logic (e.g. target position for a projectile),
		-- the attack registered in Orion under 'attackName' must be designed to acquire these params.
		-- This might involve the client sending them with the Orion_ExecuteAttack remote event,
		-- or the attack logic itself raycasting / finding targets.
		orion.ExecuteAttack(player, attackName)
	else
		print("CombatHandler: Could not determine Orion attack name for card skill.")
	end
end

if skillEvent then
	-- Assuming skillEvent now sends (player: Player, skillIdentifier: string, params: table?)
	-- The client-side call to :FireServer() for this event would need to be updated accordingly.
	skillEvent.OnServerEvent:Connect(handleCardSkillEvent)
else
	print("CombatHandler: Not connecting to 'SkillEvents' as it was not found.")
end

-- Note: The original Frost(player, data.Position) call is now expected to be
-- handled by registering "Frost_Primary" (or similar) as an attack in Orion.
-- The Frost.lua module itself would need to be refactored into an Orion attack definition.
-- For example, in some server script where you register attacks:
--
-- local frostPrimaryAttack = {
--   Type = "Skill", -- or "CardSkill" if you want a new category
--   Input = nil, -- Not tied to a direct key, but triggered by card logic
--   Damage = 15,
--   Cooldown = 5,
--   AnimationId = "rbxassetid://YOUR_FROST_ANIM_ID",
--   SoundId = "rbxassetid://YOUR_FROST_SOUND_ID",
--   Hitbox = { Shape = "Cone", Range = 10, Angle = 60 }, -- Example
--   OnExecute = function(player, attackData)
--     -- Logic that used to be in Frost.lua might go here or be called from here.
--     -- For example, find target position if needed, create visual effects.
--     -- This function is executed on the server.
--     print(player.Name, "is executing Frost_Primary (via Orion)")
--     local targetPos = player:GetAttribute("TargetPosition") -- Example: client sets this attribute
--     if targetPos then
--       -- Create frost visual effect at targetPos
--     end
--   end,
--   OnHit = function(sourcePlayer, targetPlayer, damageAmount, attackData)
--     print("Frost_Primary hit", targetPlayer.Name, "for", damageAmount)
--     -- Apply slowing effect, etc.
--   end
-- }
-- orion.RegisterAttack("Frost_Primary", frostPrimaryAttack)
