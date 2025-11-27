--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- profilestructure.luau

export type profile = {
	Cards: {
		string: number,
	},
	Prisms: number,
	Level: string,
	Experience: number,
	LastLogin: number,
	EquippedCard: string,
	victories: number,
	emotes: {
		{
			name: string,
			identification: number,
			-- add more fields if necessary
			-- e.g., description: string,
			--       rarity: string,
			--       etc.
		}
	},
	options: {
		string: any,
	},
	equippedEmotes: { number },
	achievements: {
		{
			name: string,
			description: string,
			points: number,
		}
	},
	quests: {
		{
			name: string,
			description: string,
			inquirer_img: string | Instance, -- img id or a model
			progress: number,
			date_acquired: number, -- unix timestamp millis
			date_completed: number?,
			module: ModuleScript?,
		} -- another cyclic module dependency
	},
	products: {
		[number]: {
			id: number,
			recieptInfo: typemarshaller.ReceiptInfo,
			times_bought: {
				[string]: number, ---@type date format: unixtimestamp
			},
		},
	},
	keybinds: {
		string: number,
	},
}

return {
	-- Template
	Cards = {
		Pyro = 10,
		Cryo = 1,
		Plasma = 1,
		Hydro = 0,
	},
	Prisms = 5,
	Affinity = 5, -- skill points
	Level = "Bronze I",
	Experience = 0,
	LastLogin = 0,
	EquippedCard = "Pyro",
	victories = 0,
	-- Other
	options = {
		showDamageNumbers = true,
		autoEquipBestCard = false,
		shadows = true,
		showOtherPlayers = true,
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
}
