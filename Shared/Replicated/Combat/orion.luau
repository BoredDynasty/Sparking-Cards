--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local productMarshaller = require(ReplicatedStorage.Products.productMarshaller)
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
	local profile: typeof(profilestructure) = yoink.boundary:grab("profile_data")
	local equippedCard = profile.EquippedCard
	local data = {
		profile = profile,
		equippedCard = equippedCard,
	}
	-- check for changes
	local equipped_observer = observer.new(equippedCard)
	equipped_observer.Changed:Connect(function()
		-- re-register
		print("Re-registering player:", player.Name, "with new equipped card:", equippedCard)
		orion.registerPlayer(player)

		task.defer(function()
			equipped_observer:Destroy()
		end)
	end)
	playerMarshaller.removing(function(otherPlayer: playerMarshaller.player)
		if otherPlayer == player then
			task.defer(function()
				equipped_observer:Destroy()
				table.clear(orion.player_data[otherPlayer.UserId])
			end)
		end
	end)

	orion.player_data[identification] = data
end

function orion:execute(player: playerMarshaller.player, attack_type: attack_type, ...: any?): any?
	local attack_module = nil
	local playerData = orion.player_data[player.UserId]
	local equippedCard = playerData.EquippedCard or playerData.profile.EquippedCard
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
	attack_module = result :: attack_module & any
	local ret_value = nil
	if attack_module and attack_module[attack_type] then
		local attack_function = attack_module[attack_type]
		if attack_function and type(attack_function) == "function" then
			ret_value = attack_function(player, ...)
		end
	end
	return ret_value
end

return orion
