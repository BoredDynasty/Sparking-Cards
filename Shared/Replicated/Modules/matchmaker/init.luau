--!strict
--[=[
	@class MatchMakerService
	@server
	The MatchMakerService is responsible for creating and managing matchmaking queues.
	It handles party management, regional queues, and private server integration.
]=]
-- Services
local LocalizationService = game:GetService("LocalizationService")
local PlayersService = game:GetService("Players")

-- Packages
local Packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
local Promise = require(Packages:WaitForChild("Promise"))
local Trove = require(Packages:WaitForChild("Trove"))
local Signal = require(Packages._Index["sleitnick_signal@2.0.3"].signal)

-- Modules
local PrivateServer = require(script.Parent:WaitForChild("private"))
local RegionalQueue = require(script:WaitForChild("regionalqueue"))
local RegionCodes = require(script:WaitForChild("regioncodes"))

-- Types
type Promise<T> = any
type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> any,
	Fire: (self: Signal<T...>, T...) -> (),
	Destroy: (self: Signal<T...>) -> (),
}
type Trove = {
	new: () -> Trove,
	Add: (self: Trove, any) -> any,
	Destroy: (self: Trove) -> (),
}
type Party = {
	Id: string,
	Mode: string,
	RegionCode: string,
	MemberIds: { number },
	Data: { [string]: any },
	QueueTimeStart: number,
}
type Match = {
	PrivateServerId: string,
}
type RegionalQueueItem = {
	Cache: { [string]: { Party: Party } },
	Destroy: (self: RegionalQueueItem) -> (),
	AddPartyAsync: (self: RegionalQueueItem, { number }, { [string]: any }) -> Promise<Party>,
	RemovePartyAsync: (self: RegionalQueueItem, string, boolean?) -> Promise<void>,
	GetSortedMap: (self: RegionalQueueItem, string, string) -> any,
}
type RegionalQueueModule = {
	new: (params: { RegionCode: string, Mode: any }) -> RegionalQueueItem,
}
type MatchMakingFunction = (Parties: { Party }) -> { Match }

export type MatchMaker = {
	Name: string,
	MatchMaking: MatchMakingFunction,
	Active: boolean,
	Trove: Trove,
	PartyAdded: Signal<Party>,
	PartyRemoved: Signal<Party, Match?>,
	RegionalQueues: { [string]: RegionalQueueItem },
	GetMatchMaker: (self: MatchMaker, Mode: string) -> MatchMaker?,
	GetRegionalQueue: (self: MatchMaker, regionCode: string) -> RegionalQueueItem,
	AddPartyAsync: (self: MatchMaker, PartyMemberIds: { number }, PartyData: { [string]: any }?, RegionCode: string?) -> Promise<Party>,
	RemovePartyAsync: (self: MatchMaker, PartyId: string, Forced: boolean?) -> Promise<void>,
	GetParty: (self: MatchMaker, PartyId: string) -> Party?,
	GetPartyMatchAsync: (self: MatchMaker, PartyId: string, Mode: string, RegionCode: string) -> Promise<any?>,
	Destroy: (self: MatchMaker) -> (),
}

-- Private Variables
local MatchMakers: { [string]: MatchMaker } = {}

-- Module
local MatchMakerService = {}
MatchMakerService.__index = MatchMakerService

-- Public Methods

function MatchMakerService.new(Params: { Name: string, MatchMaking: MatchMakingFunction }): MatchMaker
	if MatchMakers[Params.Name] then
		return MatchMakers[Params.Name]
	end

	local self = setmetatable({} :: any, MatchMakerService)
	self.Name = Params.Name
	self.MatchMaking = Params.MatchMaking
	self.Active = true
	self.Trove = Trove.new()
	self.PartyAdded = self.Trove:Add(Signal.new())
	self.PartyRemoved = self.Trove:Add(Signal.new())
	self.RegionalQueues = {}

	MatchMakers[self.Name] = self

	print(`[{self.Name}]: New matchmaker has been created`)

	return self
end

function MatchMakerService:GetMatchMaker(Mode: string): MatchMaker?
	return MatchMakers[Mode]
end

function MatchMakerService:GetRegionalQueue(regionCode: string): RegionalQueueItem
	local existingQueue = self.RegionalQueues[regionCode]
	if existingQueue then
		return existingQueue
	end

	local newQueue = (RegionalQueue :: RegionalQueueModule).new({
		RegionCode = regionCode,
		Mode = self,
	})
	self.RegionalQueues[regionCode] = newQueue

	return newQueue
end

function MatchMakerService:AddPartyAsync(
	PartyMemberIds: { number },
	PartyData: { [string]: any }?,
	RegionCode: string?
): Promise<Party>
	return Promise.try(function()
		if not RegionCode then
			local player
			for _, partyMemberId in ipairs(PartyMemberIds) do
				player = PlayersService:GetPlayerByUserId(partyMemberId)
				if player then
					break
				end
			end

			if player then
				local success, result = pcall(function()
					return LocalizationService:GetCountryRegionForPlayerAsync(player)
				end)
				if success and result then
					RegionCode = (RegionCodes :: { [string]: string })[result]
						or (RegionCodes :: { [string]: string }).DEFAULT
				end
			end
		end

		if not RegionCode then
			RegionCode = (RegionCodes :: { [string]: string }).DEFAULT
		end

		local regionalQueue = self:GetRegionalQueue(RegionCode)
		return regionalQueue:AddPartyAsync(PartyMemberIds, PartyData or {})
	end)
end

function MatchMakerService:RemovePartyAsync(PartyId: string, Forced: boolean?): Promise<void>
	return Promise.try(function()
		local party = self:GetParty(PartyId)
		if not party then
			return Promise.reject(`Party {PartyId} is not in queue`)
		end

		local regionalQueue = self:GetRegionalQueue(party.RegionCode)
		return regionalQueue:RemovePartyAsync(party.Id, Forced)
	end)
end

function MatchMakerService:GetParty(PartyId: string): Party?
	for _, regionalQueue in pairs(self.RegionalQueues) do
		for id, cacheTable in pairs(regionalQueue.Cache) do
			if id == PartyId then
				return cacheTable.Party
			end
		end
	end
	return nil
end

function MatchMakerService:GetPartyMatchAsync(PartyId: string, Mode: string, RegionCode: string): Promise<any?>
	return Promise.try(function()
		local regionalQueue = self:GetRegionalQueue(RegionCode)
		return regionalQueue:GetSortedMap(Mode, RegionCode):GetAsync(PartyId)
	end):andThen(function(result)
		if not result or not result.MatchId then
			return
		end
		return PrivateServer:GetPrivateServerDataAsync(result.MatchId)
	end)
end

function MatchMakerService:Destroy()
	if not self.Active then
		return
	end
	self.Active = false

	for _, regionalQueue in pairs(self.RegionalQueues) do
		regionalQueue:Destroy()
	end

	self.Trove:Destroy()
	MatchMakers[self.Name] = nil
end

-- Connections
game:BindToClose(function()
	for _, matchMaker in pairs(MatchMakers) do
		task.spawn(function()
			matchMaker:Destroy()
		end)
	end
end)

return MatchMakerService
