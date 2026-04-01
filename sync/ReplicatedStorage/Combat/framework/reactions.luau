--!strict

-- reactions.luau

local reactions = {}

-- TODO) rework the current reaction modules.

local reaction_chart = {
	{
		elements = {
			"Cryo",
			"Hydro",
		},
		reaction = "Frozen",
		description = [[
         Freezes the target for 1.5 seconds or until hit; shatter damage when broken.
      ]],
		duration = 1.5,
		module = nil,
	},
	{
		elements = {
			"Pyro",
			"Cryo",
		},
		reaction = "Melt",
		description = [[
         Increases damage taken by 50% for 15 seconds; can be refreshed.
      ]],
		duration = 1.5,
		module = nil,
	},
	{
		elements = {
			"Pyro",
			"Hydro",
		},
		reaction = "Steam Burst",
		description = [[
			Creates a brief smoke cloud that blurs vision and deals light AoE burn.
		]],
		duration = 5,
		module = nil,
	},
	{
		elements = {
			"Cryo",
			"Electro",
		},
		reaction = "Cryocharge",
		description = [[
			Electric hits deal bonus damage and cause frost sparks; visual sparkle storm effect.
		]],
		duration = 4.6,
		module = nil,
	},
}

export type Reaction = {
	elements: { string }, -- usually 2
	reaction: string,
	description: string,
	duration: number?,
	module: ModuleScript?,
}
