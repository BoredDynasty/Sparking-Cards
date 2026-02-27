--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- profilestructure.luau

return {
	-- Template
	cards = {
		Pyro = 10,
		Cryo = 1,
		Electro = 1,
		Hydro = 0,
	},
	prisms = 5,
	affinity = 5, -- skill points
	skills = {}, -- unlocked skills
	level = "Bronze I",
	experience = 0,
	last_login = 0,
	equipped_card = "Pyro",
	victories = 0,
	-- Other
	options = {
		background_music = true,
		gui_sound = true,
		background_music_volume = 1,
	},
	equipped_emotes = {
		17782874968,
	},
	emotes = {
		17782874968,
	},
	achievements = {
		--
	},
	bookmarked_shop_items = {},
	quests = {},
	products = {},
	keybinds = {
		M1 = Enum.KeyCode.MouseLeftButton.Value, -- melee
		Skill = Enum.KeyCode.E.Value, -- primary
		Ultimate = Enum.KeyCode.Q.Value, -- ultimate
		Support = Enum.KeyCode.R.Value, -- support

		enable_spectating = Enum.KeyCode.N.Value,
	},
} :: typemarshaller.ProfileData
