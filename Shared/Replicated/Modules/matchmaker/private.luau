--!strict
--[=[
	@class PrivateServer
	@server
	Handles the reservation and data management of private servers using MemoryStoreService.
]=]

-- Services
local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

-- Packages
local Packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
local Promise = require(Packages:WaitForChild("Promise"))

-- Types
type Promise<T> = any
type PrivateServerData = {
	PrivateServerId: string,
	State: string?,
	[string]: any,
}

-- Constants
local MATCH_RETENTION_TIME = 60 * 60 * 24

-- Private Functions
local function GetHashMap()
	return MemoryStoreService:GetHashMap("PrivateServers")
end

-- Module
local PrivateServer = {}
PrivateServer.__index = PrivateServer

function PrivateServer:ReserveServer(PlaceId: number): (string, string)
	if RunService:IsStudio() then
		return "AccessCode", "PrivateServerId"
	else
		return TeleportService:ReserveServer(PlaceId)
	end
end

function PrivateServer:GetPrivateServerDataAsync(PrivateServerId: string): Promise<PrivateServerData?>
	local HashMap = GetHashMap()
	print(`[PrivateServer]: Fetching Private Server Data ({PrivateServerId})`)

	return Promise.try(function()
		return HashMap:GetAsync(PrivateServerId)
	end)
end

function PrivateServer:RegisterAsync(PrivateServerData: PrivateServerData): Promise<void>
	local HashMap = GetHashMap()
	print(`[PrivateServer]: Registering Private Server (`, PrivateServerData, ")")
	PrivateServerData.State = "Registered"

	return Promise.retryWithDelay(function()
		return Promise.try(function()
			HashMap:SetAsync(PrivateServerData.PrivateServerId, PrivateServerData, MATCH_RETENTION_TIME)
		end)
	end, 5, 2)
end

function PrivateServer:UpdateAsync(PrivateServerData: PrivateServerData): Promise<void>
	local HashMap = GetHashMap()
	print(`[PrivateServer]: Updating Private Server Data (`, PrivateServerData, ")")

	return Promise.try(function()
		return HashMap:UpdateAsync(
			PrivateServerData.PrivateServerId,
			function(oldValue)
				if not oldValue then
					return PrivateServerData
				end

				for key, value in pairs(PrivateServerData) do
					oldValue[key] = value
				end
				return oldValue
			end,
			MATCH_RETENTION_TIME
		)
	end)
end

function PrivateServer:CloseAsync(PrivateServerData: PrivateServerData): Promise<void>
	local HashMap = GetHashMap()
	print(`[PrivateServer]: Closing Private Server (`, PrivateServerData, ")")
	PrivateServerData.State = "Closed"

	return Promise.retryWithDelay(function()
		return PrivateServer:UpdateAsync(PrivateServerData)
	end, 5, 2)
end

return PrivateServer
