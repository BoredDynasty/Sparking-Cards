--!strict
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rbx_deeplink = require(ReplicatedStorage.Utility["rbx-deeplink"])
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- party.luau

local module = {}

local queued_parties = {} :: { typemarshaller.Party }

local party_by_leader = {} :: { [number]: typemarshaller.Party }
local party_by_member = {} :: { [number]: typemarshaller.Party }

-- notes
-- it can be only you in the party
-- or, you can invite a friend.
-- there can also be modifiers
-- i also did not make most of the party system,
-- that is why most of it seems "naked"

type Settings = {
	mode: "Solo" | "Duo" | "Squad",
	modifiers: { string },
	allow_spectators: boolean,
	friends_only: boolean,
}

type self = setmetatable<typemarshaller.Party, typeof(module)>

-- TODO) reduce network traffic after testing

-- variables

local events = ReplicatedStorage.Events

function module.new(leader_id: number)
	local self = setmetatable({}, module)

	for i, party in ipairs(queued_parties) do
		-- this shouldn't even happen anyway lmao

		if party.leader_id == leader_id then
			-- the metatable should be garbagecollected

			return nil
		end
	end

	self.party_id = `{DateTime.now().UnixTimestampMillis}{leader_id}`
	self.leader_id = leader_id
	self.members = table.create(4, leader_id)
	self.settings = {
		mode = "Solo",
		modifiers = {} :: { string },
		allow_spectators = true,
		friends_only = false,
	}
	self.state = "idle"

	table.insert(queued_parties, self)

	party_by_leader[leader_id] = self

	for _, memberId in ipairs(self.members) do
		party_by_member[memberId] = self
	end

	events.UpdatePartyList:FireAllClients(module:GetParties())

	return self
end

function module:GetParties(): { typemarshaller.Party }
	return queued_parties
end

function module:GetPartyForPlayer(player_id: number): typemarshaller.Party?
	-- fast lookup into parties by member id
	local party = party_by_member[player_id]
	if party then
		return party
	end

	-- fallback scan
	for _, p in ipairs(queued_parties) do
		for _, member in ipairs(p.members) do
			if member == player_id then
				return p
			end
		end
	end

	return nil
end

function module:SetPartyState(self: self, state: "idle" | "searching" | "in_match")
	self.state = state

	events.UpdatePartyList:FireAllClients(module:GetParties())
end

function module:StartSearching(self: self)
	if self.state == "searching" or self.state == "in_match" then
		return false
	end

	self.state = "searching"

	events.UpdatePartyList:FireAllClients(module:GetParties())

	return true
end

function module:StopSearching(self: self)
	if self.state ~= "searching" then
		return false
	end

	self.state = "idle"

	events.UpdatePartyList:FireAllClients(module:GetParties())

	return true
end

function module:GetPartyById(party_id: string): typemarshaller.Party?
	for _, party in ipairs(queued_parties) do
		if party.party_id == party_id then
			return party
		end
	end

	return nil
end

-- internal helper: register & unregister member lookups
local function register_member_lookup(party: typemarshaller.Party, player_id: number)
	party_by_member[player_id] = party
end

local function unregister_member_lookup(player_id: number)
	party_by_member[player_id] = nil
end

function module:AddMember(self: self, player_id: number): boolean
	for _, member in ipairs(self.members) do
		if member == player_id then
			return false -- already in party
		end
	end

	if #self.members >= 4 then
		return false -- party full
	end

	if self.settings.mode == "Solo" then
		return false -- cannot add members in Solo mode
	end

	if self.settings.friends_only then
		-- perform a friends check here
		local leader = Players:GetPlayerByUserId(self.leader_id)

		-- Example friend check logic (this is a placeholder)
		if player_id and leader then
			if leader:IsFriendsWithAsync(player_id) then
			-- they are friends, allow joining
			else
				return false -- not friends, cannot join
			end
		else
			return false -- player id or leader not found
		end
	end

	table.insert(self.members, player_id)
	register_member_lookup(self, player_id)

	events.UpdatePartyList:FireAllClients(module:GetParties())

	return true
end

function module:RemoveMember(self: self, player_id: number): boolean
	for i, member in ipairs(self.members) do
		if member == player_id then
			table.remove(self.members, i)
			unregister_member_lookup(player_id)

			events.UpdatePartyList:FireAllClients(module:GetParties())

			return true
		end
	end

	return false -- member not found
end

function module:SetSettings(self: self, settings: Settings)
	local new_table = {}

	tablekit.Reconcile(self.settings, settings :: any)

	-- if mode changed to Solo and more than one member exists, trim members
	if self.settings.mode == "Solo" then
		while #self.members > 1 do
			table.remove(self.members)
		end
	end

	events.UpdatePartyList:FireAllClients(module:GetParties())
end

function module:GenerateSpectateCode(self: self): string
	-- generates a spectate code for the party

	-- TODO) use messagepack instead of HttpService JSON for smaller size
	local encoded = HttpService:JSONEncode({
		["party_id"] = self.party_id,
		["join_mode"] = "Spectate",
	})

	local deeplink = rbx_deeplink.format(game.PlaceId, encoded)

	return deeplink
end

function module:GenerateJoinCode(self: self): string
	-- generates a join code for the party

	-- TODO) use messagepack instead of HttpService JSON for smaller size
	local encoded = HttpService:JSONEncode({
		["party_id"] = self.party_id,
		["join_mode"] = "Join",
	})

	-- TODO) set a new place_id
	local deeplink = rbx_deeplink.format(game.PlaceId, encoded)

	return deeplink
end

function module:RemovePartyById(party_id: string): boolean
	for i, party in ipairs(queued_parties) do
		if party.party_id == party_id then
			table.remove(queued_parties, i)
			party_by_leader[party.leader_id] = nil

			for _, member in ipairs(party.members) do
				unregister_member_lookup(member)
			end

			events.UpdatePartyList:FireAllClients(module:GetParties())

			return true
		end
	end

	return false
end

function module:Destroy(self: self)
	for i, party in ipairs(queued_parties) do
		if party.party_id == self.party_id then
			table.remove(queued_parties, i)

			events.UpdatePartyList:FireAllClients(module:GetParties())

			break
		end
	end

	-- clear lookups
	party_by_leader[self.leader_id] = nil

	for _, member in ipairs(self.members) do
		unregister_member_lookup(member)
	end

	table.clear(self)
	setmetatable(self, nil)
end

return module
