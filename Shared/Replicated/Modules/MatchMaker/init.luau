--v1.0.0-beta

--- Roblox Services
local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")

--- Custom Modules ---
local ModuleFunctions = require("@self/MatchmakingFunctions")
local Util = require("@self/Util")

--- Module ---
local SimpleMatchmaking = {}
SimpleMatchmaking.__index = SimpleMatchmaking

function SimpleMatchmaking:GetQueue(
	name: string,
	options: {
		matchPlaceId: number,
		numberOfTeams: number,
		maxPlayersPerTeam: number,
		matchExpirationTime: number,
	}
)
	if not options then
		error("Missing options.")
	end

	local self = {}
	setmetatable(self, ModuleFunctions)

	self.Name = name
	self.Queue = MemoryStoreService:GetSortedMap(name)
	self.Options = options

	return self
end

function SimpleMatchmaking:NewOptions()
	local NewOptions = {}

	NewOptions.MatchPlaceId = 0
	NewOptions.NumberOfTeams = 1
	NewOptions.MaxPlayersPerTeam = 1
	NewOptions.MatchExpirationTime = 600
	NewOptions.UseCustomTeleporting = true

	return NewOptions
end

return SimpleMatchmaking
