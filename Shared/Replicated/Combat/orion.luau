--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(script.Parent.CardLibrary)
local data = require(ReplicatedStorage.Combat.framework.utils.data)
local grip = require(ReplicatedStorage.Combat.framework.utils.grip)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)

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

local attack_modules = {}

local events = ReplicatedStorage.Events

-- Type definitons
export type attack_type = "M1" | "Skill" | "Ultimate" | "Support"
export type attack_module = {
	moveset: {
		M1: ((playerMarshaller.player, ...any?) -> ...any?)?,
		Skill: ((playerMarshaller.player, ...any?) -> ...any?)?,
		Ultimate: ((playerMarshaller.player, ...any?) -> ...any?)?,
		Support: ((playerMarshaller.player, ...any?) -> ...any?)?,
	},
}

grip.auto_update()

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

	return data:Insert({
		profile = profile,
		equippedCard = equippedCard,
		state = observer.new("blocking"),
	}, player):catch(print)
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
function orion:execute(
	player: playerMarshaller.player,
	attack_type: attack_type,
	...: any?
): ...observer.Meta<any?>
	local attack_module = nil

	local playerData = data:Fetch(player)
		:catch(function(err: unknown)
			warn("Couldn't load player data: ", err)

			return
		end)
		:expect()
	if not playerData then
		return nil
	end

	local equippedCard = playerData.equippedCard :: string
	if not equippedCard then
		warn("No equipped card found for player:", player.Name, playerData.equippedCard)

		return nil
	end

	attack_module = attack_modules[equippedCard] :: attack_module

	if not attack_module or not attack_module.moveset[attack_type] then
		warn("invalid attack module or type")

		return nil
	end

	local attack_function =
		attack_module.moveset[attack_type] :: (playerMarshaller.player, ...any?) -> ...any?

	if not attack_function and type(attack_function) ~= "function" then
		warn("attack function not found")

		return nil
	end

	return observer.scope(attack_function(player, ...))
end

return orion
