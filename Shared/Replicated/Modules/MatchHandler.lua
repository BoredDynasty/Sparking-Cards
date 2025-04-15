--!strict

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")

local MatchmakingModule = {}
local queueDataStore = DataStoreService:GetDataStore("MatchmakingQueue")

local function addToGlobalQueue(player: Player)
	pcall(function()
		local queue = queueDataStore:GetAsync("Queue") or {} :: any
		table.insert(queue, 1, player.UserId)
		queueDataStore:SetAsync("Queue", queue)
		MessagingService:PublishAsync("MatchmakingQueueUpdate")
	end)
end

local function checkForMatch()
	local success: boolean, queue: { any } = pcall(function()
		return queueDataStore:GetAsync("Queue") or {}
	end)
	if success and #queue >= 2 then
		local player1Id = table.remove(queue, 1) :: number
		local player2Id = table.remove(queue, 1) :: number
		queueDataStore:SetAsync("Queue", queue)

		local player1 = Players:GetPlayerByUserId(player1Id) :: Player
		local player2 = Players:GetPlayerByUserId(player2Id) :: Player

		if player1 and player2 then
			local placeId = 90845913624517 -- Match
			TeleportService:TeleportPartyAsync(placeId, { player1, player2 })
		end
	end
end

function MatchmakingModule.AddPlayerToQueue(player: Player)
	if not game:GetService("RunService"):IsStudio() then
		addToGlobalQueue(player)
		checkForMatch()
	end
end

MessagingService:SubscribeAsync("MatchmakingQueueUpdate", function()
	if not game:GetService("RunService"):IsStudio() then
		checkForMatch()
	end
end)

return MatchmakingModule
