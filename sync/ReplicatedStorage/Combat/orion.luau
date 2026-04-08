--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local combo = require(ReplicatedStorage.Combat.framework.utils.combo)
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local sword = require(ReplicatedStorage.Combat["combat-styles"].sword)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- orion.luau
-- the main module of the attack framework.
-- client-sided

-- attuned for testing purposes for now.
-- Pyro Katana

local module = {}
module.registered = {} :: { PlayerData }

local player = Players.LocalPlayer

type PlayerData = {
	player: Player,
	damage_multiplier: number,
	style: typemarshaller.StyleModule,
	profile: typemarshaller.Profile,
	card_name: string,
}

function module.register_player()
	local profile = fetchProfile()

	local data = {
		player = player,
		damage_multiplier = 1.00,
		style = sword.new(player, "Katana"),
		combo_info = combo.new(3),
		profile = profile,
		card_name = "Pyro",
	} :: PlayerData

	table.insert(module.registered, data)
end

function module.get_player_data(): PlayerData?
	for i, data in ipairs(module.registered) do
		if data.player == player then
			return data
		end
	end

	return nil
end

function module.execute(): ModuleScript?
	local player_data = module.get_player_data()
	if not player_data then
		warn("Couldn't index player data.")

		return nil
	end

	local card_name = player_data.card_name

	local combat_module = ReplicatedStorage.Combat.framework.attacks[card_name] :: ModuleScript

	-- the client script will require and run the moveset function.

	return combat_module
end

return module
