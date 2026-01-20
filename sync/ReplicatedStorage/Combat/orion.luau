--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(script.Parent.CardLibrary)
local combo = require(ReplicatedStorage.Combat.framework.utils.combo)
local future = require(ReplicatedStorage.Packages.future)
local grip = require(ReplicatedStorage.Combat.framework.utils.grip)
local retryer = require(ReplicatedStorage.Utility.retryer)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

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
export type AttackType = "M1" | "Skill" | "Ultimate" | "Support"

type AttackFunction = (Player, ...any) -> unknown
export type AttackModule = {
	GetMaxCombo: () -> number,
	moveset: {
		AttackType: AttackFunction,
	},
}

type PlayerData = {
	player: Player,
	profile: typemarshaller.Profile,
	current_card: string,
	combo_info: combo.ComboData,
	shield_info: unknown,
	element_active: boolean, -- if we initialized the attack stuff
	element_singleton: any,
}

grip.auto_update()

local get_profile = events.GetProfile

local function expectProfile()
	local fut = future.new(function()
		return get_profile:InvokeServer()
	end)

	return fut:Await() :: typemarshaller.Profile
end

--[[
	Should be ran on the client side.
]]
function orion.new(player: Player, profile: typemarshaller.Profile)
	profile = profile or expectProfile()

	local equippedCard = "Cryo"
	if profile and profile.Data then
		equippedCard = profile.Data.equipped_card
	else
		equippedCard = "Cryo"
	end
	-- if the profile exists, use the current existing card, else use the "Cryo" placeholder

	local attack_module = orion:GetAttackModule(equippedCard)

	local max_combo: number
	if attack_module then
		local ok, fut = orion:RequireAttackModule(attack_module)
		if not ok then
			warn("Couldn't require attack module: ", ok)

			return
		end

		local _, singleton: AttackModule = fut:Expect("Couldn't :Expect() singleton")

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
		element_active = false,
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
function orion:Execute(player: Player, attack_type: AttackType, ...: any?)
	local attack_module = nil

	local data = orion:GetPlayerData(player)
	assert(data, "Failed to fetch player data.")

	attack_module = orion:GetAttackModule(data.current_card)

	if not attack_module then
		warn("Couldn't fetch attack module: ", data.current_card)

		return
	end

	local ok, fut = orion:RequireAttackModule(attack_module)

	if not ok then
		warn("Couldn't require attack module: ", ok)

		return
	end

	local _, singleton: AttackModule = fut:Expect("Couldn't :Expect() singleton")

	local attack_function = singleton.moveset[attack_type] :: AttackFunction

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

function orion:RequireAttackModule(module: ModuleScript)
	return retryer.delay(0.01, 10, function()
		return future.Try(require, module)
	end)
end

return orion
