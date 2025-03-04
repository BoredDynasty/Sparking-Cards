--!strict

--[=[
	@class Global

	A Module Config for the game.
]=]
local Global = {}
Global.__index = Global

Global.IntermissionTime = math.random(20, 30) -- Randomized 20 , 30
Global.MaxTime = 240 -- max gametime
Global.MaxChoosingTime = 20
Global.MatchContinued = false
Global.ValidCards = {
	["Fire"] = {
		["Damage"] = 32,
		["RichTextColor"] = "#ccb6ff",
		["Price"] = 9,
	},
	["Plasma"] = {
		["Damage"] = 21,
		["RichTextColor"] = "#675496",
		["Price"] = 13,
	},
	["Frost"] = {
		["Damage"] = 13,
		["RichTextColor"] = "#675496",
		["Price"] = 12,
	},
	["Water"] = {
		["Damage"] = 4,
		["RichTextColor"] = "#55ff7f",
		["Price"] = 3,
	},
}
Global.IsPrivateServer = false
Global.IsStudio = false
Global.DefaultAward = 24 -- default add cards

Global.StartingCardsValue = 5
Global.StartingRankValue = "Bronze I"
Global.StartingMultiplierValue = "Untitled"
Global.StartingAbilityValue = "Charge"
Global.StartingExperienceValue = 0

Global.PlayerSettings = {
	A = "Light Mode",
	B = "Dark Mode",
	C = "Hide Players",
	D = "Notifications",
	E = "Remove All Light Beams",
}
Global.Characters = {
	["Edo"] = {
		type = "non_main",
		attribute = "side_character",
		tag = "edo_character",
	},
	["Obsidian"] = {
		type = "shop",
		attribute = "shop_person",
		tag = "obsidian_npc",
	},
	["Coach Mr. G"] = {
		type = "main",
		attribute = "coach_main",
		tag = "mr_g_character",
	},
}
Global.ValidWeapons = {
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
Global.WinMessages =
	{ "Well now, you did Great~! ", "You can do better than that right?", "OMG~!", "Ehehehehe~!" }
Global.WinLines = { "ALRIGHT~!", "WOWIE!" }
Global.CustomLines = { "Well now, let's get going!", "Heya.", "Heheh..." }

return Global
