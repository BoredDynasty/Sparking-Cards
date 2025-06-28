--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService") -- Keep for now, might be needed for other modules

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local orion = require(ReplicatedStorage.Combat.orion) -- Orion framework
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary) -- Corrected Path
local Packet = require(ReplicatedStorage.Packet) -- For bytenet if this script handles direct client requests
local Maid = require(ReplicatedStorage.Utility.Maid)

-- Note: orion.InitServer() is now called by orionServer.server.luau.
-- This script should not call it again.

-- // Types

type skill_parameters = {
	Position: CFrame | Vector3,
}

-- // Variables
local combatMaid = Maid.new()
print("CombatServer: Handler script running. Orion server logic is primary.")

-- // Bindable Function for Profile Retrieval
-- It's generally better to have a centralized service/module for profile access
-- rather than direct RemoteFunction/BindableFunction in ReplicatedStorage if possible.
-- For now, we assume 'GetProfile' bindable exists as per original structure.
local getProfileBindable = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("GetProfile")
if not (getProfileBindable and getProfileBindable:IsA("BindableFunction")) then
	warn("CombatServer: 'GetProfile' BindableFunction not found in ReplicatedStorage.RemoteEvents. Card-specific logic might fail.")
	getProfileBindable = nil -- Ensure it's nil if not found or wrong type
end

-- // Utility Functions
local function getPlayerProfile(player: Player): typeof(profilestructure)?
	if not getProfileBindable then
		warn("CombatServer: Cannot get profile for", player.Name, "due to missing GetProfile bindable.")
		return nil
	end
	local success, profile = pcall(getProfileBindable.Invoke, getProfileBindable, player)
	if not success then
		warn("CombatServer: Error invoking GetProfile for", player.Name, ":", profile)
		return nil
	end
	return profile as typeof(profilestructure)?
end

local function getEquippedCardName(player: Player): string?
	local profile = getPlayerProfile(player)
	if profile and profile.EquippedCard then
		-- print("CombatServer:", player.Name, "has an equipped card of", profile.EquippedCard)
		return profile.EquippedCard
	else
		-- print("CombatServer:", player.Name, "has no profile or equipped card found.")
		return nil
	end
end

-- This function maps a generic action (like "M1", "Skill", "Ultimate") and an equipped card
-- to a specific Orion attackName. This is crucial for the new system.
local function getAttackNameForAction(cardName: string, actionType: "M1" | "Skill" | "Ultimate" | "Support"): string?
	local cardInfo = CardLibrary[cardName]
	if not cardInfo or not cardInfo.Moveset then
		warn("CombatServer: Card info or moveset not found in CardLibrary for card:", cardName)
		return nil
	end

	local attackName: string?
	if actionType == "M1" then
		attackName = cardInfo.Moveset.M1
	elseif actionType == "Skill" then
		attackName = cardInfo.Moveset.Skill
	elseif actionType == "Ultimate" then
		attackName = cardInfo.Moveset.Ultimate
	elseif actionType == "Support" then
		attackName = cardInfo.Moveset.Support
	else
		warn("CombatServer: Unknown actionType provided to getAttackNameForAction:", actionType)
		return nil
	end

	if attackName and orion.RegisteredAttacks[attackName] then
		return attackName
	elseif attackName then
		warn("CombatServer: Attack '", attackName, "' for card '", cardName, "' (action: ", actionType, ") is defined in CardLibrary but not registered in Orion.")
		return nil
	else
		warn("CombatServer: No attackName defined in CardLibrary for card '", cardName, "' action '", actionType, "'.")
		return nil
	end
end


-- // Event Handling for Legacy or Specific Card Skill Triggers
-- The primary way to trigger attacks should be via client input calling orion.RequestExecuteAttack,
-- which then sends Orion_ExecuteAttackRequest. This server script (CombatServer)
-- might not need to listen to a generic "SkillEvents" anymore if all combat is through Orion.
-- However, if "SkillEvents" is used for OTHER non-Orion things or specific card interactions
-- that AREN'T direct M1/Skill/Ultimate keybinds, it can remain.

-- Let's assume for now that the client will be refactored to use Orion's input flow.
-- The `handleCardSkillEvent` was for a scenario where a generic `SkillEvents` remote was fired.
-- If the client directly calls `orion.RequestExecuteAttack` with an `attackName` (derived from card + input action),
-- then `CombatServer.server.luau`'s role shifts away from translating generic skill events.
-- Its main role related to Orion would be if it needs to *initiate* an attack *server-side* based on game logic
-- (e.g., an NPC using an ability, or a game event granting a player a free attack).

-- For the refactor, the client (Client.client.luau) will be responsible for:
-- 1. Detecting input (M1, E, Q via keybindlink).
-- 2. Getting the player's equipped card (`profile.EquippedCard`).
-- 3. Using a client-side version of `getAttackNameForAction` (or `CardLibrary` directly) to find the `attackName`.
-- 4. Calling `orion.RequestExecuteAttack(attackName, equippedCardName, targetInfo)`.

-- Therefore, `CombatServer.server.luau` might become much simpler or be merged if its only
-- Orion-related task was translating old events.

-- If there are server-side systems that need to make a player perform an attack:
function TriggerServerSideAttack(player: Player, actionType: "M1" | "Skill" | "Ultimate", targetInfo: table?)
	local cardName = getEquippedCardName(player)
	if not cardName then
		warn("CombatServer: Cannot trigger server-side attack for", player.Name, "- no card equipped.")
		return
	end

	local attackName = getAttackNameForAction(cardName, actionType)
	if not attackName then
		warn("CombatServer: Cannot trigger server-side attack for", player.Name, "- no attackName found for", cardName, actionType)
		return
	end

	-- Since this is server-initiated, we call ExecuteServerAttackLogic directly.
	-- The `equippedIdentifier` here is `cardName`.
	print("CombatServer: Triggering server-side Orion attack:", attackName, "for player:", player.Name)
	orion.ExecuteServerAttackLogic(player, attackName, cardName, targetInfo)
end

-- Example of how this might be used by another server script:
-- require(script).TriggerServerSideAttack(somePlayer, "Skill")

-- Remove legacy SkillEvents listener if client is updated
local skillEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("SkillEvents")
if skillEvent and skillEvent:IsA("RemoteEvent") then
	warn("CombatServer: 'SkillEvents' RemoteEvent still exists. Consider migrating its functionality to the new Orion input flow if it's for player combat actions.")
	-- If it MUST be kept for other reasons:
	-- combatMaid:GiveTask(skillEvent.OnServerEvent:Connect(handleLegacyCardSkillEvent))
	-- where handleLegacyCardSkillEvent would be similar to the old one but call ExecuteServerAttackLogic.
else
	print("CombatServer: 'SkillEvents' RemoteEvent not found or not a RemoteEvent, which is expected if migrated to Orion input flow.")
end


-- Cleanup
combatMaid:GiveTask(function()
	print("CombatServer: Shutting down.")
end)

script.Destroying:Connect(function()
	combatMaid:Destroy()
end)

-- This module now primarily provides utility for server-side attack initiation
-- and a mapping function if needed by other server systems.
-- The main Orion request flow (Client -> Orion_ExecuteAttackRequest -> Server Orion) bypasses this script's direct handling
-- for player-initiated attacks.
return {
	GetEquippedCardName = getEquippedCardName,
	GetAttackNameForAction = getAttackNameForAction,
	TriggerServerSideAttack = TriggerServerSideAttack,
}
