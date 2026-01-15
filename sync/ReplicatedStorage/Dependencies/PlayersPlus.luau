--!optimize 2

--[[

  _____  _                                 
 |  __ \| |                            _   
 | |__) | | __ _ _   _  ___ _ __ ___ _| |_ 
 |  ___/| |/ _` | | | |/ _ \ '__/ __|_   _|
 | |    | | (_| | |_| |  __/ |  \__ \ |_|  
 |_|    |_|\__,_|\__, |\___|_|  |___/      
                  __/ |                    
                 |___/                     

v1.2.0

A simple custom players list module, which only includes
ready clients, and retains all player indices.


GitHub (repository):
https://github.com/AlexanderLindholt/PlayersPlus

]]
--

-- Services.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

-- Network packets.
local packets = CollectionService:GetTagged("Packets")[1]
if not packets then
	error("Could not find packets module.")
end
packets = require(packets)

-- Player tables.
local players = {}
local playerIndices = {}

-- Player insertion.
packets.Loaded.OnServerEvent:Connect(function(player)
	local index = 1
	while true do
		if not players[index] then
			-- Found the lowest available index for the player.
			players[index] = player
			playerIndices[player] = index
			return
		end
		index += 1
	end
end)
-- Player removal.
Players.PlayerRemoving:Connect(function(player)
	local index = playerIndices[player]
	if not index then
		return
	end -- Skip if player was never added to list.

	players[index] = nil
	playerIndices[player] = nil
end)

-- Types.
export type Players = { [number]: Player }
export type PlayerIndices = { [Player]: number }

-- Function for returning lists. Unfortunately modules can't return tuples.
return function(): (Players, PlayerIndices)
	return players, playerIndices
end
