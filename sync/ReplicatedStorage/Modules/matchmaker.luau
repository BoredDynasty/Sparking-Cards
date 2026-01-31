--!strict
-- Minimal matchmaker: queues players and parties and forms simple matches.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local party_module = require(ReplicatedStorage.Modules.party)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

local events = ReplicatedStorage:WaitForChild("Events")

local queue_updated = events.Matchmaking.QueueUpdated

local module = {}

-- internal queues
local queued_players = {} :: { [number]: { player: Player, started: number } }
local player_queue_order = {} :: { number }
local queued_parties = {} :: { [string]: { party: any, started: number } }
local party_order = {} :: { string }

local MATCH_SIZE = 2 -- number of players per match (pair matches)
local TICK_RATE = 1 -- seconds

local next_match_id = 0

local function make_match_id(): string
	next_match_id += 1
	return `match_{DateTime.now().UnixTimestampMillis}_{next_match_id}`
end

local function get_players_from_party(party: { members: { number } })
	local out = {} :: { Player }

	for _, uid in ipairs(party.members :: { number }) do
		local other_player = Players:GetPlayerByUserId(uid)

		if other_player and other_player:FindFirstAncestorOfClass("Players") then
			table.insert(out, other_player)
		end
	end

	return out
end

local function queue_player(player: Player)
	if queued_players[player.UserId] then
		return false
	end

	queued_players[player.UserId] = { player = player, started = os.time() }

	table.insert(player_queue_order, player.UserId)

	if queue_updated then
		queue_updated:FireAllClients(module:GetQueueInfo())
	end

	return true
end

local function unqueue_player(player: Player)
	if not queued_players[player.UserId] then
		return false
	end

	queued_players[player.UserId] = nil

	for i, id in ipairs(player_queue_order) do
		if id == player.UserId then
			table.remove(player_queue_order, i)
			break
		end
	end

	if queue_updated then
		queue_updated:FireAllClients(module:GetQueueInfo())
	end

	return true
end

local function queue_party(party: typemarshaller.Party)
	if queued_parties[party.party_id] then
		return false
	end

	queued_parties[party.party_id] = { party = party, started = os.time() }

	table.insert(party_order, party.party_id)

	if queue_updated then
		queue_updated:FireAllClients(module:GetQueueInfo())
	end

	return true
end

local function unqueue_party(party_arg: typemarshaller.Party | string)
	local id: string

	if type(party_arg) == "table" then
		id = (party_arg :: { party_id: string }).party_id
	else
		id = party_arg :: string
	end

	if not queued_parties[id] then
		return false
	end

	queued_parties[id] = nil

	for i, pid in ipairs(party_order) do
		if pid == id then
			table.remove(party_order, i)
			break
		end
	end

	if queue_updated then
		queue_updated:FireAllClients(module:GetQueueInfo())
	end

	return true
end

local function form_match_with_players(players: { Player })
	local match_id = make_match_id()

	local solo_players = {} :: { Player }

	for _, p in ipairs(players) do
		local pty = party_module:GetPartyForPlayer(p.UserId)
		if pty then
			-- mark party as in_match so clients know
			(pty :: any):SetPartyState("in_match")
		else
			table.insert(solo_players, p)
		end
	end

	-- teleport solo players + players that were in parties
	local ok, result = safeteleport(game.PlaceId, players)

	-- notify players
	for _, p in ipairs(players) do
		Packet.SendNotification.sendTo({ message = "Match found! Teleporting..." }, p)
	end

	if queue_updated then
		queue_updated:FireAllClients(module:GetQueueInfo())
	end

	return match_id, ok, result
end

local function try_match()
	-- simple strategy: if we have MATCH_SIZE queued players, match them
	if #player_queue_order >= MATCH_SIZE then
		local players = {} :: { Player }

		for i = 1, MATCH_SIZE do
			local id = table.remove(player_queue_order, 1)

			if not id then
				break
			end

			local entry = queued_players[id]

			if entry and entry.player and entry.player.Parent == Players then
				table.insert(players, entry.player :: Player)
				queued_players[id] = nil
			end
		end

		if #players > 0 then
			form_match_with_players(players)
			return
		end
	end

	-- match two parties (both full/not full is allowed for now)
	if #party_order >= 2 then
		local first_id = party_order[1]
		local second_id = party_order[2]

		local a = queued_parties[first_id]
		local b = queued_parties[second_id]

		if a and b then
			local a_players = get_players_from_party(a.party)
			local b_players = get_players_from_party(b.party)

			local combined = {} :: { Player }

			for _, p in ipairs(a_players) do
				table.insert(combined, p)
			end
			for _, p in ipairs(b_players) do
				table.insert(combined, p)
			end

			-- require at least 2 players total
			if #combined >= 2 then
				-- remove from queues
				unqueue_party(a.party)
				unqueue_party(b.party)

				form_match_with_players(combined)
				return
			end
		end
	end
end

-- runner
-- lmao this should work
task.spawn(function()
	while true do
		try_match()
		task.wait(TICK_RATE)
	end
end)

-- public api
function module:JoinQueueForPlayer(player: Player)
	return queue_player(player)
end

function module:LeaveQueueForPlayer(player: Player)
	return unqueue_player(player)
end

function module:JoinQueueForParty(party)
	return queue_party(party)
end

function module:LeaveQueueForParty(party_arg: typemarshaller.Party)
	return unqueue_party(party_arg)
end

function module:GetQueueInfo()
	local players = {}

	for _, id in ipairs(player_queue_order) do
		local entry = queued_players[id]

		if entry then
			table.insert(players, { userId = id, start = entry.started })
		end
	end

	local parties = {}

	for _, id in ipairs(party_order) do
		local entry = queued_parties[id]

		if entry then
			table.insert(parties, {
				party_id = id,
				leader = entry.party.leader_id,
				size = #entry.party.members,
				start = entry.started,
			})
		end
	end

	return { players = players, parties = parties }
end

return module
