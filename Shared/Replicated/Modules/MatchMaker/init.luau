--!strict
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local future = require(ReplicatedStorage.Packages.future)
local private_server = require(script["private-server"])
local trove = require(ReplicatedStorage.Packages.trove)

-- matchmaker.luau

local module = {}

type MatchmakingMode = "Solo" | "Duo"

export type Party = {
	id: string,
	mode: string,
	region_code: string,
	member_ids: { number },
	data: { [string]: any },
	queue_time_start: number,
}

type MatchmakingParams = {
	name: string,
	matchmaking: ({ Party }) -> { { place_id: number, parties: { Party } } },
}

type MatchMaker = typeof(setmetatable({
	active = true,
	_trove = trove.new(),
	party_added = SignalPlus(),
	party_removed = SignalPlus(),
	regional_queues = {},
}, module))

local active_matchmakers = {} :: { [string]: MatchMaker }

function module.new(params: MatchmakingParams)
	if active_matchmakers[params.name] then
		warn("Matchmaker with name " .. params.name .. " already exists.")

		return active_matchmakers[params.name]
	end

	local self = setmetatable({ params }, module)
	self.active = true
	self._trove = trove.new()

	self.party_added = self._trove:Add(SignalPlus())
	self.party_removed = self._trove:Add(SignalPlus())

	self.regional_queues = {}
	active_matchmakers[params.name] = self

	return self
end

function module:GetMatchmaker(name: string)
	return active_matchmakers[name]
end

function module:GetRegionalQueue(region_code)
	local existing_queue = self.regional_queues[region_code]
	if existing_queue then
		return existing_queue
	end

	local new_queue = self.regional_queue.new({
		region_code = region_code,
		mode = self,
	})

	self.regional_queues[region_code] = new_queue

	return new_queue
end

function module:AddPartyAsync(member_ids: { number }, data, region_code)
	if not region_code then
		local player, country_code = nil, nil
		for _, member_id in ipairs(member_ids) do
			player = Players:GetPlayerByUserId(member_id)

			if not player then
				continue
			end

			break
		end
		if player then
			local fut =
				future.new(LocalizationService.GetCountryRegionForPlayerAsync, LocalizationService, player)

			country_code = fut:Await() or "DEFAULT"
		end
	end

	local queue = self:GetRegionalQueue(region_code or "DEFAULT")

	return queue:AddPartyAsync(member_ids, data)
end

function module:RemovePartyAsync(party_id, forced)
	local party = self:GetParty(party_id)

	if not party then
		warn("No party found with ID: " .. tostring(party_id))
		return
	end

	local regional_queue = party:GetRegionalQueue(party.region_code)

	return regional_queue:RemovePartyAsync(party_id, forced)
end

function module:GetParty(party_id)
	for i, regional_queue in pairs(self.regional_queues) do
		for id, cache_table in pairs(regional_queue.cache) do
			if id == party_id then
				return cache_table.party
			end
		end
	end
end

function module:GetPartyMatchAsync(party_id, mode: string, region_code)
	local fut = future.Try(function(...)
		return self.regional_queue:GetSortedMap(mode, region_code):GetAsync(party_id)
	end)

	fut:Await()

	fut:After(function(ok, result)
		if not result or (result and not result.match_id) then
			return
		end

		return private_server:GetPrivateServerDataAsnyc(result.match_id)
	end)

	return fut
end

function module:Destroy()
	if not self.active then
		return
	end

	for name, matchmaker in pairs(active_matchmakers) do
		if matchmaker == self then
			active_matchmakers[name] = nil
			break
		end
	end

	for i, regional_queue in pairs(self.regional_queues) do
		regional_queue:Destroy()
	end

	self._trove:Destroy()
	self.active = false
end

game:BindToClose(function()
	for i, matchmaker in pairs(active_matchmakers) do
		task.spawn(function()
			matchmaker:Destroy()
		end)
	end
end)

return module
