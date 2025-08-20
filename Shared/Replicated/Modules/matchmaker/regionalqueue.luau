local RegionalQueue = {}
RegionalQueue.__index = RegionalQueue

-- Variables

local Release = "v0.2"
local MemoryStore = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")
local RegionLockMap = MemoryStore:GetHashMap("RegionLocks" .. Release)

local PrivateServer = require(script.Parent.Parent:WaitForChild("PrivateServer"))

local Utils = game.ReplicatedStorage:WaitForChild("Utils")
local Maid = require(Utils:WaitForChild("Maid"))
local Promise = require(Utils:WaitForChild("Promise"))
local Signal = require(Utils:WaitForChild("Signal"))
local Thread = require(Utils:WaitForChild("Thread"))

local QUEUE_TIMEOUT = 60 * 20 -- seconds
local PARTY_TIMEOUT = 60 * 60 * 24 -- seconds
local PARTY_REFRESH = 5 -- seconds

local BIG_QUEUE_TIME = 9999999999

local COORDINATOR_REFRESH = 5 -- seconds
local COORDINATOR_TIMEOUT = 30 -- seconds

local MATCHMAKING_TOTALCOUNT = 200 -- seconds
local MATCHMAKING_SUBCOUNT = 50 -- seconds

-- Main

function RegionalQueue.new(Params)
	--[[
		Creates a new regional queue.

		Parameters:
			Params.RegionCode (string) — A short code (e.g., "NA", "EU") representing the region.
			Params.Mode (matchmaker) — The parent matchmaker of the regional queue.

		Returns:
			A new RegionalQueue instance.
	]]
	--

	local self = setmetatable(Params, RegionalQueue)

	self.RegionCode = self.RegionCode
	self.MainServer = false
	self.Active = true
	self.ID = self.Mode.Name .. "-" .. self.RegionCode
	self.SortedMap = self:GetSortedMap(self.Mode.Name, self.RegionCode)
	self.Cache = {}
	self.Connections = Maid.new()

	self.Mode.RegionalQueues[self.RegionCode] = self

	self:Print("New regional queue has been created")

	return self
end

--Players Management

function RegionalQueue:GetSortedMap(Mode, RegionCode)
	--[[
		Returns a MemoryStore SortedMap unique to a mode-region pair.

		Parameters:
			Mode (string)
			RegionCode (string)

		Returns:
			SortedMap object.
	]]
	--

	return game:GetService("MemoryStoreService"):GetSortedMap(Mode .. "-" .. RegionCode .. Release)
end

function RegionalQueue:TeleportPartyAsync(Party, MatchId)
	--[[
		Handles teleporting party members to a server if a match is found.

		Parameters:
			Party (table)
			MatchId (string)

		Returns:
			Promise<void> — Resolves after firing the PartyRemoved signal.
	]]
	--

	return PrivateServer:GetPrivateServerDataAsync(MatchId)
		:catch(function(err)
			return Promise.reject(tostring(err))
		end)
		:andThen(function(Match)
			self:RemovePartyTable(Party.Id, Match)
		end)
end

