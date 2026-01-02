--!strict

local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local future = require(ReplicatedStorage.Packages.future)
local private_server = require(script.Parent["private-server"])
local retryer = require(ReplicatedStorage.Utility.retryer)
local trove = require(ReplicatedStorage.Packages.trove)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- regional-queue.luau

--// Types
export type Params = {
	mode: {
		name: string,
		regional_queues: { [string]: RegionalQueue },
	},
	region_code: string,
}

export type Party = {
	id: string,
	mode: string,
	region_code: string,
	member_ids: { number },
	data: { [string]: any },
	queue_time_start: number,
}

export type CacheTable = {
	connections: typeof(trove.new()),
	join_time: number,
	party: Party,
	added_to_sorted_map: boolean?,
	refresh_thread: thread?,
}

export type RegionalQueue = {
	region_code: string,
	main_server: boolean,
	active: boolean,
	id: string,
	sorted_map: MemoryStoreSortedMap,
	cache: CacheTable?,
	_trove: typeof(trove.new()),
	mode: {
		name: string,
		regional_queues: { [string]: RegionalQueue },
	},

	GetSortedMap: (self: RegionalQueue, mode: string, region_code: string) -> MemoryStoreSortedMap,
	TeleportPartyAsync: (self: RegionalQueue, party: Party, match_id: string) -> (),
	CheckIfPartyFoundMatch: (
		self: RegionalQueue,
		party: Party,
		leave_queue: boolean
	) -> typeof(future.Try(function()
		return 0 :: any
	end)),
	AddPartyAsync: (self: RegionalQueue, party_member_ids: { number }, party_data: { [string]: any }?) -> (),
	RemovePartyAsync: (self: RegionalQueue, party_id: string, force: boolean?) -> (),
	RemovePartyTable: (self: RegionalQueue, party_id: string, match: any) -> (),
}

local module = {}
module.__index = module

local region_lock_map = MemoryStoreService:GetHashMap("RegionLocks")

local QUEUE_TIMEOUT = 60 * 20 -- seconds
local PARTY_TIMEOUT = 60 * 60 * 24 -- seconds
local PARTY_REFRESH = 5 -- seconds

local BIG_QUEUE_TIME = 9999999999

local COORDINATOR_REFRESH = 5 -- seconds
local COORDINATOR_TIMEOUT = 30 -- seconds

local MATCHMAKING_TOTALCOUNT = 200 -- seconds
local MATCHMAKING_SUBCOUNT = 50 -- seconds

function module.new(params: Params): RegionalQueue
	local self = setmetatable({
		region_code = params.region_code,
		main_server = true,
		active = true,
		id = params.mode.name .. "-" .. params.region_code,
		sorted_map = module:GetSortedMap(params.mode.name, params.region_code),
		cache = nil,
		_trove = trove.new(),
		mode = params.mode,
	}, module) :: RegionalQueue

	self.mode.regional_queues[self.region_code] = self

	return self
end

function module:GetSortedMap(mode: string, region_code: string): MemoryStoreSortedMap
	return MemoryStoreService:GetSortedMap(mode .. "-" .. region_code)
end

function module:TeleportPartyAsync(self: RegionalQueue, party: Party, match_id: string)
	local fut = private_server:GetPrivateServerDataAsnyc(match_id)

	fut:After(function(ok: boolean, match: any)
		if not ok then
			warn(tostring(match)) -- match == result

			return
		end

		self:RemovePartyTable(party.id, match)
	end)
end

function module:CheckIfPartyFoundMatch(
	self: RegionalQueue,
	party: Party,
	leave_queue: boolean
): future.Future<any>
	local match_id: number? = nil

	local fut = future.Try(function(...)
		return self.sorted_map:UpdateAsync(party.id, function(old_value: any, sort_key: any)
			if not old_value then
				-- awhh the queue timed out!!
				return nil, nil
			end

			if leave_queue then
				old_value.party_left = true
				sort_key = BIG_QUEUE_TIME
			end

			if old_value.match_id then
				-- yoshaa! (japanese for "alright!")
				-- we have found a match!
				match_id = old_value.match_id
			end

			return old_value, sort_key :: any
		end, PARTY_TIMEOUT)
	end)

	fut:After(function(ok: boolean, ...: any)
		if not ok then
			warn(tostring(...))
		else
			return match_id
		end
	end)

	return fut
end

function module:AddPartyAsync(
	self: RegionalQueue,
	party_member_ids: { number },
	party_data: { [string]: any }?
)
	local join_time = os.time()

	local party: Party = {
		id = url.generateShortUniqueId(),
		mode = self.mode.name,
		region_code = self.region_code,
		member_ids = party_member_ids,
		data = party_data or {},
		queue_time_start = join_time,
	}

	local cache_table: CacheTable = {
		connections = trove.new(),
		join_time = join_time,
		party = party, -- we fr be nesting tables like that
	}

	self.cache = cache_table

	cache_table.added_to_sorted_map = true

	local fut = future.Try(function(...)
		return self.sorted_map:SetAsync(party.id, party, PARTY_TIMEOUT, join_time)
	end)

	fut:After(function(ok: boolean, ...)
		if not ok then
			cache_table.added_to_sorted_map = false

			self:RemovePartyAsync(party.id, true)

			warn(tostring(...))

			return
		end

		cache_table.connections.refresh_thread = task.spawn(function()
			retryer.infdelay(PARTY_REFRESH, function()
				local time_elasped = os.time() - join_time

				if time_elasped > QUEUE_TIMEOUT then
					self:RemovePartyAsync(party.id)
				else
					self:CheckIfPartyFoundMatch(party, false)
				end
			end)
		end)
	end)
end

return module
