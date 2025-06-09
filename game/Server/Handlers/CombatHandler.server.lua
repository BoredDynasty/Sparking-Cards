--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatStructure = require(ReplicatedStorage.Structures.CombatStructure)
local Frost = require(ServerScriptService.CombatModules.Frost)

-- // Requires

-- // Variables

print("Running combat handler server")

local assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") :: Folder

-- // Util

local skillEvent = remoteEvents:WaitForChild("SkillEvents") :: RemoteEvent
local getProfile = remoteEvents:WaitForChild("GetProfile") :: BindableFunction

local function getCurrentCard(player: Player)
	local profile = getProfile.Invoke(getProfile, player)
	local equipped: string = profile.Data.EquippedCard
	print(player.Name .. " has an equipped card of", equipped)
	return equipped
end

local function handleSkillEvent(player: Player, data: { Position: Vector3 })
	print("handling skill event")
	--if getCurrentCard(player) == "Frost" then
	print("frost skill")
	assert(data, "frost data not found.")
	assert(data.Position, "frost position not found")
	Frost(player, data.Position)
	--end
end

skillEvent.OnServerEvent:Connect(handleSkillEvent)
