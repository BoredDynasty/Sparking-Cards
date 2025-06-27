--!strict

-- profilestructure.lua

return {
	-- Template
	["Cards"] = {
		Fire = 10,
		Frost = 1,
		Plasma = 1,
		Water = 0,
	},
	["Big-Cards"] = 5,
	["Level"] = "Bronze I",
	["Experience"] = 0,
	["LastLogin"] = os.time(),
	["EquippedCard"] = "Frost",
	-- Other
	["options"] = {
		["clockTime"] = 12,
		["description"] = "Destined for awesomeness!",
		["profileBannerLink"] = "rbxassetid://95864343491678",
	},
	equippedEmotes = {
		17782874968,
	},
	emotes = {
		{
			-- starter
			name = "Take The L",
			identification = 17782874968,
		},
	},
	["combatBindings"] = {
		["attack"] = "LMB", -- melee
		["special_One"] = "E", -- primary
		["special_Two"] = "Q", -- ultimate
		["special_Three"] = "R", -- support
	},
}