function RegionalQueue:CheckIfPartyFoundMatch(Party, LeaveQueue)
	--[[
		Checks if a party has already been matched in a queue.

		Parameters:
			Party (table)
			LeaveQueue (boolean) — Mark party as left if true.

		Returns:
			Promise<MatchId | nil>
	]]
	--

	local MatchId

	return Promise.try(function()
		return self.SortedMap:UpdateAsync(Party.Id, function(oldValue, sortKey)
			if not oldValue then
				-- means the queue timed out
				return nil
			end

			if LeaveQueue then
				oldValue.PartyLeft = true
				sortKey = BIG_QUEUE_TIME
			end

			if oldValue.MatchId then
				-- ayy we found a match !
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

function RegionalQueue:AddPartyAsync(PartyMemberIds, PartyData)
	--[[
		Adds a new party to the matchmaking queue.

		Parameters:
			PartyMemberIds (table<number>) — UserIds.
			PartyData (optional table) — Metadata for the party.

		Returns:
			Promise<void>
	]]
	--

	local JoinTime = os.time()
	local Party = {
		Id = game:GetService("HttpService"):GenerateGUID(false),
		Mode = self.Mode.Name,
		RegionCode = self.RegionCode,
		MemberIds = PartyMemberIds,
		Data = PartyData or {},
		QueueTimeStart = JoinTime,
	}

	local CacheTable = {
		Connections = Maid.new(),
		JoinTime = JoinTime,
		Party = Party,
	}

	self.Cache[Party.Id] = CacheTable

	self:Print("Adding a party to the queue")

	-- Adding Player to SortedMap
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
			CacheTable.Connections.RefreshConnection = Thread.DelayRepeat(PARTY_REFRESH, function()
				local TimeEllapsed = os.time() - JoinTime

				if TimeEllapsed > QUEUE_TIMEOUT then
					self:RemovePartyAsync(Party.Id)
				else
					self:CheckIfPartyFoundMatch(Party):andThen(function(MatchId)
						if MatchId then
							return self:TeleportPartyAsync(Party, MatchId)
						end
					end)
				end
			end)

			if not self.Connections.MainServerRefresh then
				task.spawn(function()
					self:DoMatchmaking()
				end)
				self.Connections.MainServerRefresh = Thread.DelayRepeat(COORDINATOR_REFRESH, function()
					self:DoMatchmaking()
				end)
			end

			self.Mode.PartyAdded:Fire(Party)
			CacheTable.InQueue = true

			return Party
		end)
end

function RegionalQueue:RemovePartyTable(PartyId, Match)
	--[[
		Immediately removes a party from the in-memory queue and signals removal.

		Parameters:
			PartyId (string)
	]]
	--

	local CacheTable = self.Cache[PartyId]
	if not CacheTable then
		self:RemoveEmptyQueue()
		return
	end

	CacheTable.Connections:Destroy()

	self.Cache[PartyId] = nil

	self.Mode.PartyRemoved:Fire(CacheTable.Party, Match)

	self:RemoveEmptyQueue()
end

function RegionalQueue:RemovePartyAsync(PartyId, Forced)
	--[[
		Safely removes a party from the queue, optionally forced. Teleports if a match is already found.

		Parameters:
			PartyId (string)
			Forced (boolean)

		Returns:
			Promise<void>
	]]
	--

	local Party
	local CacheTable

	self:Print("Removing a party from the queue")

	return Promise.try(function()
		CacheTable = self.Cache[PartyId]
		assert(CacheTable ~= nil, "The following partyId " .. PartyId .. " is not in queue in this server")

		Party = CacheTable.Party

		assert(CacheTable.InQueue or Forced, "Player is still being added to the queue, please try again")
	end)
		:andThen(function()
			if Forced then
				self:RemovePartyTable(Party.Id)
			end

			if CacheTable.AddedToSortedMap then
				return self:CheckIfPartyFoundMatch(Party, true)
			end
		end)
		:andThen(function(Match)
			if Match then
				self:TeleportPartyAsync(Party, Match)

				return Promise.reject("Player has already found a match, cannot cancel now")
			end
		end)
		:andThen(function(Match)
			self:RemovePartyTable(Party.Id)
		end)
		:finally(function(Status)
			self:Print("Removing a party from the queue:" .. Status)
		end)
end

--Queue Management

function RegionalQueue:TryLockServer()
	--[[
		Attempts to claim coordination ownership for matchmaking in this region.

		Returns:
			Promise<table> — Metadata including serverId and timestamp.
	]]
	--

	local lockKey = self.ID
	local myServerId = game.JobId
	local Active = self.Active

	return Promise.try(function()
		return RegionLockMap:UpdateAsync(lockKey, function(oldValue)
			-- No one owns the lock OR lock expired
			if not oldValue and Active then
				return {
					serverId = myServerId,
					timestamp = os.time(),
					Active = Active,
				}
			elseif oldValue and oldValue.serverId == myServerId then
				return {
					serverId = myServerId,
					timestamp = os.time(),
					Active = Active,
				}
			elseif oldValue and not oldValue.Active and Active then
				return {
					serverId = myServerId,
					timestamp = os.time(),
					Active = Active,
				}
			else
				return oldValue
			end
		end, COORDINATOR_TIMEOUT)
	end)
end

function RegionalQueue:IsServerMainServer()
	--[[
		Verifies and updates whether this server is the matchmaking coordinator for this region.

		Returns:
			Promise<void> — Rejects if not the main server.
	]]
	--

	local lockKey = self.ID
	local myServerId = game.JobId

	return self:TryLockServer()
		:andThen(function(acquired)
			assert(
				acquired and acquired.serverId == myServerId and acquired.Active,
				"This server is not the main server"
			)

			if not self.MainServer then
				self:Print("This server became the main server")
			end

			self.MainServer = true
		end)
		:catch(function(err)
			if self.MainServer then
				self:Print("This server stopped being the main server")
			end

			self.MainServer = false

			return Promise.reject(tostring(err))
		end)
end

function RegionalQueue:CreateMatchAsync(Match)
	--[[
		Attempts to assign a match to a list of parties.

		Parameters:
			Match (table): Must contain Parties, PlaceId, and optionally AccessCode.

		Returns:
			Promise<void>
	]]
	--

	local PartiesRemoved = {}
	local AllPartiesAvailable = true

	Match.CreatedTime = os.time()
	Match.Mode = self.Mode.Name
	Match.RegionCode = self.RegionCode
	if not Match.AccessCode then
		local AccessCode, PrivateServerId = PrivateServer:ReserverServer(Match.PlaceId)
		Match.AccessCode = AccessCode
		Match.PrivateServerId = PrivateServerId
	end
	Match.ServerState = "Created"

	local partyPromises = {}

	for _, Party in pairs(Match.Parties) do
		table.insert(
			partyPromises,
			Promise.try(function()
				local success = self.SortedMap:UpdateAsync(Party.Id, function(oldValue, sortKey)
					if not oldValue then
						-- means the party queue data was expired and they left queue
						print(`HERE, NOT IN QUEUE`, oldValue)
						return nil
					end

					if
						oldValue.PartyLeft
						or oldValue.MatchId and oldValue.MatchId ~= Match.PrivateServerId
					then
						-- means the party found another match or left the queue
						print(`HERE, ALREADY IN A MATCH`)
						return nil
					end

					if not AllPartiesAvailable then
						print(`HERE, OTHER PARTIES UNAVAILABLE`)
						return nil
					end

					-- means the party is available for the match
					oldValue.MatchId = Match.PrivateServerId
					sortKey = BIG_QUEUE_TIME
					table.insert(PartiesRemoved, oldValue)

					return oldValue, sortKey
				end, PARTY_TIMEOUT)

				if not success then
					return Promise.reject("One of the parties was unable to receive the match data")
				end
			end)
		)
	end

	return Promise.allSettled(partyPromises)
		:andThen(function(results)
			for _, result in ipairs(results) do
				if result ~= "Resolved" then
					return Promise.reject("One of the party could not be updated")
				end
			end
		end)
		:catch(function(err)
			local partyPromises = {}

			for _, Party in pairs(PartiesRemoved) do
				table.insert(
					partyPromises,
					Promise.try(function()
						self.SortedMap:UpdateAsync(Party.Id, function(oldValue, sortKey)
							if not oldValue then
								-- means the party queue data was expired and they left queue
								return nil
							end

							if oldValue.MatchId and oldValue.MatchId == Match.PrivateServerId then
								-- resetting the macth data if it was this match
								oldValue.MatchId = nil
							end

							if oldValue.PartyLeft then
								-- party left so making sure the party is not fetched first in the getrangeasync
								sortKey = BIG_QUEUE_TIME
							else
								-- party still in queue, putting the party back in its original position
								sortKey = oldValue.QueueTimeStart
							end

							return oldValue, sortKey
						end, PARTY_TIMEOUT)
					end)
				)
			end

			return Promise.reject(tostring(err))
		end)
		:andThen(function()
			return PrivateServer:RegisterAsync(Match)
		end)
end

function RegionalQueue:CreateMatches(Matches)
	--[[
		Creates multiple matches concurrently and reports the outcome.

		Parameters:
			Matches (table<Match>)

		Returns:
			Promise<void>
	]]
	--

	local matchPromises = {}

	for _, Match in pairs(Matches) do
		table.insert(matchPromises, self:CreateMatchAsync(Match))
	end

	return Promise.allSettled(matchPromises):andThen(function(results)
		local successCount = 0
		local failureCount = 0

		for _, result in ipairs(results) do
			if result == "Resolved" then
				successCount += 1
			else
				failureCount += 1
			end
		end

		print(results)

		self:Print(`Created successfully {successCount}/{successCount + failureCount} matches`)
	end)
end

function RegionalQueue:DoMatchmaking()
	--[[
		Runs the matchmaking loop for the current server (if it is the main coordinator). 
		Fetches eligible parties and invokes matchmaking logic.

		Returns:
			Promise<void>
	]]
	--

	local totalFetched = 0
	local maxItems = MATCHMAKING_TOTALCOUNT
	local batchSize = MATCHMAKING_SUBCOUNT
	local Parties = {}

	self:IsServerMainServer()
		:andThen(function()
			-- Fetching Parties

			local exclusiveUpperBound = {
				sortKey = os.time() + COORDINATOR_REFRESH,
			}

			local exclusiveLowerBound = {
				sortKey = os.time() - QUEUE_TIMEOUT + COORDINATOR_REFRESH,
			}

			self:Print("Retrieving parties")

			exclusiveLowerBound = nil

			while totalFetched < maxItems do
				local success, items = pcall(function()
					return self.SortedMap:GetRangeAsync(
						Enum.SortDirection.Ascending,
						batchSize,
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

					if Party.MatchId or Party.PartyLeft then
						break
					end

					table.insert(Parties, Party)

					if totalFetched >= maxItems then
						break
					end
				end

				if #items < batchSize or totalFetched >= maxItems then
					break
				end

				exclusiveLowerBound = {
					key = items[#items].key,
					sortKey = items[#items].sortKey,
				}
			end

			self:Print(`Retrieved {#Parties} parties`)
		end)
		:andThen(function()
			return self.Mode.MatchMaking(Parties)
		end)
		:andThen(function(Matches)
			if not Matches or #Matches == 0 then
				self:Print(`No match to create`)
				return
			end

			self:Print(`Creating {#Matches} matches`)

			return self:CreateMatches(Matches)
		end)
		:catch(function(err)
			self:Warn(tostring(err))
		end)
end

function RegionalQueue:Print(Txt)
	--[[
		Logs a message with context for this queue.

		Parameters:
			Txt (string)
	]]
	--

	print(`[MatchMakerService-{self.ID}] {Txt}`)
end

function RegionalQueue:Warn(Txt)
	--[[
		Logs a warning message with context for this queue.

		Parameters:
			Txt (string)
	]]
	--

	warn(`[MatchMakerService-{self.ID}] {Txt}`)
end

--Queue Removal

function RegionalQueue:RemoveEmptyQueue()
	--[[
		Destroys the regional queue if no parties are in it.
	]]
	--

	if not next(self.Cache) then
		self:Destroy()
	end
end

function RegionalQueue:Destroy()
	--[[
			Cleans up the regional queue instance, including connections and coordinator ownership.
	]]
	--

	if not self.Active then
		return
	end

	self.Active = false

	self.Connections:Destroy()

	if self.MainServer then
		self:TryLockServer()
	end

	self:Print("Regional queue has been destroyed")
	self.Mode.RegionalQueues[self.RegionCode] = nil
end

return RegionalQueue
