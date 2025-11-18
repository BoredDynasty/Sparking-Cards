--!strict
--[[
	CryoArmor.lua
	Passive module example: Provides Cryo armor benefits.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Orion = require(ReplicatedStorage.Combat.orion) -- For AttackData type
local Packet = require(ReplicatedStorage.Packet) -- For sending effects
local PlayerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

type Player = Player
type AttackData = Orion.AttackData

local CryoArmor = {}

-- Configuration for the Cryo Armor passive
local ARMOR_DAMAGE_REDUCTION_PERCENT = 0.10 -- 10% damage reduction
local SLOW_CHANCE_ON_HIT = 0.25 -- 25% chance to slow attacker
local SLOW_DURATION = 2 -- seconds
local SLOW_MAGNITUDE = 0.3 -- 30% speed reduction (applied to WalkSpeed)

function CryoArmor.OnEquip(player: Player, cardName: string)
	-- print(player.Name .. " equipped Cryo Armor passive from " .. cardName .. ". Applying benefits.")

	-- Example: Apply a persistent visual effect (client-side)
	local effectParams: Packet.EffectParams = {
		sourcePlayerId = player.UserId,
		attachToInstanceId = player.Character
				and player.Character.PrimaryPart
				and player.Character.PrimaryPart.InstanceId
			or nil,
		customData = { armorType = "Cryo" },
	}
	Packet.Orion_PlayEffectNotif.sendToAllClients({
		effectName = "PersistentArmorEffect_Cryo", -- Client will handle this effect
		effectParams = effectParams,
	})

	-- Store a marker on the player's character or a server-side table if needed for quick checks
	if player.Character then
		player.Character:SetAttribute("CryoArmorActive", true)
	end
end

function CryoArmor.OnUnequip(player: Player, cardName: string)
	-- print(player.Name .. " unequipped Cryo Armor passive from " .. cardName .. ". Removing benefits.")

	-- Example: Remove the persistent visual effect
	local effectParams: Packet.EffectParams = {
		sourcePlayerId = player.UserId,
		customData = { armorType = "Cryo" },
	}
	Packet.Orion_PlayEffectNotif.sendToAllClients({
		effectName = "RemovePersistentArmorEffect_Cryo", -- Client will handle this
		effectParams = effectParams,
	})

	if player.Character then
		player.Character:SetAttribute("CryoArmorActive", nil)
	end
end

function CryoArmor.OnPlayerDamaged(
	damagedPlayer: Player,
	sourcePlayer: Player?,
	damage: number,
	attackData: AttackData?
)
	if not damagedPlayer.Character or not damagedPlayer.Character:GetAttribute("CryoArmorActive") then
		return 0 -- Return 0 damage reduction if armor not active
	end

	-- print("CryoArmor: Passive triggered for", damagedPlayer.Name)

	-- 1. Damage Reduction
	local damageReduction = damage * ARMOR_DAMAGE_REDUCTION_PERCENT
	-- Note: Actual damage reduction needs to be handled by modifying the damage value
	-- *before* it's applied in Orion.HandleDamage. This hook is more for *reacting* to damage.
	-- For actual reduction, Orion.HandleDamage would need to query active passives for reduction values.
	-- For this example, we'll log it. A more advanced system would have HandleDamage call a
	-- GetDamageMitigation(player, attackData) on the passive manager.
	-- print("CryoArmor:", damagedPlayer.Name, "would take", damageReduction, "less damage due to Cryo Armor.")

	-- 2. Chance to slow attacker
	if
		sourcePlayer
		and sourcePlayer.Character
		and sourcePlayer.Character:FindFirstChildOfClass("Humanoid")
	then
		if math.random() < SLOW_CHANCE_ON_HIT then
			local sourceHumanoid = sourcePlayer.Character:FindFirstChildOfClass("Humanoid")
			if sourceHumanoid then
				-- print("CryoArmor: Applying slow to attacker", sourcePlayer.Name)

				-- Apply slow effect (server-side attribute for example, or a more complex status effect system)
				local originalWalkSpeed = sourceHumanoid:GetAttribute("OriginalWalkSpeed")
					or sourceHumanoid.WalkSpeed
				if not sourceHumanoid:GetAttribute("OriginalWalkSpeed") then
					sourceHumanoid:SetAttribute("OriginalWalkSpeed", originalWalkSpeed)
				end

				sourceHumanoid.WalkSpeed = originalWalkSpeed * (1 - SLOW_MAGNITUDE)
				sourceHumanoid:SetAttribute("IsSlowedByCryoArmor", true)

				-- Notify clients to play slow visual effect on the sourcePlayer
				local slowEffectParams: Packet.EffectParams = {
					targetPlayerId = sourcePlayer.UserId,
					customData = { duration = SLOW_DURATION, magnitude = SLOW_MAGNITUDE },
				}
				Packet.Orion_PlayEffectNotif.sendToAllClients({
					effectName = "ApplySlowEffect",
					effectParams = slowEffectParams,
				})

				task.delay(SLOW_DURATION, function()
					if
						sourceHumanoid
						and sourceHumanoid.Parent
						and sourceHumanoid:GetAttribute("IsSlowedByCryoArmor")
					then
						sourceHumanoid.WalkSpeed = sourceHumanoid:GetAttribute("OriginalWalkSpeed")
							or originalWalkSpeed
						sourceHumanoid:SetAttribute("IsSlowedByCryoArmor", nil)
						sourceHumanoid:SetAttribute("OriginalWalkSpeed", nil)

						local removeSlowEffectParams: Packet.EffectParams =
							{ targetPlayerId = sourcePlayer.UserId }
						Packet.Orion_PlayEffectNotif.sendToAllClients({
							effectName = "RemoveSlowEffect",
							effectParams = removeSlowEffectParams,
						})
						-- print("CryoArmor: Slow expired for", sourcePlayer.Name)
					end
				end)
			end
		end
	end

	-- This function, if it were to modify damage, would return the amount of damage to reduce.
	-- Since it's a reactive hook in this design, it doesn't return anything to modify damage directly here.
end

-- Example: A periodic effect, like a small Cryo aura that does tiny damage or applies chill
-- function CryoArmor.OnInterval(player: Player, deltaTime: number)
--    if not player.Character or not player.Character:GetAttribute("CryoArmorActive") then
--        return
--    end
--    -- print(player.Name .. " CryoArmor OnInterval tick: " .. deltaTime)
--    -- Logic for a periodic aura effect
-- end

return CryoArmor
