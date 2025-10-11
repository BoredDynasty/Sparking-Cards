--!strict
local ServerUtil = {}
ServerUtil.__index = ServerUtil

--- types ---
export type Server = {
	Config: {
		Teams: {},
		Credentials: { matchId: string, accessCode: string },
	},
	Options: {},
}

export type SerializedServer = {
	Teams: { {} },
	Credentials: { matchId: string, accessCode: string },
}

--- server creation functions ---
function ServerUtil.new(matchmakingOptions, serializedServer: SerializedServer?)
	local self = {
		Config = {
			Teams = {},
			Credentials = { matchId = "", accessCode = "" },
		},
		Options = matchmakingOptions,
	}

	if serializedServer then
		self.Config = serializedServer
	end

	setmetatable(self, ServerUtil)
	return self
end

function ServerUtil:WriteCredentials(matchId: string, accessCode: string): ()
	local credentials = self.Config.Credentials
	credentials.matchId = matchId
	credentials.accessCode = accessCode
end

function ServerUtil:CreateTeams()
	local matchmakingOptions = self.Options
	local numberOfTeams = matchmakingOptions.NumberOfTeams

	for i = 1, numberOfTeams do
		self.Config.Teams["t" .. tostring(i)] = {}
	end
end

function ServerUtil:CanAddPlayersToServer(players: { Player }): boolean
	local matchmakingOptions = self.Options
	local teams = self.Config.Teams
	local success = false

	for i, v in self.Config.Teams do
		if #v + #players <= matchmakingOptions.MaxPlayersPerTeam then
			success = true
			break
		end
	end
	return success
end

function ServerUtil:AddPlayers(players: { Player }): boolean
	local matchmakingOptions = self.Options
	local teams = self.Config.Teams
	local success = false

	if not players or #players <= 0 then
		return success
	end

	for i, v in self.Config.Teams do
		if #v + #players > matchmakingOptions.MaxPlayersPerTeam then
			continue
		end

		for x, y in players do
			table.insert(v, y.UserId)
		end
		success = true
		break
	end
	return success
end

-- returns true if AT LEAST 1 player has been removed
function ServerUtil:RemovePlayers(players: { Player }): boolean
	local teams = self.Config.Teams
	local success = false

	if not players or #players <= 0 then
		return success
	end

	for i, v in players do
		for x, y in self.Config.Teams do
			local position = table.find(y, v.UserId)

			if not position then
				continue
			end

			table.remove(teams[x], position)
			success = true
			break
		end
	end
	return success
end

function ServerUtil:FindPlayer(player: Player): (boolean, string?)
	local teams = self.Config.Teams

	for i, v in teams do
		for x, y in v do
			if y == player.UserId then
				return true, i
			end
		end
	end
	return false, nil
end

function ServerUtil:CountPlayers(): number
	local teams = self.Config.Teams
	local count = 0

	for i, v in teams do
		count += #v
	end

	return count
end

function ServerUtil:Serialize(): SerializedServer
	return self.Config
end

return ServerUtil
