--!nonstrict

local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local observer = require(ReplicatedStorage.Utility.observer)
local promise = require(ReplicatedStorage.Packages.promise)
local timer = require(ReplicatedStorage.Modules.timer)
local trove = require(ReplicatedStorage.Packages.trove)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- regionalqueue.luau

local regionalqueue = {
	lock_map_key = "regional_queue",
	QUEUE_TIMEOUT = 60 * 20, -- seconds
	PARTY_TIMEOUT = 60 * 60 * 24, -- seconds
	PARTY_REFRESH = 5, -- seconds

	BIG_QUEUE_TIME = 9999999999,

	COORDINATOR_REFRESH = 5, -- seconds
	COORDINATOR_TIMEOUT = 30, -- seconds

	MATCHMAKING_TOTALCOUNT = 200, -- seconds
	MATCHMAKING_SUBCOUNT = 50, -- seconds
}
regionalqueue.__index = regionalqueue

local lock_map = MemoryStoreService:GetHashMap(`region_locks_{regionalqueue.lock_map_key}`)

export type region_queue = {
	region_code: string,
	mode: unknown,
}

type mode = {
	Name: string,
	PartyAdded: SignalPlus.Signal<party>,
	PartyRemoved: SignalPlus.Signal<party, unknown>,
}

export type party = {
	id: string,
	mode: mode,
	region_code: string,
	member_ids: { number },
	data: {},
	unixtimestamp_millis: number,
}

export type cache = {
	_trove: typeof(trove.new()),
	unixtimestamp_millis: number,
	party: party,
}

type self = {
	region_code: string,
	main_server: observer.Observer<boolean>,
	mode: mode,
	active: observer.Observer<boolean>,
	id: string,
	sorted_map: MemoryStoreSortedMap,
	cache: {},
	_trove: typeof(trove.new()),
}

function regionalqueue.new(params: region_queue)
	local self = setmetatable(params, regionalqueue)

	self.region_code = params.region_code
	self.main_server = observer.new(false)
	self.active = observer.new(true)
	self.id = `{params.mode.Name}-{self.region_code}`
	self.sorted_map = self:GetSortedMap(self.mode.Name, self.region_code)
	self.cache = {}
	self._trove = trove.new()

	self.mode.regional_queues[self.region_code] = self

	print("New regional queue created")

	return self
end

function regionalqueue:GetSortedMap(self: self, mode: string, region_code: string)
	local str = `{mode}-{region_code}{regionalqueue.lock_map_key}`

	return MemoryStoreService:GetSortedMap(str)
end

function regionqueue:TeleportPartyAsync(self: self, party: party, id)
	--
end

function regionqueue:CheckIfPartyFoundMatch(self: self, party: party, leave_queue)
	local match_id = nil

	return promise
		.try(function()
			return self.sorted_map:UpdateAsync(party.id, function(old, sort_key)
				if not old then
					-- means the queue timed out
					return nil
				end

				if leave_queue then
					old.PartyLeft = true
					sort_key = regionalqueue.BIG_QUEUE_TIME
				end

				if old.match_id then
					-- ayo we found a tinder match!!1!
					match_id = old.match_id
				end

				return old, sort_key
			end, regionalqueue.PARTY_TIMEOUT)
		end)
		:catch(function(err)
			return promise.reject(tostring(err))
		end)
		:andThen(function()
			return match_id
		end)
end

function regionqueue:AddPartyAsync(self: self, member_ids: { number }, party_data)
	local join_time = DateTime.now().UnixTimestampMillis

	local party = {
		id = url.generateShortUniqueId(),
		mode = self.mode,
		region_code = self.region_code,
		member_ids = member_ids,
		data = party_data or {},
		unixtimestamp_millis = join_time,
	}

	local cache = {
		_trove = trove.new(),
		unixtimestamp_millis = join_time,
		party = party,
	}

	self.cache[party.id] = cache

	print("adding new party")

	cache.added_to_sorted_map = true

	return promise
		.try(function()
			return self.sorted_map:SetAsync(party.id, party, regionalqueue.PARTY_TIMEOUT, join_time)
		end)
		:catch(function(err)
			cache.added_to_sorted_map = false

			self:RemovePartyAsync(party.id, true)

			return promise.reject(tostring(err))
		end)
		:andThen(function()
			local clock = timer.new()
			clock:Start()

			local main_server_refresh = observer.None

			clock:interval(regionalqueue.PARTY_REFRESH, function()
				local elasped = DateTime.now().UnixTimestamp - join_time

				if elasped > regionalqueue.QUEUE_TIMEOUT then
					self:RemovePartyAsync(party.id)
				else
					self:CheckIfPartyFoundMatch(party):andThen(function(id)
						if id then
							return self:TeleportPartyAsync(party, id)
						end
					end)
				end
			end)

			if not main_server_refresh:Get() then
				task.spawn(function()
					self:MatchMake()
				end)
				main_server_refresh:Set(function()
					clock:interval(regionalqueue.COORDINATOR_REFRESH, function()
						self:MatchMake()
					end)
				end)

				self.mode.PartyAdded:Fire(party)
			end

			return party
		end)
end

function regionalqueue:RemovePartyTable(self: self, id: string, match)
	local cache = self.cache[id] :: cache?

	if not cache then
		self:RemoteEmptyQueue()
		return
	end

	cache._trove:Destroy()

	self.cache[id] = nil

	self.mode.PartyRemoved:Fire(cache.party, match)

	self:RemoveEmptyQueue()
end

function regionalqueue:RemovePartyAsync(id: string, forced: boolean) end
