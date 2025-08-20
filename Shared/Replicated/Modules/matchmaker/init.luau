local MatchMakerService = {}
MatchMakerService.__index = MatchMakerService

-- Variables

local LocalizationService = game:GetService("LocalizationService")
local MessagingService = game:GetService("MessagingService")
local PlayerService = game:GetService("Players")

local PrivateServer = require(script.Parent:WaitForChild("PrivateServer"))

local Utils = game.ReplicatedStorage:WaitForChild("Utils")
local Maid = require(Utils:WaitForChild("Maid"))
local Promise = require(Utils:WaitForChild("Promise"))
local Signal = require(Utils:WaitForChild("Signal"))
local Thread = require(Utils:WaitForChild("Thread"))

local MatchMakers = {}

MatchMakerService.RegionalQueue = require(script:WaitForChild("RegionalQueue"))
MatchMakerService.RegionCodes = require(script:WaitForChild("RegionCodes"))

-- Methods

function MatchMakerService.new(Params)
	--[[
		Creates a new matchmaker instance or returns an existing one for the specified name.

		Parameters:
			Params.Name (string) — The name of the matchmaking mode.
			Params.MatchMaking (function) — The function used to perform the matchmaking logic.

		Returns:
			A new or cached MatchMakerService instance.
	]]
	--

	if MatchMakers[Params.Name] then
		return MatchMakers[Params.Name]
	end

	-- New Obj
	local self = setmetatable(Params, MatchMakerService)
	self.Active = true
	self.Maid = Maid.new()

	-- Events
	self.PartyAdded = self.Maid:GiveTask(Signal.new())
	self.PartyRemoved = self.Maid:GiveTask(Signal.new())

	-- Cache
	self.RegionalQueues = {}
	MatchMakers[self.Name] = self

	-- Done
	print(`[{self.Name}]: New matchmaker has been created`)

	return self
end

function MatchMakerService:GetMatchMaker(Mode)
	--[[
		Retrieves a cached matchmaker instance by name.

		Parameters:
			Mode (string) — The name of the matchmaking mode.

		Returns:
			A matchmaker instance if it exists; otherwise nil.
	]]
	--

	return MatchMakers[Mode]
end

function MatchMakerService:GetRegionalQueue(regionCode)
	--[[
		Returns or creates a new queue for the specified region.

		Parameters:
			regionCode (string) — A short code (e.g., "NA", "EU") representing the region.

		Returns:
			Promise<RegionalQueue> — A promise resolving to the regional queue object.
	]]
	--

	local existingQueue = self.RegionalQueues[regionCode]

	if existingQueue then
		return existingQueue
	end

	local newQueue = self.RegionalQueue.new({
		RegionCode = regionCode,
		Mode = self,
	})

	self.RegionalQueues[regionCode] = newQueue

	return newQueue
end

function MatchMakerService:AddPartyAsync(PartyMemberIds, PartyData, RegionCode)
	if not RegionCode then
		local Player
		local CountryCode

		for i, PartyMemberId in pairs(PartyMemberIds) do
			Player = PlayerService:GetPlayerByUserId(PartyMemberId)
			if not Player then
				continue
			end
			break
		end

		if Player then
			local Success, result = pcall(function()
				return LocalizationService:GetCountryRegionForPlayerAsync(Player)
			end)
			RegionCode = self.RegionCodes[result or "DEFAULT"]
		end
	end

	if not RegionCode then
		RegionCode = self.RegionCodes["DEFAULT"]
	end

	local RegionalQueue = self:GetRegionalQueue(RegionCode)

	return RegionalQueue:AddPartyAsync(PartyMemberIds, PartyData):await()
end

function MatchMakerService:RemovePartyAsync(PartyId, Forced)
	local Party = self:GetParty(PartyId)

	if not Party then
		return Promise.reject("Party is not in queue")
	end

	local RegionalQueue = self:GetRegionalQueue(Party.RegionCode)

	return RegionalQueue:RemovePartyAsync(Party.Id, Forced):await()
end

function MatchMakerService:GetParty(PartyId)
	--[[
		Searches through all regional queues to retrieve a party by its ID.

		Parameters:
			PartyId (string) — The unique ID of the party.

		Returns:
			Party (table) — The party object if found; otherwise nil.
	]]
	--

	for i, RegionalQueue in pairs(self.RegionalQueues) do
		for Id, CacheTable in pairs(RegionalQueue.Cache) do
			if Id == PartyId then
				return CacheTable.Party
			end
		end
	end
end

function MatchMakerService:GetPartyMatchAsync(PartyId, Mode, RegionCode)
	--[[
		Checks whether a match has been found for the party and retrieves the associated private server data.

		Parameters:
			PartyId (string) — The unique ID of the party.
			Mode (string) — The matchmaking mode.
			RegionCode (string) — The region code.

		Returns:
			Promise<PrivateServerData | nil> — Resolves with match data or nil if not found.
	]]
	--

	return Promise.try(function()
		return self.RegionalQueue:GetSortedMap(Mode, RegionCode):GetAsync(PartyId)
	end)
		:andThen(function(result)
			if not result or result and not result.MatchId then
				return Promise.resolve()
			end

			return PrivateServer:GetPrivateServerDataAsync(result.MatchId)
		end)
		:await()
end

function MatchMakerService:Destroy()
	--[[
		Cleans up and destroys the matchmaker instance, including regional queues and event connections.
	]]
	--

	if not self.Active then
		return
	end

	self.Active = false

	for i, RegionalQueue in pairs(self.RegionalQueues) do
		RegionalQueue:Destroy()
	end

	self.Maid:Destroy()
end

game:BindToClose(function()
	for i, MatchMaker in pairs(MatchMakers) do
		task.spawn(function()
			MatchMaker:Destroy()
		end)
	end
end)

return MatchMakerService
