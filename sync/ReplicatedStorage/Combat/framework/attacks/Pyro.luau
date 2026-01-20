--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
local Packet = require(ReplicatedStorage.Packet)

local combo = require(ReplicatedStorage.Combat.framework.utils.combo)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local grip = require(ReplicatedStorage.Combat.framework.utils.grip)
local impact = require(ReplicatedStorage.Combat.framework.effects.impact)
local knockback = require(ReplicatedStorage.Combat.Strike.knockback)
local nearest = require(ReplicatedStorage.Combat.hitbox.nearest)
local orion = require(ReplicatedStorage.Combat.orion)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local rocks = require(ReplicatedStorage.Combat.framework.visuals.rocks)
local space = require(ReplicatedStorage.Modules.Serialization.space)
local sword = require(ReplicatedStorage.Combat["combat-styles"].sword)
local visuals = require(ReplicatedStorage.Combat.framework.visuals)

-- Pyro.luau

local pyro = {
	moveset = {},
	lib = CardLibrary.PyroKatana,
}

local function comboToAnimationId(combo: number): string
	if combo == 1 then
		return "rbxassetid://123950065803851" -- M1_1
	elseif combo == 2 then
		return "rbxassetid://117366009412180" -- M1_2
	elseif combo == 3 then
		return "rbxassetid://89377068894374" -- M1_3
	else
		return "rbxassetid://123950065803851" -- Default to M1_1 if out of range
	end
end

function pyro.moveset:M1(player: Player, ...: any?): any?
	print("Pyro M1_1 executed for player:", player.Name)
	-- Implement the actual attack logic here

	local character = player.Character or player.CharacterAdded:Wait()

	local sword_asset = character:FindFirstDescendant("Katana_Asset")

	local player_data = orion:GetPlayerData(player)
	assert(player_data, "no player data???????")

	local singleton = player_data.element_singleton :: typeof(sword.new(player, ""))
	if not singleton then
		player_data.element_singleton = sword.new(player, "Katana")

		singleton = player_data.element_singleton :: typeof(sword.new(player, ""))
		singleton:Equip()
	end

	singleton:Activate()

	local nearest_players = nearest(character.PrimaryPart, CardLibrary.PyroKatana, 10)
	for _, other_player in ipairs(nearest_players) do
		singleton:OnTouched(other_player.Character.PrimaryPart)
	end

	return true
end

function pyro.moveset:Skill(player: Player, ...: any?): any?
	print("Pyro Skill executed for player:", player.Name)
	-- Implement the actual attack logic here

	-- a slash

	return true
end

return pyro
