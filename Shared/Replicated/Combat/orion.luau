--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(script.Parent.CardLibrary)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

--[[
	orion.luau

	This module serves as the main entry point for the Orion combat framework.
	It provides functions to register attacks, initialize the server, and manage attack data.
]]

local orion = {
	player_data = {}, ---@type {[number]: {}?}
	framework = script.Parent.framework,
	passives = script.Parent.Passives,
	strike = script.Parent.Strike,
	visuals = script.Parent.Visuals,
	libray = CardLibrary,
}

local attack_modules = {
	Frost = require(script.Parent.framework.attacks.Frost),
	Hydro = require(script.Parent.framework.attacks.Hydro),
}

local events = ReplicatedStorage.Events

-- Type definitons
export type attack_type = "M1" | "Skill" | "Ultimate" | "Support"
export type attack_module = {
	moveset: {
		["M1"]: ((playerMarshaller.player, ...any?) -> ...any?)?,
		["Skill"]: ((playerMarshaller.player, ...any?) -> ...any?)?,
		["Ultimate"]: ((playerMarshaller.player, ...any?) -> ...any?)?,
		["Support"]: ((playerMarshaller.player, ...any?) -> ...any?)?,
	},
}

--[[
	Should be ran on the client side.
]]
function orion.registerPlayer(player: playerMarshaller.player & Player)
	local identification = player.UserId

	-- Add error handling for the GetProfile remote
	local getProfileRemote = events:FindFirstChild("GetProfile")
	if not getProfileRemote then
		warn("GetProfile remote function not found")
		return
	end

	local success, profile = pcall(function()
		return getProfileRemote:InvokeServer(player)
	end)

	if not success then
		warn("Failed to get profile for player:", player.Name, "Error:", profile)
		return
	end

	if not profile then
		warn("No profile returned for player:", player.Name)
		return
	end

	local equippedCard = profile.EquippedCard or "Frost"

	-- change
	local states = {
		Idle = {
			onEnter = function()
				print("Entering Idle State")
			end,
			onExit = function()
				print("Exiting Idle State")
			end,
			transitions = {
				Attack = "Attacking",
			},
		},
		Attacking = {
			onEnter = function()
				print("Entering Attacking State")
			end,
			onExit = function()
				print("Exiting Attacking State")
			end,
			transitions = {
				Idle = "Idle",
			},
		},
		Blocking = {
			onEnter = function()
				print("Entering Blocking State")
			end,
			onExit = function()
				print("Exiting Blocking State")
			end,
			transitions = {
				Idle = "Idle",
			},
		},
	}

	local data = {
		profile = profile,
		equippedCard = equippedCard,
		states = statemachine.new(states, "Idle"),
	}
	orion.player_data[identification] = data
end

function orion:execute(player: playerMarshaller.player, attack_type: attack_type, ...: any?): any?
	local attack_module = nil
	local playerData = orion.player_data[player.UserId]
	if not playerData then
		warn("No player data found for player:", player.Name)
		return nil
	end
	local equippedCard = playerData.equippedCard :: string
	if not equippedCard then
		warn("No equipped card found for player:", player.Name, playerData.equippedCard)
		return nil
	end
	print(1)
	attack_module = attack_modules[equippedCard] :: attack_module
	local ret_value = nil
	print(2)
	print(typeof(attack_module))
	if attack_module and attack_module.moveset[attack_type] then
		local attack_function =
			attack_module.moveset[attack_type] :: (playerMarshaller.player, ...any?) -> ...any?
		if attack_function and type(attack_function) == "function" then
			ret_value = attack_function(player, ...)
			print("attack")
		else
			print("no attack function?")
		end
	end
	print(3)
	return ret_value
end

return orion
