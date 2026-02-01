--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- profilestructure.luau

return {
	-- Template
	cards = {
		Pyro = 10,
		Cryo = 1,
		Plasma = 1,
		Hydro = 0,
	},
	prisms = 5,
	affinity = 5, -- skill points
	skills = {}, -- unlocked skills
	affinity = 5, -- skill points
	level = "Bronze I",
	experience = 0,
	last_login = 0,
	equipped_card = "Pyro",
	victories = 0,
	-- Other
	options = {},
	equipped_emotes = {
		17782874968,
	},
	emotes = {
		{
			-- starter
			name = "Take The L",
			identification = 17782874968,
		},
	},
	achievements = {
		--
	},
	quests = {},
	products = {},
	combatBindings = {
		M1 = Enum.KeyCode.MouseLeftButton.Value, -- melee
		Skill = Enum.KeyCode.E.Value, -- primary
		Ultimate = Enum.KeyCode.Q.Value, -- ultimate
		Support = Enum.KeyCode.R.Value, -- support
	},
} :: typemarshaller.ProfileData
