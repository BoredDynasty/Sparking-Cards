local PrivateServer = {}
PrivateServer.__index = PrivateServer

-- Variables

local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local MATCH_RETENTION_TIME = 60 * 60 * 24

local Utils = game.ReplicatedStorage:WaitForChild("Utils")
local Promise = require(Utils:WaitForChild("Promise"))
local Signal = require(Utils:WaitForChild("Signal"))
local Thread = require(Utils:WaitForChild("Thread"))

-- Local Functions

local function GetHashMap()
	return MemoryStoreService:GetHashMap("PrivateServers")
end

-- Main

function PrivateServer:ReserverServer(PlaceId)
	--[[
		Reserves a new private server instance for a given place.

		Parameters:
			PlaceId (number) — The ID of the place to reserve a server for.

		Returns:
			AccessCode (string) — Code used to join the reserved server.
			PrivateServerId (string) — Unique ID for the reserved server.

		Notes:
			Returns dummy values in Studio (AccessCode, PrivateServerId) to support development.
	]]
	--

	if game:GetService("RunService"):IsStudio() then
		return "AccessCode", "PrivateServerId"
	else
		return TeleportService:ReserveServer(PlaceId)
	end
end

function PrivateServer:GetPrivateServerDataAsync(PrivateServerId)
	--[[
		Fetches saved private server data from MemoryStore.

		Parameters:
			PrivateServerId (string) — The ID of the server to retrieve.

		Returns:
			Promise<table> — Resolves with the server data object, or nil if not found.
	]]
	--

	local HashMap = GetHashMap()

	print(`[PrivateServer]: Fetching Private Server Data (`, PrivateServerId, ")")

	return Promise.try(function()
		return HashMap:GetAsync(PrivateServerId)
	end)
end

function PrivateServer:RegisterAsync(PrivateServerData)
	--[[
		Registers a new private server by saving its data to MemoryStore.

		Parameters:
			PrivateServerData (table) — Must contain at least a PrivateServerId.

		Returns:
			Promise<void>

		Notes:
			Automatically sets the server State to "Registered".
			Retries up to 5 times with a delay of 2 seconds between attempts.
	]]
	--

	local HashMap = GetHashMap()

	print(`[PrivateServer]: Registering Private Server (`, PrivateServerData, ")")
	PrivateServerData.State = "Registered"

	return Promise.retryWithDelay(function()
		return Promise.try(function()
			return HashMap:SetAsync(
				PrivateServerData.PrivateServerId,
				PrivateServerData,
				MATCH_RETENTION_TIME
			)
		end)
	end, 5, 2)
end

function PrivateServer:UpdateAsync(PrivateServerData)
	--[[
		Updates the stored data of an existing private server.

		Parameters:
			PrivateServerData (table) — The updated data for the server.

		Returns:
			Promise<void>

		Behavior:
			Merges incoming values into the existing entry using UpdateAsync.
			If no entry exists, creates one using the full input data.
	]]
	--

	local HashMap = GetHashMap()

	print(`[PrivateServer]: Updating Private Server Data (`, PrivateServerData, ")")

	return Promise.try(function()
		return HashMap:UpdateAsync(PrivateServerData.PrivateServerId, function(oldValue)
			if oldValue then
				for i, v in pairs(PrivateServerData) do
					oldValue[i] = v
				end

				return oldValue
			else
				return PrivateServerData
			end
		end, MATCH_RETENTION_TIME)
	end)
end

function PrivateServer:CloseAsync(PrivateServerData)
	--[[
		Closes the server and marks it as "Closed" in MemoryStore.

		Parameters:
			PrivateServerData (table) — The server data to update.

		Returns:
			Promise<void>

		Notes:
			Sets the State field to "Closed" before updating MemoryStore.
			Retries up to 5 times with a 2-second delay on failure.
	]]
	--

	local HashMap = GetHashMap()

	PrivateServerData.State = "Closed"
	print(`[PrivateServer]: Closing Private Server (`, PrivateServerData, ")")

	return Promise.retryWithDelay(function()
		return Promise.try(function()
			return HashMap:UpdateAsync(PrivateServerData.PrivateServerId, function(oldValue)
				if oldValue then
					for i, v in pairs(PrivateServerData) do
						oldValue[i] = v
					end

					return oldValue
				else
					return PrivateServerData
				end
			end, MATCH_RETENTION_TIME)
		end)
	end, 5, 2)
end

return PrivateServer
