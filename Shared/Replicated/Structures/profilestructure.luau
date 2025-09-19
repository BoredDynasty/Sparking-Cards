--!strict

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
	combatBindings: {
		["attack"]: string, -- melee
		["special_One"]: string, -- primary
		["special_Two"]: string, -- ultimate
		["special_Three"]: string, -- support
	},
}

return {
	-- Template
	["Cards"] = {
		Fire = 10,
		Frost = 1,
		Plasma = 1,
		Hydro = 0,
	},
	["Prisms"] = 5,
	["Level"] = "Bronze I",
	["Experience"] = 0,
	["LastLogin"] = DateTime.now().UnixTimestampMillis,
	["EquippedCard"] = "Frost",
	["victories"] = 0,
	-- Other
	["options"] = {
		["clockTime"] = 12,
		["showDamageNumbers"] = true,
		["autoEquipBestCard"] = false,
		["shadows"] = true,
		["showOtherPlayers"] = true,
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
	["combatBindings"] = {
		["attack"] = Enum.KeyCode.MouseLeftButton.Name, -- melee
		["special_One"] = Enum.KeyCode.E.Name, -- primary
		["special_Two"] = Enum.KeyCode.Q.Name, -- ultimate
		["special_Three"] = Enum.KeyCode.R.Name, -- support
	},
}
