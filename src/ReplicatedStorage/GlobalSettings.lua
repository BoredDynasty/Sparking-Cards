--!strict
local Class = {}
Class.__index = Class

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

Class.IntermissionTime = math.random(20, 30) -- Randomized 20 , 30
Class.MaxTime = 240 -- max gametime
Class.MaxChoosingTime = 20
Class.MatchContinued = false
Class.ValidCards = { Fire = 9, Frost = 5, Plasma = 12, Water = 4 }
Class.IsPrivateServer = false
Class.IsStudio = false -- Wether the current environment is running in Studio.
Class.DefaultAward = 24 -- default add cards

Class.StartingCardsValue = 5
Class.StartingRankValue = "Bronze I"
Class.StartingMultiplierValue = "Untitled"
Class.StartingAbilityValue = "Charge"
Class.StartingExperienceValue = 0

Class.PlayerSettings =
	{ A = "Light Mode", B = "Dark Mode", C = "Hide Players", D = "Notifications", E = "Remove All Light Beams" }

Class.Characters = {
	["Edo"] = {
		type = "non_main",
		attribute = "side_character",
	},
	["Obsidian"] = {
		type = "shop",
		attribute = "shop_person",
	},
	["Coach Mr. G"] = {
		type = "main",
		attribute = "coach_main",
	},
}

Class.ValidWeapons = {
	["Charge"] = {
		type = "base",
	},
	["Ultimate"] = {
		type = "super",
	},
	["Fusion Coil"] = {
		type = "ultimate",
	},
	["Supernatural Radiation"] = {
		type = "super",
	},
}

Class.WinMessages = { "Well now, you did Great~! ", "You can do better than that right?", "OMG~!", "Ehehehehe~!" }
Class.WinLines = { "ALRIGHT~!", "WOWIE!" }
Class.CustomLines = { "Well now, let's get going!", "Heya.", "Heheh..." }

--[=[
    Sets the Default Settings

    @param MaxTime number -- The Max Round time
    @param MaxChoosingTime number -- The Max time the player has to choose a card
]=]
function Class.SetDefaultSettings(MaxTime: number, MaxChoosingTime: number) -- Sets The Default Values
	Class.MaxChoosingTime = MaxChoosingTime
	Class.MaxTime = MaxTime
end

--[=[
    Restores Default Settings

    @param MaxTime number -- The Max Round time is now 240
    @param MaxChoosingTime number -- The Max time the player has to choose a card is now 20
]=]
function Class.RestoreDefaultSettings()
	Class.MaxTime = 240
	Class.MaxChoosingTime = 20
end

--[=[
    Returns true whenever the current game instance is running in a private server
]=]
function Class.GrabPrivateServer() -- Returns true if the game is running a private server
	if game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0 then
		Players.PlayerAdded:Connect(function(player)
			if player.UserId == game.PrivateServerOwnerId then
				Class.IsPrivateServer = true
			else
				Class.IsPrivateServer = false
			end
		end)
	end
end

if RunService:IsStudio() then
	Class.IsStudio = true
end

return Class