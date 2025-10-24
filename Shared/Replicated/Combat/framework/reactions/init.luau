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
		module = script.freeze,
	},
	{
		elements = {
			"Pyro",
			"Cryo",
		},
		reaction = "Melt",
		description = [[
         Freezes the target for 1.5 seconds or until hit; shatter damage when broken.
      ]],
		duration = 1.5,
		module = nil,
	},
} :: reaction_chart

export type reaction_chart = {
	{
		elements: { string }, -- usually 2
		reaction: string,
		description: string,
		duration: number?,
		module: ModuleScript?,
	}
}
