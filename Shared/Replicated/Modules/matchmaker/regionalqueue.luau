--!strict
--[=[
	@class RegionalQueue
	@server
	Manages a single regional matchmaking queue, including party management,
	match creation, and coordinator server election.
]=]

-- Services
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")

-- Packages
local Packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
local Promise = require(Packages:WaitForChild("Promise"))
local Trove = require(Packages:WaitForChild("Trove"))
local Signal = require(Packages._Index["sleitnick_signal@2.0.3"].signal)

-- Modules
local PrivateServer = require(script.Parent:WaitForChild("private"))

-- Types
type Promise<T> = any
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
	MatchId: string?,
	PartyLeft: boolean?,
}
type Match = {
	Parties: { Party },
	PlaceId: number,
	AccessCode: string?,
	PrivateServerId: string,
	CreatedTime: number,
	Mode: string,
	RegionCode: string,
	ServerState: string,
}
type MatchMaker = {
	Name: string,
	PartyAdded: Signal,
	PartyRemoved: Signal,
	RegionalQueues: { [string]: any },
	MatchMaking: (parties: { Party }) -> { { any } },
}
type CacheTable = {
	Trove: Trove,
	JoinTime: number,
	Party: Party,
	AddedToSortedMap: boolean,
	InQueue: boolean,
}
type RegionalQueue = {
	RegionCode: string,
	Mode: MatchMaker,
	MainServer: boolean,
	Active: boolean,
	ID: string,
	SortedMap: any,
	Cache: { [string]: CacheTable },
	Trove: Trove,
}

-- Constants
local RELEASE = "v0.2"
local REGION_LOCK_MAP_NAME = "RegionLocks" .. RELEASE

local QUEUE_TIMEOUT = 60 * 20
local PARTY_TIMEOUT = 60 * 60 * 24
local PARTY_REFRESH = 5

local BIG_QUEUE_TIME = 9999999999

local COORDINATOR_REFRESH = 5
local COORDINATOR_TIMEOUT = 30

local MATCHMAKING_TOTAL_COUNT = 200
local MATCHMAKING_SUB_COUNT = 50

-- Module
local RegionalQueue = {}
RegionalQueue.__index = RegionalQueue

-- Private Methods
local function GetSortedMap(Mode: string, RegionCode: string)
	return MemoryStoreService:GetSortedMap(Mode .. "-" .. RegionCode .. RELEASE)
end

local function Print(self: RegionalQueue, text: string)
	print(`[MatchMakerService-{self.ID}] {text}`)
end

local function Warn(self: RegionalQueue, text: string)
	warn(`[MatchMakerService-{self.ID}] {text}`)
end

-- Public Methods

function RegionalQueue.new(Params: { RegionCode: string, Mode: MatchMaker }): RegionalQueue
	local self = setmetatable({} :: any, RegionalQueue)

	self.RegionCode = Params.RegionCode
	self.Mode = Params.Mode
	self.MainServer = false
	self.Active = true
	self.ID = self.Mode.Name .. "-" .. self.RegionCode
	self.SortedMap = GetSortedMap(self.Mode.Name, self.RegionCode)
	self.Cache = {}
	self.Trove = Trove.new()

	self.Mode.RegionalQueues[self.RegionCode] = self
	Print(self, "New regional queue has been created")

	return self
end

function RegionalQueue:TeleportPartyAsync(Party: Party, MatchId: string): Promise<void>
	return PrivateServer:GetPrivateServerDataAsync(MatchId)
		:catch(function(err)
			return Promise.reject(tostring(err))
		end)
		:andThen(function(Match)
			self:_RemovePartyTable(Party.Id, Match)
		end)
end

function RegionalQueue:CheckIfPartyFoundMatch(Party: Party, LeaveQueue: boolean?): Promise<string?>
	local MatchId: string?

	return Promise.try(function()
		return self.SortedMap:UpdateAsync(Party.Id, function(oldValue, sortKey)
			if not oldValue then
				return nil
			end

			if LeaveQueue then
				oldValue.PartyLeft = true
				sortKey = BIG_QUEUE_TIME
			end

			if oldValue.MatchId then
				MatchId = oldValue.MatchId
			end

			return oldValue, sortKey
		end, PARTY_TIMEOUT)
	end)
		:catch(function(err)
			return Promise.reject(tostring(err))
		end)
		:andThen(function()
			return MatchId
		end)
end

