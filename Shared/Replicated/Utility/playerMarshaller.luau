--!nonstrict

--[[
    playerMarshaller.luau

    Better typechecking and utilities for player objects!
    Inspired by characterMarshaller.luau
--]]

local Players = game:GetService("Players")

local playerMarshaller = {}

-- Utility to get a player by UserId
function playerMarshaller.getByUserId(userId: number): Player?
	for _, player in ipairs(playerMarshaller.all()) do
		if player.UserId == userId then
			return player :: any
		end
	end
	return nil
end

-- Utility to get a player by Name (case-sensitive)
function playerMarshaller.getByName(name: string): Player?
	for _, player in ipairs(playerMarshaller.all()) do
		if player.Name == name then
			return player :: any
		end
	end
	return nil
end

-- Utility to get a player by DisplayName (case-insensitive)
function playerMarshaller.getByDisplayName(displayName: string): Player?
	for _, player in ipairs(playerMarshaller.all()) do
		if player.DisplayName:lower() == displayName:lower() then
			return player :: any
		end
	end
	return nil
end

-- Utility to get the local player
function playerMarshaller.get(): Player
	local localPlayer = Players.LocalPlayer

	playerMarshaller.added(function(p)
		if localPlayer.UserId == p.UserId then
			localPlayer = p
		end
	end)

	assert(localPlayer, "Local player is not available | ensure this is run on the client")
	return localPlayer :: any
end

-- Utility to get a player from a character instance
function playerMarshaller.getFromCharacter(character: Model): Player?
	for _, player in ipairs(playerMarshaller.all()) do
		if player.Character == character then
			return player :: any
		end
	end
	return nil
end

--  Asynchronous utility to get all players
function playerMarshaller.all(): { Player }
	local list: { Player } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(list, player)
	end
	return list
end

-- Listen for when a player joins
function playerMarshaller.added(f: (player: Player) -> (), dont_run_for_existing_players: boolean?)
	local connections = {}

	if not dont_run_for_existing_players then
		for _, player in playerMarshaller.all() do
			task.defer(f, player :: any)
		end
	end

	local conn = Players.PlayerAdded:Connect(function(player)
		f(player :: any)
		return player :: Player
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
function playerMarshaller.removing(f: (player: Player) -> ())
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
