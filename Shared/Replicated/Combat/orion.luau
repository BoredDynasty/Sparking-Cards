--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(script.Parent.CardLibrary)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local productMarshaller = require(ReplicatedStorage.Products.productMarshaller)
local profileMarshaller = require(ReplicatedStorage.Datastore.profileMarshaller)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local requirer = require(script.Parent.requirer)
local yoink = require(ReplicatedStorage.Utility.yoink)

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
	arbitrary_data = {},
}

local events = ReplicatedStorage.Events

-- Type definitons
export type attack_type = "M1" | "Skill" | "Ultimate" | "Support"
export type attack_module = {
	M1: (any) -> any?,
	Skill: (any) -> any?,
	Ultimate: (any) -> any?,
	Support: (any) -> any?,
}

--[[
	Should be ran on the client side.
]]
function orion.registerPlayer(player: playerMarshaller.player & Player)
	local identification = player.UserId
	local profile = nil :: typeof(profilestructure)?
	profile = (events:FindFirstChild("GetProfile") :: RemoteFunction):InvokeServer(
			player
		) :: typeof(profilestructure)
	print(profile)
	local equippedCard = profile.EquippedCard or "Frost"
	local data = {
		profile = profile,
		equippedCard = equippedCard,
	}
	orion.player_data[identification] = data
end

function orion:execute(player: playerMarshaller.player, attack_type: attack_type, ...: any?): any?
	local attack_module = nil
	local playerData = orion.player_data[player.UserId]
	print(playerData)
	local equippedCard = playerData.equippedCard or "Frost"
	if not equippedCard then
		warn("No equipped card found for player:", player.Name, playerData.equippedCard)
		return nil
	end
	attack_module = requirer.require(equippedCard) :: attack_module
	local ret_value = nil
	if attack_module and attack_module[attack_type] then
		local attack_function = attack_module[attack_type] :: (playerMarshaller.player, ...any?) -> ...any?
		if attack_function and type(attack_function) == "function" then
			ret_value = attack_function(player, ...)
		else
			print("no attack function?")
		end
	else
		warn("no attack module??")
	end
	return ret_value
end

return orion
