--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
local Cryo = require(ReplicatedStorage.Combat.framework.attacks.Cryo)
local Pyro = require(ReplicatedStorage.Combat.framework.attacks.Pyro)
local combo = require(ReplicatedStorage.Combat.framework.utils.combo)
local future = require(ReplicatedStorage.Packages.future)
local grip = require(ReplicatedStorage.Combat.framework.utils.grip)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
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

local attack_modules = {
	["Cryo"] = Cryo,
	["Pyro"] = Pyro,
}

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

type StyleModule = {
	model: Model,
	player: Player,

	grip_info: grip.GripInfo,
	character: Model,
	_connections: { RBXScriptConnection },
	_hit_cache: { [Player]: number },
	_trail: Trail?,
	_can_hit: boolean,
}

grip.auto_update()

local get_profile = events.GetProfile

local function expectProfile(): typemarshaller.Profile
	local fut = future.new(function()
		return get_profile:InvokeServer() :: typemarshaller.Profile
	end)

	repeat
		task.wait(1)
	--print("pending profile fetch")
	until not fut:IsPending()

	local result = fut:Unwrap()

	--[[
	if not result and RunService:IsStudio() then
		result = { Data = profilestructure }
	end
	--]]

	return result
end

--[[
	Should be ran on the client side.
]]
function orion.new(player: Player, profile: typemarshaller.Profile)
	profile = profile or expectProfile()

	local equipped_card = "Pyro"
	if profile and profile.Data then
		equipped_card = profile.Data.equipped_card
	else
		equipped_card = "Pyro"
	end
	-- if the profile exists, use the current existing card, else use the "Pyro" placeholder

	local attack_module = orion:GetAttackModule(equipped_card)

	if not attack_module then
		warn("Couldn't fetch attack module: ", equipped_card)

		return
	end

	local max_combo = attack_module:GetMaxCombo()

	if not max_combo then
		max_combo = 3
	end

	table.insert(player_data, {
		player = player,
		profile = profile,
		current_card = equipped_card,
		combo_info = combo.new(max_combo),
		element_active = false,
		element_singleton = nil,
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
	if not data then
		warn("Failed to fetch player data.")

		return
	end

	attack_module = orion:GetAttackModule(data.current_card)

	if not attack_module then
		warn("Couldn't fetch attack module: ", data.current_card)

		return
	end

	local attack_function = attack_module.moveset[attack_type] :: AttackFunction

	if not attack_function and type(attack_function) ~= "function" then
		warn("attack function not found")

		return
	end

	-- TODO) instead of a variadic,
	-- use a table, containing any necassary data
	-- e.g: {mouse_pos, camera_pos, ...}

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
function orion:GetAttackModule(card_name: string): AttackModule
	return attack_modules[card_name]
end

function orion:ReconcileElement(player: Player, style: StyleModule, ...): StyleModule
	local player_data = orion:GetPlayerData(player)
	assert(player_data, "no player data???????")

	if not player_data.element_active or not player_data.element_singleton then
		style:Equip()
		player_data.element_active = true
		player_data.element_singleton = style.new(player, ...)

		return player_data.element_singleton
	else
		return player_data.element_singleton
	end
end

return orion
