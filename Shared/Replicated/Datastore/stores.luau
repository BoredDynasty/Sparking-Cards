--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)

-- stores.luau
-- a utility for profilestore

local stores = {
	server = {},
}

local profiles = stores.server

local player_related = profilestore.New("player-related", profilestructure)

function stores.onPlayerAdded(player: playerMarshaller.player)
	-- Start profile session with timeout
	local profile: typeof(player_related:StartSessionAsync("", {}))?

	profile = promise
		.retry(function()
			return player_related:StartSessionAsync(`player:{player.UserId}`, {
				Cancel = function()
					return player.Parent ~= Players
				end,
			})
		end, 20)
		:expect() :: typeof(player_related:StartSessionAsync("", {}))?
	print(typeof(profile))

	if profile then
		-- Set up profile
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		-- Handle session end
		profile.OnSessionEnd:Connect(function()
			profiles[player] = nil
			player:Kick("Session Locked, rejoin")
		end)

		if player:FindFirstAncestorOfClass("Players") then
			profiles[player] = profile

			profile.Data.LastLogin = os.time()

			profile:Reconcile()
			profile:Save()
		else
			profile:EndSession()

			warn("Data not loaded for " .. player.DisplayName .. ", session ended.")
		end
	elseif not profile then
		player:Kick("The Roblox Servers are on fire. Try rejoining.")
	end

	return profile
end

function stores.get(player: playerMarshaller.player)
	local value = nil

	promise
		.new(function(resolve, reject)
			local profile = profiles[player]

			if not profile and profile == nil then
				reject("Profile does not exist!")

				Packet.SendNotification.sendTo({
					message = "Couldn't get data",
					title = "Profile not found",
					type = "error",
				}, player)
			end

			value = {
				Data = profile.Data,
				Key = profile.Key,
				LastSaved = profile.LastSavedData,
			}

			resolve({
				Data = profile.Data,
				Key = profile.Key,
				LastSaved = profile.LastSavedData,
			})
		end)
		:andThen(print)
		:catch(warn)

	return value :: typeof(player_related:StartSessionAsync("", {}))
end

function stores.wrapSave(player: playerMarshaller.player)
	local profile = stores.get(player)

	profile:Reconcile()
	profile:Save()

	Packet.SendNotification.sendTo({
		message = "Your data has just been saved.",
		title = "Data Saved",
	}, player)

	return true
end

-- native methods

function stores:deductPrims(player: playerMarshaller.player, amount: number)
	local profile = stores.get(player)

	promise
		.new(function()
			profile.Data.Prisms -= amount
		end)
		:andThen(nil)
		:catch(warn)

	return true
end

function stores:addPrisms(player: playerMarshaller.player, amount: number)
	local profile = stores.get(player)

	promise
		.new(function()
			profile.Data.Prisms += amount
		end)
		:andThen(nil)
		:catch(warn)

	return true
end

return stores
