--!strict
--[[
	CombatServer.server.luau
	Provides server-side utilities for combat, primarily for initiating attacks programmatically (e.g., by NPCs).
	Most player-driven combat flow is handled directly by Orion and CombatModuleManager.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local ServerScriptService = game:GetService("ServerScriptService")

local PlayerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local Orion = require(ReplicatedStorage.Combat.orion)
local ProfileStructure = require(ReplicatedStorage.Structures.profilestructure) -- For type, if profile needed
local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
local Maid = require(ReplicatedStorage.Utility.Maid)

type Player = PlayerMarshaller.player
type TargetInfoParams = { targetPosition: Vector3?, targetInstanceId: number? } -- From Orion/CombatModuleManager
type ActionType = "M1" | "Skill" | "Ultimate" | "Support" -- Standard action types

local combatServerMaid = Maid.new()

-- Attempt to get the GetProfile bindable function. This is a dependency for getting equipped cards.
-- Ideally, a ProfileService module would be injected or required.
local getProfileBindable: BindableFunction?
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEventsFolder then
	local bindable = remoteEventsFolder:FindFirstChild("GetProfile")
	if bindable and bindable:IsA("BindableFunction") then
		getProfileBindable = bindable
	end
end

if not getProfileBindable then
	warn("CombatServer: 'GetProfile' BindableFunction not found in ReplicatedStorage.RemoteEvents. TriggerServerSideAttack might fail to get equipped cards.")
end

local function getPlayerProfile(player: Player): typeof(ProfileStructure)?
	if not getProfileBindable then
		warn("CombatServer: Cannot get profile for", player.Name, "due to missing GetProfile bindable.")
		return nil
	end
	local success, profile = pcall(getProfileBindable.Invoke, getProfileBindable, player)
	if not success then
		warn("CombatServer: Error invoking GetProfile for", player.Name, ":", profile)
		return nil
	end
	return profile as typeof(ProfileStructure)?
end

-- // Core Functionality: Triggering Server-Side Attacks //

--[[
	Initiates an attack for a given player as if triggered by the server (e.g., for an NPC).
	@param player The player entity that will perform the attack.
	@param actionType The type of action to perform (e.g., "M1", "Skill").
	@param targetInfo Optional targeting information (position, instanceId).
]]
function TriggerServerSideAttack(player: Player, actionType: ActionType, targetInfo: TargetInfoParams?)
	local profile = getPlayerProfile(player)
	local cardName = profile and profile.EquippedCard

	if not cardName then
		warn("CombatServer: Cannot trigger server-side attack for", player.Name, "- no card equipped or profile not found.")
		return
	end

	local cardData = CardLibrary[cardName]
	if not cardData or not cardData.Moveset then
		warn("CombatServer: Card info or moveset not found in CardLibrary for card:", cardName, "Player:", player.Name)
		return
	end

	local attackName: string? = cardData.Moveset[actionType]

	if not attackName then
		warn("CombatServer: No attackName defined in CardLibrary for card '", cardName, "' action '", actionType, "'. Player:", player.Name)
		return
	end

	-- Check if the attack is actually registered in Orion.
	-- CombatModuleManager should have registered it if the module and card are set up correctly.
	if not Orion.RegisteredAttacks[attackName] then
		warn("CombatServer: Attack '", attackName, "' for card '", cardName, "' (action: ", actionType, ") is defined in CardLibrary but not registered in Orion. Player:", player.Name)
		return
	end

	print("CombatServer: Triggering server-side Orion attack:", attackName, "for player:", player.Name)
	-- The `equippedIdentifier` for Orion.ExecuteServerAttackLogic is the cardName itself.
	Orion.ExecuteServerAttackLogic(player, attackName, cardName, targetInfo)
end


-- // Cleanup //
combatServerMaid:GiveTask(function()
	-- print("CombatServer: Shutting down.")
	-- Any other cleanup tasks for this module
end)

script.Destroying:Connect(function()
	combatServerMaid:Destroy()
end)

-- The module primarily provides utility for server-side attack initiation.
-- Player-initiated attacks are handled via client requests to Orion directly.
return {
	TriggerServerSideAttack = TriggerServerSideAttack,
}
