--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)

-- stores.luau
-- a wrapper for profilestore

local stores = {
	server = {},
	profile_key = "playerstore",
}

local profiles = stores.server

local player_related = profilestore.New(stores.profile_key, profilestructure)

function stores.load(player: playerMarshaller.player)
	-- Start profile session with timeout
	local profile: typeof(player_related:StartSessionAsync("", {}))?

	profile =
		--promise
		--.retry(function()
		-- return
		player_related:StartSessionAsync(`player:{player.UserId}`, {
			Cancel = function()
				return player:IsDescendantOf(Players) == false
			end,
		})
	--end, 9999)
	--:expect() :: typeof(player_related:StartSessionAsync("", {}))?
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

			profile.Data.LastLogin = DateTime.now().UnixTimestamp

			profile:Reconcile()
			profile:Save()
		else
			profile:EndSession()

			warn("Data not loaded for " .. player.DisplayName .. ", session ended.")
		end
		--elseif profile == nil then
		--player:Kick("The Roblox Servers are on fire. Try rejoining.")
	end

	return profile
end

function stores.get(player: playerMarshaller.player)
	local value = nil

	value = promise
		.new(function()
			local profile = profiles[player]

			if not profile and profile == nil then
				Packet.SendNotification.sendTo({
					message = "Couldn't get data",
					title = "Profile not found",
					type = "error",
				}, player)

				return nil
			end

			return profile
		end)
		:awaitValue()

	return value :: typeof(player_related:StartSessionAsync("", {}))
end

function stores.wrapSave(player: playerMarshaller.player)
	local profile = stores.get(player)

	profile:Reconcile()
	profile:Save()

	Packet.SendNotification.sendTo({
		message = "Your data has just been saved.",
		title = "Data Saved",
		type = "info",
	}, player)

	return true
end

local function notifyWarning(player: playerMarshaller.player)
	Packet.SendNotification.sendTo({
		message = "Something went wrong with the current operation.",
		title = "Task failed.",
		type = "warning",
	}, player)
end

-- native methods

function stores:deductPrims(player: playerMarshaller.player, amount: number)
	local profile = stores.get(player)

	promise
		.new(function()
			profile.Data.Prisms -= amount
		end)
		:andThen(nil)
		:catch(function()
			notifyWarning(player)
		end)

	return true
end

function stores:addPrisms(player: playerMarshaller.player, amount: number)
	local profile = stores.get(player)

	promise
		.new(function()
			profile.Data.Prisms += amount
		end)
		:andThen(nil)
		:catch(function()
			notifyWarning(player)
		end)

	return true
end

function stores:deductCards(player: playerMarshaller.player, name: string, amount: number)
	local profile = stores.get(player)

	promise
		.new(function()
			if table.find(profile.Data.Cards, name) then
				if profile.Data.Cards[name] <= 0 then
					return
				end
				profile.Data.Cards[name] -= amount or 1
			end
		end)
		:andThen(nil)
		:catch(function()
			notifyWarning(player)
		end)

	return true
end

function stores:resetCards(player: playerMarshaller.player)
	local profile = stores.get(player)

	promise
		.new(function()
			profile.Data.Cards = {}
		end)
		:andThen(nil)
		:catch(function()
			notifyWarning(player)
		end)

	return true
end

function stores:addCard(player: playerMarshaller.player, name: string, amount: number)
	local profile = stores.get(player)

	promise
		.new(function()
			if table.find(profile.Data.Cards, name) then
				profile.Data.Cards[name] += amount or 1
			else
				profile.Data.Cards[name] = amount or 1
			end
		end)
		:andThen(nil)
		:catch(function()
			notifyWarning(player)
		end)

	return true
end

-- native functions

function stores.getPrisms(player: playerMarshaller.player)
	local profile = stores.get(player)

	if not profile then
		return 0
	end

	return profile.Data.Prisms
end

return stores
