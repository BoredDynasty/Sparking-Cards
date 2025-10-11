local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Util = {}
--- module types ---
export type Server = {
	Teams: { {} },
	Credentials: { string },
}

--- Player util ---
function Util:TeleportPlayers(matchPlaceId: number, players: { Player }, accessCode)
	if RunService:IsStudio() then
		return true, "studio"
	end
	local ATTEMPT_LIMIT = 5

	local debounce = 0
	local tries = 0

	local success, result = false, nil

	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ReservedServerAccessCode = accessCode

	repeat
		success, result = pcall(function()
			return TeleportService:TeleportAsync(matchPlaceId, players, teleportOptions)
		end)

		if not success then
			tries += 1
			debounce += 1
			task.wait(debounce)
		end
	until success or tries == ATTEMPT_LIMIT

	return success, result
end

--- [DEPRECATED] Server util ---
function Util:CompileDefaultServer(matchmakingOptions, matchCredentials)
	local newServer = {}
	newServer.Teams = {}
	newServer.Credentials = matchCredentials

	for i = 1, matchmakingOptions.NumberOfTeams do
		newServer.Teams["t" .. tostring(i)] = {}
	end

	return newServer
end

function Util:AddPlayersToMatch(serverData, players: { Player }, options)
	if not players or #players == 0 then
		error("No players given.")
	end

	local newServerData = serverData
	local success = false

	for i, v in newServerData.Teams do
		if #v + #players > options.MaxPlayersPerTeam then
			continue
		end

		for x, y in players do
			table.insert(newServerData.Teams[i], y.UserId)
		end

		success = true
		break
	end

	return success, newServerData
end

function Util:IsPlayerInMatch(player: Player, serverData)
	local isInMatch = false
	local teamChecked = nil

	for i, v in serverData.Teams do
		for x, y in v do
			if y ~= player.UserId then
				continue
			end

			isInMatch = true
			teamChecked = i
			break
		end
	end

	return isInMatch, teamChecked
end

return Util
