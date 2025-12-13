--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(script.Parent.CardLibrary)
local combo = require(ReplicatedStorage.Combat.framework.utils.combo)
local future = require(ReplicatedStorage.Packages.future)
local grip = require(ReplicatedStorage.Combat.framework.utils.grip)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)

--[[
	### orion.luau

	This module serves as the main entry point for the orion combat framework.
	It provides functions to register attacks, and manage attack data
]]

local orion = {
	framework = script.Parent.framework,
	passives = script.Parent.Passives,
	strike = script.Parent.Strike,
	libray = CardLibrary,
}

local player_data = {}

local attack_modules = {}

local events = ReplicatedStorage.Events

-- Type definitons
export type attack_type = "M1" | "Skill" | "Ultimate" | "Support"
export type attack_module = {
	moveset: {
		M1: ((Player, ...any?) -> ...any?)?,
		Skill: ((Player, ...any?) -> ...any?)?,
		Ultimate: ((Player, ...any?) -> ...any?)?,
		Support: ((Player, ...any?) -> ...any?)?,
	},
}

type PlayerData = {
	player: Player,
	profile: { Data: profilestructure.profile },
	current_card: string,
	combo_info: combo.ComboData,
	shield_info: unknown,
}

grip.auto_update()

local get_profile = events:WaitForChild("GetProfile") :: RemoteFunction

local function expectProfile()
	local fut = future.new(function()
		return get_profile:InvokeServer()
	end)

	return fut:Await()
end

--[[
	Should be ran on the client side.
]]
function orion.registerPlayer(player: Player, profile: { Data: profilestructure.profile })
	local identification = player.UserId

	profile = profile or expectProfile()

	local equippedCard = if profile then profile.Data.EquippedCard else "Cryo"
	-- if the profile exists, use the current existing card, else use the "Cryo" placeholder

	local attack_module = orion:GetAttackModule(equippedCard)

	local max_combo: number
	if attack_module then
		local ok, singleton: attack_module? = pcall(require, attack_module)
		if not ok and not singleton then
			warn("Couldn't require singleton")

			return
		end

		max_combo = singleton:GetMaxCombo()
	end

	if not max_combo then
		max_combo = 3
	end

	table.insert(player_data, {
		player = player,
		profile = profile,
		current_card = equippedCard,
		combo_info = combo.new(max_combo),
	})
end

--[[
	Execute an attack

	@param `player` The player the attack should be executed for
	@param `attack_type` The attack type: `M1 | Skill | Ultimate | Support`
	@param `...` a variadic for other parameters that should be passed on to the attack function

	```luau
	local info, data = orion:execute("Skill")
	-- info, data == observer.Meta<any?>

	print(info:Get(), data:Expect())

	-- do whatever else with your info and data ig
	```
]]
function orion:execute(player: Player, attack_type: attack_type, ...: any?): ...observer.Meta<any?>
	local attack_module = nil

	local data = orion:GetPlayerData(player)

	attack_module = orion:GetAttackModule(data.current_card)

	if not attack_module then
		warn("Couldn't fetch attack module: ", data.current_card)

		return
	end

	local ok, singleton: attack_module? = pcall(require, attack_module)
	if not ok and not singleton then
		warn("Couldn't require singleton")

		return
	end

	local attack_function = singleton.moveset[attack_type]

	if not attack_function and type(attack_function) ~= "function" then
		warn("attack function not found")

		return
	end

	return attack_function(player, ...)
end

--[[
	Get player data by player instance

	@param `player` The player to retrieve data for
	@return The player data table, or nil if not found
]]
function orion:GetPlayerData(player: Player): PlayerData?
	for i, data in ipairs(player_data :: { PlayerData }) do
		if data.player == player then
			return data
		end
	end

	return nil
end

--[[
	Get attack module by card name

	@param `card_name` The name of the card to retrieve the module for
	@return The attack module, or nil if not found
]]
function orion:GetAttackModule(card_name: string): ModuleScript
	return attack_modules[card_name]
end

return orion