function RegionalQueue:AddPartyAsync(
	PartyMemberIds: { number },
	PartyData: { [string]: any }
): Promise<Party>
	local JoinTime = os.time()
	local Party: Party = {
		Id = HttpService:GenerateGUID(false),
		Mode = self.Mode.Name,
		RegionCode = self.RegionCode,
		MemberIds = PartyMemberIds,
		Data = PartyData,
		QueueTimeStart = JoinTime,
	}

	local CacheTable: CacheTable = {
		Trove = Trove.new(),
		JoinTime = JoinTime,
		Party = Party,
		AddedToSortedMap = false,
		InQueue = false,
	}

	self.Cache[Party.Id] = CacheTable

	Print(self, "Adding a party to the queue")

	CacheTable.AddedToSortedMap = true
	return Promise.try(function()
		return self.SortedMap:SetAsync(Party.Id, Party, PARTY_TIMEOUT, JoinTime)
	end)
		:catch(function(err)
			CacheTable.AddedToSortedMap = false
			self:RemovePartyAsync(Party.Id, true)
			return Promise.reject(tostring(err))
		end)
		:andThen(function()
			local trove = CacheTable.Trove
			trove:Add(task.delay(PARTY_REFRESH, function()
				local TimeEllapsed = os.time() - JoinTime

				if TimeEllapsed > QUEUE_TIMEOUT then
					self:RemovePartyAsync(Party.Id)
				else
					self:CheckIfPartyFoundMatch(Party):andThen(function(MatchId)
						if MatchId then
							self:TeleportPartyAsync(Party, MatchId)
						end
					end)
				end
			end))

			if not self.Trove:FindFirstChild("MainServerRefresh") then
				task.spawn(function()
					self:DoMatchmaking()
				end)
				local refreshThread = task.delay(COORDINATOR_REFRESH, function()
					self:DoMatchmaking()
				end)
				self.Trove:Add(refreshThread, "MainServerRefresh")
			end

			self.Mode.PartyAdded:Fire(Party)
			CacheTable.InQueue = true

			return Party
		end)
end

function RegionalQueue:RemovePartyAsync(PartyId: string, Forced: boolean?): Promise<void>
	Print(self, "Removing a party from the queue")

	return Promise.try(function()
		local CacheTable = self.Cache[PartyId]
		assert(CacheTable, `PartyId {PartyId} is not in queue in this server`)

		local Party = CacheTable.Party
		assert(CacheTable.InQueue or Forced, "Player is still being added to the queue, please try again")

		if Forced then
			self:_RemovePartyTable(Party.Id)
		end

		if CacheTable.AddedToSortedMap then
			return self:CheckIfPartyFoundMatch(Party, true)
		end
	end)
		:andThen(function(MatchId)
			if MatchId then
				local Party = self.Cache[PartyId].Party
				self:TeleportPartyAsync(Party, MatchId)
				return Promise.reject("Player has already found a match, cannot cancel now")
			end
			self:_RemovePartyTable(PartyId)
		end)
		:finally(function(Status)
			Print(self, "Removing a party from the queue:" .. Status)
		end)
end

function RegionalQueue:TryLockServer(): Promise<any>
	local lockKey = self.ID
	local myServerId = game.JobId
	local Active = self.Active

	return Promise.try(function()
		local RegionLockMap = MemoryStoreService:GetHashMap(REGION_LOCK_MAP_NAME)
		return RegionLockMap:UpdateAsync(lockKey, function(oldValue)
			if not oldValue and Active then
				return { serverId = myServerId, timestamp = os.time(), Active = Active }
			elseif oldValue and oldValue.serverId == myServerId then
				return { serverId = myServerId, timestamp = os.time(), Active = Active }
			elseif oldValue and not oldValue.Active and Active then
				return { serverId = myServerId, timestamp = os.time(), Active = Active }
			else
				return oldValue
			end
		end, COORDINATOR_TIMEOUT)
	end)
end

function RegionalQueue:IsServerMainServer(): Promise<void>
	local myServerId = game.JobId

	return self:TryLockServer()
		:andThen(function(acquired)
			assert(acquired and acquired.serverId == myServerId and acquired.Active, "This server is not the main server")

			if not self.MainServer then
				Print(self, "This server became the main server")
			end
			self.MainServer = true
		end)
		:catch(function(err)
			if self.MainServer then
				Print(self, "This server stopped being the main server")
			end
			self.MainServer = false
			return Promise.reject(tostring(err))
		end)
end

function RegionalQueue:CreateMatchAsync(Match: Match): Promise<void>
	local PartiesRemoved = {}

	Match.CreatedTime = os.time()
	Match.Mode = self.Mode.Name
	Match.RegionCode = self.RegionCode
	if not Match.AccessCode then
		local AccessCode, PrivateServerId = PrivateServer:ReserveServer(Match.PlaceId)
		Match.AccessCode = AccessCode
		Match.PrivateServerId = PrivateServerId
	end
	Match.ServerState = "Created"

	local partyPromises = {}
	for _, Party in ipairs(Match.Parties) do
		table.insert(partyPromises, self:_UpdatePartyForMatch(Party, Match.PrivateServerId, PartiesRemoved))
	end

	return Promise.all(partyPromises)
		:andThen(function()
			return PrivateServer:RegisterAsync(Match)
		end)
		:catch(function(err)
			local rollbackPromises = {}
			for _, Party in ipairs(PartiesRemoved) do
				table.insert(rollbackPromises, self:_RollbackPartyMatch(Party, Match.PrivateServerId))
			end
			return Promise.all(rollbackPromises):andThen(function()
				return Promise.reject(tostring(err))
			end)
		end)
