--!nonstrict

--[[
    playerMarshaller.luau

    Better typechecking and utilities for player objects!
    Inspired by characterMarshaller.luau
--]]

local Players = game:GetService("Players")

local characterMarshaller = require(script.Parent.characterMarshaller)

export type player = Player & {
	UserId: number,
	Name: string,
	DisplayName: string,
	PlayerGui: PlayerGui,
	Character: characterMarshaller.Character,
}

local playerMarshaller = {}

-- Utility to get a player by UserId
function playerMarshaller.getByUserId(userId: number): player?
	for _, player in playerMarshaller.all() do
		if player.UserId == userId then
			return player :: any
		end
	end
	return nil
end

-- Utility to get a player by Name (case-sensitive)
function playerMarshaller.getByName(name: string): player?
	for _, player in playerMarshaller.all() do
		if player.Name == name then
			return player :: any
		end
	end
	return nil
end

-- Utility to get a player by DisplayName (case-insensitive)
function playerMarshaller.getByDisplayName(displayName: string): player?
	for _, player in playerMarshaller.all() do
		if player.DisplayName:lower() == displayName:lower() then
			return player :: any
		end
	end
	return nil
end

-- Utility to get the local player
function playerMarshaller.get(): player
	local localPlayer = Players.LocalPlayer
	--[[
	localPlayer = playerMarshaller.added(function(p)
		if localPlayer.Name == p.Name then
			localPlayer = p
		end
	end)
	]]
	assert(localPlayer, "Local player is not available | ensure this is run on the client")
	return localPlayer :: any
end

-- Utility to get a player from a character instance
function playerMarshaller.getFromCharacter(character: Model): player?
	for _, player in playerMarshaller.all() do
		if player.Character == character then
			return player :: any
		end
	end
	return nil
end

--  Asynchronous utility to get all players
function playerMarshaller.all(): { player }
	local list: { Player } = {}
	for _, player in Players:GetPlayers() do
		table.insert(list, player)
	end
	return list
end

-- Listen for when a player joins
function playerMarshaller.added(f: (player: Player) -> (), dont_run_for_existing_players: boolean?): player
	local connections = {}

	if not dont_run_for_existing_players then
		for _, player in playerMarshaller.all() do
			task.defer(f, player :: any)
		end
	end

	local conn = Players.PlayerAdded:Connect(function(player)
		f(player :: any)
		return player :: player
	end)
	table.insert(connections, conn)

	return function()
		for _, c in connections do
			if c.Connected then
				c:Disconnect()
			end
		end
	end
end

-- Listen for when a player leaves
function playerMarshaller.removing(f: (player: player) -> ())
	local conn = Players.PlayerRemoving:Connect(function(player)
		f(player :: any)
	end)
	return function()
		if conn.Connected then
			conn:Disconnect()
		end
	end
end

return playerMarshaller
