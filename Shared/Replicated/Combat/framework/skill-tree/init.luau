--!strict

-- skill-tree.luau

local skill_chart = {
	-- TODO) expand here
	{
		name = "Itchy Feet",
		technique = "Itchy Feet",
		upgrade_number = 1,
		description = "Move 5% faster",
		cost = 2,
		requirements = {},
		next = { "Itchy Feet 2" },
		blacklisted = { "Geo" },
		icon = "rbxassetid://0",
	},
	{
		name = "Very Itchy Feet",
		technique = "Itchy Feet",
		upgrade_number = 2,
		description = "Move 5% faster",
		cost = 4,
		requirements = {},
		next = { "Itchy Feet 3" },
		blacklisted = { "Geo" },
		icon = "rbxassetid://0",
	},
	{
		name = "Extreme Itchy Feet",
		technique = "Itchy Feet",
		upgrade_number = 3,
		description = "Move 5% faster",
		cost = 6,
		requirements = {},
		next = { "Itchy Feet 4" },
		blacklisted = { "Geo" },
		icon = "rbxassetid://0",
	},
	{
		name = "Mega Itchy Feet",
		technique = "Itchy Feet",
		upgrade_number = 4,
		description = "Move 5% faster",
		cost = 8,
		requirements = {},
		next = {},
		blacklisted = { "Geo" },
		icon = "rbxassetid://0",
	},
	{
		name = "Investment Oppertunity",
		technique = "Investment Oppertunity",
		upgrade_number = 1,
		description = "Gain %5 more EXP.",
		cost = 4,
		requirements = {},
		next = { "Investment Oppertunity 2" },
		blacklisted = {},
		icon = "rbxassetid://0",
	},
	{
		name = "Better Investment Oppertunity",
		technique = "Investment Oppertunity",
		upgrade_number = 2,
		description = "Gain %5 more EXP.",
		cost = 8,
		requirements = {},
		next = { "Investment Oppertunity 3" },
		blacklisted = {},
		icon = "rbxassetid://0",
	},
	{
		name = "Best Investment Oppertunity",
		technique = "Investment Oppertunity",
		upgrade_number = 3,
		description = "Gain %5 more EXP.",
		cost = 12,
		requirements = {},
		next = {},
		blacklisted = {},
		icon = "rbxassetid://0",
	},
	{
		name = "Ranged Mastery",
		technique = "Ranged Mastery",
		upgrade_number = 1,
		description = "Increased surface penetration with ranged attacks.",
		cost = 4,
		requirements = {},
		next = { "Ranged Mastery 2" },
		blacklisted = {},
		icon = "rbxassetid://0",
	},
	{
		name = "Ranged Mastery 2",
		technique = "Ranged Mastery",
		upgrade_number = 2,
		description = "Increased surface penetration with ranged attacks.",
		cost = 8,
		requirements = {},
		next = { "Ranged Mastery 3" },
		blacklisted = {},
		icon = "rbxassetid://0",
	},
	{
		name = "Ranged Mastery 3",
		technique = "Ranged Mastery",
		upgrade_number = 3,
		description = "Increased surface penetration with ranged attacks.",
		cost = 12,
		requirements = {},
		next = {},
		blacklisted = {},
		icon = "rbxassetid://0",
	},
} :: skill_chart

export type skill_chart = {
	{
		name: string,
		technique: string?,
		upgrade_number: number?,
		description: string,
		cost: number, -- must be rounded to the nearest tenth
		level_required: number, -- dont worry, we can convert level number to rank name
		requirements: { string? }, -- ahem, ALL skill requirements.
		next: { string? },
		blacklisted: { string? }, -- what cards CAN'T use this skill
		icon: Content | string, -- content or "rbxassetid://ASSET_ID"
		type: "major" | "minor",
	}
}

export type skill = {
	name: string,
	technique: string?,
	upgrade_number: number?,
	description: string,
	cost: number, -- must be rounded to the nearest tenth
	level_required: number, -- dont worry, we can convert level number to rank name
	requirements: { string? }, -- ahem, ALL skill requirements.
	next: { string? },
	blacklisted: { string? }, -- what cards CAN'T use this skill
	icon: Content | string, -- content or "rbxassetid://ASSET_ID"
	type: "major" | "minor",
}

return skill_chart