end

function RegionalQueue:CreateMatches(Matches: { Match }): Promise<void>
	local matchPromises = {}
	for _, Match in ipairs(Matches) do
		table.insert(matchPromises, self:CreateMatchAsync(Match))
	end

	return Promise.allSettled(matchPromises):andThen(function(results)
		local successCount = 0
		local failureCount = 0
		for _, result in ipairs(results) do
			if result.status == "resolved" then
				successCount += 1
			else
				failureCount += 1
			end
		end
		Print(self, `Created successfully {successCount}/{successCount + failureCount} matches`)
	end)
end

function RegionalQueue:DoMatchmaking(): Promise<void>
	local Parties = {}

	return self:IsServerMainServer()
		:andThen(function()
			return self:_FetchParties()
		end)
		:andThen(function(FetchedParties)
			Parties = FetchedParties
			Print(self, `Retrieved {#Parties} parties`)
			return self.Mode.MatchMaking(Parties)
		end)
		:andThen(function(Matches)
			if not Matches or #Matches == 0 then
				Print(self, `No match to create`)
				return
			end
			Print(self, `Creating {#Matches} matches`)
			return self:CreateMatches(Matches)
		end)
		:catch(function(err)
			Warn(self, tostring(err))
		end)
end

function RegionalQueue:Destroy()
	if not self.Active then
		return
	end
	self.Active = false

	self.Trove:Destroy()

	if self.MainServer then
		self:TryLockServer()
	end

	Print(self, "Regional queue has been destroyed")
	self.Mode.RegionalQueues[self.RegionCode] = nil
end

-- Internal Methods

function RegionalQueue:_RemovePartyTable(PartyId: string, Match: any?)
	local CacheTable = self.Cache[PartyId]
	if not CacheTable then
		self:_RemoveEmptyQueue()
		return
	end

	CacheTable.Trove:Destroy()
	self.Cache[PartyId] = nil
	self.Mode.PartyRemoved:Fire(CacheTable.Party, Match)
	self:_RemoveEmptyQueue()
end

function RegionalQueue:_RemoveEmptyQueue()
	if not next(self.Cache) then
		self:Destroy()
	end
end

function RegionalQueue:_FetchParties(): Promise<{ Party }>
	return Promise.try(function()
		local totalFetched = 0
		local Parties = {}
		local exclusiveLowerBound
		local exclusiveUpperBound = os.time() + COORDINATOR_REFRESH

		while totalFetched < MATCHMAKING_TOTAL_COUNT do
			local success, items = pcall(function()
				return self.SortedMap:GetRangeAsync(
					Enum.SortDirection.Ascending,
					MATCHMAKING_SUB_COUNT,
					exclusiveLowerBound,
					exclusiveUpperBound
				)
			end)

			if not success then
				return Promise.reject(items)
			end

			for _, item in ipairs(items) do
				totalFetched += 1
				local Party = item.value
				if not Party.MatchId and not Party.PartyLeft then
					table.insert(Parties, Party)
				end

				if totalFetched >= MATCHMAKING_TOTAL_COUNT then
					break
				end
			end

			if #items < MATCHMAKING_SUB_COUNT or totalFetched >= MATCHMAKING_TOTAL_COUNT then
				break
			end

			exclusiveLowerBound = {
				key = items[#items].key,
				sortKey = items[#items].sortKey,
			}
		end
		return Parties
	end)
end

function RegionalQueue:_UpdatePartyForMatch(Party: Party, MatchId: string, PartiesRemoved: { Party }): Promise<void>
	return Promise.try(function()
		local success = self.SortedMap:UpdateAsync(Party.Id, function(oldValue, sortKey)
			if not oldValue or oldValue.PartyLeft or (oldValue.MatchId and oldValue.MatchId ~= MatchId) then
				return nil
			end

			oldValue.MatchId = MatchId
			sortKey = BIG_QUEUE_TIME
			table.insert(PartiesRemoved, oldValue)
			return oldValue, sortKey
		end, PARTY_TIMEOUT)

		if not success then
			return Promise.reject("Party was unable to receive the match data")
		end
	end)
end

function RegionalQueue:_RollbackPartyMatch(Party: Party, MatchId: string): Promise<void>
	return Promise.try(function()
		self.SortedMap:UpdateAsync(Party.Id, function(oldValue, sortKey)
			if not oldValue then
				return nil
			end

			if oldValue.MatchId and oldValue.MatchId == MatchId then
				oldValue.MatchId = nil
			end

			if oldValue.PartyLeft then
				sortKey = BIG_QUEUE_TIME
			else
				sortKey = oldValue.QueueTimeStart
			end
			return oldValue, sortKey
		end, PARTY_TIMEOUT)
	end)
end

return RegionalQueue
