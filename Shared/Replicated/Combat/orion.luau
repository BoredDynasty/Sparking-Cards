--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(script.Parent.CardLibrary)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local productMarshaller = require(ReplicatedStorage.Products.productMarshaller)
local profileMarshaller = require(ReplicatedStorage.Datastore.profileMarshaller)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
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

-- Type definitons
export type attack_type = "M1" | "Skill" | "Ultimate" | "Support"
export type attack_module = {
	M1: (any) -> any?,
	Skill: (any) -> any?,
	Ultimate: (any) -> any?,
	Support: (any) -> any?,
}

function orion.registerPlayer(player: playerMarshaller.player & Player)
	local identification = player.UserId
	local profile = nil :: typeof(profilestructure)?
	local profilePromise = promise.new(function(resolve, reject)
		if profileMarshaller.server[player] then
			resolve(profileMarshaller.server[player])
		else
			reject("Couldn't get profile from the profileMarshaller")
		end
		return profile
	end)
	local worked, result = profilePromise:await()
	assert(worked, result)
	profile = result :: typeof(profilestructure)
	local equippedCard = profile.EquippedCard
	local data = {
		profile = profile,
		equippedCard = equippedCard,
	}
	playerMarshaller.removing(function(otherPlayer: playerMarshaller.player)
		if otherPlayer == player then
			task.defer(function()
				table.clear(orion.player_data[otherPlayer.UserId])
			end)
		end
	end)

	orion.player_data[identification] = data
end

function orion:execute(player: playerMarshaller.player, attack_type: attack_type, ...: any?): any?
	local attack_module = nil
	local playerData = orion.player_data[player.UserId]
	local equippedCard = playerData.equippedCard
	if not equippedCard then
		warn("No equipped card found for player:", player.Name)
		return nil
	end
	-- use a promise
	local attackModulePromise = promise.new(function(resolve, reject)
		local modulePath = `{script.Parent}/framework/attacks/{equippedCard}`
		local success, result = pcall(require, modulePath)
		if success then
			resolve(result)
		else
			reject("Attack module couldn't be loaded: " .. tostring(result))
		end
	end)
	local worked, result = attackModulePromise:await()
	assert(worked, "Couldn't require attack module")
	attack_module = result :: attack_module & any
	local ret_value = nil
	if attack_module and attack_module[attack_type] then
		local attack_function = attack_module[attack_type] :: (playerMarshaller.player, ...any?) -> ...any?
		if attack_function and type(attack_function) == "function" then
			ret_value = attack_function(player, ...)
		end
	end
	return ret_value
end

return orion
