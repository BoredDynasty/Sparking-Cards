--!strict

local ExperienceManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataStore = require(ServerStorage.Classes.DataStore)
local LevelCalculate = require(ReplicatedStorage.ClientModules.LevelCalculate)

local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") :: Folder

local levelUpRE = RemoteEvents:WaitForChild("LevelUp") :: RemoteEvent

local function toRomanNumeral(number: number): string
	local romanNumerals = {
		[1] = "I",
		[2] = "II",
		[3] = "III",
		[4] = "IV",
		[5] = "V",
		[6] = "VI",
		[7] = "VII",
		[8] = "VIII",
		[9] = "IX",
		[10] = "X",
	}

	return romanNumerals[number] or "Invalid number"
end

local registeredLevels = {
    [1] = "Bronze",
    [2] = "Silver",
    [3] = "Gold",
    [4] = "Platinum",
    [5] = "Diamond",
    [6] = "Master",
}

function ExperienceManager.add(player: Player, experience: number)
	local playerStats = player:FindFirstChild("leaderstats") :: Folder
	local playerLevel = playerStats:FindFirstChild("Rank") :: StringValue
	local playerExperience = playerStats:FindFirstChild("ExperiencePoints") :: IntValue

	local currentLevel = tonumber(playerLevel.Value) :: number

	local newExp = playerExperience.Value + experience :: number

	pcall(function()
		local experienceDataStore = DataStore.GetStore("ExperiencePoints") :: DataStore
		experienceDataStore:SetAsync(`player:{player.UserId}`, newExp)
	end)

	local newLevel = tonumber(playerLevel.Value) :: number

	if newLevel >= currentLevel then
		levelUpRE:FireClient(player, newLevel)
	end
end

function ExperienceManager.set(player, newLevel, newExperience)
	local playerStats = player:FindFirstChild("leaderstats") :: Folder
	local playerLevel = playerStats:FindFirstChild("Rank") :: StringValue
	local playerExperience = playerStats:FindFirstChild("ExperiencePoints") :: IntValue

	if not newLevel then
		newLevel = LevelCalculate.FromExp(newExperience)
	end
	if not newExperience then
		newExperience = LevelCalculate.FromLevel(newLevel)
	end

	playerLevel.Value = toRomanNumeral(newLevel)
end

return ExperienceManager
