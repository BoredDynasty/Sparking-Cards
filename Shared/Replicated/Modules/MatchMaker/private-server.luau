--!strict

local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local future = require(ReplicatedStorage.Packages.future)
local retryer = require(ReplicatedStorage.Utility.retryer)

-- private-server.luau

local MATCH_RETENTION_TIME = 60 * 60 * 24 -- 24 hours in seconds

local module = {}

export type ServerData = {
	private_server_id: string,
	access_code: string,
	place_id: number,
	parties: {},
	state: string,
}

local function fetchHashMap()
	return MemoryStoreService:GetHashMap("PrivateServers")
end

function module:ReserveServer(place_id)
	if RunService:IsStudio() then
		return "AccessCode", "PrivateServerId"
	else
		return TeleportService:ReserveServer(place_id)
	end
end

function module:GetPrivateServerDataAsnyc(private_server_id: string)
	local hash_map = fetchHashMap()

	print("Fetching private server data: ", private_server_id)

	return future.Try(function()
		return hash_map:GetAsync(private_server_id)
	end)
end

function module:RegisterAsync(private_server_data: ServerData)
	local hash_map = fetchHashMap()

	print("registering private server: ", private_server_data)

	return retryer.delay(2, 5, function(...)
		return future.Try(function(...)
			return hash_map:SetAsync(
				private_server_data.private_server_id,
				private_server_data,
				MATCH_RETENTION_TIME
			)
		end)
	end)
end

function module:UpdateAsync(private_server_data: ServerData)
	local hash_map = fetchHashMap()

	return future.Try(function(...)
		return hash_map:UpdateAsync(private_server_data.private_server_id, function(old_value)
			if old_value then
				for i, value in pairs(private_server_data :: { [string]: any }) do
					old_value[i] = value
				end

				return old_value
			else
				return private_server_data
			end
		end, MATCH_RETENTION_TIME)
	end)
end

function module:CloseAsync(private_server_data: ServerData)
	local hash_map = fetchHashMap()

	private_server_data.state = "Closed"

	return retryer.delay(2, 5, function(...)
		return future.Try(function(...)
			return hash_map:UpdateAsync(private_server_data.private_server_id, function(old_value)
				if old_value then
					for i, value in pairs(private_server_data :: { [string]: any }) do
						old_value[i] = value
					end

					return old_value
				else
					return private_server_data
				end
			end, MATCH_RETENTION_TIME)
		end)
	end)
end

return module
