--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(script.Parent.CardLibrary)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
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
	libray = CardLibrary,
}

local attack_modules = {}

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
function orion.registerPlayer(
	player: playerMarshaller.player & Player,
	profile: { Data: profilestructure.profile }
)
	local identification = player.UserId

	if not profile then
		-- Add error handling for the GetProfile remote
		local getProfileRemote = events:FindFirstChild("GetProfile") :: RemoteFunction
		local function expectProfile()
			return promise
				.new(function(resolve)
					local value = getProfileRemote:InvokeServer()

					resolve(value)

					return value
				end)
				:expect()
		end

		profile = expectProfile()
	end

	local equippedCard = if profile then profile.Data.EquippedCard else "Cryo"
	-- if the profile exists, use the current existing card, else use the "Cryo" placeholder

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
