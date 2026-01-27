--!strict
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rbx_deeplink = require(ReplicatedStorage.Utility["rbx-deeplink"])
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- party.luau

local module = {}

local queued_parties = {} :: { Party }
local loaded_party

-- notes
-- it can be only you in the party
-- or, you can invite a friend.
-- there can also be modifiers

export type Party = {
	party_id: string,
	leader_id: number,
	members: { number },
	settings: Settings,
	state: "idle" | "searching" | "in_match",
}

type Settings = {
	mode: "Solo" | "Duo" | "Squad",
	modifiers: { string },
	allow_spectators: boolean,
	friends_only: boolean,
}

type self = setmetatable<Party, typeof(module)>

-- TODO) reduce network traffic after testing

-- variables

local events = ReplicatedStorage.Events

function module.new(leader_id: number): self
	local self = setmetatable({}, module)

	for i, party in ipairs(queued_parties) do
		if party.leader_id == leader_id then
			-- the metatable should be garbagecollected

			return
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

	events.UpdatePartyList:FireAllClients(module:GetParties())

	return self
end

function module:GetParties(): { Party }
	return queued_parties
end

function module:GetPartyById(party_id: string): Party?
	for _, party in ipairs(queued_parties) do
		if party.party_id == party_id then
			return party
		end
	end

	return nil
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

	events.UpdatePartyList:FireAllClients(module:GetParties())

	return true
end

function module:RemoveMember(self: self, player_id: number): boolean
	for i, member in ipairs(self.members) do
		if member == player_id then
			table.remove(self.members, i)

			events.UpdatePartyList:FireAllClients(module:GetParties())

			return true
		end
	end

	return false -- member not found
end

function module:SetSettings(self: self, settings: Settings)
	local new_table = {}

	tablekit.Reconcile(self.settings, settings)

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

function module:Destroy(self: self)
	for i, party in ipairs(queued_parties) do
		if party.party_id == self.party_id then
			table.remove(queued_parties, i)

			events.UpdatePartyList:FireAllClients(module:GetParties())

			break
		end
	end

	table.clear(self)
	setmetatable(self, nil)
end

return module
