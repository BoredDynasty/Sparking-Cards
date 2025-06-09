--!nonstrict

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local safeteleport = require(ReplicatedStorage.Modules.safeteleport)

local MatchmakingModule = {}
local queueDataStore = DataStoreService:GetDataStore("MatchmakingQueue")

local localQueue = {} :: { Player }

MatchmakingModule.localQueue = localQueue

local function addToGlobalQueue(player: Player)
	table.insert(localQueue, player)
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
			safeteleport(placeId, { player1, player2 }, {
				reserve_server = true,
				data = {
					identification1 = player1.UserId,
					indetification2 = player2.UserId,
				},
			})
			print("Teleporting " .. player1.Name .. " and " .. player2.Name .. " to match.")
			table.remove(localQueue, table.find(localQueue, player1))
			--[[
			 There's no need to remove player2 from the queue here, 
			 	as they are not in the local queue.
			--]]
		else
			print("One or both players not found.")
		end
	end
end

function MatchmakingModule.AddPlayerToQueue(player: Player)
	if not game:GetService("RunService"):IsStudio() then
		if not player or table.find(localQueue, player) then
			print("Player already in queue or invalid player.")
			return
		end
		table.insert(localQueue, player)
		addToGlobalQueue(player)
		checkForMatch()
	end
end

function MatchmakingModule.RemovePlayerFromQueue(player: Player)
	if table.find(localQueue, player) then
		table.remove(localQueue, table.find(localQueue, player))
		print(player.Name .. " has been removed from the queue.")
	else
		print("Player not found in queue.")
	end
end

MessagingService:SubscribeAsync("MatchmakingQueueUpdate", function()
	if game:GetService("RunService"):IsStudio() ~= true then
		checkForMatch()
	else
		print("studio mode, skipping matchmaking.")
	end
end)

return MatchmakingModule
