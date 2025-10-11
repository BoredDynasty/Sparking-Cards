--- Roblox Services
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

--- Custom Modules
local ServerUtil = require(script.Parent.ServerUtil)
local Util = require(script.Parent.Util)
local random = require(ReplicatedStorage.Utility.random)

--- Misc Variables
local readServer = nil
local isReading = false

local MatchmakingFunctions = {}
MatchmakingFunctions.__index = MatchmakingFunctions

--- Core Functions ---
function MatchmakingFunctions:AddAsync(server, players: { Player }?)
	local queue = self.Queue
	local options = self.Options

	local expirationTime = options.MatchExpirationTime
	local numberOfTeams = options.NumberOfTeams
	local maxPlayersPerTeam = options.MaxPlayersPerTeam
	local matchmakingEndedEvent = options.matchmakingEndedEvent

	server:AddPlayers(players)

	local aSuccess, NewData, playersInMatch = queue:UpdateAsync(
		server.Config.Credentials.matchId,
		function(oldData)
			local returnData = HttpService:JSONEncode(server:Serialize())
			return returnData, server:CountPlayers()
		end,
		expirationTime
	)

	return aSuccess, NewData, playersInMatch
end

function MatchmakingFunctions:ReadAsync(matchId)
	local queue = self.Queue
	local options = self.Options
	local expirationTime = options.MatchExpirationTime
	local server, playersInMatch

	local gSuccess, gResult, playerCount = pcall(function()
		return queue:UpdateAsync(matchId, function(oldData, oldPlayerCount)
			local newData = HttpService:JSONDecode(oldData)

			playersInMatch = oldPlayerCount
			server = ServerUtil.new(options, newData)
			return nil
		end, expirationTime)
	end)

	return gSuccess, server, playersInMatch
end

function MatchmakingFunctions:UpdateAsync(matchId, playersToAdd: { Player }?, playersToRemove: { Player }?)
	if (not playersToAdd or #playersToAdd == 0) and (not playersToRemove or #playersToRemove == 0) then
		return false, nil, nil
	end

	local queue: MemoryStoreSortedMap = self.Queue
	local options = self.Options
	local maxPlayersPerTeam = options.MaxPlayersPerTeam
	local numberOfTeams = options.NumberOfTeams
	local expirationTime = options.MatchExpirationTime
	local returnedData = 10

	local playersToAdd = playersToAdd or {}
	local playersToRemove = playersToRemove or {}

	-- Update function
	local function updateFunction(oldData, oldPlayerCount: number)
		if
			not oldData
			or (oldPlayerCount - #playersToRemove + #playersToAdd) > (maxPlayersPerTeam * numberOfTeams)
		then
			return nil
		end
		local success

		local server = ServerUtil.new(options, HttpService:JSONDecode(oldData))
		local removeSuccess = server:RemovePlayers(playersToRemove)
		local addSuccess = server:AddPlayers(playersToAdd)

		if not removeSuccess and not addSuccess then
			return nil
		end

		local serializedServer = server:Serialize()
		local encodedData = HttpService:JSONEncode(serializedServer)
		local newPlayerCount = server:CountPlayers()

		returnedData = server
		return encodedData, newPlayerCount
	end

	-- Add players to the match
	local uSuccess, uData, playerCount = pcall(function()
		return queue:UpdateAsync(matchId, updateFunction, expirationTime)
	end)

	return uSuccess, returnedData, playerCount
end

function MatchmakingFunctions:RemoveAsync(matchId: string)
	local queue: MemoryStoreSortedMap = self.Queue

	local success, result
	local debounce = 0

	repeat
		task.wait(debounce)

		success, result = pcall(function()
			queue:RemoveAsync(matchId)
		end)

		debounce += 1
	until success

	return success, result
end

function MatchmakingFunctions:GetRangeAsync(players: { Instance }?)
	local queue: MemoryStoreSortedMap = self.Queue
	local options = self.Options

	local debounce = 0
	local lowerBound = { key = "", sortKey = 0, inclusive = false }
	local upperBound = nil
	local success, result

	local orders = { Enum.SortDirection.Descending, Enum.SortDirection.Ascending }
	local sortDirection = orders[random.integer(1, 2)]

	if players and #players > 0 then
		local maxPlayerCount = options.NumberOfTeams * options.MaxPlayersPerTeam
		upperBound = { key = "", sortKey = maxPlayerCount - #players + 1 }
	end

	for i = 1, 5 do
		task.wait(debounce)

		success, result = pcall(function()
			return queue:GetRangeAsync(sortDirection, 10, lowerBound, upperBound)
		end)

		if success and result then
			break
		end
		debounce += 1
	end

	return success, result
end

--- Custom Functions ---
function MatchmakingFunctions:CreateMatchAsync()
	local options = self.Options
	local matchPlaceId = options.MatchPlaceId
	local accessCode, matchId

	if not RunService:IsStudio() then
		accessCode, matchId = TeleportService:ReserveServer(matchPlaceId)
	else
		accessCode, matchId = "studio", HttpService:GenerateGUID(false)
	end

	local newServer = ServerUtil.new(options)
	newServer:CreateTeams()
	newServer:WriteCredentials(matchId, accessCode)

	return newServer
end

function MatchmakingFunctions:QueuePlayers(players: { Player })
	if not players or #players == 0 then
		error("No players to be queued")
	end
	local options = self.Options

	local debounce = 0
	local gSuccess, gResult

	for i = 1, random.integer(5) do
		task.wait(debounce)
		debounce += 1

		gSuccess, gResult = self:GetRangeAsync(players)

		if not gSuccess or gResult then
			continue
		end

		local count = 0
		for i, v in gResult do
			count += 1
		end

		if count > 0 then
			break
		end
	end

	if gSuccess and gResult then
		for i, v in gResult do
			local uSuccess, uData = self:UpdateAsync(v.key, players)

			if uSuccess and uData then
				if options.UseCustomTeleporting then
					Util:TeleportPlayers(options.MatchPlaceId, players, uData.Config.Credentials.accessCode)
				end
				return uSuccess, uData.Credentials
			end
		end
	end

	local newServer = self:CreateMatchAsync(players)
	newServer:AddPlayers(players)

	if not newServer.Config.Credentials or not newServer.Config.Credentials.accessCode then
		return false, nil
	end

	local success, newData = self:AddAsync(newServer)

	if options.UseCustomTeleporting then
		Util:TeleportPlayers(options.MatchPlaceId, players, newServer.Config.Credentials.accessCode)
	end
	return true, newServer.Config.Credentials
end

function MatchmakingFunctions:CheckPlayerTeam(
	player: Player,
	callbackFunction: (player: Player, success: boolean, team: string) -> ()?
)
	local matchId = game.PrivateServerId

	local rSuccess
	local isInMatch, team = false, nil

	if not readServer then
		rSuccess, readServer = self:ReadAsync(matchId)
	end

	for i = 1, 2 do
		repeat
			task.wait()
		until not isReading

		isInMatch, team = readServer:FindPlayer(player)

		if isInMatch or i >= 2 then
			break
		end

		if isReading then
			continue
		end

		isReading = true
		rSuccess, readServer = self:ReadAsync(matchId)
		isReading = false
	end

	if callbackFunction then
		callbackFunction(player, isInMatch, team)
	else
		return isInMatch, team
	end
end

return MatchmakingFunctions
